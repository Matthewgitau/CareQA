import 'package:flutter/material.dart';
import 'package:staff_app/models/catheter_care_assessment.dart';
import 'package:staff_app/services/catheter_care_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatheterCareForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;
  final String? assessmentId; // If editing existing assessment
  final Function()? onSaved;

  const CatheterCareForm({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
    this.assessmentId,
    this.onSaved,
  }) : super(key: key);

  @override
  _CatheterCareFormState createState() => _CatheterCareFormState();
}

class _CatheterCareFormState extends State<CatheterCareForm> {
  final _formKey = GlobalKey<FormState>();
  final _catheterService = CatheterCareService(Supabase.instance.client);
  
  // Form controllers
  final TextEditingController _catheterSizeController = TextEditingController();
  final TextEditingController _balloonVolumeController = TextEditingController();
  final TextEditingController _urineAppearanceNotesController = TextEditingController();
  final TextEditingController _infectionNotesController = TextEditingController();
  final TextEditingController _skinConditionNotesController = TextEditingController();
  final TextEditingController _drainageNotesController = TextEditingController();
  final TextEditingController _patientComplaintsController = TextEditingController();
  final TextEditingController _actionsDetailsController = TextEditingController();

  // Form fields
  String _catheterType = 'indwelling';
  DateTime? _insertionDate;
  DateTime? _nextChangeDate;
  int? _urineOutputMorning;
  int? _urineOutputAfternoon;
  int? _urineOutputNight;
  String? _urineAppearance;
  bool _feverPresent = false;
  bool _painPresent = false;
  bool _urineOdourPresent = false;
  String? _skinCondition;
  bool _bagPositionCorrect = true;
  bool _bagSecure = true;
  bool _tubingSecure = true;
  int? _painLevel;
  int? _comfortLevel;
  bool _infectionRisk = false;
  bool _blockageRisk = false;
  bool _dislodgementRisk = false;
  bool _skinBreakdownRisk = false;
  String? _overallRiskLevel;
  bool _actionsRequired = false;
  String? _monitoringFrequency;
  DateTime? _nextReviewDate;
  
  // Form state
  bool _isLoading = false;
  CatheterCareAssessment? _existingAssessment;

  @override
  void initState() {
    super.initState();
    if (widget.assessmentId != null) {
      _loadExistingAssessment();
    }
  }

