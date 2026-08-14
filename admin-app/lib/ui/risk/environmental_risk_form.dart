import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/environmental_assessment.dart';
import 'package:admin_app/services/environmental_service.dart';

class EnvironmentalRiskForm extends StatefulWidget {
  final EnvironmentalAssessment? assessment;
  final String? serviceUserId;

  const EnvironmentalRiskForm({
    Key? key,
    this.assessment,
    this.serviceUserId,
  }) : super(key: key);

  @override
  State<EnvironmentalRiskForm> createState() => _EnvironmentalRiskFormState();
}

class _EnvironmentalRiskFormState extends State<EnvironmentalRiskForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = EnvironmentalService(Supabase.instance.client);

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  // Form controllers
  final _assessmentDateController = TextEditingController();
  final _assessorNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _actionPlanController = TextEditingController();
  final _reviewDateController = TextEditingController();

  // Form data
  DateTime _assessmentDate = DateTime.now();
  String _assessorName = 'Current User';
  String _location = '';
  AssessmentStatus _lightingAdequacy = AssessmentStatus.good;
  AssessmentStatus _ventilation = AssessmentStatus.good;
  AssessmentStatus _temperatureControl = AssessmentStatus.adequate;
  AssessmentStatus _flooringCondition = AssessmentStatus.safe;
  AssessmentStatus _walkways = AssessmentStatus.clear;
  AssessmentStatus _stairs = AssessmentStatus.good;
  AssessmentStatus _doorsExits = AssessmentStatus.accessible;
  AssessmentStatus _fireExits = AssessmentStatus.clear;
  AssessmentStatus _emergencyLighting = AssessmentStatus.working;
  AssessmentStatus _electricalSafety = AssessmentStatus.patTested;
  AssessmentStatus _waterSafety = AssessmentStatus.adequate;
  AssessmentStatus _coshhStorage = AssessmentStatus.secure;
  AssessmentStatus _wasteManagement = AssessmentStatus.appropriate;
  AssessmentStatus _security = AssessmentStatus.secure;
  AssessmentStatus _outdoorAreas = AssessmentStatus.safe;
  AssessmentStatus _equipmentStorage = AssessmentStatus.safe;
  RiskLevel _riskLevel = RiskLevel.low;
  String? _actionPlan;
  DateTime? _reviewDate;
  String? _photoUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    _initializeForm();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
    }
  }

  @override
  void dispose() {
    _assessmentDateController.dispose();
    _assessorNameController.dispose();
    _locationController.dispose();
    _actionPlanController.dispose();
    _reviewDateController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.assessment != null) {
      final assessment = widget.assessment!;
      _selectedServiceUserId = assessment.serviceUserId;
      _assessmentDate = assessment.assessmentDate;
      _assessorName = assessment.assessorName;
      _location = assessment.location;
      _lightingAdequacy = assessment.lightingAdequacy;
      _ventilation = assessment.ventilation;
      _temperatureControl = assessment.temperatureControl;
      _flooringCondition = assessment.flooringCondition;
      _walkways = assessment.walkways;
      _stairs = assessment.stairs;
      _doorsExits = assessment.doorsExits;
      _fireExits = assessment.fireExits;
      _emergencyLighting = assessment.emergencyLighting;
      _electricalSafety = assessment.electricalSafety;
      _waterSafety = assessment.waterSafety;
      _coshhStorage = assessment.coshhStorage;
      _wasteManagement = assessment.wasteManagement;
      _security = assessment.security;
      _outdoorAreas = assessment.outdoorAreas;
      _equipmentStorage = assessment.equipmentStorage;
      _riskLevel = assessment.riskLevel;
      _actionPlan = assessment.actionPlan;
      _reviewDate = assessment.reviewDate;
      _photoUrl = assessment.photoUrl;

      _assessmentDateController.text = _assessmentDate.toIso8601String().split('T').first;
      _assessorNameController.text = _assessorName;
      _locationController.text = _location;
      _actionPlanController.text = _actionPlan ?? '';
      if (_reviewDate != null) {
        _reviewDateController.text = _reviewDate!.toIso8601String().split('T').first;
      }
    } else {
      _assessmentDate = DateTime.now();
      _assessmentDateController.text = _assessmentDate.toIso8601String().split('T').first;
      _reviewDate = DateTime.now().add(const Duration(days: 90));
      _reviewDateController.text = _reviewDate!.toIso8601String().split('T').first;
      _assessorName = 'Current User';
      _assessorNameController.text = _assessorName;
    }
  }

  void _calculateRiskLevel() {
    int score = 0;

    if (_lightingAdequacy == AssessmentStatus.requiresAttention) score += 1;
    if (_ventilation == AssessmentStatus.requiresAttention) score += 1;
    if (_temperatureControl == AssessmentStatus.inadequate) score += 2;
    if (_flooringCondition != AssessmentStatus.safe) score += 2;
    if (_walkways == AssessmentStatus.obstructed) score += 2;
    if (_stairs != AssessmentStatus.good) score += 2;
    if (_doorsExits != AssessmentStatus.accessible) score += 3;
    if (_fireExits != AssessmentStatus.clear) score += 3;
    if (_emergencyLighting != AssessmentStatus.working) score += 3;
    if (_electricalSafety != AssessmentStatus.patTested) score += 2;
    if (_waterSafety != AssessmentStatus.adequate) score += 2;
    if (_coshhStorage != AssessmentStatus.secure) score += 2;
    if (_wasteManagement != AssessmentStatus.appropriate) score += 1;
    if (_security != AssessmentStatus.secure) score += 2;
    if (_outdoorAreas != AssessmentStatus.safe) score += 1;
    if (_equipmentStorage != AssessmentStatus.safe) score += 1;

    setState(() {
      if (score >= 15) {
        _riskLevel = RiskLevel.critical;
      } else if (score >= 8) {
        _riskLevel = RiskLevel.high;
      } else if (score >= 4) {
        _riskLevel = RiskLevel.medium;
      } else {
        _riskLevel = RiskLevel.low;
      }
    });
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service user')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final assessment = EnvironmentalAssessment(
        id: widget.assessment?.id,
        serviceUserId: _selectedServiceUserId,
        assessmentDate: _assessmentDate,
        assessorName: _assessorName,
        location: _location,
        lightingAdequacy: _lightingAdequacy,
        ventilation: _ventilation,
        temperatureControl: _temperatureControl,
        flooringCondition: _flooringCondition,
        walkways: _walkways,
        stairs: _stairs,
        doorsExits: _doorsExits,
        fireExits: _fireExits,
        emergencyLighting: _emergencyLighting,
        electricalSafety: _electricalSafety,
        waterSafety: _waterSafety,
        coshhStorage: _coshhStorage,
        wasteManagement: _wasteManagement,
        security: _security,
        outdoorAreas: _outdoorAreas,
        equipmentStorage: _equipmentStorage,
        riskLevel: _riskLevel,
        actionPlan: _actionPlan,
        reviewDate: _reviewDate,
        photoUrl: _photoUrl,
        createdAt: widget.assessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.assessment?.id != null) {
        await _service.updateAssessment(widget.assessment!.id!, assessment);
      } else {
        await _service.createAssessment(assessment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Environmental assessment saved successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save assessment: $e'), backgroundColor: Colors.red),
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
        title: Text(widget.assessment != null ? 'Edit Environmental Assessment' : 'New Environmental Assessment'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Service user selector
            if (_loadingUsers)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedServiceUserId,
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
                onChanged: (value) => setState(() => _selectedServiceUserId = value),
                validator: (value) => value == null ? 'Please select a service user' : null,
              ),
            const SizedBox(height: 16),

            // Assessment Information
            _buildSectionHeader('Assessment Information'),
            TextFormField(
              controller: _assessmentDateController,
              decoration: const InputDecoration(
                labelText: 'Assessment Date',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _assessmentDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _assessmentDate = date;
                    _assessmentDateController.text = date.toIso8601String().split('T').first;
                  });
                }
              },
              validator: (value) => value!.isEmpty ? 'Assessment date is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _assessorNameController,
              decoration: const InputDecoration(
                labelText: 'Assessor Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Assessor name is required' : null,
              onChanged: (value) => _assessorName = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Location is required' : null,
              onChanged: (value) => _location = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reviewDateController,
              decoration: const InputDecoration(
                labelText: 'Review Date',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _reviewDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _reviewDate = date;
                    _reviewDateController.text = date.toIso8601String().split('T').first;
                  });
                }
              },
            ),

            // Environmental Areas Assessment
            const SizedBox(height: 24),
            _buildSectionHeader('Environmental Areas Assessment'),

            _buildAssessmentField('Lighting Adequacy', _lightingAdequacy, (value) {
              setState(() { _lightingAdequacy = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.good, AssessmentStatus.poor, AssessmentStatus.requiresAttention]),

            _buildAssessmentField('Ventilation', _ventilation, (value) {
              setState(() { _ventilation = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.good, AssessmentStatus.poor, AssessmentStatus.requiresAttention]),

            _buildAssessmentField('Temperature Control', _temperatureControl, (value) {
              setState(() { _temperatureControl = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.adequate, AssessmentStatus.inadequate]),

            _buildAssessmentField('Flooring Condition', _flooringCondition, (value) {
              setState(() { _flooringCondition = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.safe, AssessmentStatus.tripHazard, AssessmentStatus.uneven]),

            _buildAssessmentField('Walkways', _walkways, (value) {
              setState(() { _walkways = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.clear, AssessmentStatus.obstructed]),

            _buildAssessmentField('Stairs', _stairs, (value) {
              setState(() { _stairs = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.good, AssessmentStatus.poor, AssessmentStatus.requiresAttention]),

            _buildAssessmentField('Doors/Exits', _doorsExits, (value) {
              setState(() { _doorsExits = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.accessible, AssessmentStatus.blocked]),

            _buildAssessmentField('Fire Exits', _fireExits, (value) {
              setState(() { _fireExits = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.clear, AssessmentStatus.obstructed]),

            _buildAssessmentField('Emergency Lighting', _emergencyLighting, (value) {
              setState(() { _emergencyLighting = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.working, AssessmentStatus.notTested]),

            _buildAssessmentField('Electrical Safety', _electricalSafety, (value) {
              setState(() { _electricalSafety = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.patTested, AssessmentStatus.notTested, AssessmentStatus.damaged]),

            _buildAssessmentField('Water Safety', _waterSafety, (value) {
              setState(() { _waterSafety = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.adequate, AssessmentStatus.inadequate]),

            _buildAssessmentField('COSHH Storage', _coshhStorage, (value) {
              setState(() { _coshhStorage = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.secure, AssessmentStatus.insecure]),

            _buildAssessmentField('Waste Management', _wasteManagement, (value) {
              setState(() { _wasteManagement = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.appropriate, AssessmentStatus.inappropriate, AssessmentStatus.disposal]),

            _buildAssessmentField('Security', _security, (value) {
              setState(() { _security = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.secure, AssessmentStatus.insecure]),

            _buildAssessmentField('Outdoor Areas', _outdoorAreas, (value) {
              setState(() { _outdoorAreas = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.safe, AssessmentStatus.unsafe]),

            _buildAssessmentField('Equipment Storage', _equipmentStorage, (value) {
              setState(() { _equipmentStorage = value!; _calculateRiskLevel(); });
            }, options: [AssessmentStatus.safe, AssessmentStatus.unsafe]),

            // Risk Level Display
            const SizedBox(height: 16),
            _buildRiskLevelDisplay(),

            // Action Plan
            const SizedBox(height: 16),
            _buildSectionHeader('Action Plan'),
            TextFormField(
              controller: _actionPlanController,
              decoration: const InputDecoration(
                labelText: 'Action Plan',
                border: OutlineInputBorder(),
                hintText: 'Enter action plan details...',
              ),
              maxLines: 4,
              onChanged: (value) => _actionPlan = value,
            ),

            // Save Button
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        widget.assessment != null ? 'Update Assessment' : 'Create Assessment',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildAssessmentField(
    String label,
    AssessmentStatus currentValue,
    ValueChanged<AssessmentStatus?> onChanged, {
    required List<AssessmentStatus> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: options.map((option) {
            final isSelected = currentValue == option;
            return FilterChip(
              label: Text(_getStatusLabel(option)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(option);
              },
              backgroundColor: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              selectedColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRiskLevelDisplay() {
    Color getRiskColor(RiskLevel level) {
      switch (level) {
        case RiskLevel.low: return Colors.green;
        case RiskLevel.medium: return Colors.orange;
        case RiskLevel.high: return Colors.red;
        case RiskLevel.critical: return Colors.purple;
      }
    }

    IconData getRiskIcon(RiskLevel level) {
      switch (level) {
        case RiskLevel.critical: return Icons.gpp_bad;
        case RiskLevel.high: return Icons.warning;
        case RiskLevel.medium: return Icons.info;
        case RiskLevel.low: return Icons.check_circle;
      }
    }

    return Card(
      color: getRiskColor(_riskLevel).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(getRiskIcon(_riskLevel), color: getRiskColor(_riskLevel), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-calculated Risk: ${_getRiskLevelLabel(_riskLevel)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: getRiskColor(_riskLevel), fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Automatically calculated from your selections above.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(AssessmentStatus status) {
    switch (status) {
      case AssessmentStatus.good: return 'Good';
      case AssessmentStatus.poor: return 'Poor';
      case AssessmentStatus.requiresAttention: return 'Needs Attention';
      case AssessmentStatus.adequate: return 'Adequate';
      case AssessmentStatus.inadequate: return 'Inadequate';
      case AssessmentStatus.safe: return 'Safe';
      case AssessmentStatus.tripHazard: return 'Trip Hazard';
      case AssessmentStatus.uneven: return 'Uneven';
      case AssessmentStatus.clear: return 'Clear';
      case AssessmentStatus.obstructed: return 'Obstructed';
      case AssessmentStatus.accessible: return 'Accessible';
      case AssessmentStatus.blocked: return 'Blocked';
      case AssessmentStatus.working: return 'Working';
      case AssessmentStatus.notTested: return 'Not Tested';
      case AssessmentStatus.patTested: return 'PAT Tested';
      case AssessmentStatus.damaged: return 'Damaged';
      case AssessmentStatus.secure: return 'Secure';
      case AssessmentStatus.insecure: return 'Insecure';
      case AssessmentStatus.appropriate: return 'Appropriate';
      case AssessmentStatus.inappropriate: return 'Inappropriate';
      case AssessmentStatus.disposal: return 'Disposal';
      case AssessmentStatus.unsafe: return 'Unsafe';
    }
  }

  String _getRiskLevelLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low: return 'Low';
      case RiskLevel.medium: return 'Medium';
      case RiskLevel.high: return 'High';
      case RiskLevel.critical: return 'Critical';
    }
  }
}