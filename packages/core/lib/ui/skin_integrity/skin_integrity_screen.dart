import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/skin_integrity_assessment.dart';
import '../../services/skin_integrity_service.dart';
import '../../services/auth_service.dart';

class SkinIntegrityScreen extends StatefulWidget {
  final String serviceUserId;

  const SkinIntegrityScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _SkinIntegrityScreenState createState() => _SkinIntegrityScreenState();
}

class _SkinIntegrityScreenState extends State<SkinIntegrityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SkinIntegrityService _skinIntegrityService;
  late AuthService _authService;
  List<SkinIntegrityAssessment> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _skinIntegrityService = SkinIntegrityService(Supabase.instance.client);
    _authService = AuthService();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      _assessments = await _skinIntegrityService.getForServiceUser(widget.serviceUserId);
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
        title: const Text('Skin Integrity Assessment'),
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
    return NewSkinIntegrityAssessment(
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
      return const Center(child: Text('No skin integrity assessments found'));
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
                  builder: (context) => SkinIntegrityDetailScreen(assessment: assessment),
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

class NewSkinIntegrityAssessment extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onAssessmentCreated;

  const NewSkinIntegrityAssessment({
    Key? key,
    required this.serviceUserId,
    required this.onAssessmentCreated,
  }) : super(key: key);

  @override
  _NewSkinIntegrityAssessmentState createState() => _NewSkinIntegrityAssessmentState();
}