  @override
  void dispose() {
    _catheterSizeController.dispose();
    _balloonVolumeController.dispose();
    _urineAppearanceNotesController.dispose();
    _infectionNotesController.dispose();
    _skinConditionNotesController.dispose();
    _drainageNotesController.dispose();
    _patientComplaintsController.dispose();
    _actionsDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAssessment() async {
    try {
      setState(() => _isLoading = true);
      _existingAssessment = await _catheterService.getAssessmentById(widget.assessmentId!);
      
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

  void _populateForm(CatheterCareAssessment assessment) {
    _catheterType = assessment.catheterType;
    _insertionDate = assessment.insertionDate;
    _nextChangeDate = assessment.nextChangeDate;
    _catheterSizeController.text = assessment.catheterSize ?? '';
    _balloonVolumeController.text = assessment.balloonVolume ?? '';
    _urineOutputMorning = assessment.urineOutputMorning;
    _urineOutputAfternoon = assessment.urineOutputAfternoon;
    _urineOutputNight = assessment.urineOutputNight;
    _urineAppearance = assessment.urineAppearance;
    _urineAppearanceNotesController.text = assessment.urineAppearanceNotes ?? '';
    _feverPresent = assessment.feverPresent;
    _painPresent = assessment.painPresent;
    _urineOdourPresent = assessment.urineOdourPresent;
    _infectionNotesController.text = assessment.infectionNotes ?? '';
    _skinCondition = assessment.skinCondition;
    _skinConditionNotesController.text = assessment.skinConditionNotes ?? '';
    _bagPositionCorrect = assessment.bagPositionCorrect;
    _bagSecure = assessment.bagSecure;
    _tubingSecure = assessment.tubingSecure;
    _drainageNotesController.text = assessment.drainageNotes ?? '';
    _painLevel = assessment.painLevel;
    _comfortLevel = assessment.comfortLevel;
    _patientComplaintsController.text = assessment.patientComplaints ?? '';
    _infectionRisk = assessment.infectionRisk;
    _blockageRisk = assessment.blockageRisk;
    _dislodgementRisk = assessment.dislodgementRisk;
    _skinBreakdownRisk = assessment.skinBreakdownRisk;
    _overallRiskLevel = assessment.overallRiskLevel;
    _actionsRequired = assessment.actionsRequired;
    _actionsDetailsController.text = assessment.actionsDetails ?? '';
    _monitoringFrequency = assessment.monitoringFrequency;
    _nextReviewDate = assessment.nextReviewDate;
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final assessment = CatheterCareAssessment(
        serviceUserId: widget.serviceUserId,
        assessorId: Supabase.instance.client.auth.currentUser?.id,
        assessmentDate: DateTime.now(),
        catheterType: _catheterType,
        insertionDate: _insertionDate,
        nextChangeDate: _nextChangeDate,
        catheterSize: _catheterSizeController.text.trim(),
        balloonVolume: _balloonVolumeController.text.trim(),
        urineOutputMorning: _urineOutputMorning,
        urineOutputAfternoon: _urineOutputAfternoon,
        urineOutputNight: _urineOutputNight,
        urineAppearance: _urineAppearance,
        urineAppearanceNotes: _urineAppearanceNotesController.text.trim(),
        feverPresent: _feverPresent,
        painPresent: _painPresent,
        urineOdourPresent: _urineOdourPresent,
        infectionNotes: _infectionNotesController.text.trim(),
        skinCondition: _skinCondition,
        skinConditionNotes: _skinConditionNotesController.text.trim(),
        bagPositionCorrect: _bagPositionCorrect,
        bagSecure: _bagSecure,
        tubingSecure: _tubingSecure,
        drainageNotes: _drainageNotesController.text.trim(),
        painLevel: _painLevel,
        comfortLevel: _comfortLevel,
        patientComplaints: _patientComplaintsController.text.trim(),
        infectionRisk: _infectionRisk,
        blockageRisk: _blockageRisk,
        dislodgementRisk: _dislodgementRisk,
        skinBreakdownRisk: _skinBreakdownRisk,
        overallRiskLevel: _overallRiskLevel,
        actionsRequired: _actionsRequired,
        actionsDetails: _actionsDetailsController.text.trim(),
        monitoringFrequency: _monitoringFrequency,
        nextReviewDate: _nextReviewDate,
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_existingAssessment != null) {
        // Update existing assessment
        await _catheterService.updateAssessment(assessment);
      } else {
        // Create new assessment
        await _catheterService.createAssessment(assessment);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catheter care assessment saved successfully')),
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
        final assessment = CatheterCareAssessment(
          serviceUserId: widget.serviceUserId,
          assessorId: Supabase.instance.client.auth.currentUser?.id,
          assessmentDate: DateTime.now(),
          catheterType: _catheterType,
          insertionDate: _insertionDate,
          nextChangeDate: _nextChangeDate,
          catheterSize: _catheterSizeController.text.trim(),
          balloonVolume: _balloonVolumeController.text.trim(),
          urineOutputMorning: _urineOutputMorning,
          urineOutputAfternoon: _urineOutputAfternoon,
          urineOutputNight: _urineOutputNight,
          urineAppearance: _urineAppearance,
          urineAppearanceNotes: _urineAppearanceNotesController.text.trim(),
          feverPresent: _feverPresent,
          painPresent: _painPresent,
          urineOdourPresent: _urineOdourPresent,
          infectionNotes: _infectionNotesController.text.trim(),
          skinCondition: _skinCondition,
          skinConditionNotes: _skinConditionNotesController.text.trim(),
          bagPositionCorrect: _bagPositionCorrect,
          bagSecure: _bagSecure,
          tubingSecure: _tubingSecure,
          drainageNotes: _drainageNotesController.text.trim(),
          painLevel: _painLevel,
          comfortLevel: _comfortLevel,
          patientComplaints: _patientComplaintsController.text.trim(),
          infectionRisk: _infectionRisk,
          blockageRisk: _blockageRisk,
          dislodgementRisk: _dislodgementRisk,
          skinBreakdownRisk: _skinBreakdownRisk,
          overallRiskLevel: _overallRiskLevel,
          actionsRequired: _actionsRequired,
          actionsDetails: _actionsDetailsController.text.trim(),
          monitoringFrequency: _monitoringFrequency,
          nextReviewDate: _nextReviewDate,
          status: 'completed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        assessmentId = await _catheterService.createAssessment(assessment);
      }

      await _catheterService.submitAssessment(assessmentId, 'Digital Signature');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catheter care assessment submitted successfully')),
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

  Future<void> _selectDate({required bool isInsertionDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInsertionDate 
          ? (_insertionDate ?? DateTime.now())
          : (_nextChangeDate ?? DateTime.now().add(Duration(days: 28))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isInsertionDate) {
          _insertionDate = picked;
        } else {
          _nextChangeDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingAssessment != null 
            ? 'Edit Catheter Care Assessment' 
            : 'New Catheter Care Assessment - ${widget.serviceUserName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Catheter Information
                  _buildSectionHeader('Catheter Information'),
                  _buildDropdownField(
                    label: 'Catheter Type',
                    value: _catheterType,
                    onChanged: (value) => setState(() => _catheterType = value!),
                    items: const [
                      DropdownMenuItem(value: 'indwelling', child: Text('Indwelling')),
                      DropdownMenuItem(value: 'suprapubic', child: Text('Suprapubic')),
                      DropdownMenuItem(value: 'intermittent', child: Text('Intermittent')),
                    ],
                  ),
                  
                  _buildDateField(
                    label: 'Insertion Date',
                    date: _insertionDate,
                    onTap: () => _selectDate(isInsertionDate: true),
                  ),
                  
                  _buildDateField(
                    label: 'Next Change Date',
                    date: _nextChangeDate,
                    onTap: () => _selectDate(isInsertionDate: false),
                  ),
                  
                  _buildTextField(
                    controller: _catheterSizeController,
                    label: 'Catheter Size (e.g., 14Fr, 16Fr)',
                    validator: (value) => value!.isEmpty ? 'Catheter size is required' : null,
                  ),
                  
                  _buildTextField(
                    controller: _balloonVolumeController,
                    label: 'Balloon Volume (e.g., 10ml, 30ml)',
                    validator: (value) => value!.isEmpty ? 'Balloon volume is required' : null,
                  ),

                  const SizedBox(height: 20),

                  // Urine Monitoring
                  _buildSectionHeader('Urine Monitoring'),
                  _buildUrineOutputField(
                    label: 'Morning Output (ml)',
                    value: _urineOutputMorning,
                    onChanged: (value) => setState(() => _urineOutputMorning = value),
                  ),
                  _buildUrineOutputField(
                    label: 'Afternoon Output (ml)',
                    value: _urineOutputAfternoon,
                    onChanged: (value) => setState(() => _urineOutputAfternoon = value),
                  ),
                  _buildUrineOutputField(
                    label: 'Night Output (ml)',
                    value: _urineOutputNight,
                    onChanged: (value) => setState(() => _urineOutputNight = value),
                  ),
                  
                  _buildDropdownField(
                    label: 'Urine Appearance',
                    value: _urineAppearance,
                    onChanged: (value) => setState(() => _urineAppearance = value),
                    items: const [
                      DropdownMenuItem(value: 'clear', child: Text('Clear')),
                      DropdownMenuItem(value: 'cloudy', child: Text('Cloudy')),
                      DropdownMenuItem(value: 'blood-stained', child: Text('Blood-stained')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                  ),
                  
                  if (_urineAppearance == 'other')
                    _buildTextField(
                      controller: _urineAppearanceNotesController,
                      label: 'Urine Appearance Notes',
                    ),

                  const SizedBox(height: 20),

                  // Infection Monitoring
                  _buildSectionHeader('Infection Monitoring'),
                  _buildYesNoField(
                    label: 'Fever Present?',
                    value: _feverPresent,
                    onChanged: (value) => setState(() => _feverPresent = value!),
                  ),
                  _buildYesNoField(
                    label: 'Pain Present?',
                    value: _painPresent,
                    onChanged: (value) => setState(() => _painPresent = value!),
                  ),
                  _buildYesNoField(
                    label: 'Urine Odour Present?',
                    value: _urineOdourPresent,
                    onChanged: (value) => setState(() => _urineOdourPresent = value!),
                  ),
                  
                  _buildTextField(
                    controller: _infectionNotesController,
                    label: 'Infection Notes',
                  ),

                  const SizedBox(height: 20),

                  // Skin Condition
                  _buildSectionHeader('Skin Condition'),
                  _buildDropdownField(
                    label: 'Skin Condition',
                    value: _skinCondition,
                    onChanged: (value) => setState(() => _skinCondition = value),
                    items: const [
                      DropdownMenuItem(value: 'intact', child: Text('Intact')),
                      DropdownMenuItem(value: 'redness', child: Text('Redness')),
                      DropdownMenuItem(value: 'irritation', child: Text('Irritation')),
                      DropdownMenuItem(value: 'breakdown', child: Text('Breakdown')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                  ),
                  
                  if (_skinCondition == 'other')
                    _buildTextField(
                      controller: _skinConditionNotesController,
                      label: 'Skin Condition Notes',
                    ),

                  const SizedBox(height: 20),

                  // Drainage System
                  _buildSectionHeader('Drainage System'),
                  _buildYesNoField(
                    label: 'Bag Position Correct?',
                    value: _bagPositionCorrect,
                    onChanged: (value) => setState(() => _bagPositionCorrect = value!),
                  ),
                  _buildYesNoField(
                    label: 'Bag Secure?',
                    value: _bagSecure,
                    onChanged: (value) => setState(() => _bagSecure = value!),
                  ),
                  _buildYesNoField(
                    label: 'Tubing Secure?',
                    value: _tubingSecure,
                    onChanged: (value) => setState(() => _tubingSecure = value!),
                  ),
                  
                  _buildTextField(
                    controller: _drainageNotesController,
                    label: 'Drainage Notes',
                  ),

                  const SizedBox(height: 20),

                  // Patient Comfort
                  _buildSectionHeader('Patient Comfort'),
                  _buildSliderField(
                    label: 'Pain Level (0-10)',
                    value: _painLevel ?? 0,
                    onChanged: (value) => setState(() => _painLevel = value.round()),
                    min: 0,
                    max: 10,
                  ),
                  _buildSliderField(
                    label: 'Comfort Level (1-5)',
                    value: _comfortLevel ?? 3,
                    onChanged: (value) => setState(() => _comfortLevel = value.round()),
                    min: 1,
                    max: 5,
                  ),
                  
                  _buildTextField(
                    controller: _patientComplaintsController,
                    label: 'Patient Complaints',
                  ),

                  const SizedBox(height: 20),

                  // Risk Assessment
                  _buildSectionHeader('Risk Assessment'),
                  _buildYesNoField(
                    label: 'Infection Risk?',
                    value: _infectionRisk,
                    onChanged: (value) => setState(() => _infectionRisk = value!),
                  ),
                  _buildYesNoField(
                    label: 'Blockage Risk?',
                    value: _blockageRisk,
                    onChanged: (value) => setState(() => _blockageRisk = value!),
                  ),
                  _buildYesNoField(
                    label: 'Dislodgement Risk?',
                    value: _dislodgementRisk,
                    onChanged: (value) => setState(() => _dislodgementRisk = value!),
                  ),
                  _buildYesNoField(
                    label: 'Skin Breakdown Risk?',
                    value: _skinBreakdownRisk,
                    onChanged: (value) => setState(() => _skinBreakdownRisk = value!),
                  ),
                  
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

                  const SizedBox(height: 20),

                  // Actions and Monitoring
                  _buildSectionHeader('Actions and Monitoring'),
                  _buildYesNoField(
                    label: 'Actions Required?',
                    value: _actionsRequired,
                    onChanged: (value) => setState(() => _actionsRequired = value!),
                  ),
                  
                  if (_actionsRequired)
                    _buildTextField(
                      controller: _actionsDetailsController,
                      label: 'Actions Details',
                    ),
                  
                  _buildDropdownField(
                    label: 'Monitoring Frequency',
                    value: _monitoringFrequency,
                    onChanged: (value) => setState(() => _monitoringFrequency = value),
                    items: const [
                      DropdownMenuItem(value: '4 hourly', child: Text('4 Hourly')),
                      DropdownMenuItem(value: '8 hourly', child: Text('8 Hourly')),
                      DropdownMenuItem(value: '12 hourly', child: Text('12 Hourly')),
                    ],
                  ),
                  
                  _buildDateField(
                    label: 'Next Review Date',
                    date: _nextReviewDate,
                    onTap: () {
                      showDatePicker(
                        context: context,
                        initialDate: _nextReviewDate ?? DateTime.now().add(Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      ).then((date) {
                        if (date != null) {
                          setState(() => _nextReviewDate = date);
                        }
                      });
                    },
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
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
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

  Widget _buildUrineOutputField({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: value?.toString() ?? '',
              onChanged: (text) {
                final number = int.tryParse(text);
                onChanged(number);
              },
            ),
          ),
          const SizedBox(width: 8),
          const Text('ml'),
        ],
      ),
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(min.toInt().toString()),
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: (max - min).toInt(),
                  label: value.round().toString(),
                  onChanged: onChanged,
                ),
              ),
              Text(max.toInt().toString()),
            ],
          ),
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