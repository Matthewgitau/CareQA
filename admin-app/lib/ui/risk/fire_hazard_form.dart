import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/fire_hazard_assessment.dart';
import '../../services/fire_hazard_service.dart';

class FireHazardForm extends StatefulWidget {
  final FireHazardAssessment? assessment;
  final String? serviceUserId;

  const FireHazardForm({
    Key? key,
    this.assessment,
    this.serviceUserId,
  }) : super(key: key);

  @override
  _FireHazardFormState createState() => _FireHazardFormState();
}

class _FireHazardFormState extends State<FireHazardForm> {
  final _formKey = GlobalKey<FormState>();
  final _fireHazardService = FireHazardService(Supabase.instance.client);
  final _supabase = Supabase.instance.client;
  
  late FireHazardAssessment _assessment;
  bool _isLoading = false;
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;

  final TextEditingController _assessmentDateController = TextEditingController();
  final TextEditingController _assessorNameController = TextEditingController();
  final TextEditingController _fireWardenNameController = TextEditingController();
  final TextEditingController _fireAlarmTestDateController = TextEditingController();
  final TextEditingController _emergencyLightingTestDateController = TextEditingController();
  final TextEditingController _fireExtinguisherNextServiceDueController = TextEditingController();
  final TextEditingController _fireBlanketServiceDateController = TextEditingController();
  final TextEditingController _staffTrainingNextDueController = TextEditingController();
  final TextEditingController _patTestExpiryDateController = TextEditingController();
  final TextEditingController _fireRiskAssessmentReviewDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    _initializeAssessment();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await _supabase
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _fetchAndSetServiceUserName(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    try {
      final response = await _supabase
          .from('service_users')
          .select('name')
          .eq('id', userId)
          .single();
      final name = response['name'] as String? ?? '';
      _assessment = _assessment.copyWith(serviceUserId: userId);
      setState(() {});
    } catch (_) {}
  }

  String _calculateRiskLevel() {
    int riskScore = 0;
    if (_assessment.fireAlarmWeeklyTestRecorded != true) riskScore += 2;
    if (_assessment.emergencyLightingWorking != true) riskScore += 2;
    if (_assessment.fireExitSignsIlluminated != true) riskScore += 1;
    if (_assessment.finalExitsOpenOutward != true) riskScore += 2;
    if (_assessment.escapeRoutesSuitableForMobilityAids != true) riskScore += 2;
    if (_assessment.staffFireTrainingCompleted != true) riskScore += 3;
    if (_assessment.fireDrillConducted != true) riskScore += 2;
    if (_assessment.fireExtinguisherNextServiceDue == null) riskScore += 2;
    if (_assessment.fireAlarmTestDate == null) riskScore += 2;
    if (riskScore >= 10) return 'high';
    if (riskScore >= 5) return 'medium';
    return 'low';
  }

  @override
  void dispose() {
    _assessmentDateController.dispose();
    _assessorNameController.dispose();
    _fireWardenNameController.dispose();
    _fireAlarmTestDateController.dispose();
    _emergencyLightingTestDateController.dispose();
    _fireExtinguisherNextServiceDueController.dispose();
    _fireBlanketServiceDateController.dispose();
    _staffTrainingNextDueController.dispose();
    _patTestExpiryDateController.dispose();
    _fireRiskAssessmentReviewDateController.dispose();
    super.dispose();
  }

