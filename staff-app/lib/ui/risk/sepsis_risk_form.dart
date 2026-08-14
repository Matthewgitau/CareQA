import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/sepsis_assessment.dart';
import 'package:staff_app/services/sepsis_service.dart';
import 'package:staff_app/ui/common/custom_app_bar.dart';
import 'package:staff_app/ui/common/custom_button.dart';
import 'package:staff_app/ui/common/custom_card.dart';
import 'package:staff_app/ui/common/custom_text_field.dart';
import 'package:staff_app/ui/common/section_header.dart';
import 'package:staff_app/utils/constants.dart';
import 'package:staff_app/utils/date_utils.dart';
import 'package:staff_app/utils/dialog_utils.dart';
import 'package:staff_app/utils/snackbar_utils.dart';

class SepsisRiskForm extends StatefulWidget {
  final String? assessmentId;
  final String? serviceUserId;
  final String? assessorId;

  const SepsisRiskForm({
    Key? key,
    this.assessmentId,
    this.serviceUserId,
    this.assessorId,
  }) : super(key: key);

  @override
  _SepsisRiskFormState createState() => _SepsisRiskFormState();
}

class _SepsisRiskFormState extends State<SepsisRiskForm> {
  final _sepsisService = SepsisService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _temperatureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _oxygenSaturationController = TextEditingController();
  final _systolicBpController = TextEditingController();
  final _infectionSourceController = TextEditingController();
  final _hospitalOutcomeController = TextEditingController();
  final _assessorSignatureController = TextEditingController();

  // Form fields
  DateTime? _assessmentDate;
  TimeOfDay? _assessmentTime;
  double? _temperature;
  int? _heartRate;
  int? _respiratoryRate;
  double? _oxygenSaturation;
  int? _systolicBp;
  ConsciousnessLevel? _consciousnessLevel;
  bool _newConfusion = false;
  List<String> _signsOfInfection = [];
  String? _infectionSource;
  bool _patientUnwell = false;
  bool _familyConcerned = false;
  List<bool> _sepsisSixCompleted = [false, false, false, false, false, false];
  Map<String, dynamic> _sepsisSixDetails = {};
  bool _referralToHospital = false;
  DateTime? _referralTime;
  String? _hospitalOutcome;
  String? _assessorSignature;
  DateTime? _reviewTime;

  bool _isLoading = false;
  bool _isEditing = false;
  int _news2Score = 0;
  SepsisRiskLevel _sepsisRiskLevel = SepsisRiskLevel.low;
  ActionTaken _actionTaken = ActionTaken.monitor;

  @override
  void initState() {
    super.initState();
    _assessmentDate = DateTime.now();
    _assessmentTime = TimeOfDay.now();
    if (widget.assessmentId != null) {
      _loadAssessment();
    }
  }

