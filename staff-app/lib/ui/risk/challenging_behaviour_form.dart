import 'package:flutter/material.dart';
import 'package:staff_app/models/challenging_behaviour_assessment.dart';
import 'package:staff_app/services/challenging_behaviour_service.dart';
import 'package:supabase/supabase.dart';

class ChallengingBehaviourForm extends StatefulWidget {
  final ChallengingBehaviourAssessment? assessment;
  final String? serviceUserId;

  const ChallengingBehaviourForm({
    Key? key,
    this.assessment,
    this.serviceUserId,
  }) : super(key: key);

  @override
  State<ChallengingBehaviourForm> createState() => _ChallengingBehaviourFormState();
}

class _ChallengingBehaviourFormState extends State<ChallengingBehaviourForm> {
  late final ChallengingBehaviourService _challengingBehaviourService;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  late DateTime _assessmentDate;
  late String _behaviourType;
  late String _behaviourFrequency;
  late int? _behaviourDurationMinutes;
  late String _intensity;
  late List<String> _triggers;
  late List<String> _warningSigns;
  late List<String> _deEscalationStrategies;
  late String _medicationUsed;
  late String _injuriesCaused;
  late bool _injuriesToSelf;
  late bool _injuriesToOthers;
  late bool _propertyDamage;
  late bool _staffTrainedDeEscalation;
  late bool _pbsPlanInPlace;
  late String? _environmentalModificationsNeeded;
  late String _supportNeeds;
  late String _riskLevel;
  late String? _actionPlan;
  late DateTime? _reviewDate;
  late DateTime? _nextBehaviourMonitoringDate;
  late String _assessorName;
  late String? _assessorSignature;

  // Available options
  final List<String> _behaviourTypes = [
    'aggression', 'self_harm', 'wandering', 'sexual', 'inappropriate', 'vocal', 'withdrawal'
  ];
  
  final List<String> _frequencies = ['hourly', 'daily', 'weekly', 'monthly'];
  final List<String> _intensities = ['mild', 'moderate', 'severe'];
  final List<String> _medications = ['none', 'prn', 'regular'];
  final List<String> _injuries = ['none', 'minor', 'moderate', 'severe'];
  final List<String> _supportNeedsOptions = ['none', '1:1', '2:1', 'specialist'];
  
  final List<String> _triggerOptions = [
    'communication', 'pain', 'environment', 'activity', 'boredom', 'frustration', 
    'confusion', 'fear', 'anxiety', 'unmet needs', 'physical discomfort', 'routine change'
  ];
  
  final List<String> _warningSignOptions = [
    'clenched fists', 'facial expression', 'body tension', 'verbal cues', 
    'pacing', 'increased heart rate', 'sweating', 'avoidance', 'withdrawal'
  ];
  
  final List<String> _deEscalationOptions = [
    'calm voice', 'personal space', 'distraction', 'redirection', 'quiet area',
    'deep pressure', 'sensory tools', 'breathing exercises', 'positive reinforcement'
  ];

