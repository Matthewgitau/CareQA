import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/mca_assessment.dart';
import 'package:admin_app/services/mca_service.dart';

class McaForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;
  final String decisionType;
  final McaAssessment? existing;

  const McaForm({
    super.key,
    required this.serviceUserId,
    required this.serviceUserName,
    required this.decisionType,
    this.existing,
  });

  @override
  State<McaForm> createState() => _McaFormState();
}

class _McaFormState extends State<McaForm> {
  final _formKey = GlobalKey<FormState>();
  final _mcaService = McaService(Supabase.instance.client);
  bool _isSubmitting = false;

  final _reasonController = TextEditingController();
  final _q1ConditionController = TextEditingController();
  final _q2aNotesController = TextEditingController();
  final _q2bNotesController = TextEditingController();
  final _q2cNotesController = TextEditingController();
  final _q2dNotesController = TextEditingController();
  final _howCompletedController = TextEditingController();
  final _outcomeController = TextEditingController();
  final _assessorController = TextEditingController();

  bool? _q1Impairment;
  bool? _q2aUnderstands;
  bool? _q2bRetains;
  bool? _q2cWeighs;
  bool? _q2dCommunicates;
  bool _fluctuatingCapacity = false;
  DateTime _assessmentDate = DateTime.now();
  DateTime? _reassessmentDate;

