import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supervision_record.dart';
import '../../services/supervision_service.dart';
import '../../services/auth_service.dart';

class SupervisionScreen extends StatefulWidget {
  final String serviceUserId;

  const SupervisionScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _SupervisionScreenState createState() => _SupervisionScreenState();
}

class _SupervisionScreenState extends State<SupervisionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SupervisionService _supervisionService;
  late AuthService _authService;
  List<SupervisionRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _supervisionService = SupervisionService(Supabase.instance.client);
    _authService = AuthService();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      _records = await _supervisionService.getForServiceUser(widget.serviceUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load records: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervision Record'),
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
          _buildNewRecordTab(),
          _buildHistoryTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildNewRecordTab() {
    return NewSupervisionRecord(
      serviceUserId: widget.serviceUserId,
      onRecordCreated: () {
        _loadRecords();
        _tabController.index = 1; // Switch to history tab
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return const Center(child: Text('No supervision records found'));
    }

    return ListView.builder(
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(DateFormat('dd/MM/yyyy').format(record.assessmentDate)),
            subtitle: Text('Status: ${record.status}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SupervisionDetailScreen(record: record),
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

class NewSupervisionRecord extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onRecordCreated;

  const NewSupervisionRecord({
    Key? key,
    required this.serviceUserId,
    required this.onRecordCreated,
  }) : super(key: key);

  @override
  _NewSupervisionRecordState createState() => _NewSupervisionRecordState();
}

class _NewSupervisionRecordState extends State<NewSupervisionRecord> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _staffController = TextEditingController();
  final _nextSupervisionController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _nextSupervisionController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 90)));
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'supervision_date': '',
      'supervisor_name': '',
      'staff_name': '',
      'previous_actions': '',
      'performance_discussion': '',
      'workload_wellbeing': '',
      'training_needs': '',
      'next_supervision_date': '',
      'staff_signature': '',
      'supervisor_signature': '',
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
              'New Supervision Record',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Supervision Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Supervision Date',
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
                    controller: _supervisorController,
                    decoration: const InputDecoration(labelText: 'Supervisor Name'),
                    onChanged: (value) {
                      _responses['supervisor_name'] = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _staffController,
              decoration: const InputDecoration(labelText: 'Staff Name'),
              onChanged: (value) {
                _responses['staff_name'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Review of Previous Supervision',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Actions from Previous Supervision',
                hintText: 'Review progress on previous agreed actions',
              ),
              maxLines: 4,
              onChanged: (value) {
                _responses['previous_actions'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Current Discussion',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Performance & Practice Discussion',
                hintText: 'Discuss performance, practice, challenges',
              ),
              maxLines: 6,
              onChanged: (value) {
                _responses['performance_discussion'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Workload & Wellbeing Check',
                hintText: 'Discuss workload, stress, support needs',
              ),
              maxLines: 4,
              onChanged: (value) {
                _responses['workload_wellbeing'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Training & Development Needs',
                hintText: 'Identify training needs and development opportunities',
              ),
              maxLines: 4,
              onChanged: (value) {
                _responses['training_needs'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Agreed Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ActionPlanWidget(
              onActionPlanChanged: (actionPlan) {
                _responses['action_plan'] = actionPlan;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Next Supervision',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nextSupervisionController,
              decoration: const InputDecoration(
                labelText: 'Next Supervision Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  _nextSupervisionController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
              onChanged: (value) {
                _responses['next_supervision_date'] = value;
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
                    decoration: const InputDecoration(labelText: 'Staff Signature'),
                    onChanged: (value) {
                      _responses['staff_signature'] = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Supervisor Signature'),
                    onChanged: (value) {
                      _responses['supervisor_signature'] = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveRecord,
                    child: const Text('Save Supervision Record'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      final record = SupervisionRecord(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _supervisionService.create(record);
      widget.onRecordCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supervision record saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save record: $e')),
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

class SupervisionDetailScreen extends StatelessWidget {
  final SupervisionRecord record;

  const SupervisionDetailScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Supervision Record - ${DateFormat('dd/MM/yyyy').format(record.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${record.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildRecordDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supervision Information',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Supervisor: ${record.responses['supervisor_name'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Staff: ${record.responses['staff_name'] ?? ''}'),
            const SizedBox(height: 8),
            Text(
              'Review of Previous Actions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(record.responses['previous_actions'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'Performance & Practice Discussion',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(record.responses['performance_discussion'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'Workload & Wellbeing',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(record.responses['workload_wellbeing'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'Training & Development Needs',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(record.responses['training_needs'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'Next Supervision: ${record.responses['next_supervision_date'] ?? ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Staff Signature: ${record.responses['staff_signature'] ?? ''}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Supervisor Signature: ${record.responses['supervisor_signature'] ?? ''}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPlan() {
    if (record.actionPlan.isEmpty) {
      return const Text('No action plan items');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agreed Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...record.actionPlan.map((item) => Card(
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
}