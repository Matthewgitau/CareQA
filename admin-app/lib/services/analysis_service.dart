import 'package:supabase_flutter/supabase_flutter.dart';

class AnalysisService {
  final SupabaseClient _client;

  AnalysisService(this._client);

  // ==================== FINANCIAL METRICS ====================
  Future<Map<String, dynamic>> getFinancialSummary(DateTime start, DateTime end) async {
    try {
      final revenue = await _getRevenue(start, end);
      final expenses = await _getExpenses(start, end);
      final profit = revenue - expenses;
      
      final revenueBySource = await _getRevenueBySource(start, end);
      final expensesByCategory = await _getExpensesByCategory(start, end);
      final routeProfitability = await _getRouteProfitability(start, end);
      
      return {
        'total_revenue': revenue,
        'total_expenses': expenses,
        'net_profit': profit,
        'profit_margin': revenue > 0 ? (profit / revenue * 100) : 0,
        'revenue_by_source': revenueBySource,
        'expenses_by_category': expensesByCategory,
        'route_profitability': routeProfitability,
      };
    } catch (e) {
      throw Exception('Failed to fetch financial summary: $e');
    }
  }

  Future<double> _getRevenue(DateTime start, DateTime end) async {
    final response = await _client
        .from('invoices')
        .select('total_amount')
        .eq('status', 'paid')
        .gte('invoice_date', start.toIso8601String())
        .lte('invoice_date', end.toIso8601String());
    
    return (response as List).fold<double>(0.0, (sum, invoice) => sum + (invoice['total_amount'] as num).toDouble());
  }

  Future<Map<String, double>> _getRevenueBySource(DateTime start, DateTime end) async {
    final response = await _client
        .from('invoices')
        .select('client_type, total_amount')
        .eq('status', 'paid')
        .gte('invoice_date', start.toIso8601String())
        .lte('invoice_date', end.toIso8601String());
    
    final result = <String, double>{};
    for (final invoice in response as List) {
      final type = invoice['client_type'] ?? 'other';
      result[type] = (result[type] ?? 0) + (invoice['total_amount'] as num).toDouble();
    }
    return result;
  }

  Future<double> _getExpenses(DateTime start, DateTime end) async {
    final response = await _client
        .from('receipt_entries')
        .select('total_amount')
        .eq('status', 'approved')
        .gte('receipt_date', start.toIso8601String())
        .lte('receipt_date', end.toIso8601String());
    
    return (response as List).fold<double>(0.0, (sum, entry) => sum + (entry['total_amount'] as num).toDouble());
  }

