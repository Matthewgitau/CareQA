import 'package:flutter/material.dart';
import 'package:admin_app/models/coshh_risk_assessment.dart';
import 'package:admin_app/services/coshh_risk_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoshhRiskForm extends StatefulWidget {
  final String serviceUserId;
  final String? assessmentId;
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
  final TextEditingController _signatureController = TextEditingController();

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

  // CQC compliance fields
  DateTime? _reviewDate;
  String _reassessmentFrequency = '1 year';

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
    _signatureController.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assessment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(CoshhRiskAssessment assessment) {
    _substanceNameController.text = assessment.substanceName;
    _typeOfHarmController.text = assessment.typeOfHarm;
    _descriptionController.text = assessment.description;
    _howCausesHarm = assessment.howCausesHarm;
    _whoExposed = List.from(assessment.whoExposed);
    _frequencyOfUse = assessment.frequencyOfUse;
    _purposeActivityController.text = assessment.purposeActivity;
    _canBeEliminated = assessment.canBeEliminated;
    _eliminationReason = assessment.eliminationReason;
    _controlMeasures = Map.from(assessment.controlMeasures);
    _emergencyProcedures = Map.from(assessment.emergencyProcedures);
    _staffAware = assessment.staffAware;
    _riskAcceptable = assessment.riskAcceptable;
    _riskLevel = assessment.riskLevel;
    _trainingDetailsController.text = assessment.trainingDetails ?? '';
    _reconsiderControlsController.text = assessment.reconsiderControls ?? '';
    _signatureController.text = assessment.assessorSignature ?? '';
    _reviewDate = assessment.reviewDate;
    _reassessmentFrequency = assessment.reassessmentFrequency ?? '1 year';
  }

  Future<bool> _showEditWarningDialog() async {
    if (widget.assessmentId == null) return true;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Existing Assessment'),
        content: const Text(
          'You are about to update information on an already submitted form. '
          'Please make sure you are sure you want to edit this file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, leave it as is'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, edit this file'),
          ),
        ],
      ),
    ) ?? false;
  }

  String? _getCurrentUserOrganisationId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['organisation_id'] as String?;
  }

  CoshhRiskAssessment _buildAssessment(String status) {
    return CoshhRiskAssessment(
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
      trainingRequired: !_staffAware,
      trainingDetails: _trainingDetailsController.text.trim(),
      riskAcceptable: _riskAcceptable,
      riskLevel: _riskLevel,
      reconsiderControls: _reconsiderControlsController.text.trim(),
      assessorSignature: _signatureController.text.trim().isEmpty ? null : _signatureController.text.trim(),
      reviewDate: _reviewDate,
      reassessmentFrequency: _reassessmentFrequency,
      organisationId: _getCurrentUserOrganisationId(),
      status: status,
      createdAt: _existingAssessment?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.serviceUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service user ID is required')),
      );
      return;
    }

    final shouldContinue = await _showEditWarningDialog();
    if (!shouldContinue) return;

    setState(() => _isLoading = true);
    try {
      final assessment = _buildAssessment('draft');
      if (_existingAssessment != null) {
        await _coshhService.updateAssessment(assessment);
      } else {
        await _coshhService.createAssessment(assessment);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('COSHH assessment saved successfully')),
        );
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save assessment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.serviceUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service user ID is required')),
      );
      return;
    }

    final shouldContinue = await _showEditWarningDialog();
    if (!shouldContinue) return;

    setState(() => _isLoading = true);
    try {
      String assessmentId;
      if (_existingAssessment != null) {
        assessmentId = _existingAssessment!.id!;
        await _coshhService.updateAssessment(_buildAssessment('completed'));
      } else {
        final assessment = _buildAssessment('completed');
        assessmentId = await _coshhService.createAssessment(assessment);
      }
      await _coshhService.submitAssessment(assessmentId, 'Digital Signature');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('COSHH assessment submitted successfully')),
        );
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit assessment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

                  _buildMultiSelectField(
                    label: 'Who is Exposed',
                    options: const ['staff', 'service users', 'visitors'],
                    selectedOptions: _whoExposed,
                    onChanged: (options) => setState(() => _whoExposed = options),
                  ),

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
                  
                  _buildYesNoField(
                    label: 'Can it be Eliminated?',
                    value: _canBeEliminated,
                    onChanged: (value) {
                      setState(() {
                        _canBeEliminated = value!;
                        if (!_canBeEliminated) _eliminationReason = null;
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
                        if (_riskAcceptable) _reconsiderControlsController.text = '';
                      });
                    },
                  ),

                  if (!_riskAcceptable)
                    _buildTextField(
                      controller: _reconsiderControlsController,
                      label: 'Reconsider Controls',
                    ),

                  const SizedBox(height: 20),

                  // CQC Compliance Fields
                  _buildSectionHeader('CQC Compliance'),
                  
                  _buildTextField(
                    controller: _signatureController,
                    label: 'Assessor Signature',
                    validator: (value) {
                      if ((value == null || value.isEmpty) && _existingAssessment == null) {
                        return 'Signature is required';
                      }
                      return null;
                    },
                  ),

                  _buildDropdownField(
                    label: 'Reassessment Frequency',
                    value: _reassessmentFrequency,
                    onChanged: (value) => setState(() => _reassessmentFrequency = value!),
                    items: const [
                      DropdownMenuItem(value: '6 months', child: Text('6 months')),
                      DropdownMenuItem(value: '1 year', child: Text('1 year')),
                      DropdownMenuItem(value: '2 years', child: Text('2 years')),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _reviewDate ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) setState(() => _reviewDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Review Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _reviewDate != null
                              ? '${_reviewDate!.day}/${_reviewDate!.month}/${_reviewDate!.year}'
                              : 'Select review date...',
                        ),
                      ),
                    ),
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
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
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
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
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  Radio<bool>(value: true, groupValue: value, onChanged: onChanged),
                  const Text('Yes'),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Radio<bool>(value: false, groupValue: value, onChanged: onChanged),
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