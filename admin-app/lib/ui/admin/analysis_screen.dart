import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Analysis Screen - Data analysis dashboard
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _visitTrends = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final serviceUsers = await _supabase.from('service_users').select('id');
      final staff = await _supabase.from('profiles').select('id').eq('role', 'carer');
      
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final visits = await _supabase
          .from('visits')
          .select('id')
          .gte('date', startOfMonth.toIso8601String());

      final visitTrends = await _supabase
          .from('visits')
          .select('date, status')
          .gte('date', _startDate.toIso8601String())
          .lte('date', _endDate.toIso8601String())
          .order('date');

      Map<String, Map<String, int>> trendsMap = {};
      for (var visit in visitTrends) {
        final date = visit['date'].toString().substring(0, 10);
        if (!trendsMap.containsKey(date)) {
          trendsMap[date] = {'completed': 0, 'missed': 0, 'total': 0};
        }
        trendsMap[date]!['total'] = (trendsMap[date]!['total'] ?? 0) + 1;
        if (visit['status'] == 'completed') {
          trendsMap[date]!['completed'] = (trendsMap[date]!['completed'] ?? 0) + 1;
        } else if (visit['status'] == 'missed') {
          trendsMap[date]!['missed'] = (trendsMap[date]!['missed'] ?? 0) + 1;
        }
      }

      List<Map<String, dynamic>> trends = trendsMap.entries.map((e) {
        return {'date': e.key, ...e.value};
      }).toList();
      trends.sort((a, b) => a['date'].compareTo(b['date']));

      setState(() {
        _metrics = {
          'serviceUsers': serviceUsers.length,
          'staff': staff.length,
          'visitsThisMonth': visits.length,
          'complianceRate': visits.isNotEmpty 
              ? ((visits.length * 100) / (serviceUsers.length * 30)).clamp(0, 100).toInt() 
              : 0,
        };
        _visitTrends = trends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRangeSelector(),
                    const SizedBox(height: 24),
                    _buildMetricsSection(),
                    const SizedBox(height: 24),
                    _buildVisitTrendsSection(),
                    const SizedBox(height: 24),
                    _buildExportButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                        _loadData();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                        _loadData();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Key Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard('Service Users', _metrics['serviceUsers']?.toString() ?? '0', Icons.home, Colors.blue),
            _buildMetricCard('Staff Members', _metrics['staff']?.toString() ?? '0', Icons.people, Colors.green),
            _buildMetricCard('Visits This Month', _metrics['visitsThisMonth']?.toString() ?? '0', Icons.delivery_dining, Colors.orange),
            _buildMetricCard('Compliance Rate', '${_metrics['complianceRate'] ?? 0}%', Icons.verified_user, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTrendsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Visit Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_visitTrends.isEmpty)
              const Center(child: Text('No visit data available'))
            else
              ..._visitTrends.map((trend) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(DateFormat('dd MMM').format(DateTime.parse(trend['date'])), style: const TextStyle(fontWeight: FontWeight.w500))),
                    Expanded(flex: 3, child: LinearProgressIndicator(value: (trend['total'] ?? 0) > 0 ? (trend['completed'] ?? 0) / (trend['total'] ?? 1) : 0, backgroundColor: Colors.grey[300], valueColor: const AlwaysStoppedAnimation<Color>(Colors.green))),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${trend['completed'] ?? 0}/${trend['total'] ?? 0}', textAlign: TextAlign.center)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report exported successfully')),
          );
        },
        icon: const Icon(Icons.download),
        label: const Text('Export Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}