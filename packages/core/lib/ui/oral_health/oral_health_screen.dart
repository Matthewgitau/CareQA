import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/oral_health_assessment.dart';
import '../../services/oral_health_service.dart';
import '../../services/auth_service.dart';

class OralHealthScreen extends StatefulWidget {
  final String serviceUserId;

  const OralHealthScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _OralHealthScreenState createState() => _OralHealthScreenState();
}

class _OralHealthScreenState extends State<OralHealthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OralHealthService _oralHealthService;
  late AuthService _authService;
  List<OralHealthAssessment> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _oralHealthService = OralHealthService(Supabase.instance.client);
    _authService = AuthService();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      _assessments = await _oralHealthService.getForServiceUser(widget.serviceUserId);
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
        title: const Text('Oral Health Assessment'),
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
    return NewOralHealthAssessment(
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
      return const Center(child: Text('No oral health assessments found'));
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
                  builder: (context) => OralHealthDetailScreen(assessment: assessment),
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

class NewOralHealthAssessment extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onAssessmentCreated;

  const NewOralHealthAssessment({
    Key? key,
    required this.serviceUserId,
    required this.onAssessmentCreated,
  }) : super(key: key);

  @override
  _NewOralHealthAssessmentState createState() => _NewOralHealthAssessmentState();
}

