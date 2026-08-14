import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';
import '../../services/competency_scoring.dart';

class SpotCheckCompetencyForm extends StatefulWidget {
  final String? staffId;
  final String? staffName;

  const SpotCheckCompetencyForm({super.key, this.staffId, this.staffName});

  @override
  State<SpotCheckCompetencyForm> createState() => _SpotCheckCompetencyFormState();
}

class _SpotCheckCompetencyFormState extends State<SpotCheckCompetencyForm> {
  final _service = CompetencyService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Section 1: Staff Information
  String? _selectedCarerId;
  String? _selectedCarerName;
  List<Map<String, dynamic>> _carersList = [];
  final _careHomeController = TextEditingController();
  DateTime _spotCheckDate = DateTime.now();
  TimeOfDay _spotCheckTime = TimeOfDay.now();
  String _assessorName = '';

  // Section 2: Spot Check Criteria
  Map<String, String> _punctualityAttendance = {
    'arrived_on_time': '',
    'break_times_appropriate': '',
    'notification_given_if_late': '',
    'overtime_agreed': '',
    'absence_communicated': '',
  };

  Map<String, String> _communicationConsent = {
    'greeted_politely': '',
    'introduced_self': '',
    'consent_obtained': '',
    'communication_clear': '',
  };

  Map<String, String> _careDeliveryDocumentation = {
    'care_plan_followed': '',
    'tasks_completed': '',
    'documentation_accurate': '',
    'documentation_timely': '',
    'handover_completed': '',
    'concerns_reported': '',
  };

  Map<String, String> _healthSafety = {
    'ppe_used': '',
    'equipment_safe': '',
    'hazard_identified': '',
    'emergency_procedure_known': '',
  };

  Map<String, String> _medicationAdministration = {
    'medication_secure': '',
    'medication_rounds_completed': '',
  };

  Map<String, String> _privacyDignity = {
    'privacy_maintained': '',
    'dignity_respected': '',
    'personal_care_appropriate': '',
  };

  Map<String, String> _serviceUserFeedback = {
    'smiled_friendly': '',
    'addressed_by_name': '',
    'listened_attentively': '',
    'explained_actions': '',
    'involved_in_care': '',
    'encouraged_independence': '',
    'respected_choices': '',
    'cultural_needs_respected': '',
    'complaints_handled_appropriately': '',
    'positive_relationship': '',
  };

  // Section 3: Overall Decision
  String _furtherTrainingNotes = '';
  DateTime? _followUpDate;

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

    // Section 1: Punctuality and Attendance
    final allPunctuality = _punctualityAttendance.values.every((v) => v == 'yes' || v == 'na');

    // Section 2: Communication and Consent
    final allCommunication = _communicationConsent.values.every((v) => v == 'yes' || v == 'na');

    // Section 3: Care Delivery and Documentation
    final allCareDelivery = _careDeliveryDocumentation.values.every((v) => v == 'yes' || v == 'na');

    // Section 4: Health and Safety
    final allHealthSafety = _healthSafety.values.every((v) => v == 'yes' || v == 'na');

    // Section 5: Medication Administration
    final allMedication = _medicationAdministration.values.every((v) => v == 'yes' || v == 'na');

    // Section 6: Privacy and Dignity
    final allPrivacyDignity = _privacyDignity.values.every((v) => v == 'yes' || v == 'na');

    // Section 7: Service User Feedback
    final allServiceUserFeedback = _serviceUserFeedback.values.every((v) => v == 'yes' || v == 'na');

    // Any 'no' means not competent
    return allPunctuality && allCommunication && allCareDelivery && allHealthSafety && allMedication && allPrivacyDignity && allServiceUserFeedback;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final isCompetent = _isCompetent();

      // Create competency ratings
      final competencyRatings = <CompetencyRating>[];

      // Add all criteria as ratings
      void addCriteria(Map<String, String> criteriaMap, String category) {
        for (final entry in criteriaMap.entries) {
          competencyRatings.add(CompetencyRating(
            competencyId: '${category}_${entry.key}',
            competencyName: _getCriteriaDisplayName(entry.key, category),
            achievedLevel: entry.value == 'yes' ? 4 : 2,
            assessorNotes: entry.value == 'yes' ? 'Passed' : 'Failed',
            assessedDate: _spotCheckDate,
          ));
        }
      }

      addCriteria(_punctualityAttendance, 'punctuality');
      addCriteria(_communicationConsent, 'communication');
      addCriteria(_careDeliveryDocumentation, 'care_delivery');
      addCriteria(_healthSafety, 'health_safety');
      addCriteria(_medicationAdministration, 'medication');
      addCriteria(_privacyDignity, 'privacy_dignity');
      addCriteria(_serviceUserFeedback, 'service_user_feedback');

