import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/falls_risk_assessment.dart';
import 'package:admin_app/services/falls_risk_service.dart';

class FallsRiskForm extends StatefulWidget {
  final String? assessmentId;
  final String? serviceUserId;
  const FallsRiskForm({super.key, this.assessmentId, this.serviceUserId});

  @override
  State<FallsRiskForm> createState() => _FallsRiskFormState();
}

class _FallsRiskFormState extends State<FallsRiskForm> {
  final _service = FallsRiskService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _serviceUserNameController = TextEditingController();
  final _assessorNameController = TextEditingController();
  final _actionController = TextEditingController();
  final _verifiedByController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _assessmentDate;
  DateTime? _verificationDate;

  AgeScoreOption? _ageScoreOption;
  FallHistoryScoreOption? _fallHistoryOption;
  EliminationScoreOption? _eliminationOption;
  MedicationScoreOption? _medicationOption;
  EquipmentScoreOption? _equipmentOption;
  MobilityScoreOption? _mobilityOption;
  CognitionScoreOption? _cognitionOption;

  List<FallsActionPlan> _actionPlans = [];
  bool _loading = false;
  bool _isEditing = false;

  int get _totalScore {
    return (_ageScoreOption?.score ?? 0) +
           (_fallHistoryOption?.score ?? 0) +
           (_eliminationOption?.score ?? 0) +
           (_medicationOption?.score ?? 0) +
           (_equipmentOption?.score ?? 0) +
           (_mobilityOption?.score ?? 0) +
           (_cognitionOption?.score ?? 0);
  }

  String get _riskLevel {
    final score = _totalScore;
    if (score >= 6 && score <= 8) return 'Low';
    if (score >= 9 && score <= 12) return 'Moderate';
    if (score >= 13) return 'High';
    return 'Not Calculated';
  }

  Color get _riskColor {
    switch (_riskLevel) {
      case 'Low': return Colors.green;
      case 'Moderate': return Colors.orange;
      case 'High': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.assessmentId != null) {
      _loadAssessment();
    }
  }

  @override
  void dispose() {
    _serviceUserNameController.dispose();
    _assessorNameController.dispose();
    _actionController.dispose();
    _verifiedByController.dispose();
    super.dispose();
  }

