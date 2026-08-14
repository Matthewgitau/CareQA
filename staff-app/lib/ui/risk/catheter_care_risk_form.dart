import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatheterCareRiskForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;
  final String? assessmentId;
  final VoidCallback? onSaved;

  const CatheterCareRiskForm({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
    this.assessmentId,
    this.onSaved,
  }) : super(key: key);

  @override
  _CatheterCareRiskFormState createState() => _CatheterCareRiskFormState();
}

class _CatheterCareRiskFormState extends State<CatheterCareRiskForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = CatheterCareRiskService(Supabase.instance.client);
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Form data
  DateTime _assessmentDate = DateTime.now();
  String? _catheterType;
  DateTime? _insertionDate;
  DateTime? _nextChangeDate;
  int? _catheterSize;
  int? _balloonVolume;
  
  int? _urineOutputMl;
  String? _urineAppearance;
  String? _urineOdour;
  
  double? _feverCelsius;
  int? _painLevel;
  final TextEditingController _painLocationController = TextEditingController();
  
  String? _skinCondition;
  final TextEditingController _skinConditionNotesController = TextEditingController();
  
  String? _drainageBagPosition;
  bool _drainageBagSecure = true;
  
  String? _infectionRisk;
  String? _blockageRisk;
  String? _dislodgementRisk;
  String? _overallRiskLevel;
  
  int? _comfortLevel;
  final TextEditingController _patientConcernsController = TextEditingController();
  
  bool _staffCompetencyVerified = false;
  DateTime? _reviewDate;
  final TextEditingController _actionPlanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.assessmentId != null) {
      _loadAssessment();
      _isEditing = true;
    }
  }

  @override
  void dispose() {
    _painLocationController.dispose();
    _skinConditionNotesController.dispose();
    _patientConcernsController.dispose();
    _actionPlanController.dispose();
    super.dispose();
  }

  Future<void> _loadAssessment() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAssessmentById(widget.assessmentId!);
      if (data != null) {
        setState(() {
          _assessmentDate = DateTime.parse(data['assessment_date']);
          _catheterType = data['catheter_type'];
          _insertionDate = data['insertion_date'] != null ? DateTime.parse(data['insertion_date']) : null;
          _nextChangeDate = data['next_change_date'] != null ? DateTime.parse(data['next_change_date']) : null;
          _catheterSize = data['catheter_size'];
          _balloonVolume = data['balloon_volume'];
          
          _urineOutputMl = data['urine_output_ml'];
          _urineAppearance = data['urine_appearance'];
          _urineOdour = data['urine_odour'];
          
          _feverCelsius = data['fever_celsius'] != null ? double.tryParse(data['fever_celsius'].toString()) : null;
          _painLevel = data['pain_level'];
          _painLocationController.text = data['pain_location'] ?? '';
          
          _skinCondition = data['skin_condition'];
          _skinConditionNotesController.text = data['skin_condition_notes'] ?? '';
          
          _drainageBagPosition = data['drainage_bag_position'];
          _drainageBagSecure = data['drainage_bag_secure'] ?? true;
          
          _infectionRisk = data['infection_risk'];
          _blockageRisk = data['blockage_risk'];
          _dislodgementRisk = data['dislodgement_risk'];
          _overallRiskLevel = data['overall_risk_level'];
          
          _comfortLevel = data['comfort_level'];
          _patientConcernsController.text = data['patient_concerns'] ?? '';
          
          _staffCompetencyVerified = data['staff_competency_verified'] ?? false;
          _reviewDate = data['review_date'] != null ? DateTime.parse(data['review_date']) : null;
          _actionPlanController.text = data['action_plan'] ?? '';
        });
      }
    } catch (e) {
      _showError('Failed to load assessment: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final assessmentData = {
        'service_user_id': widget.serviceUserId,
        'assessment_date': _assessmentDate.toIso8601String().split('T')[0],
        'catheter_type': _catheterType,
        'insertion_date': _insertionDate?.toIso8601String().split('T')[0],
        'next_change_date': _nextChangeDate?.toIso8601String().split('T')[0],
        'catheter_size': _catheterSize,
        'balloon_volume': _balloonVolume,
        'urine_output_ml': _urineOutputMl,
        'urine_appearance': _urineAppearance,
        'urine_odour': _urineOdour,
        'fever_celsius': _feverCelsius,
        'pain_level': _painLevel,
        'pain_location': _painLocationController.text,
        'skin_condition': _skinCondition,
        'skin_condition_notes': _skinConditionNotesController.text,
        'drainage_bag_position': _drainageBagPosition,
        'drainage_bag_secure': _drainageBagSecure,
        'infection_risk': _infectionRisk,
        'blockage_risk': _blockageRisk,
        'dislodgement_risk': _dislodgementRisk,
        'overall_risk_level': _overallRiskLevel,
        'comfort_level': _comfortLevel,
        'patient_concerns': _patientConcernsController.text,
        'staff_competency_verified': _staffCompetencyVerified,
        'review_date': _reviewDate?.toIso8601String().split('T')[0],
        'action_plan': _actionPlanController.text,
      };

      if (_isEditing) {
        await _service.updateAssessment(assessmentData, widget.assessmentId!);
        _showSuccess('Assessment updated successfully');
      } else {
        await _service.createAssessment(assessmentData);
        _showSuccess('Assessment created successfully');
      }

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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Catheter Care Assessment' : 'New Catheter Care Assessment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAssessment,
            tooltip: 'Save',
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
                          Text(
                            'Service User: ${widget.serviceUserName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text('Assessment Date: ${DateFormat('dd/MM/yyyy').format(_assessmentDate)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catheter Information
                  _buildSectionHeader('Catheter Information'),
                  _buildDropdownField(
                    label: 'Catheter Type',
                    value: _catheterType,
                    items: CatheterCareRiskAssessment.getCatheterTypes(),
                    displayText: (value) => _getCatheterTypeDisplay(value),
                    onChanged: (value) => setState(() => _catheterType = value),
                  ),
                  _buildDateField(
                    label: 'Insertion Date',
                    selectedDate: _insertionDate,
                    onDateChanged: (date) => setState(() => _insertionDate = date),
                  ),
                  _buildDateField(
                    label: 'Next Change Date',
                    selectedDate: _nextChangeDate,
                    onDateChanged: (date) => setState(() => _nextChangeDate = date),
                  ),
                  _buildNumberField(
                    label: 'Catheter Size (Fr)',
                    value: _catheterSize?.toDouble(),
                    onChanged: (value) => setState(() => _catheterSize = value?.toInt()),
                    min: 0,
                    max: 30,
                  ),
                  _buildNumberField(
                    label: 'Balloon Volume (ml)',
                    value: _balloonVolume?.toDouble(),
                    onChanged: (value) => setState(() => _balloonVolume = value?.toInt()),
                    min: 0,
                    max: 30,
                  ),

                  // Urine Monitoring
                  _buildSectionHeader('Urine Monitoring'),
                  _buildNumberField(
                    label: 'Urine Output (ml/24h)',
                    value: _urineOutputMl?.toDouble(),
                    onChanged: (value) => setState(() => _urineOutputMl = value?.toInt()),
                    min: 0,
                    max: 5000,
                  ),
                  _buildDropdownField(
                    label: 'Urine Appearance',
                    value: _urineAppearance,
                    items: CatheterCareRiskAssessment.getUrineAppearances(),
                    displayText: (value) => _getUrineAppearanceDisplay(value),
                    onChanged: (value) => setState(() => _urineAppearance = value),
                  ),
                  _buildDropdownField(
                    label: 'Urine Odour',
                    value: _urineOdour,
                    items: CatheterCareRiskAssessment.getUrineOdours(),
                    displayText: (value) => _getUrineOdourDisplay(value),
                    onChanged: (value) => setState(() => _urineOdour = value),
                  ),

                  // Infection Signs
                  _buildSectionHeader('Infection Signs'),
                  _buildNumberField(
                    label: 'Temperature (°C)',
                    value: _feverCelsius,
                    onChanged: (value) => setState(() => _feverCelsius = value),
                    min: 35,
                    max: 42,
                    decimals: 1,
                  ),
                  _buildSliderField(
                    label: 'Pain Level (0-10)',
                    value: _painLevel?.toDouble() ?? 0,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: (value) => setState(() => _painLevel = value.toInt()),
                    labelBuilder: (value) => value.toInt().toString(),
                  ),
                  _buildTextField(
                    controller: _painLocationController,
                    label: 'Pain Location',
                    hintText: 'e.g., bladder, abdomen, urethra',
                  ),

                  // Skin Condition
                  _buildSectionHeader('Skin Condition'),
                  _buildDropdownField(
                    label: 'Skin Condition at Insertion Site',
                    value: _skinCondition,
                    items: CatheterCareRiskAssessment.getSkinConditions(),
                    displayText: (value) => _getSkinConditionDisplay(value),
                    onChanged: (value) => setState(() => _skinCondition = value),
                  ),
                  _buildTextField(
                    controller: _skinConditionNotesController,
                    label: 'Skin Condition Notes',
                    hintText: 'Describe any observations',
                    maxLines: 3,
                  ),

                  // Drainage System
                  _buildSectionHeader('Drainage System'),
                  _buildDropdownField(
                    label: 'Drainage Bag Position',
                    value: _drainageBagPosition,
                    items: CatheterCareRiskAssessment.getDrainageBagPositions(),
                    displayText: (value) => _getDrainageBagPositionDisplay(value),
                    onChanged: (value) => setState(() => _drainageBagPosition = value),
                  ),
                  _buildCheckboxField(
                    label: 'Drainage Bag Securely Fixed',
                    value: _drainageBagSecure,
                    onChanged: (value) => setState(() => _drainageBagSecure = value ?? false),
                  ),

                  // Risk Assessment
                  _buildSectionHeader('Risk Assessment'),
                  _buildDropdownField(
                    label: 'Infection Risk',
                    value: _infectionRisk,
                    items: CatheterCareRiskAssessment.getRiskLevels(),
                    displayText: (value) => _getRiskLevelDisplay(value),
                    onChanged: (value) => setState(() => _infectionRisk = value),
                  ),
                  _buildDropdownField(
                    label: 'Blockage Risk',
                    value: _blockageRisk,
                    items: CatheterCareRiskAssessment.getRiskLevels(),
                    displayText: (value) => _getRiskLevelDisplay(value),
                    onChanged: (value) => setState(() => _blockageRisk = value),
                  ),
                  _buildDropdownField(
                    label: 'Dislodgement Risk',
                    value: _dislodgementRisk,
                    items: CatheterCareRiskAssessment.getRiskLevels(),
                    displayText: (value) => _getRiskLevelDisplay(value),
                    onChanged: (value) => setState(() => _dislodgementRisk = value),
                  ),
                  _buildDropdownField(
                    label: 'Overall Risk Level',
                    value: _overallRiskLevel,
                    items: CatheterCareRiskAssessment.getOverallRiskLevels(),
                    displayText: (value) => _getOverallRiskLevelDisplay(value),
                    onChanged: (value) => setState(() => _overallRiskLevel = value),
                  ),

                  // Patient Comfort
                  _buildSectionHeader('Patient Comfort'),
                  _buildSliderField(
                    label: 'Comfort Level (1-5)',
                    value: _comfortLevel?.toDouble() ?? 3,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => _comfortLevel = value.toInt()),
                    labelBuilder: (value) => value.toInt().toString(),
                  ),
                  _buildTextField(
                    controller: _patientConcernsController,
                    label: 'Patient Concerns',
                    hintText: 'Any concerns expressed by the patient',
                    maxLines: 3,
                  ),

                  // Staff & Review
                  _buildSectionHeader('Staff & Review'),
                  _buildCheckboxField(
                    label: 'Staff Competency Verified',
                    value: _staffCompetencyVerified,
                    onChanged: (value) => setState(() => _staffCompetencyVerified = value ?? false),
                  ),
                  _buildDateField(
                    label: 'Review Date',
                    selectedDate: _reviewDate,
                    onDateChanged: (date) => setState(() => _reviewDate = date),
                  ),
                  _buildTextField(
                    controller: _actionPlanController,
                    label: 'Action Plan',
                    hintText: 'Any actions required',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveAssessment,
                          icon: const Icon(Icons.save),
                          label: Text(_isEditing ? 'Update Assessment' : 'Create Assessment'),
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
    int maxLines = 1,
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
            maxLines: maxLines,
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
    int? decimals,
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
            keyboardType: decimals != null ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
            validator: (input) {
              if (input == null || input.isEmpty) return null; // Optional field
              final numValue = double.tryParse(input);
              if (numValue == null) return 'Please enter a valid number';
              if (min != null && numValue < min) return 'Value must be at least $min';
              if (max != null && numValue > max) return 'Value must not exceed $max';
              return null;
            },
            onSaved: (input) {
              final numValue = double.tryParse(input ?? '');
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
                firstDate: DateTime(2000),
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
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) labelBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: labelBuilder(value),
                  onChanged: onChanged,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  labelBuilder(value),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Display helpers
  String _getCatheterTypeDisplay(String? value) {
    switch (value) {
      case 'indwelling':
        return 'Indwelling (Foley)';
      case 'suprapubic':
        return 'Suprapubic';
      case 'intermittent':
        return 'Intermittent (CIC)';
      default:
        return 'Select type';
    }
  }

  String _getUrineAppearanceDisplay(String? value) {
    switch (value) {
      case 'clear':
        return 'Clear';
      case 'cloudy':
        return 'Cloudy';
      case 'blood_stained':
        return 'Blood-stained';
      case 'dark':
        return 'Dark';
      default:
        return 'Select appearance';
    }
  }

  String _getUrineOdourDisplay(String? value) {
    switch (value) {
      case 'normal':
        return 'Normal';
      case 'foul':
        return 'Foul';
      case 'sweet':
        return 'Sweet';
      default:
        return 'Select odour';
    }
  }

  String _getSkinConditionDisplay(String? value) {
    switch (value) {
      case 'intact':
        return 'Intact';
      case 'redness':
        return 'Redness';
      case 'rash':
        return 'Rash';
      case 'broken':
        return 'Broken';
      case 'infected':
        return 'Infected';
      default:
        return 'Select condition';
    }
  }

  String _getDrainageBagPositionDisplay(String? value) {
    switch (value) {
      case 'below_bladder':
        return 'Below Bladder (Correct)';
      case 'above_bladder':
        return 'Above Bladder (Incorrect)';
      case 'floor':
        return 'On Floor (Incorrect)';
      default:
        return 'Select position';
    }
  }

  String _getRiskLevelDisplay(String? value) {
    switch (value) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      default:
        return 'Select risk level';
    }
  }

  String _getOverallRiskLevelDisplay(String? value) {
    switch (value) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return 'Select risk level';
    }
  }
}

