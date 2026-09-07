import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/anaphylaxis_assessment.dart';
import 'package:staff_app/services/anaphylaxis_service.dart';
import 'package:staff_app/services/service_user_service.dart';
import 'package:staff_app/services/carer_service.dart';
import 'package:staff_app/ui/common/custom_app_bar.dart';
import 'package:staff_app/ui/common/custom_button.dart';
import 'package:staff_app/ui/common/custom_text_field.dart';
import 'package:staff_app/ui/common/loading_overlay.dart';
import 'package:staff_app/ui/common/section_header.dart';
import 'package:staff_app/utils/constants.dart';
import 'package:staff_app/utils/date_utils.dart';
import 'package:staff_app/utils/dialog_utils.dart';
import 'package:staff_app/utils/snackbar_utils.dart';

class AnaphylaxisRiskForm extends StatefulWidget {
  final String? assessmentId;
  final String? serviceUserId;
  final String? assessorId;

  const AnaphylaxisRiskForm({
    Key? key,
    this.assessmentId,
    this.serviceUserId,
    this.assessorId,
  }) : super(key: key);

  @override
  _AnaphylaxisRiskFormState createState() => _AnaphylaxisRiskFormState();
}

class _AnaphylaxisRiskFormState extends State<AnaphylaxisRiskForm> {
  final _anaphylaxisService = AnaphylaxisService(Supabase.instance.client);
  final _serviceUserService = ServiceUserService(Supabase.instance.client);
  final _carerService = CarerService(Supabase.instance.client);

  late AnaphylaxisAssessment _assessment;
  late bool _isLoading = false;
  late bool _isEditing = false;
  late String _serviceUserName = '';
  late String _assessorName = '';

  final _allergenController = TextEditingController();
  final _allergenDetailsController = TextEditingController();
  final _previousReactionDetailsController = TextEditingController();
  final _autoinjectorTypeController = TextEditingController();
  final _autoinjectorLocationController = TextEditingController();
  final _actionPlanLocationController = TextEditingController();
  final _actionPlanReviewController = TextEditingController();
  final _staffTrainingController = TextEditingController();
  final _staffTrainingExpiryController = TextEditingController();
  final _allergyAlertLocationController = TextEditingController();
  final _medicalIdDetailsController = TextEditingController();
  final _specialistNameController = TextEditingController();
  final _lastAppointmentController = TextEditingController();
  final _nextAppointmentController = TextEditingController();
  final _crossReactivityDetailsController = TextEditingController();
  final _dietaryDetailsController = TextEditingController();
  final _assessmentNotesController = TextEditingController();

  // Form keys for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    setState(() => _isLoading = true);
    try {
      if (widget.assessmentId != null) {
        // Editing existing assessment
        _isEditing = true;
        final assessment = await _anaphylaxisService.getAssessmentById(widget.assessmentId!);
        if (assessment != null) {
          _assessment = assessment;
          _populateControllers();
        }
      } else {
        // Creating new assessment
        _assessment = AnaphylaxisAssessment.createNew(
          serviceUserId: widget.serviceUserId ?? '',
          assessorId: widget.assessorId ?? Supabase.instance.client.auth.currentSession?.user.id ?? '',
        );
      }

      // Load user names
      if (widget.serviceUserId != null) {
        final serviceUser = await _serviceUserService.getServiceUserById(widget.serviceUserId!);
        _serviceUserName = serviceUser?.fullName ?? 'Unknown Service User';
      }

      if (_assessment.assessorId != null) {
        final assessor = await _carerService.getCarerById(_assessment.assessorId);
        _assessorName = assessor?.fullName ?? 'Unknown Assessor';
      }
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to load assessment: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    _allergenController.text = _assessment.allergens.join(', ');
    _allergenDetailsController.text = _assessment.allergenDetails ?? '';
    _previousReactionDetailsController.text = _assessment.previousReactionDetails ?? '';
    _autoinjectorTypeController.text = _assessment.autoinjectorType ?? '';
    _autoinjectorLocationController.text = _assessment.autoinjectorLocation ?? '';
    _actionPlanLocationController.text = _assessment.actionPlanLocation ?? '';
    _actionPlanReviewController.text = _assessment.actionPlanReviewDate != null 
        ? DateFormat('dd/MM/yyyy').format(_assessment.actionPlanReviewDate!)
        : '';
    _staffTrainingController.text = _assessment.staffTrainingDate != null 
        ? DateFormat('dd/MM/yyyy').format(_assessment.staffTrainingDate!)
        : '';
    _staffTrainingExpiryController.text = _assessment.staffTrainingExpiryDate != null 
        ? DateFormat('dd/MM/yyyy').format(_assessment.staffTrainingExpiryDate!)
        : '';
    _allergyAlertLocationController.text = _assessment.allergyAlertLocation ?? '';
    _medicalIdDetailsController.text = _assessment.medicalIdDetails ?? '';
    _specialistNameController.text = _assessment.specialistName ?? '';
    _lastAppointmentController.text = _assessment.lastAppointmentDate != null 
        ? DateFormat('dd/MM/yyyy').format(_assessment.lastAppointmentDate!)
        : '';
    _nextAppointmentController.text = _assessment.nextAppointmentDate != null 
        ? DateFormat('dd/MM/yyyy').format(_assessment.nextAppointmentDate!)
        : '';
    _crossReactivityDetailsController.text = _assessment.crossReactivityDetails ?? '';
    _dietaryDetailsController.text = _assessment.dietaryDetails ?? '';
    _assessmentNotesController.text = _assessment.assessmentNotes ?? '';
  }

