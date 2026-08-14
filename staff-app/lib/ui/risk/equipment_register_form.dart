import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/models/equipment_register_assessment.dart';
import 'package:staff_app/services/equipment_register_service.dart';
import 'package:supabase/supabase.dart';

class EquipmentRegisterForm extends StatefulWidget {
  final EquipmentRegisterAssessment? assessment;
  final String? equipmentId;

  const EquipmentRegisterForm({
    Key? key,
    this.assessment,
    this.equipmentId,
  }) : super(key: key);

  @override
  State<EquipmentRegisterForm> createState() => _EquipmentRegisterFormState();
}

class _EquipmentRegisterFormState extends State<EquipmentRegisterForm> {
  late final EquipmentRegisterService _equipmentService;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _equipmentIdController = TextEditingController();
  final TextEditingController _equipmentNameController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _serviceProviderController = TextEditingController();
  final TextEditingController _assessorNameController = TextEditingController();
  final TextEditingController _actionRequiredController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Form fields
  String _equipmentCategory = 'hoist';
  String _equipmentCondition = 'good';
  String _reportedFaults = 'none';
  String _riskLevel = 'low';
  
  DateTime? _purchaseDate;
  DateTime? _lastServiceDate;
  DateTime? _nextServiceDueDate;
  DateTime? _patTestDate;
  DateTime? _patTestExpiry;
  DateTime? _lolerTestDate;
  DateTime? _lolerTestExpiry;
  DateTime? _faultReportedDate;
  DateTime? _faultResolvedDate;
  DateTime? _reviewDate;
  
  bool _dailyChecksCompleted = false;
  bool _weeklyChecksCompleted = false;
  bool _monthlyChecksCompleted = false;
  bool _staffTrained = false;
  bool _trainingRecordAvailable = false;

  @override
  void initState() {
    super.initState();
    _equipmentService = EquipmentRegisterService(SupabaseClient('https://your-project.supabase.co', 'your-anon-key'));
    
    // Initialize form with existing data if editing
    if (widget.assessment != null) {
      final assessment = widget.assessment!;
      _equipmentIdController.text = assessment.equipmentId;
      _equipmentNameController.text = assessment.equipmentName;
      _equipmentCategory = assessment.equipmentCategory;
      _serialNumberController.text = assessment.serialNumber ?? '';
      _manufacturerController.text = assessment.manufacturer ?? '';
      _supplierController.text = assessment.supplier ?? '';
      _purchaseDate = assessment.purchaseDate;
      _lastServiceDate = assessment.lastServiceDate;
      _nextServiceDueDate = assessment.nextServiceDueDate;
      _serviceProviderController.text = assessment.serviceProvider ?? '';
      _patTestDate = assessment.patTestDate;
      _patTestExpiry = assessment.patTestExpiry;
      _lolerTestDate = assessment.lolerTestDate;
      _lolerTestExpiry = assessment.lolerTestExpiry;
      _dailyChecksCompleted = assessment.dailyChecksCompleted;
      _weeklyChecksCompleted = assessment.weeklyChecksCompleted;
      _monthlyChecksCompleted = assessment.monthlyChecksCompleted;
      _equipmentCondition = assessment.equipmentCondition;
      _reportedFaults = assessment.reportedFaults;
      _faultReportedDate = assessment.faultReportedDate;
      _faultResolvedDate = assessment.faultResolvedDate;
      _staffTrained = assessment.staffTrained;
      _trainingRecordAvailable = assessment.trainingRecordAvailable;
      _riskLevel = assessment.riskLevel;
      _actionRequiredController.text = assessment.actionRequired ?? '';
      _reviewDate = assessment.reviewDate;
      _assessorNameController.text = assessment.assessorName ?? '';
      _notesController.text = assessment.notes ?? '';
    } else if (widget.equipmentId != null) {
      _equipmentIdController.text = widget.equipmentId!;
    }
  }

