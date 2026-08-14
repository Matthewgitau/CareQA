import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/policy.dart';
import '../../services/policy_service.dart';

class PolicyFormScreen extends StatefulWidget {
  final String? policyId;
  const PolicyFormScreen({super.key, this.policyId});

  @override
  State<PolicyFormScreen> createState() => _PolicyFormScreenState();
}

class _PolicyFormScreenState extends State<PolicyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PolicyService(Supabase.instance.client);
  bool _loading = true;
  bool _saving = false;
  Policy? _policy;

  // Controllers
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _policyBodyController = TextEditingController();
  final _scopeController = TextEditingController();
  final _purposeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _trainingNotesController = TextEditingController();
  final _notesController = TextEditingController();
  final _internalNotesController = TextEditingController();

  // Values
  String? _selectedCategory;
  String? _selectedStatus;
  DateTime? _effectiveDate;
  DateTime? _reviewDate;
  DateTime? _nextReviewDate;
  bool _trainingRequired = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      if (widget.policyId != null) {
        final policy = await _service.getPolicy(widget.policyId!);
        if (policy != null) {
          _loadPolicyIntoForm(policy);
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _loadPolicyIntoForm(Policy policy) {
    setState(() {
      _policy = policy;
      _titleController.text = policy.policyTitle;
      _summaryController.text = policy.summary ?? '';
      _policyBodyController.text = policy.policyBody;
      _scopeController.text = policy.scope ?? '';
      _purposeController.text = policy.purpose ?? '';
      _departmentController.text = policy.department ?? '';
      _subCategoryController.text = policy.subCategory ?? '';
      _trainingNotesController.text = policy.trainingNotes ?? '';
      _notesController.text = policy.notes ?? '';
      _internalNotesController.text = policy.internalNotes ?? '';
      _selectedCategory = policy.category;
      _selectedStatus = policy.status;
      _effectiveDate = policy.effectiveDate;
      _reviewDate = policy.reviewDate;
      _nextReviewDate = policy.nextReviewDate;
      _trainingRequired = policy.trainingRequired;
    });
  }

  Future<void> _savePolicy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final policy = Policy(
        id: _policy?.id,
        policyTitle: _titleController.text,
        policyReference: _policy?.policyReference ?? '',
        version: _policy?.version ?? '1.0',
        department: _departmentController.text.isEmpty ? null : _departmentController.text,
        category: _selectedCategory,
        subCategory: _subCategoryController.text.isEmpty ? null : _subCategoryController.text,
        summary: _summaryController.text.isEmpty ? null : _summaryController.text,
        policyBody: _policyBodyController.text,
        scope: _scopeController.text.isEmpty ? null : _scopeController.text,
        purpose: _purposeController.text.isEmpty ? null : _purposeController.text,
        status: _selectedStatus ?? 'draft',
        effectiveDate: _effectiveDate,
        reviewDate: _reviewDate,
        nextReviewDate: _nextReviewDate,
        trainingRequired: _trainingRequired,
        trainingNotes: _trainingNotesController.text.isEmpty ? null : _trainingNotesController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        internalNotes: _internalNotesController.text.isEmpty ? null : _internalNotesController.text,
        createdAt: _policy?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        organisationId: '',
      );

      if (widget.policyId != null) {
        await _service.updatePolicy(widget.policyId!, policy.toJson());
      } else {
        await _service.createPolicy(policy);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Policy ${widget.policyId != null ? 'updated' : 'created'}'), backgroundColor: Colors.green));
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
        title: Text(widget.policyId != null ? 'Edit Policy' : 'New Policy'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton.icon(
              onPressed: _savePolicy,
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
                  _buildSection('Policy Information', [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Policy Title *', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                      value: _selectedCategory,
                      items: const [
                        DropdownMenuItem(value: 'clinical', child: Text('Clinical')),
                        DropdownMenuItem(value: 'governance', child: Text('Governance')),
                        DropdownMenuItem(value: 'health_safety', child: Text('Health & Safety')),
                        DropdownMenuItem(value: 'human_resources', child: Text('Human Resources')),
                        DropdownMenuItem(value: 'finance', child: Text('Finance')),
                        DropdownMenuItem(value: 'data_protection', child: Text('Data Protection')),
                        DropdownMenuItem(value: 'safeguarding', child: Text('Safeguarding')),
                        DropdownMenuItem(value: 'medication', child: Text('Medication')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                        DropdownMenuItem(value: 'service_user', child: Text('Service User')),
                        DropdownMenuItem(value: 'quality', child: Text('Quality')),
                        DropdownMenuItem(value: 'operations', child: Text('Operations')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subCategoryController,
                      decoration: const InputDecoration(labelText: 'Sub-category', border: OutlineInputBorder()),
                    ),
                  ]),
                  _buildSection('Policy Content', [
                    TextFormField(
                      controller: _summaryController,
                      decoration: const InputDecoration(labelText: 'Summary', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _policyBodyController,
                      decoration: const InputDecoration(labelText: 'Policy Body *', border: OutlineInputBorder()),
                      maxLines: 8,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _scopeController,
                      decoration: const InputDecoration(labelText: 'Scope', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _purposeController,
                      decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                  ]),
                  _buildSection('Dates', [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: _effectiveDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (date != null) setState(() => _effectiveDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Effective Date', border: OutlineInputBorder()),
                              child: Text(_effectiveDate != null ? DateFormat('dd/MM/yyyy').format(_effectiveDate!) : 'Select date'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: _nextReviewDate ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (date != null) setState(() => _nextReviewDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Next Review Date', border: OutlineInputBorder()),
                              child: Text(_nextReviewDate != null ? DateFormat('dd/MM/yyyy').format(_nextReviewDate!) : 'Select date'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _buildSection('Training', [
                    SwitchListTile(
                      title: const Text('Training Required'),
                      subtitle: const Text('Does this policy require staff training?'),
                      value: _trainingRequired,
                      onChanged: (v) => setState(() => _trainingRequired = v),
                    ),
                    if (_trainingRequired) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _trainingNotesController,
                        decoration: const InputDecoration(labelText: 'Training Notes', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                    ],
                  ]),
                  _buildSection('Status', [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'review_pending', child: Text('Review Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'published', child: Text('Published')),
                        DropdownMenuItem(value: 'archived', child: Text('Archived')),
                      ],
                      onChanged: (v) => setState(() => _selectedStatus = v),
                    ),
                  ]),
                  _buildSection('Notes', [
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _internalNotesController,
                      decoration: const InputDecoration(labelText: 'Internal Notes', border: OutlineInputBorder()),
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
    _summaryController.dispose();
    _policyBodyController.dispose();
    _scopeController.dispose();
    _purposeController.dispose();
    _departmentController.dispose();
    _subCategoryController.dispose();
    _trainingNotesController.dispose();
    _notesController.dispose();
    _internalNotesController.dispose();
    super.dispose();
  }
}