  bool get _lacksCapacity =>
      _q1Impairment == true &&
      (_q2aUnderstands == false ||
       _q2bRetains == false ||
       _q2cWeighs == false ||
       _q2dCommunicates == false);

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _reasonController.text = e.reasonForAssessment ?? '';
      _q1ConditionController.text = e.q1Condition ?? '';
      _q2aNotesController.text = e.q2aNotes ?? '';
      _q2bNotesController.text = e.q2bNotes ?? '';
      _q2cNotesController.text = e.q2cNotes ?? '';
      _q2dNotesController.text = e.q2dNotes ?? '';
      _howCompletedController.text = e.howCompleted ?? '';
      _outcomeController.text = e.outcome ?? '';
      _assessorController.text = e.assessorName ?? '';
      _q1Impairment = e.q1Impairment;
      _q2aUnderstands = e.q2aUnderstands;
      _q2bRetains = e.q2bRetains;
      _q2cWeighs = e.q2cWeighs;
      _q2dCommunicates = e.q2dCommunicates;
      _fluctuatingCapacity = e.hasFluctuatingCapacity;
      _assessmentDate = e.assessmentDate;
      _reassessmentDate = e.reassessmentDate;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _q1ConditionController.dispose();
    _q2aNotesController.dispose();
    _q2bNotesController.dispose();
    _q2cNotesController.dispose();
    _q2dNotesController.dispose();
    _howCompletedController.dispose();
    _outcomeController.dispose();
    _assessorController.dispose();
    super.dispose();
  }

  Widget _yesNoField(String label, bool? value, void Function(bool?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Yes — Able'),
                value: true,
                groupValue: value,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('No — Unable'),
                value: false,
                groupValue: value,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _notesField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final assessment = McaAssessment(
        serviceUserId: widget.serviceUserId,
        serviceUserName: widget.serviceUserName,
        decisionType: widget.decisionType,
        reasonForAssessment: _reasonController.text.trim(),
        q1Impairment: _q1Impairment,
        q1Condition: _q1ConditionController.text.trim(),
        q2aUnderstands: _q2aUnderstands,
        q2aNotes: _q2aNotesController.text.trim(),
        q2bRetains: _q2bRetains,
        q2bNotes: _q2bNotesController.text.trim(),
        q2cWeighs: _q2cWeighs,
        q2cNotes: _q2cNotesController.text.trim(),
        q2dCommunicates: _q2dCommunicates,
        q2dNotes: _q2dNotesController.text.trim(),
        assessmentDate: _assessmentDate,
        howCompleted: _howCompletedController.text.trim(),
        outcome: _outcomeController.text.trim(),
        hasFluctuatingCapacity: _fluctuatingCapacity,
        reassessmentDate: _reassessmentDate,
        assessorName: _assessorController.text.trim(),
        status: 'completed',
      );
      if (widget.existing?.id != null) {
        await _mcaService.updateAssessment(widget.existing!.id!, assessment);
      } else {
        await _mcaService.createAssessment(assessment);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MCA assessment saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = McaAssessment.decisionTypeLabels[widget.decisionType] ?? widget.decisionType;
    final prompts = McaAssessment.decisionTypePrompts[widget.decisionType] ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text('MCA — $label'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFFE3F2FD),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service User: ${widget.serviceUserName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Decision Area: $label',
                        style: const TextStyle(color: Color(0xFF1565C0))),
                    Text('Date: ${_assessmentDate.toString().split(' ').first}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('What has led you to believe this person may lack capacity?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _notesField('Reason for assessment', _reasonController),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.amber[50],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '⚖️ Per recent case law: complete Q2a–d before Q1.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Q2a — Can they understand the information?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (prompts.isNotEmpty) ...prompts.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• $p', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  )),
                  const SizedBox(height: 8),
                  _yesNoField('Can they understand?', _q2aUnderstands,
                      (v) => setState(() => _q2aUnderstands = v)),
                  const SizedBox(height: 8),
                  _notesField('Record observations / direct quotes', _q2aNotesController),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Q2b — Can they retain the information?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Not a memory test. Notebooks and picture charts are acceptable.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _yesNoField('Can they retain?', _q2bRetains,
                      (v) => setState(() => _q2bRetains = v)),
                  const SizedBox(height: 8),
                  _notesField('Record how you tested retention', _q2bNotesController),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Q2c — Can they weigh the information?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Must include acknowledgment of risks and consequences.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _yesNoField('Can they weigh?', _q2cWeighs,
                      (v) => setState(() => _q2cWeighs = v)),
                  const SizedBox(height: 8),
                  _notesField('Questions asked and responses given', _q2cNotesController),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Q2d — Can they communicate the decision?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Does not need to be verbal. Cannot answer No because someone refuses.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _yesNoField('Can they communicate?', _q2dCommunicates,
                      (v) => setState(() => _q2dCommunicates = v)),
                  const SizedBox(height: 8),
                  _notesField('Record how they communicated', _q2dNotesController),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Q1 — Is there an impairment or disturbance in the functioning of mind or brain?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _yesNoField('Impairment present?', _q1Impairment,
                      (v) => setState(() => _q1Impairment = v)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _q1ConditionController,
                    decoration: const InputDecoration(
                      labelText: 'If yes, state the condition',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: _lacksCapacity ? Colors.red[50] : Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _lacksCapacity
                        ? '⚠️ This person LACKS CAPACITY under MCA 2005'
                        : '✅ This person HAS CAPACITY',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _lacksCapacity ? Colors.red[800] : Colors.green[800],
                    ),
                  ),
                  if (_lacksCapacity) ...[
                    const SizedBox(height: 8),
                    const Text('A Best Interest Decision form must now be completed.',
                        style: TextStyle(fontSize: 13)),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Fluctuating capacity?'),
                    subtitle: const Text('Can the decision wait until capacity returns?'),
                    value: _fluctuatingCapacity,
                    onChanged: (v) => setState(() => _fluctuatingCapacity = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_fluctuatingCapacity) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _reassessmentDate = picked);
                      },
                      child: Text(_reassessmentDate != null
                          ? 'Reassessment: ${_reassessmentDate!.toString().split(' ').first}'
                          : 'Set Reassessment Date'),
                    ),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('How was the assessment completed?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Who was present, where did it happen, how did you enable the person?',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _notesField('Assessment context', _howCompletedController),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Outcome', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _notesField('Record the outcome', _outcomeController),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _assessorController,
                    decoration: const InputDecoration(
                      labelText: 'Decision maker / Assessor name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save MCA Assessment', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}