// Service class for database operations
class CatheterCareRiskService {
  final SupabaseClient _client;

  CatheterCareRiskService(this._client);

  Future<String> createAssessment(Map<String, dynamic> data) async {
    final response = await _client
        .from('catheter_care_risk_assessments')
        .insert(data)
        .select('id')
        .single();
    return response['id'];
  }

  Future<void> updateAssessment(Map<String, dynamic> data, String id) async {
    await _client
        .from('catheter_care_risk_assessments')
        .update(data)
        .eq('id', id);
  }

  Future<Map<String, dynamic>?> getAssessmentById(String id) async {
    final response = await _client
        .from('catheter_care_risk_assessments')
        .select('*')
        .eq('id', id)
        .single();
    return response;
  }
}

// Model class for display helpers
class CatheterCareRiskAssessment {
  static List<String> getCatheterTypes() => ['indwelling', 'suprapubic', 'intermittent'];
  static List<String> getUrineAppearances() => ['clear', 'cloudy', 'blood_stained', 'dark'];
  static List<String> getUrineOdours() => ['normal', 'foul', 'sweet'];
  static List<String> getSkinConditions() => ['intact', 'redness', 'rash', 'broken', 'infected'];
  static List<String> getDrainageBagPositions() => ['below_bladder', 'above_bladder', 'floor'];
  static List<String> getRiskLevels() => ['low', 'medium', 'high'];
  static List<String> getOverallRiskLevels() => ['low', 'medium', 'high', 'critical'];
}