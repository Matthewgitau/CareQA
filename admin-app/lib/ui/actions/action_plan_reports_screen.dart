import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/action_plan.dart';
import '../../services/action_plan_service.dart';

class ActionPlanReportsScreen extends StatefulWidget {
  const ActionPlanReportsScreen({super.key});

  @override
  State<ActionPlanReportsScreen> createState() => _ActionPlanReportsScreenState();
}

class _ActionPlanReportsScreenState extends State<ActionPlanReportsScreen> {
  final _service = ActionPlanService(Supabase.instance.client);
  bool _loading = true;
  Map<String, int> _stats = {};
  List<ActionPlan> _allPlans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.getActionPlanStats();
      final plans = await _service.getActionPlans();
      setState(() {
        _stats = stats;
        _allPlans = plans;
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
        title: const Text('Action Plan Reports'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCsv,
            tooltip: 'Export CSV',
          ),
        ],
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
                  _buildPriorityChart(),
                  const SizedBox(height: 24),
                  _buildCategoryChart(),
                  const SizedBox(height: 24),
                  _buildOverdueSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _stats['total'] ?? 0;
    final open = _stats['open'] ?? 0;
    final inProgress = _stats['in_progress'] ?? 0;
    final completed = _stats['completed'] ?? 0;
    final overdue = _stats['overdue'] ?? 0;

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
            _buildSummaryCard('Total Actions', total, Colors.blue),
            _buildSummaryCard('Open', open, Colors.orange),
            _buildSummaryCard('In Progress', inProgress, Colors.purple),
            _buildSummaryCard('Completed', completed, Colors.green),
            _buildSummaryCard('Overdue', overdue, Colors.red),
            _buildSummaryCard('Completion Rate', total > 0 ? '${((completed / total) * 100).toStringAsFixed(1)}%' : '0%', Colors.teal),
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
    final statuses = ['open', 'in_progress', 'under_review', 'completed', 'verified', 'closed', 'overdue'];
    final statusLabels = {'open': 'Open', 'in_progress': 'In Progress', 'under_review': 'Under Review', 'completed': 'Completed', 'verified': 'Verified', 'closed': 'Closed', 'overdue': 'Overdue'};
    final statusColors = {'open': Colors.blue, 'in_progress': Colors.orange, 'under_review': Colors.purple, 'completed': Colors.green, 'verified': Colors.teal, 'closed': Colors.grey, 'overdue': Colors.red};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actions by Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildPriorityChart() {
    final priorities = ['critical', 'high', 'medium', 'low'];
    final priorityLabels = {'critical': 'Critical', 'high': 'High', 'medium': 'Medium', 'low': 'Low'};
    final priorityColors = {'critical': Colors.red, 'high': Colors.orange, 'medium': Colors.yellow, 'low': Colors.green};

    final priorityCounts = <String, int>{};
    for (final plan in _allPlans) {
      priorityCounts[plan.priority] = (priorityCounts[plan.priority] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actions by Priority', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...priorities.map((priority) {
              final count = priorityCounts[priority] ?? 0;
              final total = _allPlans.length;
              final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: priorityColors[priority], shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(priorityLabels[priority]!)),
                        Text('$count (${percentage}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: total > 0 ? count / total : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(priorityColors[priority]!),
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
    for (final plan in _allPlans) {
      if (plan.category != null) {
        categories[plan.category!] = (categories[plan.category!] ?? 0) + 1;
      }
    }

    final sortedCategories = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actions by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (sortedCategories.isEmpty)
              const Text('No data available', style: TextStyle(color: Colors.grey))
            else
              ...sortedCategories.map((entry) {
                final category = entry.key.replaceAll('_', ' ').toUpperCase();
                final count = entry.value;
                final total = _allPlans.length;
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

  Widget _buildOverdueSection() {
    final overduePlans = _allPlans.where((p) => p.isOverdue).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text('Overdue Actions (${overduePlans.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
            if (overduePlans.isEmpty)
              const Text('No overdue actions', style: TextStyle(color: Colors.grey))
            else
              ...overduePlans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${plan.referenceNumber} • ${plan.assignedToName ?? 'Unassigned'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${plan.daysOverdue}d overdue', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final buf = StringBuffer();
      buf.writeln('Action Plan Report - ${DateTime.now().toString().split(' ')[0]}');
      buf.writeln();
      buf.writeln('Reference,Title,Status,Priority,Assigned To,Due Date,Days Overdue');
      for (final plan in _allPlans) {
        final overdue = plan.isOverdue ? plan.daysOverdue : 0;
        buf.writeln('${plan.referenceNumber},"${plan.title.replaceAll('"', '""')}",${plan.statusLabel},${plan.priority},${plan.assignedToName ?? ''},${plan.targetCompletionDate.toString().split(' ')[0]},$overdue');
      }

      final file = File('action_plans_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Action Plan Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}