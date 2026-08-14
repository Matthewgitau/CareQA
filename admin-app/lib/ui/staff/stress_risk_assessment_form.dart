import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/welfare_service.dart';
import '../../widgets/reusable_form_widgets.dart';

class StressRiskAssessmentFormScreen extends StatefulWidget {
  const StressRiskAssessmentFormScreen({super.key});

  @override
  State<StressRiskAssessmentFormScreen> createState() => _StressRiskAssessmentFormScreenState();
}

class _StressRiskAssessmentFormScreenState extends State<StressRiskAssessmentFormScreen> {
  final _service = WelfareService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  String? _selectedStaffId;
  String? _selectedStaffName;
  DateTime _assessmentDate = DateTime.now();
  DateTime? _reviewDate;
  int _demandsScore = 3;
  int _controlScore = 3;
  int _supportScore = 3;
  int _relationshipsScore = 3;
  int _roleScore = 3;
  int _changeScore = 3;
  String? _demandsNotes;
  String? _controlNotes;
  String? _supportNotes;
  String? _relationshipsNotes;
  String? _roleNotes;
  String? _changeNotes;
  String? _riskAssessmentNotes;
  String? _actionPlan;
  DateTime? _actionDeadline;
  String? _actionOwner;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stress Risk Assessment'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

            // Dates
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _assessmentDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _assessmentDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Assessment Date *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_assessmentDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _reviewDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _reviewDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Review Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_reviewDate != null ? DateFormat('dd/MM/yyyy').format(_reviewDate!) : 'Select date'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // HSE Six Management Standards
            const Text('HSE Six Management Standards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildScoreSection('Demands', _demandsScore, (v) => setState(() => _demandsScore = v), _demandsNotes, (v) => setState(() => _demandsNotes = v)),
            _buildScoreSection('Control', _controlScore, (v) => setState(() => _controlScore = v), _controlNotes, (v) => setState(() => _controlNotes = v)),
            _buildScoreSection('Support', _supportScore, (v) => setState(() => _supportScore = v), _supportNotes, (v) => setState(() => _supportNotes = v)),
            _buildScoreSection('Relationships', _relationshipsScore, (v) => setState(() => _relationshipsScore = v), _relationshipsNotes, (v) => setState(() => _relationshipsNotes = v)),
            _buildScoreSection('Role', _roleScore, (v) => setState(() => _roleScore = v), _roleNotes, (v) => setState(() => _roleNotes = v)),
            _buildScoreSection('Change', _changeScore, (v) => setState(() => _changeScore = v), _changeNotes, (v) => setState(() => _changeNotes = v)),
            const SizedBox(height: 16),

            // Overall Risk Level
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getRiskColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Risk Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(_getRiskLevel(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Risk Assessment Notes
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Risk Assessment Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: (v) => _riskAssessmentNotes = v,
            ),
            const SizedBox(height: 16),

            // Action Plan
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Action Plan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: (v) => _actionPlan = v,
            ),
            const SizedBox(height: 16),

            // Action Deadline
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _actionDeadline ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _actionDeadline = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Action Deadline',
                  border: OutlineInputBorder(),
                ),
                child: Text(_actionDeadline != null ? DateFormat('dd/MM/yyyy').format(_actionDeadline!) : 'Select date'),
              ),
            ),
            const SizedBox(height: 16),

            // Action Owner
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Action Owner',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _actionOwner = v,
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
                    : const Text('Save Assessment', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection(String title, int score, Function(int) onScoreChanged, String? notes, Function(String?) onNotesChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title: $score/5', style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: score.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$score',
              onChanged: (v) => onScoreChanged(v.toInt()),
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: '$title Notes',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              onChanged: onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }

  String _getRiskLevel() {
    final average = (_demandsScore + _controlScore + _supportScore + _relationshipsScore + _roleScore + _changeScore) / 6;
    if (average >= 4) return 'Low Risk';
    if (average >= 3) return 'Medium Risk';
    if (average >= 2) return 'High Risk';
    return 'Critical Risk';
  }

  Color _getRiskColor() {
    final average = (_demandsScore + _controlScore + _supportScore + _relationshipsScore + _roleScore + _changeScore) / 6;
    if (average >= 4) return Colors.green.shade100;
    if (average >= 3) return Colors.orange.shade100;
    if (average >= 2) return Colors.red.shade100;
    return Colors.purple.shade100;
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
      final assessmentData = {
        'staff_id': _selectedStaffId,
        'staff_name': _selectedStaffName ?? '',
        'assessment_date': _assessmentDate.toIso8601String().split('T').first,
        'review_date': _reviewDate?.toIso8601String().split('T').first,
        'demands_score': _demandsScore,
        'demands_notes': _demandsNotes,
        'control_score': _controlScore,
        'control_notes': _controlNotes,
        'support_score': _supportScore,
        'support_notes': _supportNotes,
        'relationships_score': _relationshipsScore,
        'relationships_notes': _relationshipsNotes,
        'role_score': _roleScore,
        'role_notes': _roleNotes,
        'change_score': _changeScore,
        'change_notes': _changeNotes,
        'overall_risk_level': _getRiskLevel().toLowerCase().replaceAll(' ', '_'),
        'risk_assessment_notes': _riskAssessmentNotes,
        'action_plan': _actionPlan,
        'action_deadline': _actionDeadline?.toIso8601String().split('T').first,
        'action_owner': _actionOwner,
      };

      await _service.createStressRiskAssessment(assessmentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stress risk assessment saved'), backgroundColor: Colors.green),
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
}