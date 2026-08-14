import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/action_plan.dart';
import '../../services/action_plan_service.dart';
import 'action_plan_list_screen.dart';

class ActionPlanWidget extends StatefulWidget {
  const ActionPlanWidget({super.key});

  @override
  State<ActionPlanWidget> createState() => _ActionPlanWidgetState();
}

class _ActionPlanWidgetState extends State<ActionPlanWidget> {
  final _service = ActionPlanService(Supabase.instance.client);
  bool _loading = true;
  Map<String, int> _stats = {};
  List<ActionPlan> _overdue = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.getActionPlanStats();
      final overdue = await _service.getOverdueActionPlans();
      setState(() {
        _stats = stats;
        _overdue = overdue.take(5).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final openCount = _stats['open'] ?? 0;
    final inProgressCount = _stats['in_progress'] ?? 0;
    final overdueCount = _stats['overdue'] ?? 0;
    final totalCount = _stats['total'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Color(0xFF1565C0), size: 24),
                const SizedBox(width: 8),
                const Text('Action Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ActionPlanListScreen()));
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Open', openCount, Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('In Progress', inProgressCount, Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Overdue', overdueCount, Colors.red),
                ),
              ],
            ),
            if (_overdue.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Overdue Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              ..._overdue.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.title,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${plan.daysOverdue}d',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}