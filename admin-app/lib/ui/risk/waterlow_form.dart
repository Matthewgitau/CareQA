import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class WaterlowForm extends StatefulWidget {
  final String? assessmentId;
  final String? serviceUserId;
  final String? serviceUserName;

  const WaterlowForm({
    super.key,
    this.assessmentId,
    this.serviceUserId,
    this.serviceUserName,
  });

  @override
  State<WaterlowForm> createState() => _WaterlowFormState();
}

class _WaterlowFormState extends State<WaterlowForm> {
  final _service = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isEditing = false;

  DateTime? _assessmentDate;
  Map<int, String> _responses = {};
  List<Map<String, dynamic>> _questions = [];
  int _totalScore = 0;

  @override
  void initState() {
    super.initState();
    _assessmentDate = DateTime.now();
    _loadQuestions();
    if (widget.assessmentId != null) {
      _loadAssessment();
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final response = await _service
          .from('waterlow_questions')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      setState(() {
        _questions = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  Future<void> _loadAssessment() async {
    setState(() => _loading = true);
    try {
      final response = await _service
          .from('waterlow_assessments')
          .select()
          .eq('id', widget.assessmentId!)
          .single();

      final responses = Map<String, dynamic>.from(response['responses'] as Map);
      setState(() {
        _responses = responses.map((key, value) => MapEntry(int.parse(key), value as String));
        _assessmentDate = response['assessment_date'] != null
            ? DateTime.parse(response['assessment_date'])
            : DateTime.now();
        _isEditing = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assessment: $e')),
        );
      }
    }
  }

  int _calculateTotalScore() {
    int total = 0;
    for (final question in _questions) {
      final questionId = question['id'] as int;
      final selectedOption = _responses[questionId];
      if (selectedOption != null) {
        final options = question['options'] as Map<String, dynamic>;
        if (options.containsKey(selectedOption)) {
          total += (options[selectedOption] as num).toInt();
        }
      }
    }
    return total;
  }

  String _getRiskLevel(int score) {
    if (score >= 20) return 'Very High Risk';
    if (score >= 15) return 'High Risk';
    if (score >= 10) return 'At Risk';
    return 'No Risk';
  }

  Color _getRiskColor(int score) {
    if (score >= 20) return Colors.red;
    if (score >= 15) return Colors.orange;
    if (score >= 10) return Colors.amber;
    return Colors.green;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_responses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer at least one question')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final totalScore = _calculateTotalScore();
      final riskLevel = _getRiskLevel(totalScore);
      final responsesMap = _responses.map((key, value) => MapEntry(key.toString(), value));

      if (_isEditing) {
        await _service
            .from('waterlow_assessments')
            .update({
              'assessment_date': _assessmentDate!.toIso8601String(),
              'responses': responsesMap,
              'total_score': totalScore,
              'risk_level': riskLevel,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.assessmentId!);
      } else {
        await _service.from('waterlow_assessments').insert({
          'service_user_id': widget.serviceUserId,
          'assessor_id': _service.auth.currentUser?.id,
          'assessment_date': _assessmentDate!.toIso8601String(),
          'responses': responsesMap,
          'total_score': totalScore,
          'risk_level': riskLevel,
          'status': 'completed',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assessment saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving assessment: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalScore = _calculateTotalScore();
    final riskLevel = _getRiskLevel(totalScore);
    final riskColor = _getRiskColor(totalScore);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Waterlow Assessment' : 'New Waterlow Assessment'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Score Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          border: Border.all(color: riskColor, width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Total Score', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalScore',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: riskColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      riskLevel,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: riskColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (widget.serviceUserName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Service User: ${widget.serviceUserName}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Questions List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            final questionId = question['id'] as int;
                            final questionText = question['question_text'] as String;
                            final category = question['category'] as String?;
                            final options = question['options'] as Map<String, dynamic>;
                            final selectedOption = _responses[questionId];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      questionText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (category != null)
                                      Text(
                                        'Category: $category',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: options.keys.map((option) {
                                        final score = (options[option] as num).toInt();
                                        final isSelected = selectedOption == option;
                                        return ChoiceChip(
                                          label: Text('$option (${score > 0 ? '+$score' : score})'),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _responses[questionId] = option;
                                              } else {
                                                _responses.remove(questionId);
                                              }
                                            });
                                          },
                                          selectedColor: const Color(0xFF1565C0).withOpacity(0.2),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Save Button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              _isEditing ? 'Update Assessment' : 'Save Assessment',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}