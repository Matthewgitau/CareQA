import 'package:flutter/material.dart';
import 'package:staff_app/models/coshh_risk_assessment.dart';
import 'package:staff_app/services/coshh_risk_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoshhRiskForm extends StatefulWidget {
  final String serviceUserId;
  final String? assessmentId; // If editing existing assessment
  final Function()? onSaved;

  const CoshhRiskForm({
    Key? key,
    required this.serviceUserId,
    this.assessmentId,
    this.onSaved,
  }) : super(key: key);

  @override
  _CoshhRiskFormState createState() => _CoshhRiskFormState();
}

class _CoshhRiskFormState extends State<CoshhRiskForm> {
  final _formKey = GlobalKey<FormState>();
  final _coshhService = CoshhRiskService(Supabase.instance.client);
  
  // Form controllers
  final TextEditingController _substanceNameController = TextEditingController();
  final TextEditingController _typeOfHarmController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _purposeActivityController = TextEditingController();
  final TextEditingController _trainingDetailsController = TextEditingController();
  final TextEditingController _reconsiderControlsController = TextEditingController();

  // Form fields
  String _howCausesHarm = 'inhalation';
  List<String> _whoExposed = [];
  String _frequencyOfUse = 'daily';
  bool _canBeEliminated = false;
  String? _eliminationReason;
  bool _staffAware = false;
  bool _riskAcceptable = false;
  String? _riskLevel;
  
  // Control measures
  Map<String, dynamic> _controlMeasures = {
    'engineering': [],
    'PPE': [],
    'procedures': [],
  };
  
  // Emergency procedures
  Map<String, dynamic> _emergencyProcedures = {
    'spill': [],
    'exposure': [],
  };

  // Form state
  bool _isLoading = false;
  CoshhRiskAssessment? _existingAssessment;

  @override
  void initState() {
    super.initState();
    if (widget.assessmentId != null) {
      _loadExistingAssessment();
    }
  }

