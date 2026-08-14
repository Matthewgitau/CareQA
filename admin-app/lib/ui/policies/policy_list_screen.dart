import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/policy.dart';
import '../../services/policy_service.dart';
import 'policy_form.dart';

class PolicyListScreen extends StatefulWidget {
  const PolicyListScreen({super.key});

  @override
  State<PolicyListScreen> createState() => _PolicyListScreenState();
}

class _PolicyListScreenState extends State<PolicyListScreen> {
  final _service = PolicyService(Supabase.instance.client);
  bool _loading = true;
  List<Policy> _policies = [];
  String? _filterStatus;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  Future<void> _loadPolicies() async {
    setState(() => _loading = true);
    try {
      final policies = await _service.getPolicies(
        status: _filterStatus,
        category: _filterCategory,
      );
      setState(() {
        _policies = policies;
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
        title: const Text('Policy Library'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyFormScreen()));
              await _loadPolicies();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _policies.isEmpty
                    ? const Center(child: Text('No policies found', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _policies.length,
                        itemBuilder: (context, index) {
                          final policy = _policies[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: policy.statusColor,
                                child: Text(policy.status[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(policy.policyTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(policy.policyReference),
                                  Text(policy.categoryLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: policy.statusColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(policy.statusLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  if (policy.isReviewDue)
                                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                                ],
                              ),
                              onTap: () {
                                // View details
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              value: _filterStatus,
              items: const [
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'review_pending', child: Text('Review Pending')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'published', child: Text('Published')),
                DropdownMenuItem(value: 'archived', child: Text('Archived')),
              ],
              onChanged: (v) {
                setState(() => _filterStatus = v);
                _loadPolicies();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              value: _filterCategory,
              items: const [
                DropdownMenuItem(value: 'clinical', child: Text('Clinical')),
                DropdownMenuItem(value: 'governance', child: Text('Governance')),
                DropdownMenuItem(value: 'health_safety', child: Text('Health & Safety')),
                DropdownMenuItem(value: 'human_resources', child: Text('Human Resources')),
                DropdownMenuItem(value: 'finance', child: Text('Finance')),
                DropdownMenuItem(value: 'data_protection', child: Text('Data Protection')),
                DropdownMenuItem(value: 'safeguarding', child: Text('Safeguarding')),
                DropdownMenuItem(value: 'medication', child: Text('Medication')),
                DropdownMenuItem(value: 'quality', child: Text('Quality')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) {
                setState(() => _filterCategory = v);
                _loadPolicies();
              },
            ),
          ),
        ],
      ),
    );
  }
}