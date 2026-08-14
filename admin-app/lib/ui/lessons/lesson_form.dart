import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/lesson_learnt.dart';
import '../../services/lesson_learnt_service.dart';

class LessonFormScreen extends StatefulWidget {
  final String? lessonId;
  const LessonFormScreen({super.key, this.lessonId});

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = LessonLearntService(Supabase.instance.client);
  bool _loading = true;
  bool _saving = false;
  LessonLearnt? _lesson;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourceReferenceController = TextEditingController();
  final _rootCauseController = TextEditingController();
  final _keyLearningController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _changesMadeController = TextEditingController();
  final _implementationNotesController = TextEditingController();
  final _reviewNotesController = TextEditingController();
  final _sharedNotesController = TextEditingController();

  // Values
  String? _selectedSourceType;
  String? _selectedSeverity;
  String? _selectedCategory;
  String? _selectedRootCauseCategory;
  String? _selectedStatus;
  DateTime? _incidentDate;
  bool _implemented = false;
  DateTime? _implementationDate;
  bool _sharedWithTeam = false;
  DateTime? _sharedDate;
  String? _selectedSharedMethod;
  bool _isTrainingRequired = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      if (widget.lessonId != null) {
        final lesson = await _service.getLesson(widget.lessonId!);
        if (lesson != null) {
          _loadLessonIntoForm(lesson);
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _loadLessonIntoForm(LessonLearnt lesson) {
    setState(() {
      _lesson = lesson;
      _titleController.text = lesson.title;
      _descriptionController.text = lesson.description;
      _sourceReferenceController.text = lesson.sourceReference ?? '';
      _rootCauseController.text = lesson.rootCause ?? '';
      _keyLearningController.text = lesson.keyLearning;
      _recommendationsController.text = lesson.recommendations ?? '';
      _changesMadeController.text = lesson.changesMade ?? '';
      _implementationNotesController.text = lesson.implementationNotes ?? '';
      _reviewNotesController.text = lesson.reviewNotes ?? '';
      _sharedNotesController.text = lesson.sharedNotes ?? '';
      _selectedSourceType = lesson.sourceType;
      _selectedSeverity = lesson.severity;
      _selectedCategory = lesson.category;
      _selectedRootCauseCategory = lesson.rootCauseCategory;
      _selectedStatus = lesson.status;
      _incidentDate = lesson.incidentDate;
      _implemented = lesson.implemented;
      _implementationDate = lesson.implementationDate;
      _sharedWithTeam = lesson.sharedWithTeam;
      _sharedDate = lesson.sharedDate;
      _selectedSharedMethod = lesson.sharedMethod;
      _isTrainingRequired = lesson.isTrainingRequired;
    });
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final lesson = LessonLearnt(
        id: _lesson?.id,
        referenceNumber: _lesson?.referenceNumber ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        sourceType: _selectedSourceType,
        sourceReference: _sourceReferenceController.text.isEmpty ? null : _sourceReferenceController.text,
        incidentDate: _incidentDate,
        severity: _selectedSeverity ?? 'medium',
        category: _selectedCategory,
        rootCause: _rootCauseController.text.isEmpty ? null : _rootCauseController.text,
        rootCauseCategory: _selectedRootCauseCategory,
        keyLearning: _keyLearningController.text,
        recommendations: _recommendationsController.text.isEmpty ? null : _recommendationsController.text,
        changesMade: _changesMadeController.text.isEmpty ? null : _changesMadeController.text,
        actionPlanId: _lesson?.actionPlanId,
        implemented: _implemented,
        implementationDate: _implementationDate,
        implementationNotes: _implementationNotesController.text.isEmpty ? null : _implementationNotesController.text,
        reviewNotes: _reviewNotesController.text.isEmpty ? null : _reviewNotesController.text,
        sharedWithTeam: _sharedWithTeam,
        sharedDate: _sharedDate,
        sharedMethod: _selectedSharedMethod,
        sharedNotes: _sharedNotesController.text.isEmpty ? null : _sharedNotesController.text,
        isTrainingRequired: _isTrainingRequired,
        status: _selectedStatus ?? 'draft',
        createdAt: _lesson?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        organisationId: '',
      );

      if (widget.lessonId != null) {
        await _service.updateLesson(widget.lessonId!, lesson.toJson());
      } else {
        await _service.createLesson(lesson);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lesson ${widget.lessonId != null ? 'updated' : 'created'}'), backgroundColor: Colors.green));
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
        title: Text(widget.lessonId != null ? 'Edit Lesson' : 'New Lesson'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton.icon(
              onPressed: _saveLesson,
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
                  _buildSection('Incident Details', [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Source Type', border: OutlineInputBorder()),
                      value: _selectedSourceType,
                      items: const [
                        DropdownMenuItem(value: 'incident', child: Text('Incident')),
                        DropdownMenuItem(value: 'accident', child: Text('Accident')),
                        DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                        DropdownMenuItem(value: 'safeguarding', child: Text('Safeguarding')),
                        DropdownMenuItem(value: 'audit_finding', child: Text('Audit Finding')),
                        DropdownMenuItem(value: 'inspection', child: Text('Inspection')),
                        DropdownMenuItem(value: 'near_miss', child: Text('Near Miss')),
                        DropdownMenuItem(value: 'medication_error', child: Text('Medication Error')),
                        DropdownMenuItem(value: 'service_user_feedback', child: Text('Service User Feedback')),
                        DropdownMenuItem(value: 'staff_feedback', child: Text('Staff Feedback')),
                        DropdownMenuItem(value: 'external_review', child: Text('External Review')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _selectedSourceType = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sourceReferenceController,
                      decoration: const InputDecoration(labelText: 'Source Reference', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: _incidentDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                        if (date != null) setState(() => _incidentDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Incident Date', border: OutlineInputBorder()),
                        child: Text(_incidentDate != null ? DateFormat('dd/MM/yyyy').format(_incidentDate!) : 'Select date'),
                      ),
                    ),
                  ]),
                  _buildSection('Classification', [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Severity *', border: OutlineInputBorder()),
                            value: _selectedSeverity,
                            items: const [
                              DropdownMenuItem(value: 'critical', child: Text('Critical')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'low', child: Text('Low')),
                            ],
                            onChanged: (v) => setState(() => _selectedSeverity = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
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
                              DropdownMenuItem(value: 'health_safety', child: Text('Health & Safety')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (v) => setState(() => _selectedCategory = v),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _buildSection('Root Cause Analysis', [
                    TextFormField(
                      controller: _rootCauseController,
                      decoration: const InputDecoration(labelText: 'Root Cause *', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Root Cause Category', border: OutlineInputBorder()),
                      value: _selectedRootCauseCategory,
                      items: const [
                        DropdownMenuItem(value: 'training_gap', child: Text('Training Gap')),
                        DropdownMenuItem(value: 'process_failure', child: Text('Process Failure')),
                        DropdownMenuItem(value: 'communication_breakdown', child: Text('Communication Breakdown')),
                        DropdownMenuItem(value: 'resource_shortage', child: Text('Resource Shortage')),
                        DropdownMenuItem(value: 'environmental', child: Text('Environmental')),
                        DropdownMenuItem(value: 'equipment_failure', child: Text('Equipment Failure')),
                        DropdownMenuItem(value: 'staffing', child: Text('Staffing')),
                        DropdownMenuItem(value: 'systemic', child: Text('Systemic')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _selectedRootCauseCategory = v),
                    ),
                  ]),
                  _buildSection('Key Learning', [
                    TextFormField(
                      controller: _keyLearningController,
                      decoration: const InputDecoration(labelText: 'Key Learning *', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _recommendationsController,
                      decoration: const InputDecoration(labelText: 'Recommendations', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _changesMadeController,
                      decoration: const InputDecoration(labelText: 'Changes Made', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ]),
                  _buildSection('Implementation', [
                    SwitchListTile(
                      title: const Text('Implemented'),
                      subtitle: const Text('Has this lesson been implemented?'),
                      value: _implemented,
                      onChanged: (v) => setState(() => _implemented = v),
                    ),
                    if (_implemented) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(context: context, initialDate: _implementationDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                          if (date != null) setState(() => _implementationDate = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Implementation Date', border: OutlineInputBorder()),
                          child: Text(_implementationDate != null ? DateFormat('dd/MM/yyyy').format(_implementationDate!) : 'Select date'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _implementationNotesController,
                        decoration: const InputDecoration(labelText: 'Implementation Notes', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                    ],
                  ]),
                  _buildSection('Sharing', [
                    SwitchListTile(
                      title: const Text('Shared With Team'),
                      subtitle: const Text('Has this lesson been shared with the team?'),
                      value: _sharedWithTeam,
                      onChanged: (v) => setState(() => _sharedWithTeam = v),
                    ),
                    if (_sharedWithTeam) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Shared Method', border: OutlineInputBorder()),
                        value: _selectedSharedMethod,
                        items: const [
                          DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                          DropdownMenuItem(value: 'email', child: Text('Email')),
                          DropdownMenuItem(value: 'newsletter', child: Text('Newsletter')),
                          DropdownMenuItem(value: 'training', child: Text('Training')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _selectedSharedMethod = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sharedNotesController,
                        decoration: const InputDecoration(labelText: 'Shared Notes', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                    ],
                  ]),
                  _buildSection('Training', [
                    SwitchListTile(
                      title: const Text('Training Required'),
                      subtitle: const Text('Does this lesson require training?'),
                      value: _isTrainingRequired,
                      onChanged: (v) => setState(() => _isTrainingRequired = v),
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
    _sourceReferenceController.dispose();
    _rootCauseController.dispose();
    _keyLearningController.dispose();
    _recommendationsController.dispose();
    _changesMadeController.dispose();
    _implementationNotesController.dispose();
    _reviewNotesController.dispose();
    _sharedNotesController.dispose();
    super.dispose();
  }
}