      final assessment = CompetencyAssessment(
        id: '',
        staffId: _selectedCarerId ?? '',
        staffName: _selectedCarerName ?? '',
        assessorId: Supabase.instance.client.auth.currentUser?.id ?? '',
        assessorName: _assessorName,
        assessmentDate: _spotCheckDate,
        assessmentType: 'spot',
        competencyRatings: competencyRatings,
        overallRating: isCompetent ? 'competent' : 'not_competent',
        passed: isCompetent,
        developmentAreas: isCompetent ? [] : ['Care delivery', 'Communication', 'Professional standards'],
        actionPlan: isCompetent ? '' : 'Additional training and supervised practice required',
        nextReviewDate: _followUpDate ?? DateTime.now().add(const Duration(days: 30)),
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
    
    // Punctuality and Attendance
    names['arrived_on_time'] = 'Arrived on time';
    names['break_times_appropriate'] = 'Break times appropriate';
    names['notification_given_if_late'] = 'Notification given if late';
    names['overtime_agreed'] = 'Overtime agreed';
    names['absence_communicated'] = 'Absence communicated';

    // Communication and Consent
    names['greeted_politely'] = 'Greeted politely';
    names['introduced_self'] = 'Introduced self';
    names['consent_obtained'] = 'Consent obtained';
    names['communication_clear'] = 'Communication clear';

    // Care Delivery and Documentation
    names['care_plan_followed'] = 'Care plan followed';
    names['tasks_completed'] = 'Tasks completed';
    names['documentation_accurate'] = 'Documentation accurate';
    names['documentation_timely'] = 'Documentation timely';
    names['handover_completed'] = 'Handover completed';
    names['concerns_reported'] = 'Concerns reported';

    // Health and Safety
    names['ppe_used'] = 'PPE used';
    names['equipment_safe'] = 'Equipment safe';
    names['hazard_identified'] = 'Hazard identified';
    names['emergency_procedure_known'] = 'Emergency procedure known';

    // Medication Administration
    names['medication_secure'] = 'Medication secure';
    names['medication_rounds_completed'] = 'Medication rounds completed';

    // Privacy and Dignity
    names['privacy_maintained'] = 'Privacy maintained';
    names['dignity_respected'] = 'Dignity respected';
    names['personal_care_appropriate'] = 'Personal care appropriate';

    // Service User Feedback
    names['smiled_friendly'] = 'Smiled and friendly';
    names['addressed_by_name'] = 'Addressed by name';
    names['listened_attentively'] = 'Listened attentively';
    names['explained_actions'] = 'Explained actions';
    names['involved_in_care'] = 'Involved in care';
    names['encouraged_independence'] = 'Encouraged independence';
    names['respected_choices'] = 'Respected choices';
    names['cultural_needs_respected'] = 'Cultural needs respected';
    names['complaints_handled_appropriately'] = 'Complaints handled appropriately';
    names['positive_relationship'] = 'Positive relationship';

    return names[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot Check Assessment'),
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
                  initialDate: _spotCheckDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _spotCheckDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Spot Check *',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_spotCheckDate)),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _spotCheckTime,
                );
                if (picked != null) setState(() => _spotCheckTime = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Time of Spot Check *',
                  border: OutlineInputBorder(),
                ),
                child: Text(_spotCheckTime.format(context)),
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

            // Section 2: Spot Check Criteria
            _buildSectionHeader('Punctuality and Attendance'),
            ..._buildCriteriaRows(_punctualityAttendance, 'punctuality'),
            const SizedBox(height: 24),

            _buildSectionHeader('Communication and Consent'),
            ..._buildCriteriaRows(_communicationConsent, 'communication'),
            const SizedBox(height: 24),

            _buildSectionHeader('Care Delivery and Documentation'),
            ..._buildCriteriaRows(_careDeliveryDocumentation, 'care_delivery'),
            const SizedBox(height: 24),

            _buildSectionHeader('Health and Safety'),
            ..._buildCriteriaRows(_healthSafety, 'health_safety'),
            const SizedBox(height: 24),

            _buildSectionHeader('Medication Administration'),
            ..._buildCriteriaRows(_medicationAdministration, 'medication'),
            const SizedBox(height: 24),

            _buildSectionHeader('Privacy and Dignity'),
            ..._buildCriteriaRows(_privacyDignity, 'privacy_dignity'),
            const SizedBox(height: 24),

            _buildSectionHeader('Service User Feedback'),
            ..._buildCriteriaRows(_serviceUserFeedback, 'service_user_feedback'),
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
            if (!_isCompetent()) ...[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Further Training Required (Notes)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onChanged: (v) => _furtherTrainingNotes = v,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _followUpDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Follow-up Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_followUpDate != null 
                    ? DateFormat('dd/MM/yyyy').format(_followUpDate!) 
                    : 'Select date'),
                ),
              ),
            ],
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