  Future<Map<String, double>> _getExpensesByCategory(DateTime start, DateTime end) async {
    final response = await _client
        .from('receipt_entries')
        .select('expense_category, total_amount')
        .eq('status', 'approved')
        .gte('receipt_date', start.toIso8601String())
        .lte('receipt_date', end.toIso8601String());
    
    final result = <String, double>{};
    for (final entry in response as List) {
      final category = entry['expense_category'] ?? 'other';
      result[category] = (result[category] ?? 0) + (entry['total_amount'] as num).toDouble();
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _getRouteProfitability(DateTime start, DateTime end) async {
    try {
      final routes = await _client.from('dom_care_routes').select('id, name').eq('is_active', true);
      
      final result = <Map<String, dynamic>>[];
      for (final route in routes as List) {
        final visits = await _client
            .from('visits')
            .select('billing_amount')
            .eq('route_id', route['id'])
            .gte('visit_date', start.toIso8601String())
            .lte('visit_date', end.toIso8601String());
        
        final revenue = (visits as List).fold(0.0, (sum, v) => sum + (v['billing_amount'] as num).toDouble());
        
        final expenses = await _client
            .from('receipt_entries')
            .select('total_amount')
            .eq('route_id', route['id'])
            .gte('receipt_date', start.toIso8601String())
            .lte('receipt_date', end.toIso8601String());
        
        final totalExpenses = (expenses as List).fold(0.0, (sum, e) => sum + (e['total_amount'] as num).toDouble());
        
        result.add({
          'route_id': route['id'],
          'route_name': route['name'],
          'revenue': revenue,
          'expenses': totalExpenses,
          'profit': revenue - totalExpenses,
          'profit_margin': revenue > 0 ? ((revenue - totalExpenses) / revenue * 100) : 0,
          'visit_count': visits.length,
        });
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  // ==================== COMPLIANCE METRICS ====================
  Future<Map<String, dynamic>> getComplianceSummary(DateTime start, DateTime end) async {
    try {
      final trainingCompliance = await _getTrainingCompliance();
      final riskAssessmentCompliance = await _getRiskAssessmentCompliance(start, end);
      final auditCompliance = await _getAuditCompliance(start, end);
      
      return {
        'training_compliance': trainingCompliance,
        'risk_assessment_compliance': riskAssessmentCompliance,
        'audit_compliance': auditCompliance,
        'overall_compliance_score': 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch compliance summary: $e');
    }
  }

  Future<Map<String, dynamic>> _getTrainingCompliance() async {
    try {
      final totalResponse = await _client.from('profiles').select('id').single();
      final completed = await _client
          .from('training_records')
          .select('staff_id')
          .not('completion_date', 'is', null)
          .gte('completion_date', DateTime.now().subtract(const Duration(days: 365)).toIso8601String());
      
      final totalCount = (totalResponse as Map<String, dynamic>)['count'] ?? 0;
      return {
        'total_staff': totalCount,
        'completed_training': (completed as List).length,
        'compliance_rate': totalCount > 0 ? ((completed as List).length / totalCount * 100) : 0,
      };
    } catch (e) {
      return {'total_staff': 0, 'completed_training': 0, 'compliance_rate': 0};
    }
  }

  Future<Map<String, dynamic>> _getRiskAssessmentCompliance(DateTime start, DateTime end) async {
    try {
      final totalResponse = await _client.from('service_users').select('id').single();
      final withAssessments = await _client
          .from('risk_assessments')
          .select('service_user_id')
          .gte('assessment_date', start.toIso8601String())
          .lte('assessment_date', end.toIso8601String());
      
      final totalCount = (totalResponse as Map<String, dynamic>)['count'] ?? 0;
      return {
        'total_service_users': totalCount,
        'with_assessments': (withAssessments as List).length,
        'compliance_rate': totalCount > 0 ? ((withAssessments as List).length / totalCount * 100) : 0,
      };
    } catch (e) {
      return {'total_service_users': 0, 'with_assessments': 0, 'compliance_rate': 0};
    }
  }

  Future<Map<String, dynamic>> _getAuditCompliance(DateTime start, DateTime end) async {
    try {
      final audits = await _client
          .from('audits')
          .select('compliance_score')
          .gte('audit_date', start.toIso8601String())
          .lte('audit_date', end.toIso8601String());
      
      if (audits.isEmpty) {
        return {'average_score': 0, 'audit_count': 0};
      }
      
      final totalScore = (audits as List).fold(0.0, (sum, audit) => sum + (audit['compliance_score'] as num).toDouble());
      
      return {
        'average_score': totalScore / audits.length,
        'audit_count': audits.length,
      };
    } catch (e) {
      return {'average_score': 0, 'audit_count': 0};
    }
  }

  // ==================== OPERATIONAL METRICS ====================
  Future<Map<String, dynamic>> getOperationalSummary(DateTime start, DateTime end) async {
    try {
      final shiftCoverage = await _getShiftCoverage(start, end);
      final visitCompletion = await _getVisitCompletion(start, end);
      final incidentTrends = await _getIncidentTrends(start, end);
      
      return {
        'shift_coverage': shiftCoverage,
        'visit_completion': visitCompletion,
        'incident_trends': incidentTrends,
      };
    } catch (e) {
      throw Exception('Failed to fetch operational summary: $e');
    }
  }

  Future<Map<String, dynamic>> _getShiftCoverage(DateTime start, DateTime end) async {
    try {
      final totalResponse = await _client
          .from('shifts')
          .select('id')
          .gte('shift_date', start.toIso8601String())
          .lte('shift_date', end.toIso8601String());
      
      final covered = await _client
          .from('shifts')
          .select('id')
          .gte('shift_date', start.toIso8601String())
          .lte('shift_date', end.toIso8601String())
          .not('assigned_staff_id', 'is', null);
      
      final totalCount = (totalResponse as List).length;
      return {
        'total_shifts': (totalResponse as List).length,
        'covered_shifts': (covered as List).length,
        'coverage_rate': totalCount > 0 ? ((covered as List).length / totalCount * 100) : 0,
      };
    } catch (e) {
      return {'total_shifts': 0, 'covered_shifts': 0, 'coverage_rate': 0};
    }
  }

  Future<Map<String, dynamic>> _getVisitCompletion(DateTime start, DateTime end) async {
    try {
      final totalResponse = await _client
          .from('visits')
          .select('id')
          .gte('visit_date', start.toIso8601String())
          .lte('visit_date', end.toIso8601String());
      
      final completed = await _client
          .from('visits')
          .select('id')
          .gte('visit_date', start.toIso8601String())
          .lte('visit_date', end.toIso8601String())
          .eq('status', 'completed');
      
      final totalCount = (totalResponse as List).length;
      return {
        'total_visits': (totalResponse as List).length,
        'completed_visits': (completed as List).length,
        'completion_rate': totalCount > 0 ? ((completed as List).length / totalCount * 100) : 0,
      };
    } catch (e) {
      return {'total_visits': 0, 'completed_visits': 0, 'completion_rate': 0};
    }
  }

  Future<List<Map<String, dynamic>>> _getIncidentTrends(DateTime start, DateTime end) async {
    try {
      final incidents = await _client
          .from('incidents')
          .select('incident_date, severity')
          .gte('incident_date', start.toIso8601String())
          .lte('incident_date', end.toIso8601String())
          .order('incident_date');
      
      final byDate = <String, Map<String, int>>{};
      for (final incident in incidents as List) {
        final date = incident['incident_date']?.toString().split('T')[0] ?? 'unknown';
        final severity = incident['severity'] ?? 'unknown';
        
        if (!byDate.containsKey(date)) {
          byDate[date] = {'total': 0, 'critical': 0, 'high': 0, 'medium': 0, 'low': 0};
        }
        byDate[date]!['total'] = (byDate[date]!['total'] ?? 0) + 1;
        if (byDate[date]!.containsKey(severity)) {
          byDate[date]![severity] = (byDate[date]![severity] ?? 0) + 1;
        }
      }
      
      return byDate.entries.map((e) => {'date': e.key, ...e.value}).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== STAFF METRICS ====================
  Future<Map<String, dynamic>> getStaffMetrics(DateTime start, DateTime end) async {
    try {
      final staffByRole = await _getStaffByRole();
      final trainingCompletion = await _getStaffTrainingCompletion(start, end);
      
      return {
        'staff_by_role': staffByRole,
        'training_completion': trainingCompletion,
      };
    } catch (e) {
      throw Exception('Failed to fetch staff metrics: $e');
    }
  }

  Future<Map<String, int>> _getStaffByRole() async {
    try {
      final response = await _client.from('profiles').select('role');
      final result = <String, int>{};
      
      for (final profile in response as List) {
        final role = profile['role'] ?? 'other';
        result[role] = (result[role] ?? 0) + 1;
      }
      
      return result;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getCarers() async {
    try {
      final response = await _client
          .from('carers')
          .select('id, first_name, last_name, email, phone')
          .order('last_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getServiceUsers() async {
    try {
      final response = await _client
          .from('service_users')
          .select('id, name, email, phone')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStaff() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, email, role')
          .order('full_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _getStaffTrainingCompletion(DateTime start, DateTime end) async {
    try {
      final totalResponse = await _client.from('profiles').select('id').single();
      final completed = await _client
          .from('training_records')
          .select('staff_id')
          .gte('completion_date', start.toIso8601String())
          .lte('completion_date', end.toIso8601String());
      
      final totalCount = (totalResponse as Map<String, dynamic>)['count'] ?? 0;
      return {
        'total_staff': totalCount,
        'completed_training': (completed as List).length,
        'completion_rate': totalCount > 0 ? ((completed as List).length / totalCount * 100) : 0,
      };
    } catch (e) {
      return {'total_staff': 0, 'completed_training': 0, 'completion_rate': 0};
    }
  }

  // ==================== SERVICE USER METRICS ====================
  Future<Map<String, dynamic>> getServiceUserMetrics(DateTime start, DateTime end) async {
    try {
      final userCountResponse = await _client.from('service_users').select('id').count();
      final newAdmissions = await _client
          .from('service_users')
          .select('id')
          .gte('admission_date', start.toIso8601String())
          .lte('admission_date', end.toIso8601String());
      
      final userCount = userCountResponse.count ?? 0;
      return {
        'service_user_count': userCount,
        'new_admissions': (newAdmissions as List).length,
      };
    } catch (e) {
      throw Exception('Failed to fetch service user metrics: $e');
    }
  }

  // ==================== ANALYSIS VIEWS ====================
  Future<List<Map<String, dynamic>>> getAnalysisViews() async {
    try {
      final response = await _client.from('analysis_views').select().order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch analysis views: $e');
    }
  }

  Future<Map<String, dynamic>> createAnalysisView(Map<String, dynamic> view) async {
    try {
      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');
      
      view['organisation_id'] = orgId;
      view['created_by'] = _client.auth.currentUser?.id;
      view['created_at'] = DateTime.now().toIso8601String();
      view['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client.from('analysis_views').insert(view).select().single();
      return response;
    } catch (e) {
      throw Exception('Failed to create analysis view: $e');
    }
  }

  Future<String?> _getOrganisationId() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['organisation_id']?.toString();
    } catch (e) {
      return null;
    }
  }
}