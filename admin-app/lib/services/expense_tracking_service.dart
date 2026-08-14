import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseTrackingService {
  final SupabaseClient _client;

  ExpenseTrackingService(this._client);

  // Get all expenses by category for a period
  Future<Map<String, double>> getExpensesByCategory(DateTime start, DateTime end) async {
    final response = await _client
        .from('receipt_entries')
        .select('expense_category, total_amount')
        .gte('receipt_date', start.toIso8601String().split('T')[0])
        .lte('receipt_date', end.toIso8601String().split('T')[0])
        .eq('is_revenue', false)
        .eq('status', 'approved');

    final result = <String, double>{};
    for (var entry in response as List) {
      final category = entry['expense_category'] ?? 'other';
      result[category] = (result[category] ?? 0) + (entry['total_amount'] as num).toDouble();
    }
    return result;
  }

  // Get expenses by route
  Future<Map<String, double>> getExpensesByRoute(DateTime start, DateTime end) async {
    final response = await _client
        .from('receipt_entries')
        .select('route_name, total_amount')
        .gte('receipt_date', start.toIso8601String().split('T')[0])
        .lte('receipt_date', end.toIso8601String().split('T')[0])
        .not('route_name', 'is', null)
        .eq('is_revenue', false)
        .eq('status', 'approved');

    final result = <String, double>{};
    for (var entry in response as List) {
      final route = entry['route_name'] ?? 'Unassigned';
      result[route] = (result[route] ?? 0) + (entry['total_amount'] as num).toDouble();
    }
    return result;
  }

  // Get revenue by source
  Future<Map<String, double>> getRevenueBySource(DateTime start, DateTime end) async {
    final response = await _client
        .from('receipt_entries')
        .select('revenue_source, total_amount')
        .gte('receipt_date', start.toIso8601String().split('T')[0])
        .lte('receipt_date', end.toIso8601String().split('T')[0])
        .eq('is_revenue', true)
        .eq('status', 'approved');

    final result = <String, double>{};
    for (var entry in response as List) {
      final source = entry['revenue_source'] ?? 'other';
      result[source] = (result[source] ?? 0) + (entry['total_amount'] as num).toDouble();
    }
    return result;
  }

  // Calculate profit for a period
  Future<Map<String, dynamic>> calculateProfit(DateTime start, DateTime end) async {
    final expenses = await getExpensesByCategory(start, end);
    final totalExpenses = expenses.values.fold(0.0, (sum, v) => sum + v);

    final revenue = await getRevenueBySource(start, end);
    final totalRevenue = revenue.values.fold(0.0, (sum, v) => sum + v);

    final routeExpenses = await getExpensesByRoute(start, end);

    return {
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'total_profit': totalRevenue - totalExpenses,
      'expenses_by_category': expenses,
      'revenue_by_source': revenue,
      'expenses_by_route': routeExpenses,
      'profit_margin': totalRevenue > 0 ? ((totalRevenue - totalExpenses) / totalRevenue * 100) : 0,
    };
  }

  // Calculate route-specific profit
  Future<Map<String, dynamic>> calculateRouteProfit(String routeId, DateTime start, DateTime end) async {
    // Get revenue from visits on this route
    final revenueResponse = await _client
        .from('visits')
        .select('billing_amount')
        .eq('route_id', routeId)
        .gte('visit_date', start.toIso8601String().split('T')[0])
        .lte('visit_date', end.toIso8601String().split('T')[0]);

    final totalRevenue = (revenueResponse as List)
        .fold<num>(0, (sum, v) => sum + (v['billing_amount'] as num? ?? 0)).toDouble();

    // Get expenses for this route
    final expenseResponse = await _client
        .from('receipt_entries')
        .select('total_amount, expense_category')
        .eq('route_id', routeId)
        .gte('receipt_date', start.toIso8601String().split('T')[0])
        .lte('receipt_date', end.toIso8601String().split('T')[0])
        .eq('is_revenue', false)
        .eq('status', 'approved');

    final expenses = (expenseResponse as List);
    double totalExpenses = 0;
    final expensesByCategory = <String, double>{};
    
    for (var entry in expenses) {
      final amount = (entry['total_amount'] as num).toDouble();
      totalExpenses += amount;
      final cat = entry['expense_category'] ?? 'other';
      expensesByCategory[cat] = (expensesByCategory[cat] ?? 0) + amount;
    }

    // Get visit count
    final visitCount = (revenueResponse as List).length;

    return {
      'route_id': routeId,
      'revenue': totalRevenue,
      'expenses': totalExpenses,
      'expenses_by_category': expensesByCategory,
      'profit': totalRevenue - totalExpenses,
      'profit_margin': totalRevenue > 0 ? ((totalRevenue - totalExpenses) / totalRevenue * 100) : 0,
      'visit_count': visitCount,
      'profit_per_visit': visitCount > 0 ? (totalRevenue - totalExpenses) / visitCount : 0,
      'revenue_per_visit': visitCount > 0 ? totalRevenue / visitCount : 0,
    };
  }

  // Get all routes for dropdown
  Future<List<Map<String, dynamic>>> getRoutes() async {
    try {
      final response = await _client
          .from('dom_care_routes')
          .select('id, name')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Save profit snapshot
  Future<void> saveProfitSnapshot(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profit_snapshots').insert({
      ...data,
      'created_by': user.id,
    });
  }

  // Get expense category display names
  static String getExpenseCategoryDisplay(String key) {
    const displayNames = {
      'wages': 'Wages',
      'fuel': 'Fuel',
      'ppe': 'PPE',
      'uniforms': 'Uniforms',
      'training': 'Training',
      'vehicle_maintenance': 'Vehicle Maintenance',
      'insurance': 'Insurance',
      'rent': 'Rent',
      'utilities': 'Utilities',
      'marketing': 'Marketing',
      'office_supplies': 'Office Supplies',
      'equipment': 'Equipment',
      'cleaning': 'Cleaning',
      'food': 'Food',
      'staff': 'Staff',
      'administration': 'Administration',
      'other': 'Other',
    };
    return displayNames[key] ?? key;
  }

  // Get revenue source display names
  static String getRevenueSourceDisplay(String key) {
    const displayNames = {
      'dom_care_visit': 'Dom Care Visits',
      'agency_placement': 'Agency Placements',
      'other': 'Other Revenue',
    };
    return displayNames[key] ?? key;
  }

  // Category colors for charts
  static const Map<String, int> categoryColors = {
    'wages': 0xFFE53935,
    'fuel': 0xFFFF9800,
    'ppe': 0xFF4CAF50,
    'uniforms': 0xFF2196F3,
    'training': 0xFF9C27B0,
    'vehicle_maintenance': 0xFF795548,
    'insurance': 0xFF607D8B,
    'rent': 0xFFE91E63,
    'utilities': 0xFF00BCD4,
    'marketing': 0xFFFF5722,
    'office_supplies': 0xFF3F51B5,
    'equipment': 0xFF8BC34A,
    'cleaning': 0xFF009688,
    'food': 0xFFFFC107,
    'staff': 0xFF673AB7,
    'administration': 0xFF9E9E9E,
    'other': 0xFFBDBDBD,
  };

  List<String> getExpenseCategories() {
    return [
      'wages', 'fuel', 'ppe', 'uniforms', 'training', 'vehicle_maintenance',
      'insurance', 'rent', 'utilities', 'marketing', 'office_supplies',
      'equipment', 'cleaning', 'food', 'staff', 'administration', 'other',
    ];
  }

  List<String> getRevenueSources() {
    return ['dom_care_visit', 'agency_placement', 'other'];
  }
}