  Future<void> _loadAssessment() async {
    setState(() => _isLoading = true);
    try {
      final assessment = await _sepsisService.getAssessment(widget.assessmentId!);
      setState(() {
        _assessmentDate = assessment.assessmentDate;
        _assessmentTime = assessment.assessmentTime;
        _temperature = assessment.temperature;
        _heartRate = assessment.heartRate;
        _respiratoryRate = assessment.respiratoryRate;
        _oxygenSaturation = assessment.oxygenSaturation;
        _systolicBp = assessment.systolicBp;
        _consciousnessLevel = assessment.consciousnessLevel;
        _newConfusion = assessment.newConfusion;
        _signsOfInfection = assessment.signsOfInfection;
        _infectionSource = assessment.infectionSource;
        _patientUnwell = assessment.patientUnwell;
        _familyConcerned = assessment.familyConcerned;
        _sepsisSixCompleted = assessment.sepsisSixCompleted;
        _sepsisSixDetails = assessment.sepsisSixDetails;
        _referralToHospital = assessment.referralToHospital;
        _referralTime = assessment.referralTime;
        _hospitalOutcome = assessment.hospitalOutcome;
        _assessorSignature = assessment.assessorSignature;
        _reviewTime = assessment.reviewTime;
        _news2Score = assessment.news2Score;
        _sepsisRiskLevel = assessment.sepsisRiskLevel;
        _actionTaken = assessment.actionTaken;
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
      final assessment = SepsisAssessment(
        serviceUserId: widget.serviceUserId!,
        assessorId: widget.assessorId ?? Supabase.instance.client.auth.currentSession?.user.id,
        assessmentDate: _assessmentDate!,
        assessmentTime: _assessmentTime!,
        temperature: _temperature!,
        heartRate: _heartRate!,
        respiratoryRate: _respiratoryRate!,
        oxygenSaturation: _oxygenSaturation!,
        systolicBp: _systolicBp!,
        consciousnessLevel: _consciousnessLevel!,
        news2Score: _news2Score,
        newConfusion: _newConfusion,
        signsOfInfection: _signsOfInfection,
        infectionSource: _infectionSource,
        patientUnwell: _patientUnwell,
        familyConcerned: _familyConcerned,
        sepsisRiskLevel: _sepsisRiskLevel,
        actionTaken: _actionTaken,
        sepsisSixCompleted: _sepsisSixCompleted,
        sepsisSixDetails: _sepsisSixDetails,
        referralToHospital: _referralToHospital,
        referralTime: _referralTime,
        hospitalOutcome: _hospitalOutcome,
        assessorSignature: _assessorSignature,
        reviewTime: _reviewTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing && widget.assessmentId != null) {
        await _sepsisService.updateAssessment(widget.assessmentId!, assessment);
        SnackbarUtils.showSuccessSnackbar(context, 'Sepsis assessment updated successfully!');
      } else {
        await _sepsisService.createAssessment(assessment);
        SnackbarUtils.showSuccessSnackbar(context, 'Sepsis assessment created successfully!');
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to save assessment: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateScores() {
    if (_temperature != null && _heartRate != null && _respiratoryRate != null && 
        _oxygenSaturation != null && _systolicBp != null && _consciousnessLevel != null) {
      
      final assessment = SepsisAssessment(
        serviceUserId: widget.serviceUserId ?? '',
        assessorId: widget.assessorId ?? '',
        assessmentDate: _assessmentDate ?? DateTime.now(),
        assessmentTime: _assessmentTime ?? TimeOfDay.now(),
        temperature: _temperature!,
        heartRate: _heartRate!,
        respiratoryRate: _respiratoryRate!,
        oxygenSaturation: _oxygenSaturation!,
        systolicBp: _systolicBp!,
        consciousnessLevel: _consciousnessLevel!,
        news2Score: 0,
        newConfusion: _newConfusion,
        signsOfInfection: _signsOfInfection,
        infectionSource: _infectionSource,
        patientUnwell: _patientUnwell,
        familyConcerned: _familyConcerned,
        sepsisRiskLevel: SepsisRiskLevel.low,
        actionTaken: ActionTaken.monitor,
        sepsisSixCompleted: _sepsisSixCompleted,
        sepsisSixDetails: _sepsisSixDetails,
        referralToHospital: _referralToHospital,
        referralTime: _referralTime,
        hospitalOutcome: _hospitalOutcome,
        assessorSignature: _assessorSignature,
        reviewTime: _reviewTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _news2Score = assessment.calculateNews2Score();
        _sepsisRiskLevel = assessment.calculateSepsisRiskLevel();
        _actionTaken = assessment.determineActionTaken();
      });
    }
  }

  void _addSignOfInfection(String sign) {
    if (sign.isNotEmpty && !_signsOfInfection.contains(sign)) {
      setState(() {
        _signsOfInfection.add(sign);
      });
    }
  }

  void _removeSignOfInfection(String sign) {
    setState(() {
      _signsOfInfection.remove(sign);
    });
  }

  void _updateSepsisSix(int index, bool completed) {
    setState(() {
      _sepsisSixCompleted[index] = completed;
    });
  }

  void _updateSepsisSixDetails(String key, String value) {
    setState(() {
      _sepsisSixDetails[key] = value;
    });
  }

  Widget _buildVitalSignsSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Vital Signs & NEWS2 Score'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _temperatureController,
                  labelText: 'Temperature (°C)',
                  hintText: '36.1 - 42.0',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?(\.\d{0,1})?$'))],
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _temperature = double.tryParse(value);
                      });
                      _calculateScores();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter temperature';
                    final temp = double.tryParse(value);
                    if (temp == null) return 'Please enter a valid temperature';
                    if (temp < 34.0 || temp > 42.0) return 'Temperature must be between 34.0 and 42.0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _heartRateController,
                  labelText: 'Heart Rate (bpm)',
                  hintText: '20 - 220',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _heartRate = int.tryParse(value);
                      });
                      _calculateScores();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter heart rate';
                    final hr = int.tryParse(value);
                    if (hr == null) return 'Please enter a valid heart rate';
                    if (hr < 20 || hr > 220) return 'Heart rate must be between 20 and 220';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _respiratoryRateController,
                  labelText: 'Respiratory Rate (breaths/min)',
                  hintText: '4 - 50',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _respiratoryRate = int.tryParse(value);
                      });
                      _calculateScores();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter respiratory rate';
                    final rr = int.tryParse(value);
                    if (rr == null) return 'Please enter a valid respiratory rate';
                    if (rr < 4 || rr > 50) return 'Respiratory rate must be between 4 and 50';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _oxygenSaturationController,
                  labelText: 'Oxygen Saturation (%)',
                  hintText: '70.0 - 100.0',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?(\.\d{0,1})?$'))],
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _oxygenSaturation = double.tryParse(value);
                      });
                      _calculateScores();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter oxygen saturation';
                    final os = double.tryParse(value);
                    if (os == null) return 'Please enter a valid oxygen saturation';
                    if (os < 70.0 || os > 100.0) return 'Oxygen saturation must be between 70.0 and 100.0';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _systolicBpController,
                  labelText: 'Systolic BP (mmHg)',
                  hintText: '50 - 250',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _systolicBp = int.tryParse(value);
                      });
                      _calculateScores();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter systolic BP';
                    final bp = int.tryParse(value);
                    if (bp == null) return 'Please enter a valid systolic BP';
                    if (bp < 50 || bp > 250) return 'Systolic BP must be between 50 and 250';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<ConsciousnessLevel>(
                  value: _consciousnessLevel,
                  decoration: const InputDecoration(
                    labelText: 'Consciousness Level',
                    border: OutlineInputBorder(),
                  ),
                  items: ConsciousnessLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(_getConsciousnessDisplay(level)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _consciousnessLevel = value;
                    });
                    _calculateScores();
                  },
                  validator: (value) => value == null ? 'Please select consciousness level' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: _assessmentDate != null 
                      ? DateFormat('dd/MM/yyyy').format(_assessmentDate!)
                      : 'Select Date',
                  decoration: const InputDecoration(
                    labelText: 'Assessment Date',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _assessmentDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 30)),
                      lastDate: DateTime.now().add(Duration(days: 1)),
                    );
                    if (date != null) {
                      setState(() {
                        _assessmentDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: _assessmentTime != null 
                      ? _assessmentTime!.format(context)
                      : 'Select Time',
                  decoration: const InputDecoration(
                    labelText: 'Assessment Time',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _assessmentTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _assessmentTime = time;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: _news2Score.toString(),
                  decoration: const InputDecoration(
                    labelText: 'NEWS2 Score',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: _sepsisRiskLevel.toString().split('.').last.toUpperCase(),
                  decoration: InputDecoration(
                    labelText: 'Sepsis Risk Level',
                    border: OutlineInputBorder(),
                    fillColor: _getRiskColor(_sepsisRiskLevel),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: _actionTaken.toString().split('.').last.toUpperCase(),
                  decoration: const InputDecoration(
                    labelText: 'Recommended Action',
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

  Widget _buildSepsisIndicatorsSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Sepsis Indicators'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('New Confusion'),
                  value: _newConfusion,
                  onChanged: (value) {
                    setState(() {
                      _newConfusion = value ?? false;
                    });
                    _calculateScores();
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Patient Looks Unwell'),
                  value: _patientUnwell,
                  onChanged: (value) {
                    setState(() {
                      _patientUnwell = value ?? false;
                    });
                    _calculateScores();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Family Concerned'),
                  value: _familyConcerned,
                  onChanged: (value) {
                    setState(() {
                      _familyConcerned = value ?? false;
                    });
                    _calculateScores();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _infectionSourceController,
                  labelText: 'Suspected Infection Source',
                  hintText: 'e.g., UTI, Pneumonia, Wound',
                  onChanged: (value) => _infectionSource = value.isNotEmpty ? value : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Signs of Infection:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfectionChip('Fever'),
                  _buildInfectionChip('Shivering'),
                  _buildInfectionChip('Cold'),
                  _buildInfectionChip('Cough'),
                  _buildInfectionChip('Wound Redness'),
                  _buildInfectionChip('Urinary Symptoms'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      labelText: 'Add Other Sign',
                      hintText: 'Describe other signs',
                    ),
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    onPressed: () {},
                    text: 'Add',
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSepsisSixSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Sepsis Six Protocol'),
          const SizedBox(height: 16),
          _buildSepsisSixItem(0, 'High-flow oxygen', 'Oxygen saturation ≥ 94%'),
          _buildSepsisSixItem(1, 'Blood cultures', 'Before antibiotics if possible'),
          _buildSepsisSixItem(2, 'IV antibiotics', 'Within 1 hour'),
          _buildSepsisSixItem(3, 'IV fluids', '500ml crystalloid bolus'),
          _buildSepsisSixItem(4, 'Urine output', 'Catheter & measure hourly'),
          _buildSepsisSixItem(5, 'Blood glucose', 'Check & treat if needed'),
        ],
      ),
    );
  }

  Widget _buildEscalationSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Escalation & Referral'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Referral to Hospital'),
                  value: _referralToHospital,
                  onChanged: (value) {
                    setState(() {
                      _referralToHospital = value ?? false;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_referralToHospital)
            Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: _referralTime != null 
                            ? DateFormat('dd/MM/yyyy HH:mm').format(_referralTime!)
                            : 'Select Referral Time',
                        decoration: const InputDecoration(
                          labelText: 'Referral Time',
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _referralTime ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(Duration(hours: 24)),
                            lastDate: DateTime.now().add(Duration(hours: 24)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                _referralTime = DateTime(
                                  date.year, date.month, date.day,
                                  time.hour, time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _hospitalOutcomeController,
                  labelText: 'Hospital Outcome',
                  hintText: 'e.g., Admitted, Discharged, Deceased',
                ),
              ],
            ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _assessorSignatureController,
            labelText: 'Assessor Signature',
            hintText: 'Staff member name',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: _reviewTime != null 
                      ? DateFormat('dd/MM/yyyy HH:mm').format(_reviewTime!)
                      : 'Select Review Time',
                  decoration: const InputDecoration(
                    labelText: 'Next Review Time',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _reviewTime ?? DateTime.now().add(Duration(hours: 4)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 7)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _reviewTime = DateTime(
                            date.year, date.month, date.day,
                            time.hour, time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfectionChip(String sign) {
    return FilterChip(
      label: Text(sign),
      selected: _signsOfInfection.contains(sign),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _signsOfInfection.add(sign);
          } else {
            _signsOfInfection.remove(sign);
          }
        });
        _calculateScores();
      },
    );
  }

  Widget _buildSepsisSixItem(int index, String title, String description) {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(title),
          subtitle: Text(description),
          value: _sepsisSixCompleted[index],
          onChanged: (value) {
            _updateSepsisSix(index, value ?? false);
          },
        ),
        if (_sepsisSixCompleted[index])
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 16, bottom: 8),
            child: CustomTextField(
              labelText: 'Details',
              hintText: 'e.g., 2L via nasal specs',
              onChanged: (value) => _updateSepsisSixDetails(title.toLowerCase().replaceAll(' ', '_'), value),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  String _getConsciousnessDisplay(ConsciousnessLevel level) {
    switch (level) {
      case ConsciousnessLevel.alert: return 'Alert';
      case ConsciousnessLevel.voice: return 'Responds to Voice';
      case ConsciousnessLevel.pain: return 'Responds to Pain';
      case ConsciousnessLevel.unresponsive: return 'Unresponsive';
    }
  }

  Color _getRiskColor(SepsisRiskLevel riskLevel) {
    switch (riskLevel) {
      case SepsisRiskLevel.low: return Colors.green[100]!;
      case SepsisRiskLevel.medium: return Colors.yellow[100]!;
      case SepsisRiskLevel.high: return Colors.orange[100]!;
      case SepsisRiskLevel.critical: return Colors.red[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Sepsis Assessment' : 'New Sepsis Assessment',
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
                    _buildVitalSignsSection(),
                    const SizedBox(height: 16),
                    _buildSepsisIndicatorsSection(),
                    const SizedBox(height: 16),
                    _buildSepsisSixSection(),
                    const SizedBox(height: 16),
                    _buildEscalationSection(),
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