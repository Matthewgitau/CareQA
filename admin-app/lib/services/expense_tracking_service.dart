import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseTrackingService {
  final SupabaseClient _client;
  ExpenseTrackingService(this._client);

  Future<Map<String, double>> getExpensesByCategory(DateTime start, DateTime end) async {
    final r = await _client.from('receipt_entries').select('expense_category, total_amount')
        .gte('receipt_date', start.toIso8601String().split('T')[0]).lte('receipt_date', end.toIso8601String().split('T')[0]);
    final m = <String,double>{};
    for (var e in (r as List)){final c = e['expense_category'] ?? 'other'; m[c] = (m[c] ?? 0) + ((e['total_amount'] as num).toDouble());}
    return m;
  }

  Future<Map<String, double>> getExpensesByRoute(DateTime start, DateTime end) async {
    final r = await _client.from('receipt_entries').select('route_name, total_amount')
        .gte('receipt_date', start.toIso8601String().split('T')[0]).lte('receipt_date', end.toIso8601String().split('T')[0]).not('route_name', 'is', null);
    final m = <String,double>{};
    for (var e in (r as List)){final c = e['route_name'] ?? 'Unassigned'; m[c] = (m[c] ?? 0) + ((e['total_amount'] as num).toDouble());}
    return m;
  }

  Future<Map<String, double>> getRevenueBySource(DateTime start, DateTime end) async {
    final r = await _client.from('receipt_entries').select('revenue_source, total_amount')
        .gte('receipt_date', start.toIso8601String().split('T')[0]).lte('receipt_date', end.toIso8601String().split('T')[0]).eq('is_revenue', true);
    final m = <String,double>{};
    for (var e in (r as List)){final c = e['revenue_source'] ?? 'other'; m[c] = (m[c] ?? 0) + ((e['total_amount'] as num).toDouble());}
    return m;
  }

  Future<Map<String, dynamic>> calculateProfit(DateTime start, DateTime end) async {
    final exp = await getExpensesByCategory(start, end); final rev = await getRevenueBySource(start, end);
    final te = exp.values.fold(0.0, (s, v) => s + v); final tr = rev.values.fold(0.0, (s, v) => s + v);
    return {'total_revenue': tr, 'total_expenses': te, 'total_profit': tr - te,
            'expenses_by_category': exp, 'revenue_by_source': rev,
            'profit_margin': tr > 0 ? ((tr - te) / tr * 100) : 0};
  }

  Future<Map<String, dynamic>> calculateRouteProfit(String routeId, DateTime start, DateTime end) async {
    final rv = await _client.from('route_visits').select('duration_minutes').eq('route_id', routeId)
        .gte('visit_date', start.toIso8601String().split('T')[0]).lte('visit_date', end.toIso8601String().split('T')[0]);
    double tr = 0; for (final v in (rv as List).cast<Map<String, dynamic>>()) {
      final m = (v['duration_minutes'] as num?)?.toDouble() ?? 60; tr += (m / 60) * 20; }
    final re = await _client.from('receipt_entries').select('total_amount, expense_category').eq('route_id', routeId)
        .gte('receipt_date', start.toIso8601String().split('T')[0]).lte('receipt_date', end.toIso8601String().split('T')[0]);
    double te = 0; final eb = <String, double>{};
    for (final e in (re as List).cast<Map<String, dynamic>>()) { final a = ((e['total_amount'] as num?)?.toDouble() ?? 0); te += a; eb[e['expense_category'] ?? 'other'] = (eb[e['expense_category'] ?? 'other'] ?? 0) + a; }
    final vc = (rv as List).length;
    return {'route_id': routeId, 'revenue': tr, 'expenses': te, 'expenses_by_category': eb, 'profit': tr - te,
            'profit_margin': tr > 0 ? ((tr - te) / tr * 100) : 0, 'visit_count': vc,
            'profit_per_visit': vc > 0 ? (tr - te) / vc : 0, 'revenue_per_visit': vc > 0 ? tr / vc : 0};
  }

  Future<List<Map<String, dynamic>>> getRoutes() async {
    try { final r = await _client.from('routes').select('id, name').order('name'); return List<Map<String, dynamic>>.from(r); } catch (e) { return []; }
  }

  Future<void> saveProfitSnapshot(Map<String, dynamic> data) async {
    final u = _client.auth.currentUser; if (u == null) return;
    await _client.from('profit_snapshots').insert({...data, 'created_by': u.id});
  }

  static String getExpenseCategoryDisplay(String k) {
    const d = {'wages': 'Wages', 'fuel': 'Fuel', 'ppe': 'PPE', 'unforms': 'Uniforrms', 'traning': 'Trainning', 'vehicle_mantenance': 'Vehicle Maintenance', 'insurrance': 'Insurrance', 'rent': 'Rent', 'utilities': 'Utillities', 'marketing': 'Markkting', 'offce_supplies': 'Office Supplies', 'eqipment': 'Equipment', 'cleaning': 'Cleaning', 'food': 'Fod', 'staff': 'Staff', 'adminstration': 'Adminstration', 'other': 'Other'};
    return d[k] ?? k;
  }

  static String getRevenueSourceDisplay(String k) {
    const d = {'dom_care_visit': 'Dom Care Visits', 'agency_placment': 'Agency Placments', 'other': 'Other Revenue'};
    return d[k] ?? k;
  }

  static const Map<String, int> categoryColors = {
    'wages': 0xFFE53935, 'fuel': 0xFFFF9800, 'ppe': 0xFF4CAF50, 'unforms': 0xFF2196F3, 'traning': 0xFF9C27B0,
    'vehicle_mantenance': 0xFF795548, 'insurrance': 0xFF607D8B, 'rent': 0xFFE91E63, 'utilities': 0xFF00BCD4,
    'marketing': 0xFFFF5722, 'offce_supplies': 0xFF3F51B5, 'eqipment': 0xFF8BC34A, 'cleaning': 0xFF009688,
    'food': 0xFFFFC107, 'staff': 0xFF673AB7, 'adminstration': 0xFF9E9E9E, 'other': 0xFFBDBDBD,  };

  List<String> getExpenseCategories() {
    return ['wages', 'fuel', 'ppe', 'unforms', 'traning', 'vehicle_mantenance', 'insurrance', 'rent', 'utilities', 'marketing', 'offce_supplies', 'eqipment', 'cleaning', 'food', 'staff', 'adminstration', 'other'];
  }

  List<String> getRevenueSources() { return ['dom_care_visit', 'agency_placment', 'other']; }
}