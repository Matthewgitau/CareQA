import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/services/sleep_service.dart';
import 'package:staff_app/models/sleep_chart.dart';

class SleepForm extends StatefulWidget {
  final String serviceUserId;
  final String carerId;

  const SleepForm({
    Key? key,
    required this.serviceUserId,
    required this.carerId,
  }) : super(key: key);

  @override
  _SleepFormState createState() => _SleepFormState();
}

class _SleepFormState extends State<SleepForm> {
  final _formKey = GlobalKey<FormState>();
  final _sleepService = SleepService(Supabase.instance.client);
  
  DateTime _chartDate = DateTime.now();
  TimeOfDay? _bedtimeTime;
  String _bedtimeRoutine = '';
  List<OvernightObservation> _overnightEntries = [];
  String? _sleepQuality;
  String _morningNotes = '';

  @override
  void initState() {
    super.initState();
    // Add one empty entry by default
    _addEntry();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addEntry() {
    setState(() {
      _overnightEntries.add(OvernightObservation(
        time: DateTime.now(),
        status: 'Asleep',
        notes: '',
      ));
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _overnightEntries.removeAt(index);
    });
  }

  void _updateEntry(int index, OvernightObservation entry) {
    setState(() {
      _overnightEntries[index] = entry;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _chartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _chartDate) {
      setState(() {
        _chartDate = picked;
      });
    }
  }

  Future<void> _selectBedtimeTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _bedtimeTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _bedtimeTime = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_overnightEntries[index].time),
    );
    if (picked != null) {
      setState(() {
        _overnightEntries[index] = _overnightEntries[index].copyWith(
          time: DateTime(
            _chartDate.year,
            _chartDate.month,
            _chartDate.day,
            picked.hour,
            picked.minute,
          ),
        );
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final chart = SleepChart(
        serviceUserId: widget.serviceUserId,
        chartDate: _chartDate,
        bedtimeTime: _bedtimeTime,
        bedtimeRoutine: _bedtimeRoutine,
        overnightEntries: _overnightEntries,
        sleepQuality: _sleepQuality,
        morningNotes: _morningNotes,
      );

      await _sleepService.createChart(chart, widget.carerId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep chart created successfully')),
      );
      
      Navigator.pop(context, true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating chart: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Chart'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Date:'),
                    const SizedBox(width: 16),
                    Text(
                      '${_chartDate.day}/${_chartDate.month}/${_chartDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
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
                          _bedtimeTime != null 
                            ? '${_bedtimeTime!.hour.toString().padLeft(2, '0')}:${_bedtimeTime!.minute.toString().padLeft(2, '0')}'
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
                      initialValue: _bedtimeRoutine,
                      decoration: const InputDecoration(
                        labelText: 'Bedtime Routine',
                        hintText: 'Describe the bedtime routine...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        _bedtimeRoutine = value;
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

            if (_overnightEntries.isEmpty)
              const Text('No observations added yet. Tap "Add Observation" to begin.'),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _overnightEntries.length,
              itemBuilder: (context, index) {
                final entry = _overnightEntries[index];
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
                      value: _sleepQuality,
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
                          _sleepQuality = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Morning notes
                    TextFormField(
                      initialValue: _morningNotes,
                      decoration: const InputDecoration(
                        labelText: 'Morning Notes',
                        hintText: 'How did they wake up? Any observations...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      onChanged: (value) {
                        _morningNotes = value;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Create Chart'),
              ),
            ),
          ],
        ),
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