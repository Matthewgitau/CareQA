import 'package:flutter/material.dart';
import 'package:admin_app/models/catheter_care_risk_assessment.dart';
import 'package:admin_app/services/catheter_care_risk_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
  final _catheterCareService = CatheterCareRiskService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  late CatheterCareRiskAssessment _assessment;
  bool _isLoading = false;
  bool _isEditing = false;

  // Controllers for text fields
  final TextEditingController _painLocationController = TextEditingController();
  final TextEditingController _skinConditionNotesController = TextEditingController();
  final TextEditingController _patientConcernsController = TextEditingController();
  final TextEditingController _actionPlanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAssessment();
  }

  @override
  void dispose() {
    _painLocationController.dispose();
    _skinConditionNotesController.dispose();
    _patientConcernsController.dispose();
    _actionPlanController.dispose();
    super.dispose();
  }

  Future<void> _initializeAssessment() async {
    setState(() => _isLoading = true);
    try {
      if (widget.assessmentId != null) {
        final existingAssessment = await _catheterCareService.getAssessmentById(widget.assessmentId!);
        if (existingAssessment != null) {
          _assessment = existingAssessment;
          _isEditing = true;
          _populateControllers();
        } else {
          _assessment = CatheterCareRiskAssessment.createNew(widget.serviceUserId, null);
        }
      } else {
        _assessment = CatheterCareRiskAssessment.createNew(widget.serviceUserId, null);
      }
    } catch (e) {
      _showError('Failed to load assessment: $e');
      _assessment = CatheterCareRiskAssessment.createNew(widget.serviceUserId, null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    _painLocationController.text = _assessment.painLocation ?? '';
    _skinConditionNotesController.text = _assessment.skinConditionNotes ?? '';
    _patientConcernsController.text = _assessment.patientConcerns ?? '';
    _actionPlanController.text = _assessment.actionPlan ?? '';
  }

  void _updateAssessmentFromForm() {
    _assessment = _assessment.copyWith(
      painLocation: _painLocationController.text.isNotEmpty ? _painLocationController.text : null,
      skinConditionNotes: _skinConditionNotesController.text.isNotEmpty ? _skinConditionNotesController.text : null,
      patientConcerns: _patientConcernsController.text.isNotEmpty ? _patientConcernsController.text : null,
      actionPlan: _actionPlanController.text.isNotEmpty ? _actionPlanController.text : null,
    );
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    _updateAssessmentFromForm();
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _catheterCareService.updateAssessment(_assessment);
        _showSuccess('Assessment updated successfully');
      } else {
        await _catheterCareService.createAssessment(_assessment);
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Catheter Care Assessment' : 'New Catheter Care Assessment'),
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
                          const SizedBox(height: 4),
                          Text('Service User ID: ${widget.serviceUserId}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catheter Information
                  _buildSectionHeader('Catheter Information'),
                  _buildDropdownField(
                    label: 'Catheter Type',
                    value: _assessment.catheterType,
                    items: CatheterCareRiskAssessment.getCatheterTypes(),
                    displayText: (value) => _getCatheterTypeDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(catheterType: value!);
                      });
                    },
                  ),
                  _buildDateField(
                    label: 'Insertion Date',
                    selectedDate: _assessment.insertionDate,
                    onDateChanged: (date) {
                      setState(() {
                        _assessment = _assessment.copyWith(insertionDate: date);
                      });
                    },
                  ),
                  _buildDateField(
                    label: 'Next Change Date',
                    selectedDate: _assessment.nextChangeDate,
                    onDateChanged: (date) {
                      setState(() {
                        _assessment = _assessment.copyWith(nextChangeDate: date);
                      });
                    },
                  ),
                  _buildNumberField(
                    label: 'Catheter Size (Fr)',
                    value: _assessment.catheterSize?.toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(catheterSize: value?.toInt());
                      });
                    },
                    min: 0,
                    max: 30,
                  ),
                  _buildNumberField(
                    label: 'Balloon Volume (ml)',
                    value: _assessment.balloonVolume?.toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(balloonVolume: value?.toInt());
                      });
                    },
                    min: 0,
                    max: 30,
                  ),

                  // Urine Monitoring
                  _buildSectionHeader('Urine Monitoring'),
                  _buildNumberField(
                    label: 'Urine Output (ml/24h)',
                    value: _assessment.urineOutputMl?.toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(urineOutputMl: value?.toInt());
                      });
                    },
                    min: 0,
                    max: 5000,
                  ),
                  _buildDropdownField(
                    label: 'Urine Appearance',
                    value: _assessment.urineAppearance,
                    items: CatheterCareRiskAssessment.getUrineAppearances(),
                    displayText: (value) => _getUrineAppearanceDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(urineAppearance: value);
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Urine Odour',
                    value: _assessment.urineOdour,
                    items: CatheterCareRiskAssessment.getUrineOdours(),
                    displayText: (value) => _getUrineOdourDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(urineOdour: value);
                      });
                    },
                  ),

                  // Infection Signs
                  _buildSectionHeader('Infection Signs'),
                  _buildNumberField(
                    label: 'Temperature (°C)',
                    value: _assessment.feverCelsius,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(feverCelsius: value);
                      });
                    },
                    min: 35,
                    max: 42,
                    decimals: 1,
                  ),
                  _buildSliderField(
                    label: 'Pain Level (0-10)',
                    value: _assessment.painLevel?.toDouble() ?? 0,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(painLevel: value.toInt());
                      });
                    },
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
                    value: _assessment.skinCondition,
                    items: CatheterCareRiskAssessment.getSkinConditions(),
                    displayText: (value) => _getSkinConditionDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(skinCondition: value);
                      });
                    },
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
                    value: _assessment.drainageBagPosition,
                    items: CatheterCareRiskAssessment.getDrainageBagPositions(),
                    displayText: (value) => _getDrainageBagPositionDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(drainageBagPosition: value);
                      });
                    },
                  ),
                  _buildCheckboxField(
                    label: 'Drainage Bag Securely Fixed',
                    value: _assessment.drainageBagSecure,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(drainageBagSecure: value ?? false);
                      });
                    },
                  ),

                  // Risk Assessment
                  _buildSectionHeader('Risk Assessment'),
                  _buildDropdownField(
                    label: 'Infection Risk',
                    value: _assessment.infectionRisk,
                    items: CatheterCareRiskAssessment.getRiskLevels(),
                    displayText: (value) => _getRiskLevelDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(infectionRisk: value);
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Blockage Risk',
                    value: _assessment.blockageRisk,
                    items: CatheterCareRiskAssessment.getRiskLevels(),
                    displayText: (value) => _getRiskLevelDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(blockageRisk: value);
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Dislodgement Risk',
                    value: _assessment.dislodgementRisk,
                    items: CatheterCareRiskAssessment.getRiskLevels(),
                    displayText: (value) => _getRiskLevelDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(dislodgementRisk: value);
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Overall Risk Level',
                    value: _assessment.overallRiskLevel,
                    items: CatheterCareRiskAssessment.getOverallRiskLevels(),
                    displayText: (value) => _getOverallRiskLevelDisplay(value),
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(overallRiskLevel: value);
                      });
                    },
                  ),

                  // Patient Comfort
                  _buildSectionHeader('Patient Comfort'),
                  _buildSliderField(
                    label: 'Comfort Level (1-5)',
                    value: _assessment.comfortLevel?.toDouble() ?? 3,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(comfortLevel: value.toInt());
                      });
                    },
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
                    value: _assessment.staffCompetencyVerified,
                    onChanged: (value) {
                      setState(() {
                        _assessment = _assessment.copyWith(staffCompetencyVerified: value ?? false);
                      });
                    },
                  ),
                  _buildDateField(
                    label: 'Review Date',
                    selectedDate: _assessment.reviewDate,
                    onDateChanged: (date) {
                      setState(() {
                        _assessment = _assessment.copyWith(reviewDate: date);
                      });
                    },
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
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: value ?? false,
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