import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Medication Competency Assessment Form
/// Staff members complete this form to demonstrate their medication competency.
class MedicationCompetencyForm extends StatefulWidget {
  const MedicationCompetencyForm({super.key});

  @override
  State<MedicationCompetencyForm> createState() => _MedicationCompetencyFormState();
}

class _MedicationCompetencyFormState extends State<MedicationCompetencyForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Form answers
  Map<String, dynamic> _answers = {};
  String? _overallConfidence;
  final TextEditingController _notesController = TextEditingController();

  // Questions for Medication Competency
  final List<Map<String, dynamic>> _questions = [
    {
      'id': 'identify_medications',
      'question': 'Can you identify common medications?',
      'type': 'yes_no',
    },
    {
      'id': 'six_rights',
      'question': 'Do you understand the 6 rights of medication administration?',
      'type': 'yes_no',
    },
    {
      'id': 'mar_chart',
      'question': 'Can you complete a MAR chart correctly?',
      'type': 'yes_no',
    },
    {
      'id': 'controlled_drugs',
      'question': 'Do you know how to handle controlled drugs?',
      'type': 'yes_no',
    },
    {
      'id': 'medication_errors',
      'question': 'Can you identify medication errors?',
      'type': 'yes_no',
    },
    {
      'id': 'storage_requirements',
      'question': 'Do you know medication storage requirements?',
      'type': 'yes_no',
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to submit this form');
      }

      // Get user profile for name
      final profileResponse = await _supabase
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .single();

      // Prepare answers
      final answers = Map<String, dynamic>.from(_answers);
      answers['overall_confidence'] = _overallConfidence;

      // Determine outcome based on answers
      bool allYes = _questions.every((q) => answers[q['id']] == 'yes');
      String outcome = allYes ? 'pass' : 'requires_training';

      // Create competency record
      await _supabase.from('staff_competency_records').insert({
        'staff_id': user.id,
        'staff_name': profileResponse['name'],
        'competency_type': 'medication',
        'completed_date': DateTime.now().toIso8601String().split('T')[0],
        'expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
        'status': 'valid',
        'outcome': outcome,
        'answers': answers,
        'notes': _notesController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication competency assessment submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Medication Competency'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medication, color: const Color(0xFF1565C0), size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Medication Competency Assessment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please answer the following questions honestly. This assessment helps ensure you have the knowledge and skills needed for safe medication administration.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Questions
            ..._questions.map((question) => _buildQuestionCard(question)),
            const SizedBox(height: 16),

            // Overall confidence
            _buildConfidenceCard(),
            const SizedBox(height: 16),

            // Notes
            _buildNotesCard(),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
            Text(
              question['question'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Yes'),
                    value: 'yes',
                    groupValue: _answers[question['id']],
                    onChanged: (value) {
                      setState(() {
                        _answers[question['id']] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('No'),
                    value: 'no',
                    groupValue: _answers[question['id']],
                    onChanged: (value) {
                      setState(() {
                        _answers[question['id']] = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
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
            const Text(
              'Overall, how confident do you feel administering medications?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _overallConfidence,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select confidence level',
              ),
              items: const [
                DropdownMenuItem(value: 'very_confident', child: Text('Very Confident')),
                DropdownMenuItem(value: 'confident', child: Text('Confident')),
                DropdownMenuItem(value: 'somewhat_confident', child: Text('Somewhat Confident')),
                DropdownMenuItem(value: 'not_confident', child: Text('Not Confident')),
              ],
              onChanged: (value) {
                setState(() {
                  _overallConfidence = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your confidence level';
                }
                return null;
              },
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
            const Text(
              'Additional Notes (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Any additional comments or areas you\'d like support with...',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}