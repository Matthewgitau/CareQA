import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/fire_safety_audit.dart';
import '../../services/fire_safety_service.dart';
import '../../services/auth_service.dart';

class FireSafetyScreen extends StatefulWidget {
  final String serviceUserId;

  const FireSafetyScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _FireSafetyScreenState createState() => _FireSafetyScreenState();
}

class _FireSafetyScreenState extends State<FireSafetyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FireSafetyService _fireSafetyService;
  late AuthService _authService;
  List<FireSafetyAudit> _audits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fireSafetyService = FireSafetyService(Supabase.instance.client);
    _authService = AuthService();
    _loadAudits();
  }

  Future<void> _loadAudits() async {
    setState(() => _isLoading = true);
    try {
      _audits = await _fireSafetyService.getForServiceUser(widget.serviceUserId);
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
        title: const Text('Fire Safety Audit'),
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
    return NewFireSafetyAudit(
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
                  builder: (context) => FireSafetyDetailScreen(audit: audit),
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

class NewFireSafetyAudit extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onAuditCreated;

  const NewFireSafetyAudit({
    Key? key,
    required this.serviceUserId,
    required this.onAuditCreated,
  }) : super(key: key);

  @override
  _NewFireSafetyAuditState createState() => _NewFireSafetyAuditState();
}

class _NewFireSafetyAuditState extends State<NewFireSafetyAudit> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _auditorController = TextEditingController();
  final _lastDrillController = TextEditingController();
  final _nextAuditController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _lastDrillController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 90)));
    _nextAuditController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 30)));
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'audit_date': '',
      'auditor_name': '',
      'fire_detection': '',
      'fire_fighting': '',
      'means_of_escape': '',
      'evacuation_procedures': '',
      'staff_training': '',
      'peep_in_place': '',
      'last_fire_drill': '',
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
              'New Fire Safety Audit',
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
            _buildAuditSection('Fire Detection & Warning Systems', 'fire_detection'),
            const SizedBox(height: 16),
            _buildAuditSection('Fire Fighting Equipment', 'fire_fighting'),
            const SizedBox(height: 16),
            _buildAuditSection('Means of Escape', 'means_of_escape'),
            const SizedBox(height: 16),
            _buildAuditSection('Evacuation Procedures', 'evacuation_procedures'),
            const SizedBox(height: 16),
            _buildAuditSection('Staff Training Records', 'staff_training'),
            const SizedBox(height: 16),
            _buildAuditSection('PEEP in Place', 'peep_in_place'),
            const SizedBox(height: 24),
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastDrillController,
              decoration: const InputDecoration(
                labelText: 'Last Fire Drill Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 90)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _lastDrillController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
              onChanged: (value) {
                _responses['last_fire_drill'] = value;
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

      final audit = FireSafetyAudit(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _fireSafetyService.create(audit);
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

class FireSafetyDetailScreen extends StatelessWidget {
  final FireSafetyAudit audit;

  const FireSafetyDetailScreen({Key? key, required this.audit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fire Safety Audit - ${DateFormat('dd/MM/yyyy').format(audit.assessmentDate)}')),
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
            _buildAuditResult('Fire Detection & Warning Systems', audit.responses['fire_detection'] ?? ''),
            _buildAuditResult('Fire Fighting Equipment', audit.responses['fire_fighting'] ?? ''),
            _buildAuditResult('Means of Escape', audit.responses['means_of_escape'] ?? ''),
            _buildAuditResult('Evacuation Procedures', audit.responses['evacuation_procedures'] ?? ''),
            _buildAuditResult('Staff Training Records', audit.responses['staff_training'] ?? ''),
            _buildAuditResult('PEEP in Place', audit.responses['peep_in_place'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'Last Fire Drill: ${audit.responses['last_fire_drill'] ?? ''}',
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