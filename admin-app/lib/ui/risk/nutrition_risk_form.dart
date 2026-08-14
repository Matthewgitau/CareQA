import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/nutrition_assessment.dart';
import 'package:admin_app/services/nutrition_service.dart';

class NutritionRiskForm extends StatefulWidget {
  final NutritionAssessment? assessment;
  final String? serviceUserId;

  const NutritionRiskForm({super.key, this.assessment, this.serviceUserId});

  @override
  State<NutritionRiskForm> createState() => _NutritionRiskFormState();
}

class _NutritionRiskFormState extends State<NutritionRiskForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = NutritionService(Supabase.instance.client);

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  // MUST Core fields
  DateTime _assessmentDate = DateTime.now();
  String _assessorName = '';
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _prevWeightController = TextEditingController();
  bool _hasWeightLoss = false;
  double _weightLossKg = 0;
  int _weightLossPeriodMonths = 3;
  bool _acuteDiseaseNoIntake = false;

  // MUST calculated values
  double? _calculatedBmi;
  int _calculatedBmiScore = 0;
  double? _calculatedWeightLossPercent;
  int _calculatedWeightLossScore = 0;
  int _calculatedAcuteDiseaseScore = 0;
  int _calculatedMustTotal = 0;
  String _calculatedRiskCategory = 'low';

  // Additional assessment
  String _appetite = 'good';
  List<String> _selectedEatingDifficulties = [];
  final _dietaryRequirementsController = TextEditingController();
  final _foodAllergiesController = TextEditingController();
  bool _swallowingDifficulties = false;

  // Food monitoring (auto-populated)
  bool _requiresFoodMonitoring = false;
  String _monitoringFrequency = 'weekly';
  DateTime? _nextMonitoringDate;

  // Care plan
  bool _referredToDietitian = false;
  bool _gpReferral = false;
  bool _supplementationRequired = false;
  final _supplementsDetailsController = TextEditingController();
  final _actionPlanController = TextEditingController();

  // Review
  DateTime? _reviewDate;
  String _reassessmentFrequency = '1 month';

  // Sign-off
  bool _signatureConfirmed = false;
  final _signatureController = TextEditingController();

  bool _isLoading = false;

  final List<String> _appetiteOptions = ['good', 'reduced', 'poor', 'none'];
  final List<String> _eatingDifficultyOptions = [
    'swallowing', 'chewing', 'nausea', 'vomiting', 'diarrhoea', 'constipation', 'pain', 'fatigue'
  ];
  final List<String> _monitoringFrequencyOptions = ['daily', 'weekly', 'fortnightly', 'monthly'];
  final List<String> _reassessmentFrequencyOptions = ['1 week', '2 weeks', '1 month', '3 months'];

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    _initialize();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _prevWeightController.dispose();
    _dietaryRequirementsController.dispose();
    _foodAllergiesController.dispose();
    _supplementsDetailsController.dispose();
    _actionPlanController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  void _initialize() {
    if (widget.assessment != null) {
      final a = widget.assessment!;
      _selectedServiceUserId = a.serviceUserId;
      _assessmentDate = a.assessmentDate;
      _assessorName = a.assessorName;
      _weightController.text = a.currentWeightKg.toString();
      _heightController.text = a.heightCm.toString();
      if (a.weight3_6MonthsAgoKg != null) {
        _hasWeightLoss = true;
        _prevWeightController.text = a.weight3_6MonthsAgoKg.toString();
      }
      _acuteDiseaseNoIntake = a.acuteDiseaseEffectScore == 2;
      _calculatedBmi = a.bmi;
      _calculatedBmiScore = a.bmiScore;
      _calculatedWeightLossPercent = a.weightLossPercentage;
      _calculatedWeightLossScore = a.weightLossScore;
      _calculatedAcuteDiseaseScore = a.acuteDiseaseEffectScore;
      _calculatedMustTotal = a.mustTotalScore;
      _calculatedRiskCategory = a.riskCategory;
      _appetite = a.appetite ?? 'good';
      _selectedEatingDifficulties = a.eatingDifficulties ?? [];
      _dietaryRequirementsController.text = a.dietaryRequirements ?? '';
      _foodAllergiesController.text = a.foodPreferencesAllergies ?? '';
      _swallowingDifficulties = a.swallowingDifficulties;
      _requiresFoodMonitoring = a.requiresFoodMonitoring;
      _monitoringFrequency = a.monitoringFrequency ?? 'weekly';
      _nextMonitoringDate = a.nextMonitoringDate;
      _referredToDietitian = a.referredToDietitian;
      _gpReferral = a.gpReferral;
      _supplementationRequired = a.supplementationRequired;
      _supplementsDetailsController.text = a.supplementsDetails ?? '';
      _actionPlanController.text = a.actionPlan ?? '';
      _reviewDate = a.reviewDate;
      _reassessmentFrequency = a.reassessmentFrequency ?? '1 month';
    } else {
      _assessorName = Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Current User';
      _recalculateMUST();
    }
  }

  void _recalculateMUST() {
    // BMI calculation
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (weight != null && height != null && height > 0) {
      _calculatedBmi = weight / ((height / 100) * (height / 100));
      if (_calculatedBmi! > 20) {
        _calculatedBmiScore = 0;
      } else if (_calculatedBmi! >= 18.5) {
        _calculatedBmiScore = 1;
      } else {
        _calculatedBmiScore = 2;
      }
    } else {
      _calculatedBmi = null;
      _calculatedBmiScore = 0;
    }

    // Weight loss calculation
    final prevWeight = double.tryParse(_prevWeightController.text);
    if (_hasWeightLoss && weight != null && prevWeight != null && prevWeight > 0) {
      _weightLossKg = prevWeight - weight;
      _calculatedWeightLossPercent = ((prevWeight - weight) / prevWeight) * 100;
      if (_calculatedWeightLossPercent! < 5) {
        _calculatedWeightLossScore = 0;
      } else if (_calculatedWeightLossPercent! <= 10) {
        _calculatedWeightLossScore = 1;
      } else {
        _calculatedWeightLossScore = 2;
      }
    } else {
      _weightLossKg = 0;
      _calculatedWeightLossPercent = null;
      _calculatedWeightLossScore = 0;
    }

    // Acute disease score
    _calculatedAcuteDiseaseScore = _acuteDiseaseNoIntake ? 2 : 0;

    // Total MUST score
    _calculatedMustTotal = _calculatedBmiScore + _calculatedWeightLossScore + _calculatedAcuteDiseaseScore;

    // Risk category
    if (_calculatedMustTotal == 0) {
      _calculatedRiskCategory = 'low';
      _requiresFoodMonitoring = false;
      _monitoringFrequency = 'monthly';
      _reassessmentFrequency = '3 months';
      _reviewDate = DateTime.now().add(const Duration(days: 90));
    } else if (_calculatedMustTotal == 1) {
      _calculatedRiskCategory = 'medium';
      _requiresFoodMonitoring = true;
      _monitoringFrequency = 'weekly';
      _nextMonitoringDate = DateTime.now().add(const Duration(days: 7));
      _reassessmentFrequency = '1 month';
      _reviewDate = DateTime.now().add(const Duration(days: 30));
    } else {
      _calculatedRiskCategory = 'high';
      _requiresFoodMonitoring = true;
      _monitoringFrequency = 'daily';
      _nextMonitoringDate = DateTime.now().add(const Duration(days: 1));
      _reassessmentFrequency = '1 week';
      _reviewDate = DateTime.now().add(const Duration(days: 7));
    }

    setState(() {});
  }

  Future<void> _selectDate({required DateTime initial, required DateTime first, required DateTime last, required ValueChanged<DateTime> onSelected}) async {
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: first, lastDate: last);
    if (picked != null) onSelected(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service user')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final weight = double.tryParse(_weightController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0;
      final prevWeight = _hasWeightLoss ? double.tryParse(_prevWeightController.text) : null;

      final serviceUserName = _serviceUsers
          .firstWhere((u) => u['id'] == _selectedServiceUserId)['name'] as String;

      final assessment = NutritionAssessment(
        id: widget.assessment?.id,
        serviceUserId: _selectedServiceUserId,
        serviceUserName: serviceUserName,
        assessorId: Supabase.instance.client.auth.currentUser?.id,
        assessmentDate: _assessmentDate,
        heightCm: height,
        currentWeightKg: weight,
        weight3_6MonthsAgoKg: prevWeight,
        bmi: _calculatedBmi,
        bmiScore: _calculatedBmiScore,
        weightLossPercentage: _calculatedWeightLossPercent,
        weightLossScore: _calculatedWeightLossScore,
        acuteDiseaseEffectScore: _calculatedAcuteDiseaseScore,
        mustTotalScore: _calculatedMustTotal,
        riskCategory: _calculatedRiskCategory,
        appetite: _appetite,
        eatingDifficulties: _selectedEatingDifficulties.isNotEmpty ? _selectedEatingDifficulties : null,
        dietaryRequirements: _dietaryRequirementsController.text.isNotEmpty ? _dietaryRequirementsController.text : null,
        foodPreferencesAllergies: _foodAllergiesController.text.isNotEmpty ? _foodAllergiesController.text : null,
        swallowingDifficulties: _swallowingDifficulties,
        requiresFoodMonitoring: _requiresFoodMonitoring,
        monitoringFrequency: _requiresFoodMonitoring ? _monitoringFrequency : null,
        nextMonitoringDate: _requiresFoodMonitoring ? _nextMonitoringDate : null,
        referredToDietitian: _referredToDietitian,
        gpReferral: _gpReferral,
        supplementationRequired: _supplementationRequired,
        supplementsDetails: _supplementsDetailsController.text.isNotEmpty ? _supplementsDetailsController.text : null,
        actionPlan: _actionPlanController.text.isNotEmpty ? _actionPlanController.text : null,
        reviewDate: _reviewDate,
        nextWeightCheckDate: _reviewDate,
        reassessmentFrequency: _reassessmentFrequency,
        assessorName: _assessorName,
        assessorSignature: _signatureConfirmed ? _signatureController.text.trim() : null,
        status: _signatureConfirmed ? 'completed' : 'draft',
        createdAt: widget.assessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.assessment?.id != null) {
        await _service.updateAssessment(widget.assessment!.id!, assessment);
      } else {
        await _service.createAssessment(assessment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nutrition assessment saved successfully')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _riskColor(String category) {
    switch (category) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _riskIcon(String category) {
    switch (category) {
      case 'high': return Icons.warning;
      case 'medium': return Icons.info;
      case 'low': return Icons.check_circle;
      default: return Icons.help;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  Widget _buildCheckboxGroup(List<String> options, List<String> selected, Function(String, bool) onChanged) {
    return Column(
      children: options.map((opt) => CheckboxListTile(
        title: Text(opt.capitalize()),
        value: selected.contains(opt),
        onChanged: (v) { onChanged(opt, v ?? false); setState(() {}); },
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment != null ? 'Edit Nutrition Assessment' : 'Nutrition Risk Assessment (MUST)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service user selector
            if (_loadingUsers)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedServiceUserId,
                decoration: const InputDecoration(
                  labelText: 'Service User *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String))).toList(),
                onChanged: (v) => setState(() => _selectedServiceUserId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            const SizedBox(height: 16),

            // Assessment Date & Assessor
            InkWell(
              onTap: () => _selectDate(
                initial: _assessmentDate, first: DateTime(2020), last: DateTime(2030),
                onSelected: (d) => setState(() => _assessmentDate = d),
              ),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Assessment Date', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                child: Text('${_assessmentDate.day}/${_assessmentDate.month}/${_assessmentDate.year}'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Assessor Name', border: OutlineInputBorder()),
              initialValue: _assessorName,
              onChanged: (v) => _assessorName = v,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // BMI Section
            _buildSectionTitle('1. BMI Calculation'),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                SizedBox(width: 150, child: TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalculateMUST(),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                )),
                SizedBox(width: 150, child: TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalculateMUST(),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                )),
              ],
            ),
            if (_calculatedBmi != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('BMI: ${_calculatedBmi!.toStringAsFixed(1)} → Score: $_calculatedBmiScore',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _calculatedBmiScore == 2 ? Colors.red : _calculatedBmiScore == 1 ? Colors.orange : Colors.green)),
              ),
            const SizedBox(height: 16),

            // Weight Loss Section
            _buildSectionTitle('2. Unintentional Weight Loss'),
            SwitchListTile(
              title: const Text('Has there been unintentional weight loss?'),
              value: _hasWeightLoss,
              onChanged: (v) { setState(() => _hasWeightLoss = v); _recalculateMUST(); },
            ),
            if (_hasWeightLoss) ...[
              Wrap(
                spacing: 12, runSpacing: 12,
                children: [
                  SizedBox(width: 150, child: TextFormField(
                    controller: _prevWeightController,
                    decoration: const InputDecoration(labelText: 'Previous weight (kg)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recalculateMUST(),
                  )),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<int>(
                      value: _weightLossPeriodMonths,
                      decoration: const InputDecoration(labelText: 'Over period', border: OutlineInputBorder()),
                      items: [3, 6].map((m) => DropdownMenuItem(value: m, child: Text('$m months'))).toList(),
                      onChanged: (v) => setState(() => _weightLossPeriodMonths = v!),
                    ),
                  ),
                ],
              ),
              if (_calculatedWeightLossPercent != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Weight loss: ${_calculatedWeightLossPercent!.toStringAsFixed(1)}% → Score: $_calculatedWeightLossScore',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _calculatedWeightLossScore == 2 ? Colors.red : _calculatedWeightLossScore == 1 ? Colors.orange : Colors.green)),
                ),
            ],
            const SizedBox(height: 16),

            // Acute Disease Section
            _buildSectionTitle('3. Acute Disease Effect'),
            SwitchListTile(
              title: const Text('Acutely ill with no nutritional intake for >5 days?'),
              value: _acuteDiseaseNoIntake,
              onChanged: (v) { setState(() => _acuteDiseaseNoIntake = v); _recalculateMUST(); },
            ),
            const SizedBox(height: 16),

            // MUST Score Display
            Card(
              color: _riskColor(_calculatedRiskCategory).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(_riskIcon(_calculatedRiskCategory), color: _riskColor(_calculatedRiskCategory), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MUST Score', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Total Score: $_calculatedMustTotal',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _riskColor(_calculatedRiskCategory))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _riskColor(_calculatedRiskCategory).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_calculatedRiskCategory.toUpperCase()} RISK',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _riskColor(_calculatedRiskCategory)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildScoreChip('BMI', _calculatedBmiScore, 2),
                        const SizedBox(width: 8),
                        _buildScoreChip('Weight Loss', _calculatedWeightLossScore, 2),
                        const SizedBox(width: 8),
                        _buildScoreChip('Acute Disease', _calculatedAcuteDiseaseScore, 2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Assessment
            _buildSectionTitle('4. Additional Assessment'),
            DropdownButtonFormField<String>(
              value: _appetite,
              decoration: const InputDecoration(labelText: 'Appetite', border: OutlineInputBorder()),
              items: _appetiteOptions.map((o) => DropdownMenuItem(value: o, child: Text(o.capitalize()))).toList(),
              onChanged: (v) => setState(() => _appetite = v!),
            ),
            const SizedBox(height: 12),
            Text('Eating Difficulties:', style: const TextStyle(fontWeight: FontWeight.bold)),
            _buildCheckboxGroup(_eatingDifficultyOptions, _selectedEatingDifficulties, (key, value) {
              if (value) { _selectedEatingDifficulties.add(key); } else { _selectedEatingDifficulties.remove(key); }
            }),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dietaryRequirementsController,
              decoration: const InputDecoration(labelText: 'Dietary Requirements', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _foodAllergiesController,
              decoration: const InputDecoration(labelText: 'Food Preferences / Allergies', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Swallowing difficulties'),
              value: _swallowingDifficulties,
              onChanged: (v) => setState(() => _swallowingDifficulties = v),
            ),
            const SizedBox(height: 16),

            // Food Intake Monitoring
            _buildSectionTitle('5. Food Intake Monitoring'),
            SwitchListTile(
              title: const Text('Requires food monitoring?'),
              subtitle: Text(_calculatedRiskCategory == 'low' ? 'Auto-set: Low risk' : 'Auto-set: ${_calculatedRiskCategory.toUpperCase()} risk'),
              value: _requiresFoodMonitoring,
              onChanged: (v) => setState(() => _requiresFoodMonitoring = v),
            ),
            if (_requiresFoodMonitoring) ...[
              DropdownButtonFormField<String>(
                value: _monitoringFrequency,
                decoration: const InputDecoration(labelText: 'Monitoring Frequency', border: OutlineInputBorder()),
                items: _monitoringFrequencyOptions.map((o) => DropdownMenuItem(value: o, child: Text(o.capitalize()))).toList(),
                onChanged: (v) => setState(() => _monitoringFrequency = v!),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(
                  initial: _nextMonitoringDate ?? DateTime.now(), first: DateTime.now(), last: DateTime(2030),
                  onSelected: (d) => setState(() => _nextMonitoringDate = d),
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Next Monitoring Date', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                  child: Text(_nextMonitoringDate != null ? '${_nextMonitoringDate!.day}/${_nextMonitoringDate!.month}/${_nextMonitoringDate!.year}' : 'Select date'),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Care Plan
            _buildSectionTitle('6. Care Plan Actions'),
            CheckboxListTile(title: const Text('Refer to Dietitian'), value: _referredToDietitian, onChanged: (v) => setState(() => _referredToDietitian = v ?? false)),
            CheckboxListTile(title: const Text('Refer to GP'), value: _gpReferral, onChanged: (v) => setState(() => _gpReferral = v ?? false)),
            CheckboxListTile(title: const Text('Prescribe Nutritional Supplements'), value: _supplementationRequired, onChanged: (v) => setState(() => _supplementationRequired = v ?? false)),
            if (_supplementationRequired) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _supplementsDetailsController,
                decoration: const InputDecoration(labelText: 'Supplements Details', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _actionPlanController,
              decoration: const InputDecoration(labelText: 'Action Plan', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Review & Sign-off
            _buildSectionTitle('7. Review & Sign-off'),
            InkWell(
              onTap: () => _selectDate(
                initial: _reviewDate ?? DateTime.now(), first: DateTime.now(), last: DateTime(2030),
                onSelected: (d) => setState(() => _reviewDate = d),
              ),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Review Date', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                child: Text(_reviewDate != null ? '${_reviewDate!.day}/${_reviewDate!.month}/${_reviewDate!.year}' : 'Select date'),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _reassessmentFrequency,
              decoration: const InputDecoration(labelText: 'Reassessment Frequency', border: OutlineInputBorder()),
              items: _reassessmentFrequencyOptions.map((o) => DropdownMenuItem(value: o, child: Text(o.capitalize()))).toList(),
              onChanged: (v) => setState(() => _reassessmentFrequency = v!),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('I confirm this assessment is accurate'),
                    value: _signatureConfirmed,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _signatureConfirmed = v ?? false),
                  ),
                  if (_signatureConfirmed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _signatureController,
                        decoration: const InputDecoration(
                          labelText: 'Assessor Signature (type your name)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.assessment != null ? 'Update Assessment' : 'Save Assessment', style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(String label, int score, int maxScore) {
    final color = score == maxScore ? Colors.red : score > 0 ? Colors.orange : Colors.green;
    return Chip(
      label: Text('$label: $score', style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }
}

extension StringExt on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}