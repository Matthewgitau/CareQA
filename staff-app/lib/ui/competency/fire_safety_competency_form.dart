import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fire Safety Competency Assessment Form
class FireSafetyCompetencyForm extends StatefulWidget {
  const FireSafetyCompetencyForm({super.key});

  @override
  State<FireSafetyCompetencyForm> createState() => _FireSafetyCompetencyFormState();
}

class _FireSafetyCompetencyFormState extends State<FireSafetyCompetencyForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isSubmitting = false;

  Map<String, dynamic> _answers = {};
  String? _overallConfidence;
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _questions = [
    {
      'id': 'fire_extinguishers',
      'question': 'Can you identify the different types of fire extinguishers and their uses?',
      'type': 'yes_no',
    },
    {
      'id': 'evacuation_procedures',
      'question': 'Do you know the emergency evacuation procedures for your work area?',
      'type': 'yes_no',
    },
    {
      'id': 'peep_completion',
      'question': 'Can you complete a Personal Emergency Evacuation Plan (PEEP) for a service user?',
      'type': 'yes_no',
    },
    {
      'id': 'fire_risk_assessment',
      'question': 'Do you understand the fire risk assessment process?',
      'type': 'yes_no',
    },
    {
      'id': 'raise_alarm',
      'question': 'Are you confident in raising the fire alarm and calling emergency services?',
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
        'competency_type': 'fire_safety',
        'completed_date': DateTime.now().toIso8601String().split('T')[0],
        'expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
        'status': 'valid',
        'outcome': outcome,
        'answers': answers,
        'notes': _notesController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fire safety competency submitted'), backgroundColor: Colors.green),
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
        title: const Text('Fire Safety Competency'),
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
                Icon(Icons.local_fire_department, color: const Color(0xFF1565C0), size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Fire Safety Competency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This assessment covers fire safety knowledge and emergency procedures.',
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
            const Text('Overall, how confident do you feel with fire safety procedures?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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