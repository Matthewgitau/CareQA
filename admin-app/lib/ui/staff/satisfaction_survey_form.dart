import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/satisfaction_survey.dart';
import '../../services/satisfaction_service.dart';
import '../../widgets/reusable_form_widgets.dart';

class SatisfactionSurveyFormScreen extends StatefulWidget {
  final SatisfactionSurvey? survey;

  const SatisfactionSurveyFormScreen({super.key, this.survey});

  @override
  State<SatisfactionSurveyFormScreen> createState() => _SatisfactionSurveyFormScreenState();
}

class _SatisfactionSurveyFormScreenState extends State<SatisfactionSurveyFormScreen> {
  final _service = SatisfactionService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  String? _selectedStaffId;
  String? _selectedStaffName;
  String _surveyType = 'standard';
  DateTime _surveyDate = DateTime.now();
  int? _overallSatisfaction;
  int? _engagementScore;
  int? _motivationScore;
  int? _workEnvironmentScore;
  int? _teamCollaborationScore;
  int? _resourcesAvailableScore;
  int? _managementSupportScore;
  int? _leadershipTrustScore;
  int? _communicationScore;
  int? _feedbackEffectivenessScore;
  int? _careerDevelopmentScore;
  int? _trainingOpportunitiesScore;
  int? _recognitionScore;
  int? _workLifeBalanceScore;
  int? _flexibilityScore;
  final _enjoyController = TextEditingController();
  final _improveController = TextEditingController();
  final _suggestionsController = TextEditingController();
  final _commentsController = TextEditingController();
  bool? _feelValued;
  bool? _feelHeard;
  bool? _feelSupported;
  bool? _feelDeveloped;
  bool? _feelRecognized;
  bool _isAnonymous = false;
  bool _isSaving = false;

  final List<String> _surveyTypes = ['standard', 'quarterly', 'annual', 'pulse', 'exit', 'onboarding', 'project_feedback'];

  @override
  void initState() {
    super.initState();
    if (widget.survey != null) {
      _populateForm(widget.survey!);
    }
  }

  void _populateForm(SatisfactionSurvey survey) {
    _selectedStaffId = survey.staffId;
    _selectedStaffName = survey.staffName;
    _surveyType = survey.surveyType;
    _surveyDate = survey.surveyDate;
    _overallSatisfaction = survey.overallSatisfaction;
    _engagementScore = survey.engagementScore;
    _motivationScore = survey.motivationScore;
    _workEnvironmentScore = survey.workEnvironmentScore;
    _teamCollaborationScore = survey.teamCollaborationScore;
    _resourcesAvailableScore = survey.resourcesAvailableScore;
    _managementSupportScore = survey.managementSupportScore;
    _leadershipTrustScore = survey.leadershipTrustScore;
    _communicationScore = survey.communicationScore;
    _feedbackEffectivenessScore = survey.feedbackEffectivenessScore;
    _careerDevelopmentScore = survey.careerDevelopmentScore;
    _trainingOpportunitiesScore = survey.trainingOpportunitiesScore;
    _recognitionScore = survey.recognitionScore;
    _workLifeBalanceScore = survey.workLifeBalanceScore;
    _flexibilityScore = survey.flexibilityScore;
    _enjoyController.text = survey.whatDoYouEnjoy ?? '';
    _improveController.text = survey.whatCouldImprove ?? '';
    _suggestionsController.text = survey.suggestionsForImprovement ?? '';
    _commentsController.text = survey.additionalComments ?? '';
    _feelValued = survey.feelValued;
    _feelHeard = survey.feelHeard;
    _feelSupported = survey.feelSupported;
    _feelDeveloped = survey.feelDeveloped;
    _feelRecognized = survey.feelRecognized;
    _isAnonymous = survey.isAnonymous;
  }

