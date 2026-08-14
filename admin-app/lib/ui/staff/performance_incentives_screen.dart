import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/incentive_service.dart';

class PerformanceIncentivesScreen extends StatefulWidget {
  const PerformanceIncentivesScreen({super.key});

  @override
  State<PerformanceIncentivesScreen> createState() => _PerformanceIncentivesScreenState();
}

class _PerformanceIncentivesScreenState extends State<PerformanceIncentivesScreen> {
  final _service = IncentiveService(Supabase.instance.client);
  List<Map<String, dynamic>> _metrics = [];
  bool _isLoading = true;
  String? _selectedStaffId;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    try {
      final metrics = await _service.getPerformanceMetrics(_selectedStaffId ?? '');
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading metrics: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _calculatePoints() async {
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final result = await _service.calculatePointsForPerformance(_selectedStaffId!);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Points Calculation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Points: ${result['total_points']}'),
                Text('Metrics Count: ${result['metrics_count']}'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Incentives'),
        actions: [
          IconButton(
            onPressed: _loadMetrics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Staff Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      const Text('Filter by staff:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _service.getAllStaff(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Text('Loading...');
                            }
                            final staff = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              value: _selectedStaffId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Staff')),
                                ...staff.map((s) => DropdownMenuItem(
                                      value: s['id'] as String,
                                      child: Text('${s['name']} (${s['type'] == 'carer' ? 'Carer' : 'Staff'})'),
                                    )),
                              ],
                              onChanged: (v) {
                                setState(() => _selectedStaffId = v);
                                _loadMetrics();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Calculate Points Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _calculatePoints,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calculate Points for Selected Staff'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics List
                Expanded(
                  child: _metrics.isEmpty
                      ? const Center(child: Text('No performance metrics available'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _metrics.length,
                          itemBuilder: (context, index) {
                            final metric = _metrics[index];
                            final achievement = metric['achievement_percentage'] ?? 0;
                            final color = _getAchievementColor(achievement);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _getMetricTypeDisplay(metric['metric_type'] ?? ''),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: color.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            '${achievement.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Staff: ${metric['staff_name'] ?? 'N/A'}'),
                                    if (metric['metric_period_start'] != null && metric['metric_period_end'] != null)
                                      Text(
                                        'Period: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(metric['metric_period_start']))} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(metric['metric_period_end']))}',
                                      ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: (achievement / 100).clamp(0.0, 1.0),
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                      minHeight: 8,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Target: ${metric['target_value'] ?? 0}'),
                                        Text('Actual: ${metric['metric_value'] ?? 0}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Color _getAchievementColor(double achievement) {
    if (achievement >= 100) return Colors.green;
    if (achievement >= 80) return Colors.lightGreen;
    if (achievement >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getMetricTypeDisplay(String metricType) {
    switch (metricType) {
      case 'visits_completed': return 'Visits Completed';
      case 'on_time_rate': return 'On-Time Rate';
      case 'medication_accuracy': return 'Medication Accuracy';
      case 'client_complaints': return 'Client Complaints';
      case 'compliments_received': return 'Compliments Received';
      case 'overtime_hours': return 'Overtime Hours';
      case 'training_completed': return 'Training Completed';
      default: return metricType;
    }
  }
}