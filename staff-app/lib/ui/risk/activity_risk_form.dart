import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/activity_risk_assessment.dart';
import 'package:staff_app/services/activity_risk_service.dart';
import 'package:staff_app/ui/common/custom_app_bar.dart';
import 'package:staff_app/ui/common/custom_button.dart';
import 'package:staff_app/ui/common/custom_card.dart';
import 'package:staff_app/ui/common/custom_text_field.dart';
import 'package:staff_app/ui/common/section_header.dart';
import 'package:staff_app/utils/constants.dart';
import 'package:staff_app/utils/date_utils.dart';
import 'package:staff_app/utils/dialog_utils.dart';
import 'package:staff_app/utils/snackbar_utils.dart';

class ActivityRiskForm extends StatefulWidget {
  final String? assessmentId;
  final String? serviceUserId;
  final String? assessorId;

  const ActivityRiskForm({
    Key? key,
    this.assessmentId,
    this.serviceUserId,
    this.assessorId,
  }) : super(key: key);

  @override
  _ActivityRiskFormState createState() => _ActivityRiskFormState();
}

class _ActivityRiskFormState extends State<ActivityRiskForm> {
  final _activityRiskService = ActivityRiskService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _equipmentController = TextEditingController();
  final _risksController = TextEditingController();
  final _controlsController = TextEditingController();
  final _competencyController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _notesController = TextEditingController();

