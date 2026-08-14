import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lesson_learnt.dart';
import '../../services/lesson_learnt_service.dart';

class LessonReportsScreen extends StatefulWidget {
  const LessonReportsScreen({super.key});

  @override
  State<LessonReportsScreen> createState() => _LessonReportsScreenState();
}

class _LessonReportsScreenState extends State<LessonReportsScreen> {
  final _service = LessonLearntService(Supabase.instance.client);
  bool _loading = true;
  Map<String, int> _stats = {};
  Map<String, int> _rootCauses = {};
  List<LessonLearnt> _allLessons = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.getLessonStats();
      final rootCauses = await _service.getRootCauseAnalysis();
      final lessons = await _service.getLessons();
      setState(() {
        _stats = stats;
        _rootCauses = rootCauses;
        _allLessons = lessons;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons Learnt Reports'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildSeverityChart(),
                  const SizedBox(height: 24),
                  _buildStatusChart(),
                  const SizedBox(height: 24),
                  _buildRootCauseChart(),
                  const SizedBox(height: 24),
                  _buildImplementationCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _stats['total'] ?? 0;
    final critical = _stats['critical'] ?? 0;
    final high = _stats['high'] ?? 0;
    final implemented = _stats['implemented_count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard('Total Lessons', total, Colors.blue),
            _buildSummaryCard('Critical', critical, Colors.red),
            _buildSummaryCard('High', high, Colors.orange),
            _buildSummaryCard('Implemented', implemented, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSeverityChart() {
    final severities = ['critical', 'high', 'medium', 'low'];
    final severityLabels = {'critical': 'Critical', 'high': 'High', 'medium': 'Medium', 'low': 'Low'};
    final severityColors = {'critical': Colors.red, 'high': Colors.orange, 'medium': Colors.yellow, 'low': Colors.green};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lessons by Severity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...severities.map((severity) {
              final count = _stats[severity] ?? 0;
              final total = _stats['total'] ?? 1;
              final percentage = (count / total * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: severityColors[severity], shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(severityLabels[severity]!)),
                        Text('$count (${percentage}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: count / total,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(severityColors[severity]!),
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart() {
    final statuses = ['draft', 'review_pending', 'approved', 'implemented', 'shared', 'closed'];
    final statusLabels = {'draft': 'Draft', 'review_pending': 'Review Pending', 'approved': 'Approved', 'implemented': 'Implemented', 'shared': 'Shared', 'closed': 'Closed'};
    final statusColors = {'draft': Colors.grey, 'review_pending': Colors.orange, 'approved': Colors.blue, 'implemented': Colors.green, 'shared': Colors.purple, 'closed': Colors.teal};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lessons by Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...statuses.map((status) {
              final count = _stats[status] ?? 0;
              final total = _stats['total'] ?? 1;
              final percentage = (count / total * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: statusColors[status], shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(statusLabels[status]!)),
                        Text('$count (${percentage}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: count / total,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColors[status]!),
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRootCauseChart() {
    final sortedRootCauses = _rootCauses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Root Cause Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (sortedRootCauses.isEmpty)
              const Text('No data available', style: TextStyle(color: Colors.grey))
            else
              ...sortedRootCauses.map((entry) {
                final rootCause = entry.key.replaceAll('_', ' ').toUpperCase();
                final count = entry.value;
                final total = _allLessons.length;
                final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(rootCause)),
                          Text('$count (${percentage}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: total > 0 ? count / total : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 6,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildImplementationCard() {
    final total = _stats['total'] ?? 0;
    final implemented = _stats['implemented_count'] ?? 0;
    final rate = total > 0 ? ((implemented / total) * 100).toStringAsFixed(1) : '0.0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Implementation Rate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('$rate%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                      const SizedBox(height: 8),
                      Text('$implemented of $total lessons implemented', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: total > 0 ? implemented / total : 0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          strokeWidth: 8,
                        ),
                      ),
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}