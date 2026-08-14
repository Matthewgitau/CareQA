import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appraisal_form.dart';
import '../../services/appraisal_service.dart';
import '../../services/auth_service.dart';

class AppraisalScreen extends StatefulWidget {
  final String serviceUserId;

  const AppraisalScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _AppraisalScreenState createState() => _AppraisalScreenState();
}

class _AppraisalScreenState extends State<AppraisalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppraisalService _appraisalService;
  late AuthService _authService;
  List<AppraisalForm> _forms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _appraisalService = AppraisalService(Supabase.instance.client);
    _authService = AuthService();
    _loadForms();
  }

  Future<void> _loadForms() async {
    setState(() => _isLoading = true);
    try {
      _forms = await _appraisalService.getForServiceUser(widget.serviceUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load forms: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appraisal Form'),
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
          _buildNewFormTab(),
          _buildHistoryTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildNewFormTab() {
    return NewAppraisalForm(
      serviceUserId: widget.serviceUserId,
      onFormCreated: () {
        _loadForms();
        _tabController.index = 1; // Switch to history tab
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_forms.isEmpty) {
      return const Center(child: Text('No appraisal forms found'));
    }

    return ListView.builder(
      itemCount: _forms.length,
      itemBuilder: (context, index) {
        final form = _forms[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(DateFormat('dd/MM/yyyy').format(form.assessmentDate)),
            subtitle: Text('Status: ${form.status}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppraisalDetailScreen(form: form),
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

class NewAppraisalForm extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onFormCreated;

  const NewAppraisalForm({
    Key? key,
    required this.serviceUserId,
    required this.onFormCreated,
  }) : super(key: key);

  @override
  _NewAppraisalFormState createState() => _NewAppraisalFormState();
}

class _NewAppraisalFormState extends State<NewAppraisalForm> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _appraiserController = TextEditingController();
  final _staffController = TextEditingController();
  final _nextAppraisalController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _nextAppraisalController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 365)));
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'appraisal_date': '',
      'appraiser_name': '',
      'staff_name': '',
      'previous_objectives': [
        {'objective': '', 'outcome': '', 'comments': ''},
        {'objective': '', 'outcome': '', 'comments': ''},
        {'objective': '', 'outcome': '', 'comments': ''},
      ],
      'overall_performance': '',
      'values_behaviours': '',
      'training_needs': '',
      'new_objectives': [
        {'objective': '', 'target_date': ''},
        {'objective': '', 'target_date': ''},
        {'objective': '', 'target_date': ''},
      ],
      'staff_comments': '',
      'next_appraisal_date': '',
      'staff_signature': '',
      'appraiser_signature': '',
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
              'New Appraisal Form',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Appraisal Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Appraisal Date',
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
                    controller: _appraiserController,
                    decoration: const InputDecoration(labelText: 'Appraiser Name'),
                    onChanged: (value) {
                      _responses['appraiser_name'] = value;
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
              'Review of Previous Objectives',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            PreviousObjectivesWidget(
              objectives: _responses['previous_objectives'],
              onObjectivesChanged: (objectives) {
                _responses['previous_objectives'] = objectives;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Overall Performance Rating',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _responses['overall_performance'],
              decoration: const InputDecoration(labelText: 'Overall Performance'),
              items: [
                DropdownMenuItem(value: 'exceptional', child: Text('Exceptional')),
                DropdownMenuItem(value: 'exceeds_expectations', child: Text('Exceeds Expectations')),
                DropdownMenuItem(value: 'meets_expectations', child: Text('Meets Expectations')),
                DropdownMenuItem(value: 'partially_meets', child: Text('Partially Meets Expectations')),
                DropdownMenuItem(value: 'does_not_meet', child: Text('Does Not Meet Expectations')),
              ],
              onChanged: (value) {
                _responses['overall_performance'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Values & Behaviours Assessment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Values & Behaviours',
                hintText: 'Assess alignment with organizational values and behaviours',
              ),
              maxLines: 4,
              onChanged: (value) {
                _responses['values_behaviours'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Training & Development Needs',
              style: Theme.of(context).textTheme.titleMedium,
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
              'New Objectives',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            NewObjectivesWidget(
              objectives: _responses['new_objectives'],
              onObjectivesChanged: (objectives) {
                _responses['new_objectives'] = objectives;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Staff Comments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Staff Comments',
                hintText: 'Staff comments on appraisal process and outcomes',
              ),
              maxLines: 4,
              onChanged: (value) {
                _responses['staff_comments'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Next Appraisal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nextAppraisalController,
              decoration: const InputDecoration(
                labelText: 'Next Appraisal Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  _nextAppraisalController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
              onChanged: (value) {
                _responses['next_appraisal_date'] = value;
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
                    decoration: const InputDecoration(labelText: 'Appraiser Signature'),
                    onChanged: (value) {
                      _responses['appraiser_signature'] = value;
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
                    onPressed: _saveForm,
                    child: const Text('Save Appraisal Form'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      final form = AppraisalForm(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _appraisalService.create(form);
      widget.onFormCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appraisal form saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save form: $e')),
      );
    }
  }
}

class PreviousObjectivesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> objectives;
  final Function(List<Map<String, dynamic>>) onObjectivesChanged;

  const PreviousObjectivesWidget({
    Key? key,
    required this.objectives,
    required this.onObjectivesChanged,
  }) : super(key: key);

  @override
  _PreviousObjectivesWidgetState createState() => _PreviousObjectivesWidgetState();
}

class _PreviousObjectivesWidgetState extends State<PreviousObjectivesWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.objectives.asMap().entries.map((entry) {
          final index = entry.key;
          final objective = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Objective ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Objective'),
                    initialValue: objective['objective'] ?? '',
                    onChanged: (value) {
                      widget.objectives[index]['objective'] = value;
                      widget.onObjectivesChanged(widget.objectives);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: objective['outcome'],
                    decoration: const InputDecoration(labelText: 'Outcome'),
                    items: [
                      DropdownMenuItem(value: 'achieved', child: Text('Achieved')),
                      DropdownMenuItem(value: 'partially_achieved', child: Text('Partially Achieved')),
                      DropdownMenuItem(value: 'not_achieved', child: Text('Not Achieved')),
                      DropdownMenuItem(value: 'n_a', child: Text('N/A')),
                    ],
                    onChanged: (value) {
                      widget.objectives[index]['outcome'] = value;
                      widget.onObjectivesChanged(widget.objectives);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Comments'),
                    initialValue: objective['comments'] ?? '',
                    maxLines: 3,
                    onChanged: (value) {
                      widget.objectives[index]['comments'] = value;
                      widget.onObjectivesChanged(widget.objectives);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class NewObjectivesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> objectives;
  final Function(List<Map<String, dynamic>>) onObjectivesChanged;

  const NewObjectivesWidget({
    Key? key,
    required this.objectives,
    required this.onObjectivesChanged,
  }) : super(key: key);

  @override
  _NewObjectivesWidgetState createState() => _NewObjectivesWidgetState();
}

class _NewObjectivesWidgetState extends State<NewObjectivesWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.objectives.asMap().entries.map((entry) {
          final index = entry.key;
          final objective = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Objective ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Objective'),
                    initialValue: objective['objective'] ?? '',
                    onChanged: (value) {
                      widget.objectives[index]['objective'] = value;
                      widget.onObjectivesChanged(widget.objectives);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Target Date',
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
                        widget.objectives[index]['target_date'] = DateFormat('dd/MM/yyyy').format(date);
                        widget.onObjectivesChanged(widget.objectives);
                      }
                    },
                    initialValue: objective['target_date'] ?? '',
                    onChanged: (value) {
                      widget.objectives[index]['target_date'] = value;
                      widget.onObjectivesChanged(widget.objectives);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class AppraisalDetailScreen extends StatelessWidget {
  final AppraisalForm form;

  const AppraisalDetailScreen({Key? key, required this.form}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Appraisal Form - ${DateFormat('dd/MM/yyyy').format(form.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${form.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildFormDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appraisal Information',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Appraiser: ${form.responses['appraiser_name'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Staff: ${form.responses['staff_name'] ?? ''}'),
            const SizedBox(height: 8),
            Text(
              'Review of Previous Objectives',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildPreviousObjectives(),
            const SizedBox(height: 8),
            Text(
              'Overall Performance: ${_getPerformanceLabel(form.responses['overall_performance'] ?? '')}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Values & Behaviours',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(form.responses['values_behaviours'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'Training & Development Needs',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(form.responses['training_needs'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'New Objectives',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildNewObjectives(),
            const SizedBox(height: 8),
            Text(
              'Staff Comments',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(form.responses['staff_comments'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'Next Appraisal: ${form.responses['next_appraisal_date'] ?? ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Staff Signature: ${form.responses['staff_signature'] ?? ''}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Appraiser Signature: ${form.responses['appraiser_signature'] ?? ''}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPreviousObjectives() {
    final objectives = form.responses['previous_objectives'] as List? ?? [];
    return objectives.map((obj) {
      final objective = obj as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${objective['objective'] ?? ''}'),
            Text('  Outcome: ${_getObjectiveOutcomeLabel(objective['outcome'] ?? '')}'),
            if (objective['comments'] != null && objective['comments'] != '')
              Text('  Comments: ${objective['comments']}'),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildNewObjectives() {
    final objectives = form.responses['new_objectives'] as List? ?? [];
    return objectives.map((obj) {
      final objective = obj as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${objective['objective'] ?? ''}'),
            Text('  Target Date: ${objective['target_date'] ?? ''}'),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildActionPlan() {
    if (form.actionPlan.isEmpty) {
      return const Text('No action plan items');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agreed Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...form.actionPlan.map((item) => Card(
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

  String _getPerformanceLabel(String performance) {
    switch (performance) {
      case 'exceptional': return 'Exceptional';
      case 'exceeds_expectations': return 'Exceeds Expectations';
      case 'meets_expectations': return 'Meets Expectations';
      case 'partially_meets': return 'Partially Meets Expectations';
      case 'does_not_meet': return 'Does Not Meet Expectations';
      default: return performance;
    }
  }

  String _getObjectiveOutcomeLabel(String outcome) {
    switch (outcome) {
      case 'achieved': return 'Achieved';
      case 'partially_achieved': return 'Partially Achieved';
      case 'not_achieved': return 'Not Achieved';
      case 'n_a': return 'N/A';
      default: return outcome;
    }
  }
}