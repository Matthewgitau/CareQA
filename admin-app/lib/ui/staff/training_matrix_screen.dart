import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/training_course.dart';
import '../../models/carer_training_record.dart';
import '../../models/carer_training_history.dart';
import '../../services/training_service.dart';

class TrainingMatrixScreen extends StatefulWidget {
  const TrainingMatrixScreen({super.key});

  @override
  State<TrainingMatrixScreen> createState() => _TrainingMatrixScreenState();
}

class _TrainingMatrixScreenState extends State<TrainingMatrixScreen> with SingleTickerProviderStateMixin {
  final _service = TrainingService(Supabase.instance.client);
  late TabController _tabController;

  // Tab 1: Courses
  List<TrainingCourse> _courses = [];
  bool _loadingCourses = true;

  // Tab 2: Matrix
  List<Map<String, dynamic>> _carers = [];
  List<TrainingCourse> _matrixCourses = [];
  Map<String, List<CarerTrainingRecord>> _matrixData = {}; // Changed to List to support history
  bool _loadingMatrix = true;

  // Tab 3: Add/Edit Record
  List<Map<String, dynamic>> _formCarers = [];
  List<Map<String, dynamic>> _formCourses = [];
  bool _loadingFormData = true;
  String? _selectedCarerId;
  String? _selectedCourseId;
  DateTime? _completedDate;
  DateTime? _expiryDate;
  final _notesController = TextEditingController();
  String? _certificateUrl;
  bool _isSaving = false;

  // Tab 4: History
  List<CarerTrainingHistory> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCourses();
    _loadMatrixData();
    _loadFormData();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ==================== LOADERS ====================

