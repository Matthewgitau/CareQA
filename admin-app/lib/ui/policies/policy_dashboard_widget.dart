import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/policy.dart';
import '../../services/policy_service.dart';
import 'policy_list_screen.dart';

class PolicyDashboardWidget extends StatefulWidget {
  const PolicyDashboardWidget({super.key});

  @override
  State<PolicyDashboardWidget> createState() => _PolicyDashboardWidgetState();
}

class _PolicyDashboardWidgetState extends State<PolicyDashboardWidget> {
  final _service = PolicyService(Supabase.instance.client);
  bool _loading = true;
  Map<String, int> _stats = {};
  List<Policy> _reviewDue = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.getPolicyStats();
      final policies = await _service.getPolicies();
      setState(() {
        _stats = stats;
        _reviewDue = policies.where((p) => p.isReviewDue).take(5).toList();
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

    final total = _stats['total'] ?? 0;
    final published = _stats['published'] ?? 0;
    final reviewPending = _stats['review_pending'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder, color: Color(0xFF1565C0), size: 24),
                const SizedBox(width: 8),
                const Text('Policy Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PolicyListScreen()));
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
                  child: _buildStatCard('Total', total, Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Published', published, Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Review Due', reviewPending, Colors.orange),
                ),
              ],
            ),
            if (_reviewDue.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Review Due Soon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 8),
              ..._reviewDue.map((policy) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        policy.policyTitle,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${policy.daysUntilReview}d',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
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