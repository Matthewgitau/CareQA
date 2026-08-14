import 'package:flutter/material.dart';
import 'package:staff_app/models/bed_railing_assessment.dart';
import 'package:staff_app/services/bed_railing_service.dart';
import 'package:supabase/supabase.dart';

class BedRailingForm extends StatefulWidget {
  final BedRailingAssessment? assessment;
  final String? serviceUserId;

  const BedRailingForm({
    Key? key,
    this.assessment,
    this.serviceUserId,
  }) : super(key: key);

  @override
  State<BedRailingForm> createState() => _BedRailingFormState();
}

class _BedRailingFormState extends State<BedRailingForm> {
  late final BedRailingService _bedRailingService;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  late DateTime _assessmentDate;
  late String _bedType;
  late String _bedRailsType;
  late String _railCondition;
  late bool _manufacturerInstructionsAvailable;
  late String _railHeightAndFit;
  late bool _entrapmentRiskAssessed;
  late String _patientMobility;
  late bool _cognitiveImpairment;
  late bool _agitationRestlessness;
  late String _riskOfFallingOutOfBed;
  late String _riskOfEntrapment;
  late bool _alternativeMeasuresConsidered;
  late bool _familyConsentObtained;
  late bool _staffTrainedInBedRailUse;
  late bool _railRegularlyChecked;
  late DateTime? _lastCheckDate;
  late DateTime? _nextCheckDate;
  late String? _actionPlan;
  late DateTime? _reviewDate;
  late String _assessorName;
  late String? _assessorSignature;

  // Available options
  final List<String> _bedTypes = ['standard', 'profiling', 'hospital', 'other'];
  final List<String> _bedRailsTypes = ['full', 'half', 'mobile', 'other'];
  final List<String> _railConditions = ['good', 'worn', 'damaged'];
  final List<String> _railHeightAndFits = ['correct', 'incorrect'];
  final List<String> _patientMobilities = ['independent', 'assisted', 'bedbound'];
  final List<String> _riskLevels = ['high', 'medium', 'low'];
  
