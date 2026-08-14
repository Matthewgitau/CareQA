import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';
import '../../services/competency_scoring.dart';

class FireSafetyCompetencyForm extends StatefulWidget {
  final String? staffId;
  final String? staffName;

  const FireSafetyCompetencyForm({super.key, this.staffId, this.staffName});

  @override
  State<FireSafetyCompetencyForm> createState() => _FireSafetyCompetencyFormState();
}

class _FireSafetyCompetencyFormState extends State<FireSafetyCompetencyForm> {
  final _service = CompetencyService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Section 1: Staff Information
  String? _selectedStaffId;
  String? _selectedStaffName;
  List<Map<String, dynamic>> _staffList = [];
  final _careHomeController = TextEditingController();
  DateTime _assessmentDate = DateTime.now();
  String _assessorName = '';

  // Fire Safety Knowledge
  Map<String, String> _fireSafetyKnowledge = {
    'extinguisher_types': '', 'evacuation_procedures': '', 'peep_completion': '', 'risk_assessment_process': '', 'raise_alarm_call_emergency': '',
  };

  // Fire Safety Practice
  Map<String, String> _fireSafetyPractice = {
    'extinguisher_location': '', 'extinguisher_service_date': '', 'fire_door_condition': '', 'evacuation_route_clear': '', 'fire_drill_participation': '',
  };

  String _furtherTrainingNotes = '';
  DateTime _signOffDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAssessorName();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final response = await _service.getAllStaff();
      setState(() => _staffList = response);
    } catch (e) {
      print('Error loading staff: $e');
    }
  }

  Future<void> _loadAssessorName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client.from('profiles').select('full_name').eq('id', user.id).single();
        setState(() => _assessorName = profile['full_name'] ?? '');
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

    // Section 1: Fire Safety Knowledge
    final allKnowledge = _fireSafetyKnowledge.values.every((v) => v == 'yes' || v == 'na');

    // Section 2: Fire Safety Practice
    final allPractice = _fireSafetyPractice.values.every((v) => v == 'yes' || v == 'na');

    // Any 'no' means not competent
    return allKnowledge && allPractice;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a staff member'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isCompetent = _isCompetent();
      final competencyRatings = <CompetencyRating>[];

      for (final e in _fireSafetyKnowledge.entries) {
        competencyRatings.add(CompetencyRating(competencyId: e.key, competencyName: _getKnowledgeDisplayName(e.key), achievedLevel: e.value == 'yes' ? 4 : 2, assessorNotes: e.value == 'yes' ? 'Passed' : 'Failed', assessedDate: _assessmentDate));
      }
      for (final e in _fireSafetyPractice.entries) {
        competencyRatings.add(CompetencyRating(competencyId: e.key, competencyName: _getPracticeDisplayName(e.key), achievedLevel: e.value == 'yes' ? 4 : 2, assessorNotes: e.value == 'yes' ? 'Passed' : 'Failed', assessedDate: _assessmentDate));
      }

      final assessment = CompetencyAssessment(
        id: '', staffId: _selectedStaffId ?? '', staffName: _selectedStaffName ?? '',
        assessorId: Supabase.instance.client.auth.currentUser?.id ?? '', assessorName: _assessorName,
        assessmentDate: _assessmentDate, assessmentType: 'fire_safety',
        competencyRatings: competencyRatings, overallRating: isCompetent ? 'competent' : 'not_competent',
        passed: isCompetent, developmentAreas: isCompetent ? [] : ['Fire safety procedures'],
        actionPlan: isCompetent ? '' : 'Additional fire safety training required',
        nextReviewDate: DateTime.now().add(const Duration(days: 90)),
        status: 'approved', staffSignOffDate: _signOffDate, createdAt: DateTime.now(), updatedAt: DateTime.now(),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving assessment: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getKnowledgeDisplayName(String key) {
    switch (key) {
      case 'extinguisher_types': return 'Can identify different fire extinguisher types and uses';
      case 'evacuation_procedures': return 'Knows emergency evacuation procedures';
      case 'peep_completion': return 'Can complete a PEEP';
      case 'risk_assessment_process': return 'Understands fire risk assessment process';
      case 'raise_alarm_call_emergency': return 'Can raise the fire alarm and call emergency services';
      default: return key;
    }
  }

  String _getPracticeDisplayName(String key) {
    switch (key) {
      case 'extinguisher_location': return 'Fire extinguisher correctly located';
      case 'extinguisher_service_date': return 'Fire extinguisher service date checked';
      case 'fire_door_condition': return 'Fire door condition checked';
      case 'evacuation_route_clear': return 'Evacuation route clear';
      case 'fire_drill_participation': return 'Fire drill participation';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fire Safety Assessment'), backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _buildSectionHeader('Staff Information'),
          DropdownButtonFormField<String>(
            value: _selectedStaffId,
            decoration: const InputDecoration(labelText: 'Staff Name *', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('Select a staff member...')),
              ..._staffList.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'] ?? 'Unknown'))),
            ],
            onChanged: (v) { setState(() { _selectedStaffId = v; final staff = _staffList.firstWhere((s) => s['id'] == v, orElse: () => {}); _selectedStaffName = staff['name'] as String?; }); },
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _careHomeController, decoration: const InputDecoration(labelText: 'Care Home *', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async { final picked = await showDatePicker(context: context, initialDate: _assessmentDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (picked != null) setState(() => _assessmentDate = picked); },
            child: InputDecorator(decoration: const InputDecoration(labelText: 'Assessment Date *', border: OutlineInputBorder()), child: Text(DateFormat('dd/MM/yyyy').format(_assessmentDate))),
          ),
          const SizedBox(height: 16),
          TextFormField(initialValue: _assessorName, decoration: const InputDecoration(labelText: 'Assessor Name (from public.profiles)', border: OutlineInputBorder()), enabled: false),
          const SizedBox(height: 24),

          _buildSectionHeader('Fire Safety Knowledge'),
          ..._fireSafetyKnowledge.keys.map((key) => _buildYesNoNARow(_getKnowledgeDisplayName(key), key, _fireSafetyKnowledge)),
          const SizedBox(height: 24),
          _buildSectionHeader('Fire Safety Practice'),
          ..._fireSafetyPractice.keys.map((key) => _buildYesNoNARow(_getPracticeDisplayName(key), key, _fireSafetyPractice)),
          const SizedBox(height: 24),

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
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Further Training Required (Notes)', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 3, onChanged: (v) => _furtherTrainingNotes = v),
          ],
          const SizedBox(height: 24),

          _buildSectionHeader('Assessor Sign-off'),
          InkWell(
            onTap: () async { final picked = await showDatePicker(context: context, initialDate: _signOffDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (picked != null) setState(() => _signOffDate = picked); },
            child: InputDecorator(decoration: const InputDecoration(labelText: 'Date *', border: OutlineInputBorder()), child: Text(DateFormat('dd/MM/yyyy').format(_signOffDate))),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(onPressed: _isSaving ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Assessment', style: TextStyle(fontWeight: FontWeight.bold))),
          ),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))));
  }

  Widget _buildYesNoNARow(String label, String key, Map<String, String> map) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: RadioListTile<String>(title: const Text('Yes'), value: 'yes', groupValue: map[key], onChanged: (v) => setState(() => map[key] = v!))),
        Expanded(child: RadioListTile<String>(title: const Text('No'), value: 'no', groupValue: map[key], onChanged: (v) => setState(() => map[key] = v!))),
        Expanded(child: RadioListTile<String>(title: const Text('N/A'), value: 'na', groupValue: map[key], onChanged: (v) => setState(() => map[key] = v!))),
      ]),
    ]));
  }
}