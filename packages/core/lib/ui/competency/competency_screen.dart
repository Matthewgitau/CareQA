import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';
import '../../services/auth_service.dart';

class CompetencyScreen extends StatefulWidget {
  final String serviceUserId;

  const CompetencyScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _CompetencyScreenState createState() => _CompetencyScreenState();
}

class _CompetencyScreenState extends State<CompetencyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CompetencyService _competencyService;
  late AuthService _authService;
  List<CompetencyAssessment> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _competencyService = CompetencyService(Supabase.instance.client);
    _authService = AuthService();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      _assessments = await _competencyService.getForServiceUser(widget.serviceUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load assessments: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competency Assessment'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'History'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewAssessmentTab(),
          _buildHistoryTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildNewAssessmentTab() {
    return NewCompetencyAssessment(
      serviceUserId: widget.serviceUserId,
      onAssessmentCreated: () {
        _loadAssessments();
        _tabController.index = 1; // Switch to history tab
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assessments.isEmpty) {
      return const Center(child: Text('No competency assessments found'));
    }

    return ListView.builder(
      itemCount: _assessments.length,
      itemBuilder: (context, index) {
        final assessment = _assessments[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)),
            subtitle: Text('Status: ${assessment.status}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompetencyDetailScreen(assessment: assessment),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    return const Center(child: Text('Summary coming soon'));
  }
}

class NewCompetencyAssessment extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onAssessmentCreated;

  const NewCompetencyAssessment({
    Key? key,
    required this.serviceUserId,
    required this.onAssessmentCreated,
  }) : super(key: key);

  @override
  _NewCompetencyAssessmentState createState() => _NewCompetencyAssessmentState();
}

class _NewCompetencyAssessmentState extends State<NewCompetencyAssessment> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _assessorController = TextEditingController();
  final _staffController = TextEditingController();
  final _nextReviewController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _nextReviewController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 180)));
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'assessment_date': '',
      'assessor_name': '',
      'staff_name': '',
      'skill_competency': '',
      'competency_criteria': [],
      'knowledge_questions': [
        {'question': '', 'answer': '', 'correct': false},
        {'question': '', 'answer': '', 'correct': false},
        {'question': '', 'answer': '', 'correct': false},
      ],
      'overall_outcome': '',
      'conditions_notes': '',
      'next_review_date': '',
      'assessor_signature': '',
      'staff_signature': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Competency Assessment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Assessment Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Assessment Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _assessorController,
                    decoration: const InputDecoration(labelText: 'Assessor Name'),
                    onChanged: (value) {
                      _responses['assessor_name'] = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _staffController,
              decoration: const InputDecoration(labelText: 'Staff Name'),
              onChanged: (value) {
                _responses['staff_name'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Skill/Competency Being Assessed'),
              onChanged: (value) {
                _responses['skill_competency'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Competency Criteria',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            CompetencyCriteriaWidget(
              criteria: _responses['competency_criteria'],
              onCriteriaChanged: (criteria) {
                _responses['competency_criteria'] = criteria;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Knowledge Questions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            KnowledgeQuestionsWidget(
              questions: _responses['knowledge_questions'],
              onQuestionsChanged: (questions) {
                _responses['knowledge_questions'] = questions;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Overall Outcome',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _responses['overall_outcome'],
              decoration: const InputDecoration(labelText: 'Overall Outcome'),
              items: [
                DropdownMenuItem(value: 'competent_signed_off', child: Text('Competent - Signed Off')),
                DropdownMenuItem(value: 'competent_conditions', child: Text('Competent with Conditions')),
                DropdownMenuItem(value: 'not_yet_competent', child: Text('Not Yet Competent - Further Training Required')),
              ],
              onChanged: (value) {
                _responses['overall_outcome'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Conditions Notes (if applicable)',
                hintText: 'Specify any conditions or limitations for competent with conditions',
              ),
              maxLines: 3,
              onChanged: (value) {
                _responses['conditions_notes'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Next Review',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nextReviewController,
              decoration: const InputDecoration(
                labelText: 'Next Review Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 180)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  _nextReviewController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
              onChanged: (value) {
                _responses['next_review_date'] = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Signatures',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Assessor Signature'),
                    onChanged: (value) {
                      _responses['assessor_signature'] = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Staff Signature (Acknowledgement)'),
                    onChanged: (value) {
                      _responses['staff_signature'] = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAssessment,
                    child: const Text('Save Competency Assessment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      final assessment = CompetencyAssessment(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _competencyService.create(assessment);
      widget.onAssessmentCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Competency assessment saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save assessment: $e')),
      );
    }
  }
}

class CompetencyCriteriaWidget extends StatefulWidget {
  final List<Map<String, dynamic>> criteria;
  final Function(List<Map<String, dynamic>>) onCriteriaChanged;

  const CompetencyCriteriaWidget({
    Key? key,
    required this.criteria,
    required this.onCriteriaChanged,
  }) : super(key: key);

  @override
  _CompetencyCriteriaWidgetState createState() => _CompetencyCriteriaWidgetState();
}

class _CompetencyCriteriaWidgetState extends State<CompetencyCriteriaWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.criteria.asMap().entries.map((entry) {
          final index = entry.key;
          final criterion = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Criterion ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Criterion Description'),
                    initialValue: criterion['description'] ?? '',
                    onChanged: (value) {
                      widget.criteria[index]['description'] = value;
                      widget.onCriteriaChanged(widget.criteria);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: criterion['level'],
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: [
                      DropdownMenuItem(value: 'competent', child: Text('Competent')),
                      DropdownMenuItem(value: 'developing', child: Text('Developing')),
                      DropdownMenuItem(value: 'not_yet_competent', child: Text('Not Yet Competent')),
                      DropdownMenuItem(value: 'n_a', child: Text('N/A')),
                    ],
                    onChanged: (value) {
                      widget.criteria[index]['level'] = value;
                      widget.onCriteriaChanged(widget.criteria);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Assessor Comments'),
                    initialValue: criterion['comments'] ?? '',
                    maxLines: 3,
                    onChanged: (value) {
                      widget.criteria[index]['comments'] = value;
                      widget.onCriteriaChanged(widget.criteria);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _removeCriterion(index),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addCriterion,
          icon: const Icon(Icons.add),
          label: const Text('Add Criterion'),
        ),
      ],
    );
  }

  void _addCriterion() {
    setState(() {
      widget.criteria.add({
        'description': '',
        'level': '',
        'comments': '',
      });
      widget.onCriteriaChanged(widget.criteria);
    });
  }

  void _removeCriterion(int index) {
    setState(() {
      widget.criteria.removeAt(index);
      widget.onCriteriaChanged(widget.criteria);
    });
  }
}

class KnowledgeQuestionsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final Function(List<Map<String, dynamic>>) onQuestionsChanged;

  const KnowledgeQuestionsWidget({
    Key? key,
    required this.questions,
    required this.onQuestionsChanged,
  }) : super(key: key);

  @override
  _KnowledgeQuestionsWidgetState createState() => _KnowledgeQuestionsWidgetState();
}

class _KnowledgeQuestionsWidgetState extends State<KnowledgeQuestionsWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Question'),
                    initialValue: question['question'] ?? '',
                    onChanged: (value) {
                      widget.questions[index]['question'] = value;
                      widget.onQuestionsChanged(widget.questions);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Answer'),
                    initialValue: question['answer'] ?? '',
                    maxLines: 3,
                    onChanged: (value) {
                      widget.questions[index]['answer'] = value;
                      widget.onQuestionsChanged(widget.questions);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<bool>(
                    value: question['correct'],
                    decoration: const InputDecoration(labelText: 'Correct?'),
                    items: [
                      DropdownMenuItem(value: true, child: Text('Yes')),
                      DropdownMenuItem(value: false, child: Text('No')),
                    ],
                    onChanged: (value) {
                      widget.questions[index]['correct'] = value;
                      widget.onQuestionsChanged(widget.questions);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class CompetencyDetailScreen extends StatelessWidget {
  final CompetencyAssessment assessment;

  const CompetencyDetailScreen({Key? key, required this.assessment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Competency Assessment - ${DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${assessment.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildAssessmentDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Information',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Assessor: ${assessment.responses['assessor_name'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Staff: ${assessment.responses['staff_name'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Skill/Competency: ${assessment.responses['skill_competency'] ?? ''}'),
            const SizedBox(height: 16),
            Text(
              'Competency Criteria',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildCompetencyCriteria(),
            const SizedBox(height: 16),
            Text(
              'Knowledge Questions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildKnowledgeQuestions(),
            const SizedBox(height: 16),
            Text(
              'Overall Outcome: ${_getOutcomeLabel(assessment.responses['overall_outcome'] ?? '')}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (assessment.responses['conditions_notes'] != null && assessment.responses['conditions_notes'] != '')
              Text(
                'Conditions Notes: ${assessment.responses['conditions_notes']}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            const SizedBox(height: 8),
            Text(
              'Next Review: ${assessment.responses['next_review_date'] ?? ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Assessor Signature: ${assessment.responses['assessor_signature'] ?? ''}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Staff Signature: ${assessment.responses['staff_signature'] ?? ''}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCompetencyCriteria() {
    final criteria = assessment.responses['competency_criteria'] as List? ?? [];
    return criteria.map((crit) {
      final criterion = crit as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${criterion['description'] ?? ''}'),
            Text('  Level: ${_getLevelLabel(criterion['level'] ?? '')}'),
            if (criterion['comments'] != null && criterion['comments'] != '')
              Text('  Comments: ${criterion['comments']}'),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildKnowledgeQuestions() {
    final questions = assessment.responses['knowledge_questions'] as List? ?? [];
    return questions.map((q) {
      final question = q as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Q: ${question['question'] ?? ''}'),
            Text('A: ${question['answer'] ?? ''}'),
            Text('Correct: ${question['correct'] == true ? 'Yes' : 'No'}'),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildActionPlan() {
    if (assessment.actionPlan.isEmpty) {
      return const Text('No action plan items');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agreed Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...assessment.actionPlan.map((item) => Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What: ${item['what'] ?? ''}'),
                      Text('Who: ${item['who'] ?? ''}'),
                      Text('By When: ${item['by_when'] ?? ''}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  String _getOutcomeLabel(String outcome) {
    switch (outcome) {
      case 'competent_signed_off': return 'Competent - Signed Off';
      case 'competent_conditions': return 'Competent with Conditions';
      case 'not_yet_competent': return 'Not Yet Competent - Further Training Required';
      default: return outcome;
    }
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'competent': return 'Competent';
      case 'developing': return 'Developing';
      case 'not_yet_competent': return 'Not Yet Competent';
      case 'n_a': return 'N/A';
      default: return level;
    }
  }
}