import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/moving_handling_assessment.dart';
import '../../services/moving_handling_service.dart';
import '../../services/auth_service.dart';

class MovingHandlingScreen extends StatefulWidget {
  final String serviceUserId;

  const MovingHandlingScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _MovingHandlingScreenState createState() => _MovingHandlingScreenState();
}

class _MovingHandlingScreenState extends State<MovingHandlingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MovingHandlingService _movingHandlingService;
  late AuthService _authService;
  List<MovingHandlingAssessment> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _movingHandlingService = MovingHandlingService(Supabase.instance.client);
    _authService = AuthService();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      _assessments = await _movingHandlingService.getForServiceUser(widget.serviceUserId);
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
        title: const Text('Moving & Handling Assessment'),
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
    return NewMovingHandlingAssessment(
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
      return const Center(child: Text('No moving & handling assessments found'));
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
                  builder: (context) => MovingHandlingDetailScreen(assessment: assessment),
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

class NewMovingHandlingAssessment extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onAssessmentCreated;

  const NewMovingHandlingAssessment({
    Key? key,
    required this.serviceUserId,
    required this.onAssessmentCreated,
  }) : super(key: key);

  @override
  _NewMovingHandlingAssessmentState createState() => _NewMovingHandlingAssessmentState();
}

class _NewMovingHandlingAssessmentState extends State<NewMovingHandlingAssessment> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _assessorController = TextEditingController();
  final _reviewDateController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _reviewDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 90)));
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'assessment_date': '',
      'assessor_name': '',
      'medical_considerations': '',
      'physical_considerations': '',
      'mobility_level': '',
      'weight_bearing': '',
      'tasks': {
        'bathing': false,
        'toileting': false,
        'dressing': false,
        'feeding': false,
        'transfers': false,
        'repositioning': false,
      },
      'equipment': {
        'hoist': false,
        'stand_aid': false,
        'slide_sheets': false,
        'transfer_board': false,
        'wheelchair': false,
        'walking_aid': false,
        'other': '',
      },
      'staff_required': '',
      'handling_instructions': '',
      'contraindications': '',
      'review_date': '',
      'assessor_signature': '',
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
              'New Moving & Handling Assessment',
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
              'Medical & Physical Considerations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Medical Considerations'),
              maxLines: 3,
              onChanged: (value) {
                _responses['medical_considerations'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Physical Considerations'),
              maxLines: 3,
              onChanged: (value) {
                _responses['physical_considerations'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Mobility & Weight Bearing',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _responses['mobility_level'],
              decoration: const InputDecoration(labelText: 'Mobility Level'),
              items: [
                DropdownMenuItem(value: 'independent', child: Text('Independent')),
                DropdownMenuItem(value: 'one_person_assist', child: Text('1 Person Assist')),
                DropdownMenuItem(value: 'two_person_assist', child: Text('2 Person Assist')),
                DropdownMenuItem(value: 'hoist_dependent', child: Text('Hoist Dependent')),
                DropdownMenuItem(value: 'bedbound', child: Text('Bedbound')),
              ],
              onChanged: (value) {
                _responses['mobility_level'] = value;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _responses['weight_bearing'],
              decoration: const InputDecoration(labelText: 'Weight Bearing'),
              items: [
                DropdownMenuItem(value: 'full', child: Text('Full Weight Bearing')),
                DropdownMenuItem(value: 'partial', child: Text('Partial Weight Bearing')),
                DropdownMenuItem(value: 'non_weight_bearing', child: Text('Non-Weight Bearing')),
              ],
              onChanged: (value) {
                _responses['weight_bearing'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Tasks Requiring Handling',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TasksWidget(
              tasks: _responses['tasks'],
              onTasksChanged: (tasks) {
                _responses['tasks'] = tasks;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Equipment Required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            EquipmentWidget(
              equipment: _responses['equipment'],
              onEquipmentChanged: (equipment) {
                _responses['equipment'] = equipment;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Staffing Requirements',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _responses['staff_required'],
              decoration: const InputDecoration(labelText: 'Number of Staff Required'),
              items: [
                DropdownMenuItem(value: '1', child: Text('1 Staff Member')),
                DropdownMenuItem(value: '2', child: Text('2 Staff Members')),
                DropdownMenuItem(value: '3', child: Text('3 Staff Members')),
                DropdownMenuItem(value: 'specialist_only', child: Text('Specialist Only')),
              ],
              onChanged: (value) {
                _responses['staff_required'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Step-by-Step Handling Instructions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Critical Safety Instructions',
                hintText: 'Detailed step-by-step instructions for safe handling',
              ),
              maxLines: 6,
              onChanged: (value) {
                _responses['handling_instructions'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Actions Staff MUST NOT Take',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Contraindications & Restrictions',
                hintText: 'What staff must avoid doing',
              ),
              maxLines: 4,
              onChanged: (value) {
                _responses['contraindications'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Review Information',
              style: Theme.of(context).textTheme.titleMedium,
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
              'Signature',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Assessor Signature'),
              onChanged: (value) {
                _responses['assessor_signature'] = value;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAssessment,
                    child: const Text('Save Moving & Handling Assessment'),
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

      final assessment = MovingHandlingAssessment(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _movingHandlingService.create(assessment);
      widget.onAssessmentCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moving & handling assessment saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save assessment: $e')),
      );
    }
  }
}

class TasksWidget extends StatefulWidget {
  final Map<String, dynamic> tasks;
  final Function(Map<String, dynamic>) onTasksChanged;

  const TasksWidget({
    Key? key,
    required this.tasks,
    required this.onTasksChanged,
  }) : super(key: key);

  @override
  _TasksWidgetState createState() => _TasksWidgetState();
}

class _TasksWidgetState extends State<TasksWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Bathing'),
              value: widget.tasks['bathing'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.tasks['bathing'] = value;
                  widget.onTasksChanged(widget.tasks);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Toileting'),
              value: widget.tasks['toileting'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.tasks['toileting'] = value;
                  widget.onTasksChanged(widget.tasks);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Dressing'),
              value: widget.tasks['dressing'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.tasks['dressing'] = value;
                  widget.onTasksChanged(widget.tasks);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Feeding'),
              value: widget.tasks['feeding'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.tasks['feeding'] = value;
                  widget.onTasksChanged(widget.tasks);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Transfers'),
              value: widget.tasks['transfers'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.tasks['transfers'] = value;
                  widget.onTasksChanged(widget.tasks);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Repositioning'),
              value: widget.tasks['repositioning'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.tasks['repositioning'] = value;
                  widget.onTasksChanged(widget.tasks);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EquipmentWidget extends StatefulWidget {
  final Map<String, dynamic> equipment;
  final Function(Map<String, dynamic>) onEquipmentChanged;

  const EquipmentWidget({
    Key? key,
    required this.equipment,
    required this.onEquipmentChanged,
  }) : super(key: key);

  @override
  _EquipmentWidgetState createState() => _EquipmentWidgetState();
}

class _EquipmentWidgetState extends State<EquipmentWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Hoist'),
              value: widget.equipment['hoist'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.equipment['hoist'] = value;
                  widget.onEquipmentChanged(widget.equipment);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Stand Aid'),
              value: widget.equipment['stand_aid'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.equipment['stand_aid'] = value;
                  widget.onEquipmentChanged(widget.equipment);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Slide Sheets'),
              value: widget.equipment['slide_sheets'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.equipment['slide_sheets'] = value;
                  widget.onEquipmentChanged(widget.equipment);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Transfer Board'),
              value: widget.equipment['transfer_board'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.equipment['transfer_board'] = value;
                  widget.onEquipmentChanged(widget.equipment);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Wheelchair'),
              value: widget.equipment['wheelchair'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.equipment['wheelchair'] = value;
                  widget.onEquipmentChanged(widget.equipment);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Walking Aid'),
              value: widget.equipment['walking_aid'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.equipment['walking_aid'] = value;
                  widget.onEquipmentChanged(widget.equipment);
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Other Equipment'),
              initialValue: widget.equipment['other'] ?? '',
              onChanged: (value) {
                widget.equipment['other'] = value;
                widget.onEquipmentChanged(widget.equipment);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MovingHandlingDetailScreen extends StatelessWidget {
  final MovingHandlingAssessment assessment;

  const MovingHandlingDetailScreen({Key? key, required this.assessment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Moving & Handling Assessment - ${DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)}')),
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
              'Medical & Physical Considerations',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Medical: ${assessment.responses['medical_considerations'] ?? ''}'),
            Text('Physical: ${assessment.responses['physical_considerations'] ?? ''}'),
            const SizedBox(height: 16),
            Text(
              'Mobility & Weight Bearing',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Mobility Level: ${_getMobilityLabel(assessment.responses['mobility_level'] ?? '')}'),
            Text('Weight Bearing: ${_getWeightBearingLabel(assessment.responses['weight_bearing'] ?? '')}'),
            const SizedBox(height: 16),
            Text(
              'Tasks Requiring Handling',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildTasks(),
            const SizedBox(height: 16),
            Text(
              'Equipment Required',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildEquipment(),
            const SizedBox(height: 16),
            Text(
              'Staffing Requirements',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Staff Required: ${_getStaffLabel(assessment.responses['staff_required'] ?? '')}'),
            const SizedBox(height: 16),
            Text(
              'Step-by-Step Handling Instructions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(assessment.responses['handling_instructions'] ?? ''),
            const SizedBox(height: 16),
            Text(
              'Actions Staff MUST NOT Take',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(assessment.responses['contraindications'] ?? ''),
            const SizedBox(height: 16),
            Text(
              'Review Date: ${assessment.responses['review_date'] ?? ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Assessor Signature: ${assessment.responses['assessor_signature'] ?? ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasks() {
    final tasks = assessment.responses['tasks'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tasks['bathing'] == true) Text('• Bathing'),
        if (tasks['toileting'] == true) Text('• Toileting'),
        if (tasks['dressing'] == true) Text('• Dressing'),
        if (tasks['feeding'] == true) Text('• Feeding'),
        if (tasks['transfers'] == true) Text('• Transfers'),
        if (tasks['repositioning'] == true) Text('• Repositioning'),
      ],
    );
  }

  Widget _buildEquipment() {
    final equipment = assessment.responses['equipment'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (equipment['hoist'] == true) Text('• Hoist'),
        if (equipment['stand_aid'] == true) Text('• Stand Aid'),
        if (equipment['slide_sheets'] == true) Text('• Slide Sheets'),
        if (equipment['transfer_board'] == true) Text('• Transfer Board'),
        if (equipment['wheelchair'] == true) Text('• Wheelchair'),
        if (equipment['walking_aid'] == true) Text('• Walking Aid'),
        if (equipment['other'] != null && equipment['other'] != '')
          Text('• Other: ${equipment['other']}'),
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

  String _getMobilityLabel(String mobility) {
    switch (mobility) {
      case 'independent': return 'Independent';
      case 'one_person_assist': return '1 Person Assist';
      case 'two_person_assist': return '2 Person Assist';
      case 'hoist_dependent': return 'Hoist Dependent';
      case 'bedbound': return 'Bedbound';
      default: return mobility;
    }
  }

  String _getWeightBearingLabel(String weightBearing) {
    switch (weightBearing) {
      case 'full': return 'Full Weight Bearing';
      case 'partial': return 'Partial Weight Bearing';
      case 'non_weight_bearing': return 'Non-Weight Bearing';
      default: return weightBearing;
    }
  }

  String _getStaffLabel(String staff) {
    switch (staff) {
      case '1': return '1 Staff Member';
      case '2': return '2 Staff Members';
      case '3': return '3 Staff Members';
      case 'specialist_only': return 'Specialist Only';
      default: return staff;
    }
  }
}