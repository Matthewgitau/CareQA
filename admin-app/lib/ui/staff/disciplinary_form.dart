import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/disciplinary_case.dart';
import '../../services/disciplinary_service.dart';
import '../../widgets/signature_pad.dart';

class DisciplinaryFormScreen extends StatefulWidget {
  final DisciplinaryCase? case_;

  const DisciplinaryFormScreen({super.key, this.case_});

  @override
  State<DisciplinaryFormScreen> createState() => _DisciplinaryFormScreenState();
}

class _DisciplinaryFormScreenState extends State<DisciplinaryFormScreen> {
  final _service = DisciplinaryService(Supabase.instance.client);
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _investigationNotesController = TextEditingController();
  final _investigationFindingsController = TextEditingController();
  final _hearingNotesController = TextEditingController();
  final _decisionController = TextEditingController();
  final _actionNotesController = TextEditingController();
  final _notesController = TextEditingController();
  final _hrNotesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  // Form fields
  String? _selectedStaffId;
  String? _selectedStaffName;
  String? _employeeNumber;
  String? _department;
  String? _jobTitle;
  String? _selectedCarerId;
  String? _selectedCarerName;
  bool _serviceUserInvolved = false;
  String? _selectedServiceUserId;
  String? _selectedServiceUserName;
  String? _signatureUrl;
  DateTime? _incidentDate;
  DateTime? _reportDate;
  String? _reportedById;
  String? _reportedByName;
  String? _incidentType;
  String? _severity;
  bool _investigationCompleted = false;
  DateTime? _investigationCompletedDate;
  String? _investigationOfficer;
  List<dynamic> _witnesses = [];
  DateTime? _hearingDate;
  String? _hearingOutcome;
  String? _decision;
  DateTime? _decisionDate;
  String? _decisionMadeById;
  String? _decisionMadeByName;
  String? _actionTaken;
  DateTime? _actionStartDate;
  DateTime? _actionEndDate;
  bool _appealRaised = false;
  DateTime? _appealDate;
  String? _appealOutcome;
  String? _outcomeType;
  String? _outcomeDetails;
  String _status = 'open';
  bool _isConfidential = true;
  bool _complianceRisk = false;
  bool _hrReviewRequired = false;
  DateTime? _hrReviewDate;

  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _carersList = [];
  List<Map<String, dynamic>> _serviceUsersList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.case_ != null) {
      _populateForm(widget.case_!);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _investigationNotesController.dispose();
    _investigationFindingsController.dispose();
    _hearingNotesController.dispose();
    _decisionController.dispose();
    _actionNotesController.dispose();
    _notesController.dispose();
    _hrNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final staff = await _service.getAllStaff();
      final carers = await _service.getAllCarers();
      final serviceUsers = await _service.getAllServiceUsers();
      if (mounted) {
        setState(() {
          _staffList = staff;
          _carersList = carers;
          _serviceUsersList = serviceUsers;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(DisciplinaryCase case_) {
    _selectedStaffId = case_.staffId;
    _selectedStaffName = case_.staffName;
    _employeeNumber = case_.employeeNumber;
    _department = case_.department;
    _jobTitle = case_.jobTitle;
    _selectedCarerId = case_.carerId;
    _selectedCarerName = case_.carerName;
    _serviceUserInvolved = case_.serviceUserInvolved;
    _selectedServiceUserId = case_.serviceUserId;
    _selectedServiceUserName = case_.serviceUserName;
    _signatureUrl = case_.signatureUrl;
    _incidentDate = case_.incidentDate;
    _reportDate = case_.reportDate;
    _reportedById = case_.reportedById;
    _reportedByName = case_.reportedByName;
    _incidentType = case_.incidentType;
    _severity = case_.severity;
    _descriptionController.text = case_.description;
    _investigationNotesController.text = case_.investigationNotes ?? '';
    _investigationCompleted = case_.investigationCompleted;
    _investigationCompletedDate = case_.investigationCompletedDate;
    _investigationOfficer = case_.investigationOfficer;
    _investigationFindingsController.text = case_.investigationFindings ?? '';
    _witnesses = case_.witnesses;
    _hearingDate = case_.hearingDate;
    _hearingNotesController.text = case_.hearingNotes ?? '';
    _hearingOutcome = case_.hearingOutcome;
    _decisionController.text = case_.decision ?? '';
    _decisionDate = case_.decisionDate;
    _decisionMadeById = case_.decisionMadeById;
    _decisionMadeByName = case_.decisionMadeByName;
    _actionTaken = case_.actionTaken;
    _actionStartDate = case_.actionStartDate;
    _actionEndDate = case_.actionEndDate;
    _actionNotesController.text = case_.actionNotes ?? '';
    _appealRaised = case_.appealRaised;
    _appealDate = case_.appealDate;
    _appealOutcome = case_.appealOutcome;
    _outcomeType = case_.outcomeType;
    _outcomeDetails = case_.outcomeDetails;
    _status = case_.status;
    _notesController.text = case_.notes ?? '';
    _isConfidential = case_.isConfidential;
    _complianceRisk = case_.complianceRisk;
    _hrReviewRequired = case_.hrReviewRequired;
    _hrReviewDate = case_.hrReviewDate;
    _hrNotesController.text = case_.hrNotes ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final case_ = DisciplinaryCase(
        id: widget.case_?.id ?? '',
        staffId: _selectedStaffId,
        staffName: _selectedStaffName ?? '',
        employeeNumber: _employeeNumber,
        department: _department,
        jobTitle: _jobTitle,
        incidentDate: _incidentDate ?? DateTime.now(),
        reportDate: _reportDate ?? DateTime.now(),
        reportedById: _reportedById,
        reportedByName: _reportedByName,
        incidentType: _incidentType,
        severity: _severity,
        description: _descriptionController.text,
        investigationNotes: _investigationNotesController.text.isNotEmpty ? _investigationNotesController.text : null,
        investigationCompleted: _investigationCompleted,
        investigationCompletedDate: _investigationCompletedDate,
        investigationOfficer: _investigationOfficer,
        investigationFindings: _investigationFindingsController.text.isNotEmpty ? _investigationFindingsController.text : null,
        witnesses: _witnesses,
        hearingDate: _hearingDate,
        hearingNotes: _hearingNotesController.text.isNotEmpty ? _hearingNotesController.text : null,
        hearingOutcome: _hearingOutcome,
        decision: _decisionController.text.isNotEmpty ? _decisionController.text : null,
        decisionDate: _decisionDate,
        decisionMadeById: _decisionMadeById,
        decisionMadeByName: _decisionMadeByName,
        actionTaken: _actionTaken,
        actionStartDate: _actionStartDate,
        actionEndDate: _actionEndDate,
        actionNotes: _actionNotesController.text.isNotEmpty ? _actionNotesController.text : null,
        appealRaised: _appealRaised,
        appealDate: _appealDate,
        appealOutcome: _appealOutcome,
        appealNotes: _appealOutcome,
        outcomeType: _outcomeType,
        outcomeDetails: _outcomeDetails,
        status: _status,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isConfidential: _isConfidential,
        complianceRisk: _complianceRisk,
        hrReviewRequired: _hrReviewRequired,
        hrReviewDate: _hrReviewDate,
        carerId: _selectedCarerId,
        carerName: _selectedCarerName,
        serviceUserInvolved: _serviceUserInvolved,
        serviceUserId: _selectedServiceUserId,
        serviceUserName: _selectedServiceUserName,
        signatureUrl: _signatureUrl,
        hrNotes: _hrNotesController.text.isNotEmpty ? _hrNotesController.text : null,
        createdAt: widget.case_?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.case_ != null) {
        await _service.updateCase(case_);
      } else {
        await _service.createCase(case_);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.case_ != null ? 'Case updated' : 'Case created'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate(bool isIncident) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIncident) {
          _incidentDate = picked;
        } else {
          _reportDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.case_ != null ? 'Edit Disciplinary Case' : 'New Disciplinary Case'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Staff Selection
                    DropdownButtonFormField<String>(
                      value: _selectedStaffId,
                      decoration: const InputDecoration(
                        labelText: 'Staff Member *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Select staff...')),
                        ..._staffList.map((s) => DropdownMenuItem(
                              value: s['id'] as String,
                              child: Text(s['full_name'] ?? s['name'] ?? 'Unknown'),
                            )),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedStaffId = v;
                          final staff = _staffList.firstWhere((s) => s['id'] == v, orElse: () => {});
                          _selectedStaffName = staff['full_name'] ?? staff['name'];
                          _employeeNumber = staff['employee_number'];
                          _department = staff['department'];
                          _jobTitle = staff['job_title'];
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Incident Type
                    DropdownButtonFormField<String>(
                      value: _incidentType,
                      decoration: const InputDecoration(
                        labelText: 'Incident Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'gross_misconduct', child: Text('Gross Misconduct')),
                        DropdownMenuItem(value: 'misconduct', child: Text('Misconduct')),
                        DropdownMenuItem(value: 'poor_performance', child: Text('Poor Performance')),
                        DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
                        DropdownMenuItem(value: 'health_and_safety', child: Text('Health & Safety')),
                        DropdownMenuItem(value: 'bullying_harassment', child: Text('Bullying/Harassment')),
                        DropdownMenuItem(value: 'theft_fraud', child: Text('Theft/Fraud')),
                        DropdownMenuItem(value: 'data_breach', child: Text('Data Breach')),
                        DropdownMenuItem(value: 'confidentiality_breach', child: Text('Confidentiality Breach')),
                        DropdownMenuItem(value: 'conduct_outside_work', child: Text('Conduct Outside Work')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _incidentType = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Severity
                    DropdownButtonFormField<String>(
                      value: _severity,
                      decoration: const InputDecoration(
                        labelText: 'Severity *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'critical', child: Text('Critical')),
                      ],
                      onChanged: (v) => setState(() => _severity = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Dates
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Incident Date *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_incidentDate != null ? DateFormat('dd/MM/yyyy').format(_incidentDate!) : 'Select date'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Report Date *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_reportDate != null ? DateFormat('dd/MM/yyyy').format(_reportDate!) : 'Select date'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Status
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'open', child: Text('Open')),
                        DropdownMenuItem(value: 'investigating', child: Text('Investigating')),
                        DropdownMenuItem(value: 'hearing_scheduled', child: Text('Hearing Scheduled')),
                        DropdownMenuItem(value: 'decision_pending', child: Text('Decision Pending')),
                        DropdownMenuItem(value: 'closed', child: Text('Closed')),
                        DropdownMenuItem(value: 'appealed', child: Text('Appealed')),
                      ],
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 16),

                    // Outcome Type
                    DropdownButtonFormField<String>(
                      value: _outcomeType,
                      decoration: const InputDecoration(
                        labelText: 'Outcome Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
                        DropdownMenuItem(value: 'final_written_warning', child: Text('Final Written Warning')),
                        DropdownMenuItem(value: 'written_warning', child: Text('Written Warning')),
                        DropdownMenuItem(value: 'verbal_warning', child: Text('Verbal Warning')),
                        DropdownMenuItem(value: 'suspension', child: Text('Suspension')),
                        DropdownMenuItem(value: 'demotion', child: Text('Demotion')),
                        DropdownMenuItem(value: 'training_required', child: Text('Training Required')),
                        DropdownMenuItem(value: 'monitoring_required', child: Text('Monitoring Required')),
                        DropdownMenuItem(value: 'no_action', child: Text('No Action')),
                      ],
                      onChanged: (v) => setState(() => _outcomeType = v),
                    ),
                    const SizedBox(height: 16),

                    // Carer Selection
                    DropdownButtonFormField<String>(
                      value: _selectedCarerId,
                      decoration: const InputDecoration(
                        labelText: 'Carer (if involved)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ..._carersList.map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Text(c['full_name'] ?? c['name'] ?? 'Unknown'),
                            )),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedCarerId = v;
                          final carer = _carersList.firstWhere((c) => c['id'] == v, orElse: () => {});
                          _selectedCarerName = carer['full_name'] ?? carer['name'];
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Service User Involvement
                    CheckboxListTile(
                      title: const Text('Service User Involved'),
                      value: _serviceUserInvolved,
                      onChanged: (v) => setState(() => _serviceUserInvolved = v ?? false),
                    ),
                    if (_serviceUserInvolved)
                      DropdownButtonFormField<String>(
                        value: _selectedServiceUserId,
                        decoration: const InputDecoration(
                          labelText: 'Service User *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Select service user...')),
                          ..._serviceUsersList.map((su) => DropdownMenuItem(
                                value: su['id'] as String,
                                child: Text(su['full_name'] ?? su['name'] ?? 'Unknown'),
                              )),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedServiceUserId = v;
                            final su = _serviceUsersList.firstWhere((su) => su['id'] == v, orElse: () => {});
                            _selectedServiceUserName = su['full_name'] ?? su['name'];
                          });
                        },
                      ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Signature Pad
                    const Text('Signature:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SignaturePad(
                      onSaved: (bytes) {
                        if (bytes != null) {
                          final base64Str = base64Encode(bytes);
                          setState(() => _signatureUrl = base64Str);
                        } else {
                          setState(() => _signatureUrl = null);
                        }
                      },
                    ),
                    if (_signatureUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: const Text('✓ Signature captured', style: TextStyle(fontSize: 12, color: Colors.green)),
                      ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(widget.case_ != null ? 'Update Case' : 'Create Case', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}