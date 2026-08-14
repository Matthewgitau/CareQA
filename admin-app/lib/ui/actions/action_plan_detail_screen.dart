import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/action_plan.dart';
import '../../services/action_plan_service.dart';

class ActionPlanDetailScreen extends StatefulWidget {
  final String actionPlanId;
  const ActionPlanDetailScreen({super.key, required this.actionPlanId});

  @override
  State<ActionPlanDetailScreen> createState() => _ActionPlanDetailScreenState();
}

class _ActionPlanDetailScreenState extends State<ActionPlanDetailScreen> {
  final _service = ActionPlanService(Supabase.instance.client);
  bool _loading = true;
  ActionPlan? _plan;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _loading = true);
    try {
      final plan = await _service.getActionPlan(widget.actionPlanId);
      setState(() {
        _plan = plan;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_plan == null) return;
    try {
      await _service.updateActionPlan(_plan!.id!, {'status': status});
      await _loadPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _addUpdateNote() async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Update Note'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, noteController.text), child: const Text('Add')),
        ],
      ),
    );

    if (note == null || note.isEmpty) return;

    try {
      await _service.addUpdateLog(_plan!.id!, note);
      await _loadPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update note added'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan?.referenceNumber ?? 'Action Plan Details'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_plan != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'edit') {
                  Navigator.pop(context);
                } else if (v == 'delete') {
                  _deletePlan();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plan == null
              ? const Center(child: Text('Action plan not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildDetailsCard(),
                      const SizedBox(height: 16),
                      _buildProgressCard(),
                      const SizedBox(height: 16),
                      _buildUpdateLogCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_plan!.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _plan!.priorityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_plan!.priority.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_plan!.referenceNumber, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            if (_plan!.description != null) ...[
              const SizedBox(height: 12),
              Text(_plan!.description!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _plan!.statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_plan!.statusLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_plan!.isOverdue) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('${_plan!.daysOverdue} days overdue', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ] else ...[
              Text('${_plan!.daysRemaining} days remaining', style: TextStyle(color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(onPressed: () => _updateStatus('in_progress'), child: const Text('Mark In Progress')),
                ElevatedButton(onPressed: () => _updateStatus('completed'), child: const Text('Mark Complete')),
                if (_plan!.verificationRequired)
                  ElevatedButton(onPressed: () => _updateStatus('verified'), child: const Text('Verify')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow('Source Type', _plan!.sourceType?.replaceAll('_', ' ').toUpperCase()),
            _detailRow('Category', _plan!.category?.replaceAll('_', ' ').toUpperCase()),
            _detailRow('Action Type', _plan!.actionType?.replaceAll('_', ' ').toUpperCase()),
            _detailRow('Assigned To', _plan!.assignedToName),
            _detailRow('Assigned Date', _plan!.assignedDate.toString().split(' ')[0]),
            _detailRow('Target Completion', _plan!.targetCompletionDate.toString().split(' ')[0]),
            if (_plan!.actualCompletionDate != null)
              _detailRow('Actual Completion', _plan!.actualCompletionDate.toString().split(' ')[0]),
            if (_plan!.regulatoryReference != null)
              _detailRow('Regulatory Reference', _plan!.regulatoryReference),
            if (_plan!.complianceRequirement != null)
              _detailRow('Compliance Requirement', _plan!.complianceRequirement),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _plan!.progressPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_plan!.progressPercentage == 100 ? Colors.green : Colors.blue),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text('${_plan!.progressPercentage}% Complete', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Action Required:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_plan!.actionRequired, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateLogCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Update Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(onPressed: _addUpdateNote, icon: const Icon(Icons.add), label: const Text('Add Note')),
              ],
            ),
            const SizedBox(height: 12),
            if (_plan!.updateLog.isEmpty)
              const Text('No updates yet', style: TextStyle(color: Colors.grey))
            else
              ..._plan!.updateLog.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry['note'] ?? '', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(entry['date'])),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
          Expanded(child: Text(value ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Future<void> _deletePlan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Action Plan'),
        content: Text('Are you sure you want to delete ${_plan!.referenceNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteActionPlan(_plan!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action plan deleted'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}