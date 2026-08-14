import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/care_log_audit.dart';

class CareLogAuditService {
  final SupabaseClient _client;

  CareLogAuditService(this._client);

  /// Get all audits with optional filters
  Future<List<CareLogAudit>> getAudits({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? riskLevel,
  }) async {
    var query = _client
        .from('care_log_audits')
        .select();

    if (serviceUserId != null) {
      query = query.eq('service_user_id', serviceUserId);
    }
    if (startDate != null) {
      query = query.gte('audit_date', startDate.toIso8601String().split('T').first);
    }
    if (endDate != null) {
      query = query.lte('audit_date', endDate.toIso8601String().split('T').first);
    }
    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    if (riskLevel != null && riskLevel != 'all') {
      query = query.eq('risk_level', riskLevel);
    }

    final data = await query.order('audit_date', ascending: false);
    return (data as List)
        .map((item) => CareLogAudit.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Get a single audit by ID
  Future<CareLogAudit> getAudit(String id) async {
    final data = await _client
        .from('care_log_audits')
        .select()
        .eq('id', id)
        .single();
    return CareLogAudit.fromMap(data as Map<String, dynamic>);
  }

  /// Create a new audit
  Future<CareLogAudit> createAudit(CareLogAudit audit) async {
    final data = await _client
        .from('care_log_audits')
        .insert(audit.toMap())
        .select()
        .single();
    return CareLogAudit.fromMap(data as Map<String, dynamic>);
  }

  /// Update an existing audit
  Future<CareLogAudit> updateAudit(String id, CareLogAudit audit) async {
    final data = await _client
        .from('care_log_audits')
        .update(audit.toMap())
        .eq('id', id)
        .select()
        .single();
    return CareLogAudit.fromMap(data as Map<String, dynamic>);
  }

  /// Delete an audit
  Future<void> deleteAudit(String id) async {
    await _client.from('care_log_audits').delete().eq('id', id);
  }

  /// Get daily notes for audit selection
  Future<List<Map<String, dynamic>>> getDailyNotesForAudit({
    String? serviceUserId,
  }) async {
    var query = _client
        .from('daily_notes')
        .select('id, service_user_id, service_user_name, visit_date, visit_type, status');

    if (serviceUserId != null) {
      query = query.eq('service_user_id', serviceUserId);
    }

    final data = await query.order('visit_date', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Get daily note details for pre-populating audit
  Future<Map<String, dynamic>?> getDailyNoteDetails(String dailyNoteId) async {
    final data = await _client
        .from('daily_notes')
        .select()
        .eq('id', dailyNoteId)
        .maybeSingle();
    return data as Map<String, dynamic>?;
  }

  /// Get service users list
  Future<List<Map<String, dynamic>>> getServiceUsers() async {
    final data = await _client
        .from('service_users')
        .select('id, name')
        .order('name');
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Get staff/users for assignment dropdown
  Future<List<Map<String, dynamic>>> getStaffUsers() async {
    final data = await _client
        .from('profiles')
        .select('id, full_name, email')
        .order('full_name');
    return (data as List).cast<Map<String, dynamic>>();
  }
}