import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final SupabaseClient _client;
  NotificationService(this._client);

  static const _kHiddenKey = 'notification_hidden_ids_v1';
  static const _kArchivedKey = 'notification_archived_ids_v1';

  // Process-local caches so we don't re-query tables that don't exist
  // (e.g. `policies` on deployments that pre-date migration 048) on
  // every notification list refresh. Once we know a table is missing
  // we skip its poller block entirely for the lifetime of the page.
  static bool _policiesProbed = false;
  static bool _policiesMissing = false;

  // Runtime notifications are cached in memory for `_runtimeCacheTtl`
  // so taps that trigger rebuilds (e.g. setState on the ExpansionTile
  // or the InkWell's splash state) don't cause every poller to fire
  // 7 HTTP requests all over again. The cache is invalidated on any
  // explicit mutation (mark read, archive, etc.).
  static const Duration _runtimeCacheTtl = Duration(seconds: 30);
  static List<Notification>? _runtimeCache;
  static DateTime? _runtimeCacheAt;
  static Set<String> _runtimeCacheHidden = const <String>{};

  Future<List<Notification>> getNotifications({
    bool? unreadOnly,
    String? type,
    String? priority,
    int limit = 200,
    int offset = 0,
    bool archivedOnly = false,
    bool includeArchived = false,
  }) async {
    final hidden = await _loadHiddenIds();
    final stored = await _safeFetchStored(
      unreadOnly: unreadOnly,
      type: type,
      priority: priority,
      limit: limit,
      offset: offset,
      archivedOnly: archivedOnly,
      includeArchived: includeArchived,
    );
    final runtime = await _buildRuntimeNotifications(hidden: hidden);
    final merged = <Notification>[...stored, ...runtime]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    Iterable<Notification> filtered = merged;
    if (unreadOnly == true) filtered = filtered.where((n) => !n.read);
    if (type != null) filtered = filtered.where((n) => n.type == type);
    if (priority != null) filtered = filtered.where((n) => n.priority == priority);
    if (archivedOnly) {
      filtered = filtered.where((n) => n.isArchived);
    } else if (!includeArchived) {
      filtered = filtered.where((n) => !n.isArchived);
    }
    return filtered.skip(offset).take(limit).toList();
  }

  Future<int> getUnreadCount() async {
    final all = await getNotifications(unreadOnly: true, limit: 500);
    return all.length;
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.startsWith('runtime::')) {
      await _hideRuntime(notificationId);
      invalidateRuntimeCache();
      return;
    }
    try {
      await _client.from('notifications').update({
        'read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final hidden = await _loadHiddenIds();
    final all = await _buildRuntimeNotifications(hidden: hidden);
    for (final n in all) {
      if (!n.read) await _hideRuntime(n.id);
    }
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        await _client.from('notifications').update({
          'read': true,
          'read_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId).eq('read', false);
      }
    } catch (_) {}
  }

  Future<void> deleteNotification(String notificationId) async {
    if (notificationId.startsWith('runtime::')) {
      await _hideRuntime(notificationId);
      invalidateRuntimeCache();
      return;
    }
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (_) {}
  }

  /// Archive a notification: hide it from the default view but keep it
  /// in the database so it can be retrieved later. Runtime notifications
  /// (those whose id starts with `runtime::`) are local-only - their
  /// archive state is stored in `user.userMetadata` under a separate key.
  Future<void> archiveNotification(String notificationId) async {
    if (notificationId.startsWith('runtime::')) {
      await _setRuntimeFlag(notificationId, archived: true);
      invalidateRuntimeCache();
      return;
    }
    try {
      await _client.from('notifications').update({
        'archived_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (_) {}
  }

  /// Move a notification back to the active list.
  Future<void> unarchiveNotification(String notificationId) async {
    if (notificationId.startsWith('runtime::')) {
      await _setRuntimeFlag(notificationId, archived: false);
      invalidateRuntimeCache();
      return;
    }
    try {
      await _client.from('notifications').update({
        'archived_at': null,
      }).eq('id', notificationId);
    } catch (_) {}
  }

  /// Convenience: list everything that's been archived.
  Future<List<Notification>> getArchivedNotifications({
    int limit = 200,
    int offset = 0,
  }) async {
    return getNotifications(archivedOnly: true, limit: limit, offset: offset);
  }

  Future<void> markAsDelivered(String notificationId) async {
    try {
      await _client.from('notifications').update({
        'delivered': true,
        'delivered_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (_) {}
  }

  Future<List<Notification>> _buildRuntimeNotifications({required Set<String> hidden}) async {
    // Cache hit: same hidden-set as last time and cache is fresh.
    final now = DateTime.now();
    if (_runtimeCache != null &&
        _runtimeCacheAt != null &&
        now.difference(_runtimeCacheAt!) < _runtimeCacheTtl &&
        _setEquals(_runtimeCacheHidden, hidden)) {
      return List<Notification>.from(_runtimeCache!);
    }

    final list = <Notification>[];
    final since7  = now.subtract(const Duration(days: 7)).toIso8601String();
    final since30 = now.subtract(const Duration(days: 30)).toIso8601String();
    final today   = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final archived = await _loadRuntimeArchived();

    Future<void> safe(Future<void> Function() body) async {
      try { await body(); } catch (_) {}
    }

    // Safeguarding hub: the original code queried a non-existent table
    // `safeguarding_incidents` (which is why the console showed a 404).
    // The real table is `serious_incidents` (migration 093) and has
    // columns: incident_type, status, incident_date, service_user_id,
    // description, cqc_notified_at, police_involved etc. - but NO
    // `severity` column (we used to query it, which caused a 400).
    // We now use `status` as the priority driver and the title to
    // surface the incident_type. Other "incident-style" tables in
    // the safeguarding hub (medication_incidents, accident_logs,
    // complaints_logs) follow a similar shape and could be added later.
    await safe(() async {
      final rows = await _client.from('serious_incidents')
          .select('id, incident_type, status, incident_date, service_user_id, organisation_id, cqc_notified_at, police_involved, resolved_at')
          .gte('incident_date', since7)
          .order('incident_date', ascending: false).limit(50);
      for (final r in (rows as List)) {
        final id = 'runtime::serious_incidents::${r['id']}::new';
        if (hidden.contains(id)) continue;
        final status = (r['status'] ?? 'open').toString();
        final incidentType = (r['incident_type'] ?? 'Incident').toString();
        // No severity column - derive priority from status: an
        // unresolved/notifiable incident is high-priority, resolved
        // ones are normal.
        final priority = (status == 'resolved' || status == 'closed')
            ? 'normal'
            : (r['cqc_notified_at'] != null || r['police_involved'] == true)
                ? 'urgent'
                : 'high';
        list.add(Notification(
          id: id, userId: '', type: 'safeguarding',
          title: 'Serious incident: $incidentType',
          body: 'Status: ${status.toUpperCase()}',
          data: Map<String, dynamic>.from(r),
          priority: priority,
          read: false,
          createdAt: DateTime.tryParse(r['incident_date']?.toString() ?? '') ?? now,
        ));
      }
    });

    // Risk assessments: migration 004 creates `risk_assessments` with
    // columns id, service_user_id, assessment_date, completed_by,
    // statement_confirmed, submitted_at, pdf_url, created_at, updated_at.
    // There is NO `assessment_type` or `status` column - selecting them
    // produced a PostgREST 400. We now only project existing columns
    // and order by `submitted_at` (falling back to `assessment_date`).
    await safe(() async {
      final rows = await _client.from('risk_assessments')
          .select('id, service_user_id, assessment_date, completed_by, statement_confirmed, submitted_at, pdf_url, created_at, updated_at')
          .gte('created_at', since7)
          .order('submitted_at', ascending: false).limit(50);
      for (final r in (rows as List)) {
        final id = 'runtime::risk_assessments::${r['id']}::new';
        if (hidden.contains(id)) continue;
        final confirmed = r['statement_confirmed'] == true;
        final completedBy = r['completed_by'];
        list.add(Notification(
          id: id, userId: '', type: 'risk',
          title: confirmed
              ? 'Risk assessment submitted'
              : 'Risk assessment awaiting confirmation',
          body: completedBy != null
              ? 'Completed by staff member on ${r['assessment_date']}'
              : 'No assessor recorded',
          data: Map<String, dynamic>.from(r),
          priority: confirmed ? 'normal' : 'high',
          read: false,
          createdAt: DateTime.tryParse(r['submitted_at']?.toString() ??
                  r['assessment_date']?.toString() ??
                  '') ?? now,
        ));
      }
    });

    // Policies: the `policies` table was created by migration 048, but
    // some deployments don't have it - rather than spam the console
    // with a 404 every time the page is rebuilt, we probe once and
    // cache the result in memory. If the table is missing we skip the
    // poller entirely; new policy versions will still surface via the
    // notify_admins() trigger from migration 155.
    if (!_policiesProbed || !_policiesMissing) {
      await safe(() async {
        try {
          final rows = await _client.from('policies')
              .select('id, policy_name, version, created_at')
              .order('created_at', ascending: false).limit(20);
          _policiesProbed = true;
          _policiesMissing = false;
          for (final r in (rows as List)) {
            final id = 'runtime::policies::${r['id']}::new';
            if (hidden.contains(id)) continue;
            list.add(Notification(
              id: id, userId: '', type: 'compliance',
              title: 'New policy version: ${r['policy_name'] ?? 'Policy'}',
              body: 'Version ${r['version'] ?? '-'} published',
              data: Map<String, dynamic>.from(r),
              priority: 'low', read: false,
              createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? now,
            ));
          }
        } on PostgrestException catch (e) {
          // 404 / 42P01 = table missing - cache "missing" and never
          // query again this session. Trigger-based notification
          // system in migration 155 will still record policy inserts.
          if (e.code == '42P01' || e.code == '404' || e.code == 'PGRST116') {
            _policiesProbed = true;
            _policiesMissing = true;
          } else {
            rethrow;
          }
        }
      });
    }

    // MAR: missed doses - delegated to the SQL function
    // public.check_missed_mar_doses(p_from_date, p_to_date) which honours
    // start/end/stopped_date, days_of_week, is_prn, service_user_statuses
    // (respite/hospital/holiday) and the 2-hour-slot tolerance window.
    await safe(() async {
      final fromDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 7));
      final toDate = DateTime(now.year, now.month, now.day);
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final rows = await _client.rpc('check_missed_mar_doses', params: {
        'p_from_date': fmt(fromDate),
        'p_to_date':   fmt(toDate),
      });
      for (final r in (rows as List)) {
        final medId = r['medication_id']?.toString();
        final suId  = r['service_user_id']?.toString();
        final date  = r['administration_date']?.toString() ?? '';
        final slot  = r['scheduled_time']?.toString() ?? '';
        if (medId == null || date.isEmpty || slot.isEmpty) continue;
        final expected = (r['expected_count'] ?? 1).toString();
        final logged   = (r['logged_count']   ?? 0).toString();
        final medName  = (r['medication_name']  ?? 'Medication').toString();
        final dosage   = (r['dosage']           ?? '').toString();
        final suName   = (r['service_user_name'] ?? 'service user').toString();
        final id = 'runtime::mar_missed::$medId::$date::$slot';
        if (hidden.contains(id)) continue;
        // Build the local scheduled DateTime for proper chronological sort
        DateTime created = now;
        try {
          final parts = date.split('-');
          final tparts = slot.split(':');
          if (parts.length == 3 && tparts.length >= 2) {
            created = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]),
              int.parse(tparts[0]), int.parse(tparts[1]),
            );
          }
        } catch (_) {}
        // recent (yesterday/today) missed doses are URGENT safeguarding
        final isRecent = (now.difference(created).inDays) <= 1;
        list.add(Notification(
          id: id, userId: '', type: 'mar_missed',
          title: 'Missed MAR: $medName for $suName',
          body: 'Expected $dosage at $slot on $date — not logged ($logged/$expected)',
          data: {
            'medication_id': medId,
            'service_user_id': suId,
            'administration_date': date,
            'scheduled_time': slot,
            'medication_name': medName,
            'service_user_name': suName,
            'dosage': dosage,
            'expected_count': expected,
            'logged_count': logged,
            'deduplication_key': id,
          },
          priority: isRecent ? 'urgent' : 'high',
          read: false,
          createdAt: created,
        ));
      }
    });

    await safe(() async {
      final rows = await _client.from('routes')
          .select('id, route_date, status, carer_id, second_carer_id')
          .gte('route_date', today)
          .lte('route_date', now.add(const Duration(days: 7)).toIso8601String())
          .limit(50);
      for (final r in (rows as List)) {
        if (r['carer_id'] != null) continue;
        final id = 'runtime::routes::${r['id']}::unassigned';
        if (hidden.contains(id)) continue;
        list.add(Notification(
          id: id, userId: '', type: 'route',
          title: 'Route on ${r['route_date']?.toString().substring(0, 10) ?? '-'} has no carer',
          body: 'Status: ${r['status'] ?? '-'}${r['second_carer_id'] != null ? ' (2nd carer: assigned)' : ''}',
          data: Map<String, dynamic>.from(r),
          priority: 'high', read: false,
          createdAt: DateTime.tryParse(r['route_date']?.toString() ?? '') ?? now,
        ));
      }
    });

    await safe(() async {
      final rows = await _client.from('shifts')
          .select('id, scheduled_date, status, carer_id, service_user_id, client_organisation_id')
          .eq('status', 'cancelled')
          .gte('scheduled_date', since7)
          .order('scheduled_date', ascending: false).limit(50);
      for (final r in (rows as List)) {
        final id = 'runtime::shifts::${r['id']}::cancelled';
        if (hidden.contains(id)) continue;
        list.add(Notification(
          id: id, userId: '', type: 'shift',
          title: 'Shift cancelled on ${r['scheduled_date']?.toString().substring(0, 10) ?? '-'}',
          body: 'Shift ${r['id']?.toString().substring(0, 8) ?? '-'} was cancelled',
          data: Map<String, dynamic>.from(r),
          priority: 'normal', read: false,
          createdAt: DateTime.tryParse(r['scheduled_date']?.toString() ?? '') ?? now,
        ));
      }
    });

    // Service-user away status (respite / hospital / holiday).
    // The actual table is `service_user_statuses` (plural) created by
    // migration 144, with columns: status_type, started_at, ended_at,
    // reason. The old query referenced the singular table and
    // start_date/end_date/notes which never existed -> 404.
    await safe(() async {
      final rows = await _client.from('service_user_statuses')
          .select('id, service_user_id, status_type, started_at, ended_at, reason')
          .order('started_at', ascending: false).limit(50);
      for (final r in (rows as List)) {
        final id = 'runtime::service_user_status::${r['id']}::new';
        if (hidden.contains(id)) continue;
        final status = (r['status_type'] ?? 'status').toString().toUpperCase();
        list.add(Notification(
          id: id, userId: '', type: 'hospital',
          title: '$status declared',
          body: r['reason']?.toString() ??
              'Service user status changed',
          data: Map<String, dynamic>.from(r),
          priority: 'normal', read: false,
          createdAt: DateTime.tryParse(r['started_at']?.toString() ?? '') ?? now,
        ));
      }
    });

    await safe(() async {
      final rows = await _client.from('payroll_history')
          .select('id, staff_id, staff_name, period_start, period_end, regular_pay, status, created_at')
          .eq('status', 'processed')
          .gte('created_at', since30)
          .order('created_at', ascending: false).limit(50);
      for (final r in (rows as List)) {
        final id = 'runtime::payroll_history::${r['id']}::processed';
        if (hidden.contains(id)) continue;
        final amount = (r['regular_pay'] ?? 0).toString();
        list.add(Notification(
          id: id, userId: '', type: 'payroll',
          title: 'Payslip generated: ${r['staff_name'] ?? '-'}',
          body: 'GBP $amount for ${r['period_start']} -> ${r['period_end']}',
          data: Map<String, dynamic>.from(r),
          priority: 'low', read: false,
          createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? now,
        ));
      }
    });

    await safe(() async {
      final rows = await _client.from('invoices')
          .select('id, invoice_number, status, total_amount, due_date, created_at')
          .gte('created_at', since30)
          .order('created_at', ascending: false).limit(50);
      for (final r in (rows as List)) {
        final status = r['status']?.toString() ?? '';
        if (status != 'paid' && status != 'overdue') continue;
        final id = 'runtime::invoices::${r['id']}::$status';
        if (hidden.contains(id)) continue;
        list.add(Notification(
          id: id, userId: '', type: 'invoice',
          title: 'Invoice ${r['invoice_number'] ?? r['id']?.toString().substring(0, 8) ?? '-'} $status',
          body: 'GBP ${r['total_amount']?.toString() ?? '0'} - due ${r['due_date']?.toString().substring(0, 10) ?? '-'}',
          data: Map<String, dynamic>.from(r),
          priority: status == 'overdue' ? 'high' : 'normal', read: false,
          createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? now,
        ));
      }
    });

    // Disputed / overdue visits. The route_visits table (migration 137)
// has NO disputed, sign_off_status or dispute_reason columns yet -
// those fields were planned but not implemented. To stay honest with
// the schema we surface "visits that were scheduled but never completed"
// within the past 7 days instead. When the disputed columns are added
// in a future migration, switch back to `.eq('disputed', true)`.
    await safe(() async {
      final rows = await _client.from('route_visits')
          .select('id, visit_date, status, service_user_id, route_id')
          .eq('status', 'scheduled')
          .lt('visit_date', today)
          .gte('visit_date', since7)
          .order('visit_date', ascending: false)
          .limit(50);
      for (final r in (rows as List)) {
        final id = 'runtime::route_visits::${r['id']}::uncompleted';
        if (hidden.contains(id)) continue;
        list.add(Notification(
          id: id, userId: '', type: 'visit',
          title: 'Uncompleted visit on ${r['visit_date']?.toString().substring(0, 10) ?? '-'}',
          body: 'Visit on route was scheduled but never marked complete',
          data: Map<String, dynamic>.from(r),
          priority: 'high', read: false,
          createdAt: DateTime.tryParse(r['visit_date']?.toString() ?? '') ?? now,
        ));
      }
    });

    // Carers (migration 001 schema). The real column is `dbs_expiry_date`,
// NOT `dbs_check_date`. We flag two separate concerns:
//   1. carers added in the last 30 days whose is_active is still false
//      (haven't completed onboarding)
//   2. carers whose dbs_expiry_date falls within the next 30 days
//      (DBS renewal due)
    await safe(() async {
      final rows = await _client.from('carers')
          .select('id, name, is_active, dbs_expiry_date, created_at')
          .gte('created_at', since30)
          .order('created_at', ascending: false).limit(50);
      for (final r in (rows as List)) {
        if (r['is_active'] == true) continue;
        final id = 'runtime::carers::${r['id']}::inactive';
        if (hidden.contains(id)) continue;
        final dbs = r['dbs_expiry_date']?.toString();
        list.add(Notification(
          id: id, userId: '', type: 'carer',
          title: 'New carer awaiting verification: ${r['name'] ?? '-'}',
          body: dbs != null && dbs.isNotEmpty
              ? 'DBS expires: ${dbs.substring(0, 10)}'
              : 'No DBS expiry on record',
          data: Map<String, dynamic>.from(r),
          priority: 'normal', read: false,
          createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? now,
        ));
      }
    });

    await safe(() async {
      // DBS renewal due in next 30 days.
      final limit30 = now.add(const Duration(days: 30)).toIso8601String();
      final rows = await _client.from('carers')
          .select('id, name, is_active, dbs_expiry_date')
          .eq('is_active', true)
          .lte('dbs_expiry_date', limit30)
          .gte('dbs_expiry_date', today)
          .limit(50);
      for (final r in (rows as List)) {
        final id = 'runtime::carers::${r['id']}::dbs_due';
        if (hidden.contains(id)) continue;
        list.add(Notification(
          id: id, userId: '', type: 'carer',
          title: 'DBS expiring: ${r['name'] ?? '-'}',
          body: 'DBS expires ${r['dbs_expiry_date']?.toString().substring(0, 10)}',
          data: Map<String, dynamic>.from(r),
          priority: 'high', read: false,
          createdAt: now,
        ));
      }
    });

    await safe(() async {
      final rows = await _client.from('leave_requests')
          .select('id, staff_id, leave_type, start_date, end_date, status, created_at')
          .eq('status', 'pending')
          .order('created_at', ascending: false).limit(50);
      for (final r in (rows as List)) {
        final id = 'runtime::leave_requests::${r['id']}::pending';
        if (hidden.contains(id)) continue;
        list.add(Notification(
          id: id, userId: '', type: 'leave',
          title: 'Leave request: ${r['leave_type'] ?? '-'}',
          body: '${r['start_date']?.toString().substring(0, 10) ?? '-'} -> ${r['end_date']?.toString().substring(0, 10) ?? '-'}',
          data: Map<String, dynamic>.from(r),
          priority: 'normal', read: false,
          createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? now,
        ));
      }
    });

    // Apply runtime archive flags last so the archive state isn't lost
    // when the source rows are re-queried.
    for (var i = 0; i < list.length; i++) {
      if (archived.contains(list[i].id)) {
        list[i] = list[i].copyWith(archivedAt: DateTime.now());
      }
    }
    // Store in the cache so subsequent refreshes (e.g. after a tap)
    // don't re-fire every poller query.
    _runtimeCache = List<Notification>.from(list);
    _runtimeCacheAt = DateTime.now();
    _runtimeCacheHidden = Set<String>.from(hidden);
    return list;
  }

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  /// Invalidate the runtime notification cache. Call this after any
  /// mutation (mark read, archive, delete) so the next refresh picks
  /// up the new state instead of the stale cached one.
  static void invalidateRuntimeCache() {
    _runtimeCache = null;
    _runtimeCacheAt = null;
    _runtimeCacheHidden = const <String>{};
  }

  Future<List<Notification>> _safeFetchStored({
    bool? unreadOnly,
    String? type,
    String? priority,
    int limit = 200,
    int offset = 0,
    bool archivedOnly = false,
    bool includeArchived = false,
  }) async {
    try {
      var query = _client.from('notifications').select();
      if (unreadOnly == true) query = query.eq('read', false);
      if (type != null) query = query.eq('type', type);
      if (priority != null) query = query.eq('priority', priority);
      if (archivedOnly) {
        // archived_at IS NOT NULL
        query = query.not('archived_at', 'is', null);
      } else if (!includeArchived) {
        // archived_at IS NULL  (filter out archived by default)
        query = query.isFilter('archived_at', null);
      }
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (response as List).map((j) => Notification.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Set<String>> _loadHiddenIds() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return <String>{};
      final raw = user.userMetadata?[_kHiddenKey];
      if (raw is List) return raw.map((e) => e.toString()).toSet();
      return <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _hideRuntime(String id) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final hidden = await _loadHiddenIds();
      hidden.add(id);
      // gotrue 2.18+ API: updateUser is on the auth client, not on User.
      await _client.auth.updateUser(
        UserAttributes(data: <String, dynamic>{_kHiddenKey: hidden.toList()}),
      );
    } catch (_) {}
  }

  Future<Set<String>> _loadRuntimeArchived() async {
    return _loadIdSet(_kArchivedKey);
  }

  Future<Set<String>> _loadIdSet(String key) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return <String>{};
      final raw = user.userMetadata?[key];
      if (raw is List) return raw.map((e) => e.toString()).toSet();
      return <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _setRuntimeFlag(String id, {required bool archived}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final set = await _loadRuntimeArchived();
      if (archived) {
        set.add(id);
      } else {
        set.remove(id);
      }
      await _client.auth.updateUser(
        UserAttributes(data: <String, dynamic>{_kArchivedKey: set.toList()}),
      );
    } catch (_) {}
  }

  // Severity -> priority mapping. Currently unused because the only
  // table we polled for severity (safeguarding_incidents) doesn't
  // exist; serious_incidents has no severity column. Kept here for
  // any future poller that DOES query a severity-bearing table
  // (e.g. medication_incidents).
  // ignore: unused_element
  String _severityToPriority(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
      case 'death':
      case 'serious_injury':
        return 'urgent';
      case 'high':
      case 'major':
      case 'abuse':
        return 'high';
      case 'medium':
      case 'moderate':
        return 'normal';
      default:
        return 'low';
    }
  }

  Future<Notification> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String priority = 'normal',
    bool actionRequired = false,
    String? actionUrl,
    String? actionLabel,
    DateTime? expiresAt,
  }) async {
    try {
      final orgId = await _getOrganisationId();
      final response = await _client.from('notifications').insert({
        'user_id': userId, 'type': type, 'title': title, 'body': body,
        'data': data, 'priority': priority, 'action_required': actionRequired,
        'action_url': actionUrl, 'action_label': actionLabel,
        'expires_at': expiresAt?.toIso8601String(),
        'created_by': _client.auth.currentUser?.id,
        'organisation_id': orgId,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      return Notification.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<List<Notification>> getNotificationsByType(String type) => getNotifications(type: type);
  Future<List<Notification>> getUrgentNotifications() => getNotifications(priority: 'urgent');

  Future<String?> _getOrganisationId() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final response = await _client.from('profiles')
          .select('organisation_id').eq('id', userId).maybeSingle();
      return response?['organisation_id']?.toString();
    } catch (_) { return null; }
  }
}