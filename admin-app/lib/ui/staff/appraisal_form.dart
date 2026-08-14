import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appraisal.dart';
import '../../services/appraisal_service.dart';

/// Form screen for creating or editing an appraisal
class AppraisalForm extends StatefulWidget {
  final Appraisal? appraisal; // null for create, non-null for edit
  final String? preselectedEmployeeId;
  final String? preselectedEmployeeName;

  const AppraisalForm({
    super.key,
    this.appraisal,
    this.preselectedEmployeeId,
    this.preselectedEmployeeName,
  });

  @override
  State<AppraisalForm> createState() => _AppraisalFormState();
}

class _AppraisalFormState extends State<AppraisalForm> {
  final _formKey = GlobalKey<FormState>();
  final _previousGoalsController = TextEditingController();
  final _areasForImprovementController = TextEditingController();
  final _newGoalsController = TextEditingController();
  final _commentsController = TextEditingController();

  // Compliance controllers
  final _employeeSignatureController = TextEditingController();
  final _reviewerSignatureController = TextEditingController();
  final _witnessNameController = TextEditingController();
  final _witnessSignatureController = TextEditingController();
  final _authorisedByController = TextEditingController();

  final _service = AppraisalService(Supabase.instance.client);

  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  String? _selectedReviewerId;
  String? _selectedReviewerName;
  DateTime? _appraisalDate;
  DateTime? _nextAppraisalDate;
  int? _overallRating;
  String _status = 'draft';