  void _updateAssessmentFromForm() {
    // Update allergens
    final allergensText = _allergenController.text.trim();
    _assessment = _assessment.copyWith(
      allergens: allergensText.isNotEmpty ? allergensText.split(',').map((s) => s.trim()).toList() : [],
      allergenDetails: _allergenDetailsController.text.trim(),
      previousReactionDetails: _previousReactionDetailsController.text.trim(),
      autoinjectorType: _autoinjectorTypeController.text.trim(),
      autoinjectorLocation: _autoinjectorLocationController.text.trim(),
      actionPlanLocation: _actionPlanLocationController.text.trim(),
      allergyAlertLocation: _allergyAlertLocationController.text.trim(),
      medicalIdDetails: _medicalIdDetailsController.text.trim(),
      specialistName: _specialistNameController.text.trim(),
      crossReactivityDetails: _crossReactivityDetailsController.text.trim(),
      dietaryDetails: _dietaryDetailsController.text.trim(),
      assessmentNotes: _assessmentNotesController.text.trim(),
    );

    // Update dates
    if (_actionPlanReviewController.text.isNotEmpty) {
      final date = DateUtils.parseDate(_actionPlanReviewController.text);
      if (date != null) {
        _assessment = _assessment.copyWith(actionPlanReviewDate: date);
      }
    }

    if (_staffTrainingController.text.isNotEmpty) {
      final date = DateUtils.parseDate(_staffTrainingController.text);
      if (date != null) {
        _assessment = _assessment.copyWith(staffTrainingDate: date);
      }
    }

    if (_staffTrainingExpiryController.text.isNotEmpty) {
      final date = DateUtils.parseDate(_staffTrainingExpiryController.text);
      if (date != null) {
        _assessment = _assessment.copyWith(staffTrainingExpiryDate: date);
      }
    }

    if (_lastAppointmentController.text.isNotEmpty) {
      final date = DateUtils.parseDate(_lastAppointmentController.text);
      if (date != null) {
        _assessment = _assessment.copyWith(lastAppointmentDate: date);
      }
    }

    if (_nextAppointmentController.text.isNotEmpty) {
      final date = DateUtils.parseDate(_nextAppointmentController.text);
      if (date != null) {
        _assessment = _assessment.copyWith(nextAppointmentDate: date);
      }
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    _updateAssessmentFromForm();

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        await _anaphylaxisService.updateAssessment(_assessment);
        SnackbarUtils.showSuccessSnackbar(context, 'Anaphylaxis assessment updated successfully!');
      } else {
        final id = await _anaphylaxisService.createAssessment(_assessment);
        _assessment = _assessment.copyWith(id: id);
        _isEditing = true;
        SnackbarUtils.showSuccessSnackbar(context, 'Anaphylaxis assessment created successfully!');
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to save assessment: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    _updateAssessmentFromForm();

    // Check if assessment is complete
    final validationErrors = _assessment.getValidationErrors();
    if (validationErrors.isNotEmpty) {
      await DialogUtils.showValidationErrorDialog(context, validationErrors);
      return;
    }

    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      'Submit Assessment',
      'Are you sure you want to submit this anaphylaxis assessment? This will calculate the risk level and may trigger escalation.',
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _anaphylaxisService.submitAssessment(_assessment.id!, '');
        SnackbarUtils.showSuccessSnackbar(context, 'Anaphylaxis assessment submitted successfully!');
        Navigator.pop(context, true);
      } catch (e) {
        SnackbarUtils.showSnackbar(context, 'Failed to submit assessment: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAllergyIdentificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Allergy Identification'),
        CustomTextField(
          controller: _allergenController,
          labelText: 'Allergens (comma-separated)',
          hintText: 'e.g., Peanuts, Shellfish, Latex',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'At least one allergen must be specified';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _allergenDetailsController,
          labelText: 'Allergen Details',
          hintText: 'Additional information about specific allergens',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildReactionHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Reaction History'),
        DropdownButtonFormField<String>(
          value: _assessment.previousReactionSeverity,
          decoration: const InputDecoration(
            labelText: 'Previous Reaction Severity',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: 'mild', child: Text('Mild Reaction')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderate Reaction')),
            DropdownMenuItem(value: 'severe', child: Text('Severe Reaction')),
            DropdownMenuItem(value: 'anaphylactic', child: Text('Anaphylactic Reaction')),
          ],
          onChanged: (value) {
            setState(() {
              _assessment = _assessment.copyWith(previousReactionSeverity: value);
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Previous reaction severity must be specified';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _previousReactionDetailsController,
          labelText: 'Reaction Details',
          hintText: 'Describe the previous reaction',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildAutoinjectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Auto-injector Management'),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Auto-injector prescribed'),
                value: _assessment.autoinjectorPrescribed,
                onChanged: (value) {
                  setState(() {
                    _assessment = _assessment.copyWith(autoinjectorPrescribed: value ?? false);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_assessment.autoinjectorPrescribed) ...[
          CustomTextField(
            controller: _autoinjectorTypeController,
            labelText: 'Auto-injector Type',
            hintText: 'EpiPen, Jext, Emerade, etc.',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _autoinjectorLocationController,
            labelText: 'Auto-injector Location',
            hintText: 'Where is the auto-injector stored?',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: TextEditingController(
              text: _assessment.autoinjectorExpiryDate != null 
                  ? DateFormat('dd/MM/yyyy').format(_assessment.autoinjectorExpiryDate!)
                  : ''
            ),
            labelText: 'Auto-injector Expiry Date',
            hintText: 'dd/MM/yyyy',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _assessment.autoinjectorExpiryDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _assessment = _assessment.copyWith(autoinjectorExpiryDate: date);
                });
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEmergencyPreparednessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Emergency Preparedness'),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Emergency action plan in place'),
                value: _assessment.emergencyActionPlan,
                onChanged: (value) {
                  setState(() {
                    _assessment = _assessment.copyWith(emergencyActionPlan: value ?? false);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_assessment.emergencyActionPlan) ...[
          CustomTextField(
            controller: _actionPlanLocationController,
            labelText: 'Action Plan Location',
            hintText: 'Where is the action plan stored?',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _actionPlanReviewController,
            labelText: 'Action Plan Review Date',
            hintText: 'dd/MM/yyyy',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _assessment.actionPlanReviewDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _assessment = _assessment.copyWith(actionPlanReviewDate: date);
                });
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStaffTrainingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Staff Training and Awareness'),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Staff trained in auto-injector use'),
                value: _assessment.staffTrainedAutoinjector,
                onChanged: (value) {
                  setState(() {
                    _assessment = _assessment.copyWith(staffTrainedAutoinjector: value ?? false);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_assessment.staffTrainedAutoinjector) ...[
          CustomTextField(
            controller: _staffTrainingController,
            labelText: 'Staff Training Date',
            hintText: 'dd/MM/yyyy',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _assessment.staffTrainingDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _assessment = _assessment.copyWith(staffTrainingDate: date);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _staffTrainingExpiryController,
            labelText: 'Staff Training Expiry Date',
            hintText: 'dd/MM/yyyy',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _assessment.staffTrainingExpiryDate ?? DateTime.now().add(Duration(days: 365)),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _assessment = _assessment.copyWith(staffTrainingExpiryDate: date);
                });
              }
            },
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Service user able to self-administer'),
                value: _assessment.serviceUserSelfAdminister,
                onChanged: (value) {
                  setState(() {
                    _assessment = _assessment.copyWith(serviceUserSelfAdminister: value ?? false);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAllergyAwarenessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Allergy Awareness'),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Allergy alert visible'),
                value: _assessment.allergyAlertVisible,
                onChanged: (value) {
                  setState(() {
                    _assessment = _assessment.copyWith(allergyAlertVisible: value ?? false);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_assessment.allergyAlertVisible) ...[
          CustomTextField(
            controller: _allergyAlertLocationController,
            labelText: 'Allergy Alert Location',
            hintText: 'Where is the allergy alert displayed?',
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Medical ID jewellery worn'),
                value: _assessment.medicalIdJewellery,
                onChanged: (value) {
                  setState(() {
                    _assessment = _assessment.copyWith(medicalIdJewellery: value ?? false);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_assessment.medicalIdJewellery) ...[
          CustomTextField(
            controller: _medicalIdDetailsController,
            labelText: 'Medical ID Details',
            hintText: 'Details about the medical ID jewellery',
          ),
        ],
      ],
    );
  }

  Widget _buildSpecialistCareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Specialist Care'),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text('Allergy specialist referral'),
                value: _assessment.allergySpecialistReferral,
                onChanged: (value) {
                  setState(() {
                    _assessment = _assessment.copyWith(allergySpecialistReferral: value ?? false);
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_assessment.allergySpecialistReferral) ...[
          CustomTextField(
            controller: _specialistNameController,
            labelText: 'Specialist Name',
            hintText: 'Name of the allergy specialist',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _lastAppointmentController,
            labelText: 'Last Appointment Date',
            hintText: 'dd/MM/yyyy',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _assessment.lastAppointmentDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _assessment = _assessment.copyWith(lastAppointmentDate: date);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _nextAppointmentController,
            labelText: 'Next Appointment Date',
            hintText: 'dd/MM/yyyy',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _assessment.nextAppointmentDate ?? DateTime.now().add(Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _assessment = _assessment.copyWith(nextAppointmentDate: date);
                });
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRiskManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Risk Management'),
        CustomTextField(
          controller: _crossReactivityDetailsController,
          labelText: 'Cross-reactivity Details',
          hintText: 'Details about cross-reactivity risks',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _dietaryDetailsController,
          labelText: 'Dietary Details',
          hintText: 'Details about dietary restrictions',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDocumentationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Documentation'),
        CustomTextField(
          controller: _assessmentNotesController,
          labelText: 'Assessment Notes',
          hintText: 'Additional notes about the assessment',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildRiskLevelDisplay() {
    final riskLevel = _assessment.calculateRiskLevel();
    final autoinjectorStatus = _assessment.getAutoinjectorStatus();
    final needsEscalation = _assessment.needsEscalation();

    return Card(
      color: needsEscalation ? Colors.red[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Assessment Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Current Risk Level: '),
                Chip(
                  label: Text(
                    riskLevel.toUpperCase(),
                    style: TextStyle(
                      color: needsEscalation ? Colors.red[800] : Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: needsEscalation ? Colors.red[100] : Colors.blue[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Auto-injector Status: '),
                Chip(
                  label: Text(
                    autoinjectorStatus.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: autoinjectorStatus == 'expired' ? Colors.red[100] : Colors.green[100],
                ),
              ],
            ),
            if (needsEscalation) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ This assessment requires immediate escalation due to high risk level.',
                style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Anaphylaxis Assessment' : 'New Anaphylaxis Assessment',
        showBackButton: true,
        actions: [
          if (_isEditing && _assessment.status != 'completed')
            IconButton(
              icon: Icon(Icons.check, color: Colors.white),
              onPressed: _submitAssessment,
              tooltip: 'Submit Assessment',
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Constants.primaryColor))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service User: $_serviceUserName',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Assessor: $_assessorName',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${DateFormat('dd/MM/yyyy').format(_assessment.createdAt)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Risk level display
                    _buildRiskLevelDisplay(),
                    const SizedBox(height: 16),

                    // Form sections
                    _buildAllergyIdentificationSection(),
                    const SizedBox(height: 16),
                    _buildReactionHistorySection(),
                    const SizedBox(height: 16),
                    _buildAutoinjectorSection(),
                    const SizedBox(height: 16),
                    _buildEmergencyPreparednessSection(),
                    const SizedBox(height: 16),
                    _buildStaffTrainingSection(),
                    const SizedBox(height: 16),
                    _buildAllergyAwarenessSection(),
                    const SizedBox(height: 16),
                    _buildSpecialistCareSection(),
                    const SizedBox(height: 16),
                    _buildRiskManagementSection(),
                    const SizedBox(height: 16),
                    _buildDocumentationSection(),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: _isEditing ? 'Update Assessment' : 'Create Assessment',
                            onPressed: _saveAssessment,
                            color: Constants.primaryColor,
                            textColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_isEditing && _assessment.status != 'completed')
                          Expanded(
                            child: CustomButton(
                              text: 'Submit',
                              onPressed: _submitAssessment,
                              color: Colors.red,
                              textColor: Colors.white,
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

  @override
  void dispose() {
    _allergenController.dispose();
    _allergenDetailsController.dispose();
    _previousReactionDetailsController.dispose();
    _autoinjectorTypeController.dispose();
    _autoinjectorLocationController.dispose();
    _actionPlanLocationController.dispose();
    _actionPlanReviewController.dispose();
    _staffTrainingController.dispose();
    _staffTrainingExpiryController.dispose();
    _allergyAlertLocationController.dispose();
    _medicalIdDetailsController.dispose();
    _specialistNameController.dispose();
    _lastAppointmentController.dispose();
    _nextAppointmentController.dispose();
    _crossReactivityDetailsController.dispose();
    _dietaryDetailsController.dispose();
    _assessmentNotesController.dispose();
    super.dispose();
  }
}