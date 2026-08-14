import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/staff_recognition.dart';
import '../../services/satisfaction_service.dart';
import '../../widgets/reusable_form_widgets.dart';

class StaffRecognitionFormScreen extends StatefulWidget {
  final StaffRecognition? recognition;

  const StaffRecognitionFormScreen({super.key, this.recognition});

  @override
  State<StaffRecognitionFormScreen> createState() => _StaffRecognitionFormScreenState();
}

class _StaffRecognitionFormScreenState extends State<StaffRecognitionFormScreen> {
  final _service = SatisfactionService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _awardDetailsController = TextEditingController();
  String? _selectedStaffId;
  String? _selectedStaffName;
  String _recognitionType = 'spot_award';
  DateTime _recognitionDate = DateTime.now();
  String? _nominatedById;
  String? _nominatedByName;
  bool _isSaving = false;

  final List<String> _recognitionTypes = [
    'employee_of_month',
    'employee_of_quarter',
    'employee_of_year',
    'spot_award',
    'team_award',
    'long_service',
    'exceptional_care',
    'innovation',
    'leadership',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.recognition != null) {
      _populateForm(widget.recognition!);
    }
  }

  void _populateForm(StaffRecognition recognition) {
    _selectedStaffId = recognition.staffId;
    _selectedStaffName = recognition.staffName;
    _recognitionType = recognition.recognitionType;
    _recognitionDate = recognition.recognitionDate;
    _reasonController.text = recognition.reason;
    _nominatedById = recognition.nominatedById;
    _nominatedByName = recognition.nominatedByName;
    _awardDetailsController.text = recognition.awardDetails ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _awardDetailsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final recognition = StaffRecognition(
        id: widget.recognition?.id ?? '',
        staffId: _selectedStaffId,
        staffName: _selectedStaffName ?? '',
        recognitionType: _recognitionType,
        recognitionDate: _recognitionDate,
        reason: _reasonController.text,
        nominatedById: _nominatedById,
        nominatedByName: _nominatedByName,
        awardDetails: _awardDetailsController.text.isNotEmpty ? _awardDetailsController.text : null,
        createdAt: widget.recognition?.createdAt ?? DateTime.now(),
      );

      if (widget.recognition != null) {
        // Update not implemented in service, would need to add
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update not implemented'), backgroundColor: Colors.orange),
        );
      } else {
        await _service.createRecognition(recognition);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.recognition != null ? 'Recognition updated' : 'Recognition created'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recognition != null ? 'Edit Recognition' : 'New Recognition'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.recognition != null ? 'Update' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Staff Selection
            EmployeeDropdown(
              selectedEmployeeId: _selectedStaffId,
              onChanged: (v) {
                setState(() {
                  _selectedStaffId = v;
                  _selectedStaffName = v;
                });
              },
              labelText: 'Staff Member *',
              required: true,
            ),
            const SizedBox(height: 16),

            // Recognition Type
            StaticDropdown(
              selectedValue: _recognitionType,
              onChanged: (v) => setState(() => _recognitionType = v ?? 'spot_award'),
              labelText: 'Recognition Type *',
              options: _recognitionTypes,
              required: true,
            ),
            const SizedBox(height: 16),

            // Recognition Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _recognitionDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _recognitionDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Recognition Date *',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_recognitionDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Reason
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Recognition *',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Nominated By
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _service.getAllStaff(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final staff = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _nominatedById,
                  decoration: const InputDecoration(
                    labelText: 'Nominated By',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select nominator (optional)')),
                    ...staff.map((s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Text('${s['name']} (${s['type'] == 'carer' ? 'Carer' : 'Staff'})'),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _nominatedById = v;
                      if (v != null) {
                        final nominator = staff.firstWhere((s) => s['id'] == v);
                        _nominatedByName = nominator['name'];
                      } else {
                        _nominatedByName = null;
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Award Details
            TextFormField(
              controller: _awardDetailsController,
              decoration: const InputDecoration(
                labelText: 'Award Details',
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
                    : Text(widget.recognition != null ? 'Update Recognition' : 'Save Recognition', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}