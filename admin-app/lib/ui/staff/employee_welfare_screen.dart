import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/welfare_check.dart';
import '../../services/welfare_service.dart';
import 'welfare_check_form.dart';

class EmployeeWelfareScreen extends StatefulWidget {
  const EmployeeWelfareScreen({super.key});

  @override
  State<EmployeeWelfareScreen> createState() => _EmployeeWelfareScreenState();
}

class _EmployeeWelfareScreenState extends State<EmployeeWelfareScreen> with SingleTickerProviderStateMixin {
  final _service = WelfareService(Supabase.instance.client);
  List<WelfareCheck> _welfareChecks = [];
  bool _isLoading = true;
  String? _selectedStaffId;

  @override
  void initState() {
    super.initState();
    _loadWelfareChecks();
  }

  Future<void> _loadWelfareChecks() async {
    setState(() => _isLoading = true);
    try {
      final checks = await _service.getWelfareChecks();
      if (mounted) {
        setState(() {
          _welfareChecks = checks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading welfare checks: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _filterByStaff(String? staffId) async {
    setState(() => _selectedStaffId = staffId);
    if (staffId == null) {
      _loadWelfareChecks();
    } else {
      setState(() => _isLoading = true);
      try {
        final checks = await _service.getWelfareChecksForStaff(staffId);
        if (mounted) {
          setState(() {
            _welfareChecks = checks;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Welfare & Wellbeing'),
        actions: [
          IconButton(
            onPressed: _addWelfareCheck,
            icon: const Icon(Icons.add),
            tooltip: 'New Welfare Check',
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
                      const Icon(Icons.filter_list, size: 20),
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
                              onChanged: _filterByStaff,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Welfare Checks List
                Expanded(
                  child: _welfareChecks.isEmpty
                      ? const Center(child: Text('No welfare checks found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _welfareChecks.length,
                          itemBuilder: (context, index) {
                            final check = _welfareChecks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color(check.getWellbeingColorValue()),
                                  child: Text(
                                    check.wellbeingScore?.toString() ?? '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  check.staffName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(check.getCheckTypeDisplay()),
                                    Text('${DateFormat('dd/MM/yyyy').format(check.checkDate)} • Score: ${check.wellbeingScore ?? 'N/A'}/10'),
                                    if (check.stressScore != null)
                                      Text('Stress: ${check.stressScore}/10 • Satisfaction: ${check.jobSatisfactionScore}/10'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Color(check.getWellbeingColorValue() ?? 0xFF9E9E9E),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        check.getWellbeingStatus(),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (check.followUpRequired)
                                      const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                                  ],
                                ),
                                onTap: () => _viewWelfareCheckDetails(check),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWelfareCheck,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _viewWelfareCheckDetails(WelfareCheck check) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${check.getCheckTypeDisplay()} - ${check.staffName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date', DateFormat('dd/MM/yyyy').format(check.checkDate)),
              _buildDetailRow('Time', check.checkTime),
              _buildDetailRow('Wellbeing Score', '${check.wellbeingScore ?? 'N/A'}/10 (${check.getWellbeingStatus()})'),
              if (check.stressScore != null) _buildDetailRow('Stress Score', '${check.stressScore}/10'),
              if (check.jobSatisfactionScore != null) _buildDetailRow('Job Satisfaction', '${check.jobSatisfactionScore}/10'),
              if (check.workloadScore != null) _buildDetailRow('Workload Score', '${check.workloadScore}/10'),
              if (check.anxietyLevel != null) _buildDetailRow('Anxiety Level', check.anxietyLevel!),
              if (check.depressionSymptoms != null) _buildDetailRow('Depression Symptoms', check.depressionSymptoms!),
              if (check.burnoutSymptoms != null) _buildDetailRow('Burnout Symptoms', check.burnoutSymptoms!),
              if (check.sleepingIssues != null) _buildDetailRow('Sleeping Issues', check.sleepingIssues!),
              if (check.workloadManageable != null) _buildDetailRow('Workload Manageable', check.workloadManageable! ? 'Yes' : 'No'),
              if (check.supportAvailable != null) _buildDetailRow('Support Available', check.supportAvailable! ? 'Yes' : 'No'),
              if (check.teamRelationships != null) _buildDetailRow('Team Relationships', check.teamRelationships!),
              if (check.managerSupport != null) _buildDetailRow('Manager Support', check.managerSupport!),
              if (check.workLifeBalance != null) _buildDetailRow('Work-Life Balance', check.workLifeBalance!),
              if (check.caringResponsibilities) _buildDetailRow('Caring Responsibilities', 'Yes'),
              if (check.identifiedStressors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Identified Stressors:', style: const TextStyle(fontWeight: FontWeight.bold)),
                ...check.identifiedStressors.map((s) => Text('• $s')),
              ],
              if (check.supportProvided != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Support Provided:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(check.supportProvided!),
              ],
              if (check.referralMade) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Referral:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Text('Type: ${check.referralType ?? 'N/A'}'),
                if (check.referralDate != null)
                  Text('Date: ${DateFormat('dd/MM/yyyy').format(check.referralDate!)}'),
              ],
              if (check.followUpRequired) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Follow-up Required', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                if (check.followUpDate != null)
                  Text('Date: ${DateFormat('dd/MM/yyyy').format(check.followUpDate!)}'),
              ],
              if (check.actionPlan != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Action Plan:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(check.actionPlan!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addWelfareCheck() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WelfareCheckFormScreen()),
    );
    if (result == true) {
      _loadWelfareChecks();
    }
  }
}
