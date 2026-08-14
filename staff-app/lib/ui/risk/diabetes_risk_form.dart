import 'package:flutter/material.dart';
import 'package:staff_app/models/diabetes_assessment.dart';
import 'package:staff_app/services/diabetes_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiabetesRiskForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;
  final String? assessmentId; // If editing existing assessment
  final Function()? onSaved;

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
  final _formKey = GlobalKey<FormState>();
  final _diabetesService = DiabetesService(Supabase.instance.client);
  
  // Form controllers
  final TextEditingController _diabetesTypeOtherController = TextEditingController();
  final TextEditingController _diagnosisDateController = TextEditingController();
  final TextEditingController _lastHba1cValueController = TextEditingController();
  final TextEditingController _lastHba1cDateController = TextEditingController();
  final TextEditingController _hba1cTargetController = TextEditingController();
  final TextEditingController _cgmDeviceNameController = TextEditingController();
  final TextEditingController _cgmTargetRangeLowController = TextEditingController();
  final TextEditingController _cgmTargetRangeHighController = TextEditingController();
  final TextEditingController _insulinTypeController = TextEditingController();
  final TextEditingController _insulinDoseDetailsController = TextEditingController();
  final TextEditingController _oralMedicationsController = TextEditingController();
  final TextEditingController _otherMedicationsController = TextEditingController();
  final TextEditingController _hypoglycaemiaSevereEpisodesController = TextEditingController();
  final TextEditingController _hyperglycaemiaKetoacidosisController = TextEditingController();
  final TextEditingController _hyperglycaemiaHyperosmolarController = TextEditingController();
  final TextEditingController _footCareAssessmentDetailsController = TextEditingController();
  final TextEditingController _footCareReminderDateController = TextEditingController();
  final TextEditingController _eyeScreeningDetailsController = TextEditingController();
  final TextEditingController _dietaryManagementDetailsController = TextEditingController();
  final TextEditingController _exerciseFrequencyController = TextEditingController();
  final TextEditingController _hospitalAdmissionReasonsController = TextEditingController();
  final TextEditingController _diabetesComplicationsController = TextEditingController();
  final TextEditingController _otherHealthConditionsController = TextEditingController();
  final TextEditingController _sickDayRulesDetailsController = TextEditingController();
  final TextEditingController _whenToSeekMedicalHelpController = TextEditingController();
  final TextEditingController _monitoringRequirementsController = TextEditingController();
  final TextEditingController _nextReviewDateController = TextEditingController();

  // Form fields
  String _diabetesType = 'type2';
  String? _diabetesTypeOther;
  DateTime? _diagnosisDate;
  double? _lastHba1cValue;
  DateTime? _lastHba1cDate;
  double? _hba1cTarget;
  String _bgMonitoringFrequency = 'multiple_daily';
  String? _bgMonitoringMethod;
  String? _cgmDeviceName;
  double? _cgmTargetRangeLow;
  double? _cgmTargetRangeHigh;
  String? _insulinRegime;
  String? _insulinType;
  String? _insulinDoseDetails;
  List<String> _oralMedications = [];
  List<String> _otherMedications = [];
  String _hypoglycaemiaFrequency = 'none';
  bool _hypoglycaemiaSymptomsRecognized = true;
  int _hypoglycaemiaSevereEpisodes = 0;
  bool _hypoglycaemiaUnawareness = false;
  String? _hyperglycaemiaEpisodes;
  bool _hyperglycaemiaKetoacidosis = false;
  bool _hyperglycaemiaHyperosmolar = false;
  DateTime? _footCareAssessmentDate;
  String? _footCareAssessmentResult;
  String? _footCareAssessmentDetails;
  DateTime? _footCareReminderDate;
  bool _footwearAssessment = false;
  bool _nailCareAssessment = false;
  DateTime? _eyeScreeningDate;
  String? _eyeScreeningResult;
  String? _eyeScreeningDetails;
  String? _dietaryManagement;
  String? _dietaryManagementDetails;
  String? _exerciseLevel;
  String? _exerciseFrequency;
  String? _smokingStatus;
  String? _alcoholConsumption;
  int _hospitalAdmissionsLastYear = 0;
  List<String> _hospitalAdmissionReasons = [];
  List<String> _diabetesComplications = [];
  List<String> _otherHealthConditions = [];
  bool _sickDayRulesKnowledge = false;
  bool _sickDayRulesDocumented = false;
  String? _sickDayRulesDetails;
  bool _ketoneTestingKnowledge = false;
  String? _whenToSeekMedicalHelp;
  String? _overallRiskLevel;
  List<String> _riskFactorsIdentified = [];
  String? _monitoringRequirements;
  DateTime? _nextReviewDate;
  
  // Form state
  bool _isLoading = false;
  DiabetesAssessment? _existingAssessment;

  @override
  void initState() {
    super.initState();
    if (widget.assessmentId != null) {
      _loadExistingAssessment();
    }
  }

  @override
  void dispose() {
    _diabetesTypeOtherController.dispose();
    _diagnosisDateController.dispose();
    _lastHba1cValueController.dispose();
    _lastHba1cDateController.dispose();
    _hba1cTargetController.dispose();
    _cgmDeviceNameController.dispose();
    _cgmTargetRangeLowController.dispose();
    _cgmTargetRangeHighController.dispose();
    _insulinTypeController.dispose();
    _insulinDoseDetailsController.dispose();
    _oralMedicationsController.dispose();
    _otherMedicationsController.dispose();
    _hypoglycaemiaSevereEpisodesController.dispose();
    _hyperglycaemiaKetoacidosisController.dispose();
    _hyperglycaemiaHyperosmolarController.dispose();
    _footCareAssessmentDetailsController.dispose();
    _footCareReminderDateController.dispose();
    _eyeScreeningDetailsController.dispose();
    _dietaryManagementDetailsController.dispose();
    _exerciseFrequencyController.dispose();
    _hospitalAdmissionReasonsController.dispose();
    _diabetesComplicationsController.dispose();
    _otherHealthConditionsController.dispose();
    _sickDayRulesDetailsController.dispose();
    _whenToSeekMedicalHelpController.dispose();
    _monitoringRequirementsController.dispose();
    _nextReviewDateController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAssessment() async {
    try {
      setState(() => _isLoading = true);
      _existingAssessment = await _diabetesService.getAssessmentById(widget.assessmentId!);
      
      if (_existingAssessment != null) {
        _populateForm(_existingAssessment!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load assessment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateForm(DiabetesAssessment assessment) {
    _diabetesType = assessment.diabetesType;
    _diabetesTypeOtherController.text = assessment.diabetesTypeOther ?? '';
    _diagnosisDate = assessment.diagnosisDate;
    _lastHba1cValueController.text = assessment.lastHba1cValue?.toString() ?? '';
    _lastHba1cDate = assessment.lastHba1cDate;
    _hba1cTargetController.text = assessment.hba1cTarget?.toString() ?? '';
    _bgMonitoringFrequency = assessment.bgMonitoringFrequency;
    _bgMonitoringMethod = assessment.bgMonitoringMethod;
    _cgmDeviceNameController.text = assessment.cgmDeviceName ?? '';
    _cgmTargetRangeLowController.text = assessment.cgmTargetRangeLow?.toString() ?? '';
    _cgmTargetRangeHighController.text = assessment.cgmTargetRangeHigh?.toString() ?? '';
    _insulinRegime = assessment.insulinRegime;
    _insulinTypeController.text = assessment.insulinType ?? '';
    _insulinDoseDetailsController.text = assessment.insulinDoseDetails ?? '';
    _oralMedications = assessment.oralMedications;
    _otherMedications = assessment.otherMedications;
    _hypoglycaemiaFrequency = assessment.hypoglycaemiaFrequency;
    _hypoglycaemiaSymptomsRecognized = assessment.hypoglycaemiaSymptomsRecognized;
    _hypoglycaemiaSevereEpisodes = assessment.hypoglycaemiaSevereEpisodes;
    _hypoglycaemiaUnawareness = assessment.hypoglycaemiaUnawareness;
    _hyperglycaemiaEpisodes = assessment.hyperglycaemiaEpisodes;
    _hyperglycaemiaKetoacidosis = assessment.hyperglycaemiaKetoacidosis;
    _hyperglycaemiaHyperosmolar = assessment.hyperglycaemiaHyperosmolar;
    _footCareAssessmentDate = assessment.footCareAssessmentDate;
    _footCareAssessmentResult = assessment.footCareAssessmentResult;
    _footCareAssessmentDetailsController.text = assessment.footCareAssessmentDetails ?? '';
    _footCareReminderDate = assessment.footCareReminderDate;
    _footwearAssessment = assessment.footwearAssessment;
    _nailCareAssessment = assessment.nailCareAssessment;
    _eyeScreeningDate = assessment.eyeScreeningDate;
    _eyeScreeningResult = assessment.eyeScreeningResult;
    _eyeScreeningDetailsController.text = assessment.eyeScreeningDetails ?? '';
    _dietaryManagement = assessment.dietaryManagement;
    _dietaryManagementDetailsController.text = assessment.dietaryManagementDetails ?? '';
    _exerciseLevel = assessment.exerciseLevel;
    _exerciseFrequencyController.text = assessment.exerciseFrequency ?? '';
    _smokingStatus = assessment.smokingStatus;
    _alcoholConsumption = assessment.alcoholConsumption;
    _hospitalAdmissionsLastYear = assessment.hospitalAdmissionsLastYear;
    _hospitalAdmissionReasons = assessment.hospitalAdmissionReasons;
    _diabetesComplications = assessment.diabetesComplications;
    _otherHealthConditions = assessment.otherHealthConditions;
    _sickDayRulesKnowledge = assessment.sickDayRulesKnowledge;
    _sickDayRulesDocumented = assessment.sickDayRulesDocumented;
    _sickDayRulesDetailsController.text = assessment.sickDayRulesDetails ?? '';
    _ketoneTestingKnowledge = assessment.ketoneTestingKnowledge;
    _whenToSeekMedicalHelpController.text = assessment.whenToSeekMedicalHelp ?? '';
    _overallRiskLevel = assessment.overallRiskLevel;
    _riskFactorsIdentified = assessment.riskFactorsIdentified;
    _monitoringRequirementsController.text = assessment.monitoringRequirements ?? '';
    _nextReviewDate = assessment.nextReviewDate;
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final assessment = DiabetesAssessment(
        serviceUserId: widget.serviceUserId,
        assessorId: Supabase.instance.client.auth.currentUser?.id,
        diabetesType: _diabetesType,
        diabetesTypeOther: _diabetesType == 'other' ? _diabetesTypeOtherController.text.trim() : null,
        diagnosisDate: _diagnosisDate,
        lastHba1cValue: _lastHba1cValue,
        lastHba1cDate: _lastHba1cDate,
        hba1cTarget: _hba1cTarget,
        bgMonitoringFrequency: _bgMonitoringFrequency,
        bgMonitoringMethod: _bgMonitoringMethod,
        cgmDeviceName: _cgmDeviceNameController.text.trim(),
        cgmTargetRangeLow: _cgmTargetRangeLow,
        cgmTargetRangeHigh: _cgmTargetRangeHigh,
        insulinRegime: _insulinRegime,
        insulinType: _insulinTypeController.text.trim(),
        insulinDoseDetails: _insulinDoseDetailsController.text.trim(),
        oralMedications: _oralMedications,
        otherMedications: _otherMedications,
        hypoglycaemiaFrequency: _hypoglycaemiaFrequency,
        hypoglycaemiaSymptomsRecognized: _hypoglycaemiaSymptomsRecognized,
        hypoglycaemiaSevereEpisodes: _hypoglycaemiaSevereEpisodes,
        hypoglycaemiaUnawareness: _hypoglycaemiaUnawareness,
        hyperglycaemiaEpisodes: _hyperglycaemiaEpisodes,
        hyperglycaemiaKetoacidosis: _hyperglycaemiaKetoacidosis,
        hyperglycaemiaHyperosmolar: _hyperglycaemiaHyperosmolar,
        footCareAssessmentDate: _footCareAssessmentDate,
        footCareAssessmentResult: _footCareAssessmentResult,
        footCareAssessmentDetails: _footCareAssessmentDetailsController.text.trim(),
        footCareReminderDate: _footCareReminderDate,
        footwearAssessment: _footwearAssessment,
        nailCareAssessment: _nailCareAssessment,
        eyeScreeningDate: _eyeScreeningDate,
        eyeScreeningResult: _eyeScreeningResult,
        eyeScreeningDetails: _eyeScreeningDetailsController.text.trim(),
        dietaryManagement: _dietaryManagement,
        dietaryManagementDetails: _dietaryManagementDetailsController.text.trim(),
        exerciseLevel: _exerciseLevel,
        exerciseFrequency: _exerciseFrequencyController.text.trim(),
        smokingStatus: _smokingStatus,
        alcoholConsumption: _alcoholConsumption,
        hospitalAdmissionsLastYear: _hospitalAdmissionsLastYear,
        hospitalAdmissionReasons: _hospitalAdmissionReasons,
        diabetesComplications: _diabetesComplications,
        otherHealthConditions: _otherHealthConditions,
        sickDayRulesKnowledge: _sickDayRulesKnowledge,
        sickDayRulesDocumented: _sickDayRulesDocumented,
        sickDayRulesDetails: _sickDayRulesDetailsController.text.trim(),
        ketoneTestingKnowledge: _ketoneTestingKnowledge,
        whenToSeekMedicalHelp: _whenToSeekMedicalHelpController.text.trim(),
        overallRiskLevel: _overallRiskLevel,
        riskFactorsIdentified: _riskFactorsIdentified,
        monitoringRequirements: _monitoringRequirementsController.text.trim(),
        nextReviewDate: _nextReviewDate,
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_existingAssessment != null) {
        // Update existing assessment
        await _diabetesService.updateAssessment(assessment);
      } else {
        // Create new assessment
        await _diabetesService.createAssessment(assessment);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diabetes assessment saved successfully')),
      );
      
      if (widget.onSaved != null) {
        widget.onSaved!();
      }
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save assessment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String assessmentId;
      if (_existingAssessment != null) {
        assessmentId = _existingAssessment!.id!;
      } else {
        final assessment = DiabetesAssessment(
          serviceUserId: widget.serviceUserId,
          assessorId: Supabase.instance.client.auth.currentUser?.id,
          diabetesType: _diabetesType,
          diabetesTypeOther: _diabetesType == 'other' ? _diabetesTypeOtherController.text.trim() : null,
          diagnosisDate: _diagnosisDate,
          lastHba1cValue: _lastHba1cValue,
          lastHba1cDate: _lastHba1cDate,
          hba1cTarget: _hba1cTarget,
          bgMonitoringFrequency: _bgMonitoringFrequency,
          bgMonitoringMethod: _bgMonitoringMethod,
          cgmDeviceName: _cgmDeviceNameController.text.trim(),
          cgmTargetRangeLow: _cgmTargetRangeLow,
          cgmTargetRangeHigh: _cgmTargetRangeHigh,
          insulinRegime: _insulinRegime,
          insulinType: _insulinTypeController.text.trim(),
          insulinDoseDetails: _insulinDoseDetailsController.text.trim(),
          oralMedications: _oralMedications,
          otherMedications: _otherMedications,
          hypoglycaemiaFrequency: _hypoglycaemiaFrequency,
          hypoglycaemiaSymptomsRecognized: _hypoglycaemiaSymptomsRecognized,
          hypoglycaemiaSevereEpisodes: _hypoglycaemiaSevereEpisodes,
          hypoglycaemiaUnawareness: _hypoglycaemiaUnawareness,
          hyperglycaemiaEpisodes: _hyperglycaemiaEpisodes,
          hyperglycaemiaKetoacidosis: _hyperglycaemiaKetoacidosis,
          hyperglycaemiaHyperosmolar: _hyperglycaemiaHyperosmolar,
          footCareAssessmentDate: _footCareAssessmentDate,
          footCareAssessmentResult: _footCareAssessmentResult,
          footCareAssessmentDetails: _footCareAssessmentDetailsController.text.trim(),
          footCareReminderDate: _footCareReminderDate,
          footwearAssessment: _footwearAssessment,
          nailCareAssessment: _nailCareAssessment,
          eyeScreeningDate: _eyeScreeningDate,
          eyeScreeningResult: _eyeScreeningResult,
          eyeScreeningDetails: _eyeScreeningDetailsController.text.trim(),
          dietaryManagement: _dietaryManagement,
          dietaryManagementDetails: _dietaryManagementDetailsController.text.trim(),
          exerciseLevel: _exerciseLevel,
          exerciseFrequency: _exerciseFrequencyController.text.trim(),
          smokingStatus: _smokingStatus,
          alcoholConsumption: _alcoholConsumption,
          hospitalAdmissionsLastYear: _hospitalAdmissionsLastYear,
          hospitalAdmissionReasons: _hospitalAdmissionReasons,
          diabetesComplications: _diabetesComplications,
          otherHealthConditions: _otherHealthConditions,
          sickDayRulesKnowledge: _sickDayRulesKnowledge,
          sickDayRulesDocumented: _sickDayRulesDocumented,
          sickDayRulesDetails: _sickDayRulesDetailsController.text.trim(),
          ketoneTestingKnowledge: _ketoneTestingKnowledge,
          whenToSeekMedicalHelp: _whenToSeekMedicalHelpController.text.trim(),
          overallRiskLevel: _overallRiskLevel,
          riskFactorsIdentified: _riskFactorsIdentified,
          monitoringRequirements: _monitoringRequirementsController.text.trim(),
          nextReviewDate: _nextReviewDate,
          status: 'completed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        assessmentId = await _diabetesService.createAssessment(assessment);
      }

      await _diabetesService.submitAssessment(assessmentId, 'Digital Signature');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diabetes assessment submitted successfully')),
      );
      
      if (widget.onSaved != null) {
        widget.onSaved!();
      }
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit assessment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate({required bool isDiagnosisDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDiagnosisDate 
          ? (_diagnosisDate ?? DateTime.now())
          : (_nextReviewDate ?? DateTime.now().add(Duration(days: 90))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isDiagnosisDate) {
          _diagnosisDate = picked;
        } else {
          _nextReviewDate = picked;
        }
      });
    }
  }

  Future<void> _selectLastHba1cDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastHba1cDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() => _lastHba1cDate = picked);
    }
  }

  Future<void> _selectFootCareDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _footCareAssessmentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() => _footCareAssessmentDate = picked);
    }
  }

  Future<void> _selectEyeScreeningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eyeScreeningDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() => _eyeScreeningDate = picked);
    }
  }

  void _toggleOralMedication(String medication) {
    setState(() {
      if (_oralMedications.contains(medication)) {
        _oralMedications.remove(medication);
      } else {
        _oralMedications.add(medication);
      }
    });
  }

  void _toggleOtherMedication(String medication) {
    setState(() {
      if (_otherMedications.contains(medication)) {
        _otherMedications.remove(medication);
      } else {
        _otherMedications.add(medication);
      }
    });
  }

  void _toggleDiabetesComplication(String complication) {
    setState(() {
      if (_diabetesComplications.contains(complication)) {
        _diabetesComplications.remove(complication);
      } else {
        _diabetesComplications.add(complication);
      }
    });
  }

  void _toggleHealthCondition(String condition) {
    setState(() {
      if (_otherHealthConditions.contains(condition)) {
        _otherHealthConditions.remove(condition);
      } else {
        _otherHealthConditions.add(condition);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingAssessment != null 
            ? 'Edit Diabetes Assessment' 
            : 'New Diabetes Assessment - ${widget.serviceUserName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Diabetes Information
                  _buildSectionHeader('Diabetes Information'),
                  _buildDropdownField(
                    label: 'Diabetes Type',
                    value: _diabetesType,
                    onChanged: (value) => setState(() => _diabetesType = value!),
                    items: const [
                      DropdownMenuItem(value: 'type1', child: Text('Type 1 Diabetes')),
                      DropdownMenuItem(value: 'type2', child: Text('Type 2 Diabetes')),
                      DropdownMenuItem(value: 'gestational', child: Text('Gestational Diabetes')),
                      DropdownMenuItem(value: 'other', child: Text('Other Type')),
                    ],
                  ),
                  
                  if (_diabetesType == 'other')
                    _buildTextField(
                      controller: _diabetesTypeOtherController,
                      label: 'Specify Other Type',
                    ),
                  
                  _buildDateField(
                    label: 'Diagnosis Date',
                    date: _diagnosisDate,
                    onTap: () => _selectDate(isDiagnosisDate: true),
                  ),
                  
                  _buildTextField(
                    controller: _lastHba1cValueController,
                    label: 'Last HbA1c Value (%)',
                    hintText: 'e.g., 7.5',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  
                  _buildDateField(
                    label: 'Last HbA1c Date',
                    date: _lastHba1cDate,
                    onTap: _selectLastHba1cDate,
                  ),
                  
                  _buildTextField(
                    controller: _hba1cTargetController,
                    label: 'HbA1c Target (%)',
                    hintText: 'e.g., 7.0',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),

                  const SizedBox(height: 20),

                  // Blood Glucose Monitoring
                  _buildSectionHeader('Blood Glucose Monitoring'),
                  _buildDropdownField(
                    label: 'Monitoring Frequency',
                    value: _bgMonitoringFrequency,
                    onChanged: (value) => setState(() => _bgMonitoringFrequency = value!),
                    items: const [
                      DropdownMenuItem(value: 'multiple_daily', child: Text('Multiple times daily')),
                      DropdownMenuItem(value: 'once_daily', child: Text('Once daily')),
                      DropdownMenuItem(value: 'few_times_week', child: Text('Few times per week')),
                      DropdownMenuItem(value: 'occasionally', child: Text('Occasionally')),
                      DropdownMenuItem(value: 'none', child: Text('None')),
                    ],
                  ),
                  
                  _buildDropdownField(
                    label: 'Monitoring Method',
                    value: _bgMonitoringMethod,
                    onChanged: (value) => setState(() => _bgMonitoringMethod = value),
                    items: const [
                      DropdownMenuItem(value: 'finger_prick', child: Text('Finger Prick')),
                      DropdownMenuItem(value: 'cgm', child: Text('Continuous Glucose Monitor')),
                      DropdownMenuItem(value: 'both', child: Text('Both')),
                    ],
                  ),
                  
                  if (_bgMonitoringMethod == 'cgm' || _bgMonitoringMethod == 'both')
                    _buildTextField(
                      controller: _cgmDeviceNameController,
                      label: 'CGM Device Name',
                    ),
                  
                  if (_bgMonitoringMethod == 'cgm' || _bgMonitoringMethod == 'both')
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cgmTargetRangeLowController,
                            label: 'CGM Target Range Low (%)',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _cgmTargetRangeHighController,
                            label: 'CGM Target Range High (%)',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Medication Information
                  _buildSectionHeader('Medication Information'),
                  _buildDropdownField(
                    label: 'Insulin Regime',
                    value: _insulinRegime,
                    onChanged: (value) => setState(() => _insulinRegime = value),
                    items: const [
                      DropdownMenuItem(value: 'basal_bolus', child: Text('Basal-Bolus (Multiple Daily Injections)')),
                      DropdownMenuItem(value: 'premixed', child: Text('Premixed Insulin')),
                      DropdownMenuItem(value: 'basal_only', child: Text('Basal Only')),
                      DropdownMenuItem(value: 'pump', child: Text('Insulin Pump')),
                      DropdownMenuItem(value: 'none', child: Text('No Insulin')),
                    ],
                  ),
                  
                  if (_insulinRegime != 'none' && _insulinRegime != null)
                    _buildTextField(
                      controller: _insulinTypeController,
                      label: 'Insulin Type',
                    ),
                  
                  if (_insulinRegime != 'none' && _insulinRegime != null)
                    _buildTextField(
                      controller: _insulinDoseDetailsController,
                      label: 'Insulin Dose Details',
                      hintText: 'e.g., 20 units morning, 15 units evening',
                    ),

                  _buildSectionHeader('Oral Medications'),
                  ...DiabetesAssessment.getDiabetesComplications().map((medication) => 
                    _buildCheckboxField(
                      label: medication,
                      value: _oralMedications.contains(medication),
                      onChanged: (value) => _toggleOralMedication(medication),
                    ),
                  ).toList(),
                  
                  _buildTextField(
                    controller: _otherMedicationsController,
                    label: 'Other Diabetes Medications',
                    hintText: 'List any other medications',
                  ),

                  const SizedBox(height: 20),

                  // Hypoglycaemia Assessment
                  _buildSectionHeader('Hypoglycaemia Assessment'),
                  _buildDropdownField(
                    label: 'Hypoglycaemia Frequency',
                    value: _hypoglycaemiaFrequency,
                    onChanged: (value) => setState(() => _hypoglycaemiaFrequency = value!),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('None')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'multiple_daily', child: Text('Multiple times daily')),
                    ],
                  ),
                  
                  _buildYesNoField(
                    label: 'Symptoms Recognized',
                    value: _hypoglycaemiaSymptomsRecognized,
                    onChanged: (value) => setState(() => _hypoglycaemiaSymptomsRecognized = value!),
                  ),
                  
                  _buildTextField(
                    controller: _hypoglycaemiaSevereEpisodesController,
                    label: 'Severe Episodes (last 6 months)',
                    hintText: 'Number of severe episodes',
                    keyboardType: TextInputType.number,
                  ),
                  
                  _buildYesNoField(
                    label: 'Hypoglycaemia Unawareness',
                    value: _hypoglycaemiaUnawareness,
                    onChanged: (value) => setState(() => _hypoglycaemiaUnawareness = value!),
                  ),

                  const SizedBox(height: 20),

                  // Hyperglycaemia Assessment
                  _buildSectionHeader('Hyperglycaemia Assessment'),
                  _buildDropdownField(
                    label: 'Hyperglycaemia Episodes',
                    value: _hyperglycaemiaEpisodes,
                    onChanged: (value) => setState(() => _hyperglycaemiaEpisodes = value),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('None')),
                      DropdownMenuItem(value: 'occasional', child: Text('Occasional')),
                      DropdownMenuItem(value: 'frequent', child: Text('Frequent')),
                      DropdownMenuItem(value: 'always', child: Text('Always')),
                    ],
                  ),
                  
                  _buildYesNoField(
                    label: 'Ketoacidosis Episodes',
                    value: _hyperglycaemiaKetoacidosis,
                    onChanged: (value) => setState(() => _hyperglycaemiaKetoacidosis = value!),
                  ),
                  
                  _buildYesNoField(
                    label: 'Hyperosmolar Episodes',
                    value: _hyperglycaemiaHyperosmolar,
                    onChanged: (value) => setState(() => _hyperglycaemiaHyperosmolar = value!),
                  ),

                  const SizedBox(height: 20),

                  // Foot Care Assessment
                  _buildSectionHeader('Foot Care Assessment'),
                  _buildDateField(
                    label: 'Assessment Date',
                    date: _footCareAssessmentDate,
                    onTap: _selectFootCareDate,
                  ),
                  
                  _buildDropdownField(
                    label: 'Assessment Result',
                    value: _footCareAssessmentResult,
                    onChanged: (value) => setState(() => _footCareAssessmentResult = value),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'reduced_sensation', child: Text('Reduced Sensation')),
                      DropdownMenuItem(value: 'ulceration', child: Text('Ulceration')),
                      DropdownMenuItem(value: 'amputation', child: Text('Amputation')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                  ),
                  
                  _buildTextField(
                    controller: _footCareAssessmentDetailsController,
                    label: 'Assessment Details',
                  ),
                  
                  _buildDateField(
                    label: 'Next Foot Assessment Due',
                    date: _footCareReminderDate,
                    onTap: () => _selectDate(isDiagnosisDate: false),
                  ),
                  
                  _buildYesNoField(
                    label: 'Footwear Assessment',
                    value: _footwearAssessment,
                    onChanged: (value) => setState(() => _footwearAssessment = value!),
                  ),
                  
                  _buildYesNoField(
                    label: 'Nail Care Assessment',
                    value: _nailCareAssessment,
                    onChanged: (value) => setState(() => _nailCareAssessment = value!),
                  ),

                  const SizedBox(height: 20),

                  // Eye Care Assessment
                  _buildSectionHeader('Eye Care Assessment'),
                  _buildDateField(
                    label: 'Screening Date',
                    date: _eyeScreeningDate,
                    onTap: _selectEyeScreeningDate,
                  ),
                  
                  _buildDropdownField(
                    label: 'Screening Result',
                    value: _eyeScreeningResult,
                    onChanged: (value) => setState(() => _eyeScreeningResult = value),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'background_retinopathy', child: Text('Background Retinopathy')),
                      DropdownMenuItem(value: 'preproliferative', child: Text('Preproliferative')),
                      DropdownMenuItem(value: 'proliferative', child: Text('Proliferative')),
                      DropdownMenuItem(value: 'maculopathy', child: Text('Maculopathy')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                  ),
                  
                  _buildTextField(
                    controller: _eyeScreeningDetailsController,
                    label: 'Screening Details',
                  ),

                  const SizedBox(height: 20),

                  // Lifestyle Assessment
                  _buildSectionHeader('Lifestyle Assessment'),
                  _buildDropdownField(
                    label: 'Dietary Management',
                    value: _dietaryManagement,
                    onChanged: (value) => setState(() => _dietaryManagement = value),
                    items: const [
                      DropdownMenuItem(value: 'diet_controlled', child: Text('Diet Controlled')),
                      DropdownMenuItem(value: 'carb_counting', child: Text('Carbohydrate Counting')),
                      DropdownMenuItem(value: 'meal_planning', child: Text('Meal Planning')),
                      DropdownMenuItem(value: 'dietitian_input', child: Text('Dietitian Input')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                  ),
                  
                  _buildTextField(
                    controller: _dietaryManagementDetailsController,
                    label: 'Dietary Management Details',
                  ),
                  
                  _buildDropdownField(
                    label: 'Exercise Level',
                    value: _exerciseLevel,
                    onChanged: (value) => setState(() => _exerciseLevel = value),
                    items: const [
                      DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
                      DropdownMenuItem(value: 'light', child: Text('Light Activity')),
                      DropdownMenuItem(value: 'moderate', child: Text('Moderate Activity')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'very_active', child: Text('Very Active')),
                    ],
                  ),
                  
                  _buildTextField(
                    controller: _exerciseFrequencyController,
                    label: 'Exercise Frequency',
                    hintText: 'e.g., 3 times per week',
                  ),
                  
                  _buildDropdownField(
                    label: 'Smoking Status',
                    value: _smokingStatus,
                    onChanged: (value) => setState(() => _smokingStatus = value),
                    items: const [
                      DropdownMenuItem(value: 'non_smoker', child: Text('Non-smoker')),
                      DropdownMenuItem(value: 'current_smoker', child: Text('Current Smoker')),
                      DropdownMenuItem(value: 'ex_smoker', child: Text('Ex-smoker')),
                    ],
                  ),
                  
                  _buildDropdownField(
                    label: 'Alcohol Consumption',
                    value: _alcoholConsumption,
                    onChanged: (value) => setState(() => _alcoholConsumption = value),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('None')),
                      DropdownMenuItem(value: 'occasional', child: Text('Occasional')),
                      DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                      DropdownMenuItem(value: 'heavy', child: Text('Heavy')),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Hospital and Complications
                  _buildSectionHeader('Hospital and Complications'),
                  _buildTextField(
                    controller: TextEditingController(text: _hospitalAdmissionsLastYear.toString()),
                    label: 'Hospital Admissions (last year)',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _hospitalAdmissionsLastYear = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  
                  _buildTextField(
                    controller: _hospitalAdmissionReasonsController,
                    label: 'Admission Reasons',
                    hintText: 'List reasons for hospitalization',
                  ),
                  
                  _buildSectionHeader('Diabetes Complications'),
                  ...DiabetesAssessment.getDiabetesComplications().map((complication) => 
                    _buildCheckboxField(
                      label: complication,
                      value: _diabetesComplications.contains(complication),
                      onChanged: (value) => _toggleDiabetesComplication(complication),
                    ),
                  ).toList(),
                  
                  _buildTextField(
                    controller: _otherHealthConditionsController,
                    label: 'Other Health Conditions',
                    hintText: 'List other relevant conditions',
                  ),

                  const SizedBox(height: 20),

                  // Sick Day Rules
                  _buildSectionHeader('Sick Day Rules'),
                  _buildYesNoField(
                    label: 'Knowledge of Sick Day Rules',
                    value: _sickDayRulesKnowledge,
                    onChanged: (value) => setState(() => _sickDayRulesKnowledge = value!),
                  ),
                  
                  _buildYesNoField(
                    label: 'Rules Documented',
                    value: _sickDayRulesDocumented,
                    onChanged: (value) => setState(() => _sickDayRulesDocumented = value!),
                  ),
                  
                  _buildTextField(
                    controller: _sickDayRulesDetailsController,
                    label: 'Sick Day Rules Details',
                  ),
                  
                  _buildYesNoField(
                    label: 'Ketone Testing Knowledge',
                    value: _ketoneTestingKnowledge,
                    onChanged: (value) => setState(() => _ketoneTestingKnowledge = value!),
                  ),
                  
                  _buildTextField(
                    controller: _whenToSeekMedicalHelpController,
                    label: 'When to Seek Medical Help',
                    hintText: 'e.g., HbA1c >10%, persistent vomiting',
                  ),

                  const SizedBox(height: 20),

                  // Assessment Metadata
                  _buildSectionHeader('Assessment Metadata'),
                  _buildDropdownField(
                    label: 'Overall Risk Level',
                    value: _overallRiskLevel,
                    onChanged: (value) => setState(() => _overallRiskLevel = value),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                  ),
                  
                  _buildTextField(
                    controller: _monitoringRequirementsController,
                    label: 'Monitoring Requirements',
                  ),
                  
                  _buildDateField(
                    label: 'Next Review Date',
                    date: _nextReviewDate,
                    onTap: () => _selectDate(isDiagnosisDate: false),
                  ),

                  const SizedBox(height: 30),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveAssessment,
                          child: const Text('Save Draft'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitAssessment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<DropdownMenuItem<String>> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(date?.toLocal().toIso8601String().split('T').first ?? 'Select date'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (bool? newValue) => onChanged(newValue ?? false),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildYesNoField({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 20),
          Row(
            children: [
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                  const Text('Yes'),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                  const Text('No'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}