  Future<void> _loadCourses() async {
    setState(() => _loadingCourses = true);
    try {
      final courses = await _service.getAllCourses();
      if (mounted) setState(() => _courses = courses);
    } catch (e) {
      print('Error loading courses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load courses: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _loadMatrixData() async {
    setState(() => _loadingMatrix = true);
    try {
      final carers = await _service.getAllCarers();
      final courses = await _service.getAllCourses();
      final records = await _service.getAllRecords();

      final matrixData = <String, List<CarerTrainingRecord>>{};
      for (final record in records) {
        final key = '${record.carerId}_${record.trainingCourseId}';
        if (!matrixData.containsKey(key)) {
          matrixData[key] = [];
        }
        matrixData[key]!.add(record);
      }

      if (mounted) {
        setState(() {
          _carers = carers;
          _matrixCourses = courses;
          _matrixData = matrixData;
        });
      }
    } catch (e) {
      print('Error loading matrix: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load matrix: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMatrix = false);
    }
  }

  Future<void> _loadFormData() async {
    setState(() => _loadingFormData = true);
    try {
      final carers = await _service.getAllCarers();
      final courses = await _service.getAllCoursesForDropdown();
      if (mounted) {
        setState(() {
          _formCarers = carers;
          _formCourses = courses;
        });
      }
    } catch (e) {
      print('Error loading form data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load form data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingFormData = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final allHistory = <CarerTrainingHistory>[];
      final records = await _service.getAllRecords();
      for (final record in records) {
        final history = await _service.getHistoryForRecord(record.id);
        allHistory.addAll(history);
      }
      allHistory.sort((a, b) => b.changedAt.compareTo(a.changedAt));
      if (mounted) setState(() => _history = allHistory);
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  // ==================== ACTIONS ====================

  Future<void> _saveRecord() async {
    if (_selectedCarerId == null || _selectedCourseId == null || _completedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select carer, course, and completion date'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final course = _formCourses.firstWhere((c) => c['id'] == _selectedCourseId);
      final renewalMonths = course['default_renewal_interval_months'] ?? 12;
      final expiry = _completedDate!.add(Duration(days: (renewalMonths * 30)));

      final record = CarerTrainingRecord(
        id: '',
        carerId: _selectedCarerId!,
        trainingCourseId: _selectedCourseId!,
        completedDate: _completedDate!,
        expiryDate: _expiryDate ?? expiry,
        certificateUrl: _certificateUrl,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _service.createRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training record created'), backgroundColor: Colors.green),
        );
        _resetForm();
        _loadMatrixData();
        _loadHistory();
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

  void _resetForm() {
    setState(() {
      _selectedCarerId = null;
      _selectedCourseId = null;
      _completedDate = null;
      _expiryDate = null;
      _certificateUrl = null;
      _notesController.clear();
    });
  }

  Future<void> _pickDate(bool isCompleted) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isCompleted) {
          _completedDate = picked;
          if (_selectedCourseId != null) {
            final course = _formCourses.firstWhere((c) => c['id'] == _selectedCourseId, orElse: () => {});
            final renewalMonths = course['default_renewal_interval_months'] ?? 12;
            _expiryDate = picked.add(Duration(days: (renewalMonths * 30)));
          }
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() => _isSaving = true);

        final url = await _service.uploadCertificateFile(file, _selectedCarerId!);

        if (url != null) {
          setState(() => _certificateUrl = url);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Certificate uploaded'), backgroundColor: Colors.green),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload certificate'), backgroundColor: Colors.red),
            );
          }
        }
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

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Matrix'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Courses', icon: Icon(Icons.menu_book)),
            Tab(text: 'Matrix', icon: Icon(Icons.grid_view)),
            Tab(text: 'Add Record', icon: Icon(Icons.add_circle)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCoursesTab(),
          _buildMatrixTab(),
          _buildAddRecordTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: COURSES ====================

  Widget _buildCoursesTab() {
    if (_loadingCourses) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: _courses.isEmpty
              ? const Center(child: Text('No training courses found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(course.description ?? ''),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (course.isMandatory)
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                Text(
                                  '${course.category ?? "Uncategorized"} • Renew every ${course.defaultRenewalIntervalMonths} months',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editCourse(course),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _deleteCourse(course),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        FloatingActionButton(onPressed: _addCourse, child: const Icon(Icons.add)),
      ],
    );
  }

  Future<void> _addCourse() async {
    final result = await showDialog<TrainingCourse>(
      context: context,
      builder: (context) => const _CourseFormDialog(),
    );
    if (result != null) {
      await _service.createCourse(result);
      _loadCourses();
    }
  }

  Future<void> _editCourse(TrainingCourse course) async {
    final result = await showDialog<TrainingCourse>(
      context: context,
      builder: (context) => _CourseFormDialog(course: course),
    );
    if (result != null) {
      await _service.updateCourse(result);
      _loadCourses();
    }
  }

  Future<void> _deleteCourse(TrainingCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${course.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteCourse(course.id);
      _loadCourses();
    }
  }

  // ==================== TAB 2: MATRIX ====================

  Widget _buildMatrixTab() {
    if (_loadingMatrix) return const Center(child: CircularProgressIndicator());
    if (_carers.isEmpty || _matrixCourses.isEmpty) return const Center(child: Text('No carers or courses found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Carer', style: TextStyle(fontWeight: FontWeight.bold))),
            ..._matrixCourses.map((course) => DataColumn(
              label: Tooltip(
                message: course.name,
                child: Text(
                  course.name.length > 15 ? '${course.name.substring(0, 15)}...' : course.name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            )),
          ],
          rows: _carers.map((carer) {
            return DataRow(
              cells: [
                DataCell(Text(carer['name'] ?? 'Unknown')),
                ..._matrixCourses.map((course) {
                  final records = _matrixData['${carer['id']}_${course.id}'];
                  if (records == null || records.isEmpty) {
                    return DataCell(Icon(Icons.circle, color: Colors.grey.shade300, size: 20));
                  }
                  // Show the most recent record
                  final rec = records.first;
                  Color color;
                  if (rec.isExpired) color = Colors.red;
                  else if (rec.isExpiringSoon) color = Colors.orange;
                  else color = Colors.green;
                  return DataCell(
                    Icon(Icons.check_circle, color: color, size: 20),
                    onTap: () => _viewRecordHistory(records),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _viewRecord(CarerTrainingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.courseName ?? 'Training Record'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Carer: ${record.carerName ?? 'Unknown'}'),
              Text('Completed: ${DateFormat('dd/MM/yyyy').format(record.completedDate)}'),
              if (record.expiryDate != null)
                Text('Expires: ${DateFormat('dd/MM/yyyy').format(record.expiryDate!)}'),
              if (record.certificateUrl != null)
                Text('Certificate: ${record.certificateUrl}'),
              Text('Status: ${record.status}'),
              const SizedBox(height: 8),
              const Divider(),
              Text('Course Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Renewal: Every 12 months'),
              Text('Status: ${record.status == 'active' ? 'Active' : record.status == 'expired' ? 'Expired' : 'Revoked'}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _viewRecordHistory(List<CarerTrainingRecord> records) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Training History (${records.length} records)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${record.courseName ?? "Unknown"}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Completed: ${DateFormat('dd/MM/yyyy').format(record.completedDate)}'),
                      if (record.expiryDate != null)
                        Text('Expires: ${DateFormat('dd/MM/yyyy').format(record.expiryDate!)}'),
                      Text('Status: ${record.status}'),
                    ],
                  ),
                  trailing: Icon(
                    record.isExpired ? Icons.cancel : Icons.check_circle,
                    color: record.isExpired ? Colors.red : Colors.green,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  // ==================== TAB 3: ADD RECORD ====================

  Widget _buildAddRecordTab() {
    if (_loadingFormData) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCarerId,
              decoration: const InputDecoration(
                labelText: 'Carer *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Select a carer...')),
                ..._formCarers.map((c) => DropdownMenuItem(
                  value: c['id'] as String,
                  child: Text(c['name'] ?? 'Unknown'),
                )),
              ],
              onChanged: (v) => setState(() => _selectedCarerId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Training Course *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Select a course...')),
                ..._formCourses.map((c) => DropdownMenuItem(
                  value: c['id'] as String,
                  child: Text(c['name'] ?? 'Unknown'),
                )),
              ],
              onChanged: (v) {
                setState(() => _selectedCourseId = v);
                if (v != null && _completedDate != null) {
                  final course = _formCourses.firstWhere((c) => c['id'] == v, orElse: () => {});
                  final renewalMonths = course['default_renewal_interval_months'] ?? 12;
                  setState(() {
                    _expiryDate = _completedDate!.add(Duration(days: (renewalMonths * 30)));
                  });
                }
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () => _pickDate(true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Completion Date *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _completedDate != null ? DateFormat('dd/MM/yyyy').format(_completedDate!) : 'Select date',
                ),
              ),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () => _pickDate(false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _expiryDate != null ? DateFormat('dd/MM/yyyy').format(_expiryDate!) : 'Select date (auto-calculated)',
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Certificate upload
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickCertificate,
              icon: const Icon(Icons.upload_file),
              label: Text(_certificateUrl != null ? 'Certificate Uploaded' : 'Upload Certificate (PDF/PNG)'),
            ),
            if (_certificateUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Certificate: $_certificateUrl', style: const TextStyle(fontSize: 12, color: Colors.green)),
              ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Training Record', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 4: HISTORY ====================

  Widget _buildHistoryTab() {
    if (_loadingHistory) return const Center(child: CircularProgressIndicator());
    if (_history.isEmpty) return const Center(child: Text('No history found'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(entry.getActionDisplay()),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy HH:mm').format(entry.changedAt)}\n'
              'Changed by: ${entry.changedBy ?? 'Unknown'}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showHistoryDetail(entry),
          ),
        );
      },
    );
  }

  void _showHistoryDetail(CarerTrainingHistory entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.getActionDisplay()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Action: ${entry.getActionDisplay()}'),
              Text('Changed at: ${DateFormat('dd/MM/yyyy HH:mm').format(entry.changedAt)}'),
              if (entry.previousData != null) ...[
                const SizedBox(height: 8),
                const Text('Previous:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry.previousData.toString()),
              ],
              if (entry.newData != null) ...[
                const SizedBox(height: 8),
                const Text('New:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(entry.newData.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

// ==================== COURSE FORM DIALOG ====================

class _CourseFormDialog extends StatefulWidget {
  final TrainingCourse? course;

  const _CourseFormDialog({this.course});

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isMandatory = true;
  int _renewalInterval = 12;
  String? _category;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _nameController.text = widget.course!.name;
      _descriptionController.text = widget.course!.description ?? '';
      _isMandatory = widget.course!.isMandatory;
      _renewalInterval = widget.course!.defaultRenewalIntervalMonths;
      _category = widget.course!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final course = TrainingCourse(
      id: widget.course?.id ?? '',
      name: _nameController.text,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      isMandatory: _isMandatory,
      defaultRenewalIntervalMonths: _renewalInterval,
      category: _category,
      isActive: true,
      createdAt: widget.course?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, course);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.course != null ? 'Edit Course' : 'Add Course'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Course Name *', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Mandatory'),
                value: _isMandatory,
                onChanged: (v) => setState(() => _isMandatory = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Renewal Interval (months)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue: _renewalInterval.toString(),
                onChanged: (v) => _renewalInterval = int.tryParse(v) ?? 12,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Save'),
        ),
      ],
    );
  }
}