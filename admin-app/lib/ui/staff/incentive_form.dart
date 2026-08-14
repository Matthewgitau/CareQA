import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/employee_incentive.dart';
import '../../services/incentive_service.dart';
import '../../widgets/reusable_form_widgets.dart';

class IncentiveFormScreen extends StatefulWidget {
  final EmployeeIncentive? incentive;

  const IncentiveFormScreen({super.key, this.incentive});

  @override
  State<IncentiveFormScreen> createState() => _IncentiveFormScreenState();
}

class _IncentiveFormScreenState extends State<IncentiveFormScreen> {
  final _service = IncentiveService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _selectedStaffId;
  String? _selectedStaffName;
  String _incentiveType = 'spot_award';
  DateTime _awardDate = DateTime.now();
  int _pointsAwarded = 0;
  double _monetaryValue = 0;
  bool _isPublic = true;
  bool _isSaving = false;

  final List<String> _incentiveTypes = [
    'employee_of_month',
    'employee_of_quarter',
    'employee_of_year',
    'spot_award',
    'performance_bonus',
    'referral_bonus',
    'retention_bonus',
    'team_award',
    'long_service_award',
    'outstanding_care',
    'innovation_award',
    'leadership_award',
    'safety_hero',
    'customer_service_excellence',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.incentive != null) {
      _populateForm(widget.incentive!);
    }
  }

  void _populateForm(EmployeeIncentive incentive) {
    _selectedStaffId = incentive.staffId;
    _selectedStaffName = incentive.staffName;
    _incentiveType = incentive.incentiveType;
    _awardDate = incentive.awardDate;
    _pointsAwarded = incentive.pointsAwarded;
    _monetaryValue = incentive.monetaryValue;
    _titleController.text = incentive.awardTitle;
    _descriptionController.text = incentive.awardDescription ?? '';
    _reasonController.text = incentive.awardReason;
    _isPublic = incentive.isPublic;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
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
      final incentive = EmployeeIncentive(
        id: widget.incentive?.id ?? '',
        staffId: _selectedStaffId,
        staffName: _selectedStaffName ?? '',
        incentiveType: _incentiveType,
        awardDate: _awardDate,
        pointsAwarded: _pointsAwarded,
        pointsBalance: _pointsAwarded,
        monetaryValue: _monetaryValue,
        awardTitle: _titleController.text,
        awardDescription: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        awardReason: _reasonController.text,
        isPublic: _isPublic,
        createdAt: widget.incentive?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _service.createIncentiveAward(incentive);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.incentive != null ? 'Incentive updated' : 'Incentive created'), backgroundColor: Colors.green),
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
        title: Text(widget.incentive != null ? 'Edit Incentive' : 'New Incentive Award'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.incentive != null ? 'Update' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

            // Incentive Type
            StaticDropdown(
              selectedValue: _incentiveType,
              onChanged: (v) => setState(() => _incentiveType = v ?? 'spot_award'),
              labelText: 'Incentive Type *',
              options: _incentiveTypes,
              required: true,
            ),
            const SizedBox(height: 16),

            // Award Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _awardDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _awardDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Award Date *',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_awardDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Award Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Award Title *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Points Awarded
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Points Awarded',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: _pointsAwarded.toString(),
              onChanged: (v) => _pointsAwarded = int.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 16),

            // Monetary Value
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Monetary Value (£)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: _monetaryValue.toString(),
              onChanged: (v) => _monetaryValue = double.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 16),

            // Reason
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Award *',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Public Toggle
            SwitchListTile(
              title: const Text('Public Recognition'),
              subtitle: const Text('Show on leaderboard'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
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
                    : Text(widget.incentive != null ? 'Update Incentive' : 'Save Incentive', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}