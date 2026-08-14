import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/expense_tracking_service.dart';

class ProfitCalculatorScreen extends StatefulWidget {
  const ProfitCalculatorScreen({super.key});

  @override
  State<ProfitCalculatorScreen> createState() => _ProfitCalculatorScreenState();
}

class _ProfitCalculatorScreenState extends State<ProfitCalculatorScreen> {
  final ExpenseTrackingService _service = ExpenseTrackingService(Supabase.instance.client);
  
  // Period selection
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'month';
  
  // Data
  Map<String, dynamic>? _profitData;
  bool _isLoading = false;
  String? _selectedRoute;
  Map<String, dynamic>? _routeProfitData;
  List<Map<String, dynamic>> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _setPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'quarter':
          _startDate = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
          _endDate = now;
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
        case 'custom':
          break;
      }
      _loadData();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'custom';
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _profitData = await _service.calculateProfit(_startDate, _endDate);
      _routes = await _service.getRoutes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profit data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRouteProfit(String routeId) async {
    setState(() => _isLoading = true);
    try {
      _routeProfitData = await _service.calculateRouteProfit(routeId, _startDate, _endDate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading route profit: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Calculator'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: 16),

            // Overall Dashboard
            if (_profitData != null) ...[
              _buildOverallDashboard(),
              const SizedBox(height: 16),
              _buildExpenseBreakdown(),
              const SizedBox(height: 16),
              _buildRevenueBreakdown(),
              const SizedBox(height: 16),
              _buildRouteBreakdown(),
              const SizedBox(height: 16),
              _buildRouteDetailSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPeriodChip('month', 'Month'),
                const SizedBox(width: 8),
                _buildPeriodChip('quarter', 'Quarter'),
                const SizedBox(width: 8),
                _buildPeriodChip('year', 'Year'),
                const SizedBox(width: 8),
                _buildPeriodChip('custom', 'Custom'),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDateRange,
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => _setPeriod(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOverallDashboard() {
    final data = _profitData!;
    final revenue = data['total_revenue'] as double;
    final expenses = data['total_expenses'] as double;
    final profit = data['total_profit'] as double;
    final margin = data['profit_margin'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overall Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Revenue', revenue, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Expenses', expenses, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Profit', profit, profit >= 0 ? Colors.blue : Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: margin >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: margin >= 0 ? Colors.green : Colors.red),
              ),
              child: Text(
                'Profit Margin: ${margin.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: margin >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '£${value.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildExpenseBreakdown() {
    final expenses = _profitData!['expenses_by_category'] as Map<String, double>;
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No expense data for this period', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final total = expenses.values.fold(0.0, (sum, v) => sum + v);
    final sorted = expenses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expenses by Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            ...sorted.map((entry) {
              final percentage = (entry.value / total * 100);
              final colorValue = ExpenseTrackingService.categoryColors[entry.key] ?? 0xFFBDBDBD;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: Color(colorValue),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ExpenseTrackingService.getExpenseCategoryDisplay(entry.key)),
                          ],
                        ),
                        Text('£${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(Color(colorValue)),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Total Expenses: £${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    final revenue = _profitData!['revenue_by_source'] as Map<String, double>;
    if (revenue.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No revenue data for this period', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final total = revenue.values.fold(0.0, (sum, v) => sum + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue by Source',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            ...revenue.entries.map((entry) {
              final percentage = (entry.value / total * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ExpenseTrackingService.getRevenueSourceDisplay(entry.key)),
                    Text('£${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)'),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Total Revenue: £${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteBreakdown() {
    final routeExpenses = _profitData!['expenses_by_route'] as Map<String, double>;
    if (routeExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route Expenses',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            ...routeExpenses.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('£${entry.value.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetailSection() {
    if (_routes.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route Profit Detail',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Route',
                border: OutlineInputBorder(),
              ),
              value: _selectedRoute,
              items: [
                const DropdownMenuItem(value: null, child: Text('Select a route')),
                ..._routes.map((route) => DropdownMenuItem(
                  value: route['id'] as String,
                  child: Text(route['name'] as String),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedRoute = value);
                if (value != null) {
                  _loadRouteProfit(value);
                }
              },
            ),
            if (_routeProfitData != null) ...[
              const SizedBox(height: 16),
              _buildRouteMetrics(),
              const SizedBox(height: 12),
              _buildRouteExpenseDetail(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteMetrics() {
    final d = _routeProfitData!;
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Revenue', d['revenue'] as double, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricCard('Expenses', d['expenses'] as double, Colors.red)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricCard('Profit', d['profit'] as double, Colors.blue)),
      ],
    );
  }

  Widget _buildRouteExpenseDetail() {
    final expByCat = _routeProfitData!['expenses_by_category'] as Map<String, double>;
    if (expByCat.isEmpty) return const SizedBox.shrink();

    final d = _routeProfitData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        ...expByCat.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ExpenseTrackingService.getExpenseCategoryDisplay(e.key)),
              Text('£${e.value.toStringAsFixed(2)}'),
            ],
          ),
        )),
        const Divider(),
        Text('Visits: ${d['visit_count']}'),
        Text('Revenue/Visit: £${(d['revenue_per_visit'] as double).toStringAsFixed(2)}'),
        Text('Profit/Visit: £${(d['profit_per_visit'] as double).toStringAsFixed(2)}'),
        Text('Margin: ${(d['profit_margin'] as double).toStringAsFixed(1)}%'),
      ],
    );
  }
}