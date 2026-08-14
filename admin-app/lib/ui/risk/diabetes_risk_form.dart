import 'package:flutter/material.dart';
import 'package:admin_app/models/diabetes_assessment.dart';
import 'package:admin_app/services/diabetes_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DiabetesRiskForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;
  final String? assessmentId;
  final VoidCallback? onSaved;

  const DiabetesRiskForm({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
    this.assessmentId,
    this.onSaved,
  }) : super(key: key);

  @override
  _DiabetesRiskFormState createState() => _DiabetesRiskFormState();
}

class _DiabetesRiskFormState extends State<DiabetesRiskForm> {
  final _diabetesService = DiabetesService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late DiabetesAssessment _assessment;
  bool _isLoading = false;
  bool _isEditing = false;

  // Form controllers
  final TextEditingController _diabetesTypeOtherController = TextEditingController();
  final TextEditingController _bgMonitoringMethodController = TextEditingController();
  final TextEditingController _cgmDeviceNameController = TextEditingController();
  final TextEditingController _insulinDoseDetailsController = TextEditingController();
  final TextEditingController _footCareAssessmentDetailsController = TextEditingController();
  final TextEditingController _eyeScreeningDetailsController = TextEditingController();
  final TextEditingController _dietaryManagementDetailsController = TextEditingController();
  final TextEditingController _sickDayRulesDetailsController = TextEditingController();
  final TextEditingController _whenToSeekMedicalHelpController = TextEditingController();
  final TextEditingController _monitoringRequirementsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAssessment();
  }

  @override
  void dispose() {
    _diabetesTypeOtherController.dispose();
    _bgMonitoringMethodController.dispose();
    _cgmDeviceNameController.dispose();
    _insulinDoseDetailsController.dispose();
    _footCareAssessmentDetailsController.dispose();
    _eyeScreeningDetailsController.dispose();
    _dietaryManagementDetailsController.dispose();
    _sickDayRulesDetailsController.dispose();
    _whenToSeekMedicalHelpController.dispose();
    _monitoringRequirementsController.dispose();
    super.dispose();
  }

  Future<void> _initializeAssessment() async {
    setState(() => _isLoading = true);
    try {
      if (widget.assessmentId != null) {
        final existingAssessment = await _diabetesService.getAssessmentById(widget.assessmentId!);
        if (existingAssessment != null) {
          _assessment = existingAssessment;
          _isEditing = true;
          _populateControllers();
        } else {
          _assessment = DiabetesAssessment.createNew(widget.serviceUserId, null);
        }
      } else {
        _assessment = DiabetesAssessment.createNew(widget.serviceUserId, null);
      }
    } catch (e) {
      _showError('Failed to load assessment: $e');
      _assessment = DiabetesAssessment.createNew(widget.serviceUserId, null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    _diabetesTypeOtherController.text = _assessment.diabetesTypeOther ?? '';
    _bgMonitoringMethodController.text = _assessment.bgMonitoringMethod ?? '';
    _cgmDeviceNameController.text = _assessment.cgmDeviceName ?? '';
    _insulinDoseDetailsController.text = _assessment.insulinDoseDetails ?? '';
    _footCareAssessmentDetailsController.text = _assessment.footCareAssessmentDetails ?? '';
    _eyeScreeningDetailsController.text = _assessment.eyeScreeningDetails ?? '';
    _dietaryManagementDetailsController.text = _assessment.dietaryManagementDetails ?? '';
    _sickDayRulesDetailsController.text = _assessment.sickDayRulesDetails ?? '';
    _whenToSeekMedicalHelpController.text = _assessment.whenToSeekMedicalHelp ?? '';
    _monitoringRequirementsController.text = _assessment.monitoringRequirements ?? '';
  }

  void _updateAssessmentFromForm() {
    _assessment = _assessment.copyWith(
      diabetesTypeOther: _diabetesTypeOtherController.text.isNotEmpty ? _diabetesTypeOtherController.text : null,
      bgMonitoringMethod: _bgMonitoringMethodController.text.isNotEmpty ? _bgMonitoringMethodController.text : null,
      cgmDeviceName: _cgmDeviceNameController.text.isNotEmpty ? _cgmDeviceNameController.text : null,
      insulinDoseDetails: _insulinDoseDetailsController.text.isNotEmpty ? _insulinDoseDetailsController.text : null,
      footCareAssessmentDetails: _footCareAssessmentDetailsController.text.isNotEmpty ? _footCareAssessmentDetailsController.text : null,
      eyeScreeningDetails: _eyeScreeningDetailsController.text.isNotEmpty ? _eyeScreeningDetailsController.text : null,
      dietaryManagementDetails: _dietaryManagementDetailsController.text.isNotEmpty ? _dietaryManagementDetailsController.text : null,
      sickDayRulesDetails: _sickDayRulesDetailsController.text.isNotEmpty ? _sickDayRulesDetailsController.text : null,
      whenToSeekMedicalHelp: _whenToSeekMedicalHelpController.text.isNotEmpty ? _whenToSeekMedicalHelpController.text : null,
      monitoringRequirements: _monitoringRequirementsController.text.isNotEmpty ? _monitoringRequirementsController.text : null,
    );
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    _updateAssessmentFromForm();
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _diabetesService.updateAssessment(_assessment);
      } else {
        await _diabetesService.createAssessment(_assessment);
      }

      _showSuccess('Assessment ${_isEditing ? 'updated' : 'created'} successfully');
      if (widget.onSaved != null) widget.onSaved!();
      Navigator.pop(context);
    } catch (e) {
      _showError('Failed to save assessment: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Diabetes Assessment' : 'New Diabetes Assessment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAssessment,
            tooltip: 'Save Assessment',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service User: ${widget.serviceUserName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Service User ID: ${widget.serviceUserId}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Diabetes Information
                  _buildSectionHeader('Diabetes Information'),
                  _buildDropdownField(
                    label: 'Diabetes Type',
                    value: _assessment.diabetesType,
                    items: DiabetesAssessment.getDiabetesTypes(),
                    displayText: (value) => _getDiabetesTypeDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(diabetesType: value!);
                      });
                    },
                  ),
                  if (_assessment.diabetesType == 'other')
                    _buildTextField(
                      controller: _diabetesTypeOtherController,
                      label: 'Other Diabetes Type',
                      hintText: 'Please specify',
                    ),
                  _buildDateField(
                    label: 'Diagnosis Date',
                    selectedDate: _assessment.diagnosisDate,
                    onDateChanged: (date) {
                      setState(() {
                        _assessment = _assessment.copyWith(diagnosisDate: date);
                      });
                    },
                  ),
                  _buildNumberField(
                    label: 'Last HbA1c Value (%)',
                    value: _assessment.lastHba1cValue,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(lastHba1cValue: value);
                      });
                    },
                  ),
                  _buildDateField(
                    label: 'Last HbA1c Date',
                    selectedDate: _assessment.lastHba1cDate,
                    onDateChanged: (date) {
                      setState(() {
                        _assessment = _assessment.copyWith(lastHba1cDate: date);
                      });
                    },
                  ),
                  _buildNumberField(
                    label: 'HbA1c Target (%)',
                    value: _assessment.hba1cTarget,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(hba1cTarget: value);
                      });
                    },
                  ),

                  // Blood Glucose Monitoring
                  _buildSectionHeader('Blood Glucose Monitoring'),
                  _buildDropdownField(
                    label: 'Monitoring Frequency',
                    value: _assessment.bgMonitoringFrequency,
                    items: DiabetesAssessment.getBgMonitoringFrequencies(),
                    displayText: (value) => _getBgMonitoringFrequencyDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(bgMonitoringFrequency: value!);
                      });
                    },
                  ),
                  _buildTextField(
                    controller: _bgMonitoringMethodController,
                    label: 'Monitoring Method',
                    hintText: 'e.g., Finger prick, CGM, etc.',
                  ),
                  if (_assessment.bgMonitoringFrequency == 'multiple_daily' || _assessment.bgMonitoringMethod == 'cgm')
                    _buildTextField(
                      controller: _cgmDeviceNameController,
                      label: 'CGM Device Name',
                      hintText: 'e.g., Dexcom G6, Libre, etc.',
                    ),
                  if (_assessment.bgMonitoringFrequency == 'multiple_daily' || _assessment.bgMonitoringMethod == 'cgm')
                    _buildNumberField(
                      label: 'CGM Target Range Low (mmol/L)',
                      value: _assessment.cgmTargetRangeLow,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(cgmTargetRangeLow: value);
                        });
                      },
                    ),
                  if (_assessment.bgMonitoringFrequency == 'multiple_daily' || _assessment.bgMonitoringMethod == 'cgm')
                    _buildNumberField(
                      label: 'CGM Target Range High (mmol/L)',
                      value: _assessment.cgmTargetRangeHigh,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(cgmTargetRangeHigh: value);
                        });
                      },
                    ),

                  // Medication Information
                  _buildSectionHeader('Medication Information'),
                  _buildDropdownField(
                    label: 'Insulin Regime',
                    value: _assessment.insulinRegime,
                    items: DiabetesAssessment.getInsulinRegimes(),
                    displayText: (value) => _getInsulinRegimeDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(insulinRegime: value);
                      });
                    },
                  ),
                  _buildTextField(
                    controller: _insulinDoseDetailsController,
                    label: 'Insulin Dose Details',
                    hintText: 'e.g., Total daily dose, timing, etc.',
                  ),
                  _buildMultiSelectField(
                    label: 'Oral Medications',
                    selectedItems: _assessment.oralMedications,
                    allItems: const [
                      'Metformin',
                      'Sulfonylureas',
                      'DPP-4 inhibitors',
                      'SGLT2 inhibitors',
                      'GLP-1 receptor agonists',
                      'Thiazolidinediones',
                      'Other',
                    ],
                    onSelectionChanged: (selected) {
                      setState(() {
                        _assessment = _assessment.copyWith(oralMedications: selected);
                      });
                    },
                  ),
                  _buildMultiSelectField(
                    label: 'Other Medications',
                    selectedItems: _assessment.otherMedications,
                    allItems: const [
                      'Blood pressure medications',
                      'Cholesterol medications',
                      'Pain medications',
                      'Antidepressants',
                      'Other',
                    ],
                    onSelectionChanged: (selected) {
                      setState(() {
                        _assessment = _assessment.copyWith(otherMedications: selected);
                      });
                    },
                  ),

                  // Hypoglycaemia Assessment
                  _buildSectionHeader('Hypoglycaemia Assessment'),
                  _buildDropdownField(
                    label: 'Hypoglycaemia Frequency',
                    value: _assessment.hypoglycaemiaFrequency,
                    items: DiabetesAssessment.getHypoglycaemiaFrequencies(),
                    displayText: (value) => _getHypoglycaemiaFrequencyDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(hypoglycaemiaFrequency: value!);
                      });
                    },
                  ),
                  _buildCheckboxField(
                    label: 'Symptoms Recognized',
                    value: _assessment.hypoglycaemiaSymptomsRecognized,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(hypoglycaemiaSymptomsRecognized: value!);
                      });
                    },
                  ),
                  _buildNumberField(
                    label: 'Severe Episodes (last 6 months)',
                    value: _assessment.hypoglycaemiaSevereEpisodes?.toDouble() ?? 0,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(hypoglycaemiaSevereEpisodes: value!.toInt());
                      });
                    },
                    min: 0,
                    max: 100,
                  ),
                  _buildCheckboxField(
                    label: 'Hypoglycaemia Unawareness',
                    value: _assessment.hypoglycaemiaUnawareness,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(hypoglycaemiaUnawareness: value!);
                      });
                    },
                  ),

                  // Hyperglycaemia Assessment
                  _buildSectionHeader('Hyperglycaemia Assessment'),
                  _buildDropdownField(
                    label: 'Hyperglycaemia Episodes',
                    value: _assessment.hyperglycaemiaEpisodes,
                    items: DiabetesAssessment.getHyperglycaemiaEpisodes(),
                    displayText: (value) => value ?? 'Select option',
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(hyperglycaemiaEpisodes: value);
                      });
                    },
                  ),
                  _buildCheckboxField(
                    label: 'Diabetic Ketoacidosis History',
                    value: _assessment.hyperglycaemiaKetoacidosis,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(hyperglycaemiaKetoacidosis: value!);
                      });
                    },
                  ),
                  _buildCheckboxField(
                    label: 'Hyperosmolar Hyperglycaemic State History',
                    value: _assessment.hyperglycaemiaHyperosmolar,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(hyperglycaemiaHyperosmolar: value!);
                      });
                    },
                  ),

                  // Foot Care Assessment
                  _buildSectionHeader('Foot Care Assessment'),
                  _buildDateField(
                    label: 'Foot Care Assessment Date',
                    selectedDate: _assessment.footCareAssessmentDate,
                    onDateChanged: (date) {
                      setState(() {
                        _assessment = _assessment.copyWith(footCareAssessmentDate: date);
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Foot Care Assessment Result',
                    value: _assessment.footCareAssessmentResult,
                    items: DiabetesAssessment.getFootCareResults(),
                    displayText: (value) => _getFootCareResultDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(footCareAssessmentResult: value);
                      });
                    },
                  ),
                  _buildTextField(
                    controller: _footCareAssessmentDetailsController,
                    label: 'Foot Care Assessment Details',
                    hintText: 'Detailed findings and recommendations',
                  ),
                  _buildDateField(
                    label: 'Foot Care Reminder Date',
                    selectedDate: _assessment.footCareReminderDate,
                    onDateChanged: (date) {
                      setState(() {
                        _assessment = _assessment.copyWith(footCareReminderDate: date);
                      });
                    },
                  ),
                  _buildCheckboxField(
                    label: 'Footwear Assessment Completed',
                    value: _assessment.footwearAssessment,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(footwearAssessment: value!);
                      });
                    },
                  ),
                  _buildCheckboxField(
                    label: 'Nail Care Assessment Completed',
                    value: _assessment.nailCareAssessment,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(nailCareAssessment: value!);
                      });
                    },
                  ),

                  // Eye Care Assessment
                  _buildSectionHeader('Eye Care Assessment'),
                  _buildDateField(
                    label: 'Eye Screening Date',
                    selectedDate: _assessment.eyeScreeningDate,
                    onDateChanged: (date) {
                      setState(() {
                        _assessment = _assessment.copyWith(eyeScreeningDate: date);
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Eye Screening Result',
                    value: _assessment.eyeScreeningResult,
                    items: DiabetesAssessment.getEyeScreeningResults(),
                    displayText: (value) => _getEyeScreeningResultDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(eyeScreeningResult: value);
                      });
                    },
                  ),
                  _buildTextField(
                    controller: _eyeScreeningDetailsController,
                    label: 'Eye Screening Details',
                    hintText: 'Detailed findings and recommendations',
                  ),

                  // Lifestyle Assessment
                  _buildSectionHeader('Lifestyle Assessment'),
                  _buildDropdownField(
                    label: 'Dietary Management',
                    value: _assessment.dietaryManagement,
                    items: DiabetesAssessment.getDietaryManagements(),
                    displayText: (value) => _getDietaryManagementDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(dietaryManagement: value);
                      });
                    },
                  ),
                  _buildTextField(
                    controller: _dietaryManagementDetailsController,
                    label: 'Dietary Management Details',
                    hintText: 'Specific dietary requirements and restrictions',
                  ),
                  _buildDropdownField(
                    label: 'Exercise Level',
                    value: _assessment.exerciseLevel,
                    items: DiabetesAssessment.getExerciseLevels(),
                    displayText: (value) => _getExerciseLevelDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(exerciseLevel: value);
                      });
                    },
                  ),
                  _buildTextField(
                    controller: TextEditingController(text: _assessment.exerciseFrequency ?? ''),
                    label: 'Exercise Frequency',
                    hintText: 'e.g., 3 times per week',
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(exerciseFrequency: value);
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Smoking Status',
                    value: _assessment.smokingStatus,
                    items: DiabetesAssessment.getSmokingStatuses(),
                    displayText: (value) => _getSmokingStatusDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(smokingStatus: value);
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Alcohol Consumption',
                    value: _assessment.alcoholConsumption,
                    items: DiabetesAssessment.getAlcoholConsumptions(),
                    displayText: (value) => _getAlcoholConsumptionDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(alcoholConsumption: value);
                      });
                    },
                  ),

                  // Hospital and Complications
                  _buildSectionHeader('Hospital and Complications'),
                  _buildNumberField(
                    label: 'Hospital Admissions (last year)',
                    value: (_assessment.hospitalAdmissionsLastYear as num).toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(hospitalAdmissionsLastYear: value!.toInt());
                      });
                    },
                    min: 0,
                    max: 50,
                  ),
                  _buildMultiSelectField(
                    label: 'Diabetes Complications',
                    selectedItems: _assessment.diabetesComplications,
                    allItems: DiabetesAssessment.getDiabetesComplications(),
                    onSelectionChanged: (selected) {
                      setState(() {
                        _assessment = _assessment.copyWith(diabetesComplications: selected);
                      });
                    },
                  ),
                  _buildMultiSelectField(
                    label: 'Other Health Conditions',
                    selectedItems: _assessment.otherHealthConditions,
                    allItems: const [
                      'Hypertension',
                      'Heart Disease',
                      'Kidney Disease',
                      'Obesity',
                      'Depression/Anxiety',
                      'Other',
                    ],
                    onSelectionChanged: (selected) {
                      setState(() {
                        _assessment = _assessment.copyWith(otherHealthConditions: selected);
                      });
                    },
                  ),

                  // Sick Day Rules
                  _buildSectionHeader('Sick Day Rules'),
                  _buildCheckboxField(
                    label: 'Knowledge of Sick Day Rules',
                    value: _assessment.sickDayRulesKnowledge,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(sickDayRulesKnowledge: value!);
                      });
                    },
                  ),
                  _buildCheckboxField(
                    label: 'Sick Day Rules Documented',
                    value: _assessment.sickDayRulesDocumented,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(sickDayRulesDocumented: value!);
                      });
                    },
                  ),
                  _buildTextField(
                    controller: _sickDayRulesDetailsController,
                    label: 'Sick Day Rules Details',
                    hintText: 'Specific sick day management instructions',
                  ),
                  _buildCheckboxField(
                    label: 'Knowledge of Ketone Testing',
                    value: _assessment.ketoneTestingKnowledge,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(ketoneTestingKnowledge: value!);
                      });
                    },
                  ),
                  _buildTextField(
                    controller: _whenToSeekMedicalHelpController,
                    label: 'When to Seek Medical Help',
                    hintText: 'Specific criteria for seeking medical attention',
                  ),

                  // Assessment Metadata
                  _buildSectionHeader('Assessment Metadata'),
                  _buildMultiSelectField(
                    label: 'Risk Factors Identified',
                    selectedItems: _assessment.riskFactorsIdentified,
                    allItems: const [
                      'High HbA1c',
                      'Frequent Hypoglycaemia',
                      'Foot Complications',
                      'Eye Complications',
                      'Frequent Hospital Admissions',
                      'Poor Medication Adherence',
                      'Lifestyle Factors',
                      'Other',
                    ],
                    onSelectionChanged: (selected) {
                      setState(() {
                        _assessment = _assessment.copyWith(riskFactorsIdentified: selected);
                      });
                    },
                  ),
                  _buildTextField(
                    controller: _monitoringRequirementsController,
                    label: 'Monitoring Requirements',
                    hintText: 'Specific monitoring needs and frequency',
                  ),
                  _buildDateField(
                    label: 'Next Review Date',
                    selectedDate: _assessment.nextReviewDate,
                    onDateChanged: (date) {
                      setState(() {
                        _assessment = _assessment.copyWith(nextReviewDate: date);
                      });
                    },
                  ),

                  // Status and Signatures
                  _buildSectionHeader('Status and Signatures'),
                  _buildDropdownField(
                    label: 'Overall Risk Level',
                    value: _assessment.overallRiskLevel,
                    items: DiabetesAssessment.getRiskLevels(),
                    displayText: (value) => _getRiskLevelDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(overallRiskLevel: value);
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Status',
                    value: _assessment.status,
                    items: const ['draft', 'completed', 'reviewed'],
                    displayText: (value) => _getStatusDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(status: value!);
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveAssessment,
                          child: Text(_isEditing ? 'Update Assessment' : 'Create Assessment'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // Helper methods for building form fields
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String?) displayText,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(displayText(item)),
            )).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            onSaved: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required double? value,
    required ValueChanged<double?> onChanged,
    double? min,
    double? max,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value?.toString(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'This field is required';
              final numValue = double.tryParse(value);
              if (numValue == null) return 'Please enter a valid number';
              if (min != null && numValue < min) return 'Value must be at least $min';
              if (max != null && numValue > max) return 'Value must not exceed $max';
              return null;
            },
            onSaved: (value) {
              final numValue = double.tryParse(value ?? '');
              onChanged(numValue);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime?> onDateChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null && picked != selectedDate) {
                onDateChanged(picked);
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: TextEditingController(
                  text: selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate) : '',
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxField({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMultiSelectField({
    required String label,
    required List<String> selectedItems,
    required List<String> allItems,
    required ValueChanged<List<String>> onSelectionChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: allItems.map((item) {
              final isSelected = selectedItems.contains(item);
              return FilterChip(
                label: Text(item),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedItems.add(item);
                    } else {
                      selectedItems.remove(item);
                    }
                    onSelectionChanged(selectedItems);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Helper methods for display text
  String _getDiabetesTypeDisplay(String? value) {
    switch (value) {
      case 'type1':
        return 'Type 1 Diabetes';
      case 'type2':
        return 'Type 2 Diabetes';
      case 'gestational':
        return 'Gestational Diabetes';
      case 'other':
        return 'Other Type';
      default:
        return 'Unknown';
    }
  }

  String _getBgMonitoringFrequencyDisplay(String? value) {
    switch (value) {
      case 'multiple_daily':
        return 'Multiple times daily';
      case 'once_daily':
        return 'Once daily';
      case 'few_times_week':
        return 'Few times per week';
      case 'occasionally':
        return 'Occasionally';
      case 'none':
        return 'None';
      default:
        return 'Unknown';
    }
  }

  String _getInsulinRegimeDisplay(String? value) {
    switch (value) {
      case 'basal_bolus':
        return 'Basal-Bolus (Multiple Daily Injections)';
      case 'premixed':
        return 'Premixed Insulin';
      case 'basal_only':
        return 'Basal Only';
      case 'pump':
        return 'Insulin Pump';
      case 'none':
        return 'No Insulin';
      default:
        return 'Unknown';
    }
  }

  String _getHypoglycaemiaFrequencyDisplay(String? value) {
    switch (value) {
      case 'none':
        return 'None';
      case 'monthly':
        return 'Monthly';
      case 'weekly':
        return 'Weekly';
      case 'daily':
        return 'Daily';
      case 'multiple_daily':
        return 'Multiple times daily';
      default:
        return 'Unknown';
    }
  }

  String _getFootCareResultDisplay(String? value) {
    switch (value) {
      case 'normal':
        return 'Normal';
      case 'reduced_sensation':
        return 'Reduced Sensation';
      case 'ulceration':
        return 'Ulceration';
      case 'amputation':
        return 'Amputation';
      case 'other':
        return 'Other';
      default:
        return 'Unknown';
    }
  }

  String _getEyeScreeningResultDisplay(String? value) {
    switch (value) {
      case 'normal':
        return 'Normal';
      case 'background_retinopathy':
        return 'Background Retinopathy';
      case 'preproliferative':
        return 'Preproliferative';
      case 'proliferative':
        return 'Proliferative';
      case 'maculopathy':
        return 'Maculopathy';
      case 'other':
        return 'Other';
      default:
        return 'Unknown';
    }
  }

  String _getDietaryManagementDisplay(String? value) {
    switch (value) {
      case 'unknown':
        return 'Unknown';
      case 'carb_counting':
        return 'Carbohydrate counting';
      case 'fat_monitoring':
        return 'Fat monitoring';
      case 'protein_conscious':
        return 'Protein conscious';
      case 'fluid_monitoring':
        return 'Fluid monitoring';
      default:
        return 'Unknown';
    }
  }

  String _getExerciseLevelDisplay(String? value) {
    switch (value) {
      case 'sedentary':
        return 'Sedentary';
      case 'light':
        return 'Light Activity';
      case 'moderate':
        return 'Moderate Activity';
      case 'active':
        return 'Active';
      case 'very_active':
        return 'Very Active';
      default:
        return 'Unknown';
    }
  }

  String _getSmokingStatusDisplay(String? value) {
    switch (value) {
      case 'non_smoker':
        return 'Not a smoker';
      case 'medium_smoker':
        return 'Medium smoker';
      case 'chain_smoker':
        return 'Chain smoker';
      case 'unknown':
        return 'Unknown';
      default:
        return 'Unknown';
    }
  }

  String _getAlcoholConsumptionDisplay(String? value) {
    switch (value) {
      case 'none':
        return 'None';
      case 'occasional':
        return 'Occasional';
      case 'moderate':
        return 'Moderate';
      case 'heavy':
        return 'Heavy';
      default:
        return 'Unknown';
    }
  }

  String _getRiskLevelDisplay(String? value) {
    switch (value) {
      case 'high':
        return 'High Risk';
      case 'medium':
        return 'Medium Risk';
      case 'low':
        return 'Low Risk';
      default:
        return 'Unknown';
    }
  }

  String _getStatusDisplay(String? value) {
    switch (value) {
      case 'draft':
        return 'Draft';
      case 'completed':
        return 'Completed';
      case 'reviewed':
        return 'Reviewed';
      default:
        return value ?? 'Unknown';
    }
  }
}