  @override
  void initState() {
    super.initState();
    _bedRailingService = BedRailingService(SupabaseClient('https://your-project.supabase.co', 'your-anon-key'));
    
    // Initialize with existing assessment or defaults
    if (widget.assessment != null) {
      final assessment = widget.assessment!;
      _assessmentDate = assessment.assessmentDate;
      _bedType = assessment.bedType;
      _bedRailsType = assessment.bedRailsType;
      _railCondition = assessment.railCondition;
      _manufacturerInstructionsAvailable = assessment.manufacturerInstructionsAvailable;
      _railHeightAndFit = assessment.railHeightAndFit;
      _entrapmentRiskAssessed = assessment.entrapmentRiskAssessed;
      _patientMobility = assessment.patientMobility;
      _cognitiveImpairment = assessment.cognitiveImpairment;
      _agitationRestlessness = assessment.agitationRestlessness;
      _riskOfFallingOutOfBed = assessment.riskOfFallingOutOfBed;
      _riskOfEntrapment = assessment.riskOfEntrapment;
      _alternativeMeasuresConsidered = assessment.alternativeMeasuresConsidered;
      _familyConsentObtained = assessment.familyConsentObtained;
      _staffTrainedInBedRailUse = assessment.staffTrainedInBedRailUse;
      _railRegularlyChecked = assessment.railRegularlyChecked;
      _lastCheckDate = assessment.lastCheckDate;
      _nextCheckDate = assessment.nextCheckDate;
      _actionPlan = assessment.actionPlan;
      _reviewDate = assessment.reviewDate;
      _assessorName = assessment.assessorName;
      _assessorSignature = assessment.assessorSignature;
    } else {
      _assessmentDate = DateTime.now();
      _bedType = 'standard';
      _bedRailsType = 'full';
      _railCondition = 'good';
      _manufacturerInstructionsAvailable = false;
      _railHeightAndFit = 'correct';
      _entrapmentRiskAssessed = false;
      _patientMobility = 'independent';
      _cognitiveImpairment = false;
      _agitationRestlessness = false;
      _riskOfFallingOutOfBed = 'low';
      _riskOfEntrapment = 'low';
      _alternativeMeasuresConsidered = false;
      _familyConsentObtained = false;
      _staffTrainedInBedRailUse = false;
      _railRegularlyChecked = false;
      _lastCheckDate = null;
      _nextCheckDate = null;
      _actionPlan = null;
      _reviewDate = null;
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
      final assessment = BedRailingAssessment(
        id: widget.assessment?.id,
        serviceUserId: widget.serviceUserId,
        assessmentDate: _assessmentDate,
        bedType: _bedType,
        bedRailsType: _bedRailsType,
        railCondition: _railCondition,
        manufacturerInstructionsAvailable: _manufacturerInstructionsAvailable,
        railHeightAndFit: _railHeightAndFit,
        entrapmentRiskAssessed: _entrapmentRiskAssessed,
        patientMobility: _patientMobility,
        cognitiveImpairment: _cognitiveImpairment,
        agitationRestlessness: _agitationRestlessness,
        riskOfFallingOutOfBed: _riskOfFallingOutOfBed,
        riskOfEntrapment: _riskOfEntrapment,
        alternativeMeasuresConsidered: _alternativeMeasuresConsidered,
        familyConsentObtained: _familyConsentObtained,
        staffTrainedInBedRailUse: _staffTrainedInBedRailUse,
        railRegularlyChecked: _railRegularlyChecked,
        lastCheckDate: _lastCheckDate,
        nextCheckDate: _nextCheckDate,
        actionPlan: _actionPlan,
        reviewDate: _reviewDate,
        assessorName: _assessorName,
        assessorSignature: _assessorSignature,
        createdAt: widget.assessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.assessment != null) {
        await _bedRailingService.updateAssessment(widget.assessment!.id!, assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bed railing assessment updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _bedRailingService.createAssessment(assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bed railing assessment created successfully'),
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

  Future<void> _selectLastCheckDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastCheckDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _lastCheckDate = picked;
      });
    }
  }

  Future<void> _selectNextCheckDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextCheckDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _nextCheckDate = picked;
      });
    }
  }

  String _getBedTypeText(String type) {
    switch (type) {
      case 'standard': return 'Standard Bed';
      case 'profiling': return 'Profiling Bed';
      case 'hospital': return 'Hospital Bed';
      case 'other': return 'Other';
      default: return type;
    }
  }

  String _getBedRailsTypeText(String type) {
    switch (type) {
      case 'full': return 'Full Bed Rails';
      case 'half': return 'Half Bed Rails';
      case 'mobile': return 'Mobile Bed Rails';
      case 'other': return 'Other';
      default: return type;
    }
  }

  String _getRailConditionText(String condition) {
    switch (condition) {
      case 'good': return 'Good Condition';
      case 'worn': return 'Worn Condition';
      case 'damaged': return 'Damaged Condition';
      default: return condition;
    }
  }

  String _getPatientMobilityText(String mobility) {
    switch (mobility) {
      case 'independent': return 'Independent';
      case 'assisted': return 'Requires Assistance';
      case 'bedbound': return 'Bedbound';
      default: return mobility;
    }
  }

  String _getRiskLevelText(String riskLevel) {
    switch (riskLevel) {
      case 'high': return 'High Risk';
      case 'medium': return 'Medium Risk';
      case 'low': return 'Low Risk';
      default: return riskLevel;
    }
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getRiskLevelEmoji(String riskLevel) {
    switch (riskLevel) {
      case 'high': return '🔴';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  bool get _isLOLERCompliant {
    return _manufacturerInstructionsAvailable &&
           _railCondition == 'good' &&
           _railHeightAndFit == 'correct' &&
           _entrapmentRiskAssessed &&
           _staffTrainedInBedRailUse &&
           _railRegularlyChecked;
  }

  bool get _isHighRisk {
    return _riskOfFallingOutOfBed == 'high' || _riskOfEntrapment == 'high';
  }

  String get _checkFrequencyRecommendation {
    if (_riskOfFallingOutOfBed == 'high' || _riskOfEntrapment == 'high') {
      return 'Weekly checks recommended';
    } else if (_riskOfFallingOutOfBed == 'medium' || _riskOfEntrapment == 'medium') {
      return 'Monthly checks recommended';
    } else {
      return 'Quarterly checks recommended';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment != null ? 'Edit Bed Railing Assessment' : 'New Bed Railing Assessment'),
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

              // Bed Information
              const Text('Bed Information', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Bed Type
              DropdownButtonFormField<String>(
                value: _bedType,
                items: _bedTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getBedTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _bedType = value!),
                decoration: const InputDecoration(
                  labelText: 'Bed Type',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bed Rails Type
              DropdownButtonFormField<String>(
                value: _bedRailsType,
                items: _bedRailsTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getBedRailsTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _bedRailsType = value!),
                decoration: const InputDecoration(
                  labelText: 'Bed Rails Type',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Rail Condition
              DropdownButtonFormField<String>(
                value: _railCondition,
                items: _railConditions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(_getRailConditionText(condition)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _railCondition = value!),
                decoration: const InputDecoration(
                  labelText: 'Rail Condition',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Manufacturer Instructions Available
              Row(
                children: [
                  Checkbox(
                    value: _manufacturerInstructionsAvailable,
                    onChanged: (value) => setState(() => _manufacturerInstructionsAvailable = value!),
                  ),
                  const Text('Manufacturer\'s instructions available'),
                ],
              ),
              
              // Rail Height and Fit
              DropdownButtonFormField<String>(
                value: _railHeightAndFit,
                items: _railHeightAndFits.map((fit) {
                  return DropdownMenuItem(
                    value: fit,
                    child: Text(fit == 'correct' ? 'Correct Height and Fit' : 'Incorrect Height and Fit'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _railHeightAndFit = value!),
                decoration: const InputDecoration(
                  labelText: 'Rail Height and Fit',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Risk Assessment
              const Text('Risk Assessment', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Entrapment Risk Assessed
              Row(
                children: [
                  Checkbox(
                    value: _entrapmentRiskAssessed,
                    onChanged: (value) => setState(() => _entrapmentRiskAssessed = value!),
                  ),
                  const Text('Entrapment risk assessed'),
                ],
              ),
              
              // Patient Mobility
              DropdownButtonFormField<String>(
                value: _patientMobility,
                items: _patientMobilities.map((mobility) {
                  return DropdownMenuItem(
                    value: mobility,
                    child: Text(_getPatientMobilityText(mobility)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _patientMobility = value!),
                decoration: const InputDecoration(
                  labelText: 'Patient Mobility',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cognitive Impairment
              Row(
                children: [
                  Checkbox(
                    value: _cognitiveImpairment,
                    onChanged: (value) => setState(() => _cognitiveImpairment = value!),
                  ),
                  const Text('Cognitive impairment'),
                ],
              ),
              
              // Agitation/Restlessness
              Row(
                children: [
                  Checkbox(
                    value: _agitationRestlessness,
                    onChanged: (value) => setState(() => _agitationRestlessness = value!),
                  ),
                  const Text('Agitation/Restlessness'),
                ],
              ),
              
              const SizedBox(height: 24),

              // Risk Levels (Calculated)
              const Text('Risk Levels (Calculated)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // LOLER Compliance Status
              Card(
                color: _isLOLERCompliant ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(_isLOLERCompliant ? Icons.check_circle : Icons.warning, 
                           color: _isLOLERCompliant ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        _isLOLERCompliant ? 'LOLER Compliant' : 'LOLER Non-Compliant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isLOLERCompliant ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Falling Risk Level
              Card(
                color: _getRiskLevelColor(_riskOfFallingOutOfBed).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Text(
                        '${_getRiskLevelEmoji(_riskOfFallingOutOfBed)} Falling Risk: ${_getRiskLevelText(_riskOfFallingOutOfBed)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRiskLevelColor(_riskOfFallingOutOfBed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Entrapment Risk Level
              Card(
                color: _getRiskLevelColor(_riskOfEntrapment).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Text(
                        '${_getRiskLevelEmoji(_riskOfEntrapment)} Entrapment Risk: ${_getRiskLevelText(_riskOfEntrapment)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRiskLevelColor(_riskOfEntrapment),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // High Risk Alert
              if (_isHighRisk)
                Card(
                  color: Colors.red.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: const [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          '⚠️ HIGH RISK: Immediate attention required',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),

              // Safety Measures
              const Text('Safety Measures', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Alternative Measures Considered
              Row(
                children: [
                  Checkbox(
                    value: _alternativeMeasuresConsidered,
                    onChanged: (value) => setState(() => _alternativeMeasuresConsidered = value!),
                  ),
                  const Text('Alternative measures considered'),
                ],
              ),
              
              // Family Consent Obtained
              Row(
                children: [
                  Checkbox(
                    value: _familyConsentObtained,
                    onChanged: (value) => setState(() => _familyConsentObtained = value!),
                  ),
                  const Text('Family consent obtained'),
                ],
              ),
              
              // Staff Trained in Bed Rail Use
              Row(
                children: [
                  Checkbox(
                    value: _staffTrainedInBedRailUse,
                    onChanged: (value) => setState(() => _staffTrainedInBedRailUse = value!),
                  ),
                  const Text('Staff trained in bed rail use'),
                ],
              ),
              
              // Rail Regularly Checked
              Row(
                children: [
                  Checkbox(
                    value: _railRegularlyChecked,
                    onChanged: (value) => setState(() => _railRegularlyChecked = value!),
                  ),
                  const Text('Rail regularly checked'),
                ],
              ),
              
              const SizedBox(height: 24),

              // Check Dates
              const Text('Check Dates', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Last Check Date
              Row(
                children: [
                  Expanded(
                    child: _lastCheckDate != null 
                        ? Text('Last Check: ${_lastCheckDate!.toIso8601String().split('T').first}')
                        : const Text('No last check date set'),
                  ),
                  TextButton(
                    onPressed: _selectLastCheckDate,
                    child: const Text('Set Last Check'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Next Check Date
              Row(
                children: [
                  Expanded(
                    child: _nextCheckDate != null 
                        ? Text('Next Check: ${_nextCheckDate!.toIso8601String().split('T').first}')
                        : const Text('No next check date set'),
                  ),
                  TextButton(
                    onPressed: _selectNextCheckDate,
                    child: const Text('Set Next Check'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Check Frequency Recommendation
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Recommendation: $_checkFrequencyRecommendation',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Documentation
              const Text('Documentation', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Action Plan
              const Text('Action Plan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _actionPlan,
                decoration: const InputDecoration(
                  labelText: 'Action Plan',
                  border: OutlineInputBorder(),
                  hintText: 'Describe the action plan for bed rail safety',
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
}