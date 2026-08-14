import 'package:flutter/material.dart';
import 'package:staff_app/models/nutrition_assessment.dart';
import 'package:staff_app/services/nutrition_service.dart';
import 'package:supabase/supabase.dart';

class NutritionRiskForm extends StatefulWidget {
  final NutritionAssessment? assessment;
  final String? serviceUserId;

  const NutritionRiskForm({
    Key? key,
    this.assessment,
    this.serviceUserId,
  }) : super(key: key);

  @override
  State<NutritionRiskForm> createState() => _NutritionRiskFormState();
}

class _NutritionRiskFormState extends State<NutritionRiskForm> {
  late final NutritionService _nutritionService;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  late DateTime _assessmentDate;
  late double _heightCm;
  late double _currentWeightKg;
  late double? _weight3_6MonthsAgoKg;
  late int _acuteDiseaseEffectScore;
  late String _assessorName;
  late String? _dietaryRequirements;
  late String? _foodPreferencesAllergies;
  late bool _swallowingDifficulties;
  late bool _referredToDietitian;
  late bool _supplementationRequired;
  late String? _actionPlan;
  late DateTime? _reviewDate;
  late DateTime? _nextWeightCheckDate;
  late String? _assessorSignature;

  // Calculated values
  double? _calculatedBmi;
  double? _calculatedWeightLossPercentage;
  int _calculatedBmiScore = 0;
  int _calculatedWeightLossScore = 0;
  int _calculatedMustTotalScore = 0;
  String _calculatedRiskCategory = 'low';

  // Available options
  final List<int> _acuteDiseaseOptions = [0, 2];

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(SupabaseClient('https://your-project.supabase.co', 'your-anon-key'));
    
