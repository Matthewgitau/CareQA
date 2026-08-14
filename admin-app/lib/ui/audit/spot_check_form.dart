import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/services/spot_check_service.dart';

class SpotCheckForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const SpotCheckForm({
    super.key,
    required this.serviceUserId,
    required this.serviceUserName,
  });

  @override
  State<SpotCheckForm> createState() => _SpotCheckFormState();
}

class _SpotCheckFormState extends State<SpotCheckForm> {
  final _formKey = GlobalKey<FormState>();
  final _auditorController = TextEditingController();
  final _commentControllers = <int, TextEditingController>{};
  final _answers = <int, String>{};
  final _deadlines = <int, DateTime?>{};
  final _selectedButtonIndex = <int, int>{};
  bool _isLoading = false;

  late Future<List<Map<String, dynamic>>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuestions();
  }

  Future<List<Map<String, dynamic>>> _loadQuestions() async {
    final spotCheckService = Provider.of<SpotCheckService>(context, listen: false);
    return await spotCheckService.getQuestionsRaw();
  }

  String _getQuestionText(Map<String, dynamic> question) {
    return question['question_text'] ?? '';
  }

  String _getCategory(Map<String, dynamic> question) {
    return question['category'] ?? '';
  }

  bool _isServiceUserFeedbackQuestion(Map<String, dynamic> question) {
    final category = _getCategory(question).toLowerCase();
    return category.contains('service user feedback');
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

  Future<void> _submitSpotCheck() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final spotCheckService = Provider.of<SpotCheckService>(context, listen: false);

        // Create spot check record
        final spotCheckId = await spotCheckService.createSpotCheck(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          assessorName: _auditorController.text.trim(),
          spotCheckDate: DateTime.now(),
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

        // Complete spot check
        await spotCheckService.completeSpotCheck(spotCheckId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Spot Check submitted successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting spot check: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildAnswerButtons(int questionId) {
    final options = ['Yes', 'No', 'N/A'];
    final values = ['yes', 'no', 'na'];
    final selectedIndex = _selectedButtonIndex[questionId] ?? -1;

    return Row(
      children: List.generate(options.length, (index) {
        final isSelected = selectedIndex == index;
        final color = index == 0 
            ? Colors.green 
            : index == 1 
                ? Colors.red 
                : Colors.grey;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? color : Colors.transparent,
                foregroundColor: isSelected ? Colors.white : color,
                elevation: isSelected ? 2 : 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: color, width: 1.5),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedButtonIndex[questionId] = index;
                  _answers[questionId] = values[index];
                });
              },
              child: Text(
                options[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spot Check - ${widget.serviceUserName}'),
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
                              'Spot Check Information',
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
                        final groupedQuestions = <String, List<Map<String, dynamic>>>{};

                        // Group questions by category
                        for (final question in questions) {
                          final category = _getCategory(question);
                          if (!groupedQuestions.containsKey(category)) {
                            groupedQuestions[category] = [];
                          }
                          groupedQuestions[category]!.add(question);
                        }

                        return Column(
                          children: groupedQuestions.entries.map((entry) {
                            final category = entry.key;
                            final categoryQuestions = entry.value;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        category.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Questions in this category
                                    Column(
                                      children: categoryQuestions.map((question) {
                                        final questionId = question['id'] as int;
                                        final questionText = _getQuestionText(question);
                                        final isServiceUserFeedback = _isServiceUserFeedbackQuestion(question);

                                        // Initialize controllers if not exists
                                        if (!_commentControllers.containsKey(questionId)) {
                                          _commentControllers[questionId] = TextEditingController();
                                        }

                                        return Column(
                                          children: [
                                            Card(
                                              margin: const EdgeInsets.symmetric(vertical: 8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
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

                                                    // Answer Buttons
                                                    _buildAnswerButtons(questionId),

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

                                                    if (isServiceUserFeedback) ...[
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
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
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
                        onPressed: _submitSpotCheck,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: const Text('Submit Spot Check'),
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