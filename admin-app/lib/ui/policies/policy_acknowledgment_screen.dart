import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/policy.dart';
import '../../services/policy_service.dart';

class PolicyAcknowledgmentScreen extends StatefulWidget {
  const PolicyAcknowledgmentScreen({super.key});

  @override
  State<PolicyAcknowledgmentScreen> createState() => _PolicyAcknowledgmentScreenState();
}

class _PolicyAcknowledgmentScreenState extends State<PolicyAcknowledgmentScreen> {
  final _service = PolicyService(Supabase.instance.client);
  bool _loading = true;
  List<Policy> _policies = [];
  String? _staffId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _staffId = Supabase.instance.client.auth.currentUser?.id;
      if (_staffId != null) {
        final policies = await _service.getPoliciesForAcknowledgment(_staffId!);
        setState(() {
          _policies = policies;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _acknowledgePolicy(Policy policy) async {
    try {
      await _service.recordRead(policy.id!, _staffId!);
      await _service.recordAcknowledgment(policy.id!, _staffId!, acknowledged: true);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Acknowledged: ${policy.policyTitle}'), backgroundColor: Colors.green));
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
        title: const Text('Policy Acknowledgment'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _policies.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text('All policies acknowledged', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('No pending acknowledgments', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _policies.length,
                  itemBuilder: (context, index) {
                    final policy = _policies[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(policy.policyTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: policy.statusColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(policy.statusLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(policy.policyReference, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            if (policy.summary != null) ...[
                              const SizedBox(height: 8),
                              Text(policy.summary!, style: const TextStyle(fontSize: 14)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (policy.trainingRequired)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.school, size: 14, color: Colors.blue.shade700),
                                        const SizedBox(width: 4),
                                        Text('Training Required', style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                                      ],
                                    ),
                                  ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () => _acknowledgePolicy(policy),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Acknowledge'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1565C0),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}