class _NewOralHealthAssessmentState extends State<NewOralHealthAssessment> {
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
    _reviewDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 30)));
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'assessment_date': '',
      'assessor_name': '',
      'dental_status': {
        'natural_teeth': false,
        'partial_dentures': false,
        'full_dentures': false,
        'no_teeth': false,
      },
      'oral_health': {
        'gum_health': '',
        'bleeding_gums': false,
        'bad_breath': false,
        'dry_mouth': false,
        'mouth_pain': false,
        'difficulty_chewing': false,
      },
      'hygiene_assessment': {
        'brushing_frequency': '',
        'flossing_frequency': '',
        'denture_care': '',
        'assistance_needed': false,
        'assistance_type': '',
      },
      'dietary_factors': {
        'sugar_intake': '',
        'acidic_foods': '',
        'hydration': '',
        'nutritional_status': '',
      },
      'medical_factors': {
        'medications': '',
        'medical_conditions': '',
        'smoking': false,
        'alcohol': false,
      },
      'care_plan': {
        'dental_appointments': '',
        'hygiene_schedule': '',
        'special_instructions': '',
        'staff_training': '',
      },
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
              'New Oral Health Assessment',
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
              'Dental Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DentalStatusWidget(
              dentalStatus: _responses['dental_status'],
              onDentalStatusChanged: (dentalStatus) {
                _responses['dental_status'] = dentalStatus;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Oral Health Assessment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OralHealthWidget(
              oralHealth: _responses['oral_health'],
              onOralHealthChanged: (oralHealth) {
                _responses['oral_health'] = oralHealth;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Hygiene Assessment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            HygieneWidget(
              hygiene: _responses['hygiene_assessment'],
              onHygieneChanged: (hygiene) {
                _responses['hygiene_assessment'] = hygiene;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Dietary Factors',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DietaryWidget(
              dietary: _responses['dietary_factors'],
              onDietaryChanged: (dietary) {
                _responses['dietary_factors'] = dietary;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Medical Factors',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            MedicalWidget(
              medical: _responses['medical_factors'],
              onMedicalChanged: (medical) {
                _responses['medical_factors'] = medical;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Care Plan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            CarePlanWidget(
              carePlan: _responses['care_plan'],
              onCarePlanChanged: (carePlan) {
                _responses['care_plan'] = carePlan;
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
                  initialDate: DateTime.now().add(const Duration(days: 30)),
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
                    child: const Text('Save Oral Health Assessment'),
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

      final assessment = OralHealthAssessment(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _oralHealthService.create(assessment);
      widget.onAssessmentCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oral health assessment saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save assessment: $e')),
      );
    }
  }
}

class DentalStatusWidget extends StatefulWidget {
  final Map<String, dynamic> dentalStatus;
  final Function(Map<String, dynamic>) onDentalStatusChanged;

  const DentalStatusWidget({
    Key? key,
    required this.dentalStatus,
    required this.onDentalStatusChanged,
  }) : super(key: key);

  @override
  _DentalStatusWidgetState createState() => _DentalStatusWidgetState();
}

class _DentalStatusWidgetState extends State<DentalStatusWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Natural Teeth'),
              value: widget.dentalStatus['natural_teeth'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.dentalStatus['natural_teeth'] = value;
                  widget.onDentalStatusChanged(widget.dentalStatus);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Partial Dentures'),
              value: widget.dentalStatus['partial_dentures'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.dentalStatus['partial_dentures'] = value;
                  widget.onDentalStatusChanged(widget.dentalStatus);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Full Dentures'),
              value: widget.dentalStatus['full_dentures'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.dentalStatus['full_dentures'] = value;
                  widget.onDentalStatusChanged(widget.dentalStatus);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('No Teeth'),
              value: widget.dentalStatus['no_teeth'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.dentalStatus['no_teeth'] = value;
                  widget.onDentalStatusChanged(widget.dentalStatus);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OralHealthWidget extends StatefulWidget {
  final Map<String, dynamic> oralHealth;
  final Function(Map<String, dynamic>) onOralHealthChanged;

  const OralHealthWidget({
    Key? key,
    required this.oralHealth,
    required this.onOralHealthChanged,
  }) : super(key: key);

  @override
  _OralHealthWidgetState createState() => _OralHealthWidgetState();
}

class _OralHealthWidgetState extends State<OralHealthWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Gum Health'),
              initialValue: widget.oralHealth['gum_health'] ?? '',
              onChanged: (value) {
                widget.oralHealth['gum_health'] = value;
                widget.onOralHealthChanged(widget.oralHealth);
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Bleeding Gums'),
              value: widget.oralHealth['bleeding_gums'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.oralHealth['bleeding_gums'] = value;
                  widget.onOralHealthChanged(widget.oralHealth);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Bad Breath'),
              value: widget.oralHealth['bad_breath'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.oralHealth['bad_breath'] = value;
                  widget.onOralHealthChanged(widget.oralHealth);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Dry Mouth'),
              value: widget.oralHealth['dry_mouth'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.oralHealth['dry_mouth'] = value;
                  widget.onOralHealthChanged(widget.oralHealth);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Mouth Pain'),
              value: widget.oralHealth['mouth_pain'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.oralHealth['mouth_pain'] = value;
                  widget.onOralHealthChanged(widget.oralHealth);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Difficulty Chewing'),
              value: widget.oralHealth['difficulty_chewing'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.oralHealth['difficulty_chewing'] = value;
                  widget.onOralHealthChanged(widget.oralHealth);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HygieneWidget extends StatefulWidget {
  final Map<String, dynamic> hygiene;
  final Function(Map<String, dynamic>) onHygieneChanged;

  const HygieneWidget({
    Key? key,
    required this.hygiene,
    required this.onHygieneChanged,
  }) : super(key: key);

  @override
  _HygieneWidgetState createState() => _HygieneWidgetState();
}

class _HygieneWidgetState extends State<HygieneWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Brushing Frequency'),
              initialValue: widget.hygiene['brushing_frequency'] ?? '',
              onChanged: (value) {
                widget.hygiene['brushing_frequency'] = value;
                widget.onHygieneChanged(widget.hygiene);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Flossing Frequency'),
              initialValue: widget.hygiene['flossing_frequency'] ?? '',
              onChanged: (value) {
                widget.hygiene['flossing_frequency'] = value;
                widget.onHygieneChanged(widget.hygiene);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Denture Care'),
              initialValue: widget.hygiene['denture_care'] ?? '',
              onChanged: (value) {
                widget.hygiene['denture_care'] = value;
                widget.onHygieneChanged(widget.hygiene);
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Assistance Needed'),
              value: widget.hygiene['assistance_needed'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.hygiene['assistance_needed'] = value;
                  widget.onHygieneChanged(widget.hygiene);
                });
              },
            ),
            if (widget.hygiene['assistance_needed'] == true)
              TextFormField(
                decoration: const InputDecoration(labelText: 'Type of Assistance'),
                initialValue: widget.hygiene['assistance_type'] ?? '',
                onChanged: (value) {
                  widget.hygiene['assistance_type'] = value;
                  widget.onHygieneChanged(widget.hygiene);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class DietaryWidget extends StatefulWidget {
  final Map<String, dynamic> dietary;
  final Function(Map<String, dynamic>) onDietaryChanged;

  const DietaryWidget({
    Key? key,
    required this.dietary,
    required this.onDietaryChanged,
  }) : super(key: key);

  @override
  _DietaryWidgetState createState() => _DietaryWidgetState();
}

class _DietaryWidgetState extends State<DietaryWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Sugar Intake'),
              initialValue: widget.dietary['sugar_intake'] ?? '',
              onChanged: (value) {
                widget.dietary['sugar_intake'] = value;
                widget.onDietaryChanged(widget.dietary);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Acidic Foods'),
              initialValue: widget.dietary['acidic_foods'] ?? '',
              onChanged: (value) {
                widget.dietary['acidic_foods'] = value;
                widget.onDietaryChanged(widget.dietary);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Hydration'),
              initialValue: widget.dietary['hydration'] ?? '',
              onChanged: (value) {
                widget.dietary['hydration'] = value;
                widget.onDietaryChanged(widget.dietary);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nutritional Status'),
              initialValue: widget.dietary['nutritional_status'] ?? '',
              onChanged: (value) {
                widget.dietary['nutritional_status'] = value;
                widget.onDietaryChanged(widget.dietary);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MedicalWidget extends StatefulWidget {
  final Map<String, dynamic> medical;
  final Function(Map<String, dynamic>) onMedicalChanged;

  const MedicalWidget({
    Key? key,
    required this.medical,
    required this.onMedicalChanged,
  }) : super(key: key);

  @override
  _MedicalWidgetState createState() => _MedicalWidgetState();
}

class _MedicalWidgetState extends State<MedicalWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Medications'),
              initialValue: widget.medical['medications'] ?? '',
              onChanged: (value) {
                widget.medical['medications'] = value;
                widget.onMedicalChanged(widget.medical);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Medical Conditions'),
              initialValue: widget.medical['medical_conditions'] ?? '',
              onChanged: (value) {
                widget.medical['medical_conditions'] = value;
                widget.onMedicalChanged(widget.medical);
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Smoking'),
              value: widget.medical['smoking'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.medical['smoking'] = value;
                  widget.onMedicalChanged(widget.medical);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Alcohol'),
              value: widget.medical['alcohol'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.medical['alcohol'] = value;
                  widget.onMedicalChanged(widget.medical);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CarePlanWidget extends StatefulWidget {
  final Map<String, dynamic> carePlan;
  final Function(Map<String, dynamic>) onCarePlanChanged;

  const CarePlanWidget({
    Key? key,
    required this.carePlan,
    required this.onCarePlanChanged,
  }) : super(key: key);

  @override
  _CarePlanWidgetState createState() => _CarePlanWidgetState();
}

class _CarePlanWidgetState extends State<CarePlanWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Dental Appointments',
                hintText: 'Schedule and frequency of dental visits',
              ),
              initialValue: widget.carePlan['dental_appointments'] ?? '',
              onChanged: (value) {
                widget.carePlan['dental_appointments'] = value;
                widget.onCarePlanChanged(widget.carePlan);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Hygiene Schedule',
                hintText: 'Daily oral hygiene routine',
              ),
              initialValue: widget.carePlan['hygiene_schedule'] ?? '',
              onChanged: (value) {
                widget.carePlan['hygiene_schedule'] = value;
                widget.onCarePlanChanged(widget.carePlan);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Special Instructions',
                hintText: 'Any special oral care instructions',
              ),
              initialValue: widget.carePlan['special_instructions'] ?? '',
              onChanged: (value) {
                widget.carePlan['special_instructions'] = value;
                widget.onCarePlanChanged(widget.carePlan);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Staff Training',
                hintText: 'Training needs for staff',
              ),
              initialValue: widget.carePlan['staff_training'] ?? '',
              onChanged: (value) {
                widget.carePlan['staff_training'] = value;
                widget.onCarePlanChanged(widget.carePlan);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OralHealthDetailScreen extends StatelessWidget {
  final OralHealthAssessment assessment;

  const OralHealthDetailScreen({Key? key, required this.assessment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Oral Health Assessment - ${DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)}')),
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
              'Dental Status',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildDentalStatus(),
            const SizedBox(height: 16),
            Text(
              'Oral Health',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildOralHealth(),
            const SizedBox(height: 16),
            Text(
              'Hygiene Assessment',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildHygiene(),
            const SizedBox(height: 16),
            Text(
              'Dietary Factors',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildDietary(),
            const SizedBox(height: 16),
            Text(
              'Medical Factors',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildMedical(),
            const SizedBox(height: 16),
            Text(
              'Care Plan',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildCarePlan(),
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

  Widget _buildDentalStatus() {
    final dentalStatus = assessment.responses['dental_status'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dentalStatus['natural_teeth'] == true) Text('• Natural Teeth'),
        if (dentalStatus['partial_dentures'] == true) Text('• Partial Dentures'),
        if (dentalStatus['full_dentures'] == true) Text('• Full Dentures'),
        if (dentalStatus['no_teeth'] == true) Text('• No Teeth'),
      ],
    );
  }

  Widget _buildOralHealth() {
    final oralHealth = assessment.responses['oral_health'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Gum Health: ${oralHealth['gum_health'] ?? ''}'),
        if (oralHealth['bleeding_gums'] == true) Text('• Bleeding Gums'),
        if (oralHealth['bad_breath'] == true) Text('• Bad Breath'),
        if (oralHealth['dry_mouth'] == true) Text('• Dry Mouth'),
        if (oralHealth['mouth_pain'] == true) Text('• Mouth Pain'),
        if (oralHealth['difficulty_chewing'] == true) Text('• Difficulty Chewing'),
      ],
    );
  }

  Widget _buildHygiene() {
    final hygiene = assessment.responses['hygiene_assessment'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Brushing: ${hygiene['brushing_frequency'] ?? ''}'),
        Text('• Flossing: ${hygiene['flossing_frequency'] ?? ''}'),
        Text('• Denture Care: ${hygiene['denture_care'] ?? ''}'),
        if (hygiene['assistance_needed'] == true)
          Text('• Assistance: ${hygiene['assistance_type'] ?? ''}'),
      ],
    );
  }

  Widget _buildDietary() {
    final dietary = assessment.responses['dietary_factors'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Sugar Intake: ${dietary['sugar_intake'] ?? ''}'),
        Text('• Acidic Foods: ${dietary['acidic_foods'] ?? ''}'),
        Text('• Hydration: ${dietary['hydration'] ?? ''}'),
        Text('• Nutrition: ${dietary['nutritional_status'] ?? ''}'),
      ],
    );
  }

  Widget _buildMedical() {
    final medical = assessment.responses['medical_factors'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Medications: ${medical['medications'] ?? ''}'),
        Text('• Conditions: ${medical['medical_conditions'] ?? ''}'),
        if (medical['smoking'] == true) Text('• Smoking'),
        if (medical['alcohol'] == true) Text('• Alcohol'),
      ],
    );
  }

  Widget _buildCarePlan() {
    final carePlan = assessment.responses['care_plan'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Dental Appointments: ${carePlan['dental_appointments'] ?? ''}'),
        Text('• Hygiene Schedule: ${carePlan['hygiene_schedule'] ?? ''}'),
        Text('• Special Instructions: ${carePlan['special_instructions'] ?? ''}'),
        Text('• Staff Training: ${carePlan['staff_training'] ?? ''}'),
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
}