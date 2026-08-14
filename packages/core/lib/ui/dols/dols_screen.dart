import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/dols_assessment.dart';
import '../../services/dols_service.dart';
import '../../services/auth_service.dart';

class DolsScreen extends StatefulWidget {
  final String serviceUserId;

  const DolsScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _DolsScreenState createState() => _DolsScreenState();
}

class _DolsScreenState extends State<DolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DolsService _dolsService;
  late AuthService _authService;
  List<DolsAssessment> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dolsService = DolsService(Supabase.instance.client);
    _authService = AuthService();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      _assessments = await _dolsService.getForServiceUser(widget.serviceUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load assessments: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DoLS Assessment'),
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
          _buildNewAssessmentTab(),
          _buildHistoryTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildNewAssessmentTab() {
    return NewDolsAssessment(
      serviceUserId: widget.serviceUserId,
      onAssessmentCreated: () {
        _loadAssessments();
        _tabController.index = 1; // Switch to history tab
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assessments.isEmpty) {
      return const Center(child: Text('No DoLS assessments found'));
    }

    return ListView.builder(
      itemCount: _assessments.length,
      itemBuilder: (context, index) {
        final assessment = _assessments[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)),
            subtitle: Text('Status: ${assessment.status}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DolsDetailScreen(assessment: assessment),
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

class NewDolsAssessment extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onAssessmentCreated;

  const NewDolsAssessment({
    Key? key,
    required this.serviceUserId,
    required this.onAssessmentCreated,
  }) : super(key: key);

  @override
  _NewDolsAssessmentState createState() => _NewDolsAssessmentState();
}

class _NewDolsAssessmentState extends State<NewDolsAssessment> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _assessorController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _reviewDateController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _startDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _endDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 365)));
    _reviewDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 90)));
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'assessment_date': '',
      'assessor_name': '',
      'mental_capacity_assessment': {
        'understand': false,
        'retain': false,
        'use_weigh': false,
        'communicate': false,
      },
      'best_interests': '',
      'restrictions': {
        'locked_doors': false,
        'supervision': false,
        'restraint': false,
        'medication_control': false,
        'activity_restriction': false,
        'visitor_control': false,
      },
      'rpr_details': {
        'name': '',
        'relationship': '',
        'contact_details': '',
      },
      'imca_involved': 'not_required',
      'authorisation_type': 'standard',
      'authorisation_start_date': '',
      'authorisation_end_date': '',
      'review_date': '',
      'assessor_signature': '',
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
              'New DoLS Assessment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Assessment Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Assessment Date',
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
                    controller: _assessorController,
                    decoration: const InputDecoration(labelText: 'Assessor Name'),
                    onChanged: (value) {
                      _responses['assessor_name'] = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Mental Capacity Assessment (4-part functional test)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            MentalCapacityWidget(
              capacity: _responses['mental_capacity_assessment'],
              onCapacityChanged: (capacity) {
                _responses['mental_capacity_assessment'] = capacity;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Best Interests Decision Record',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Best Interests Decision'),
              maxLines: 5,
              onChanged: (value) {
                _responses['best_interests'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Restrictions in Place',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            RestrictionsWidget(
              restrictions: _responses['restrictions'],
              onRestrictionsChanged: (restrictions) {
                _responses['restrictions'] = restrictions;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Relevant Person\'s Representative (RPR)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'RPR Name'),
              onChanged: (value) {
                _responses['rpr_details']['name'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Relationship to Service User'),
              onChanged: (value) {
                _responses['rpr_details']['relationship'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Contact Details'),
              onChanged: (value) {
                _responses['rpr_details']['contact_details'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'IMCA Involvement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _responses['imca_involved'],
              decoration: const InputDecoration(labelText: 'IMCA Involvement'),
              items: [
                DropdownMenuItem(value: 'yes', child: Text('Yes')),
                DropdownMenuItem(value: 'no', child: Text('No')),
                DropdownMenuItem(value: 'not_required', child: Text('Not Required')),
              ],
              onChanged: (value) {
                _responses['imca_involved'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Authorisation Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _responses['authorisation_type'],
              decoration: const InputDecoration(labelText: 'Authorisation Type'),
              items: [
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                DropdownMenuItem(value: 'standard', child: Text('Standard')),
                DropdownMenuItem(value: 'court_of_protection', child: Text('Court of Protection')),
              ],
              onChanged: (value) {
                _responses['authorisation_type'] = value;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Authorisation Start Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        _startDateController.text = DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                    onChanged: (value) {
                      _responses['authorisation_start_date'] = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'Authorisation End Date',
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
                        _endDateController.text = DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                    onChanged: (value) {
                      _responses['authorisation_end_date'] = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reviewDateController,
              decoration: const InputDecoration(
                labelText: 'Review Date',
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
                  _reviewDateController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
              onChanged: (value) {
                _responses['review_date'] = value;
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
                    decoration: const InputDecoration(labelText: 'Assessor Signature'),
                    onChanged: (value) {
                      _responses['assessor_signature'] = value;
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAssessment,
                    child: const Text('Save DoLS Assessment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      final assessment = DolsAssessment(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _dolsService.create(assessment);
      widget.onAssessmentCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DoLS assessment saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save assessment: $e')),
      );
    }
  }
}

class MentalCapacityWidget extends StatefulWidget {
  final Map<String, dynamic> capacity;
  final Function(Map<String, dynamic>) onCapacityChanged;

  const MentalCapacityWidget({
    Key? key,
    required this.capacity,
    required this.onCapacityChanged,
  }) : super(key: key);

  @override
  _MentalCapacityWidgetState createState() => _MentalCapacityWidgetState();
}

class _MentalCapacityWidgetState extends State<MentalCapacityWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Understand the information relevant to the decision'),
              value: widget.capacity['understand'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.capacity['understand'] = value;
                  widget.onCapacityChanged(widget.capacity);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Retain that information long enough to make the decision'),
              value: widget.capacity['retain'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.capacity['retain'] = value;
                  widget.onCapacityChanged(widget.capacity);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Use or weigh that information as part of the process of making the decision'),
              value: widget.capacity['use_weigh'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.capacity['use_weigh'] = value;
                  widget.onCapacityChanged(widget.capacity);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Communicate their decision (by talking, using sign language or any other means)'),
              value: widget.capacity['communicate'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.capacity['communicate'] = value;
                  widget.onCapacityChanged(widget.capacity);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RestrictionsWidget extends StatefulWidget {
  final Map<String, dynamic> restrictions;
  final Function(Map<String, dynamic>) onRestrictionsChanged;

  const RestrictionsWidget({
    Key? key,
    required this.restrictions,
    required this.onRestrictionsChanged,
  }) : super(key: key);

  @override
  _RestrictionsWidgetState createState() => _RestrictionsWidgetState();
}

class _RestrictionsWidgetState extends State<RestrictionsWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Locked doors'),
              value: widget.restrictions['locked_doors'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.restrictions['locked_doors'] = value;
                  widget.onRestrictionsChanged(widget.restrictions);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Supervision'),
              value: widget.restrictions['supervision'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.restrictions['supervision'] = value;
                  widget.onRestrictionsChanged(widget.restrictions);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Restraint'),
              value: widget.restrictions['restraint'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.restrictions['restraint'] = value;
                  widget.onRestrictionsChanged(widget.restrictions);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Medication control'),
              value: widget.restrictions['medication_control'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.restrictions['medication_control'] = value;
                  widget.onRestrictionsChanged(widget.restrictions);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Activity restriction'),
              value: widget.restrictions['activity_restriction'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.restrictions['activity_restriction'] = value;
                  widget.onRestrictionsChanged(widget.restrictions);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Visitor control'),
              value: widget.restrictions['visitor_control'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.restrictions['visitor_control'] = value;
                  widget.onRestrictionsChanged(widget.restrictions);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DolsDetailScreen extends StatelessWidget {
  final DolsAssessment assessment;

  const DolsDetailScreen({Key? key, required this.assessment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DoLS Assessment - ${DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${assessment.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildAssessmentDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Information',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Assessor: ${assessment.responses['assessor_name'] ?? ''}'),
            const SizedBox(height: 16),
            Text(
              'Mental Capacity Assessment',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildMentalCapacity(),
            const SizedBox(height: 16),
            Text(
              'Best Interests Decision',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(assessment.responses['best_interests'] ?? ''),
            const SizedBox(height: 16),
            Text(
              'Restrictions in Place',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildRestrictions(),
            const SizedBox(height: 16),
            Text(
              'Relevant Person\'s Representative (RPR)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Name: ${assessment.responses['rpr_details']['name'] ?? ''}'),
            Text('Relationship: ${assessment.responses['rpr_details']['relationship'] ?? ''}'),
            Text('Contact: ${assessment.responses['rpr_details']['contact_details'] ?? ''}'),
            const SizedBox(height: 16),
            Text(
              'IMCA Involvement: ${_getImcaLabel(assessment.responses['imca_involved'] ?? '')}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Authorisation Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Type: ${_getAuthorisationTypeLabel(assessment.responses['authorisation_type'] ?? '')}'),
            Text('Start Date: ${assessment.responses['authorisation_start_date'] ?? ''}'),
            Text('End Date: ${assessment.responses['authorisation_end_date'] ?? ''}'),
            Text('Review Date: ${assessment.responses['review_date'] ?? ''}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Assessor Signature: ${assessment.responses['assessor_signature'] ?? ''}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Manager Signature: ${assessment.responses['manager_signature'] ?? ''}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentalCapacity() {
    final capacity = assessment.responses['mental_capacity_assessment'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Understand: ${capacity['understand'] == true ? 'Yes' : 'No'}'),
        Text('• Retain: ${capacity['retain'] == true ? 'Yes' : 'No'}'),
        Text('• Use/Weigh: ${capacity['use_weigh'] == true ? 'Yes' : 'No'}'),
        Text('• Communicate: ${capacity['communicate'] == true ? 'Yes' : 'No'}'),
      ],
    );
  }

  Widget _buildRestrictions() {
    final restrictions = assessment.responses['restrictions'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (restrictions['locked_doors'] == true) Text('• Locked doors'),
        if (restrictions['supervision'] == true) Text('• Supervision'),
        if (restrictions['restraint'] == true) Text('• Restraint'),
        if (restrictions['medication_control'] == true) Text('• Medication control'),
        if (restrictions['activity_restriction'] == true) Text('• Activity restriction'),
        if (restrictions['visitor_control'] == true) Text('• Visitor control'),
      ],
    );
  }

  Widget _buildActionPlan() {
    if (assessment.actionPlan.isEmpty) {
      return const Text('No action plan items');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agreed Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...assessment.actionPlan.map((item) => Card(
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

  String _getImcaLabel(String imca) {
    switch (imca) {
      case 'yes': return 'Yes';
      case 'no': return 'No';
      case 'not_required': return 'Not Required';
      default: return imca;
    }
  }

  String _getAuthorisationTypeLabel(String type) {
    switch (type) {
      case 'urgent': return 'Urgent';
      case 'standard': return 'Standard';
      case 'court_of_protection': return 'Court of Protection';
      default: return type;
    }
  }
}