    // Initialize with existing assessment or defaults
    if (widget.assessment != null) {
      final assessment = widget.assessment!;
      _assessmentDate = assessment.assessmentDate;
      _heightCm = assessment.heightCm;
      _currentWeightKg = assessment.currentWeightKg;
      _weight3_6MonthsAgoKg = assessment.weight3_6MonthsAgoKg;
      _acuteDiseaseEffectScore = assessment.acuteDiseaseEffectScore;
      _assessorName = assessment.assessorName;
      _dietaryRequirements = assessment.dietaryRequirements;
      _foodPreferencesAllergies = assessment.foodPreferencesAllergies;
      _swallowingDifficulties = assessment.swallowingDifficulties;
      _referredToDietitian = assessment.referredToDietitian;
      _supplementationRequired = assessment.supplementationRequired;
      _actionPlan = assessment.actionPlan;
      _reviewDate = assessment.reviewDate;
      _nextWeightCheckDate = assessment.nextWeightCheckDate;
      _assessorSignature = assessment.assessorSignature;
      
      // Calculate initial values
      _calculateAllScores();
    } else {
      _assessmentDate = DateTime.now();
      _heightCm = 0.0;
      _currentWeightKg = 0.0;
      _weight3_6MonthsAgoKg = null;
      _acuteDiseaseEffectScore = 0;
      _assessorName = '';
      _dietaryRequirements = null;
      _foodPreferencesAllergies = null;
      _swallowingDifficulties = false;
      _referredToDietitian = false;
      _supplementationRequired = false;
      _actionPlan = null;
      _reviewDate = null;
      _nextWeightCheckDate = null;
      _assessorSignature = null;
    }
  }

  void _calculateAllScores() {
    // Calculate BMI
    if (_heightCm > 0) {
      _calculatedBmi = _currentWeightKg / ((_heightCm / 100) * (_heightCm / 100));
    } else {
      _calculatedBmi = null;
    }

    // Calculate weight loss percentage
    if (_weight3_6MonthsAgoKg != null && _weight3_6MonthsAgoKg! > 0) {
      _calculatedWeightLossPercentage = ((_weight3_6MonthsAgoKg! - _currentWeightKg) / _weight3_6MonthsAgoKg!) * 100;
    } else {
      _calculatedWeightLossPercentage = null;
    }

    // Calculate BMI score
    if (_calculatedBmi != null) {
      if (_calculatedBmi! > 20) {
        _calculatedBmiScore = 0;
      } else if (_calculatedBmi! >= 18.5) {
        _calculatedBmiScore = 1;
      } else {
        _calculatedBmiScore = 2;
      }
    } else {
      _calculatedBmiScore = 0;
    }

    // Calculate weight loss score
    if (_calculatedWeightLossPercentage != null) {
      if (_calculatedWeightLossPercentage! < 5) {
        _calculatedWeightLossScore = 0;
      } else if (_calculatedWeightLossPercentage! <= 10) {
        _calculatedWeightLossScore = 1;
      } else {
        _calculatedWeightLossScore = 2;
      }
    } else {
      _calculatedWeightLossScore = 0;
    }

    // Calculate total MUST score
    _calculatedMustTotalScore = _calculatedBmiScore + _calculatedWeightLossScore + _acuteDiseaseEffectScore;

    // Determine risk category
    if (_calculatedMustTotalScore == 0) {
      _calculatedRiskCategory = 'low';
    } else if (_calculatedMustTotalScore == 1) {
      _calculatedRiskCategory = 'medium';
    } else {
      _calculatedRiskCategory = 'high';
    }

    setState(() {});
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    try {
      final assessment = NutritionAssessment(
        id: widget.assessment?.id,
        serviceUserId: widget.serviceUserId,
        assessmentDate: _assessmentDate,
        heightCm: _heightCm,
        currentWeightKg: _currentWeightKg,
        weight3_6MonthsAgoKg: _weight3_6MonthsAgoKg,
        bmiScore: _calculatedBmiScore,
        weightLossScore: _calculatedWeightLossScore,
        acuteDiseaseEffectScore: _acuteDiseaseEffectScore,
        mustTotalScore: _calculatedMustTotalScore,
        riskCategory: _calculatedRiskCategory,
        dietaryRequirements: _dietaryRequirements,
        foodPreferencesAllergies: _foodPreferencesAllergies,
        swallowingDifficulties: _swallowingDifficulties,
        referredToDietitian: _referredToDietitian,
        supplementationRequired: _supplementationRequired,
        actionPlan: _actionPlan,
        reviewDate: _reviewDate,
        nextWeightCheckDate: _nextWeightCheckDate,
        assessorName: _assessorName,
        assessorSignature: _assessorSignature,
        createdAt: widget.assessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.assessment != null) {
        await _nutritionService.updateAssessment(widget.assessment!.id!, assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nutrition assessment updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _nutritionService.createAssessment(assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nutrition assessment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isAssessmentDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isAssessmentDate ? _assessmentDate : (_reviewDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isAssessmentDate) {
          _assessmentDate = picked;
        } else {
          _reviewDate = picked;
        }
        _calculateAllScores();
      });
    }
  }

  Future<void> _selectWeightCheckDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextWeightCheckDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _nextWeightCheckDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment != null ? 'Edit Nutrition Assessment' : 'New Nutrition Assessment'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assessment Information
              const Text('Assessment Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Assessment Date
              Row(
                children: [
                  Expanded(
                    child: Text('Assessment Date: ${_assessmentDate.toIso8601String().split('T').first}'),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context, true),
                    child: const Text('Change Date'),
                  ),
                ],
              ),
              
              // Assessor Name
              TextFormField(
                initialValue: _assessorName,
                decoration: const InputDecoration(
                  labelText: 'Assessor Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter assessor name';
                  }
                  return null;
                },
                onSaved: (value) => _assessorName = value!,
              ),
              
              const SizedBox(height: 24),

              // Physical Measurements
              const Text('Physical Measurements', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Height
              TextFormField(
                initialValue: _heightCm.toString(),
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter height in centimeters',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter height';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height <= 0) {
                    return 'Please enter a valid height';
                  }
                  if (height > 250) {
                    return 'Height seems unusually high';
                  }
                  return null;
                },
                onSaved: (value) {
                  _heightCm = double.parse(value!);
                  _calculateAllScores();
                },
              ),
              
              const SizedBox(height: 16),
              
              // Current Weight
              TextFormField(
                initialValue: _currentWeightKg.toString(),
                decoration: const InputDecoration(
                  labelText: 'Current Weight (kg)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter current weight in kilograms',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Please enter a valid weight';
                  }
                  if (weight > 300) {
                    return 'Weight seems unusually high';
                  }
                  return null;
                },
                onSaved: (value) {
                  _currentWeightKg = double.parse(value!);
                  _calculateAllScores();
                },
              ),
              
              const SizedBox(height: 16),
              
              // Weight 3-6 Months Ago
              TextFormField(
                initialValue: _weight3_6MonthsAgoKg?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Weight 3-6 Months Ago (kg) (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter weight from 3-6 months ago',
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _weight3_6MonthsAgoKg = value != null && value.isNotEmpty ? double.parse(value) : null;
                  _calculateAllScores();
                },
              ),
              
              const SizedBox(height: 24),

              // Calculated Values
              const Text('Calculated Values', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // BMI
              Card(
                color: Colors.blueGrey[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMI: ${_calculatedBmi?.toStringAsFixed(1) ?? 'Not calculated'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BMI Category: ${_getBmiCategory()}',
                        style: TextStyle(
                          color: _getBmiCategoryColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BMI Score: $_calculatedBmiScore',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Weight Loss
              Card(
                color: Colors.blueGrey[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight Loss: ${_calculatedWeightLossPercentage?.toStringAsFixed(1) ?? 'Not calculated'}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Weight Loss Category: ${_getWeightLossCategory()}',
                        style: TextStyle(
                          color: _getWeightLossCategoryColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Weight Loss Score: $_calculatedWeightLossScore',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // MUST Score
              Card(
                color: _getRiskCategoryColor(),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MUST Total Score: $_calculatedMustTotalScore',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Risk Category: ${_getRiskCategoryText()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acute Disease Effect Score: $_acuteDiseaseEffectScore',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Acute Disease Effect
              const Text('Acute Disease Effect', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _acuteDiseaseEffectScore,
                items: _acuteDiseaseOptions.map((score) {
                  return DropdownMenuItem(
                    value: score,
                    child: Text(score == 0 ? 'No acute disease effect' : 'Acute disease effect (score: 2)'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _acuteDiseaseEffectScore = value!;
                    _calculateAllScores();
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Dietary Information
              const Text('Dietary Information', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Dietary Requirements
              TextFormField(
                initialValue: _dietaryRequirements,
                decoration: const InputDecoration(
                  labelText: 'Dietary Requirements',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Soft diet, Pureed, Low sodium',
                ),
                maxLines: 3,
                onSaved: (value) => _dietaryRequirements = value,
              ),
              
              const SizedBox(height: 16),
              
              // Food Preferences/Allergies
              TextFormField(
                initialValue: _foodPreferencesAllergies,
                decoration: const InputDecoration(
                  labelText: 'Food Preferences/Allergies',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., No nuts, Vegetarian, Lactose intolerant',
                ),
                maxLines: 3,
                onSaved: (value) => _foodPreferencesAllergies = value,
              ),
              
              const SizedBox(height: 16),
              
              // Swallowing Difficulties
              Row(
                children: [
                  Checkbox(
                    value: _swallowingDifficulties,
                    onChanged: (value) => setState(() => _swallowingDifficulties = value!),
                  ),
                  const Text('Swallowing difficulties present'),
                ],
              ),
              
              const SizedBox(height: 24),

              // Referrals and Interventions
              const Text('Referrals and Interventions', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Dietitian Referral
              Row(
                children: [
                  Checkbox(
                    value: _referredToDietitian,
                    onChanged: (value) => setState(() => _referredToDietitian = value!),
                  ),
                  const Text('Referred to dietitian'),
                ],
              ),
              
              // Supplementation Required
              Row(
                children: [
                  Checkbox(
                    value: _supplementationRequired,
                    onChanged: (value) => setState(() => _supplementationRequired = value!),
                  ),
                  const Text('Supplementation required'),
                ],
              ),
              
              const SizedBox(height: 24),

              // Action Plan
              const Text('Action Plan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _actionPlan,
                decoration: const InputDecoration(
                  labelText: 'Action Plan',
                  border: OutlineInputBorder(),
                  hintText: 'Describe the nutrition intervention plan',
                ),
                maxLines: 4,
                onSaved: (value) => _actionPlan = value,
              ),
              
              const SizedBox(height: 16),

              // Review and Follow-up
              const Text('Review and Follow-up', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Review Date
              Row(
                children: [
                  Expanded(
                    child: _reviewDate != null 
                        ? Text('Review Date: ${_reviewDate!.toIso8601String().split('T').first}')
                        : const Text('No review date set'),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context, false),
                    child: const Text('Set Review Date'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Next Weight Check Date
              Row(
                children: [
                  Expanded(
                    child: _nextWeightCheckDate != null 
                        ? Text('Next Weight Check: ${_nextWeightCheckDate!.toIso8601String().split('T').first}')
                        : const Text('No weight check date set'),
                  ),
                  TextButton(
                    onPressed: _selectWeightCheckDate,
                    child: const Text('Set Weight Check Date'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Assessor Signature
              TextFormField(
                initialValue: _assessorSignature,
                decoration: const InputDecoration(
                  labelText: 'Assessor Signature',
                  border: OutlineInputBorder(),
                  hintText: 'Digital signature or initials',
                ),
                onSaved: (value) => _assessorSignature = value,
              ),
              
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(widget.assessment != null ? 'Update Assessment' : 'Create Assessment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBmiCategory() {
    if (_calculatedBmi == null) return 'Not calculated';
    if (_calculatedBmi! < 18.5) return 'Underweight';
    if (_calculatedBmi! < 25) return 'Normal';
    if (_calculatedBmi! < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiCategoryColor() {
    if (_calculatedBmi == null) return Colors.grey;
    if (_calculatedBmi! < 18.5) return Colors.orange;
    if (_calculatedBmi! < 25) return Colors.green;
    if (_calculatedBmi! < 30) return Colors.yellow;
    return Colors.red;
  }

  String _getWeightLossCategory() {
    if (_calculatedWeightLossPercentage == null) return 'Not calculated';
    if (_calculatedWeightLossPercentage! < 5) return 'Minimal (< 5%)';
    if (_calculatedWeightLossPercentage! <= 10) return 'Moderate (5-10%)';
    return 'Severe (> 10%)';
  }

  Color _getWeightLossCategoryColor() {
    if (_calculatedWeightLossPercentage == null) return Colors.grey;
    if (_calculatedWeightLossPercentage! < 5) return Colors.green;
    if (_calculatedWeightLossPercentage! <= 10) return Colors.orange;
    return Colors.red;
  }

  String _getRiskCategoryText() {
    switch (_calculatedRiskCategory) {
      case 'low':
        return 'Low Risk (Score: 0)';
      case 'medium':
        return 'Medium Risk (Score: 1)';
      case 'high':
        return 'High Risk (Score: 2+)';
      default:
        return 'Unknown';
    }
  }

  Color _getRiskCategoryColor() {
    switch (_calculatedRiskCategory) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}