class _NewSkinIntegrityAssessmentState extends State<NewSkinIntegrityAssessment> {
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
      'risk_factors': {
        'immobility': false,
        'incontinence': false,
        'poor_nutrition': false,
        'poor_hydration': false,
        'medications': false,
        'medical_conditions': '',
      },
      'skin_assessment': {
        'color': '',
        'temperature': '',
        'moisture': '',
        'integrity': '',
        'turgor': '',
      },
      'pressure_points': {
        'sacrum': false,
        'heels': false,
        'elbows': false,
        'hips': false,
        'shoulders': false,
        'ankles': false,
        'other': '',
      },
      'existing_wounds': [],
      'prevention_measures': {
        'repositioning': '',
        'support_surfaces': '',
        'skin_care': '',
        'nutrition': '',
        'hydration': '',
      },
      'staff_training': '',
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
              'New Skin Integrity Assessment',
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
              'Risk Factors',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            RiskFactorsWidget(
              riskFactors: _responses['risk_factors'],
              onRiskFactorsChanged: (riskFactors) {
                _responses['risk_factors'] = riskFactors;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Skin Assessment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SkinAssessmentWidget(
              skinAssessment: _responses['skin_assessment'],
              onSkinAssessmentChanged: (skinAssessment) {
                _responses['skin_assessment'] = skinAssessment;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Pressure Points Assessment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            PressurePointsWidget(
              pressurePoints: _responses['pressure_points'],
              onPressurePointsChanged: (pressurePoints) {
                _responses['pressure_points'] = pressurePoints;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Existing Wounds',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ExistingWoundsWidget(
              existingWounds: _responses['existing_wounds'],
              onExistingWoundsChanged: (existingWounds) {
                _responses['existing_wounds'] = existingWounds;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Prevention Measures',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            PreventionMeasuresWidget(
              preventionMeasures: _responses['prevention_measures'],
              onPreventionMeasuresChanged: (preventionMeasures) {
                _responses['prevention_measures'] = preventionMeasures;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Staff Training & Education',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Staff Training Requirements',
                hintText: 'Training needs and requirements for staff',
              ),
              maxLines: 3,
              onChanged: (value) {
                _responses['staff_training'] = value;
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
                    child: const Text('Save Skin Integrity Assessment'),
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

      final assessment = SkinIntegrityAssessment(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _skinIntegrityService.create(assessment);
      widget.onAssessmentCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skin integrity assessment saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save assessment: $e')),
      );
    }
  }
}

class RiskFactorsWidget extends StatefulWidget {
  final Map<String, dynamic> riskFactors;
  final Function(Map<String, dynamic>) onRiskFactorsChanged;

  const RiskFactorsWidget({
    Key? key,
    required this.riskFactors,
    required this.onRiskFactorsChanged,
  }) : super(key: key);

  @override
  _RiskFactorsWidgetState createState() => _RiskFactorsWidgetState();
}

class _RiskFactorsWidgetState extends State<RiskFactorsWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Immobility'),
              value: widget.riskFactors['immobility'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.riskFactors['immobility'] = value;
                  widget.onRiskFactorsChanged(widget.riskFactors);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Incontinence'),
              value: widget.riskFactors['incontinence'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.riskFactors['incontinence'] = value;
                  widget.onRiskFactorsChanged(widget.riskFactors);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Poor Nutrition'),
              value: widget.riskFactors['poor_nutrition'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.riskFactors['poor_nutrition'] = value;
                  widget.onRiskFactorsChanged(widget.riskFactors);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Poor Hydration'),
              value: widget.riskFactors['poor_hydration'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.riskFactors['poor_hydration'] = value;
                  widget.onRiskFactorsChanged(widget.riskFactors);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Medications'),
              value: widget.riskFactors['medications'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.riskFactors['medications'] = value;
                  widget.onRiskFactorsChanged(widget.riskFactors);
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Medical Conditions'),
              initialValue: widget.riskFactors['medical_conditions'] ?? '',
              onChanged: (value) {
                widget.riskFactors['medical_conditions'] = value;
                widget.onRiskFactorsChanged(widget.riskFactors);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SkinAssessmentWidget extends StatefulWidget {
  final Map<String, dynamic> skinAssessment;
  final Function(Map<String, dynamic>) onSkinAssessmentChanged;

  const SkinAssessmentWidget({
    Key? key,
    required this.skinAssessment,
    required this.onSkinAssessmentChanged,
  }) : super(key: key);

  @override
  _SkinAssessmentWidgetState createState() => _SkinAssessmentWidgetState();
}

class _SkinAssessmentWidgetState extends State<SkinAssessmentWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Color'),
              initialValue: widget.skinAssessment['color'] ?? '',
              onChanged: (value) {
                widget.skinAssessment['color'] = value;
                widget.onSkinAssessmentChanged(widget.skinAssessment);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Temperature'),
              initialValue: widget.skinAssessment['temperature'] ?? '',
              onChanged: (value) {
                widget.skinAssessment['temperature'] = value;
                widget.onSkinAssessmentChanged(widget.skinAssessment);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Moisture'),
              initialValue: widget.skinAssessment['moisture'] ?? '',
              onChanged: (value) {
                widget.skinAssessment['moisture'] = value;
                widget.onSkinAssessmentChanged(widget.skinAssessment);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Integrity'),
              initialValue: widget.skinAssessment['integrity'] ?? '',
              onChanged: (value) {
                widget.skinAssessment['integrity'] = value;
                widget.onSkinAssessmentChanged(widget.skinAssessment);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Turgor'),
              initialValue: widget.skinAssessment['turgor'] ?? '',
              onChanged: (value) {
                widget.skinAssessment['turgor'] = value;
                widget.onSkinAssessmentChanged(widget.skinAssessment);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PressurePointsWidget extends StatefulWidget {
  final Map<String, dynamic> pressurePoints;
  final Function(Map<String, dynamic>) onPressurePointsChanged;

  const PressurePointsWidget({
    Key? key,
    required this.pressurePoints,
    required this.onPressurePointsChanged,
  }) : super(key: key);

  @override
  _PressurePointsWidgetState createState() => _PressurePointsWidgetState();
}

class _PressurePointsWidgetState extends State<PressurePointsWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Sacrum'),
              value: widget.pressurePoints['sacrum'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.pressurePoints['sacrum'] = value;
                  widget.onPressurePointsChanged(widget.pressurePoints);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Heels'),
              value: widget.pressurePoints['heels'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.pressurePoints['heels'] = value;
                  widget.onPressurePointsChanged(widget.pressurePoints);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Elbows'),
              value: widget.pressurePoints['elbows'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.pressurePoints['elbows'] = value;
                  widget.onPressurePointsChanged(widget.pressurePoints);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Hips'),
              value: widget.pressurePoints['hips'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.pressurePoints['hips'] = value;
                  widget.onPressurePointsChanged(widget.pressurePoints);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Shoulders'),
              value: widget.pressurePoints['shoulders'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.pressurePoints['shoulders'] = value;
                  widget.onPressurePointsChanged(widget.pressurePoints);
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Ankles'),
              value: widget.pressurePoints['ankles'] ?? false,
              onChanged: (value) {
                setState(() {
                  widget.pressurePoints['ankles'] = value;
                  widget.onPressurePointsChanged(widget.pressurePoints);
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Other Pressure Points'),
              initialValue: widget.pressurePoints['other'] ?? '',
              onChanged: (value) {
                widget.pressurePoints['other'] = value;
                widget.onPressurePointsChanged(widget.pressurePoints);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ExistingWoundsWidget extends StatefulWidget {
  final List<dynamic> existingWounds;
  final Function(List<dynamic>) onExistingWoundsChanged;

  const ExistingWoundsWidget({
    Key? key,
    required this.existingWounds,
    required this.onExistingWoundsChanged,
  }) : super(key: key);

  @override
  _ExistingWoundsWidgetState createState() => _ExistingWoundsWidgetState();
}

class _ExistingWoundsWidgetState extends State<ExistingWoundsWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Existing Wounds', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (widget.existingWounds.isEmpty)
              const Text('No existing wounds'),
            ...widget.existingWounds.map((wound) => Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location: ${wound['location'] ?? ''}'),
                    Text('Stage: ${wound['stage'] ?? ''}'),
                    Text('Size: ${wound['size'] ?? ''}'),
                    Text('Description: ${wound['description'] ?? ''}'),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addWound,
                    child: const Text('Add Wound'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addWound() {
    setState(() {
      widget.existingWounds.add({
        'location': '',
        'stage': '',
        'size': '',
        'description': '',
      });
      widget.onExistingWoundsChanged(widget.existingWounds);
    });
  }
}

class PreventionMeasuresWidget extends StatefulWidget {
  final Map<String, dynamic> preventionMeasures;
  final Function(Map<String, dynamic>) onPreventionMeasuresChanged;

  const PreventionMeasuresWidget({
    Key? key,
    required this.preventionMeasures,
    required this.onPreventionMeasuresChanged,
  }) : super(key: key);

  @override
  _PreventionMeasuresWidgetState createState() => _PreventionMeasuresWidgetState();
}

class _PreventionMeasuresWidgetState extends State<PreventionMeasuresWidget> {
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
                labelText: 'Repositioning Schedule',
                hintText: 'How often and how to reposition',
              ),
              initialValue: widget.preventionMeasures['repositioning'] ?? '',
              onChanged: (value) {
                widget.preventionMeasures['repositioning'] = value;
                widget.onPreventionMeasuresChanged(widget.preventionMeasures);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Support Surfaces',
                hintText: 'Mattresses, cushions, etc.',
              ),
              initialValue: widget.preventionMeasures['support_surfaces'] ?? '',
              onChanged: (value) {
                widget.preventionMeasures['support_surfaces'] = value;
                widget.onPreventionMeasuresChanged(widget.preventionMeasures);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Skin Care',
                hintText: 'Cleansing, moisturizing, etc.',
              ),
              initialValue: widget.preventionMeasures['skin_care'] ?? '',
              onChanged: (value) {
                widget.preventionMeasures['skin_care'] = value;
                widget.onPreventionMeasuresChanged(widget.preventionMeasures);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nutrition',
                hintText: 'Dietary requirements and supplements',
              ),
              initialValue: widget.preventionMeasures['nutrition'] ?? '',
              onChanged: (value) {
                widget.preventionMeasures['nutrition'] = value;
                widget.onPreventionMeasuresChanged(widget.preventionMeasures);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Hydration',
                hintText: 'Fluid intake requirements',
              ),
              initialValue: widget.preventionMeasures['hydration'] ?? '',
              onChanged: (value) {
                widget.preventionMeasures['hydration'] = value;
                widget.onPreventionMeasuresChanged(widget.preventionMeasures);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SkinIntegrityDetailScreen extends StatelessWidget {
  final SkinIntegrityAssessment assessment;

  const SkinIntegrityDetailScreen({Key? key, required this.assessment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Skin Integrity Assessment - ${DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)}')),
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
              'Risk Factors',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildRiskFactors(),
            const SizedBox(height: 16),
            Text(
              'Skin Assessment',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildSkinAssessment(),
            const SizedBox(height: 16),
            Text(
              'Pressure Points',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildPressurePoints(),
            const SizedBox(height: 16),
            Text(
              'Existing Wounds',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildExistingWounds(),
            const SizedBox(height: 16),
            Text(
              'Prevention Measures',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildPreventionMeasures(),
            const SizedBox(height: 16),
            Text(
              'Staff Training: ${assessment.responses['staff_training'] ?? ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
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

  Widget _buildRiskFactors() {
    final riskFactors = assessment.responses['risk_factors'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (riskFactors['immobility'] == true) Text('• Immobility'),
        if (riskFactors['incontinence'] == true) Text('• Incontinence'),
        if (riskFactors['poor_nutrition'] == true) Text('• Poor Nutrition'),
        if (riskFactors['poor_hydration'] == true) Text('• Poor Hydration'),
        if (riskFactors['medications'] == true) Text('• Medications'),
        if (riskFactors['medical_conditions'] != null && riskFactors['medical_conditions'] != '')
          Text('• Medical Conditions: ${riskFactors['medical_conditions']}'),
      ],
    );
  }

  Widget _buildSkinAssessment() {
    final skinAssessment = assessment.responses['skin_assessment'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Color: ${skinAssessment['color'] ?? ''}'),
        Text('• Temperature: ${skinAssessment['temperature'] ?? ''}'),
        Text('• Moisture: ${skinAssessment['moisture'] ?? ''}'),
        Text('• Integrity: ${skinAssessment['integrity'] ?? ''}'),
        Text('• Turgor: ${skinAssessment['turgor'] ?? ''}'),
      ],
    );
  }

  Widget _buildPressurePoints() {
    final pressurePoints = assessment.responses['pressure_points'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pressurePoints['sacrum'] == true) Text('• Sacrum'),
        if (pressurePoints['heels'] == true) Text('• Heels'),
        if (pressurePoints['elbows'] == true) Text('• Elbows'),
        if (pressurePoints['hips'] == true) Text('• Hips'),
        if (pressurePoints['shoulders'] == true) Text('• Shoulders'),
        if (pressurePoints['ankles'] == true) Text('• Ankles'),
        if (pressurePoints['other'] != null && pressurePoints['other'] != '')
          Text('• Other: ${pressurePoints['other']}'),
      ],
    );
  }

  Widget _buildExistingWounds() {
    final existingWounds = assessment.responses['existing_wounds'] as List<dynamic>? ?? [];
    if (existingWounds.isEmpty) {
      return const Text('No existing wounds');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: existingWounds.map((wound) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: ${wound['location'] ?? ''}'),
              Text('Stage: ${wound['stage'] ?? ''}'),
              Text('Size: ${wound['size'] ?? ''}'),
              Text('Description: ${wound['description'] ?? ''}'),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildPreventionMeasures() {
    final preventionMeasures = assessment.responses['prevention_measures'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• Repositioning: ${preventionMeasures['repositioning'] ?? ''}'),
        Text('• Support Surfaces: ${preventionMeasures['support_surfaces'] ?? ''}'),
        Text('• Skin Care: ${preventionMeasures['skin_care'] ?? ''}'),
        Text('• Nutrition: ${preventionMeasures['nutrition'] ?? ''}'),
        Text('• Hydration: ${preventionMeasures['hydration'] ?? ''}'),
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