  Future<void> _initializeAssessment() async {
    if (widget.assessment != null) {
      _assessment = widget.assessment!;
    } else {
      _assessment = FireHazardAssessment(
        id: '',
        serviceUserId: widget.serviceUserId ?? '',
        assessmentDate: DateTime.now(),
        assessorName: '',
        fireWardenName: '',
        riskLevel: 'low',
        fireAlarmSystemType: 'manual',
        smokeDetectorsPresent: 'yes',
        fireExtinguisherTypes: [],
        fireAlarmTestDate: null,
        emergencyLightingTestDate: null,
        fireExtinguisherNextServiceDue: null,
        fireBlanketServiceDate: null,
        staffTrainingNextDue: null,
        patTestExpiryDate: null,
        fireRiskAssessmentReviewDate: null,
        fireAlarmWeeklyTestRecorded: false,
        emergencyLightingWorking: false,
        fireExitSignsIlluminated: false,
        finalExitsOpenOutward: false,
        escapeRoutesSuitableForMobilityAids: false,
        peepsReviewedAnnually: false,
        evacuationPlanRehearsed: false,
        visitorsSignedInOut: false,
        nightStaffNumbersAdequate: false,
        disabledRefugePointsIdentified: false,
        staffFireTrainingCompleted: false,
        fireDrillConducted: false,
        fireWardenAppointed: false,
        fireExtinguisherLocationsDocumented: false,
        equipmentInspectedMonthly: false,
        heatDetectorsInKitchens: false,
        fireBlanketInKitchen: false,
        fireHoseReelPresent: false,
        cookerIsolatorSwitchAccessible: false,
        patTestingUpToDate: false,
        staffKnowPeepsForAssignedServiceUsers: false,
        evacuationPlanDisplayed: false,
        fireLogBookMaintained: false,
        weeklyChecksRecorded: false,
        monthlyChecksRecorded: false,
        kitchenExtractorHoodCleaned: false,
        laundryDryerLintFilterCleaned: false,
        electricalEquipmentNotOverloaded: false,
        chargingDevicesOnNonFlammableSurface: false,
        externalWasteBinsAwayFromBuilding: false,
        binStoresLocked: false,
        externalLightingWorking: false,
        intruderAlarmWorking: false,
        fireDoorsSelfClosing: false,
        fireDoorGapsLessThan4mm: false,
        fireDoorSealsIntact: false,
        compartmentWallsIntact: false,
        ceilingFloorPenetrationsSealed: false,
        emergencyExitsClearlyMarked: false,
        exitDoorsOpenEasily: false,
        exitRoutesUnobstructed: false,
        fireDrillFrequency: 'monthly',
        peepsInPlaceForAllServiceUsers: 'yes',
        actionItems: [],
        responsiblePerson: '',
        completionDeadline: null,
        reviewDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Set initial values for controllers
    _assessmentDateController.text = DateFormat('yyyy-MM-dd').format(_assessment.assessmentDate);
    _assessorNameController.text = _assessment.assessorName ?? '';
    _fireWardenNameController.text = _assessment.fireWardenName ?? '';
    if (_assessment.fireAlarmTestDate != null) {
      _fireAlarmTestDateController.text = DateFormat('yyyy-MM-dd').format(_assessment.fireAlarmTestDate!);
    }
    if (_assessment.emergencyLightingTestDate != null) {
      _emergencyLightingTestDateController.text = DateFormat('yyyy-MM-dd').format(_assessment.emergencyLightingTestDate!);
    }
    if (_assessment.fireExtinguisherNextServiceDue != null) {
      _fireExtinguisherNextServiceDueController.text = DateFormat('yyyy-MM-dd').format(_assessment.fireExtinguisherNextServiceDue!);
    }
    if (_assessment.fireBlanketServiceDate != null) {
      _fireBlanketServiceDateController.text = DateFormat('yyyy-MM-dd').format(_assessment.fireBlanketServiceDate!);
    }
    if (_assessment.staffTrainingNextDue != null) {
      _staffTrainingNextDueController.text = DateFormat('yyyy-MM-dd').format(_assessment.staffTrainingNextDue!);
    }
    if (_assessment.patTestExpiryDate != null) {
      _patTestExpiryDateController.text = DateFormat('yyyy-MM-dd').format(_assessment.patTestExpiryDate!);
    }
    if (_assessment.fireRiskAssessmentReviewDate != null) {
      _fireRiskAssessmentReviewDateController.text = DateFormat('yyyy-MM-dd').format(_assessment.fireRiskAssessmentReviewDate!);
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != DateTime.now()) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_assessment.serviceUserId == null || _assessment.serviceUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service user')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update assessment with form values
      _assessment = _assessment.copyWith(
        serviceUserId: _assessment.serviceUserId,
        assessmentDate: DateTime.parse(_assessmentDateController.text),
        assessorName: _assessorNameController.text,
        fireWardenName: _fireWardenNameController.text,
        fireAlarmTestDate: _fireAlarmTestDateController.text.isNotEmpty 
            ? DateTime.parse(_fireAlarmTestDateController.text) 
            : null,
        emergencyLightingTestDate: _emergencyLightingTestDateController.text.isNotEmpty 
            ? DateTime.parse(_emergencyLightingTestDateController.text) 
            : null,
        fireExtinguisherNextServiceDue: _fireExtinguisherNextServiceDueController.text.isNotEmpty 
            ? DateTime.parse(_fireExtinguisherNextServiceDueController.text) 
            : null,
        fireBlanketServiceDate: _fireBlanketServiceDateController.text.isNotEmpty 
            ? DateTime.parse(_fireBlanketServiceDateController.text) 
            : null,
        staffTrainingNextDue: _staffTrainingNextDueController.text.isNotEmpty 
            ? DateTime.parse(_staffTrainingNextDueController.text) 
            : null,
        patTestExpiryDate: _patTestExpiryDateController.text.isNotEmpty 
            ? DateTime.parse(_patTestExpiryDateController.text) 
            : null,
        fireRiskAssessmentReviewDate: _fireRiskAssessmentReviewDateController.text.isNotEmpty 
            ? DateTime.parse(_fireRiskAssessmentReviewDateController.text) 
            : null,
      );

      if (widget.assessment != null) {
        await _fireHazardService.updateAssessment(widget.assessment!.id ?? '', _assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fire hazard assessment updated successfully')),
        );
      } else {
        await _fireHazardService.createAssessment(_assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fire hazard assessment created successfully')),
        );
      }

      Navigator.pop(context, true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save assessment: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment != null ? 'Edit Fire Hazard Assessment' : 'New Fire Hazard Assessment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Basic Information
                    const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    if (widget.serviceUserId == null)
                      _loadingUsers
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: _assessment.serviceUserId?.isEmpty ?? true ? null : _assessment.serviceUserId,
                              decoration: const InputDecoration(
                                labelText: 'Service User *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: _serviceUsers.map((user) {
                                return DropdownMenuItem(
                                  value: user['id'] as String,
                                  child: Text(user['name'] as String),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null && value.isNotEmpty) {
                                  _fetchAndSetServiceUserName(value);
                                }
                              },
                              validator: (value) => value == null ? 'Required' : null,
                            ),
                    
                    TextFormField(
                      controller: _assessmentDateController,
                      decoration: const InputDecoration(
                        labelText: 'Assessment Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_assessmentDateController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an assessment date';
                        }
                        return null;
                      },
                    ),
                    
                    TextFormField(
                      controller: _assessorNameController,
                      decoration: const InputDecoration(labelText: 'Assessor Name'),
                      onChanged: (value) {
                        _assessment = _assessment.copyWith(assessorName: value ?? '');
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter assessor name';
                        }
                        return null;
                      },
                    ),
                    
                    TextFormField(
                      controller: _fireWardenNameController,
                      decoration: const InputDecoration(labelText: 'Fire Warden Name'),
                    ),

                    const SizedBox(height: 24),

                    // Risk Level
                    const Text('Risk Level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _assessment.riskLevel,
                      decoration: const InputDecoration(labelText: 'Risk Level'),
                      items: ['low', 'medium', 'high'].map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(riskLevel: value ?? 'low');
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Fire Safety Equipment
                    const Text('Fire Safety Equipment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _assessment.fireAlarmSystemType,
                      decoration: const InputDecoration(labelText: 'Fire Alarm System Type'),
                      items: ['manual', 'automatic', 'both'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(fireAlarmSystemType: value ?? 'manual');
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _assessment.smokeDetectorsPresent,
                      decoration: const InputDecoration(labelText: 'Smoke Detectors Present'),
                      items: ['yes', 'no', 'not applicable'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(smokeDetectorsPresent: value ?? 'yes');
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Fire Extinguisher Types
                    const Text('Fire Extinguisher Types', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        FilterChip(
                          label: const Text('Water'),
                          selected: _assessment.fireExtinguisherTypes?.contains('water') ?? false,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _assessment.fireExtinguisherTypes?.add('water');
                              } else {
                                _assessment.fireExtinguisherTypes?.remove('water');
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Foam'),
                          selected: _assessment.fireExtinguisherTypes?.contains('foam') ?? false,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _assessment.fireExtinguisherTypes?.add('foam');
                              } else {
                                _assessment.fireExtinguisherTypes?.remove('foam');
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('CO2'),
                          selected: _assessment.fireExtinguisherTypes?.contains('co2') ?? false,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _assessment.fireExtinguisherTypes?.add('co2');
                              } else {
                                _assessment.fireExtinguisherTypes?.remove('co2');
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Powder'),
                          selected: _assessment.fireExtinguisherTypes?.contains('powder') ?? false,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _assessment.fireExtinguisherTypes?.add('powder');
                              } else {
                                _assessment.fireExtinguisherTypes?.remove('powder');
                              }
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Test Dates
                    const Text('Test Dates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _fireAlarmTestDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fire Alarm Test Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_fireAlarmTestDateController),
                    ),

                    TextFormField(
                      controller: _emergencyLightingTestDateController,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Lighting Test Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_emergencyLightingTestDateController),
                    ),

                    TextFormField(
                      controller: _fireExtinguisherNextServiceDueController,
                      decoration: const InputDecoration(
                        labelText: 'Fire Extinguisher Next Service Due',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_fireExtinguisherNextServiceDueController),
                    ),

                    TextFormField(
                      controller: _fireBlanketServiceDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fire Blanket Service Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_fireBlanketServiceDateController),
                    ),

                    const SizedBox(height: 24),

                    // Training and Documentation
                    const Text('Training and Documentation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _staffTrainingNextDueController,
                      decoration: const InputDecoration(
                        labelText: 'Staff Training Next Due',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_staffTrainingNextDueController),
                    ),

                    TextFormField(
                      controller: _patTestExpiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'PAT Test Expiry Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_patTestExpiryDateController),
                    ),

                    TextFormField(
                      controller: _fireRiskAssessmentReviewDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fire Risk Assessment Review Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_fireRiskAssessmentReviewDateController),
                    ),

                    const SizedBox(height: 24),

                    // Fire Safety Checks
                    const Text('Fire Safety Checks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Fire Alarm Weekly Test Recorded'),
                      value: _assessment.fireAlarmWeeklyTestRecorded ?? false,
                      onChanged: (bool value) {
                        setState(() {
                          _assessment = _assessment.copyWith(fireAlarmWeeklyTestRecorded: value);
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('Emergency Lighting Working'),
                      value: _assessment.emergencyLightingWorking ?? false,
                      onChanged: (bool value) {
                        setState(() {
                          _assessment = _assessment.copyWith(emergencyLightingWorking: value);
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('Fire Exit Signs Illuminated'),
                      value: _assessment.fireExitSignsIlluminated ?? false,
                      onChanged: (bool value) {
                        setState(() {
                          _assessment = _assessment.copyWith(fireExitSignsIlluminated: value);
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('Final Exits Open Outward'),
                      value: _assessment.finalExitsOpenOutward ?? false,
                      onChanged: (bool value) {
                        setState(() {
                          _assessment = _assessment.copyWith(finalExitsOpenOutward: value);
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('Escape Routes Suitable for Mobility Aids'),
                      value: _assessment.escapeRoutesSuitableForMobilityAids ?? false,
                      onChanged: (bool value) {
                        setState(() {
                          _assessment = _assessment.copyWith(escapeRoutesSuitableForMobilityAids: value);
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Management and Procedures
                    const Text('Management and Procedures', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _assessment.fireDrillFrequency,
                      decoration: const InputDecoration(labelText: 'Fire Drill Frequency'),
                      items: ['weekly', 'monthly', 'quarterly', 'annually'].map((freq) {
                        return DropdownMenuItem(
                          value: freq,
                          child: Text(freq.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(fireDrillFrequency: value ?? 'monthly');
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _assessment.peepsInPlaceForAllServiceUsers,
                      decoration: const InputDecoration(labelText: 'PEEPs in Place for All Service Users'),
                      items: ['yes', 'no', 'partial'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _assessment = _assessment.copyWith(peepsInPlaceForAllServiceUsers: value ?? 'yes');
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Action Plan
                    const Text('Action Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Responsible Person'),
                      initialValue: _assessment.responsiblePerson,
                      onChanged: (value) {
                        _assessment = _assessment.copyWith(responsiblePerson: value);
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Completion Deadline',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(TextEditingController(
                              text: _assessment.completionDeadline != null 
                                  ? DateFormat('yyyy-MM-dd').format(_assessment.completionDeadline!) 
                                  : ''
                            )),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _assessment = _assessment.copyWith(
                                  completionDeadline: DateTime.parse(value)
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Review Date',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(TextEditingController(
                              text: _assessment.reviewDate != null 
                                  ? DateFormat('yyyy-MM-dd').format(_assessment.reviewDate!) 
                                  : ''
                            )),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _assessment = _assessment.copyWith(
                                  reviewDate: DateTime.parse(value)
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _saveAssessment,
                      child: const Text('Save Assessment'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}