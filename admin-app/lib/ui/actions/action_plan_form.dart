import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/action_plan.dart';
import '../../services/action_plan_service.dart';

class ActionPlanFormScreen extends StatefulWidget {
  final String? actionPlanId;
  const ActionPlanFormScreen({super.key, this.actionPlanId});

  @override
  State<ActionPlanFormScreen> createState() => _ActionPlanFormScreenState();
}

class _ActionPlanFormScreenState extends State<ActionPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ActionPlanService(Supabase.instance.client);
  bool _loading = true;
  bool _saving = false;
  ActionPlan? _plan;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _actionRequiredController = TextEditingController();
  final _notesController = TextEditingController();
  final _sourceReferenceController = TextEditingController();
  final _regulatoryReferenceController = TextEditingController();
  final _complianceRequirementController = TextEditingController();
  final _verificationNotesController = TextEditingController();

  // Values
  String? _selectedSourceType;
  String? _selectedPriority;
  String? _selectedRiskLevel;
  String? _selectedCategory;
  String? _selectedActionType;
  String? _selectedAssignedTo;
  String? _selectedStatus;
  DateTime _assignedDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  bool _verificationRequired = false;
  int _progressPercentage = 0;

  // Staff list
  List<Map<String, dynamic>> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final staff = await Supabase.instance.client.from('profiles').select('id, full_name').order('full_name');
      setState(() => _staff = List<Map<String, dynamic>>.from(staff));

      if (widget.actionPlanId != null) {
        final plan = await _service.getActionPlan(widget.actionPlanId!);
        if (plan != null) {
          _loadPlanIntoForm(plan);
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _loadPlanIntoForm(ActionPlan plan) {
    setState(() {
      _plan = plan;
      _titleController.text = plan.title;
      _descriptionController.text = plan.description ?? '';
      _actionRequiredController.text = plan.actionRequired;
      _notesController.text = plan.notes ?? '';
      _sourceReferenceController.text = plan.sourceReference ?? '';
      _regulatoryReferenceController.text = plan.regulatoryReference ?? '';
      _complianceRequirementController.text = plan.complianceRequirement ?? '';
      _verificationNotesController.text = plan.verificationNotes ?? '';
      _selectedSourceType = plan.sourceType;
      _selectedPriority = plan.priority;
      _selectedRiskLevel = plan.riskLevel;
      _selectedCategory = plan.category;
      _selectedActionType = plan.actionType;
      _selectedAssignedTo = plan.assignedTo;
      _selectedStatus = plan.status;
      _assignedDate = plan.assignedDate;
      _targetDate = plan.targetCompletionDate;
      _verificationRequired = plan.verificationRequired;
      _progressPercentage = plan.progressPercentage;
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final plan = ActionPlan(
        id: _plan?.id,
        referenceNumber: _plan?.referenceNumber ?? '',
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        sourceType: _selectedSourceType,
        sourceReference: _sourceReferenceController.text.isEmpty ? null : _sourceReferenceController.text,
        priority: _selectedPriority ?? 'medium',
        riskLevel: _selectedRiskLevel ?? 'medium',
        category: _selectedCategory,
        regulatoryReference: _regulatoryReferenceController.text.isEmpty ? null : _regulatoryReferenceController.text,
        complianceRequirement: _complianceRequirementController.text.isEmpty ? null : _complianceRequirementController.text,
        actionRequired: _actionRequiredController.text,
        actionType: _selectedActionType,
        assignedTo: _selectedAssignedTo,
        assignedToName: _selectedAssignedTo != null ? _staff.firstWhere((s) => s['id'] == _selectedAssignedTo, orElse: () => {})['full_name'] : null,
        assignedBy: Supabase.instance.client.auth.currentUser?.id,
        assignedDate: _assignedDate,
        targetCompletionDate: _targetDate,
        status: _selectedStatus ?? 'open',
        progressPercentage: _progressPercentage,
        verificationRequired: _verificationRequired,
        verificationNotes: _verificationNotesController.text.isEmpty ? null : _verificationNotesController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: _plan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        organisationId: '',
      );

      if (widget.actionPlanId != null) {
        await _service.updateActionPlan(widget.actionPlanId!, plan.toJson());
      } else {
        await _service.createActionPlan(plan);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action plan ${widget.actionPlanId != null ? 'updated' : 'created'}'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.actionPlanId != null ? 'Edit Action Plan' : 'New Action Plan'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton.icon(
              onPressed: _savePlan,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('Basic Information', [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Source Type', border: OutlineInputBorder()),
                      value: _selectedSourceType,
                      items: const [
                        DropdownMenuItem(value: 'risk_assessment', child: Text('Risk Assessment')),
                        DropdownMenuItem(value: 'audit', child: Text('Audit')),
                        DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                        DropdownMenuItem(value: 'incident', child: Text('Incident')),
                        DropdownMenuItem(value: 'safeguarding', child: Text('Safeguarding')),
                        DropdownMenuItem(value: 'regulatory', child: Text('Regulatory')),
                        DropdownMenuItem(value: 'staff_supervision', child: Text('Staff Supervision')),
                        DropdownMenuItem(value: 'service_user_feedback', child: Text('Service User Feedback')),
                        DropdownMenuItem(value: 'quality_review', child: Text('Quality Review')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _selectedSourceType = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sourceReferenceController,
                      decoration: const InputDecoration(labelText: 'Source Reference', border: OutlineInputBorder()),
                    ),
                  ]),
                  _buildSection('Priority & Categorisation', [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Priority *', border: OutlineInputBorder()),
                            value: _selectedPriority,
                            items: const [
                              DropdownMenuItem(value: 'critical', child: Text('Critical')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'low', child: Text('Low')),
                            ],
                            onChanged: (v) => setState(() => _selectedPriority = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Risk Level', border: OutlineInputBorder()),
                            value: _selectedRiskLevel,
                            items: const [
                              DropdownMenuItem(value: 'critical', child: Text('Critical')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'low', child: Text('Low')),
                            ],
                            onChanged: (v) => setState(() => _selectedRiskLevel = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      value: _selectedCategory,
                      items: const [
                        DropdownMenuItem(value: 'clinical_care', child: Text('Clinical Care')),
                        DropdownMenuItem(value: 'medication', child: Text('Medication')),
                        DropdownMenuItem(value: 'safeguarding', child: Text('Safeguarding')),
                        DropdownMenuItem(value: 'staff_training', child: Text('Staff Training')),
                        DropdownMenuItem(value: 'documentation', child: Text('Documentation')),
                        DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
                        DropdownMenuItem(value: 'environment', child: Text('Environment')),
                        DropdownMenuItem(value: 'communication', child: Text('Communication')),
                        DropdownMenuItem(value: 'governance', child: Text('Governance')),
                        DropdownMenuItem(value: 'finance', child: Text('Finance')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _regulatoryReferenceController,
                      decoration: const InputDecoration(labelText: 'Regulatory Reference', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _complianceRequirementController,
                      decoration: const InputDecoration(labelText: 'Compliance Requirement', border: OutlineInputBorder()),
                    ),
                  ]),
                  _buildSection('Action Details', [
                    TextFormField(
                      controller: _actionRequiredController,
                      decoration: const InputDecoration(labelText: 'Action Required *', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Action Type', border: OutlineInputBorder()),
                      value: _selectedActionType,
                      items: const [
                        DropdownMenuItem(value: 'corrective', child: Text('Corrective')),
                        DropdownMenuItem(value: 'preventive', child: Text('Preventive')),
                        DropdownMenuItem(value: 'improvement', child: Text('Improvement')),
                        DropdownMenuItem(value: 'training', child: Text('Training')),
                        DropdownMenuItem(value: 'review', child: Text('Review')),
                        DropdownMenuItem(value: 'policy_update', child: Text('Policy Update')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _selectedActionType = v),
                    ),
                  ]),
                  _buildSection('Assignment', [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Assigned To *', border: OutlineInputBorder()),
                      value: _selectedAssignedTo,
                      items: _staff.map((s) => DropdownMenuItem(value: s['id']?.toString(), child: Text(s['full_name'] ?? 'Unknown'))).toList(),
                      onChanged: (v) => setState(() => _selectedAssignedTo = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: _assignedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                              if (date != null) setState(() => _assignedDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Assigned Date', border: OutlineInputBorder()),
                              child: Text(DateFormat('dd/MM/yyyy').format(_assignedDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: _targetDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (date != null) setState(() => _targetDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Target Completion *', border: OutlineInputBorder()),
                              child: Text(DateFormat('dd/MM/yyyy').format(_targetDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _buildSection('Progress', [
                    Row(
                      children: [
                        Expanded(child: Text('Progress: $_progressPercentage%')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _progressPercentage.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: '$_progressPercentage%',
                            onChanged: (v) => setState(() => _progressPercentage = v.toInt()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'open', child: Text('Open')),
                        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'verified', child: Text('Verified')),
                        DropdownMenuItem(value: 'closed', child: Text('Closed')),
                      ],
                      onChanged: (v) => setState(() => _selectedStatus = v),
                    ),
                  ]),
                  _buildSection('Verification', [
                    SwitchListTile(
                      title: const Text('Verification Required'),
                      subtitle: const Text('Requires sign-off upon completion'),
                      value: _verificationRequired,
                      onChanged: (v) => setState(() => _verificationRequired = v),
                    ),
                    if (_verificationRequired) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _verificationNotesController,
                        decoration: const InputDecoration(labelText: 'Verification Notes', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                    ],
                  ]),
                  _buildSection('Notes', [
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Additional Notes', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _actionRequiredController.dispose();
    _notesController.dispose();
    _sourceReferenceController.dispose();
    _regulatoryReferenceController.dispose();
    _complianceRequirementController.dispose();
    _verificationNotesController.dispose();
    super.dispose();
  }
}