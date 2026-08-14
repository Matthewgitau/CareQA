import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/training_record.dart';
import '../../services/training_service.dart';
import '../../services/auth_service.dart';

class TrainingScreen extends StatefulWidget {
  final String serviceUserId;

  const TrainingScreen({Key? key, required this.serviceUserId}) : super(key: key);

  @override
  _TrainingScreenState createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TrainingService _trainingService;
  late AuthService _authService;
  List<TrainingRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _trainingService = TrainingService(Supabase.instance.client);
    _authService = AuthService();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      _records = await _trainingService.getForServiceUser(widget.serviceUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load records: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Record'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'History'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewRecordTab(),
          _buildHistoryTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildNewRecordTab() {
    return NewTrainingRecord(
      serviceUserId: widget.serviceUserId,
      onRecordCreated: () {
        _loadRecords();
        _tabController.index = 1; // Switch to history tab
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return const Center(child: Text('No training records found'));
    }

    return ListView.builder(
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(DateFormat('dd/MM/yyyy').format(record.assessmentDate)),
            subtitle: Text('Status: ${record.status}'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainingDetailScreen(record: record),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    return const Center(child: Text('Summary coming soon'));
  }
}

class NewTrainingRecord extends StatefulWidget {
  final String serviceUserId;
  final VoidCallback onRecordCreated;

  const NewTrainingRecord({
    Key? key,
    required this.serviceUserId,
    required this.onRecordCreated,
  }) : super(key: key);

  @override
  _NewTrainingRecordState createState() => _NewTrainingRecordState();
}

class _NewTrainingRecordState extends State<NewTrainingRecord> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _staffNameController = TextEditingController();
  final _roleController = TextEditingController();
  final _startDateController = TextEditingController();
  final _authService = AuthService();
  Map<String, dynamic> _responses = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _startDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _initializeResponses();
  }

  void _initializeResponses() {
    _responses = {
      'training_date': '',
      'staff_name': '',
      'role': '',
      'start_date': '',
      'mandatory_training': [],
      'cpd_training': [],
      'qualifications': [],
      'signature': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Training Record',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Staff Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _staffNameController,
              decoration: const InputDecoration(labelText: 'Staff Name'),
              onChanged: (value) {
                _responses['staff_name'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Role'),
              onChanged: (value) {
                _responses['role'] = value;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        _startDateController.text = DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                    onChanged: (value) {
                      _responses['start_date'] = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Record Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Mandatory Training',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TrainingEntriesWidget(
              title: 'Mandatory Training',
              entries: _responses['mandatory_training'],
              onEntriesChanged: (entries) {
                _responses['mandatory_training'] = entries;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'CPD Training',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TrainingEntriesWidget(
              title: 'CPD Training',
              entries: _responses['cpd_training'],
              onEntriesChanged: (entries) {
                _responses['cpd_training'] = entries;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Qualifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            QualificationsWidget(
              qualifications: _responses['qualifications'],
              onQualificationsChanged: (qualifications) {
                _responses['qualifications'] = qualifications;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Signature',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Staff Signature'),
              onChanged: (value) {
                _responses['signature'] = value;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveRecord,
                    child: const Text('Save Training Record'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      final record = TrainingRecord(
        serviceUserId: widget.serviceUserId,
        assessorId: user.id,
        assessmentDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        responses: _responses,
      );

      await _trainingService.create(record);
      widget.onRecordCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training record saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save record: $e')),
      );
    }
  }
}

class TrainingEntriesWidget extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> entries;
  final Function(List<Map<String, dynamic>>) onEntriesChanged;

  const TrainingEntriesWidget({
    Key? key,
    required this.title,
    required this.entries,
    required this.onEntriesChanged,
  }) : super(key: key);

  @override
  _TrainingEntriesWidgetState createState() => _TrainingEntriesWidgetState();
}

class _TrainingEntriesWidgetState extends State<TrainingEntriesWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.entries.asMap().entries.map((entry) {
          final index = entry.key;
          final training = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.title} Entry ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Training Name'),
                    initialValue: training['training_name'] ?? '',
                    onChanged: (value) {
                      widget.entries[index]['training_name'] = value;
                      widget.onEntriesChanged(widget.entries);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Completed Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              widget.entries[index]['completed_date'] = DateFormat('dd/MM/yyyy').format(date);
                              widget.onEntriesChanged(widget.entries);
                            }
                          },
                          initialValue: training['completed_date'] ?? '',
                          onChanged: (value) {
                            widget.entries[index]['completed_date'] = value;
                            widget.onEntriesChanged(widget.entries);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              widget.entries[index]['expiry_date'] = DateFormat('dd/MM/yyyy').format(date);
                              widget.onEntriesChanged(widget.entries);
                            }
                          },
                          initialValue: training['expiry_date'] ?? '',
                          onChanged: (value) {
                            widget.entries[index]['expiry_date'] = value;
                            widget.onEntriesChanged(widget.entries);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Provider'),
                    initialValue: training['provider'] ?? '',
                    onChanged: (value) {
                      widget.entries[index]['provider'] = value;
                      widget.onEntriesChanged(widget.entries);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: training['method'],
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: [
                      DropdownMenuItem(value: 'face_to_face', child: Text('Face-to-face')),
                      DropdownMenuItem(value: 'online', child: Text('Online')),
                      DropdownMenuItem(value: 'practical', child: Text('Practical')),
                      DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
                      DropdownMenuItem(value: 'blended', child: Text('Blended')),
                    ],
                    onChanged: (value) {
                      widget.entries[index]['method'] = value;
                      widget.onEntriesChanged(widget.entries);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: training['outcome'],
                    decoration: const InputDecoration(labelText: 'Outcome'),
                    items: [
                      DropdownMenuItem(value: 'pass', child: Text('Pass')),
                      DropdownMenuItem(value: 'fail', child: Text('Fail')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    ],
                    onChanged: (value) {
                      widget.entries[index]['outcome'] = value;
                      widget.onEntriesChanged(widget.entries);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Certificate Reference'),
                    initialValue: training['certificate_reference'] ?? '',
                    onChanged: (value) {
                      widget.entries[index]['certificate_reference'] = value;
                      widget.onEntriesChanged(widget.entries);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _removeEntry(index),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add Training Entry'),
        ),
      ],
    );
  }

  void _addEntry() {
    setState(() {
      widget.entries.add({
        'training_name': '',
        'completed_date': '',
        'expiry_date': '',
        'provider': '',
        'method': '',
        'outcome': '',
        'certificate_reference': '',
      });
      widget.onEntriesChanged(widget.entries);
    });
  }

  void _removeEntry(int index) {
    setState(() {
      widget.entries.removeAt(index);
      widget.onEntriesChanged(widget.entries);
    });
  }
}

class QualificationsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> qualifications;
  final Function(List<Map<String, dynamic>>) onQualificationsChanged;

  const QualificationsWidget({
    Key? key,
    required this.qualifications,
    required this.onQualificationsChanged,
  }) : super(key: key);

  @override
  _QualificationsWidgetState createState() => _QualificationsWidgetState();
}

class _QualificationsWidgetState extends State<QualificationsWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.qualifications.asMap().entries.map((entry) {
          final index = entry.key;
          final qualification = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qualification ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Qualification Name'),
                    initialValue: qualification['qualification_name'] ?? '',
                    onChanged: (value) {
                      widget.qualifications[index]['qualification_name'] = value;
                      widget.onQualificationsChanged(widget.qualifications);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Awarding Body'),
                    initialValue: qualification['awarding_body'] ?? '',
                    onChanged: (value) {
                      widget.qualifications[index]['awarding_body'] = value;
                      widget.onQualificationsChanged(widget.qualifications);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date Achieved',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        widget.qualifications[index]['date_achieved'] = DateFormat('dd/MM/yyyy').format(date);
                        widget.onQualificationsChanged(widget.qualifications);
                      }
                    },
                    initialValue: qualification['date_achieved'] ?? '',
                    onChanged: (value) {
                      widget.qualifications[index]['date_achieved'] = value;
                      widget.onQualificationsChanged(widget.qualifications);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Certificate Reference'),
                    initialValue: qualification['certificate_reference'] ?? '',
                    onChanged: (value) {
                      widget.qualifications[index]['certificate_reference'] = value;
                      widget.onQualificationsChanged(widget.qualifications);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _removeQualification(index),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addQualification,
          icon: const Icon(Icons.add),
          label: const Text('Add Qualification'),
        ),
      ],
    );
  }

  void _addQualification() {
    setState(() {
      widget.qualifications.add({
        'qualification_name': '',
        'awarding_body': '',
        'date_achieved': '',
        'certificate_reference': '',
      });
      widget.onQualificationsChanged(widget.qualifications);
    });
  }

  void _removeQualification(int index) {
    setState(() {
      widget.qualifications.removeAt(index);
      widget.onQualificationsChanged(widget.qualifications);
    });
  }
}

class TrainingDetailScreen extends StatelessWidget {
  final TrainingRecord record;

  const TrainingDetailScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Training Record - ${DateFormat('dd/MM/yyyy').format(record.assessmentDate)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${record.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildRecordDetails(),
            const SizedBox(height: 16),
            _buildActionPlan(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Staff Information',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Staff: ${record.responses['staff_name'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Role: ${record.responses['role'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Start Date: ${record.responses['start_date'] ?? ''}'),
            const SizedBox(height: 16),
            Text(
              'Mandatory Training',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildTrainingEntries(record.responses['mandatory_training'] ?? []),
            const SizedBox(height: 16),
            Text(
              'CPD Training',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildTrainingEntries(record.responses['cpd_training'] ?? []),
            const SizedBox(height: 16),
            Text(
              'Qualifications',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildQualifications(record.responses['qualifications'] ?? []),
            const SizedBox(height: 8),
            Text(
              'Staff Signature: ${record.responses['signature'] ?? ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTrainingEntries(List<dynamic> entries) {
    return entries.map((entry) {
      final training = entry as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${training['training_name'] ?? ''}'),
            Text('  Completed: ${training['completed_date'] ?? ''}'),
            Text('  Expiry: ${training['expiry_date'] ?? ''}'),
            Text('  Provider: ${training['provider'] ?? ''}'),
            Text('  Method: ${training['method'] ?? ''}'),
            Text('  Outcome: ${training['outcome'] ?? ''}'),
            Text('  Certificate: ${training['certificate_reference'] ?? ''}'),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildQualifications(List<dynamic> qualifications) {
    return qualifications.map((qual) {
      final qualification = qual as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${qualification['qualification_name'] ?? ''}'),
            Text('  Awarding Body: ${qualification['awarding_body'] ?? ''}'),
            Text('  Date Achieved: ${qualification['date_achieved'] ?? ''}'),
            Text('  Certificate: ${qualification['certificate_reference'] ?? ''}'),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildActionPlan() {
    if (record.actionPlan.isEmpty) {
      return const Text('No action plan items');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agreed Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...record.actionPlan.map((item) => Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What: ${item['what'] ?? ''}'),
                      Text('Who: ${item['who'] ?? ''}'),
                      Text('By When: ${item['by_when'] ?? ''}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}