import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';
import '../../services/competency_scoring.dart';

class PressurePreventionCompetencyForm extends StatefulWidget {
  final String? staffId;
  final String? staffName;

  const PressurePreventionCompetencyForm({super.key, this.staffId, this.staffName});

  @override
  State<PressurePreventionCompetencyForm> createState() => _PressurePreventionCompetencyFormState();
}

class _PressurePreventionCompetencyFormState extends State<PressurePreventionCompetencyForm> {
  final _service = CompetencyService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Section 1: Staff Information
  String? _selectedCarerId;
  String? _selectedCarerName;
  List<Map<String, dynamic>> _carersList = [];
  final _careHomeController = TextEditingController();
  DateTime _assessmentDate = DateTime.now();
  String _assessorName = '';

  // Section 2: Pressure Prevention Criteria
  Map<String, String> _carePlanAssessment = {
    'care_plan_accessed': '',
    'risk_identified': '',
    'interventions_understood': '',
    'equipment_specified': '',
    'review_date_known': '',
  };

  Map<String, String> _waterlowCompletion = {
    'waterlow_completed': '',
    'waterlow_scored': '',
  };

  Map<String, String> _skinAssessment = {
    'skin_inspected': '',
    'redness_identified': '',
    'skin_condition_documented': '',
    'pain_assessed': '',
  };

  Map<String, String> _skinCarePlan = {
    'care_plan_followed': '',
    'repositioning_frequency': '',
    'skin_cleaned_appropriately': '',
  };

  Map<String, String> _supportSurface = {
    'mattress_appropriate': '',
    'cushions_used': '',
    'equipment_positioned': '',
  };

  Map<String, String> _equipmentCondition = {
    'mattress_condition': '',
    'cushion_condition': '',
    'hoist_available': '',
    'turning_equipment_available': '',
    'equipment_working': '',
  };

  Map<String, String> _staffCompetency = {
    'technique_demonstrated': '',
    'knowledge_demonstrated': '',
  };

  Map<String, String> _reviewReporting = {
    'changes_reported': '',
    'documentation_completed': '',
  };

  // Section 3: Overall Decision
  String _furtherTrainingNotes = '';

