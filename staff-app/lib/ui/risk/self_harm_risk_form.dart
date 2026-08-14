import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/self_harm_assessment.dart';
import 'package:staff_app/services/self_harm_service.dart';
import 'package:staff_app/services/service_user_service.dart';
import 'package:staff_app/services/carer_service.dart';
import 'package:staff_app/ui/common/custom_app_bar.dart';
import 'package:staff_app/ui/common/custom_button.dart';
import 'package:staff_app/ui/common/custom_text_field.dart';
import 'package:staff_app/ui/common/loading_overlay.dart';
import 'package:staff_app/ui/common/signature_pad.dart';
import 'package:staff_app/utils/constants.dart';
import 'package:staff_app/utils/date_utils.dart';
import 'package:staff_app/utils/dialog_utils.dart';
import 'package:staff_app/utils/form_validation.dart';
import 'package:staff_app/utils/snackbar_utils.dart';

class SelfHarmRiskForm extends StatefulWidget {
  final String? assessmentId;
  final String serviceUserId;
  final String? assessorId;

  const SelfHarmRiskForm({
    Key? key,
    this.assessmentId,
    required this.serviceUserId,
    this.assessorId,
  }) : super(key: key);

  @override
  _SelfHarmRiskFormState createState() => _SelfHarmRiskFormState();
}

class _SelfHarmRiskFormState extends State<SelfHarmRiskForm> {
  final _formKey = GlobalKey<FormState>();
  final _selfHarmService = SelfHarmService(Supabase.instance.client);
  final _serviceUserService = ServiceUserService(Supabase.instance.client);
  final _carerService = CarerService(Supabase.instance.client);

  late SelfHarmAssessment _assessment;
  late bool _isLoading = false;
  late bool _isSubmitting = false;
  late String _serviceUserName = '';
  late String _assessorName = '';

