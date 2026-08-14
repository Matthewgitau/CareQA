import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';
import '../../services/competency_scoring.dart';

class SafeguardingCompetencyForm extends StatefulWidget {
  final String? staffId;
  final String? staffName;

  const SafeguardingCompetencyForm({super.key, this.staffId, this.staffName});

  @override
  State<SafeguardingCompetencyForm> createState() => _SafeguardingCompetencyFormState();
}

class _SafeguardingCompetencyFormState extends State<SafeguardingCompetencyForm> {
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

  // Section 2: Safeguarding Knowledge (5 criteria)
  Map<String, String> _safeguardingKnowledge = {
    'identify_abuse_types': '',
    'reporting_procedure': '',
    'recognise_signs_abuse': '',
    'respond_disclosure': '',
    'complete_referrals': '',
  };

  // Section 3: Safeguarding Practice (5 criteria)
  Map<String, String> _safeguardingPractice = {
    'policy_accessible': '',
    'reporting_followed': '',
    'incident_documentation': '',
    'confidentiality_maintained': '',
    'multi_agency_working': '',
  };

  // Section 4: Overall Decision
  String _overallDecision = 'competent';
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

  Map<String, dynamic> get _scoringResult {
    return CompetencyScoring.calculateFromMaps([
      _safeguardingKnowledge,
      _safeguardingPractice,
    ]);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final scoring = _scoringResult;

      // Create competency ratings
      final competencyRatings = <CompetencyRating>[];

      // Safeguarding Knowledge
      for (final entry in _safeguardingKnowledge.entries) {
        competencyRatings.add(CompetencyRating(
          competencyId: 'safeguarding_knowledge_${entry.key}',
          competencyName: _getKnowledgeDisplayName(entry.key),
          achievedLevel: entry.value == 'yes' ? 4 : 2,
          assessorNotes: entry.value == 'yes' ? 'Passed' : 'Failed',
          assessedDate: _assessmentDate,
        ));
      }

      // Safeguarding Practice
      for (final entry in _safeguardingPractice.entries) {
        competencyRatings.add(CompetencyRating(
          competencyId: 'safeguarding_practice_${entry.key}',
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
        overallRating: scoring['overallRating'],
        passed: scoring['passed'],
        developmentAreas: scoring['overallRating'] == 'competent' ? [] : ['Safeguarding procedures', 'Reporting requirements'],
        actionPlan: scoring['actionPlan'],
        nextReviewDate: DateTime.now().add(const Duration(days: 90)),
        status: 'approved',
        staffSignOffDate: _signOffDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _service.createAssessment(assessment);

      if (mounted) {
        final rating = scoring['overallRating'];
        final msg = rating == 'competent' ? 'Staff assessed as COMPETENT (Score: ${scoring['score']}%)'
            : rating == 'requires_reassessment' ? 'Staff requires reassessment (Score: ${scoring['score']}%)'
            : 'Staff NOT COMPETENT - action plan initiated (Score: ${scoring['score']}%)';
        final color = rating == 'competent' ? Colors.green
            : rating == 'requires_reassessment' ? Colors.orange
            : Colors.red;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
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
      case 'identify_abuse_types': return 'Can identify types of abuse';
      case 'reporting_procedure': return 'Understands safeguarding reporting procedure';
      case 'recognise_signs_abuse': return 'Can recognise signs of abuse and neglect';
      case 'respond_disclosure': return 'Knows how to respond to a safeguarding disclosure';
      case 'complete_referrals': return 'Confident in completing safeguarding referrals';
      default: return key;
    }
  }

  String _getPracticeDisplayName(String key) {
    switch (key) {
      case 'policy_accessible': return 'Safeguarding policy accessible';
      case 'reporting_followed': return 'Reporting procedure followed';
      case 'incident_documentation': return 'Incident documentation correct';
      case 'confidentiality_maintained': return 'Confidentiality maintained';
      case 'multi_agency_working': return 'Multi-agency working demonstrated';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safeguarding Assessment'),
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

            // Section 2: Safeguarding Knowledge
            _buildSectionHeader('Safeguarding Knowledge'),
            ..._buildCriteriaRows(_safeguardingKnowledge, 'knowledge'),
            const SizedBox(height: 24),

            // Section 3: Safeguarding Practice
            _buildSectionHeader('Safeguarding Practice'),
            ..._buildCriteriaRows(_safeguardingPractice, 'practice'),
            const SizedBox(height: 24),

            // Section 4: Overall Decision
            _buildSectionHeader('Overall Competency Decision (Auto-calculated)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _scoringResult['overallRating'] == 'competent' ? Colors.green.shade50 :
                       _scoringResult['overallRating'] == 'requires_reassessment' ? Colors.orange.shade50 :
                       Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _scoringResult['overallRating'] == 'competent' ? Colors.green :
                         _scoringResult['overallRating'] == 'requires_reassessment' ? Colors.orange :
                         Colors.red,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(
                    _scoringResult['overallRating'] == 'competent' ? Icons.check_circle :
                    _scoringResult['overallRating'] == 'requires_reassessment' ? Icons.refresh :
                    Icons.warning,
                    color: _scoringResult['overallRating'] == 'competent' ? Colors.green :
                           _scoringResult['overallRating'] == 'requires_reassessment' ? Colors.orange :
                           Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Score: ${_scoringResult['score']}% - ${CompetencyScoring.getRatingLabel(_scoringResult['overallRating'])}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                        color: _scoringResult['overallRating'] == 'competent' ? Colors.green :
                               _scoringResult['overallRating'] == 'requires_reassessment' ? Colors.orange :
                               Colors.red,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${_scoringResult['correctCount']} correct, ${_scoringResult['incorrectCount']} incorrect, ${_scoringResult['naCount']} N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ]),
            ),
            if (_scoringResult['overallRating'] != 'competent')
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