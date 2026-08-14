import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';
import '../../services/competency_scoring.dart';

class DignityRespectCompetencyForm extends StatefulWidget {
  final String? staffId;
  final String? staffName;

  const DignityRespectCompetencyForm({super.key, this.staffId, this.staffName});

  @override
  State<DignityRespectCompetencyForm> createState() => _DignityRespectCompetencyFormState();
}

class _DignityRespectCompetencyFormState extends State<DignityRespectCompetencyForm> {
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

  // Section 2: Dignity and Respect Knowledge (5 criteria)
  Map<String, String> _dignityKnowledge = {
    'person_centred_care': '',
    'maintain_privacy_dignity': '',
    'support_choice_independence': '',
    'identify_cultural_needs': '',
    'challenge_disrespectful': '',
  };

  // Section 3: Dignity and Respect Practice (5 criteria)
  Map<String, String> _dignityPractice = {
    'privacy_maintained': '',
    'dignity_respected': '',
    'choice_supported': '',
    'cultural_needs_addressed': '',
    'disrespect_challenged': '',
  };

  // Section 4: Overall Decision
  String _furtherTrainingNotes = '';

  // Section 5: Sign-off
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

    // Section 1: Dignity and Respect Knowledge
    final allKnowledge = _dignityKnowledge.values.every((v) => v == 'yes' || v == 'na');

    // Section 2: Dignity and Respect Practice
    final allPractice = _dignityPractice.values.every((v) => v == 'yes' || v == 'na');

    // Any 'no' means not competent
    return allKnowledge && allPractice;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final isCompetent = _isCompetent();

      // Create competency ratings
      final competencyRatings = <CompetencyRating>[];

      // Dignity and Respect Knowledge
      for (final entry in _dignityKnowledge.entries) {
        competencyRatings.add(CompetencyRating(
          competencyId: 'dignity_knowledge_${entry.key}',
          competencyName: _getKnowledgeDisplayName(entry.key),
          achievedLevel: entry.value == 'yes' ? 4 : 2,
          assessorNotes: entry.value == 'yes' ? 'Passed' : 'Failed',
          assessedDate: _assessmentDate,
        ));
      }

      // Dignity and Respect Practice
      for (final entry in _dignityPractice.entries) {
        competencyRatings.add(CompetencyRating(
          competencyId: 'dignity_practice_${entry.key}',
          competencyName: _getPracticeDisplayName(entry.key),
          achievedLevel: entry.value == 'yes' ? 4 : 2,
          assessorNotes: entry.value == 'yes' ? 'Passed' : 'Failed',
          assessedDate: _assessmentDate,
        ));
      }

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
        developmentAreas: isCompetent ? [] : ['Dignity and respect', 'Person-centred care'],
        actionPlan: isCompetent ? '' : 'Additional training on dignity and respect required',
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

  String _getKnowledgeDisplayName(String key) {
    switch (key) {
      case 'person_centred_care': return 'Understands person-centred care';
      case 'maintain_privacy_dignity': return 'Can demonstrate maintaining privacy and dignity';
      case 'support_choice_independence': return 'Knows how to support choice and independence';
      case 'identify_cultural_needs': return 'Can identify cultural and religious needs';
      case 'challenge_disrespectful': return 'Confident in challenging disrespectful behaviour';
      default: return key;
    }
  }

  String _getPracticeDisplayName(String key) {
    switch (key) {
      case 'privacy_maintained': return 'Privacy maintained';
      case 'dignity_respected': return 'Dignity respected';
      case 'choice_supported': return 'Choice supported';
      case 'cultural_needs_addressed': return 'Cultural needs addressed';
      case 'disrespect_challenged': return 'Disrespectful behaviour challenged';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dignity and Respect Assessment'),
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

            // Section 2: Dignity and Respect Knowledge
            _buildSectionHeader('Dignity and Respect Knowledge'),
            ..._buildCriteriaRows(_dignityKnowledge, 'knowledge'),
            const SizedBox(height: 24),

            // Section 3: Dignity and Respect Practice
            _buildSectionHeader('Dignity and Respect Practice'),
            ..._buildCriteriaRows(_dignityPractice, 'practice'),
            const SizedBox(height: 24),

            // Section 4: Overall Decision
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

            // Section 5: Sign-off
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
        category == 'knowledge' ? _getKnowledgeDisplayName(key) : _getPracticeDisplayName(key),
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