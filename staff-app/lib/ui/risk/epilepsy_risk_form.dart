import 'package:flutter/material.dart';
import 'package:staff_app/models/epilepsy_assessment.dart';
import 'package:staff_app/services/epilepsy_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EpilepsyRiskForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;
  final String? assessmentId; // If editing existing assessment
  final Function()? onSaved;

  const EpilepsyRiskForm({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
    this.assessmentId,
    this.onSaved,
  }) : super(key: key);

  @override
  _EpilepsyRiskFormState createState() => _EpilepsyRiskFormState();
}

class _EpilepsyRiskFormState extends State<EpilepsyRiskForm> {
  final _formKey = GlobalKey<FormState>();
  final _epilepsyService = EpilepsyService(Supabase.instance.client);
  
  // Form controllers
  final TextEditingController _seizureFrequencyDetailsController = TextEditingController();
  final TextEditingController _medicationNameController = TextEditingController();
  final TextEditingController _medicationDoseController = TextEditingController();
  final TextEditingController _warningSignsController = TextEditingController();
  final TextEditingController _postSeizureBehaviourController = TextEditingController();
  final TextEditingController _emergencyProtocolController = TextEditingController();
  final TextEditingController _rescueMedicationNameController = TextEditingController();
  final TextEditingController _rescueMedicationDoseController = TextEditingController();
  final TextEditingController _rescueMedicationResponseController = TextEditingController();
  final TextEditingController _monitoringRequirementsController = TextEditingController();

  // Form fields
  String _seizureType = 'tonic-clonic';
  String _seizureFrequency = 'weekly';
  String? _seizureFrequencyDetails;
  List<String> _seizureTriggers = [];
  DateTime? _lastSeizureDate;
  String? _medicationName;
  String? _medicationDose;
  List<String> _medicationTimes = [];
  bool _medicationCompliance = true;
  Duration? _typicalDuration;
  String? _warningSigns;
  Duration? _recoveryTime;
  String? _postSeizureBehaviour;
  List<String> _injuryRiskFactors = [];
  bool _safeguardingConcerns = false;
  List<String> _unwitnessedSeizureLocations = [];
  String _emergencyProtocol = 'Call ambulance if seizure lasts >5 minutes or multiple seizures occur';
  String? _rescueMedicationName;
  String? _rescueMedicationDose;
  bool _rescueMedicationAdministered = false;
  String? _rescueMedicationResponse;
  String? _overallRiskLevel;
  List<String> _riskFactorsIdentified = [];
  String? _monitoringRequirements;
  DateTime? _nextReviewDate;
  
  // Form state
  bool _isLoading = false;
  EpilepsyAssessment? _existingAssessment;

  @override
  void initState() {
    super.initState();
    if (widget.assessmentId != null) {
      _loadExistingAssessment();
    }
  }

