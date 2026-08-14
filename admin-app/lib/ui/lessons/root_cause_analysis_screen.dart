import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lesson_learnt.dart';
import '../../services/lesson_learnt_service.dart';

class RootCauseAnalysisScreen extends StatefulWidget {
  const RootCauseAnalysisScreen({super.key});

  @override
  State<RootCauseAnalysisScreen> createState() => _RootCauseAnalysisScreenState();
}

class _RootCauseAnalysisScreenState extends State<RootCauseAnalysisScreen> {
  final _service = LessonLearntService(Supabase.instance.client);
  bool _loading = true;
  Map<String, int> _rootCauses = {};
  List<LessonLearnt> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final rootCauses = await _service.getRootCauseAnalysis();
      final lessons = await _service.getLessons();
      setState(() {
        _rootCauses = rootCauses;
        _lessons = lessons;
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
        title: const Text('Root Cause Analysis'),
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
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildRootCauseBreakdown(),
                  const SizedBox(height: 24),
                  _buildFiveWhysTemplate(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _lessons.length;
    final withRootCause = _lessons.where((l) => l.rootCause != null && l.rootCause!.isNotEmpty).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Root Cause Analysis Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('$withRootCause of $total lessons have root cause analysis documented'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total > 0 ? withRootCause / total : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRootCauseBreakdown() {
    final sortedRootCauses = _rootCauses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final rootCauseLabels = {
      'training_gap': 'Training Gap',
      'process_failure': 'Process Failure',
      'communication_breakdown': 'Communication Breakdown',
      'resource_shortage': 'Resource Shortage',
      'environmental': 'Environmental',
      'equipment_failure': 'Equipment Failure',
      'staffing': 'Staffing',
      'systemic': 'Systemic',
      'other': 'Other',
    };
    final rootCauseColors = {
      'training_gap': Colors.blue,
      'process_failure': Colors.orange,
      'communication_breakdown': Colors.purple,
      'resource_shortage': Colors.red,
      'environmental': Colors.green,
      'equipment_failure': Colors.brown,
      'staffing': Colors.teal,
      'systemic': Colors.indigo,
      'other': Colors.grey,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Root Cause Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (sortedRootCauses.isEmpty)
              const Text('No root cause data available', style: TextStyle(color: Colors.grey))
            else
              ...sortedRootCauses.map((entry) {
                final label = rootCauseLabels[entry.key] ?? entry.key.toUpperCase();
                final color = rootCauseColors[entry.key] ?? Colors.grey;
                final count = entry.value;
                final total = _lessons.length;
                final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
                          Text('$count (${percentage}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: total > 0 ? count / total : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(_getRecommendation(entry.key), style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFiveWhysTemplate() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('5 Whys Analysis Template', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Use this template to drill down to the root cause of issues', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Why ${index + 1}?',
                          border: const OutlineInputBorder(),
                          hintText: index == 0 ? 'Why did the incident occur?' : 'Why?',
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb, color: Color(0xFF1565C0)),
                  SizedBox(width: 8),
                  Expanded(child: Text('The 5th Why should reveal the root cause. Document it in the lesson record.', style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecommendation(String rootCause) {
    switch (rootCause) {
      case 'training_gap':
        return 'Recommendation: Implement targeted training program';
      case 'process_failure':
        return 'Recommendation: Review and update procedures';
      case 'communication_breakdown':
        return 'Recommendation: Improve communication channels and protocols';
      case 'resource_shortage':
        return 'Recommendation: Review resource allocation and budgeting';
      case 'environmental':
        return 'Recommendation: Address environmental factors and workspace';
      case 'equipment_failure':
        return 'Recommendation: Review equipment maintenance and replacement schedule';
      case 'staffing':
        return 'Recommendation: Review staffing levels and workload distribution';
      case 'systemic':
        return 'Recommendation: Conduct systemic review and strategic planning';
      default:
        return 'Recommendation: Investigate and address specific issues';
    }
  }
}