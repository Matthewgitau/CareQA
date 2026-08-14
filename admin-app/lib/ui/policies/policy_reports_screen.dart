import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/policy.dart';
import '../../services/policy_service.dart';

class PolicyReportsScreen extends StatefulWidget {
  const PolicyReportsScreen({super.key});

  @override
  State<PolicyReportsScreen> createState() => _PolicyReportsScreenState();
}

class _PolicyReportsScreenState extends State<PolicyReportsScreen> {
  final _service = PolicyService(Supabase.instance.client);
  bool _loading = true;
  Map<String, int> _stats = {};
  List<Policy> _allPolicies = [];

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
        _allPolicies = policies;
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
        title: const Text('Policy Reports'),
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
                  _buildStatusChart(),
                  const SizedBox(height: 24),
                  _buildCategoryChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _stats['total'] ?? 0;
    final published = _stats['published'] ?? 0;
    final reviewPending = _stats['review_pending'] ?? 0;
    final mandatory = _stats['mandatory'] ?? 0;

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
            _buildSummaryCard('Total Policies', total, Colors.blue),
            _buildSummaryCard('Published', published, Colors.green),
            _buildSummaryCard('Review Pending', reviewPending, Colors.orange),
            _buildSummaryCard('Mandatory', mandatory, Colors.red),
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

  Widget _buildStatusChart() {
    final statuses = ['draft', 'review_pending', 'approved', 'published', 'archived'];
    final statusLabels = {'draft': 'Draft', 'review_pending': 'Review Pending', 'approved': 'Approved', 'published': 'Published', 'archived': 'Archived'};
    final statusColors = {'draft': Colors.grey, 'review_pending': Colors.orange, 'approved': Colors.blue, 'published': Colors.green, 'archived': Colors.teal};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Policies by Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildCategoryChart() {
    final categories = <String, int>{};
    for (final policy in _allPolicies) {
      if (policy.category != null) {
        categories[policy.category!] = (categories[policy.category!] ?? 0) + 1;
      }
    }

    final sortedCategories = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Policies by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (sortedCategories.isEmpty)
              const Text('No data available', style: TextStyle(color: Colors.grey))
            else
              ...sortedCategories.map((entry) {
                final category = entry.key.replaceAll('_', ' ').toUpperCase();
                final count = entry.value;
                final total = _allPolicies.length;
                final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(category)),
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
}