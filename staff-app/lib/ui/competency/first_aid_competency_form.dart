import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// First Aid Competency Assessment Form
class FirstAidCompetencyForm extends StatefulWidget {
  const FirstAidCompetencyForm({super.key});

  @override
  State<FirstAidCompetencyForm> createState() => _FirstAidCompetencyFormState();
}

class _FirstAidCompetencyFormState extends State<FirstAidCompetencyForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isSubmitting = false;

  Map<String, dynamic> _answers = {};
  String? _overallConfidence;
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _questions = [
    {
      'id': 'cpr_adult',
      'question': 'Can you perform CPR on an adult service user?',
      'type': 'yes_no',
    },
    {
      'id': 'aed_usage',
      'question': 'Do you know how to use an Automated External Defibrillator (AED)?',
      'type': 'yes_no',
    },
    {
      'id': 'common_injuries',
      'question': 'Can you identify and treat common injuries (cuts, burns, falls)?',
      'type': 'yes_no',
    },
    {
      'id': 'choking_protocol',
      'question': 'Do you understand the first aid protocol for choking?',
      'type': 'yes_no',
    },
    {
      'id': 'accident_reports',
      'question': 'Are you confident in completing accident reports and incident documentation?',
      'type': 'yes_no',
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('You must be logged in');

      final profileResponse = await _supabase
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .single();

      final answers = Map<String, dynamic>.from(_answers);
      answers['overall_confidence'] = _overallConfidence;

      bool allYes = _questions.every((q) => answers[q['id']] == 'yes');
      String outcome = allYes ? 'pass' : 'requires_training';

      await _supabase.from('staff_competency_records').insert({
        'staff_id': user.id,
        'staff_name': profileResponse['name'],
        'competency_type': 'first_aid',
        'completed_date': DateTime.now().toIso8601String().split('T')[0],
        'expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
        'status': 'valid',
        'outcome': outcome,
        'answers': answers,
        'notes': _notesController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('First aid competency submitted'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Competency'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            ..._questions.map((q) => _buildQuestionCard(q)),
            const SizedBox(height: 16),
            _buildConfidenceCard(),
            const SizedBox(height: 16),
            _buildNotesCard(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: const Color(0xFF1565C0), size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('First Aid Competency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This assessment covers essential first aid skills and emergency response.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question['question'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: RadioListTile<String>(title: const Text('Yes'), value: 'yes', groupValue: _answers[question['id']], onChanged: (v) => setState(() => _answers[question['id']] = v), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
                Expanded(child: RadioListTile<String>(title: const Text('No'), value: 'no', groupValue: _answers[question['id']], onChanged: (v) => setState(() => _answers[question['id']] = v), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overall, how confident do you feel providing first aid?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _overallConfidence,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Select confidence level'),
              items: const [
                DropdownMenuItem(value: 'very_confident', child: Text('Very Confident')),
                DropdownMenuItem(value: 'confident', child: Text('Confident')),
                DropdownMenuItem(value: 'somewhat_confident', child: Text('Somewhat Confident')),
                DropdownMenuItem(value: 'not_confident', child: Text('Not Confident')),
              ],
              onChanged: (v) => setState(() => _overallConfidence = v),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Additional Notes (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(controller: _notesController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Any comments...'), maxLines: 4),
          ],
        ),
      ),
    );
  }
}