  @override
  void dispose() {
    _equipmentIdController.dispose();
    _equipmentNameController.dispose();
    _serialNumberController.dispose();
    _manufacturerController.dispose();
    _supplierController.dispose();
    _serviceProviderController.dispose();
    _assessorNameController.dispose();
    _actionRequiredController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, ValueChanged<DateTime> onSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != initialDate) {
      onSelected(picked);
    }
  }

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('yyyy-MM-dd').format(date) : 'Not set';
  }

  void _calculateRiskLevel() {
    setState(() {
      _riskLevel = EquipmentRegisterAssessment(
        equipmentId: _equipmentIdController.text,
        equipmentName: _equipmentNameController.text,
        equipmentCategory: _equipmentCategory,
        equipmentCondition: _equipmentCondition,
        reportedFaults: _reportedFaults,
        dailyChecksCompleted: _dailyChecksCompleted,
        weeklyChecksCompleted: _weeklyChecksCompleted,
        monthlyChecksCompleted: _monthlyChecksCompleted,
      ).calculateRiskLevel();
    });
  }

  void _updateActionRequired() {
    final assessment = EquipmentRegisterAssessment(
      equipmentId: _equipmentIdController.text,
      equipmentName: _equipmentNameController.text,
      equipmentCategory: _equipmentCategory,
      equipmentCondition: _equipmentCondition,
      reportedFaults: _reportedFaults,
      dailyChecksCompleted: _dailyChecksCompleted,
      weeklyChecksCompleted: _weeklyChecksCompleted,
      monthlyChecksCompleted: _monthlyChecksCompleted,
    );
    
    final action = assessment.getActionRequired();
    if (action != null) {
      setState(() {
        _actionRequiredController.text = action;
      });
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final assessment = EquipmentRegisterAssessment(
      id: widget.assessment?.id,
      equipmentId: _equipmentIdController.text.trim(),
      equipmentName: _equipmentNameController.text.trim(),
      equipmentCategory: _equipmentCategory,
      serialNumber: _serialNumberController.text.isNotEmpty ? _serialNumberController.text.trim() : null,
      manufacturer: _manufacturerController.text.isNotEmpty ? _manufacturerController.text.trim() : null,
      supplier: _supplierController.text.isNotEmpty ? _supplierController.text.trim() : null,
      purchaseDate: _purchaseDate,
      lastServiceDate: _lastServiceDate,
      nextServiceDueDate: _nextServiceDueDate,
      serviceProvider: _serviceProviderController.text.isNotEmpty ? _serviceProviderController.text.trim() : null,
      patTestDate: _patTestDate,
      patTestExpiry: _patTestExpiry,
      lolerTestDate: _lolerTestDate,
      lolerTestExpiry: _lolerTestExpiry,
      dailyChecksCompleted: _dailyChecksCompleted,
      weeklyChecksCompleted: _weeklyChecksCompleted,
      monthlyChecksCompleted: _monthlyChecksCompleted,
      equipmentCondition: _equipmentCondition,
      reportedFaults: _reportedFaults,
      faultReportedDate: _faultReportedDate,
      faultResolvedDate: _faultResolvedDate,
      staffTrained: _staffTrained,
      trainingRecordAvailable: _trainingRecordAvailable,
      riskLevel: _riskLevel,
      actionRequired: _actionRequiredController.text.isNotEmpty ? _actionRequiredController.text.trim() : null,
      reviewDate: _reviewDate,
      assessorName: _assessorNameController.text.isNotEmpty ? _assessorNameController.text.trim() : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
    );

    try {
      if (widget.assessment != null) {
        await _equipmentService.updateAssessment(widget.assessment!.id!, assessment);
      } else {
        await _equipmentService.createAssessment(assessment);
      }
      
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.assessment != null ? 'Equipment updated successfully' : 'Equipment added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save equipment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment != null ? 'Edit Equipment' : 'Add Equipment'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipment Basic Information
              const Text('Equipment Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Equipment ID
              TextFormField(
                controller: _equipmentIdController,
                decoration: const InputDecoration(
                  labelText: 'Equipment ID *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter equipment ID';
                  }
                  return null;
                },
                enabled: widget.assessment == null, // Disable editing if updating
              ),
              const SizedBox(height: 16),

              // Equipment Name
              TextFormField(
                controller: _equipmentNameController,
                decoration: const InputDecoration(
                  labelText: 'Equipment Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter equipment name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Equipment Category
              DropdownButtonFormField<String>(
                value: _equipmentCategory,
                decoration: const InputDecoration(
                  labelText: 'Equipment Category *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'hoist', child: const Text('Hoist')),
                  DropdownMenuItem(value: 'wheelchair', child: const Text('Wheelchair')),
                  DropdownMenuItem(value: 'bed', child: const Text('Bed')),
                  DropdownMenuItem(value: 'chair', child: const Text('Chair')),
                  DropdownMenuItem(value: 'other', child: const Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _equipmentCategory = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select equipment category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Serial Number
              TextFormField(
                controller: _serialNumberController,
                decoration: const InputDecoration(
                  labelText: 'Serial Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Manufacturer
              TextFormField(
                controller: _manufacturerController,
                decoration: const InputDecoration(
                  labelText: 'Manufacturer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Supplier
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Purchase Date
              ListTile(
                title: Text('Purchase Date: ${_formatDate(_purchaseDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  _selectDate(context, _purchaseDate, (date) {
                    setState(() {
                      _purchaseDate = date;
                    });
                  });
                },
              ),
              const SizedBox(height: 16),

              // Service Information
              const Text('Service Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Last Service Date
              ListTile(
                title: Text('Last Service Date: ${_formatDate(_lastServiceDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  _selectDate(context, _lastServiceDate, (date) {
                    setState(() {
                      _lastServiceDate = date;
                    });
                  });
                },
              ),
              const SizedBox(height: 16),

              // Next Service Due Date
              ListTile(
                title: Text('Next Service Due Date: ${_formatDate(_nextServiceDueDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  _selectDate(context, _nextServiceDueDate, (date) {
                    setState(() {
                      _nextServiceDueDate = date;
                    });
                  });
                },
              ),
              const SizedBox(height: 16),

              // Service Provider
              TextFormField(
                controller: _serviceProviderController,
                decoration: const InputDecoration(
                  labelText: 'Service Provider',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Test Information
              const Text('Test Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // PAT Test Date
              ListTile(
                title: Text('PAT Test Date: ${_formatDate(_patTestDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  _selectDate(context, _patTestDate, (date) {
                    setState(() {
                      _patTestDate = date;
                      _calculateRiskLevel();
                    });
                  });
                },
              ),
              const SizedBox(height: 16),

              // PAT Test Expiry
              ListTile(
                title: Text('PAT Test Expiry: ${_formatDate(_patTestExpiry)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  _selectDate(context, _patTestExpiry, (date) {
                    setState(() {
                      _patTestExpiry = date;
                      _calculateRiskLevel();
                    });
                  });
                },
              ),
              const SizedBox(height: 16),

              // LOLER Test Date
              ListTile(
                title: Text('LOLER Test Date: ${_formatDate(_lolerTestDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  _selectDate(context, _lolerTestDate, (date) {
                    setState(() {
                      _lolerTestDate = date;
                      _calculateRiskLevel();
                    });
                  });
                },
              ),
              const SizedBox(height: 16),

              // LOLER Test Expiry
              ListTile(
                title: Text('LOLER Test Expiry: ${_formatDate(_lolerTestExpiry)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  _selectDate(context, _lolerTestExpiry, (date) {
                    setState(() {
                      _lolerTestExpiry = date;
                      _calculateRiskLevel();
                    });
                  });
                },
              ),
              const SizedBox(height: 16),

              // Checks Completed
              const Text('Checks Completed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Daily Checks
              CheckboxListTile(
                title: const Text('Daily Checks Completed'),
                value: _dailyChecksCompleted,
                onChanged: (bool? value) {
                  setState(() {
                    _dailyChecksCompleted = value!;
                    _calculateRiskLevel();
                  });
                },
              ),

              // Weekly Checks
              CheckboxListTile(
                title: const Text('Weekly Checks Completed'),
                value: _weeklyChecksCompleted,
                onChanged: (bool? value) {
                  setState(() {
                    _weeklyChecksCompleted = value!;
                    _calculateRiskLevel();
                  });
                },
              ),

              // Monthly Checks
              CheckboxListTile(
                title: const Text('Monthly Checks Completed'),
                value: _monthlyChecksCompleted,
                onChanged: (bool? value) {
                  setState(() {
                    _monthlyChecksCompleted = value!;
                    _calculateRiskLevel();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Equipment Condition
              const Text('Equipment Condition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _equipmentCondition,
                decoration: const InputDecoration(
                  labelText: 'Equipment Condition',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'good', child: const Text('Good')),
                  DropdownMenuItem(value: 'worn', child: const Text('Worn')),
                  DropdownMenuItem(value: 'damaged', child: const Text('Damaged')),
                  DropdownMenuItem(value: 'unsafe', child: const Text('Unsafe')),
                ],
                onChanged: (value) {
                  setState(() {
                    _equipmentCondition = value!;
                    _calculateRiskLevel();
                    _updateActionRequired();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Reported Faults
              const Text('Reported Faults', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _reportedFaults,
                decoration: const InputDecoration(
                  labelText: 'Reported Faults',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'none', child: const Text('None')),
                  DropdownMenuItem(value: 'minor', child: const Text('Minor')),
                  DropdownMenuItem(value: 'major', child: const Text('Major')),
                ],
                onChanged: (value) {
                  setState(() {
                    _reportedFaults = value!;
                    _calculateRiskLevel();
                    _updateActionRequired();
                    
                    // Set fault reported date if fault is reported
                    if (value != 'none' && _faultReportedDate == null) {
                      _faultReportedDate = DateTime.now();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Fault Reported Date
              if (_reportedFaults != 'none')
                ListTile(
                  title: Text('Fault Reported Date: ${_formatDate(_faultReportedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () {
                    _selectDate(context, _faultReportedDate, (date) {
                      setState(() {
                        _faultReportedDate = date;
                      });
                    });
                  },
                ),
              const SizedBox(height: 16),

              // Fault Resolved Date
              if (_faultResolvedDate != null || _reportedFaults == 'none')
                ListTile(
                  title: Text('Fault Resolved Date: ${_formatDate(_faultResolvedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () {
                    _selectDate(context, _faultResolvedDate, (date) {
                      setState(() {
                        _faultResolvedDate = date;
                      });
                    });
                  },
                ),
              const SizedBox(height: 16),

              // Staff Training
              const Text('Staff Training', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Staff Trained
              CheckboxListTile(
                title: const Text('Staff Trained on Equipment'),
                value: _staffTrained,
                onChanged: (bool? value) {
                  setState(() {
                    _staffTrained = value!;
                    _calculateRiskLevel();
                  });
                },
              ),

              // Training Record Available
              CheckboxListTile(
                title: const Text('Training Record Available'),
                value: _trainingRecordAvailable,
                onChanged: (bool? value) {
                  setState(() {
                    _trainingRecordAvailable = value!;
                    _calculateRiskLevel();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Risk Level
              const Text('Risk Level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Text(
                'Current Risk Level: ${_riskLevel.toUpperCase()} ${_getRiskLevelEmoji(_riskLevel)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getRiskLevelColor(_riskLevel),
                ),
              ),
              const SizedBox(height: 16),

              // Action Required
              const Text('Action Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _actionRequiredController,
                decoration: const InputDecoration(
                  labelText: 'Action Required',
                  border: OutlineInputBorder(),
                  hintText: 'Auto-generated based on equipment status',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Review Date
              ListTile(
                title: Text('Review Date: ${_formatDate(_reviewDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  _selectDate(context, _reviewDate, (date) {
                    setState(() {
                      _reviewDate = date;
                    });
                  });
                },
              ),
              const SizedBox(height: 16),

              // Assessor Information
              const Text('Assessor Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Assessor Name
              TextFormField(
                controller: _assessorNameController,
                decoration: const InputDecoration(
                  labelText: 'Assessor Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAssessment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                    widget.assessment != null ? 'Update Equipment' : 'Add Equipment',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRiskLevelEmoji(String riskLevel) {
    switch (riskLevel) {
      case 'critical': return '🔴';
      case 'high': return '🟠';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow[700]!;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }
}