  @override
  void dispose() {
    _enjoyController.dispose();
    _improveController.dispose();
    _suggestionsController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final survey = SatisfactionSurvey(
        id: widget.survey?.id ?? '',
        staffId: _selectedStaffId,
        staffName: _selectedStaffName,
        surveyType: _surveyType,
        surveyDate: _surveyDate,
        overallSatisfaction: _overallSatisfaction,
        engagementScore: _engagementScore,
        motivationScore: _motivationScore,
        workEnvironmentScore: _workEnvironmentScore,
        teamCollaborationScore: _teamCollaborationScore,
        resourcesAvailableScore: _resourcesAvailableScore,
        managementSupportScore: _managementSupportScore,
        leadershipTrustScore: _leadershipTrustScore,
        communicationScore: _communicationScore,
        feedbackEffectivenessScore: _feedbackEffectivenessScore,
        careerDevelopmentScore: _careerDevelopmentScore,
        trainingOpportunitiesScore: _trainingOpportunitiesScore,
        recognitionScore: _recognitionScore,
        workLifeBalanceScore: _workLifeBalanceScore,
        flexibilityScore: _flexibilityScore,
        whatDoYouEnjoy: _enjoyController.text.isNotEmpty ? _enjoyController.text : null,
        whatCouldImprove: _improveController.text.isNotEmpty ? _improveController.text : null,
        suggestionsForImprovement: _suggestionsController.text.isNotEmpty ? _suggestionsController.text : null,
        additionalComments: _commentsController.text.isNotEmpty ? _commentsController.text : null,
        feelValued: _feelValued,
        feelHeard: _feelHeard,
        feelSupported: _feelSupported,
        feelDeveloped: _feelDeveloped,
        feelRecognized: _feelRecognized,
        isAnonymous: _isAnonymous,
        createdAt: widget.survey?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.survey != null) {
        await _service.updateSurvey(widget.survey!.id, survey);
      } else {
        await _service.createSurvey(survey);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.survey != null ? 'Survey updated' : 'Survey created'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.survey != null ? 'Edit Survey' : 'New Satisfaction Survey'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.survey != null ? 'Update' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Staff Selection
            EmployeeDropdown(
              selectedEmployeeId: _selectedStaffId,
              onChanged: (v) {
                setState(() {
                  _selectedStaffId = v;
                  _selectedStaffName = v;
                });
              },
              labelText: 'Staff Member *',
              required: true,
            ),
            const SizedBox(height: 16),

            // Survey Type
            StaticDropdown(
              selectedValue: _surveyType,
              onChanged: (v) => setState(() => _surveyType = v ?? 'standard'),
              labelText: 'Survey Type *',
              options: _surveyTypes,
              required: true,
            ),
            const SizedBox(height: 16),

            // Survey Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _surveyDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _surveyDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Survey Date *',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_surveyDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Anonymous Toggle
            SwitchListTile(
              title: const Text('Anonymous Response'),
              subtitle: const Text('Hide staff name from reports'),
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
            ),
            const SizedBox(height: 16),

            // Satisfaction Scores
            const Text('Satisfaction & Engagement Scores (1-10)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildScoreSlider('Overall Satisfaction', _overallSatisfaction, (v) => setState(() => _overallSatisfaction = v)),
            _buildScoreSlider('Engagement Score', _engagementScore, (v) => setState(() => _engagementScore = v)),
            _buildScoreSlider('Motivation Score', _motivationScore, (v) => setState(() => _motivationScore = v)),
            const SizedBox(height: 16),

            // Work Environment
            const Text('Work Environment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildScoreSlider('Work Environment', _workEnvironmentScore, (v) => setState(() => _workEnvironmentScore = v)),
            _buildScoreSlider('Team Collaboration', _teamCollaborationScore, (v) => setState(() => _teamCollaborationScore = v)),
            _buildScoreSlider('Resources Available', _resourcesAvailableScore, (v) => setState(() => _resourcesAvailableScore = v)),
            const SizedBox(height: 16),

            // Management & Leadership
            const Text('Management & Leadership', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildScoreSlider('Management Support', _managementSupportScore, (v) => setState(() => _managementSupportScore = v)),
            _buildScoreSlider('Leadership Trust', _leadershipTrustScore, (v) => setState(() => _leadershipTrustScore = v)),
            _buildScoreSlider('Communication', _communicationScore, (v) => setState(() => _communicationScore = v)),
            _buildScoreSlider('Feedback Effectiveness', _feedbackEffectivenessScore, (v) => setState(() => _feedbackEffectivenessScore = v)),
            const SizedBox(height: 16),

            // Career Development
            const Text('Career Development', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildScoreSlider('Career Development', _careerDevelopmentScore, (v) => setState(() => _careerDevelopmentScore = v)),
            _buildScoreSlider('Training Opportunities', _trainingOpportunitiesScore, (v) => setState(() => _trainingOpportunitiesScore = v)),
            _buildScoreSlider('Recognition', _recognitionScore, (v) => setState(() => _recognitionScore = v)),
            const SizedBox(height: 16),

            // Work-Life Balance
            const Text('Work-Life Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildScoreSlider('Work-Life Balance', _workLifeBalanceScore, (v) => setState(() => _workLifeBalanceScore = v)),
            _buildScoreSlider('Flexibility', _flexibilityScore, (v) => setState(() => _flexibilityScore = v)),
            const SizedBox(height: 16),

            // Engagement Factors
            const Text('Engagement Factors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CheckboxListTile(title: const Text('I feel valued'), value: _feelValued ?? false, onChanged: (v) => setState(() => _feelValued = v)),
            CheckboxListTile(title: const Text('I feel heard'), value: _feelHeard ?? false, onChanged: (v) => setState(() => _feelHeard = v)),
            CheckboxListTile(title: const Text('I feel supported'), value: _feelSupported ?? false, onChanged: (v) => setState(() => _feelSupported = v)),
            CheckboxListTile(title: const Text('I feel developed'), value: _feelDeveloped ?? false, onChanged: (v) => setState(() => _feelDeveloped = v)),
            CheckboxListTile(title: const Text('I feel recognized'), value: _feelRecognized ?? false, onChanged: (v) => setState(() => _feelRecognized = v)),
            const SizedBox(height: 16),

            // Open Questions
            const Text('Open Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _enjoyController,
              decoration: const InputDecoration(
                labelText: 'What do you enjoy most about working here?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _improveController,
              decoration: const InputDecoration(
                labelText: 'What could be improved?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _suggestionsController,
              decoration: const InputDecoration(
                labelText: 'Suggestions for improvement',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Additional comments',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.survey != null ? 'Update Survey' : 'Submit Survey', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSlider(String label, int? value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value ?? 0}/10'),
          Slider(
            value: (value ?? 0).toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '${value ?? 0}',
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ],
      ),
    );
  }
}