  // Form fields
  ActivityType? _activityType;
  FrequencyType? _frequency;
  SupportLevelType? _supportLevel;
  DateTime? _reviewDate;
  String? _riskLevel;
  List<String> _equipmentRequired = [];
  List<String> _identifiedRisks = [];
  List<String> _controlMeasures = [];
  List<String> _staffCompetencyRequired = [];

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.assessmentId != null) {
      _loadAssessment();
    }
  }

  Future<void> _loadAssessment() async {
    setState(() => _isLoading = true);
    try {
      final assessment = await _activityRiskService.getAssessment(widget.assessmentId!);
      setState(() {
        _activityType = assessment.activityType;
        _frequency = assessment.frequency;
        _supportLevel = assessment.supportLevel;
        _reviewDate = assessment.reviewDate;
        _riskLevel = assessment.riskLevel;
        _equipmentRequired = assessment.equipmentRequired;
        _identifiedRisks = assessment.identifiedRisks;
        _controlMeasures = assessment.controlMeasures;
        _staffCompetencyRequired = assessment.staffCompetencyRequired;
        _emergencyController.text = assessment.emergencyProcedures;
        _notesController.text = assessment.notes ?? '';
        _isEditing = true;
      });
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to load assessment: ${e.toString()}');
      Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final assessment = ActivityRiskAssessment(
        serviceUserId: widget.serviceUserId!,
        assessorId: widget.assessorId ?? Supabase.instance.client.auth.currentSession?.user.id,
        activityType: _activityType!,
        frequency: _frequency!,
        supportLevel: _supportLevel!,
        equipmentRequired: _equipmentRequired,
        identifiedRisks: _identifiedRisks,
        riskLevel: _riskLevel ?? 'low',
        controlMeasures: _controlMeasures,
        staffCompetencyRequired: _staffCompetencyRequired,
        emergencyProcedures: _emergencyController.text,
        reviewDate: _reviewDate!,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        assessmentData: {},
      );

      if (_isEditing && widget.assessmentId != null) {
        await _activityRiskService.updateAssessment(widget.assessmentId!, assessment);
        SnackbarUtils.showSuccessSnackbar(context, 'Activity risk assessment updated successfully!');
      } else {
        await _activityRiskService.createAssessment(assessment);
        SnackbarUtils.showSuccessSnackbar(context, 'Activity risk assessment created successfully!');
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to save assessment: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addEquipment() {
    if (_equipmentController.text.isNotEmpty) {
      setState(() {
        _equipmentRequired.add(_equipmentController.text.trim());
        _equipmentController.clear();
      });
    }
  }

  void _removeEquipment(String equipment) {
    setState(() {
      _equipmentRequired.remove(equipment);
    });
  }

  void _addRisk() {
    if (_risksController.text.isNotEmpty) {
      setState(() {
        _identifiedRisks.add(_risksController.text.trim());
        _risksController.clear();
      });
    }
  }

  void _removeRisk(String risk) {
    setState(() {
      _identifiedRisks.remove(risk);
    });
  }

  void _addControl() {
    if (_controlsController.text.isNotEmpty) {
      setState(() {
        _controlMeasures.add(_controlsController.text.trim());
        _controlsController.clear();
      });
    }
  }

  void _removeControl(String control) {
    setState(() {
      _controlMeasures.remove(control);
    });
  }

  void _addCompetency() {
    if (_competencyController.text.isNotEmpty) {
      setState(() {
        _staffCompetencyRequired.add(_competencyController.text.trim());
        _competencyController.clear();
      });
    }
  }

  void _removeCompetency(String competency) {
    setState(() {
      _staffCompetencyRequired.remove(competency);
    });
  }

  void _calculateRiskLevel() {
    if (_activityType != null && _supportLevel != null) {
      final assessment = ActivityRiskAssessment(
        serviceUserId: widget.serviceUserId ?? '',
        assessorId: widget.assessorId ?? '',
        activityType: _activityType!,
        frequency: _frequency ?? FrequencyType.daily,
        supportLevel: _supportLevel!,
        equipmentRequired: _equipmentRequired,
        identifiedRisks: _identifiedRisks,
        riskLevel: 'low',
        controlMeasures: _controlMeasures,
        staffCompetencyRequired: _staffCompetencyRequired,
        emergencyProcedures: '',
        reviewDate: _reviewDate ?? DateTime.now().add(Duration(days: 180)),
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assessmentData: {},
      );

      setState(() {
        _riskLevel = assessment.calculateRiskLevel();
      });
    }
  }

  Widget _buildActivityTypeSelection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Activity Information'),
          const SizedBox(height: 16),
          DropdownButtonFormField<ActivityType>(
            value: _activityType,
            decoration: const InputDecoration(
              labelText: 'Activity Type',
              border: OutlineInputBorder(),
            ),
            items: ActivityType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getActivityTypeDisplay(type)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _activityType = value;
                _calculateRiskLevel();
              });
            },
            validator: (value) => value == null ? 'Please select an activity type' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<FrequencyType>(
                  value: _frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: FrequencyType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getFrequencyDisplay(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _frequency = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select frequency' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<SupportLevelType>(
                  value: _supportLevel,
                  decoration: const InputDecoration(
                    labelText: 'Support Level',
                    border: OutlineInputBorder(),
                  ),
                  items: SupportLevelType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getSupportLevelDisplay(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _supportLevel = value;
                      _calculateRiskLevel();
                    });
                  },
                  validator: (value) => value == null ? 'Please select support level' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _reviewDate != null 
                        ? DateFormat('dd/MM/yyyy').format(_reviewDate!)
                        : 'Select Review Date'
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Review Date',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _reviewDate ?? DateTime.now().add(Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _reviewDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: _riskLevel ?? 'low',
                  decoration: const InputDecoration(
                    labelText: 'Calculated Risk Level',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Equipment Required'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _equipmentController,
                  labelText: 'Add Equipment',
                  hintText: 'Enter equipment name',
                ),
              ),
              const SizedBox(width: 16),
              CustomButton(
                onPressed: _addEquipment,
                text: 'Add',
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipmentRequired.map((equipment) {
              return Chip(
                label: Text(equipment),
                onDeleted: () => _removeEquipment(equipment),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRisksSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Identified Risks'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _risksController,
                  labelText: 'Add Risk',
                  hintText: 'Describe the risk',
                ),
              ),
              const SizedBox(width: 16),
              CustomButton(
                onPressed: _addRisk,
                text: 'Add',
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _identifiedRisks.map((risk) {
              return Chip(
                label: Text(risk),
                onDeleted: () => _removeRisk(risk),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Control Measures'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _controlsController,
                  labelText: 'Add Control Measure',
                  hintText: 'Describe the control measure',
                ),
              ),
              const SizedBox(width: 16),
              CustomButton(
                onPressed: _addControl,
                text: 'Add',
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _controlMeasures.map((control) {
              return Chip(
                label: Text(control),
                onDeleted: () => _removeControl(control),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetencySection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Staff Competency Required'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _competencyController,
                  labelText: 'Add Competency',
                  hintText: 'Required competency or training',
                ),
              ),
              const SizedBox(width: 16),
              CustomButton(
                onPressed: _addCompetency,
                text: 'Add',
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _staffCompetencyRequired.map((competency) {
              return Chip(
                label: Text(competency),
                onDeleted: () => _removeCompetency(competency),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyProceduresSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Emergency Procedures'),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emergencyController,
            labelText: 'Emergency Procedures',
            hintText: 'Describe emergency procedures',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Additional Notes'),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _notesController,
            labelText: 'Notes',
            hintText: 'Additional notes or observations',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  String _getActivityTypeDisplay(ActivityType type) {
    switch (type) {
      case ActivityType.bathing: return 'Bathing';
      case ActivityType.dressing: return 'Dressing';
      case ActivityType.toileting: return 'Toileting';
      case ActivityType.mobility: return 'Mobility';
      case ActivityType.eating: return 'Eating';
      case ActivityType.drinking: return 'Drinking';
      case ActivityType.cooking: return 'Cooking';
      case ActivityType.cleaning: return 'Cleaning';
      case ActivityType.shopping: return 'Shopping';
      case ActivityType.appointments: return 'Appointments';
      case ActivityType.visits: return 'Visits';
      case ActivityType.outings: return 'Outings';
      case ActivityType.hobbies: return 'Hobbies';
      case ActivityType.exercise: return 'Exercise';
      case ActivityType.personalCare: return 'Personal Care';
    }
  }

  String _getFrequencyDisplay(FrequencyType type) {
    switch (type) {
      case FrequencyType.daily: return 'Daily';
      case FrequencyType.multipleTimesPerDay: return 'Multiple times per day';
      case FrequencyType.weekly: return 'Weekly';
      case FrequencyType.monthly: return 'Monthly';
      case FrequencyType.occasionally: return 'Occasionally';
      case FrequencyType.asNeeded: return 'As needed';
    }
  }

  String _getSupportLevelDisplay(SupportLevelType type) {
    switch (type) {
      case SupportLevelType.independent: return 'Independent';
      case SupportLevelType.supervision: return 'Supervision';
      case SupportLevelType.assistance: return 'Assistance';
      case SupportLevelType.fullAssistance: return 'Full Assistance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Activity Risk Assessment' : 'New Activity Risk Assessment',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildActivityTypeSelection(),
                    const SizedBox(height: 16),
                    _buildEquipmentSection(),
                    const SizedBox(height: 16),
                    _buildRisksSection(),
                    const SizedBox(height: 16),
                    _buildControlsSection(),
                    const SizedBox(height: 16),
                    _buildCompetencySection(),
                    const SizedBox(height: 16),
                    _buildEmergencyProceduresSection(),
                    const SizedBox(height: 16),
                    _buildNotesSection(),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            onPressed: _saveAssessment,
                            text: _isEditing ? 'Update Assessment' : 'Create Assessment',
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}