  Future<void> _loadAssessment() async {
    setState(() => _loading = true);
    try {
      final assessment = await _service.getAssessmentWithActionPlans(widget.assessmentId!);
      setState(() {
        _serviceUserNameController.text = assessment.serviceUserName;
        _assessorNameController.text = assessment.assessorName;
        _dateOfBirth = assessment.dateOfBirth;
        _assessmentDate = assessment.assessmentDate;

        // Set score options based on loaded values
        _ageScoreOption = _service.getAgeScoreOptions().firstWhere(
          (o) => o.score == assessment.ageScore,
          orElse: () => _service.getAgeScoreOptions().first,
        );
        _fallHistoryOption = _service.getFallHistoryScoreOptions().firstWhere(
          (o) => o.score == assessment.fallHistoryScore,
          orElse: () => _service.getFallHistoryScoreOptions().first,
        );
        _eliminationOption = _service.getEliminationScoreOptions().firstWhere(
          (o) => o.score == assessment.eliminationScore,
          orElse: () => _service.getEliminationScoreOptions().first,
        );
        _medicationOption = _service.getMedicationScoreOptions().firstWhere(
          (o) => o.score == assessment.medicationScore,
          orElse: () => _service.getMedicationScoreOptions().first,
        );
        _equipmentOption = _service.getEquipmentScoreOptions().firstWhere(
          (o) => o.score == assessment.equipmentScore,
          orElse: () => _service.getEquipmentScoreOptions().first,
        );
        _mobilityOption = _service.getMobilityScoreOptions().firstWhere(
          (o) => o.score == assessment.mobilityScore,
          orElse: () => _service.getMobilityScoreOptions().first,
        );
        _cognitionOption = _service.getCognitionScoreOptions().firstWhere(
          (o) => o.score == assessment.cognitionScore,
          orElse: () => _service.getCognitionScoreOptions().first,
        );

        _actionPlans = assessment.actionPlans;
        _isEditing = true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assessment: $e')),
        );
        Navigator.pop(context);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectDate(DateTime? currentDate, Function(DateTime) onDateSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_serviceUserNameController.text.isEmpty || _assessorNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    if (_dateOfBirth == null || _assessmentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isEditing) {
        // Update existing assessment
        await _service.updateAssessmentScores(
          assessmentId: widget.assessmentId!,
          ageScore: _ageScoreOption?.score,
          fallHistoryScore: _fallHistoryOption?.score,
          eliminationScore: _eliminationOption?.score,
          medicationScore: _medicationOption?.score,
          equipmentScore: _equipmentOption?.score,
          mobilityScore: _mobilityOption?.score,
          cognitionScore: _cognitionOption?.score,
        );
      } else {
        // Create new assessment
        final assessmentId = await _service.createAssessment(
          serviceUserId: widget.serviceUserId ?? '',
          serviceUserName: _serviceUserNameController.text,
          assessorName: _assessorNameController.text,
          dateOfBirth: _dateOfBirth!,
          assessmentDate: _assessmentDate!,
        );

        // Update scores
        await _service.updateAssessmentScores(
          assessmentId: assessmentId,
          ageScore: _ageScoreOption?.score,
          fallHistoryScore: _fallHistoryOption?.score,
          eliminationScore: _eliminationOption?.score,
          medicationScore: _medicationOption?.score,
          equipmentScore: _equipmentOption?.score,
          mobilityScore: _mobilityOption?.score,
          cognitionScore: _cognitionOption?.score,
        );

        // Add action plans
        for (final plan in _actionPlans) {
          await _service.addActionPlan(
            assessmentId: assessmentId,
            action: plan.action,
            outcome: plan.outcome,
          );
        }
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

  void _addActionPlan() {
    if (_actionController.text.trim().isNotEmpty) {
      setState(() {
        _actionPlans.add(FallsActionPlan(
          id: '',
          action: _actionController.text.trim(),
          createdAt: DateTime.now(),
        ));
        _actionController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Falls Risk Assessment' : 'New Falls Risk Assessment'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Service User Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service User Information',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _serviceUserNameController,
                            decoration: const InputDecoration(
                              labelText: 'Service User Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _assessorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Assessor Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _selectDate(_dateOfBirth, (d) => setState(() => _dateOfBirth = d)),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _dateOfBirth != null
                                    ? _dateOfBirth!.toString().split(' ').first
                                    : 'Select date',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _selectDate(_assessmentDate, (d) => setState(() => _assessmentDate = d)),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Assessment Date *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _assessmentDate != null
                                    ? _assessmentDate!.toString().split(' ').first
                                    : 'Select date',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scoring Categories Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Risk Assessment Scoring',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),

                          // Age Score
                          DropdownButtonFormField<AgeScoreOption>(
                            value: _ageScoreOption,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              border: OutlineInputBorder(),
                            ),
                            items: _service.getAgeScoreOptions()
                                .map((o) => DropdownMenuItem(value: o, child: Text(o.toString())))
                                .toList(),
                            onChanged: (v) => setState(() => _ageScoreOption = v),
                          ),
                          const SizedBox(height: 12),

                          // Fall History Score
                          DropdownButtonFormField<FallHistoryScoreOption>(
                            value: _fallHistoryOption,
                            decoration: const InputDecoration(
                              labelText: 'Fall History',
                              border: OutlineInputBorder(),
                            ),
                            items: _service.getFallHistoryScoreOptions()
                                .map((o) => DropdownMenuItem(value: o, child: Text(o.toString())))
                                .toList(),
                            onChanged: (v) => setState(() => _fallHistoryOption = v),
                          ),
                          const SizedBox(height: 12),

                          // Elimination Score
                          DropdownButtonFormField<EliminationScoreOption>(
                            value: _eliminationOption,
                            decoration: const InputDecoration(
                              labelText: 'Elimination',
                              border: OutlineInputBorder(),
                            ),
                            items: _service.getEliminationScoreOptions()
                                .map((o) => DropdownMenuItem(value: o, child: Text(o.toString())))
                                .toList(),
                            onChanged: (v) => setState(() => _eliminationOption = v),
                          ),
                          const SizedBox(height: 12),

                          // Medication Score
                          DropdownButtonFormField<MedicationScoreOption>(
                            value: _medicationOption,
                            decoration: const InputDecoration(
                              labelText: 'Medications',
                              border: OutlineInputBorder(),
                            ),
                            items: _service.getMedicationScoreOptions()
                                .map((o) => DropdownMenuItem(value: o, child: Text(o.toString())))
                                .toList(),
                            onChanged: (v) => setState(() => _medicationOption = v),
                          ),
                          const SizedBox(height: 12),

                          // Equipment Score
                          DropdownButtonFormField<EquipmentScoreOption>(
                            value: _equipmentOption,
                            decoration: const InputDecoration(
                              labelText: 'Patient Care Equipment',
                              border: OutlineInputBorder(),
                            ),
                            items: _service.getEquipmentScoreOptions()
                                .map((o) => DropdownMenuItem(value: o, child: Text(o.toString())))
                                .toList(),
                            onChanged: (v) => setState(() => _equipmentOption = v),
                          ),
                          const SizedBox(height: 12),

                          // Mobility Score
                          DropdownButtonFormField<MobilityScoreOption>(
                            value: _mobilityOption,
                            decoration: const InputDecoration(
                              labelText: 'Mobility',
                              border: OutlineInputBorder(),
                            ),
                            items: _service.getMobilityScoreOptions()
                                .map((o) => DropdownMenuItem(value: o, child: Text(o.toString())))
                                .toList(),
                            onChanged: (v) => setState(() => _mobilityOption = v),
                          ),
                          const SizedBox(height: 12),

                          // Cognition Score
                          DropdownButtonFormField<CognitionScoreOption>(
                            value: _cognitionOption,
                            decoration: const InputDecoration(
                              labelText: 'Cognition',
                              border: OutlineInputBorder(),
                            ),
                            items: _service.getCognitionScoreOptions()
                                .map((o) => DropdownMenuItem(value: o, child: Text(o.toString())))
                                .toList(),
                            onChanged: (v) => setState(() => _cognitionOption = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total Score Card
                  Card(
                    color: _riskColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Total Score', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '$_totalScore',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _riskColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                _riskLevel,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _riskColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Plans Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Action Plan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _actionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Add action item',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addActionPlan,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._actionPlans.asMap().entries.map((entry) {
                            final index = entry.key;
                            final plan = entry.value;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(plan.action),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _actionPlans.removeAt(index)),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}