  @override
  void dispose() {
    _seizureFrequencyDetailsController.dispose();
    _medicationNameController.dispose();
    _medicationDoseController.dispose();
    _warningSignsController.dispose();
    _postSeizureBehaviourController.dispose();
    _emergencyProtocolController.dispose();
    _rescueMedicationNameController.dispose();
    _rescueMedicationDoseController.dispose();
    _rescueMedicationResponseController.dispose();
    _monitoringRequirementsController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAssessment() async {
    try {
      setState(() => _isLoading = true);
      _existingAssessment = await _epilepsyService.getAssessmentById(widget.assessmentId!);
      
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

  void _populateForm(EpilepsyAssessment assessment) {
    _seizureType = assessment.seizureType;
    _seizureFrequency = assessment.seizureFrequency;
    _seizureFrequencyDetailsController.text = assessment.seizureFrequencyDetails ?? '';
    _seizureTriggers = assessment.seizureTriggers ?? [];
    _lastSeizureDate = assessment.lastSeizureDate;
    _medicationNameController.text = assessment.medicationName ?? '';
    _medicationDoseController.text = assessment.medicationDose ?? '';
    _medicationTimes = assessment.medicationTimes ?? [];
    _medicationCompliance = assessment.medicationCompliance;
    _typicalDuration = assessment.typicalDuration;
    _warningSignsController.text = assessment.warningSigns ?? '';
    _recoveryTime = assessment.recoveryTime;
    _postSeizureBehaviourController.text = assessment.postSeizureBehaviour ?? '';
    _injuryRiskFactors = assessment.injuryRiskFactors ?? [];
    _safeguardingConcerns = assessment.safeguardingConcerns;
    _unwitnessedSeizureLocations = assessment.unwitnessedSeizureLocations ?? [];
    _emergencyProtocolController.text = assessment.emergencyProtocol;
    _rescueMedicationNameController.text = assessment.rescueMedicationName ?? '';
    _rescueMedicationDoseController.text = assessment.rescueMedicationDose ?? '';
    _rescueMedicationAdministered = assessment.rescueMedicationAdministered;
    _rescueMedicationResponseController.text = assessment.rescueMedicationResponse ?? '';
    _overallRiskLevel = assessment.overallRiskLevel;
    _riskFactorsIdentified = assessment.riskFactorsIdentified ?? [];
    _monitoringRequirementsController.text = assessment.monitoringRequirements ?? '';
    _nextReviewDate = assessment.nextReviewDate;
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final assessment = EpilepsyAssessment(
        serviceUserId: widget.serviceUserId,
        assessorId: Supabase.instance.client.auth.currentUser?.id,
        seizureType: _seizureType,
        seizureFrequency: _seizureFrequency,
        seizureFrequencyDetails: _seizureFrequencyDetailsController.text.trim(),
        seizureTriggers: _seizureTriggers,
        lastSeizureDate: _lastSeizureDate,
        medicationName: _medicationNameController.text.trim(),
        medicationDose: _medicationDoseController.text.trim(),
        medicationTimes: _medicationTimes,
        medicationCompliance: _medicationCompliance,
        typicalDuration: _typicalDuration,
        warningSigns: _warningSignsController.text.trim(),
        recoveryTime: _recoveryTime,
        postSeizureBehaviour: _postSeizureBehaviourController.text.trim(),
        injuryRiskFactors: _injuryRiskFactors,
        safeguardingConcerns: _safeguardingConcerns,
        unwitnessedSeizureLocations: _unwitnessedSeizureLocations,
        emergencyProtocol: _emergencyProtocolController.text.trim(),
        rescueMedicationName: _rescueMedicationNameController.text.trim(),
        rescueMedicationDose: _rescueMedicationDoseController.text.trim(),
        rescueMedicationAdministered: _rescueMedicationAdministered,
        rescueMedicationResponse: _rescueMedicationResponseController.text.trim(),
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
        await _epilepsyService.updateAssessment(assessment);
      } else {
        // Create new assessment
        await _epilepsyService.createAssessment(assessment);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Epilepsy assessment saved successfully')),
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
        final assessment = EpilepsyAssessment(
          serviceUserId: widget.serviceUserId,
          assessorId: Supabase.instance.client.auth.currentUser?.id,
          seizureType: _seizureType,
          seizureFrequency: _seizureFrequency,
          seizureFrequencyDetails: _seizureFrequencyDetailsController.text.trim(),
          seizureTriggers: _seizureTriggers,
          lastSeizureDate: _lastSeizureDate,
          medicationName: _medicationNameController.text.trim(),
          medicationDose: _medicationDoseController.text.trim(),
          medicationTimes: _medicationTimes,
          medicationCompliance: _medicationCompliance,
          typicalDuration: _typicalDuration,
          warningSigns: _warningSignsController.text.trim(),
          recoveryTime: _recoveryTime,
          postSeizureBehaviour: _postSeizureBehaviourController.text.trim(),
          injuryRiskFactors: _injuryRiskFactors,
          safeguardingConcerns: _safeguardingConcerns,
          unwitnessedSeizureLocations: _unwitnessedSeizureLocations,
          emergencyProtocol: _emergencyProtocolController.text.trim(),
          rescueMedicationName: _rescueMedicationNameController.text.trim(),
          rescueMedicationDose: _rescueMedicationDoseController.text.trim(),
          rescueMedicationAdministered: _rescueMedicationAdministered,
          rescueMedicationResponse: _rescueMedicationResponseController.text.trim(),
          overallRiskLevel: _overallRiskLevel,
          riskFactorsIdentified: _riskFactorsIdentified,
          monitoringRequirements: _monitoringRequirementsController.text.trim(),
          nextReviewDate: _nextReviewDate,
          status: 'completed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        assessmentId = await _epilepsyService.createAssessment(assessment);
      }

      await _epilepsyService.submitAssessment(assessmentId, 'Digital Signature');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Epilepsy assessment submitted successfully')),
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

  Future<void> _selectDate({required bool isLastSeizureDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isLastSeizureDate 
          ? (_lastSeizureDate ?? DateTime.now())
          : (_nextReviewDate ?? DateTime.now().add(Duration(days: 90))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isLastSeizureDate) {
          _lastSeizureDate = picked;
        } else {
          _nextReviewDate = picked;
        }
      });
    }
  }

  Future<void> _selectDuration({required bool isTypicalDuration}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      final Duration duration = Duration(
        hours: picked.hour,
        minutes: picked.minute,
      );
      
      setState(() {
        if (isTypicalDuration) {
          _typicalDuration = duration;
        } else {
          _recoveryTime = duration;
        }
      });
    }
  }

  void _toggleTrigger(String trigger) {
    setState(() {
      if (_seizureTriggers.contains(trigger)) {
        _seizureTriggers.remove(trigger);
      } else {
        _seizureTriggers.add(trigger);
      }
    });
  }

  void _toggleInjuryRisk(String risk) {
    setState(() {
      if (_injuryRiskFactors.contains(risk)) {
        _injuryRiskFactors.remove(risk);
      } else {
        _injuryRiskFactors.add(risk);
      }
    });
  }

  void _toggleMedicationTime(String time) {
    setState(() {
      if (_medicationTimes.contains(time)) {
        _medicationTimes.remove(time);
      } else {
        _medicationTimes.add(time);
      }
    });
  }

  void _toggleUnwitnessedLocation(String location) {
    setState(() {
      if (_unwitnessedSeizureLocations.contains(location)) {
        _unwitnessedSeizureLocations.remove(location);
      } else {
        _unwitnessedSeizureLocations.add(location);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingAssessment != null 
            ? 'Edit Epilepsy Assessment' 
            : 'New Epilepsy Assessment - ${widget.serviceUserName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Seizure Information
                  _buildSectionHeader('Seizure Information'),
                  _buildDropdownField(
                    label: 'Seizure Type',
                    value: _seizureType,
                    onChanged: (value) => setState(() => _seizureType = value!),
                    items: const [
                      DropdownMenuItem(value: 'tonic-clonic', child: Text('Tonic-Clonic')),
                      DropdownMenuItem(value: 'absence', child: Text('Absence')),
                      DropdownMenuItem(value: 'focal', child: Text('Focal')),
                      DropdownMenuItem(value: 'atonic', child: Text('Atonic')),
                      DropdownMenuItem(value: 'myoclonic', child: Text('Myoclonic')),
                      DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                    ],
                  ),
                  
                  _buildDropdownField(
                    label: 'Seizure Frequency',
                    value: _seizureFrequency,
                    onChanged: (value) => setState(() => _seizureFrequency = value!),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'rarely', child: Text('Rarely')),
                      DropdownMenuItem(value: 'none', child: Text('None')),
                    ],
                  ),
                  
                  if (_seizureFrequency == 'daily' || _seizureFrequency == 'weekly')
                    _buildTextField(
                      controller: _seizureFrequencyDetailsController,
                      label: 'Frequency Details (e.g., 2-3 times per week)',
                    ),
                  
                  _buildDateField(
                    label: 'Last Seizure Date',
                    date: _lastSeizureDate,
                    onTap: () => _selectDate(isLastSeizureDate: true),
                  ),
                  
                  _buildSectionHeader('Seizure Triggers'),
                  ...EpilepsyAssessment().getCommonTriggers().map((trigger) => 
                    _buildCheckboxField(
                      label: trigger,
                      value: _seizureTriggers.contains(trigger),
                      onChanged: (value) => _toggleTrigger(trigger),
                    ),
                  ).toList(),
                  
                  _buildTextField(
                    controller: _warningSignsController,
                    label: 'Warning Signs (Aura)',
                    hintText: 'Describe any warning signs before seizures',
                  ),

                  const SizedBox(height: 20),

                  // Medication Information
                  _buildSectionHeader('Medication Information'),
                  _buildTextField(
                    controller: _medicationNameController,
                    label: 'Medication Name',
                  ),
                  
                  _buildTextField(
                    controller: _medicationDoseController,
                    label: 'Medication Dose',
                  ),
                  
                  _buildSectionHeader('Medication Times'),
                  ...['Morning', 'Afternoon', 'Evening', 'Night'].map((time) => 
                    _buildCheckboxField(
                      label: time,
                      value: _medicationTimes.contains(time.toLowerCase()),
                      onChanged: (value) => _toggleMedicationTime(time.toLowerCase()),
                    ),
                  ).toList(),
                  
                  _buildYesNoField(
                    label: 'Medication Compliance',
                    value: _medicationCompliance,
                    onChanged: (value) => setState(() => _medicationCompliance = value!),
                  ),

                  const SizedBox(height: 20),

                  // Seizure Characteristics
                  _buildSectionHeader('Seizure Characteristics'),
                  _buildDurationField(
                    label: 'Typical Duration',
                    duration: _typicalDuration,
                    onTap: () => _selectDuration(isTypicalDuration: true),
                  ),
                  
                  _buildDurationField(
                    label: 'Recovery Time',
                    duration: _recoveryTime,
                    onTap: () => _selectDuration(isTypicalDuration: false),
                  ),
                  
                  _buildTextField(
                    controller: _postSeizureBehaviourController,
                    label: 'Post-Seizure Behaviour',
                    hintText: 'Confusion, sleepiness, headache, etc.',
                  ),

                  const SizedBox(height: 20),

                  // Risk Assessment
                  _buildSectionHeader('Risk Assessment'),
                  _buildSectionHeader('Injury Risk Factors'),
                  ...EpilepsyAssessment().getCommonInjuryRisks().map((risk) => 
                    _buildCheckboxField(
                      label: risk,
                      value: _injuryRiskFactors.contains(risk),
                      onChanged: (value) => _toggleInjuryRisk(risk),
                    ),
                  ).toList(),
                  
                  _buildYesNoField(
                    label: 'Safeguarding Concerns',
                    value: _safeguardingConcerns,
                    onChanged: (value) => setState(() => _safeguardingConcerns = value!),
                  ),
                  
                  _buildSectionHeader('Unwitnessed Seizure Locations'),
                  ...['Bathroom', 'Bedroom', 'Kitchen', 'Garden', 'Outside'].map((location) => 
                    _buildCheckboxField(
                      label: location,
                      value: _unwitnessedSeizureLocations.contains(location.toLowerCase()),
                      onChanged: (value) => _toggleUnwitnessedLocation(location.toLowerCase()),
                    ),
                  ).toList(),

                  const SizedBox(height: 20),

                  // Emergency Protocol
                  _buildSectionHeader('Emergency Protocol'),
                  _buildTextField(
                    controller: _emergencyProtocolController,
                    label: 'When to Call Ambulance',
                    hintText: 'e.g., seizure >5 minutes, multiple seizures, injury',
                  ),
                  
                  _buildTextField(
                    controller: _rescueMedicationNameController,
                    label: 'Rescue Medication Name',
                  ),
                  
                  _buildTextField(
                    controller: _rescueMedicationDoseController,
                    label: 'Rescue Medication Dose',
                  ),
                  
                  _buildYesNoField(
                    label: 'Rescue Medication Administered',
                    value: _rescueMedicationAdministered,
                    onChanged: (value) => setState(() => _rescueMedicationAdministered = value!),
                  ),
                  
                  _buildTextField(
                    controller: _rescueMedicationResponseController,
                    label: 'Response to Rescue Medication',
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
                    onTap: () => _selectDate(isLastSeizureDate: false),
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

  Widget _buildDurationField({
    required String label,
    required Duration? duration,
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
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(duration != null 
                ? '${duration.inMinutes} min ${duration.inSeconds % 60} sec'
                : 'Select duration'),
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
            onChanged: onChanged,
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