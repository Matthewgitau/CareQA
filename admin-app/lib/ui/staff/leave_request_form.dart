import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/leave_request.dart';
import '../../services/leave_service.dart';
import '../../widgets/reusable_form_widgets.dart';

class LeaveRequestFormScreen extends StatefulWidget {
  final LeaveRequest? request;

  const LeaveRequestFormScreen({super.key, this.request});

  @override
  State<LeaveRequestFormScreen> createState() => _LeaveRequestFormScreenState();
}

class _LeaveRequestFormScreenState extends State<LeaveRequestFormScreen> {
  final _service = LeaveService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedStaffId;
  String? _selectedStaffName;
  String? _employeeNumber;
  String _leaveType = 'annual_holiday';
  DateTime? _startDate;
  DateTime? _endDate;
  String _payRateType = 'statutory';
  int _payPercentage = 100;
  double? _hourlyRate;
  double? _dailyRate;
  bool _isSaving = false;

  final List<String> _leaveTypes = [
    'annual_holiday',
    'sick_leave',
    'compassionate_leave',
    'bereavement_leave',
    'maternity_leave',
    'paternity_leave',
    'adoption_leave',
    'parental_leave',
    'carers_leave',
    'study_leave',
    'emergency_leave',
    'unpaid_leave',
    'other',
  ];

  final List<String> _payRateTypes = [
    'statutory',
    'enhanced',
    'unpaid',
    'full_pay',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.request != null) {
      _populateForm(widget.request!);
    }
  }

  void _populateForm(LeaveRequest request) {
    _selectedStaffId = request.staffId;
    _selectedStaffName = request.staffName;
    _employeeNumber = request.employeeNumber;
    _leaveType = request.leaveType;
    _startDate = request.startDate;
    _endDate = request.endDate;
    _payRateType = request.payRateType;
    _payPercentage = request.payPercentage;
    _hourlyRate = request.hourlyRate;
    _dailyRate = request.dailyRate;
    _notesController.text = request.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final request = LeaveRequest(
        id: widget.request?.id ?? '',
        staffId: _selectedStaffId,
        staffName: _selectedStaffName ?? '',
        employeeNumber: _employeeNumber,
        leaveType: _leaveType,
        startDate: _startDate!,
        endDate: _endDate!,
        payRateType: _payRateType,
        payPercentage: _payPercentage,
        hourlyRate: _hourlyRate,
        dailyRate: _dailyRate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        status: widget.request?.status ?? 'pending',
        createdAt: widget.request?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.request != null) {
        await _service.updateLeaveRequest(request.id, request);
      } else {
        await _service.createLeaveRequest(request);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.request != null ? 'Leave updated' : 'Leave requested'), backgroundColor: Colors.green),
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

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.request != null ? 'Edit Leave Request' : 'New Leave Request'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.request != null ? 'Update' : 'Submit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Staff Selection
            StaffDropdown(
              selectedStaffId: _selectedStaffId,
              onChanged: (v) {
                setState(() {
                  _selectedStaffId = v;
                  if (v != null) {
                    _selectedStaffName = v;
                  }
                });
              },
              labelText: 'Staff Member *',
              required: true,
            ),
            const SizedBox(height: 16),

            // Leave Type
            StaticDropdown(
              selectedValue: _leaveType,
              onChanged: (v) => setState(() => _leaveType = v ?? 'annual_holiday'),
              labelText: 'Leave Type *',
              options: _leaveTypes,
              required: true,
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
                        labelText: 'Start Date *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Select date'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Select date'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pay Rate Type
            StaticDropdown(
              selectedValue: _payRateType,
              onChanged: (v) => setState(() => _payRateType = v ?? 'statutory'),
              labelText: 'Pay Rate Type *',
              options: _payRateTypes,
              required: true,
            ),
            const SizedBox(height: 16),

            // Pay Percentage
            Text('Pay Percentage: $_payPercentage%', style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _payPercentage.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: '$_payPercentage%',
              onChanged: (v) => setState(() => _payPercentage = v.toInt()),
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
            const SizedBox(height: 24),

            // Submit Button
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
                    : Text(widget.request != null ? 'Update Request' : 'Submit Request', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}