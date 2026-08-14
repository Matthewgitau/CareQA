import 'package:flutter/material.dart';
import 'package:staff_app/models/incontinence_assessment.dart';
import 'package:staff_app/services/incontinence_service.dart';
import 'package:supabase/supabase.dart';

class IncontinenceRiskForm extends StatefulWidget {
  final IncontinenceAssessment? assessment;
  final String? serviceUserId;

  const IncontinenceRiskForm({
    Key? key,
    this.assessment,
    this.serviceUserId,
  }) : super(key: key);

  @override
  State<IncontinenceRiskForm> createState() => _IncontinenceRiskFormState();
}

class _IncontinenceRiskFormState extends State<IncontinenceRiskForm> {
  late final IncontinenceService _incontinenceService;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  late DateTime _assessmentDate;
  late String _assessorName;
  late BladderContinenceStatus _bladderContinenceStatus;
  late BowelContinenceStatus _bowelContinenceStatus;
  late Frequency _frequency;
  late List<String> _triggers;
  late int? _fluidIntakeMl;
  late bool _caffeineIntake;
  late bool _alcoholIntake;
  late String? _medications;
  late bool _mobilityAffectingAccess;
  late bool _cognitiveAwareness;
  late ToiletAccessibility _toiletAccessibility;
  late List<String> _incontinenceProducts;
  late SkinCondition _skinCondition;
  late DateTime? _previousAssessmentDate;
  late bool _referredToContinenceService;
  late bool _bladderDiaryCompleted;
  late bool _bowelDiaryCompleted;
  late String? _actionPlan;
  late DateTime? _reviewDate;

  // Available options
  final List<String> _triggerOptions = [
    'Coughing',
    'Sneezing',
    'Laughing',
    'Urgency',
    'Activity',
    'Lifting',
    'Standing up',
    'Walking',
  ];