  // Form controllers
  final TextEditingController _currentIdeationDetailsController = TextEditingController();
  final TextEditingController _previousSelfHarmDetailsController = TextEditingController();
  final TextEditingController _selfHarmMethodOtherController = TextEditingController();
  final TextEditingController _triggerDetailsController = TextEditingController();
  final TextEditingController _protectiveFactorsDetailsController = TextEditingController();
  final TextEditingController _accessToMeansDetailsController = TextEditingController();
  final TextEditingController _mentalHealthDiagnosisController = TextEditingController();
  final TextEditingController _treatmentDetailsController = TextEditingController();
  final TextEditingController _recentLifeEventsController = TextEditingController();
  final TextEditingController _substanceDetailsController = TextEditingController();
  final TextEditingController _immediateActionsController = TextEditingController();
  final TextEditingController _followUpActionsController = TextEditingController();
  final TextEditingController _crisisContactsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _currentIdeationDetailsController.dispose();
    _previousSelfHarmDetailsController.dispose();
    _selfHarmMethodOtherController.dispose();
    _triggerDetailsController.dispose();
    _protectiveFactorsDetailsController.dispose();
    _accessToMeansDetailsController.dispose();
    _mentalHealthDiagnosisController.dispose();
    _treatmentDetailsController.dispose();
    _recentLifeEventsController.dispose();
    _substanceDetailsController.dispose();
    _immediateActionsController.dispose();
    _followUpActionsController.dispose();
    _crisisContactsController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    setState(() => _isLoading = true);
    try {
      if (widget.assessmentId != null) {
        // Edit existing assessment
        final assessment = await _selfHarmService.getAssessmentById(widget.assessmentId!);
        if (assessment != null) {
          _assessment = assessment;
        } else {
          _assessment = SelfHarmAssessment.createNew(widget.serviceUserId, widget.assessorId);
        }
      } else {
        // Create new assessment
        _assessment = SelfHarmAssessment.createNew(widget.serviceUserId, widget.assessorId);
      }

      // Load service user name
      final serviceUser = await _serviceUserService.getServiceUser(widget.serviceUserId);
      if (serviceUser != null) {
        _serviceUserName = '${serviceUser.firstName} ${serviceUser.lastName}';
      }

      // Load assessor name if provided
      if (widget.assessorId != null) {
        final assessor = await _carerService.getCarerById(widget.assessorId!);
        if (assessor != null) {
          _assessorName = '${assessor.firstName} ${assessor.lastName}';
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      SnackbarUtils.showSnackbar(context, 'Failed to load form: ${e.toString()}');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Update assessment with form data
      _assessment = _assessment.copyWith(
        currentSuicidalIdeationDetails: _currentIdeationDetailsController.text.trim(),
        previousSelfHarmDetails: _previousSelfHarmDetailsController.text.trim(),
        selfHarmMethodOther: _selfHarmMethodOtherController.text.trim(),
        triggerDetails: _triggerDetailsController.text.trim(),
        protectiveFactorsDetails: _protectiveFactorsDetailsController.text.trim(),
        accessToMeansDetails: _accessToMeansDetailsController.text.trim(),
        mentalHealthDiagnosis: _mentalHealthDiagnosisController.text.trim(),
        treatmentDetails: _treatmentDetailsController.text.trim(),
        recentLifeEvents: _recentLifeEventsController.text.trim(),
        substanceDetails: _substanceDetailsController.text.trim(),
        immediateActions: _immediateActionsController.text.trim(),
        followUpActions: _followUpActionsController.text.trim(),
        crisisContacts: _crisisContactsController.text.trim(),
      );

      String assessmentId;
      if (widget.assessmentId != null) {
        await _selfHarmService.updateAssessment(_assessment);
        assessmentId = widget.assessmentId!;
      } else {
        assessmentId = await _selfHarmService.createAssessment(_assessment);
      }

      // Show signature dialog for submission
      final signatureData = await showDialog<String>(
        context: context,
        builder: (context) => SignatureDialog(
          title: 'Sign Self-Harm Risk Assessment',
          subtitle: 'Please sign to submit this assessment',
        ),
      );

      if (signatureData != null) {
        await _selfHarmService.submitAssessment(assessmentId, signatureData);
        SnackbarUtils.showSuccessSnackbar(context, 'Self-harm risk assessment submitted successfully!');
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to submit assessment: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Update assessment with form data
      _assessment = _assessment.copyWith(
        currentSuicidalIdeationDetails: _currentIdeationDetailsController.text.trim(),
        previousSelfHarmDetails: _previousSelfHarmDetailsController.text.trim(),
        selfHarmMethodOther: _selfHarmMethodOtherController.text.trim(),
        triggerDetails: _triggerDetailsController.text.trim(),
        protectiveFactorsDetails: _protectiveFactorsDetailsController.text.trim(),
        accessToMeansDetails: _accessToMeansDetailsController.text.trim(),
        mentalHealthDiagnosis: _mentalHealthDiagnosisController.text.trim(),
        treatmentDetails: _treatmentDetailsController.text.trim(),
        recentLifeEvents: _recentLifeEventsController.text.trim(),
        substanceDetails: _substanceDetailsController.text.trim(),
        immediateActions: _immediateActionsController.text.trim(),
        followUpActions: _followUpActionsController.text.trim(),
        crisisContacts: _crisisContactsController.text.trim(),
      );

      if (widget.assessmentId != null) {
        await _selfHarmService.updateAssessment(_assessment);
      } else {
        final newId = await _selfHarmService.createAssessment(_assessment);
        // Update the widget with the new ID for future updates
        // This would require a callback or state management solution
      }

      SnackbarUtils.showSuccessSnackbar(context, 'Draft saved successfully!');
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to save draft: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Constants.primaryColor,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator() {
    if (_assessment.overallRiskLevel == null) return SizedBox();

    Color riskColor;
    String riskText;

    switch (_assessment.overallRiskLevel) {
      case 'low':
        riskColor = Colors.green;
        riskText = 'Low Risk';
        break;
      case 'medium':
        riskColor = Colors.orange;
        riskText = 'Medium Risk';
        break;
      case 'high':
        riskColor = Colors.red[700]!;
        riskText = 'High Risk';
        break;
      case 'immediate':
        riskColor = Colors.red;
        riskText = 'IMMEDIATE ESCALATION REQUIRED';
        break;
      default:
        riskColor = Colors.grey;
        riskText = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        border: Border.all(color: riskColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _assessment.overallRiskLevel == 'immediate' ? Icons.warning_amber : Icons.info_outline,
            color: riskColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              riskText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: riskColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Self-Harm Risk Assessment',
        showBackButton: true,
        actions: [
          if (widget.assessmentId != null)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirmed = await DialogUtils.showConfirmationDialog(
                  context,
                  'Delete Assessment',
                  'Are you sure you want to delete this assessment? This action cannot be undone.',
                );
                if (confirmed) {
                  try {
                    await _selfHarmService.deleteAssessment(widget.assessmentId!);
                    SnackbarUtils.showSuccessSnackbar(context, 'Assessment deleted successfully!');
                    Navigator.pop(context, true);
                  } catch (e) {
                    SnackbarUtils.showSnackbar(context, 'Failed to delete assessment: ${e.toString()}');
                  }
                }
              },
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isSubmitting,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Constants.primaryColor))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Information
                    _buildSectionHeader('Assessment Information'),
                    const SizedBox(height: 16),
                    Text('Service User: $_serviceUserName', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_assessorName.isNotEmpty) Text('Assessor: $_assessorName'),
                    Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                    const SizedBox(height: 24),

                    // Critical Risk Assessment
                    _buildSectionHeader('Current Suicidal Ideation', subtitle: 'CRITICAL - Immediate escalation required if "Constant"'),
                    const SizedBox(height: 16),
                    _buildRadioGroup(
                      options: SelfHarmAssessment.getCurrentSuicidalIdeationOptions(),
                      selectedValue: _assessment.currentSuicidalIdeation,
                      onValueChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(currentSuicidalIdeation: value!);
                          _calculateRiskLevel();
                        });
                      },
                      displayMapper: (value) => SelfHarmAssessment.fromJson({'current_suicidal_ideation': value}).getCurrentSuicidalIdeationDisplay(),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _currentIdeationDetailsController,
                      labelText: 'Details (if applicable)',
                      hintText: 'Describe current thoughts, plans, or intent',
                      maxLines: 3,
                      initialValue: _assessment.currentSuicidalIdeationDetails,
                    ),
                    const SizedBox(height: 24),

                    // Previous Self-Harm Attempts
                    _buildSectionHeader('Previous Self-Harm History'),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _previousSelfHarmDetailsController,
                      labelText: 'Previous Self-Harm Attempts',
                      hintText: 'Number of previous attempts and details',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      initialValue: _assessment.previousSelfHarmAttempts.toString(),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter number of previous attempts';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Method of Self-Harm',
                      value: _assessment.selfHarmMethod,
                      items: SelfHarmAssessment.getSelfHarmMethodOptions(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(selfHarmMethod: value);
                        });
                      },
                    ),
                    if (_assessment.selfHarmMethod == 'other')
                      CustomTextField(
                        controller: _selfHarmMethodOtherController,
                        labelText: 'Specify Other Method',
                        hintText: 'Please specify the method',
                        initialValue: _assessment.selfHarmMethodOther,
                      ),
                    const SizedBox(height: 8),
                    _buildCheckboxField(
                      label: 'Method Planned?',
                      value: _assessment.methodPlanned,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(methodPlanned: value!);
                          _calculateRiskLevel();
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Frequency and Triggers
                    _buildSectionHeader('Frequency and Triggers'),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Frequency of Thoughts',
                      value: _assessment.frequencyOfThoughts,
                      items: SelfHarmAssessment.getFrequencyOfThoughtsOptions(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(frequencyOfThoughts: value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Triggers', subtitle: 'Check all that apply'),
                    _buildCheckboxField(
                      label: 'Relationship Issues',
                      value: _assessment.relationshipTriggers,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(relationshipTriggers: value!);
                        });
                      },
                    ),
                    _buildCheckboxField(
                      label: 'Financial Problems',
                      value: _assessment.financialTriggers,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(financialTriggers: value!);
                        });
                      },
                    ),
                    _buildCheckboxField(
                      label: 'Health Issues',
                      value: _assessment.healthTriggers,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(healthTriggers: value!);
                        });
                      },
                    ),
                    _buildCheckboxField(
                      label: 'Other Triggers',
                      value: _assessment.otherTriggers,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(otherTriggers: value!);
                        });
                      },
                    ),
                    if (_assessment.otherTriggers)
                      CustomTextField(
                        controller: _triggerDetailsController,
                        labelText: 'Other Triggers Details',
                        hintText: 'Describe other triggers',
                        initialValue: _assessment.triggerDetails,
                      ),
                    const SizedBox(height: 24),

                    // Protective Factors
                    _buildSectionHeader('Protective Factors'),
                    const SizedBox(height: 16),
                    _buildCheckboxField(
                      label: 'Family Support',
                      value: _assessment.familySupport,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(familySupport: value!);
                        });
                      },
                    ),
                    _buildCheckboxField(
                      label: 'Friend Support',
                      value: _assessment.friendSupport,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(friendSupport: value!);
                        });
                      },
                    ),
                    _buildCheckboxField(
                      label: 'Routine Structure',
                      value: _assessment.routineStructure,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(routineStructure: value!);
                        });
                      },
                    ),
                    _buildCheckboxField(
                      label: 'Other Protective Factors',
                      value: _assessment.otherProtectiveFactors,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(otherProtectiveFactors: value!);
                        });
                      },
                    ),
                    if (_assessment.otherProtectiveFactors)
                      CustomTextField(
                        controller: _protectiveFactorsDetailsController,
                        labelText: 'Other Protective Factors Details',
                        hintText: 'Describe other protective factors',
                        initialValue: _assessment.protectiveFactorsDetails,
                      ),
                    const SizedBox(height: 24),

                    // Risk Factors
                    _buildSectionHeader('Risk Factors'),
                    const SizedBox(height: 16),
                    _buildCheckboxField(
                      label: 'Access to Means',
                      value: _assessment.accessToMeans,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(accessToMeans: value!);
                        });
                      },
                    ),
                    if (_assessment.accessToMeans)
                      CustomTextField(
                        controller: _accessToMeansDetailsController,
                        labelText: 'Access to Means Details',
                        hintText: 'Describe what means are accessible',
                        initialValue: _assessment.accessToMeansDetails,
                      ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _mentalHealthDiagnosisController,
                      labelText: 'Mental Health Diagnosis',
                      hintText: 'Current diagnoses (e.g., Depression, Bipolar, etc.)',
                      initialValue: _assessment.mentalHealthDiagnosis,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Current Treatment',
                      value: _assessment.currentTreatment,
                      items: SelfHarmAssessment.getCurrentTreatmentOptions(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(currentTreatment: value);
                        });
                      },
                    ),
                    if (_assessment.currentTreatment != 'none')
                      CustomTextField(
                        controller: _treatmentDetailsController,
                        labelText: 'Treatment Details',
                        hintText: 'Medication names, therapy type, dosage, etc.',
                        initialValue: _assessment.treatmentDetails,
                      ),
                    const SizedBox(height: 24),

                    // Additional Factors
                    _buildSectionHeader('Additional Factors'),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _recentLifeEventsController,
                      labelText: 'Recent Life Events',
                      hintText: 'Recent stressors, losses, changes, etc.',
                      maxLines: 3,
                      initialValue: _assessment.recentLifeEvents,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Substance Use',
                      value: _assessment.substanceUse,
                      items: SelfHarmAssessment.getSubstanceUseOptions(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(substanceUse: value);
                        });
                      },
                    ),
                    if (_assessment.substanceUse != 'none')
                      CustomTextField(
                        controller: _substanceDetailsController,
                        labelText: 'Substance Use Details',
                        hintText: 'Type, frequency, impact on mood/behavior',
                        initialValue: _assessment.substanceDetails,
                      ),
                    const SizedBox(height: 16),
                    _buildCheckboxField(
                      label: 'Sleep Disturbances',
                      value: _assessment.sleepDisturbances,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(sleepDisturbances: value!);
                        });
                      },
                    ),
                    _buildCheckboxField(
                      label: 'Withdrawal from Activities',
                      value: _assessment.withdrawalFromActivities,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(withdrawalFromActivities: value!);
                        });
                      },
                    ),
                    _buildCheckboxField(
                      label: 'Giving Away Possessions',
                      value: _assessment.givingAwayPossessions,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(givingAwayPossessions: value!);
                          _calculateRiskLevel();
                        });
                      },
                    ),
                    _buildCheckboxField(
                      label: 'Making Plans/Arrangements',
                      value: _assessment.makingPlansArrangements,
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(makingPlansArrangements: value!);
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Risk Assessment and Action Plan
                    _buildSectionHeader('Risk Assessment'),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Overall Risk Level',
                      value: _assessment.overallRiskLevel,
                      items: SelfHarmAssessment.getRiskLevels(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(overallRiskLevel: value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildRiskIndicator(),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _immediateActionsController,
                      labelText: 'Immediate Actions Required',
                      hintText: 'What needs to happen right now?',
                      maxLines: 3,
                      initialValue: _assessment.immediateActions,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _followUpActionsController,
                      labelText: 'Follow-up Actions',
                      hintText: 'Ongoing monitoring, appointments, etc.',
                      maxLines: 4,
                      initialValue: _assessment.followUpActions,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _crisisContactsController,
                      labelText: 'Crisis Contacts',
                      hintText: 'Emergency numbers, crisis teams, key contacts',
                      maxLines: 3,
                      initialValue: _assessment.crisisContacts,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      labelText: 'Next Review Date',
                      hintText: 'When should this assessment be reviewed?',
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _assessment.nextReviewDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(Duration(days: 30)),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _assessment = _assessment.copyWith(nextReviewDate: date);
                          });
                        }
                      },
                      initialValue: _assessment.nextReviewDate != null
                          ? DateFormat('dd/MM/yyyy').format(_assessment.nextReviewDate!)
                          : '',
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Save Draft',
                            onPressed: _saveDraft,
                            color: Constants.secondaryColor,
                            isLoading: _isSubmitting,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Submit Assessment',
                            onPressed: _submitForm,
                            isLoading: _isSubmitting,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRadioGroup({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String?> onValueChanged,
    required String Function(String) displayMapper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((option) {
        return Row(
          children: [
            Radio<String>(
              value: option,
              groupValue: selectedValue,
              onChanged: onValueChanged,
              activeColor: Constants.primaryColor,
            ),
            Text(displayMapper(option)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDropdownField({
    required String label,
    String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCheckboxField({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Constants.primaryColor,
        ),
        Text(label),
      ],
    );
  }

  void _calculateRiskLevel() async {
    try {
      final riskLevel = await _selfHarmService.calculateRiskLevel(
        currentIdeation: _assessment.currentSuicidalIdeation,
        methodPlanned: _assessment.methodPlanned,
        givingAwayPossessions: _assessment.givingAwayPossessions,
        previousAttempts: _assessment.previousSelfHarmAttempts,
        accessToMeans: _assessment.accessToMeans,
      );

      setState(() {
        _assessment = _assessment.copyWith(overallRiskLevel: riskLevel);
      });

      // Show escalation warning if needed
      if (_assessment.requiresImmediateEscalation) {
        DialogUtils.showAlertDialog(
          context,
          'IMMEDIATE ESCALATION REQUIRED',
          'This assessment indicates immediate risk. Please follow your facility\'s escalation protocol immediately.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('I Understand', style: TextStyle(color: Constants.primaryColor)),
            ),
          ],
        );
      }
    } catch (e) {
      // If calculation fails, use basic logic
      String riskLevel = 'low';
      if (_assessment.currentSuicidalIdeation == 'constant') {
        riskLevel = 'immediate';
      } else if (_assessment.methodPlanned || _assessment.givingAwayPossessions) {
        riskLevel = 'high';
      } else if (_assessment.previousSelfHarmAttempts > 0 || _assessment.accessToMeans) {
        riskLevel = 'medium';
      }

      setState(() {
        _assessment = _assessment.copyWith(overallRiskLevel: riskLevel);
      });
    }
  }
}