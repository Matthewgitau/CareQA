import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/services/mar_audit_service.dart';
import 'package:admin_app/services/database_service.dart';

class MarAuditForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const MarAuditForm({
    super.key,
    required this.serviceUserId,
    required this.serviceUserName,
  });

  @override
  State<MarAuditForm> createState() => _MarAuditFormState();
}

class _MarAuditFormState extends State<MarAuditForm> {
  final _formKey = GlobalKey<FormState>();
  final _auditorController = TextEditingController();
  final _commentControllers = <int, TextEditingController>{};
  final _answers = <int, String>{};
  final _deadlines = <int, DateTime?>{};
  bool _isLoading = false;

  late Future<List<Map<String, dynamic>>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = Future.value([]);
  }

  bool _questionsLoaded = false;

  Future<List<Map<String, dynamic>>> _loadQuestions() async {
    final marAuditService = Provider.of<MarAuditService>(context, listen: false);
    return await marAuditService.getQuestionsRaw();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_questionsLoaded) {
      _questionsLoaded = true;
      _questionsFuture = _loadQuestions();
    }
  }

  String _getQuestionText(Map<String, dynamic> question) {
    return question['question_text'] ?? '';
  }

  bool _isWarfarinQuestion(Map<String, dynamic> question) {
    final text = _getQuestionText(question).toLowerCase();
    return text.contains('warfarin') || text.contains('anticoagulant');
  }

  void _selectDeadline(int questionId) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      setState(() {
        _deadlines[questionId] = picked;
      });
    }
  }

  Future<void> _submitAudit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final marAuditService = Provider.of<MarAuditService>(context, listen: false);

        // Create audit record
        final auditId = await marAuditService.createAudit(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          assessorName: _auditorController.text.trim(),
          auditDate: DateTime.now(),
        );

        // Save answers using the service's saveAnswers method
        final answers = <int, dynamic>{};
        
        for (final question in await _questionsFuture) {
          final questionId = question['id'] as int;
          final answer = _answers[questionId] ?? 'na';
          final comment = _commentControllers[questionId]?.text.trim() ?? '';
          final deadline = _deadlines[questionId];

          answers[questionId] = {
            'answer': answer,
            'comment': comment,
            'deadlineDate': deadline,
            'notificationSent': false,
          };
        }

        // Complete audit
        await marAuditService.completeAudit(auditId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MAR Audit submitted successfully')),
        );

        Navigator.pop(context, true); // Return success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting audit: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MAR Audit - ${widget.serviceUserName}'),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Auditor Information
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Audit Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _auditorController,
                            decoration: const InputDecoration(
                              labelText: 'Auditor Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter auditor name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Service User: ${widget.serviceUserName}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Questions
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _questionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading questions: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No questions found'));
                      }

                      final questions = snapshot.data!;

                      return Column(
                        children: questions.map((question) {
                          final questionId = question['id'] as int;
                          final questionText = _getQuestionText(question);
                          final isWarfarin = _isWarfarinQuestion(question);

                          // Initialize controllers if not exists
                          if (!_commentControllers.containsKey(questionId)) {
                            _commentControllers[questionId] = TextEditingController();
                          }

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    questionText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Answer Options
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: const Text('Yes'),
                                          value: 'yes',
                                          groupValue: _answers[questionId],
                                          onChanged: (value) {
                                            setState(() {
                                              _answers[questionId] = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: const Text('No'),
                                          value: 'no',
                                          groupValue: _answers[questionId],
                                          onChanged: (value) {
                                            setState(() {
                                              _answers[questionId] = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: const Text('N/A'),
                                          value: 'na',
                                          groupValue: _answers[questionId],
                                          onChanged: (value) {
                                            setState(() {
                                              _answers[questionId] = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Comment Field
                                  TextFormField(
                                    controller: _commentControllers[questionId],
                                    decoration: const InputDecoration(
                                      labelText: 'Comments (optional)',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  ),

                                  if (isWarfarin) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text('Deadline Date:'),
                                        const SizedBox(width: 12),
                                        OutlinedButton(
                                          onPressed: () => _selectDeadline(questionId),
                                          child: Text(
                                            _deadlines[questionId] != null
                                              ? '${_deadlines[questionId]!.day}/${_deadlines[questionId]!.month}/${_deadlines[questionId]!.year}'
                                              : 'Select Deadline',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitAudit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('Submit Audit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _auditorController.dispose();
    _commentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}