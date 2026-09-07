import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/route_visit.dart';

class RouteService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Returns the user's organisation context.
  /// ADMIN/STAFF users have `organisation_id` set (client_organisation_id = NULL).
  /// CLIENT-app users have `client_organisation_id` set.
  /// The context tells the service which column to use for ORG-SCOPING.
  Future<_OrgContext> _getOrgContext() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const _OrgContext();

    try {
      final profile = await _client
          .from('profiles')
          .select('organisation_id, client_organisation_id')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return const _OrgContext();

      return _OrgContext(
        organisationId: profile['organisation_id'] as String?,
        clientOrganisationId: profile['client_organisation_id'] as String?,
      );
    } catch (e) {
      return const _OrgContext();
    }
  }

  /// Builds the org column/value to set on INSERT.
  /// Admin/staff → organisation_id; client-app → client_organisation_id.
  Future<Map<String, dynamic>> _orgInsertColumns() async {
    final ctx = await _getOrgContext();
    final orgId = ctx.organisationId;
    if (orgId != null && orgId.isNotEmpty) {
      return {'organisation_id': orgId};
    }
    return {'client_organisation_id': ctx.clientOrganisationId};
  }

  /// Applies the user's org-scoping filter to a query aimed at a route table
  /// (routes / route_visits / route_change_log). Admin/staff scope by
  /// organisation_id; client-app scopes by client_organisation_id.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _scopeRouteQuery(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    _OrgContext ctx,
  ) {
    final orgId = ctx.organisationId;
    final clientOrgId = ctx.clientOrganisationId;
    if (orgId != null) {
      return query.eq('organisation_id', orgId);
    }
    if (clientOrgId != null) {
      return query.eq('client_organisation_id', clientOrgId);
    }
    throw Exception('No organisation context');
  }

  /// Gets all active service users.
  /// Pulls from public.service_users — no org filter is applied because
  /// RLS handles row-level security across both organisation_id and
  /// client_organisation_id. Also removes the is_active filter in case the
  /// column is missing or all records have it set to false.
  Future<List<Map<String, dynamic>>> getActiveServiceUsers() async {
    final response = await _client
        .from('service_users')
        .select()
        .order('name', ascending: true);

    final users = (response as List).cast<Map<String, dynamic>>();
    // Filter is_active in Dart in case the column doesn't exist in some schemas
    return users.where((u) => u['is_active'] != false).toList();
  }

  /// Gets all active service users WITH their weekly call timetable from
  /// public.service_user_weekly_calls.
  /// Returns list of maps: id, name, is_active, weekly_calls
  /// (weekday 1..7 -> [{time, duration_minutes}]).
  Future<List<Map<String, dynamic>>> getServiceUsersWithCalls() async {
    final usersResponse = await _client
        .from('service_users')
        .select('id, name, is_active')
        .order('name', ascending: true);
    final users = (usersResponse as List).cast<Map<String, dynamic>>();

    // Weekly timetable (best-effort; empty if the table isn't applied yet).
    final weeklyByUser = <String, Map<int, List<Map<String, dynamic>>>>{};
    try {
      final weeklyResponse = await _client
          .from('service_user_weekly_calls')
          .select('service_user_id, weekday, call_times');
      for (final row in (weeklyResponse as List).cast<Map<String, dynamic>>()) {
        final suid = row['service_user_id'] as String?;
        final weekday = (row['weekday'] as num?)?.toInt();
        if (suid == null || weekday == null) continue;
        final slots = <Map<String, dynamic>>[];
        final raw = row['call_times'];
        if (raw is List) {
          for (final e in raw) {
            if (e is Map) {
              slots.add({
                'time': e['time']?.toString() ?? '',
                'duration_minutes': (e['duration_minutes'] as num?)?.toInt() ?? 60,
              });
            } else if (e is String) {
              slots.add({'time': e, 'duration_minutes': 60});
            }
          }
        }
        (weeklyByUser[suid] ??= <int, List<Map<String, dynamic>>>{})[weekday] = slots;
      }
    } catch (_) {
      // Table not applied yet -> leave weekly empty.
    }

    final result = <Map<String, dynamic>>[];
    for (final user in users) {
      final userId = user['id'] as String;
      final weekly = weeklyByUser[userId] ?? <int, List<Map<String, dynamic>>>{};
      result.add({
        'id': userId,
        'name': user['name'],
        'is_active': user['is_active'],
        'weekly_calls': weekly,
        'has_calls': weekly.isNotEmpty,
      });
    }
    return result;
  }

  /// Gets all available carers for the current organisation.
  Future<List<Map<String, dynamic>>> getCarers() async {
    final response = await _client
        .from('carers')
        .select('id, name, employee_number, job_role, photo_url')
        .eq('is_active', true)
        .order('name', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  // ------------------------------------------------------------
  // ROUTE VISITS — the core schedule
  // ------------------------------------------------------------

  /// Gets all route visits for a given date.
  Future<List<RouteVisit>> getRouteVisitsForDate(DateTime date) async {
    final ctx = await _getOrgContext();

    final dateStr = date.toIso8601String().split('T')[0];

    var query = _client
        .from('route_visits')
        .select('*, service_users(name), carers(name), routes(name)')
        .eq('visit_date', dateStr)
        .not('status', 'eq', 'cancelled');

    query = _scopeRouteQuery(query, ctx);

    final response = await query.order('visit_time', ascending: true);
    return (response as List)
        .map((json) => RouteVisit.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Gets the route containers for a given date.
  Future<List<Map<String, dynamic>>> getRoutesForDate(DateTime date) async {
    final ctx = await _getOrgContext();

    final dateStr = date.toIso8601String().split('T')[0];

    var query = _client
        .from('routes')
        .select('*');

    query = _scopeRouteQuery(query, ctx);

    final response = await query.order('name', ascending: true);
    final all = (response as List).cast<Map<String, dynamic>>();

    // One-off routes for this date + recurring routes active on/before it
    // (permanent until deleted), so the day-by-day schedule still shows them.
    return all.where((r) {
      if (r['is_recurring'] == true) {
        final startsOn = r['starts_on'] as String?;
        if (startsOn != null) return startsOn.compareTo(dateStr) <= 0;
      }
      return r['route_date'] == dateStr;
    }).toList();
  }

  Future<void> _persistRouteMembers(String routeId, List<Map<String, dynamic>> visits) async {
    final ids = visits
        .map((v) => v['service_user_id'] as String)
        .toSet()
        .toList();
    try {
      await _client.from('route_service_users').delete().eq('route_id', routeId);
      for (final sid in ids) {
        final data = <String, dynamic>{
          'route_id': routeId,
          'service_user_id': sid,
          ...await _orgInsertColumns(),
        };
        await _client.from('route_service_users').insert(data);
      }
    } catch (_) {
      // Membership is best-effort; if the table isn't applied yet, ignore.
    }
  }

  Future<List<Map<String, dynamic>>> getRouteMembers(String routeId) async {
    try {
      final data = await _client
          .from('route_service_users')
          .select('route_id, service_user_id, service_users(name)')
          .eq('route_id', routeId);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Generates the day's visits for RECURRING routes from their membership
  /// (service users) + each member's weekly timetable + the route's carer.
  /// One-off / already-stored visits are NOT duplicated here; the caller
  /// merges with stored `route_visits` (dedupe by route+user+date+time).
  Future<List<RouteVisit>> getGeneratedVisitsForDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final weekday = date.weekday;
      final generated = <RouteVisit>[];

      final routes = await getRoutesForDate(date);
      final recurring = routes.where((r) => r['is_recurring'] == true).toList();
      if (recurring.isEmpty) return generated;

      final routeIds = recurring.map((r) => r['id'] as String).toList();

      // 1. Load membership for those routes.
      final membersResp = await _client
          .from('route_service_users')
          .select('route_id, service_user_id, service_users(name)')
          .inFilter('route_id', routeIds);
      final membersByRoute = <String, List<Map<String, dynamic>>>{};
      final memberSuIds = <String>{};
      for (final m in (membersResp as List).cast<Map<String, dynamic>>()) {
        final rid = m['route_id'] as String?;
        final sid = m['service_user_id'] as String?;
        if (rid != null && sid != null) {
          final suName = (m['service_users'] as Map<String, dynamic>?)?['name'] as String?;
          (membersByRoute[rid] ??= []).add({'service_user_id': sid, 'name': suName ?? 'Unknown'});
          memberSuIds.add(sid);
        }
      }
      if (memberSuIds.isEmpty) return generated;

      // 2. Load each member's weekly timetable.
      final weeklyResp = await _client
          .from('service_user_weekly_calls')
          .select('service_user_id, weekday, call_times')
          .inFilter('service_user_id', memberSuIds.toList());
      final weeklySlots = <String, Map<int, List<Map<String, dynamic>>>>{};
      for (final row in (weeklyResp as List).cast<Map<String, dynamic>>()) {
        final sid = row['service_user_id'] as String?;
        final wd = (row['weekday'] as num?)?.toInt();
        if (sid == null || wd == null) continue;
        final slots = <Map<String, dynamic>>[];
        final raw = row['call_times'];
        if (raw is List) {
          for (final e in raw) {
            if (e is Map) {
              slots.add({
                'time': e['time']?.toString() ?? '',
                'duration_minutes': (e['duration_minutes'] as num?)?.toInt() ?? 60,
              });
            } else if (e is String) {
              slots.add({'time': e, 'duration_minutes': 60});
            }
          }
        }
        (weeklySlots[sid] ??= <int, List<Map<String, dynamic>>>{})[wd] = slots;
      }

      // 3. Build a RouteVisit for every member call on this weekday.
      for (final route in recurring) {
        final rid = route['id'] as String;
        final routeName = route['name'] as String? ?? 'Untitled Route';
        final routeCarrier = route['carer_id'] as String?;
        for (final m in membersByRoute[rid] ?? const <Map<String, dynamic>>[]) {
          final suId = m['service_user_id'] as String;
          final slots = weeklySlots[suId]?[weekday] ?? const <Map<String, dynamic>>[];
          var sortOrder = 1;
          for (final slot in slots) {
            final parts = (slot['time'] as String? ?? '09:00').split(':');
            final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 9) : 9;
            final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
            final duration = (slot['duration_minutes'] as num?)?.toInt() ?? 60;
            final dt = DateTime(date.year, date.month, date.day, hour, minute);
            generated.add(RouteVisit.fromJson({
              'id': 'generated-${rid}-${suId}-${sortOrder}',
              'route_id': rid,
              'service_user_id': suId,
              'carer_id': routeCarrier,
              'visit_date': dateStr,
              'visit_time': dt.toIso8601String(),
              'duration_minutes': duration,
              'status': 'scheduled',
              'requires_two_carers': false,
              'sort_order': sortOrder,
              'service_users': {'name': m['name']},
              'routes': {'name': routeName},
              'carers': null,
            }));
            sortOrder++;
          }
        }
      }
      return generated;
    } catch (_) {
      return [];
    }
  }

  /// Renames a route cluster.
  Future<void> renameRoute(String routeId, String newName) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    await _client.from('routes').update({'name': newName}).eq('id', routeId);

    await _logChange(
      ctx: ctx,
      routeId: routeId,
      changeType: 'route_created',
      description: 'Route renamed to "$newName"',
      oldValue: {'name': null},
      newValue: {'name': newName},
    );
  }

  /// Assigns (or clears) a carer to a route cluster for that day AND cascades
  /// the change to all non-overridden visits (visits whose carer matches the
  /// old route carer or is NULL). Visits that were manually overridden to a
  /// different carer via the per-visit dropdown are left untouched.
  Future<void> assignCarerToRouteCluster(String routeId, String? carerId) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    // 1. Read the current route carer (so we know what was "default").
    final current = await _client
        .from('routes')
        .select('carer_id')
        .eq('id', routeId)
        .maybeSingle();
    final oldCarerId = (current != null) ? (current['carer_id'] as String?) : null;

    // 2. Update the route container.
    await _client.from('routes').update({'carer_id': carerId}).eq('id', routeId);

    // 3. Cascade to visits that were NOT manually overridden.
    //    A visit is "overridden" if its carer_id differs from the old
    //    route carer (and is not NULL because the old route was unassigned).
    //    Rule: update visits whose carer_id IS NULL OR matches the old route carer.

    // Fetch all visits for this route, filter to non-overridden, then update.
    final visits = await _client
        .from('route_visits')
        .select('id, carer_id')
        .eq('route_id', routeId);

    final toUpdate = <String>[];
    for (final v in (visits as List).cast<Map<String, dynamic>>()) {
      final vCarer = v['carer_id'] as String?;
      final isOverridden = vCarer != null && vCarer != oldCarerId;
      if (!isOverridden) {
        toUpdate.add(v['id'] as String);
      }
    }

    if (toUpdate.isNotEmpty) {
      for (final visitId in toUpdate) {
        await _client
            .from('route_visits')
            .update({'carer_id': carerId})
            .eq('id', visitId);
      }
    }

    // 4. Log the route-level change with accurate old/new values.
    await _logChange(
      ctx: ctx,
      routeId: routeId,
      changeType: carerId != null ? 'carer_assigned' : 'carer_unassigned',
      description: carerId != null
          ? 'Carer assigned to route cluster (cascaded to ${toUpdate.length} visit(s))'
          : 'Carer unassigned from route cluster',
      oldValue: {'carer_id': oldCarerId},
      newValue: {'carer_id': carerId},
    );
  }

  /// Sets or clears the DRIVER flag on a route cluster.
  /// The driver is the carer responsible for the vehicle/mileage.
  Future<void> setRouteDriverFlag(String routeId, bool isDriver) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    await _client.from('routes').update({'is_driver': isDriver}).eq('id', routeId);

    await _logChange(
      ctx: ctx,
      routeId: routeId,
      changeType: 'carer_assigned',
      description: isDriver ? 'Carer flagged as driver' : 'Driver flag removed',
      oldValue: {'is_driver': !isDriver},
      newValue: {'is_driver': isDriver},
    );
  }

  /// Assigns (or clears) a SECOND carer to a route cluster.
  Future<void> assignSecondCarerToRouteCluster(String routeId, String? carerId) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    await _client.from('routes').update({'second_carer_id': carerId}).eq('id', routeId);

    await _logChange(
      ctx: ctx,
      routeId: routeId,
      changeType: 'carer_assigned',
      description: carerId != null ? 'Second carer assigned to route' : 'Second carer unassigned from route',
      oldValue: {'second_carer_id': null},
      newValue: {'second_carer_id': carerId},
    );
  }

  /// Sets the driver mode: 'primary' | 'second' | 'both'
  /// (who was driving — primary carer, second carer, or both drove).
  Future<void> setRouteDriverMode(String routeId, String mode) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    await _client.from('routes').update({'driver_mode': mode}).eq('id', routeId);

    await _logChange(
      ctx: ctx,
      routeId: routeId,
      changeType: 'carer_assigned',
      description: 'Driver mode set to $mode',
      oldValue: {'driver_mode': null},
      newValue: {'driver_mode': mode},
    );
  }

  /// Gets a single route cluster with all its visits (for editing).
  Future<Map<String, dynamic>?> getRouteWithVisits(String routeId) async {
    final ctx = await _getOrgContext();

    var query = _client
        .from('routes')
        .select('*, route_visits(*, service_users(name))')
        .eq('id', routeId);

    query = _scopeRouteQuery(query, ctx);

    return await query.maybeSingle();
  }

  /// Updates a route cluster and its visits (add/remove/reorder/retime).
  Future<void> updateRouteWithVisits({
    required String routeId,
    required String name,
    String? carerId,
    String? secondCarerId,
    bool isDriver = false,
    String driverMode = 'primary',
    required List<Map<String, dynamic>> visits, // [{id?, service_user_id, visit_time, duration_minutes, notes}]
  }) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    // 1. Update route container
    await _client.from('routes').update({
      'name': name,
      'carer_id': carerId,
      'second_carer_id': secondCarerId,
      'is_driver': isDriver,
      'driver_mode': driverMode,
    }).eq('id', routeId);

    // 2. Get existing visit IDs
    final existing = await _client
        .from('route_visits')
        .select('id')
        .eq('route_id', routeId);

    final existingIds = (existing as List)
        .map((e) => e['id'] as String)
        .toSet();

    final newIds = visits
        .where((v) => v['id'] != null && (v['id'] as String).isNotEmpty)
        .map((v) => v['id'] as String)
        .toSet();

    // Delete visits no longer present
    final toDelete = existingIds.difference(newIds);
    for (final id in toDelete) {
      await _client.from('route_visits').delete().eq('id', id);
    }

    // Insert/update visits
    var sortOrder = 1;
    for (final v in visits) {
      final visitId = v['id'] as String?;
      final visitData = <String, dynamic>{
        'route_id': routeId,
        'service_user_id': v['service_user_id'] as String,
        'visit_time': (v['visit_time'] as DateTime).toIso8601String(),
        'visit_date': (v['visit_time'] as DateTime).toIso8601String().split('T')[0],
        'duration_minutes': v['duration_minutes'] as int? ?? 60,
        'sort_order': sortOrder,
        'notes': v['notes'] as String?,
      };

      if (visitId != null && visitId.isNotEmpty && existingIds.contains(visitId)) {
        await _client.from('route_visits').update(visitData).eq('id', visitId);
      } else {
        visitData.addAll(await _orgInsertColumns());
        await _client.from('route_visits').insert(visitData);
      }
      sortOrder++;
    }

    await _logChange(
      ctx: ctx,
      routeId: routeId,
      changeType: 'route_created',
      description: 'Route "$name" updated with ${visits.length} visit(s)',
    );

    // 4. Persist the route's permanent membership (service users).
    await _persistRouteMembers(routeId, visits);
  }

  /// Creates a route container + one (or more) visits.
  Future<void> createRouteWithVisits({
    required String name,
    required DateTime routeDate,
    required List<Map<String, dynamic>> visits, // [{service_user_id, visit_time, duration_minutes, carer_id, notes, requires_two_carers}]
    String? carerId,
    bool isRecurring = true,
  }) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    // 1. Create the route container
    final dateStr = routeDate.toIso8601String().split('T')[0];
    final routeInsert = <String, dynamic>{
      'name': name,
      'route_date': dateStr,
      'status': 'scheduled',
      'is_recurring': isRecurring,
      'starts_on': dateStr,
      'ends_on': null, // indefinite (ongoing)
      ...await _orgInsertColumns(),
    };
    final routeResp = await _client.from('routes').insert(routeInsert).select('id').single();

    final routeId = routeResp['id'] as String;

    // 2. Create visits
    var sortOrder = 1;
    for (final v in visits) {
      await _insertVisit(
        ctx: ctx,
        routeId: routeId,
        serviceUserId: v['service_user_id'] as String,
        carerId: v['carer_id'] as String? ?? carerId,
        visitDate: routeDate,
        visitTime: v['visit_time'] as DateTime,
        durationMinutes: v['duration_minutes'] as int? ?? 60,
        requiresTwoCarers: v['requires_two_carers'] as bool? ?? false,
        notes: v['notes'] as String?,
        sortOrder: sortOrder,
      );
      sortOrder++;
    }

    // 3. Log route creation
    await _logChange(
      ctx: ctx,
      routeId: routeId,
      changeType: 'route_created',
      description: 'Route "$name" created with ${visits.length} visit(s)',
    );

    // 4. Persist the route's permanent membership (service users).
    await _persistRouteMembers(routeId, visits);
  }

  /// Creates a single route container with no visits (or for a single user).
  Future<void> createRoute({
    required String serviceUserId,
    required DateTime proposedStartTime,
    required DateTime proposedEndTime,
    int callNumber = 1,
    String? carerId,
    bool respite = false,
    String? notes,
  }) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    // Create a route container
    final routeName = 'Route ${proposedStartTime.toIso8601String().split('T')[0]}';
    final routeInsert = <String, dynamic>{
      'name': routeName,
      'route_date': proposedStartTime.toIso8601String().split('T')[0],
      'service_user_id': serviceUserId,
      'proposed_start_time': proposedStartTime.toIso8601String(),
      'proposed_end_time': proposedEndTime.toIso8601String(),
      'call_number': callNumber,
      'respite': respite,
      'status': 'scheduled',
      'notes': notes,
      ...await _orgInsertColumns(),
    };
    final routeResp = await _client.from('routes').insert(routeInsert).select('id').single();

    final routeId = routeResp['id'] as String;

    // Create a visit in route_visits
    await _insertVisit(
      ctx: ctx,
      routeId: routeId,
      serviceUserId: serviceUserId,
      carerId: carerId,
      visitDate: proposedStartTime,
      visitTime: proposedStartTime,
      durationMinutes: proposedEndTime.difference(proposedStartTime).inMinutes,
      respite: respite,
      notes: notes,
    );

    await _logChange(
      ctx: ctx,
      routeId: routeId,
      changeType: 'route_created',
      description: 'Route created for service user with ${proposedEndTime.difference(proposedStartTime).inMinutes} minute visit',
    );
  }

  /// Builds routes & visits for all active service users based on their
  /// visit preferences stored in the `care_plan` JSON column.
  Future<int> buildRoutesFromPreferences({
    DateTime? fromDate,
  }) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    final users = await getActiveServiceUsers();
    var createdCount = 0;
    final startDate = fromDate ?? DateTime.now();

    for (final user in users) {
      final carePlan = user['care_plan'] as Map<String, dynamic>?;
      final visitPrefs = carePlan?['visit_preferences'] as Map<String, dynamic>?;
      if (visitPrefs == null) continue;

      final preferredTime = visitPrefs['preferred_time'] as String?;
      final durationMinutes = (visitPrefs['duration_minutes'] as num?)?.toInt() ?? 60;
      final visitDays = (visitPrefs['visit_days'] as List?)?.cast<String>() ?? [];
      final requiresTwoCarers =
          visitPrefs['requires_two_carers'] as bool? ?? false;
      final notes = visitPrefs['notes'] as String?;

      for (final day in visitDays) {
        final nextDate = _getNextDayOfWeek(day, startDate);
        final startTime = _combineDateAndTime(nextDate, preferredTime);
        if (startTime == null) continue;
        final endTime = startTime.add(Duration(minutes: durationMinutes));

        // Check for an existing visit for this user on this date/time
        var existingQuery = _client
            .from('route_visits')
            .select('id')
            .eq('service_user_id', user['id'] as String)
            .gte('visit_time', startTime.toIso8601String())
            .lte('visit_time', endTime.toIso8601String());

        existingQuery = _scopeRouteQuery(existingQuery, ctx);
        final existing = await existingQuery.maybeSingle();

        if (existing != null) {
          // Update the existing visit
          await _client.from('route_visits').update({
            'duration_minutes': durationMinutes,
            'status': 'scheduled',
            'notes': notes,
            'requires_two_carers': requiresTwoCarers,
          }).eq('id', existing['id'] as String);
        } else {
          // Find or create a route container for this day
          final dateStr = nextDate.toIso8601String().split('T')[0];
          var existingRouteQuery = _client
              .from('routes')
              .select('id')
              .eq('route_date', dateStr);

          existingRouteQuery = _scopeRouteQuery(existingRouteQuery, ctx);
          final existingRoute = await existingRouteQuery.maybeSingle();

          String routeId;
          if (existingRoute != null) {
            routeId = existingRoute['id'] as String;
          } else {
            final routeInsert = <String, dynamic>{
              'name': 'Route $dateStr',
              'route_date': dateStr,
              'status': 'scheduled',
              ...await _orgInsertColumns(),
            };
            final routeResp = await _client.from('routes').insert(routeInsert).select('id').single();
            routeId = routeResp['id'] as String;
          }

          await _insertVisit(
            ctx: ctx,
            routeId: routeId,
            serviceUserId: user['id'] as String,
            visitDate: nextDate,
            visitTime: startTime,
            durationMinutes: durationMinutes,
            requiresTwoCarers: requiresTwoCarers,
            notes: notes,
          );
          createdCount++;
        }
      }
    }

    return createdCount;
  }

  // ------------------------------------------------------------
  // VISIT OPERATIONS with change logging
  // ------------------------------------------------------------

  /// Updates a visit's time and duration, logging the change.
  Future<void> updateVisitTime({
    required String visitId,
    required DateTime newTime,
    required int durationMinutes,
  }) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    // Fetch old value for the log
    final old = await _client
        .from('route_visits')
        .select('visit_time, duration_minutes')
        .eq('id', visitId)
        .single();

    final newTimeStr = newTime.toIso8601String();

    await _client.from('route_visits').update({
      'visit_time': newTimeStr,
      'duration_minutes': durationMinutes,
      'visit_date': newTime.toIso8601String().split('T')[0],
    }).eq('id', visitId);

    await _logChange(
      ctx: ctx,
      visitId: visitId,
      changeType: 'time_adjusted',
      description: 'Visit time adjusted',
      oldValue: {
        'visit_time': old['visit_time'],
        'duration_minutes': old['duration_minutes'],
      },
      newValue: {
        'visit_time': newTimeStr,
        'duration_minutes': durationMinutes,
      },
    );
  }

  /// Assigns (or clears) a carer on a visit, logging the change.
  Future<void> assignCarerToVisit(String visitId, String? carerId) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    final old = await _client
        .from('route_visits')
        .select('carer_id')
        .eq('id', visitId)
        .single();

    await _client.from('route_visits').update({'carer_id': carerId}).eq('id', visitId);

    await _logChange(
      ctx: ctx,
      visitId: visitId,
      changeType: carerId != null ? 'carer_assigned' : 'carer_unassigned',
      description: carerId != null ? 'Carer assigned to visit' : 'Carer unassigned from visit',
      oldValue: {'carer_id': old['carer_id']},
      newValue: {'carer_id': carerId},
    );
  }

  /// Toggles respite on a visit, logging the change.
  Future<void> toggleVisitRespite(String visitId, bool respite) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    final old = await _client
        .from('route_visits')
        .select('respite')
        .eq('id', visitId)
        .single();

    await _client.from('route_visits').update({'respite': respite}).eq('id', visitId);

    await _logChange(
      ctx: ctx,
      visitId: visitId,
      changeType: 'respite_toggled',
      description: respite ? 'Marked as respite' : 'Respite removed',
      oldValue: {'respite': old['respite']},
      newValue: {'respite': respite},
    );
  }

  /// Cancels a visit, logging the change.
  Future<void> cancelVisit(String visitId, {String? reason}) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    await _client.from('route_visits').update({
      'status': 'cancelled',
      'notes': reason,
    }).eq('id', visitId);

    await _logChange(
      ctx: ctx,
      visitId: visitId,
      changeType: 'cancelled',
      description: reason ?? 'Visit cancelled',
    );
  }

  /// Moves a visit to another route, logging the change.
  Future<void> moveVisitToRoute(String visitId, String newRouteId) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    final old = await _client
        .from('route_visits')
        .select('route_id')
        .eq('id', visitId)
        .single();

    await _client.from('route_visits').update({'route_id': newRouteId}).eq('id', visitId);

    await _logChange(
      ctx: ctx,
      visitId: visitId,
      routeId: newRouteId,
      changeType: 'time_adjusted',
      description: 'Visit moved to another route',
      oldValue: {'route_id': old['route_id']},
      newValue: {'route_id': newRouteId},
    );
  }

  // ------------------------------------------------------------
  // ROUTE MERGE OPERATIONS
  // ------------------------------------------------------------

  /// Merges all visits from `sourceRouteId` into `targetRouteId`.
  /// The source route is marked as merged (its visits reassigned).
  Future<void> mergeRoute(String sourceRouteId, String targetRouteId) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }
    if (sourceRouteId == targetRouteId) return;

    // Move all visits from source to target
    final visits = await _client
        .from('route_visits')
        .select('id')
        .eq('route_id', sourceRouteId);

    for (final v in visits as List) {
      await _client
          .from('route_visits')
          .update({'route_id': targetRouteId, 'status': 'merged'})
          .eq('id', v['id'] as String);
    }

    // Mark source route as merged
    await _client.from('routes').update({
      'merged_into_route_id': targetRouteId,
      'status': 'merged',
    }).eq('id', sourceRouteId);

    await _logChange(
      ctx: ctx,
      routeId: targetRouteId,
      changeType: 'route_merged',
      description: 'Route merged into target route (${visits.length} visit(s) moved)',
      oldValue: {'source_route_id': sourceRouteId},
      newValue: {'target_route_id': targetRouteId},
    );
  }

  /// Splits a visit out of its current route into a new route container.
  Future<void> splitVisitToNewRoute(String visitId, {String? newRouteName}) async {
    final ctx = await _getOrgContext();
    if (ctx.organisationId == null && ctx.clientOrganisationId == null) {
      throw Exception('No organisation context');
    }

    final visit = await _client
        .from('route_visits')
        .select('visit_date')
        .eq('id', visitId)
        .single();

    final dateStr = (visit['visit_date'] as String).split('T')[0];

    // Create new route container
    final routeInsert = <String, dynamic>{
      'name': newRouteName ?? 'Route $dateStr (split)',
      'route_date': dateStr,
      'status': 'scheduled',
      ...await _orgInsertColumns(),
    };
    final routeResp = await _client.from('routes').insert(routeInsert).select('id').single();

    final newRouteId = routeResp['id'] as String;

    await _client.from('route_visits').update({'route_id': newRouteId}).eq('id', visitId);

    await _logChange(
      ctx: ctx,
      visitId: visitId,
      routeId: newRouteId,
      changeType: 'route_split',
      description: 'Visit split into new route',
    );
  }

  // ------------------------------------------------------------
  // CHANGE LOG
  // ------------------------------------------------------------

  /// Gets the change history for a given date, newest first.
  Future<List<RouteChangeLogEntry>> getChangeLog(DateTime date) async {
    final ctx = await _getOrgContext();

    final dateStr = date.toIso8601String().split('T')[0];
    final dayStart = '${dateStr}T00:00:00';
    final dayEnd = '${dateStr}T23:59:59';

    var query = _client
        .from('route_change_log')
        .select()
        .gte('created_at', dayStart)
        .lte('created_at', dayEnd);

    query = _scopeRouteQuery(query, ctx);

    final response = await query.order('created_at', ascending: false).limit(100);
    return (response as List)
        .map((json) => RouteChangeLogEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Gets change history for a specific visit.
  Future<List<RouteChangeLogEntry>> getVisitChangeHistory(String visitId) async {
    final ctx = await _getOrgContext();

    var query = _client
        .from('route_change_log')
        .select()
        .eq('visit_id', visitId);

    query = _scopeRouteQuery(query, ctx);

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => RouteChangeLogEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  Future<void> _insertVisit({
    required _OrgContext ctx,
    String? routeId,
    required String serviceUserId,
    String? carerId,
    required DateTime visitDate,
    required DateTime visitTime,
    int durationMinutes = 60,
    bool respite = false,
    bool requiresTwoCarers = false,
    int sortOrder = 1,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'route_id': routeId,
      'service_user_id': serviceUserId,
      'carer_id': carerId,
      'visit_date': visitDate.toIso8601String().split('T')[0],
      'visit_time': visitTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'respite': respite,
      'requires_two_carers': requiresTwoCarers,
      'sort_order': sortOrder,
      'notes': notes,
      ...await _orgInsertColumns(),
    };
    await _client.from('route_visits').insert(data);
  }

  Future<void> _logChange({
    required _OrgContext ctx,
    String? visitId,
    String? routeId,
    required String changeType,
    String? description,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      final data = <String, dynamic>{
        'visit_id': visitId,
        'route_id': routeId,
        'changed_by': userId,
        'change_type': changeType,
        'description': description,
        'old_value': oldValue,
        'new_value': newValue,
        ...await _orgInsertColumns(),
      };
      await _client.from('route_change_log').insert(data);
    } catch (e) {
      // Change logging should never break the main operation.
    }
  }

  /// Resolves the next occurrence of a weekday name ("monday".."sunday").
  static DateTime _getNextDayOfWeek(String dayName, DateTime from) {
    const days = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    final target = days[dayName.toLowerCase()] ?? -1;
    if (target == -1) return from;
    // DateTime.weekday: Monday=1 .. Sunday=7
    var diff = target - from.weekday;
    if (diff < 0) diff += 7;
    if (diff == 0) diff = 7; // next week, not today
    return DateTime(from.year, from.month, from.day).add(Duration(days: diff));
  }

  /// Combines a date with a "HH:MM" time string.
  static DateTime? _combineDateAndTime(DateTime date, String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

/// Organisation context for the current user.
/// Admin/staff → organisationId set (clientOrganisationId null)
/// client-app → clientOrganisationId set (organisationId null)
class _OrgContext {
  final String? organisationId;
  final String? clientOrganisationId;

  const _OrgContext({this.organisationId, this.clientOrganisationId});
}