  @override
  void dispose() {
    _substanceNameController.dispose();
    _typeOfHarmController.dispose();
    _descriptionController.dispose();
    _purposeActivityController.dispose();
    _trainingDetailsController.dispose();
    _reconsiderControlsController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAssessment() async {
    try {
      setState(() => _isLoading = true);
      _existingAssessment = await _coshhService.getAssessmentById(widget.assessmentId!);
      
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

  void _populateForm(CoshhRiskAssessment assessment) {
    _substanceNameController.text = assessment.substanceName;
    _typeOfHarmController.text = assessment.typeOfHarm;
    _descriptionController.text = assessment.description;
    _howCausesHarm = assessment.howCausesHarm;
    _whoExposed = assessment.whoExposed;
    _frequencyOfUse = assessment.frequencyOfUse;
    _purposeActivityController.text = assessment.purposeActivity;
    _canBeEliminated = assessment.canBeEliminated;
    _eliminationReason = assessment.eliminationReason;
    _controlMeasures = assessment.controlMeasures;
    _emergencyProcedures = assessment.emergencyProcedures;
    _staffAware = assessment.staffAware;
    _riskAcceptable = assessment.riskAcceptable;
    _riskLevel = assessment.riskLevel;
    _trainingDetailsController.text = assessment.trainingDetails ?? '';
    _reconsiderControlsController.text = assessment.reconsiderControls ?? '';
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final assessment = CoshhRiskAssessment(
        serviceUserId: widget.serviceUserId,
        assessorId: Supabase.instance.client.auth.currentUser?.id,
        assessmentDate: DateTime.now(),
        substanceName: _substanceNameController.text.trim(),
        typeOfHarm: _typeOfHarmController.text.trim(),
        description: _descriptionController.text.trim(),
        howCausesHarm: _howCausesHarm,
        whoExposed: _whoExposed,
        frequencyOfUse: _frequencyOfUse,
        purposeActivity: _purposeActivityController.text.trim(),
        canBeEliminated: _canBeEliminated,
        eliminationReason: _eliminationReason,
        controlMeasures: _controlMeasures,
        emergencyProcedures: _emergencyProcedures,
        staffAware: _staffAware,
        trainingRequired: _staffAware ? false : true,
        trainingDetails: _trainingDetailsController.text.trim(),
        riskAcceptable: _riskAcceptable,
        riskLevel: _riskLevel,
        reconsiderControls: _reconsiderControlsController.text.trim(),
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_existingAssessment != null) {
        // Update existing assessment
        await _coshhService.updateAssessment(assessment);
      } else {
        // Create new assessment
        await _coshhService.createAssessment(assessment);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('COSHH assessment saved successfully')),
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
        final assessment = CoshhRiskAssessment(
          serviceUserId: widget.serviceUserId,
          assessorId: Supabase.instance.client.auth.currentUser?.id,
          assessmentDate: DateTime.now(),
          substanceName: _substanceNameController.text.trim(),
          typeOfHarm: _typeOfHarmController.text.trim(),
          description: _descriptionController.text.trim(),
          howCausesHarm: _howCausesHarm,
          whoExposed: _whoExposed,
          frequencyOfUse: _frequencyOfUse,
          purposeActivity: _purposeActivityController.text.trim(),
          canBeEliminated: _canBeEliminated,
          eliminationReason: _eliminationReason,
          controlMeasures: _controlMeasures,
          emergencyProcedures: _emergencyProcedures,
          staffAware: _staffAware,
          trainingRequired: _staffAware ? false : true,
          trainingDetails: _trainingDetailsController.text.trim(),
          riskAcceptable: _riskAcceptable,
          riskLevel: _riskLevel,
          reconsiderControls: _reconsiderControlsController.text.trim(),
          status: 'completed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        assessmentId = await _coshhService.createAssessment(assessment);
      }

      await _coshhService.submitAssessment(assessmentId, 'Digital Signature');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('COSHH assessment submitted successfully')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingAssessment != null ? 'Edit COSHH Assessment' : 'New COSHH Assessment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Substance Information
                  _buildSectionHeader('Substance Information'),
                  _buildTextField(
                    controller: _substanceNameController,
                    label: 'Substance Name',
                    validator: (value) => value!.isEmpty ? 'Substance name is required' : null,
                  ),
                  _buildTextField(
                    controller: _typeOfHarmController,
                    label: 'Type of Harm',
                    validator: (value) => value!.isEmpty ? 'Type of harm is required' : null,
                  ),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description (liquid/solid/vapour/gas + colour)',
                    validator: (value) => value!.isEmpty ? 'Description is required' : null,
                  ),
                  
                  // How it causes harm
                  _buildDropdownField(
                    label: 'How it Causes Harm',
                    value: _howCausesHarm,
                    onChanged: (value) => setState(() => _howCausesHarm = value!),
                    items: const [
                      DropdownMenuItem(value: 'inhalation', child: Text('Inhalation')),
                      DropdownMenuItem(value: 'ingestion', child: Text('Ingestion')),
                      DropdownMenuItem(value: 'absorption', child: Text('Absorption')),
                    ],
                  ),

                  // Who is exposed
                  _buildMultiSelectField(
                    label: 'Who is Exposed',
                    options: const ['staff', 'service users', 'visitors'],
                    selectedOptions: _whoExposed,
                    onChanged: (options) => setState(() => _whoExposed = options),
                  ),

                  // Frequency of use
                  _buildDropdownField(
                    label: 'Frequency of Use',
                    value: _frequencyOfUse,
                    onChanged: (value) => setState(() => _frequencyOfUse = value!),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'occasionally', child: Text('Occasionally')),
                    ],
                  ),

                  _buildTextField(
                    controller: _purposeActivityController,
                    label: 'Purpose/Activity',
                    validator: (value) => value!.isEmpty ? 'Purpose/activity is required' : null,
                  ),

                  const SizedBox(height: 20),

                  // Risk Assessment Decisions
                  _buildSectionHeader('Risk Assessment Decisions'),
                  
                  // Can it be eliminated?
                  _buildYesNoField(
                    label: 'Can it be Eliminated?',
                    value: _canBeEliminated,
                    onChanged: (value) {
                      setState(() {
                        _canBeEliminated = value!;
                        if (!_canBeEliminated) {
                          _eliminationReason = null;
                        }
                      });
                    },
                  ),

                  if (_canBeEliminated)
                    _buildTextField(
                      controller: TextEditingController(text: _eliminationReason ?? ''),
                      label: 'Alternative/Reason',
                      onChanged: (value) => _eliminationReason = value,
                    ),

                  const SizedBox(height: 20),

                  // Control Measures
                  _buildSectionHeader('Control Measures'),
                  _buildMultiSelectField(
                    label: 'Engineering Controls',
                    options: const ['Ventilation', 'Fume Cupboard', 'Local Exhaust'],
                    selectedOptions: List.from(_controlMeasures['engineering'] ?? []),
                    onChanged: (options) => setState(() => _controlMeasures['engineering'] = options),
                  ),
                  _buildMultiSelectField(
                    label: 'PPE Required',
                    options: const ['Gloves', 'Mask', 'Goggles', 'Apron', 'Respirator'],
                    selectedOptions: List.from(_controlMeasures['PPE'] ?? []),
                    onChanged: (options) => setState(() => _controlMeasures['PPE'] = options),
                  ),
                  _buildMultiSelectField(
                    label: 'Procedures',
                    options: const ['Dilution Instructions', 'Use Sparingly', 'Allow to Dry', 'Proper Storage'],
                    selectedOptions: List.from(_controlMeasures['procedures'] ?? []),
                    onChanged: (options) => setState(() => _controlMeasures['procedures'] = options),
                  ),

                  const SizedBox(height: 20),

                  // Emergency Procedures
                  _buildSectionHeader('Emergency Procedures'),
                  _buildMultiSelectField(
                    label: 'Spill Procedures',
                    options: const ['Evacuate Area', 'Ventilate', 'Use Absorbent Material', 'Contact Supervisor'],
                    selectedOptions: List.from(_emergencyProcedures['spill'] ?? []),
                    onChanged: (options) => setState(() => _emergencyProcedures['spill'] = options),
                  ),
                  _buildMultiSelectField(
                    label: 'Exposure Procedures',
                    options: const ['Rinse with Water', 'Seek Medical Attention', 'Remove Contaminated Clothing'],
                    selectedOptions: List.from(_emergencyProcedures['exposure'] ?? []),
                    onChanged: (options) => setState(() => _emergencyProcedures['exposure'] = options),
                  ),

                  const SizedBox(height: 20),

                  // Staff Awareness and Training
                  _buildSectionHeader('Staff Awareness and Training'),
                  
                  _buildYesNoField(
                    label: 'Staff Aware of Risks?',
                    value: _staffAware,
                    onChanged: (value) => setState(() => _staffAware = value!),
                  ),

                  if (!_staffAware)
                    _buildTextField(
                      controller: _trainingDetailsController,
                      label: 'Training Required Details',
                    ),

                  const SizedBox(height: 20),

                  // Final Risk Assessment
                  _buildSectionHeader('Final Risk Assessment'),
                  
                  _buildYesNoField(
                    label: 'Risk Acceptable?',
                    value: _riskAcceptable,
                    onChanged: (value) {
                      setState(() {
                        _riskAcceptable = value!;
                        if (_riskAcceptable) {
                          _reconsiderControlsController.text = '';
                        }
                      });
                    },
                  ),

                  if (!_riskAcceptable)
                    _buildTextField(
                      controller: _reconsiderControlsController,
                      label: 'Reconsider Controls',
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
    required String value,
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

  Widget _buildMultiSelectField({
    required String label,
    required List<String> options,
    required List<String> selectedOptions,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: options.map((option) {
              bool isSelected = selectedOptions.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedOptions.add(option);
                    } else {
                      selectedOptions.remove(option);
                    }
                    onChanged(selectedOptions);
                  });
                },
              );
            }).toList(),
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