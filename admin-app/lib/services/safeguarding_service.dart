import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/safeguarding_incident.dart';
import 'package:admin_app/models/whistleblower_report.dart';

class SafeguardingService {
  final SupabaseClient _client;

  SafeguardingService(this._client);

  // ════════════════════════════════════════════════════════════
  //  ACCIDENT LOGS
  // ════════════════════════════════════════════════════════════

  Future<List<SafeguardingIncident>> getAccidentLogs() async {
    try {
      final data = await _client
          .from('accident_logs')
          .select()
          .order('accident_date', ascending: false);
      return (data as List)
          .map((m) => SafeguardingIncident.fromAccidentLog(m as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> insertAccidentLog(Map<String, dynamic> record) async {
    try {
      await _client.from('accident_logs').insert(record);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateAccidentLog(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('accident_logs').update(updates).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  COMPLAINTS LOG
  // ════════════════════════════════════════════════════════════

  Future<List<SafeguardingIncident>> getComplaintsLogs() async {
    try {
      final data = await _client
          .from('complaints_logs')
          .select()
          .order('complaint_date', ascending: false);
      return (data as List)
          .map((m) => SafeguardingIncident.fromComplaintLog(m as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> insertComplaintLog(Map<String, dynamic> record) async {
    try {
      await _client.from('complaints_logs').insert(record);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateComplaintLog(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('complaints_logs').update(updates).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  MEDICATION INCIDENTS
  // ════════════════════════════════════════════════════════════

  Future<List<SafeguardingIncident>> getMedicationIncidents() async {
    try {
      final data = await _client
          .from('medication_incidents')
          .select()
          .order('incident_date', ascending: false);
      return (data as List)
          .map((m) => SafeguardingIncident.fromMedicationIncident(m as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> insertMedicationIncident(Map<String, dynamic> record) async {
    try {
      await _client.from('medication_incidents').insert(record);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateMedicationIncident(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('medication_incidents').update(updates).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  MISSING PERSONS
  // ════════════════════════════════════════════════════════════

  Future<List<SafeguardingIncident>> getMissingPersons() async {
    try {
      final data = await _client
          .from('missing_persons')
          .select()
          .order('missing_date', ascending: false);
      return (data as List)
          .map((m) => SafeguardingIncident.fromMissingPerson(m as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> insertMissingPerson(Map<String, dynamic> record) async {
    try {
      await _client.from('missing_persons').insert(record);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateMissingPerson(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('missing_persons').update(updates).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  SERIOUS INCIDENTS
  // ════════════════════════════════════════════════════════════

  Future<List<SafeguardingIncident>> getSeriousIncidents() async {
    try {
      final data = await _client
          .from('serious_incidents')
          .select()
          .order('incident_date', ascending: false);
      return (data as List)
          .map((m) => SafeguardingIncident.fromSeriousIncident(m as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> insertSeriousIncident(Map<String, dynamic> record) async {
    try {
      await _client.from('serious_incidents').insert(record);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateSeriousIncident(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('serious_incidents').update(updates).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  MISSING ITEMS
  // ════════════════════════════════════════════════════════════

  Future<List<SafeguardingIncident>> getMissingItems() async {
    try {
      final data = await _client
          .from('missing_items')
          .select()
          .order('missing_date', ascending: false);
      return (data as List)
          .map((m) => SafeguardingIncident.fromMissingItem(m as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> insertMissingItem(Map<String, dynamic> record) async {
    try {
      await _client.from('missing_items').insert(record);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateMissingItem(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('missing_items').update(updates).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  WHISTLEBLOWER REPORTS
  // ════════════════════════════════════════════════════════════

  Future<List<WhistleblowerReport>> getWhistleblowerReports({bool includeArchived = false}) async {
    try {
      final data = await _client
          .from('whistleblower_reports')
          .select()
          .order('created_at', ascending: false);
      final all = (data as List)
          .map((m) => WhistleblowerReport.fromMap(m as Map<String, dynamic>))
          .toList();
      if (includeArchived) return all;
      return all.where((r) => !r.archived).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> insertWhistleblowerReport(Map<String, dynamic> record) async {
    try {
      await _client.from('whistleblower_reports').insert(record);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateWhistleblowerReport(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('whistleblower_reports').update(updates).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> assignWhistleblowerReport(String id, String assignedTo) async {
    try {
      await _client.from('whistleblower_reports').update({
        'assigned_to': assignedTo,
        'assigned_at': DateTime.now().toIso8601String(),
        'status': 'under_review',
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> actionWhistleblowerReport(
    String id, {
    required String outcome,
    required String actions,
    String? reviewNotes,
  }) async {
    try {
      await _client.from('whistleblower_reports').update({
        'investigation_outcome': outcome,
        'actions_taken': actions,
        'review_notes': reviewNotes,
        'status': 'actioned',
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> archiveWhistleblowerReport(String id, {String? reason}) async {
    try {
      await _client.from('whistleblower_reports').update({
        'archived': true,
        'archived_at': DateTime.now().toIso8601String(),
        'archive_reason': reason,
        'status': 'archived',
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  DASHBOARD SUMMARY
  // ════════════════════════════════════════════════════════════

  /// Returns a summary map with counts by type and status.
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final results = await Future.wait([
        _client.from('accident_logs').select('id, status, injury_severity'),
        _client.from('complaints_logs').select('id, status'),
        _client.from('medication_incidents').select('id, status, severity'),
        _client.from('missing_persons').select('id, status'),
        _client.from('serious_incidents').select('id, status'),
        _client.from('whistleblower_reports').select('id, status, priority').eq('archived', false),
        _client.from('missing_items').select('id, status'),
      ]);

      int openAccidents = 0;
      int openComplaints = 0;
      int openMedication = 0;
      int openMissingPersons = 0;
      int openSerious = 0;
      int pendingWhistleblowers = 0;
      int openMissingItems = 0;
      int criticalCount = 0;

      for (final row in results[0] as List) {
        final s = row['status'];
        if (s != 'resolved' && s != 'closed') openAccidents++;
        if (row['injury_severity'] == 'severe' || row['injury_severity'] == 'critical') criticalCount++;
      }
      for (final row in results[1] as List) {
        if (row['status'] != 'resolved' && row['status'] != 'closed') openComplaints++;
      }
      for (final row in results[2] as List) {
        if (row['status'] != 'resolved' && row['status'] != 'closed') openMedication++;
        if (row['severity'] == 'severe_harm' || row['severity'] == 'death') criticalCount++;
      }
      for (final row in results[3] as List) {
        if (row['status'] != 'resolved' && row['status'] != 'closed') openMissingPersons++;
      }
      for (final row in results[4] as List) {
        if (row['status'] != 'resolved' && row['status'] != 'closed') openSerious++;
      }
      for (final row in results[5] as List) {
        if (row['status'] == 'pending' || row['status'] == 'under_review' || row['status'] == 'investigating') {
          pendingWhistleblowers++;
        }
      }
      for (final row in results[6] as List) {
        if (row['status'] != 'resolved' && row['status'] != 'closed') openMissingItems++;
      }

      return {
        'open_accidents': openAccidents,
        'open_complaints': openComplaints,
        'open_medication': openMedication,
        'open_missing_persons': openMissingPersons,
        'open_serious': openSerious,
        'pending_whistleblowers': pendingWhistleblowers,
        'open_missing_items': openMissingItems,
        'critical_count': criticalCount,
      };
    } catch (_) {
      return {
        'open_accidents': 0,
        'open_complaints': 0,
        'open_medication': 0,
        'open_missing_persons': 0,
        'open_serious': 0,
        'pending_whistleblowers': 0,
        'open_missing_items': 0,
        'critical_count': 0,
      };
    }
  }

  /// Returns all open incidents across all types, sorted by created_at desc.
  Future<List<SafeguardingIncident>> getAllOpenIncidents() async {
    try {
      final results = await Future.wait([
        getAccidentLogs(),
        getComplaintsLogs(),
        getMedicationIncidents(),
        getMissingPersons(),
        getSeriousIncidents(),
        getMissingItems(),
      ]);

      final all = <SafeguardingIncident>[];
      for (final list in results) {
        all.addAll(list.where((i) => i.status != 'resolved' && i.status != 'closed'));
      }

      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    } catch (_) {
      return [];
    }
  }
}