  @override
  void initState() {
    super.initState();
    _challengingBehaviourService = ChallengingBehaviourService(SupabaseClient('https://your-project.supabase.co', 'your-anon-key'));
    
    // Initialize with existing assessment or defaults
    if (widget.assessment != null) {
      final assessment = widget.assessment!;
      _assessmentDate = assessment.assessmentDate;
      _behaviourType = assessment.behaviourType;
      _behaviourFrequency = assessment.behaviourFrequency;
      _behaviourDurationMinutes = assessment.behaviourDurationMinutes;
      _intensity = assessment.intensity;
      _triggers = assessment.triggers ?? [];
      _warningSigns = assessment.warningSigns ?? [];
      _deEscalationStrategies = assessment.deEscalationStrategies ?? [];
      _medicationUsed = assessment.medicationUsed;
      _injuriesCaused = assessment.injuriesCaused;
      _injuriesToSelf = assessment.injuriesToSelf;
      _injuriesToOthers = assessment.injuriesToOthers;
      _propertyDamage = assessment.propertyDamage;
      _staffTrainedDeEscalation = assessment.staffTrainedDeEscalation;
      _pbsPlanInPlace = assessment.pbsPlanInPlace;
      _environmentalModificationsNeeded = assessment.environmentalModificationsNeeded;
      _supportNeeds = assessment.supportNeeds;
      _riskLevel = assessment.riskLevel;
      _actionPlan = assessment.actionPlan;
      _reviewDate = assessment.reviewDate;
      _nextBehaviourMonitoringDate = assessment.nextBehaviourMonitoringDate;
      _assessorName = assessment.assessorName;
      _assessorSignature = assessment.assessorSignature;
    } else {
      _assessmentDate = DateTime.now();
      _behaviourType = 'aggression';
      _behaviourFrequency = 'daily';
      _behaviourDurationMinutes = null;
      _intensity = 'moderate';
      _triggers = [];
      _warningSigns = [];
      _deEscalationStrategies = [];
      _medicationUsed = 'none';
      _injuriesCaused = 'none';
      _injuriesToSelf = false;
      _injuriesToOthers = false;
      _propertyDamage = false;
      _staffTrainedDeEscalation = false;
      _pbsPlanInPlace = false;
      _environmentalModificationsNeeded = null;
      _supportNeeds = 'none';
      _riskLevel = 'medium';
      _actionPlan = null;
      _reviewDate = null;
      _nextBehaviourMonitoringDate = null;
      _assessorName = '';
      _assessorSignature = null;
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    try {
      final assessment = ChallengingBehaviourAssessment(
        id: widget.assessment?.id,
        serviceUserId: widget.serviceUserId,
        assessmentDate: _assessmentDate,
        behaviourType: _behaviourType,
        behaviourFrequency: _behaviourFrequency,
        behaviourDurationMinutes: _behaviourDurationMinutes,
        intensity: _intensity,
        triggers: _triggers,
        warningSigns: _warningSigns,
        deEscalationStrategies: _deEscalationStrategies,
        medicationUsed: _medicationUsed,
        injuriesCaused: _injuriesCaused,
        injuriesToSelf: _injuriesToSelf,
        injuriesToOthers: _injuriesToOthers,
        propertyDamage: _propertyDamage,
        staffTrainedDeEscalation: _staffTrainedDeEscalation,
        pbsPlanInPlace: _pbsPlanInPlace,
        environmentalModificationsNeeded: _environmentalModificationsNeeded,
        supportNeeds: _supportNeeds,
        riskLevel: _riskLevel,
        actionPlan: _actionPlan,
        reviewDate: _reviewDate,
        nextBehaviourMonitoringDate: _nextBehaviourMonitoringDate,
        assessorName: _assessorName,
        assessorSignature: _assessorSignature,
        createdAt: widget.assessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.assessment != null) {
        await _challengingBehaviourService.updateAssessment(widget.assessment!.id!, assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenging behaviour assessment updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _challengingBehaviourService.createAssessment(assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenging behaviour assessment created successfully'),
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

  Future<void> _selectMonitoringDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextBehaviourMonitoringDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _nextBehaviourMonitoringDate = picked;
      });
    }
  }

  void _showMultiSelectDialog(BuildContext context, List<String> options, List<String> selectedOptions, String title, Function(List<String>) onSelectionChanged) {
    final List<String> localSelections = List.from(selectedOptions);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: options.map((option) {
                return CheckboxListTile(
                  value: localSelections.contains(option),
                  title: Text(option),
                  onChanged: (bool? value) {
                    if (value == true) {
                      if (!localSelections.contains(option)) {
                        localSelections.add(option);
                      }
                    } else {
                      localSelections.remove(option);
                    }
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSelectionChanged(localSelections);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment != null ? 'Edit Challenging Behaviour Assessment' : 'New Challenging Behaviour Assessment'),
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

              // Behaviour Information
              const Text('Behaviour Information', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Behaviour Type
              DropdownButtonFormField<String>(
                value: _behaviourType,
                items: _behaviourTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getBehaviourTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _behaviourType = value!),
                decoration: const InputDecoration(
                  labelText: 'Behaviour Type',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Behaviour Frequency
              DropdownButtonFormField<String>(
                value: _behaviourFrequency,
                items: _frequencies.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(_getFrequencyText(freq)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _behaviourFrequency = value!),
                decoration: const InputDecoration(
                  labelText: 'Behaviour Frequency',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Behaviour Duration
              TextFormField(
                initialValue: _behaviourDurationMinutes?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Behaviour Duration (minutes) (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter duration in minutes',
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _behaviourDurationMinutes = value != null && value.isNotEmpty ? int.parse(value) : null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Intensity
              DropdownButtonFormField<String>(
                value: _intensity,
                items: _intensities.map((intensity) {
                  return DropdownMenuItem(
                    value: intensity,
                    child: Text(_getIntensityText(intensity)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _intensity = value!),
                decoration: const InputDecoration(
                  labelText: 'Intensity',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Risk Factors
              const Text('Risk Factors', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Injuries Caused
              DropdownButtonFormField<String>(
                value: _injuriesCaused,
                items: _injuries.map((injury) {
                  return DropdownMenuItem(
                    value: injury,
                    child: Text(injury),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _injuriesCaused = value!),
                decoration: const InputDecoration(
                  labelText: 'Injuries Caused',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Injuries to Self
              Row(
                children: [
                  Checkbox(
                    value: _injuriesToSelf,
                    onChanged: (value) => setState(() => _injuriesToSelf = value!),
                  ),
                  const Text('Injuries to self'),
                ],
              ),
              
              // Injuries to Others
              Row(
                children: [
                  Checkbox(
                    value: _injuriesToOthers,
                    onChanged: (value) => setState(() => _injuriesToOthers = value!),
                  ),
                  const Text('Injuries to others'),
                ],
              ),
              
              // Property Damage
              Row(
                children: [
                  Checkbox(
                    value: _propertyDamage,
                    onChanged: (value) => setState(() => _propertyDamage = value!),
                  ),
                  const Text('Property damage'),
                ],
              ),
              
              const SizedBox(height: 24),

              // Triggers
              const Text('Triggers', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Selected: ${_triggers.isEmpty ? 'None' : _triggers.join(', ')}'),
                  ),
                  TextButton(
                    onPressed: () => _showMultiSelectDialog(
                      context, 
                      _triggerOptions, 
                      _triggers, 
                      'Select Triggers', 
                      (selections) => setState(() => _triggers = selections)
                    ),
                    child: const Text('Edit Triggers'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Warning Signs
              const Text('Warning Signs', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Selected: ${_warningSigns.isEmpty ? 'None' : _warningSigns.join(', ')}'),
                  ),
                  TextButton(
                    onPressed: () => _showMultiSelectDialog(
                      context, 
                      _warningSignOptions, 
                      _warningSigns, 
                      'Select Warning Signs', 
                      (selections) => setState(() => _warningSigns = selections)
                    ),
                    child: const Text('Edit Warning Signs'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // De-escalation Strategies
              const Text('De-escalation Strategies', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Selected: ${_deEscalationStrategies.isEmpty ? 'None' : _deEscalationStrategies.join(', ')}'),
                  ),
                  TextButton(
                    onPressed: () => _showMultiSelectDialog(
                      context, 
                      _deEscalationOptions, 
                      _deEscalationStrategies, 
                      'Select De-escalation Strategies', 
                      (selections) => setState(() => _deEscalationStrategies = selections)
                    ),
                    child: const Text('Edit Strategies'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Interventions
              const Text('Interventions', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Medication Used
              DropdownButtonFormField<String>(
                value: _medicationUsed,
                items: _medications.map((med) {
                  return DropdownMenuItem(
                    value: med,
                    child: Text(_getMedicationText(med)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _medicationUsed = value!),
                decoration: const InputDecoration(
                  labelText: 'Medication Used',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Staff Trained in De-escalation
              Row(
                children: [
                  Checkbox(
                    value: _staffTrainedDeEscalation,
                    onChanged: (value) => setState(() => _staffTrainedDeEscalation = value!),
                  ),
                  const Text('Staff trained in de-escalation'),
                ],
              ),
              
              // PBS Plan in Place
              Row(
                children: [
                  Checkbox(
                    value: _pbsPlanInPlace,
                    onChanged: (value) => setState(() => _pbsPlanInPlace = value!),
                  ),
                  const Text('PBS plan in place'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Environmental Modifications Needed
              TextFormField(
                initialValue: _environmentalModificationsNeeded,
                decoration: const InputDecoration(
                  labelText: 'Environmental Modifications Needed',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Quiet room, Reduced stimuli',
                ),
                maxLines: 3,
                onSaved: (value) => _environmentalModificationsNeeded = value,
              ),
              
              const SizedBox(height: 16),
              
              // Support Needs
              DropdownButtonFormField<String>(
                value: _supportNeeds,
                items: _supportNeedsOptions.map((support) {
                  return DropdownMenuItem(
                    value: support,
                    child: Text(_getSupportNeedsText(support)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _supportNeeds = value!),
                decoration: const InputDecoration(
                  labelText: 'Support Needs',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Risk Level (Calculated)
              const Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                color: _getRiskLevelColor(_riskLevel),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getRiskLevelColorEmoji(_riskLevel)} ${_getRiskLevelText(_riskLevel)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'High-risk factors: ${_getHighRiskFactorsCount()}',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      if (_isUrgent)
                        const Text(
                          '⚠️ URGENT: Injuries to others + Severe intensity',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (_needsEscalation)
                        const Text(
                          '⚠️ ESCALATION: Self-harm + High frequency',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (_needsReview)
                        const Text(
                          '⚠️ REVIEW: Property damage + Aggression',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
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
                  hintText: 'Describe the Positive Behaviour Support plan',
                ),
                maxLines: 4,
                onSaved: (value) => _actionPlan = value,
              ),
              
              const SizedBox(height: 16),

              // Review and Monitoring
              const Text('Review and Monitoring', style: TextStyle(fontWeight: FontWeight.bold)),
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
              
              // Next Behaviour Monitoring Date
              Row(
                children: [
                  Expanded(
                    child: _nextBehaviourMonitoringDate != null 
                        ? Text('Next Monitoring: ${_nextBehaviourMonitoringDate!.toIso8601String().split('T').first}')
                        : const Text('No monitoring date set'),
                  ),
                  TextButton(
                    onPressed: _selectMonitoringDate,
                    child: const Text('Set Monitoring Date'),
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

  String _getBehaviourTypeText(String type) {
    switch (type) {
      case 'aggression': return 'Aggression';
      case 'self_harm': return 'Self-Harm';
      case 'wandering': return 'Wandering';
      case 'sexual': return 'Sexual Behaviour';
      case 'inappropriate': return 'Inappropriate Behaviour';
      case 'vocal': return 'Vocal Behaviour';
      case 'withdrawal': return 'Withdrawal';
      default: return type;
    }
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'hourly': return 'Hourly';
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'monthly': return 'Monthly';
      default: return frequency;
    }
  }

  String _getIntensityText(String intensity) {
    switch (intensity) {
      case 'mild': return 'Mild';
      case 'moderate': return 'Moderate';
      case 'severe': return 'Severe';
      default: return intensity;
    }
  }

  String _getMedicationText(String medication) {
    switch (medication) {
      case 'none': return 'None';
      case 'prn': return 'PRN (As Needed)';
      case 'regular': return 'Regular';
      default: return medication;
    }
  }

  String _getSupportNeedsText(String support) {
    switch (support) {
      case 'none': return 'None';
      case '1:1': return '1:1 Support';
      case '2:1': return '2:1 Support';
      case 'specialist': return 'Specialist Support';
      default: return support;
    }
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      case 'critical': return Colors.red[900]!;
      default: return Colors.grey;
    }
  }

  String _getRiskLevelColorEmoji(String riskLevel) {
    switch (riskLevel) {
      case 'low': return '🟢';
      case 'medium': return '🟡';
      case 'high': return '🟠';
      case 'critical': return '🔴';
      default: return '⚪';
    }
  }

  String _getRiskLevelText(String riskLevel) {
    switch (riskLevel) {
      case 'low': return 'Low Risk';
      case 'medium': return 'Medium Risk';
      case 'high': return 'High Risk';
      case 'critical': return 'CRITICAL RISK';
      default: return riskLevel;
    }
  }

  int _getHighRiskFactorsCount() {
    int count = 0;
    
    if (_intensity == 'severe') count += 2;
    if (_intensity == 'moderate') count += 1;
    if (_behaviourFrequency == 'hourly' || _behaviourFrequency == 'daily') count += 1;
    if (_injuriesToOthers) count += 2;
    if (_injuriesToSelf) count += 1;
    if (_propertyDamage) count += 1;
    
    return count;
  }

  bool get _isUrgent {
    return _injuriesToOthers && _intensity == 'severe';
  }

  bool get _needsEscalation {
    return _injuriesToSelf && (_behaviourFrequency == 'hourly' || _behaviourFrequency == 'daily');
  }

  bool get _needsReview {
    return _propertyDamage && _behaviourType == 'aggression';
  }
}