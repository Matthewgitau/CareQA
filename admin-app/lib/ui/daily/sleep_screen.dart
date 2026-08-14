import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/sleep_service.dart';
import 'package:admin_app/models/sleep_chart.dart';
import 'package:admin_app/ui/daily/sleep_audit.dart';

class SleepScreen extends StatefulWidget {
  final String serviceUserId;
  final String? serviceUserName;

  const SleepScreen({
    Key? key,
    required this.serviceUserId,
    this.serviceUserName,
  }) : super(key: key);

  @override
  _SleepScreenState createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> with SingleTickerProviderStateMixin {
  final _sleepService = SleepService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  
  late TabController _tabController;
  List<SleepChartSummary> _chartSummaries = [];
  SleepChart? _currentChart;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCharts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCharts() async {
    setState(() => _isLoading = true);
    try {
      _chartSummaries = await _sleepService.getChartSummariesForServiceUser(widget.serviceUserId);
      if (_chartSummaries.isNotEmpty) {
        _currentChart = await _sleepService.getChart(_chartSummaries.first.id);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading charts: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectChart(String chartId) async {
    setState(() => _isLoading = true);
    try {
      _currentChart = await _sleepService.getChart(chartId);
      _tabController.index = 1; // Switch to edit tab
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chart: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChart() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final updates = {
        'bedtime_time': _currentChart!.bedtimeTime != null 
          ? '${_currentChart!.bedtimeTime!.hour.toString().padLeft(2, '0')}:${_currentChart!.bedtimeTime!.minute.toString().padLeft(2, '0')}'
          : null,
        'bedtime_routine': _currentChart!.bedtimeRoutine,
        'overnight_entries': _currentChart!.overnightEntries.map((e) => e.toJson()).toList(),
        'sleep_quality': _currentChart!.sleepQuality,
        'morning_notes': _currentChart!.morningNotes,
      };

      await _sleepService.updateChart(_currentChart!.id!, updates, Supabase.instance.client.auth.currentUser!.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chart updated successfully')),
      );
      
      _isEditing = false;
      _tabController.index = 0; // Switch back to list tab
      await _loadCharts();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating chart: $error')),
      );
    }
  }

  Future<void> _deleteChart() async {
    if (_currentChart == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chart'),
        content: const Text('Are you sure you want to delete this chart? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _sleepService.deleteChart(_currentChart!.id!, Supabase.instance.client.auth.currentUser!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chart deleted successfully')),
        );
        _currentChart = null;
        _isEditing = false;
        _tabController.index = 0;
        await _loadCharts();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting chart: $error')),
        );
      }
    }
  }

  void _addEntry() {
    setState(() {
      _currentChart = _currentChart!.copyWith(
        overnightEntries: [
          ..._currentChart!.overnightEntries,
          OvernightObservation(
            time: DateTime.now(),
            status: 'Asleep',
            notes: '',
          ),
        ],
      );
    });
  }

  void _removeEntry(int index) {
    setState(() {
      final entries = List<OvernightObservation>.from(_currentChart!.overnightEntries);
      entries.removeAt(index);
      _currentChart = _currentChart!.copyWith(overnightEntries: entries);
    });
  }

  void _updateEntry(int index, OvernightObservation entry) {
    setState(() {
      final entries = List<OvernightObservation>.from(_currentChart!.overnightEntries);
      entries[index] = entry;
      _currentChart = _currentChart!.copyWith(overnightEntries: entries);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentChart!.chartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _currentChart = _currentChart!.copyWith(chartDate: picked);
      });
    }
  }

  Future<void> _selectBedtimeTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _currentChart!.bedtimeTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _currentChart = _currentChart!.copyWith(bedtimeTime: picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_currentChart!.overnightEntries[index].time),
    );
    if (picked != null) {
      setState(() {
        final entries = List<OvernightObservation>.from(_currentChart!.overnightEntries);
        entries[index] = entries[index].copyWith(
          time: DateTime(
            _currentChart!.chartDate.year,
            _currentChart!.chartDate.month,
            _currentChart!.chartDate.day,
            picked.hour,
            picked.minute,
          ),
        );
        _currentChart = _currentChart!.copyWith(overnightEntries: entries);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sleep Charts - ${widget.serviceUserName ?? 'Service User'}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'View Charts'),
            Tab(text: 'Edit Chart'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: View Charts
                _buildViewTab(),
                // Tab 2: Edit Chart
                _buildEditTab(),
              ],
            ),
    );
  }

  Widget _buildViewTab() {
    if (_chartSummaries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No sleep charts found', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Create a new chart to get started'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCharts,
      child: ListView.builder(
        itemCount: _chartSummaries.length,
        itemBuilder: (context, index) {
          final summary = _chartSummaries[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: summary.sleepQuality != null
                  ? Icon(
                      Icons.bedtime,
                      color: _getSleepQualityColor(summary.sleepQuality!),
                    )
                  : Icon(Icons.bedtime, color: Colors.grey),
              title: Text(
                '${summary.chartDate.day}/${summary.chartDate.month}/${summary.chartDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summary.sleepQuality != null)
                    Text('Sleep Quality: ${summary.sleepQuality}'),
                  if (summary.hasDistressingObservations)
                    const Text('⚠️ Distressing observations detected', style: TextStyle(color: Colors.red)),
                  if (summary.createdBy != null)
                    Text('Created by: ${summary.createdBy}'),
                  if (summary.updatedBy != null && summary.updatedBy != summary.createdBy)
                    Text('Last edited by: ${summary.updatedBy}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectChart(summary.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditTab() {
    if (_currentChart == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.select_all, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a chart to edit', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Go to the View Charts tab and tap a chart'),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Chart header with metadata
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Chart Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentChart!.chartDate.day}/${_currentChart!.chartDate.month}/${_currentChart!.chartDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_currentChart!.createdBy != null)
                    Text('Created by: ${_currentChart!.createdBy}'),
                  if (_currentChart!.createdAt != null)
                    Text('Created: ${_currentChart!.createdAt!.toLocal().formatDate()}'),
                  if (_currentChart!.updatedBy != null && _currentChart!.updatedBy != _currentChart!.createdBy)
                    Text('Last edited by: ${_currentChart!.updatedBy}'),
                  if (_currentChart!.updatedAt != null && _currentChart!.updatedAt != _currentChart!.createdAt)
                    Text('Last edited: ${_currentChart!.updatedAt!.toLocal().formatDate()}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bedtime Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bedtime Section',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // Bedtime time
                  Row(
                    children: [
                      const Text('Bedtime:'),
                      const SizedBox(width: 16),
                      Text(
                        _currentChart!.bedtimeTime != null 
                          ? '${_currentChart!.bedtimeTime!.hour.toString().padLeft(2, '0')}:${_currentChart!.bedtimeTime!.minute.toString().padLeft(2, '0')}'
                          : 'Not set',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () => _selectBedtimeTime(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bedtime routine
                  TextFormField(
                    initialValue: _currentChart!.bedtimeRoutine,
                    decoration: const InputDecoration(
                      labelText: 'Bedtime Routine',
                      hintText: 'Describe the bedtime routine...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      _currentChart = _currentChart!.copyWith(bedtimeRoutine: value);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Overnight Observations
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overnight Observation Types',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildObservationTypeRow('Asleep', 'Resting peacefully', Colors.green),
                  _buildObservationTypeRow('Awake-settled', 'Awake but calm', Colors.blue),
                  _buildObservationTypeRow('Awake-disturbed', 'Agitated or restless', Colors.orange),
                  _buildObservationTypeRow('Up-toilet', 'Used bathroom', Colors.purple),
                  _buildObservationTypeRow('Repositioned', 'Repositioned in bed', Colors.teal),
                  _buildObservationTypeRow('Distressed', 'In distress', Colors.red),
                  _buildObservationTypeRow('Confused-wandering', 'Wandering, confused', Colors.orange),
                  _buildObservationTypeRow('Pain reported', 'Complained of pain', Colors.red),
                  _buildObservationTypeRow('Fall', 'Had a fall', Colors.red),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Overnight Observations Entries
          const Text(
            'Overnight Observations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),

          if (_currentChart!.overnightEntries.isEmpty)
            const Text('No observations added yet.'),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentChart!.overnightEntries.length,
            itemBuilder: (context, index) {
              final entry = _currentChart!.overnightEntries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Observation ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeEntry(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Time picker
                      Row(
                        children: [
                          const Text('Time:'),
                          const SizedBox(width: 16),
                          Text(
                            '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _selectTime(context, index),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Observation status
                      DropdownButtonFormField<String>(
                        value: entry.status,
                        decoration: const InputDecoration(
                          labelText: 'Observation Status',
                        ),
                        items: SleepConstants.observationTypes.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  entry.getStatusIcon(),
                                  color: SleepConstants.observationColors[status],
                                ),
                                const SizedBox(width: 8),
                                Text(status),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _updateEntry(index, entry.copyWith(status: value!));
                        },
                      ),

                      const SizedBox(height: 8),

                      // Notes
                      TextFormField(
                        initialValue: entry.notes,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Additional observations...',
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          _updateEntry(index, entry.copyWith(notes: value));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Add observation button
          ElevatedButton.icon(
            onPressed: _addEntry,
            icon: const Icon(Icons.add),
            label: const Text('Add Observation'),
          ),

          const SizedBox(height: 16),

          // Morning Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Morning Section',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // Sleep quality
                  DropdownButtonFormField<String>(
                    value: _currentChart!.sleepQuality,
                    decoration: const InputDecoration(
                      labelText: 'Sleep Quality',
                    ),
                    items: SleepConstants.sleepQualityOptions.map((quality) {
                      return DropdownMenuItem(
                        value: quality,
                        child: Row(
                          children: [
                            Icon(
                              Icons.bedtime,
                              color: _getSleepQualityColor(quality),
                            ),
                            const SizedBox(width: 8),
                            Text(quality),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _currentChart = _currentChart!.copyWith(sleepQuality: value);
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Morning notes
                  TextFormField(
                    initialValue: _currentChart!.morningNotes,
                    decoration: const InputDecoration(
                      labelText: 'Morning Notes',
                      hintText: 'How did they wake up? Any observations...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    onChanged: (value) {
                      _currentChart = _currentChart!.copyWith(morningNotes: value);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChart,
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _tabController.index = 0;
                    _isEditing = false;
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SleepAuditScreen(chartId: _currentChart!.id!),
                    ),
                  ),
                  child: const Text('View Audit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleteChart,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObservationTypeRow(String status, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text('-'),
          const SizedBox(width: 8),
          Text(description),
        ],
      ),
    );
  }

  Color _getSleepQualityColor(String quality) {
    switch (quality) {
      case 'Good':
        return Colors.green;
      case 'Fair':
        return Colors.yellow;
      case 'Poor':
        return Colors.orange;
      case 'Very Poor':
      case 'Unsettled throughout':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Asleep':
        return Icons.bedtime;
      case 'Awake-settled':
        return Icons.accessibility;
      case 'Awake-disturbed':
        return Icons.accessibility_new;
      case 'Up-toilet':
        return Icons.bathtub;
      case 'Repositioned':
        return Icons.rotate_left;
      case 'Distressed':
        return Icons.warning;
      case 'Confused-wandering':
        return Icons.directions_walk;
      case 'Pain reported':
        return Icons.health_and_safety;
      case 'Fall':
        return Icons.warning_amber;
      default:
        return Icons.circle;
    }
  }
}

// Extension for date formatting
extension DateTimeExtensions on DateTime {
  String formatDate() {
    return '${day}/${month}/${year} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

// Extension to make SleepChart mutable
extension SleepChartExtensions on SleepChart {
  SleepChart copyWith({
    DateTime? chartDate,
    TimeOfDay? bedtimeTime,
    String? bedtimeRoutine,
    List<OvernightObservation>? overnightEntries,
    String? sleepQuality,
    String? morningNotes,
  }) {
    return SleepChart(
      id: id,
      serviceUserId: serviceUserId,
      chartDate: chartDate ?? this.chartDate,
      bedtimeTime: bedtimeTime ?? this.bedtimeTime,
      bedtimeRoutine: bedtimeRoutine ?? this.bedtimeRoutine,
      overnightEntries: overnightEntries ?? this.overnightEntries,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      morningNotes: morningNotes ?? this.morningNotes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
    );
  }
}

// Extension to make OvernightObservation mutable
extension OvernightObservationExtensions on OvernightObservation {
  OvernightObservation copyWith({
    DateTime? time,
    String? status,
    String? notes,
  }) {
    return OvernightObservation(
      time: time ?? this.time,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}