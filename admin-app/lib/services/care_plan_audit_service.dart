import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/care_plan_audit.dart';

class CarePlanAuditService {
  final SupabaseClient _client;

  CarePlanAuditService(this._client);

  Future<List<CarePlanAudit>> getAudits({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? riskLevel,
  }) async {
    var query = _client.from('care_plan_audits').select();
    if (serviceUserId != null) query = query.eq('service_user_id', serviceUserId);
    if (startDate != null) query = query.gte('audit_date', startDate.toIso8601String().split('T').first);
    if (endDate != null) query = query.lte('audit_date', endDate.toIso8601String().split('T').first);
    if (status != null && status != 'all') query = query.eq('status', status);
    if (riskLevel != null && riskLevel != 'all') query = query.eq('risk_level', riskLevel);

    final data = await query.order('audit_date', ascending: false);
    return (data as List).map((i) => CarePlanAudit.fromMap(i as Map<String, dynamic>)).toList();
  }

  Future<CarePlanAudit> getAudit(String id) async {
    final data = await _client.from('care_plan_audits').select().eq('id', id).single();
    return CarePlanAudit.fromMap(data as Map<String, dynamic>);
  }

  Future<CarePlanAudit> createAudit(CarePlanAudit audit) async {
    final data = await _client.from('care_plan_audits').insert(audit.toMap()).select().single();
    return CarePlanAudit.fromMap(data as Map<String, dynamic>);
  }

  Future<CarePlanAudit> updateAudit(String id, CarePlanAudit audit) async {
    final data = await _client.from('care_plan_audits').update(audit.toMap()).eq('id', id).select().single();
    return CarePlanAudit.fromMap(data as Map<String, dynamic>);
  }

  Future<void> deleteAudit(String id) async {
    await _client.from('care_plan_audits').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getServiceUsers() async {
    final data = await _client.from('service_users').select('id, name').order('name');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getStaffUsers() async {
    final data = await _client.from('profiles').select('id, full_name, email').order('full_name');
    return (data as List).cast<Map<String, dynamic>>();
  }
}