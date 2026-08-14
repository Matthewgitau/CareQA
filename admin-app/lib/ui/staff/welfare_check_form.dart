import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/welfare_check.dart';
import '../../services/welfare_service.dart';
import '../../widgets/reusable_form_widgets.dart';

class WelfareCheckFormScreen extends StatefulWidget {
  final WelfareCheck? check;

  const WelfareCheckFormScreen({super.key, this.check});

  @override
  State<WelfareCheckFormScreen> createState() => _WelfareCheckFormScreenState();
}

class _WelfareCheckFormScreenState extends State<WelfareCheckFormScreen> {
  final _service = WelfareService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _physicalHealthController = TextEditingController();
  final _recentIllnessController = TextEditingController();
  final _medicationNotesController = TextEditingController();
  final _supportProvidedController = TextEditingController();
  final _actionPlanController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedStaffId;
  String? _selectedStaffName;
  String _checkType = 'general_welfare';
  DateTime _checkDate = DateTime.now();
  int? _wellbeingScore;
  int? _stressScore;
  int? _jobSatisfactionScore;
  int? _workloadScore;
  String? _anxietyLevel;
  String? _depressionSymptoms;
  String? _burnoutSymptoms;
  String? _sleepingIssues;
  bool? _workloadManageable;
  bool? _supportAvailable;
  String? _teamRelationships;
  String? _managerSupport;
  String? _workLifeBalance;
  bool _caringResponsibilities = false;
  String? _caringResponsibilitiesNotes;
  List<String> _identifiedStressors = [];
  String? _stressLevelTrend;
  bool _referralMade = false;
  String? _referralType;
  DateTime? _referralDate;
  bool _followUpRequired = false;
  DateTime? _followUpDate;
  bool _isSaving = false;

  final List<String> _checkTypes = [
    'annual_wellbeing',
    'return_to_work',
    'stress_risk_assessment',
    'health_questionnaire',
    'ergonomic_assessment',
    'mental_health_check',
    'general_welfare',
    'exit_interview',
    'other',
  ];