  final List<String> _productOptions = [
    'Pads',
    'Sheaths',
    'Catheters',
    'Urinals',
    'Bedpans',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _incontinenceService = IncontinenceService(Supabase.instance.client);
    
    // Initialize with existing assessment or defaults
    if (widget.assessment != null) {
      final assessment = widget.assessment!;
      _assessmentDate = assessment.assessmentDate;
      _assessorName = assessment.assessorName;
      _bladderContinenceStatus = assessment.bladderContinenceStatus;
      _bowelContinenceStatus = assessment.bowelContinenceStatus;
      _frequency = assessment.frequency;
      _triggers = assessment.triggers;
      _fluidIntakeMl = assessment.fluidIntakeMl;
      _caffeineIntake = assessment.caffeineIntake;
      _alcoholIntake = assessment.alcoholIntake;
      _medications = assessment.medications;
      _mobilityAffectingAccess = assessment.mobilityAffectingAccess;
      _cognitiveAwareness = assessment.cognitiveAwareness;
      _toiletAccessibility = assessment.toiletAccessibility;
      _incontinenceProducts = assessment.incontinenceProducts;
      _skinCondition = assessment.skinCondition;
      _previousAssessmentDate = assessment.previousAssessmentDate;
      _referredToContinenceService = assessment.referredToContinenceService;
      _bladderDiaryCompleted = assessment.bladderDiaryCompleted;
      _bowelDiaryCompleted = assessment.bowelDiaryCompleted;
      _actionPlan = assessment.actionPlan;
      _reviewDate = assessment.reviewDate;
    } else {
      _assessmentDate = DateTime.now();
      _assessorName = '';
      _bladderContinenceStatus = BladderContinenceStatus.continent;
      _bowelContinenceStatus = BowelContinenceStatus.continent;
      _frequency = Frequency.daily;
      _triggers = [];
      _fluidIntakeMl = null;
      _caffeineIntake = false;
      _alcoholIntake = false;
      _medications = null;
      _mobilityAffectingAccess = false;
      _cognitiveAwareness = true;
      _toiletAccessibility = ToiletAccessibility.withinReach;
      _incontinenceProducts = [];
      _skinCondition = SkinCondition.intact;
      _previousAssessmentDate = null;
      _referredToContinenceService = false;
      _bladderDiaryCompleted = false;
      _bowelDiaryCompleted = false;
      _actionPlan = null;
      _reviewDate = null;
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    try {
      final assessment = IncontinenceAssessment(
        id: widget.assessment?.id,
        serviceUserId: widget.serviceUserId,
        assessmentDate: _assessmentDate,
        assessorName: _assessorName,
        bladderContinenceStatus: _bladderContinenceStatus,
        bowelContinenceStatus: _bowelContinenceStatus,
        frequency: _frequency,
        triggers: _triggers,
        fluidIntakeMl: _fluidIntakeMl,
        caffeineIntake: _caffeineIntake,
        alcoholIntake: _alcoholIntake,
        medications: _medications,
        mobilityAffectingAccess: _mobilityAffectingAccess,
        cognitiveAwareness: _cognitiveAwareness,
        toiletAccessibility: _toiletAccessibility,
        incontinenceProducts: _incontinenceProducts,
        skinCondition: _skinCondition,
        previousAssessmentDate: _previousAssessmentDate,
        referredToContinenceService: _referredToContinenceService,
        bladderDiaryCompleted: _bladderDiaryCompleted,
        bowelDiaryCompleted: _bowelDiaryCompleted,
        actionPlan: _actionPlan,
        reviewDate: _reviewDate,
        createdAt: widget.assessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.assessment != null) {
        await _incontinenceService.updateAssessment(widget.assessment!.id!, assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _incontinenceService.createAssessment(assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment created successfully'),
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
      });
    }
  }

  Future<void> _selectPreviousDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _previousAssessmentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _previousAssessmentDate = picked;
      });
    }
  }

  Widget _buildFilterChips(List<String> options, List<String> selectedOptions, Function(String) onToggle) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: options.map((option) {
        return FilterChip(
          label: Text(option),
          selected: selectedOptions.contains(option),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                selectedOptions.add(option);
              } else {
                selectedOptions.remove(option);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment != null ? 'Edit Incontinence Assessment' : 'New Incontinence Assessment'),
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

              // Bladder Continence Status
              const Text('Bladder Continence Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<BladderContinenceStatus>(
                value: _bladderContinenceStatus,
                items: BladderContinenceStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _bladderContinenceStatus = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),

              // Bowel Continence Status
              const Text('Bowel Continence Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<BowelContinenceStatus>(
                value: _bowelContinenceStatus,
                items: BowelContinenceStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _bowelContinenceStatus = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Frequency
              const Text('Frequency of Incontinence Episodes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Frequency>(
                value: _frequency,
                items: Frequency.values.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _frequency = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Triggers
              const Text('Triggers', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFilterChips(_triggerOptions, _triggers, (option) {}),
              const SizedBox(height: 8),
              const Text('Select all that apply', style: TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 24),

              // Fluid Intake
              TextFormField(
                initialValue: _fluidIntakeMl?.toString(),
                decoration: const InputDecoration(
                  labelText: 'Fluid Intake (ml per day)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _fluidIntakeMl = value != null && value.isNotEmpty ? int.parse(value) : null,
              ),
              
              const SizedBox(height: 16),

              // Caffeine Intake
              Row(
                children: [
                  Checkbox(
                    value: _caffeineIntake,
                    onChanged: (value) => setState(() => _caffeineIntake = value!),
                  ),
                  const Text('Caffeine Intake'),
                ],
              ),
              
              // Alcohol Intake
              Row(
                children: [
                  Checkbox(
                    value: _alcoholIntake,
                    onChanged: (value) => setState(() => _alcoholIntake = value!),
                  ),
                  const Text('Alcohol Intake'),
                ],
              ),
              
              const SizedBox(height: 24),

              // Medications
              TextFormField(
                initialValue: _medications,
                decoration: const InputDecoration(
                  labelText: 'Medications Affecting Continence',
                  border: OutlineInputBorder(),
                  hintText: 'List medications that may affect continence',
                ),
                maxLines: 3,
                onSaved: (value) => _medications = value,
              ),
              
              const SizedBox(height: 24),

              // Mobility and Cognitive
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: _mobilityAffectingAccess,
                          onChanged: (value) => setState(() => _mobilityAffectingAccess = value!),
                        ),
                        const Text('Mobility Affecting Access to Toilet'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: _cognitiveAwareness,
                          onChanged: (value) => setState(() => _cognitiveAwareness = value!),
                        ),
                        const Text('Cognitive Awareness of Need'),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Toilet Accessibility
              const Text('Toilet Accessibility', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ToiletAccessibility>(
                value: _toiletAccessibility,
                items: ToiletAccessibility.values.map((access) {
                  return DropdownMenuItem(
                    value: access,
                    child: Text(access.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _toiletAccessibility = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Incontinence Products
              const Text('Incontinence Products Used', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFilterChips(_productOptions, _incontinenceProducts, (option) {}),
              const SizedBox(height: 8),
              const Text('Select all that apply', style: TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 24),

              // Skin Condition
              const Text('Skin Condition', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<SkinCondition>(
                value: _skinCondition,
                items: SkinCondition.values.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _skinCondition = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Previous Assessment
              Row(
                children: [
                  Expanded(
                    child: _previousAssessmentDate != null 
                        ? Text('Previous Assessment: ${_previousAssessmentDate!.toIso8601String().split('T').first}')
                        : const Text('No previous assessment'),
                  ),
                  TextButton(
                    onPressed: () => _selectPreviousDate(context),
                    child: const Text('Set Previous Date'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Continence Service Referral
              Row(
                children: [
                  Checkbox(
                    value: _referredToContinenceService,
                    onChanged: (value) => setState(() => _referredToContinenceService = value!),
                  ),
                  const Text('Referred to Continence Service'),
                ],
              ),
              
              // Bladder Diary
              Row(
                children: [
                  Checkbox(
                    value: _bladderDiaryCompleted,
                    onChanged: (value) => setState(() => _bladderDiaryCompleted = value!),
                  ),
                  const Text('Bladder Diary Completed'),
                ],
              ),
              
              // Bowel Diary
              Row(
                children: [
                  Checkbox(
                    value: _bowelDiaryCompleted,
                    onChanged: (value) => setState(() => _bowelDiaryCompleted = value!),
                  ),
                  const Text('Bowel Diary Completed'),
                ],
              ),
              
              const SizedBox(height: 24),

              // Action Plan
              TextFormField(
                initialValue: _actionPlan,
                decoration: const InputDecoration(
                  labelText: 'Action Plan',
                  border: OutlineInputBorder(),
                  hintText: 'Describe the action plan for managing incontinence',
                ),
                maxLines: 4,
                onSaved: (value) => _actionPlan = value,
              ),
              
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
}