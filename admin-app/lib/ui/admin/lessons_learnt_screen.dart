import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LessonsLearntScreen extends StatefulWidget {
  const LessonsLearntScreen({super.key});

  @override
  State<LessonsLearntScreen> createState() => _LessonsLearntScreenState();
}

class _LessonsLearntScreenState extends State<LessonsLearntScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _lessonsFuture;
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'medication',
    'falls',
    'infection',
    'safeguarding',
    'equipment',
    'communication',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _loadLessons();
  }

  Future<List<Map<String, dynamic>>> _loadLessons() async {
    var query = _supabase.from('lessons_learnt').select('''
      *,
      creator:created_by(name, email)
    ''').order('created_at', ascending: false);

    final response = await query;
    var lessons = List<Map<String, dynamic>>.from(response);

    if (_selectedCategory != 'all') {
      lessons = lessons.where((l) => l['incident_type'] == _selectedCategory).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      lessons = lessons.where((l) =>
        (l['title'] ?? '').toLowerCase().contains(search) ||
        (l['description'] ?? '').toLowerCase().contains(search) ||
        (l['incident_type'] ?? '').toLowerCase().contains(search)
      ).toList();
    }

    return lessons;
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'medication':
        return Colors.red;
      case 'falls':
        return Colors.orange;
      case 'infection':
        return Colors.purple;
      case 'safeguarding':
        return Colors.redAccent;
      case 'equipment':
        return Colors.blue;
      case 'communication':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showLessonForm({Map<String, dynamic>? lesson}) async {
    await showDialog(
      context: context,
      builder: (context) => _LessonFormDialog(lesson: lesson),
    );
    setState(() {
      _lessonsFuture = _loadLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons Learnt'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
                _lessonsFuture = _loadLessons();
              });
            },
            itemBuilder: (context) => _categories.map((c) {
              String display = c == 'all' ? 'All Categories' : c[0].toUpperCase() + c.substring(1);
              return PopupMenuItem(value: c, child: Text(display));
            }).toList(),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search lessons',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {
                _lessonsFuture = _loadLessons();
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _lessonsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No lessons learnt found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text('Document your first lesson from an incident', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final lessons = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () => _loadLessons(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            lesson['title'] ?? 'Untitled',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                lesson['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(lesson['incident_type']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (lesson['incident_type'] ?? 'other')[0].toUpperCase() +
                                          (lesson['incident_type'] ?? 'other').substring(1),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Created: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(lesson['created_at']))}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _showLessonForm(lesson: lesson),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLessonForm(),
        tooltip: 'Add Lesson',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LessonFormDialog extends StatefulWidget {
  final Map<String, dynamic>? lesson;

  const _LessonFormDialog({this.lesson});

  @override
  State<_LessonFormDialog> createState() => _LessonFormDialogState();
}

class _LessonFormDialogState extends State<_LessonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rootCauseController = TextEditingController();
  final _actionTakenController = TextEditingController();
  final _preventionMeasuresController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'medication',
    'falls',
    'infection',
    'safeguarding',
    'equipment',
    'communication',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _titleController.text = widget.lesson!['title'] ?? '';
      _descriptionController.text = widget.lesson!['description'] ?? '';
      _rootCauseController.text = widget.lesson!['root_cause'] ?? '';
      _actionTakenController.text = widget.lesson!['action_taken'] ?? '';
      _preventionMeasuresController.text = widget.lesson!['prevention_measures'] ?? '';
      _selectedCategory = widget.lesson!['incident_type'];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'incident_type': _selectedCategory,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'root_cause': _rootCauseController.text,
        'action_taken': _actionTakenController.text,
        'prevention_measures': _preventionMeasuresController.text,
      };

      if (widget.lesson != null) {
        await Supabase.instance.client.from('lessons_learnt').update(data).eq('id', widget.lesson!['id']);
      } else {
        await Supabase.instance.client.from('lessons_learnt').insert(data);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rootCauseController.dispose();
    _actionTakenController.dispose();
    _preventionMeasuresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.lesson != null ? 'Edit Lesson' : 'New Lesson Learnt'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) {
                  String display = c[0].toUpperCase() + c.substring(1);
                  return DropdownMenuItem(value: c, child: Text(display));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rootCauseController,
                decoration: const InputDecoration(labelText: 'Root Cause', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _actionTakenController,
                decoration: const InputDecoration(labelText: 'Action Taken', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _preventionMeasuresController,
                decoration: const InputDecoration(labelText: 'Prevention Measures', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}