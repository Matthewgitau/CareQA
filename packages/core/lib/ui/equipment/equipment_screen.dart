import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/equipment_audit.dart';
import '../../services/equipment_service.dart';
import '../../services/auth_service.dart';

class EquipmentScreen extends StatefulWidget {
  final String serviceUserId;

  const EquipmentScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _EquipmentScreenState createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EquipmentService _equipmentService;
  late AuthService _authService;
  List<EquipmentAudit> _audits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _equipmentService = EquipmentService(Supabase.instance.client);
    _authService = AuthService();
    _loadAudits();
  }

  Future<void> _loadAudits() async {
    setState(() => _isLoading = true);
    try {
      _audits = await _equipmentService.getForServiceUser(widget.serviceUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load audits: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Audit'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'History'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewAuditTab(),
          _buildHistoryTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildNewAuditTab() {
    return NewEquipmentAudit(
      serviceUserId: widget.serviceUserId,
      onAuditCreated: () {
        _loadAudits();
        _tabController.index = 1; // Switch to history tab
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_audits.isEmpty) {
      return const Center(child: Text('No audits found'));
    }

    return ListView.builder(
      itemCount: _audits.length,
      itemBuilder: (context, index) {
        final audit = _audits[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(DateFormat('dd/MM/yyyy').format(audit.assessmentDate)),
            subtitle: Text('Status: ${audit.status}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EquipmentDetailScreen(audit: audit),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    return const Center(child: Text('Summary coming soon'));
  }
}

class NewEquipmentAudit extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onAuditCreated;

  const NewEquipmentAudit({
    Key? key,
    required this.serviceUserId,
    required this.onAuditCreated,
  }) : super(key: key);

  @override
  _NewEquipmentAuditState createState() => _NewEquipmentAuditState();
}

class _NewEquipmentAuditState extends State<NewEquipmentAudit> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _auditorController = TextEditingController();
  final _nextAuditController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _nextAuditController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 30)));
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'audit_date': '',
      'auditor_name': '',
      'hoists_lifts': '',
      'bed_rails': '',
      'wheelchairs': '',
      'pressure_relief': '',
      'medical_devices': '',
      'pat_testing': '',
      'service_dates': '',
      'overall_rating': '',
      'next_audit_date': '',
      'auditor_signature': '',
      'manager_signature': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Equipment Audit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Audit Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Audit Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _auditorController,
                    decoration: const InputDecoration(labelText: 'Auditor Name'),
                    onChanged: (value) {
                      _responses['auditor_name'] = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Audit Sections',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildAuditSection('Hoists & Lifts (LOLER)', 'hoists_lifts'),
            const SizedBox(height: 16),
            _buildAuditSection('Bed Rails Safety', 'bed_rails'),
            const SizedBox(height: 16),
            _buildAuditSection('Wheelchairs & Walking Aids', 'wheelchairs'),
            const SizedBox(height: 16),
            _buildAuditSection('Pressure Relief Equipment', 'pressure_relief'),
            const SizedBox(height: 16),
            _buildAuditSection('Medical Devices', 'medical_devices'),
            const SizedBox(height: 16),
            _buildAuditSection('PAT Testing Status', 'pat_testing'),
            const SizedBox(height: 24),
            Text(
              'Service Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nextAuditController,
              decoration: const InputDecoration(
                labelText: 'Next Audit Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  _nextAuditController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
              onChanged: (value) {
                _responses['next_audit_date'] = value;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Equipment Service Dates',
                hintText: 'List service dates for all equipment',
              ),
              maxLines: 3,
              onChanged: (value) {
                _responses['service_dates'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Overall Rating',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _responses['overall_rating'],
              decoration: const InputDecoration(labelText: 'Overall Rating'),
              items: [
                DropdownMenuItem(value: 'green', child: Text('Green - All Good')),
                DropdownMenuItem(value: 'amber', child: Text('Amber - Some Issues')),
                DropdownMenuItem(value: 'red', child: Text('Red - Major Issues')),
              ],
              onChanged: (value) {
                _responses['overall_rating'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Signatures',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Auditor Signature'),
                    onChanged: (value) {
                      _responses['auditor_signature'] = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Manager Signature'),
                    onChanged: (value) {
                      _responses['manager_signature'] = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Action Plan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ActionPlanWidget(
              onActionPlanChanged: (actionPlan) {
                _responses['action_plan'] = actionPlan;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAudit,
                    child: const Text('Save Audit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditSection(String title, String fieldKey) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _responses[fieldKey],
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                DropdownMenuItem(value: 'pass', child: Text('Pass')),
                DropdownMenuItem(value: 'fail', child: Text('Fail')),
                DropdownMenuItem(value: 'action_required', child: Text('Action Required')),
                DropdownMenuItem(value: 'n_a', child: Text('N/A')),
              ],
              onChanged: (value) {
                _responses[fieldKey] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAudit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      final audit = EquipmentAudit(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _equipmentService.create(audit);
      widget.onAuditCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audit saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save audit: $e')),
      );
    }
  }
}

class ActionPlanWidget extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onActionPlanChanged;

  const ActionPlanWidget({Key? key, required this.onActionPlanChanged}) : super(key: key);

  @override
  _ActionPlanWidgetState createState() => _ActionPlanWidgetState();
}

class _ActionPlanWidgetState extends State<ActionPlanWidget> {
  List<Map<String, dynamic>> _actionItems = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._actionItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'What'),
                          initialValue: item['what'] ?? '',
                          onChanged: (value) {
                            _actionItems[index]['what'] = value;
                            widget.onActionPlanChanged(_actionItems);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Who'),
                          initialValue: item['who'] ?? '',
                          onChanged: (value) {
                            _actionItems[index]['who'] = value;
                            widget.onActionPlanChanged(_actionItems);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'By When'),
                    initialValue: item['by_when'] ?? '',
                    onChanged: (value) {
                      _actionItems[index]['by_when'] = value;
                      widget.onActionPlanChanged(_actionItems);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _removeActionItem(index),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addActionItem,
          icon: const Icon(Icons.add),
          label: const Text('Add Action Item'),
        ),
      ],
    );
  }

  void _addActionItem() {
    setState(() {
      _actionItems.add({
        'what': '',
        'who': '',
        'by_when': '',
      });
      widget.onActionPlanChanged(_actionItems);
    });
  }

  void _removeActionItem(int index) {
    setState(() {
      _actionItems.removeAt(index);
      widget.onActionPlanChanged(_actionItems);
    });
  }
}

class EquipmentDetailScreen extends StatelessWidget {
  final EquipmentAudit audit;

  const EquipmentDetailScreen({Key? key, required this.audit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Equipment Audit - ${DateFormat('dd/MM/yyyy').format(audit.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${audit.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildAuditDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Information',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Auditor: ${audit.responses['auditor_name'] ?? ''}'),
            const SizedBox(height: 8),
            Text(
              'Audit Results',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildAuditResult('Hoists & Lifts (LOLER)', audit.responses['hoists_lifts'] ?? ''),
            _buildAuditResult('Bed Rails Safety', audit.responses['bed_rails'] ?? ''),
            _buildAuditResult('Wheelchairs & Walking Aids', audit.responses['wheelchairs'] ?? ''),
            _buildAuditResult('Pressure Relief Equipment', audit.responses['pressure_relief'] ?? ''),
            _buildAuditResult('Medical Devices', audit.responses['medical_devices'] ?? ''),
            _buildAuditResult('PAT Testing Status', audit.responses['pat_testing'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'Service Dates: ${audit.responses['service_dates'] ?? ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Overall Rating: ${_getRatingLabel(audit.responses['overall_rating'] ?? '')}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Next Audit: ${audit.responses['next_audit_date'] ?? ''}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Auditor Signature: ${audit.responses['auditor_signature'] ?? ''}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Manager Signature: ${audit.responses['manager_signature'] ?? ''}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditResult(String title, String result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$title: '),
          Text(
            _getResultLabel(result),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getResultColor(result),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlan() {
    if (audit.actionPlan.isEmpty) {
      return const Text('No action plan items');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Action Plan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...audit.actionPlan.map((item) => Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What: ${item['what'] ?? ''}'),
                      Text('Who: ${item['who'] ?? ''}'),
                      Text('By When: ${item['by_when'] ?? ''}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  String _getResultLabel(String result) {
    switch (result) {
      case 'pass': return 'Pass';
      case 'fail': return 'Fail';
      case 'action_required': return 'Action Required';
      case 'n_a': return 'N/A';
      default: return result;
    }
  }

  Color _getResultColor(String result) {
    switch (result) {
      case 'pass': return Colors.green;
      case 'fail': return Colors.red;
      case 'action_required': return Colors.orange;
      default: return Colors.black;
    }
  }

  String _getRatingLabel(String rating) {
    switch (rating) {
      case 'green': return 'Green - All Good';
      case 'amber': return 'Amber - Some Issues';
      case 'red': return 'Red - Major Issues';
      default: return rating;
    }
  }
}