  // Section 4: Sign-off
  DateTime _signOffDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAssessorName();
    _loadCarers();
  }

  Future<void> _loadCarers() async {
    try {
      final response = await Supabase.instance.client
          .from('carers')
          .select('id, name')
          .eq('is_active', true)
          .order('name', ascending: true);
      setState(() => _carersList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      print('Error loading carers: $e');
    }
  }

  Future<void> _loadAssessorName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();
        setState(() {
          _assessorName = profile['full_name'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading assessor name: $e');
    }
  }

  @override
  void dispose() {
    _careHomeController.dispose();
    super.dispose();
  }

  bool _isCompetent() {
    // Check all criteria in all sections
    // Any 'no' answer on critical criteria = not competent
    // All 'yes' or 'na' answers = competent

    // Section 1: Care Plan Assessment
    final allCarePlan = _carePlanAssessment.values.every((v) => v == 'yes' || v == 'na');

    // Section 2: Waterlow Completion
    final allWaterlow = _waterlowCompletion.values.every((v) => v == 'yes' || v == 'na');

    // Section 3: Skin Assessment
    final allSkinAssessment = _skinAssessment.values.every((v) => v == 'yes' || v == 'na');

    // Section 4: Skin Care Plan
    final allSkinCarePlan = _skinCarePlan.values.every((v) => v == 'yes' || v == 'na');

    // Section 5: Support Surface
    final allSupportSurface = _supportSurface.values.every((v) => v == 'yes' || v == 'na');

    // Section 6: Equipment Condition
    final allEquipmentCondition = _equipmentCondition.values.every((v) => v == 'yes' || v == 'na');

    // Section 7: Staff Competency
    final allStaffCompetency = _staffCompetency.values.every((v) => v == 'yes' || v == 'na');

    // Section 8: Review and Reporting
    final allReviewReporting = _reviewReporting.values.every((v) => v == 'yes' || v == 'na');

    // Any 'no' means not competent
    return allCarePlan && allWaterlow && allSkinAssessment && allSkinCarePlan && allSupportSurface && allEquipmentCondition && allStaffCompetency && allReviewReporting;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final isCompetent = _isCompetent();

      // Create competency ratings
      final competencyRatings = <CompetencyRating>[];

      void addCriteria(Map<String, String> criteriaMap, String category) {
        for (final entry in criteriaMap.entries) {
          competencyRatings.add(CompetencyRating(
            competencyId: 'pressure_${category}_${entry.key}',
            competencyName: _getCriteriaDisplayName(entry.key, category),
            achievedLevel: entry.value == 'yes' ? 4 : 2,
            assessorNotes: entry.value == 'yes' ? 'Passed' : 'Failed',
            assessedDate: _assessmentDate,
          ));
        }
      }

      addCriteria(_carePlanAssessment, 'care_plan');
      addCriteria(_waterlowCompletion, 'waterlow');
      addCriteria(_skinAssessment, 'skin_assessment');
      addCriteria(_skinCarePlan, 'skin_care');
      addCriteria(_supportSurface, 'support_surface');
      addCriteria(_equipmentCondition, 'equipment');
      addCriteria(_staffCompetency, 'competency');
      addCriteria(_reviewReporting, 'review');

      final assessment = CompetencyAssessment(
        id: '',
        staffId: _selectedCarerId ?? '',
        staffName: _selectedCarerName ?? '',
        assessorId: Supabase.instance.client.auth.currentUser?.id ?? '',
        assessorName: _assessorName,
        assessmentDate: _assessmentDate,
        assessmentType: 'spot',
        competencyRatings: competencyRatings,
        overallRating: isCompetent ? 'competent' : 'not_competent',
        passed: isCompetent,
        developmentAreas: isCompetent ? [] : ['Pressure prevention', 'Skin assessment', 'Equipment use'],
        actionPlan: isCompetent ? '' : 'Additional training and supervised practice required',
        nextReviewDate: DateTime.now().add(const Duration(days: 90)),
        status: 'approved',
        staffSignOffDate: _signOffDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _service.createAssessment(assessment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCompetent ? 'Staff assessed as COMPETENT' : 'Staff requires further training'),
            backgroundColor: isCompetent ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving assessment: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getCriteriaDisplayName(String key, String category) {
    final names = <String, String>{};
    
    // Care Plan Assessment
    names['care_plan_accessed'] = 'Care plan accessed';
    names['risk_identified'] = 'Risk identified';
    names['interventions_understood'] = 'Interventions understood';
    names['equipment_specified'] = 'Equipment specified';
    names['review_date_known'] = 'Review date known';

    // Waterlow Completion
    names['waterlow_completed'] = 'Waterlow completed';
    names['waterlow_scored'] = 'Waterlow scored correctly';

    // Skin Assessment
    names['skin_inspected'] = 'Skin inspected';
    names['redness_identified'] = 'Redness identified';
    names['skin_condition_documented'] = 'Skin condition documented';
    names['pain_assessed'] = 'Pain assessed';

    // Skin Care Plan
    names['care_plan_followed'] = 'Care plan followed';
    names['repositioning_frequency'] = 'Repositioning frequency correct';
    names['skin_cleaned_appropriately'] = 'Skin cleaned appropriately';

    // Support Surface
    names['mattress_appropriate'] = 'Mattress appropriate';
    names['cushions_used'] = 'Cushions used';
    names['equipment_positioned'] = 'Equipment positioned correctly';

    // Equipment Condition
    names['mattress_condition'] = 'Mattress condition checked';
    names['cushion_condition'] = 'Cushion condition checked';
    names['hoist_available'] = 'Hoist available';
    names['turning_equipment_available'] = 'Turning equipment available';
    names['equipment_working'] = 'Equipment working';

    // Staff Competency
    names['technique_demonstrated'] = 'Technique demonstrated';
    names['knowledge_demonstrated'] = 'Knowledge demonstrated';

    // Review and Reporting
    names['changes_reported'] = 'Changes reported';
    names['documentation_completed'] = 'Documentation completed';

    return names[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pressure Prevention Assessment'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section 1: Staff Information
            _buildSectionHeader('Staff Information'),
            DropdownButtonFormField<String>(
              value: _selectedCarerId,
              decoration: const InputDecoration(
                labelText: 'Carer Name *',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Select a carer...')),
                ..._carersList.map((c) => DropdownMenuItem(
                  value: c['id'],
                  child: Text(c['name'] ?? 'Unknown'),
                )),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedCarerId = v;
                  final carer = _carersList.firstWhere((c) => c['id'] == v, orElse: () => {});
                  _selectedCarerName = carer['name'] as String?;
                });
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _careHomeController,
              decoration: const InputDecoration(
                labelText: 'Care Home *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _assessmentDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _assessmentDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Assessment Date *',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_assessmentDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _assessorName,
              decoration: const InputDecoration(
                labelText: 'Assessor Name',
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
            const SizedBox(height: 24),

            // Section 2: Pressure Prevention Criteria
            _buildSectionHeader('Care Plan Assessment'),
            ..._buildCriteriaRows(_carePlanAssessment, 'care_plan'),
            const SizedBox(height: 24),

            _buildSectionHeader('Waterlow Completion'),
            ..._buildCriteriaRows(_waterlowCompletion, 'waterlow'),
            const SizedBox(height: 24),

            _buildSectionHeader('Skin Assessment'),
            ..._buildCriteriaRows(_skinAssessment, 'skin_assessment'),
            const SizedBox(height: 24),

            _buildSectionHeader('Skin Care Plan'),
            ..._buildCriteriaRows(_skinCarePlan, 'skin_care'),
            const SizedBox(height: 24),

            _buildSectionHeader('Support Surface'),
            ..._buildCriteriaRows(_supportSurface, 'support_surface'),
            const SizedBox(height: 24),

            _buildSectionHeader('Equipment Condition'),
            ..._buildCriteriaRows(_equipmentCondition, 'equipment'),
            const SizedBox(height: 24),

            _buildSectionHeader('Staff Competency'),
            ..._buildCriteriaRows(_staffCompetency, 'competency'),
            const SizedBox(height: 24),

            _buildSectionHeader('Review and Reporting'),
            ..._buildCriteriaRows(_reviewReporting, 'review'),
            const SizedBox(height: 24),

            // Section 3: Overall Decision
            _buildSectionHeader('Overall Competency Decision'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCompetent() ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isCompetent() ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCompetent() ? Icons.check_circle : Icons.warning,
                    color: _isCompetent() ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCompetent() ? 'COMPETENT' : 'NOT COMPETENT - Further Training Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isCompetent() ? Colors.green : Colors.red,
                          ),
                        ),
                        if (!_isCompetent())
                          Text(
                            'Staff member requires additional training and reassessment',
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_isCompetent())
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Further Training Required (Notes)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onChanged: (v) => _furtherTrainingNotes = v,
              ),
            const SizedBox(height: 24),

            // Section 4: Sign-off
            _buildSectionHeader('Assessor Sign-off'),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _signOffDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _signOffDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_signOffDate)),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Assessment', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }

  List<Widget> _buildCriteriaRows(Map<String, String> criteriaMap, String category) {
    return criteriaMap.keys.map((key) {
      return _buildYesNoNARow(
        _getCriteriaDisplayName(key, category),
        key,
        criteriaMap,
      );
    }).toList();
  }

  Widget _buildYesNoNARow(String label, String key, Map<String, String> map) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Yes'),
                  value: 'yes',
                  groupValue: map[key],
                  onChanged: (v) => setState(() => map[key] = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('No'),
                  value: 'no',
                  groupValue: map[key],
                  onChanged: (v) => setState(() => map[key] = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('N/A'),
                  value: 'na',
                  groupValue: map[key],
                  onChanged: (v) => setState(() => map[key] = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}