  // Compliance dates
  DateTime? _employeeSignatureDate;
  DateTime? _reviewerSignatureDate;
  DateTime? _authorisedDate;
  DateTime? _completedDate;

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _reviewers = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEligible = true;
  String? _eligibilityReason;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.appraisal != null) {
      _populateForm(widget.appraisal!);
    }
  }

  void _populateForm(Appraisal appraisal) {
    _selectedEmployeeId = appraisal.employeeId;
    _selectedEmployeeName = appraisal.employeeName;
    _selectedReviewerId = appraisal.reviewerId;
    _selectedReviewerName = appraisal.reviewerName;
    _appraisalDate = appraisal.appraisalDate;
    _nextAppraisalDate = appraisal.nextAppraisalDate;
    _overallRating = appraisal.overallRating;
    _status = appraisal.status;
    _previousGoalsController.text = appraisal.previousGoalsAchieved ?? '';
    _areasForImprovementController.text = appraisal.areasForImprovement ?? '';
    _newGoalsController.text = appraisal.newGoals ?? '';
    _commentsController.text = appraisal.comments ?? '';

    // Compliance fields
    _employeeSignatureController.text = appraisal.employeeSignature ?? '';
    _employeeSignatureDate = appraisal.employeeSignatureDate;
    _reviewerSignatureController.text = appraisal.reviewerSignature ?? '';
    _reviewerSignatureDate = appraisal.reviewerSignatureDate;
    _witnessNameController.text = appraisal.witnessName ?? '';
    _witnessSignatureController.text = appraisal.witnessSignature ?? '';
    _authorisedByController.text = appraisal.authorisedBy ?? '';
    _authorisedDate = appraisal.authorisedDate;
    _completedDate = appraisal.completedDate;
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _employees = await _service.getAllEmployees();
      _reviewers = await _service.getAllReviewers();

      // If a preselected employee was provided, use it
      if (widget.preselectedEmployeeId != null) {
        _selectedEmployeeId = widget.preselectedEmployeeId;
        _selectedEmployeeName = widget.preselectedEmployeeName;
        // Check eligibility (skip for editing existing appraisal)
        if (widget.appraisal == null) {
          final eligibility = await _service.checkEligibility(_selectedEmployeeId!);
          setState(() {
            _isEligible = eligibility['isEligible'] ?? true;
            _eligibilityReason = eligibility['reason'];
          });
        }
      }

      // Set default reviewer to current user
      if (_selectedReviewerId == null) {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          _selectedReviewerId = currentUser.id;
          // Find name from reviewers list
          final reviewer = _reviewers.firstWhere(
            (r) => r['id'] == currentUser.id,
            orElse: () => {},
          );
          _selectedReviewerName = reviewer['full_name'] ?? reviewer['name'] ?? reviewer['email'];
          if (_selectedReviewerName == null) {
            _selectedReviewerName = currentUser.email?.split('@').first ?? 'Current User';
          }
        }
      }

      // Default dates
      if (_appraisalDate == null) {
        _appraisalDate = DateTime.now();
      }
      if (_nextAppraisalDate == null) {
        _nextAppraisalDate = DateTime.now().add(const Duration(days: 365));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEligibility(String employeeId) async {
    setState(() => _isLoading = true);
    try {
      final eligibility = await _service.checkEligibility(employeeId);
      setState(() {
        _isEligible = eligibility['isEligible'] ?? true;
        _eligibilityReason = eligibility['reason'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate(void Function(DateTime) onSelected, {DateTime? initialDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate next appraisal date > appraisal date
    if (_nextAppraisalDate != null && _appraisalDate != null && _nextAppraisalDate!.isBefore(_appraisalDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Next appraisal date must be after the appraisal date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If status is completed or signed_off, require signatures
    if (_status == 'completed' || _status == 'signed_off') {
      if (_employeeSignatureController.text.isEmpty ||
          _employeeSignatureDate == null ||
          _reviewerSignatureController.text.isEmpty ||
          _reviewerSignatureDate == null ||
          _authorisedByController.text.isEmpty ||
          _authorisedDate == null ||
          _completedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('For "Completed" or "Signed Off" status, all signatures, dates, and authorisation are required.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      final appraisal = Appraisal.createNew(
        employeeId: _selectedEmployeeId!,
        reviewerId: _selectedReviewerId ?? currentUser?.id ?? '',
        appraisalDate: _appraisalDate!,
        previousGoalsAchieved: _previousGoalsController.text.isNotEmpty ? _previousGoalsController.text : null,
        areasForImprovement: _areasForImprovementController.text.isNotEmpty ? _areasForImprovementController.text : null,
        newGoals: _newGoalsController.text.isNotEmpty ? _newGoalsController.text : null,
        overallRating: _overallRating,
        nextAppraisalDate: _nextAppraisalDate ?? _appraisalDate!.add(const Duration(days: 365)),
        comments: _commentsController.text.isNotEmpty ? _commentsController.text : null,
        status: _status,
        employeeSignature: _employeeSignatureController.text.isNotEmpty ? _employeeSignatureController.text : null,
        employeeSignatureDate: _employeeSignatureDate,
        reviewerSignature: _reviewerSignatureController.text.isNotEmpty ? _reviewerSignatureController.text : null,
        reviewerSignatureDate: _reviewerSignatureDate,
        witnessName: _witnessNameController.text.isNotEmpty ? _witnessNameController.text : null,
        witnessSignature: _witnessSignatureController.text.isNotEmpty ? _witnessSignatureController.text : null,
        authorisedBy: _authorisedByController.text.isNotEmpty ? _authorisedByController.text : null,
        authorisedDate: _authorisedDate,
        completedDate: _completedDate,
      );

      if (widget.appraisal != null) {
        // Update existing
        final updated = Appraisal(
          id: widget.appraisal!.id,
          employeeId: appraisal.employeeId,
          reviewerId: appraisal.reviewerId,
          appraisalDate: appraisal.appraisalDate,
          previousGoalsAchieved: appraisal.previousGoalsAchieved,
          areasForImprovement: appraisal.areasForImprovement,
          newGoals: appraisal.newGoals,
          overallRating: appraisal.overallRating,
          nextAppraisalDate: appraisal.nextAppraisalDate,
          comments: appraisal.comments,
          status: appraisal.status,
          createdAt: widget.appraisal!.createdAt,
          updatedAt: DateTime.now(),
          employeeSignature: appraisal.employeeSignature,
          employeeSignatureDate: appraisal.employeeSignatureDate,
          reviewerSignature: appraisal.reviewerSignature,
          reviewerSignatureDate: appraisal.reviewerSignatureDate,
          witnessName: appraisal.witnessName,
          witnessSignature: appraisal.witnessSignature,
          authorisedBy: appraisal.authorisedBy,
          authorisedDate: appraisal.authorisedDate,
          completedDate: appraisal.completedDate,
        );
        await _service.updateAppraisal(updated);
      } else {
        await _service.createAppraisal(appraisal);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.appraisal != null ? 'Appraisal updated successfully' : 'Appraisal created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _setAppraisalDate(DateTime picked) {
    setState(() {
      _appraisalDate = picked;
      if (_nextAppraisalDate == null || _nextAppraisalDate!.isBefore(picked)) {
        _nextAppraisalDate = picked.add(const Duration(days: 365));
      }
    });
    return Future.value();
  }

  Future<void> _setNextAppraisalDate(DateTime picked) {
    setState(() => _nextAppraisalDate = picked);
    return Future.value();
  }

  @override
  void dispose() {
    _previousGoalsController.dispose();
    _areasForImprovementController.dispose();
    _newGoalsController.dispose();
    _commentsController.dispose();
    _employeeSignatureController.dispose();
    _reviewerSignatureController.dispose();
    _witnessNameController.dispose();
    _witnessSignatureController.dispose();
    _authorisedByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appraisal != null ? 'Edit Appraisal' : 'New Appraisal'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eligibility warning
                    if (!_isEligible && widget.appraisal == null && _selectedEmployeeId != null)
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _eligibilityReason ?? 'Employee may not be eligible for an appraisal',
                                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_isEligible && widget.appraisal == null && _selectedEmployeeId != null)
                      const SizedBox(height: 16),

                    // Employee (only for new appraisals) - pulls from carers table
                    if (widget.appraisal == null) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedEmployeeId,
                        decoration: const InputDecoration(
                          labelText: 'Employee (Carer)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Select a carer...'),
                          ),
                          ..._employees.map((e) {
                            final name = e['name'] ?? 'Unknown';
                            return DropdownMenuItem(
                              value: e['id'] as String,
                              child: Text(name),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedEmployeeId = v;
                            final emp = _employees.firstWhere((e) => e['id'] == v, orElse: () => {});
                            _selectedEmployeeName = emp['name'] ?? 'Unknown';
                          });
                          if (v != null) _checkEligibility(v);
                        },
                        validator: (v) => v == null ? 'Employee is required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Reviewer
                    DropdownButtonFormField<String>(
                      value: _selectedReviewerId,
                      decoration: const InputDecoration(
                        labelText: 'Reviewer',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.supervisor_account),
                      ),
                      items: _reviewers.map((r) {
                        final name = r['full_name'] ?? r['name'] ?? r['email'] ?? 'Unknown';
                        return DropdownMenuItem(
                          value: r['id'] as String,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedReviewerId = v;
                          final rev = _reviewers.firstWhere((r) => r['id'] == v, orElse: () => {});
                          _selectedReviewerName = rev['full_name'] ?? rev['name'] ?? rev['email'];
                        });
                      },
                      validator: (v) => v == null ? 'Reviewer is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Appraisal Date and Next Appraisal Date
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(_setAppraisalDate, initialDate: _appraisalDate),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Appraisal Date *',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _appraisalDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_appraisalDate!)
                                    : 'Select',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(_setNextAppraisalDate, initialDate: _nextAppraisalDate),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Next Appraisal Date *',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _nextAppraisalDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_nextAppraisalDate!)
                                    : 'Select',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Overall Rating
                    const Text('Overall Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final rating = index + 1;
                        final isSelected = _overallRating != null && _overallRating! >= rating;
                        return GestureDetector(
                          onTap: () => setState(() => _overallRating = rating),
                          child: Icon(
                            isSelected ? Icons.star : Icons.star_border,
                            size: 40,
                            color: isSelected ? Colors.amber : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    if (_overallRating != null)
                      Center(
                        child: Text(
                          _getRatingLabel(_overallRating!),
                          style: TextStyle(
                            color: _getRatingColor(_overallRating!),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Status
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['draft', 'completed', 'signed_off'].map((s) {
                        String display = s.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                        return DropdownMenuItem(value: s, child: Text(display));
                      }).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 16),

                    // Previous Goals Achieved
                    TextFormField(
                      controller: _previousGoalsController,
                      decoration: const InputDecoration(
                        labelText: 'Previous Goals Achieved',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Areas for Improvement
                    TextFormField(
                      controller: _areasForImprovementController,
                      decoration: const InputDecoration(
                        labelText: 'Areas for Improvement',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // New Goals
                    TextFormField(
                      controller: _newGoalsController,
                      decoration: const InputDecoration(
                        labelText: 'New Goals',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Comments
                    TextFormField(
                      controller: _commentsController,
                      decoration: const InputDecoration(
                        labelText: 'Comments (optional)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // ---------- COMPLIANCE / SIGNATURE SECTION ----------
                    const Divider(height: 32, thickness: 1),
                    const Text(
                      'Compliance & Signatures',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Employee Signature
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _employeeSignatureController,
                            decoration: const InputDecoration(
                              labelText: 'Employee Signature (full name)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate((d) => setState(() => _employeeSignatureDate = d),
                                initialDate: _employeeSignatureDate),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Signature Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _employeeSignatureDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_employeeSignatureDate!)
                                    : 'Select date',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Reviewer Signature
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _reviewerSignatureController,
                            decoration: const InputDecoration(
                              labelText: 'Reviewer Signature (full name)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate((d) => setState(() => _reviewerSignatureDate = d),
                                initialDate: _reviewerSignatureDate),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Signature Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _reviewerSignatureDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_reviewerSignatureDate!)
                                    : 'Select date',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Witness
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _witnessNameController,
                            decoration: const InputDecoration(
                              labelText: 'Witness Name (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _witnessSignatureController,
                            decoration: const InputDecoration(
                              labelText: 'Witness Signature (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Authorisation
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _authorisedByController,
                            decoration: const InputDecoration(
                              labelText: 'Authorised By (full name)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate((d) => setState(() => _authorisedDate = d),
                                initialDate: _authorisedDate),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Authorisation Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _authorisedDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_authorisedDate!)
                                    : 'Select date',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Completed Date
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate((d) => setState(() => _completedDate = d),
                                initialDate: _completedDate),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Completed Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _completedDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_completedDate!)
                                    : 'Select date',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox.shrink()),
                      ],
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
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(widget.appraisal != null ? 'Update Appraisal' : 'Create Appraisal'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Needs Improvement';
      case 2:
        return 'Below Expectations';
      case 3:
        return 'Meets Expectations';
      case 4:
        return 'Exceeds Expectations';
      case 5:
        return 'Outstanding';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}