  final List<String> _stressLevels = ['none', 'mild', 'moderate', 'severe'];
  final List<String> _burnoutLevels = ['none', 'early_warning', 'developing', 'full_burnout'];
  final List<String> _sleepLevels = ['none', 'occasional', 'regular', 'chronic'];
  final List<String> _relationshipLevels = ['excellent', 'good', 'fair', 'poor', 'toxic'];
  final List<String> _balanceLevels = ['excellent', 'good', 'fair', 'poor', 'very_poor'];
  final List<String> _trendLevels = ['improving', 'stable', 'worsening', 'fluctuating'];
  final List<String> _referralTypes = [
    'occupational_health',
    'counselling',
    'mental_health_support',
    'physiotherapy',
    'stress_management',
    'employee_assistance_programme',
    'gp',
    'other',
  ];
  final List<String> _stressorOptions = [
    'Workload',
    'Deadlines',
    'Staff shortages',
    'Difficult service users',
    'Manager support',
    'Team conflict',
    'Work-life balance',
    'Caring responsibilities',
    'Financial worries',
    'Health issues',
    'Training/development',
    'Career progression',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.check != null) {
      _populateForm(widget.check!);
    }
  }

  void _populateForm(WelfareCheck check) {
    _selectedStaffId = check.staffId;
    _selectedStaffName = check.staffName;
    _checkType = check.checkType ?? 'general_welfare';
    _checkDate = check.checkDate;
    _wellbeingScore = check.wellbeingScore;
    _stressScore = check.stressScore;
    _jobSatisfactionScore = check.jobSatisfactionScore;
    _workloadScore = check.workloadScore;
    _physicalHealthController.text = check.physicalHealthIssues ?? '';
    _recentIllnessController.text = check.recentIllness ?? '';
    _anxietyLevel = check.anxietyLevel;
    _depressionSymptoms = check.depressionSymptoms;
    _burnoutSymptoms = check.burnoutSymptoms;
    _sleepingIssues = check.sleepingIssues;
    _workloadManageable = check.workloadManageable;
    _supportAvailable = check.supportAvailable;
    _teamRelationships = check.teamRelationships;
    _managerSupport = check.managerSupport;
    _workLifeBalance = check.workLifeBalance;
    _caringResponsibilities = check.caringResponsibilities;
    _caringResponsibilitiesNotes = check.caringResponsibilitiesNotes;
    _identifiedStressors = check.identifiedStressors;
    _stressLevelTrend = check.stressLevelTrend;
    _supportProvidedController.text = check.supportProvided ?? '';
    _referralMade = check.referralMade;
    _referralType = check.referralType;
    _referralDate = check.referralDate;
    _followUpRequired = check.followUpRequired;
    _followUpDate = check.followUpDate;
    _actionPlanController.text = check.actionPlan ?? '';
    _notesController.text = check.notes ?? '';
  }

  @override
  void dispose() {
    _physicalHealthController.dispose();
    _recentIllnessController.dispose();
    _medicationNotesController.dispose();
    _supportProvidedController.dispose();
    _actionPlanController.dispose();
    _notesController.dispose();
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
      final check = WelfareCheck(
        id: widget.check?.id ?? '',
        staffId: _selectedStaffId,
        staffName: _selectedStaffName ?? '',
        checkType: _checkType,
        checkDate: _checkDate,
        checkTime: '${DateTime.now().hour}:${DateTime.now().minute}',
        wellbeingScore: _wellbeingScore,
        stressScore: _stressScore,
        jobSatisfactionScore: _jobSatisfactionScore,
        workloadScore: _workloadScore,
        physicalHealthIssues: _physicalHealthController.text.isNotEmpty ? _physicalHealthController.text : null,
        recentIllness: _recentIllnessController.text.isNotEmpty ? _recentIllnessController.text : null,
        anxietyLevel: _anxietyLevel,
        depressionSymptoms: _depressionSymptoms,
        burnoutSymptoms: _burnoutSymptoms,
        sleepingIssues: _sleepingIssues,
        workloadManageable: _workloadManageable,
        supportAvailable: _supportAvailable,
        teamRelationships: _teamRelationships,
        managerSupport: _managerSupport,
        workLifeBalance: _workLifeBalance,
        caringResponsibilities: _caringResponsibilities,
        caringResponsibilitiesNotes: _caringResponsibilities ? _caringResponsibilitiesNotes : null,
        identifiedStressors: _identifiedStressors,
        stressLevelTrend: _stressLevelTrend,
        supportProvided: _supportProvidedController.text.isNotEmpty ? _supportProvidedController.text : null,
        referralMade: _referralMade,
        referralType: _referralType,
        referralDate: _referralDate,
        followUpRequired: _followUpRequired,
        followUpDate: _followUpDate,
        actionPlan: _actionPlanController.text.isNotEmpty ? _actionPlanController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: widget.check?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.check != null) {
        await _service.updateWelfareCheck(widget.check!.id, check);
      } else {
        await _service.createWelfareCheck(check);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.check != null ? 'Welfare check updated' : 'Welfare check created'), backgroundColor: Colors.green),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _checkDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.check != null ? 'Edit Welfare Check' : 'New Welfare Check'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.check != null ? 'Update' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

            // Check Type
            StaticDropdown(
              selectedValue: _checkType,
              onChanged: (v) => setState(() => _checkType = v ?? 'general_welfare'),
              labelText: 'Check Type *',
              options: _checkTypes,
              required: true,
            ),
            const SizedBox(height: 16),

            // Check Date
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Check Date *',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_checkDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Wellbeing Scores
            const Text('Wellbeing Scores (1-10)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildScoreSlider('Wellbeing Score', _wellbeingScore, (v) => setState(() => _wellbeingScore = v)),
            _buildScoreSlider('Stress Score', _stressScore, (v) => setState(() => _stressScore = v)),
            _buildScoreSlider('Job Satisfaction', _jobSatisfactionScore, (v) => setState(() => _jobSatisfactionScore = v)),
            _buildScoreSlider('Workload Score', _workloadScore, (v) => setState(() => _workloadScore = v)),
            const SizedBox(height: 16),

            // Physical Health
            TextFormField(
              controller: _physicalHealthController,
              decoration: const InputDecoration(
                labelText: 'Physical Health Issues',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Mental Health
            const Text('Mental Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StaticDropdown(
              selectedValue: _anxietyLevel,
              onChanged: (v) => setState(() => _anxietyLevel = v),
              labelText: 'Anxiety Level',
              options: _stressLevels,
            ),
            const SizedBox(height: 12),
            StaticDropdown(
              selectedValue: _depressionSymptoms,
              onChanged: (v) => setState(() => _depressionSymptoms = v),
              labelText: 'Depression Symptoms',
              options: _stressLevels,
            ),
            const SizedBox(height: 12),
            StaticDropdown(
              selectedValue: _burnoutSymptoms,
              onChanged: (v) => setState(() => _burnoutSymptoms = v),
              labelText: 'Burnout Symptoms',
              options: _burnoutLevels,
            ),
            const SizedBox(height: 12),
            StaticDropdown(
              selectedValue: _sleepingIssues,
              onChanged: (v) => setState(() => _sleepingIssues = v),
              labelText: 'Sleeping Issues',
              options: _sleepLevels,
            ),
            const SizedBox(height: 16),

            // Work Environment
            const Text('Work Environment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Workload Manageable'),
              value: _workloadManageable ?? false,
              onChanged: (v) => setState(() => _workloadManageable = v),
            ),
            SwitchListTile(
              title: const Text('Support Available'),
              value: _supportAvailable ?? false,
              onChanged: (v) => setState(() => _supportAvailable = v),
            ),
            StaticDropdown(
              selectedValue: _teamRelationships,
              onChanged: (v) => setState(() => _teamRelationships = v),
              labelText: 'Team Relationships',
              options: _relationshipLevels,
            ),
            const SizedBox(height: 12),
            StaticDropdown(
              selectedValue: _managerSupport,
              onChanged: (v) => setState(() => _managerSupport = v),
              labelText: 'Manager Support',
              options: _relationshipLevels,
            ),
            const SizedBox(height: 12),
            StaticDropdown(
              selectedValue: _workLifeBalance,
              onChanged: (v) => setState(() => _workLifeBalance = v),
              labelText: 'Work-Life Balance',
              options: _balanceLevels,
            ),
            const SizedBox(height: 16),

            // Home Life
            SwitchListTile(
              title: const Text('Caring Responsibilities'),
              value: _caringResponsibilities,
              onChanged: (v) => setState(() => _caringResponsibilities = v),
            ),
            if (_caringResponsibilities)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Caring Responsibilities Details',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _caringResponsibilitiesNotes = v,
              ),
            const SizedBox(height: 16),

            // Support Provided
            TextFormField(
              controller: _supportProvidedController,
              decoration: const InputDecoration(
                labelText: 'Support Provided',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Action Plan
            TextFormField(
              controller: _actionPlanController,
              decoration: const InputDecoration(
                labelText: 'Action Plan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
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
                    : Text(widget.check != null ? 'Update Welfare Check' : 'Save Welfare Check', style: const TextStyle(fontWeight: FontWeight.bold)),
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