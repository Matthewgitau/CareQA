import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/services/repositioning_service.dart';
import 'package:staff_app/models/repositioning_chart.dart';

class RepositioningForm extends StatefulWidget {
  final String serviceUserId;
  final String carerId;

  const RepositioningForm({
    Key? key,
    required this.serviceUserId,
    required this.carerId,
  }) : super(key: key);

  @override
  _RepositioningFormState createState() => _RepositioningFormState();
}

class _RepositioningFormState extends State<RepositioningForm> {
  final _formKey = GlobalKey<FormState>();
  final _repositioningService = RepositioningService(Supabase.instance.client);
  
  DateTime _chartDate = DateTime.now();
  List<RepositioningEntry> _entries = [];
  String _notes = '';
  String _staffInitials = '';

  @override
  void initState() {
    super.initState();
    // Add one empty entry by default
    _addEntry();
  }

  void _addEntry() {
    setState(() {
      _entries.add(RepositioningEntry(
        time: DateTime.now(),
        positionCode: 'B',
        skinCheck: 'No',
        skinCheckNotes: '',
        staffInitials: '',
      ));
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }

  void _updateEntry(int index, RepositioningEntry entry) {
    setState(() {
      _entries[index] = entry;
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

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_entries[index].time),
    );
    if (picked != null) {
      setState(() {
        _entries[index] = _entries[index].copyWith(
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

    // Validate that all entries have required fields
    for (int i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      if (entry.staffInitials.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please provide staff initials for entry ${i + 1}')),
        );
        return;
      }
      if (entry.skinCheck == 'Yes-Concern' && (entry.skinCheckNotes?.isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please provide skin check notes for entry ${i + 1} when concern is selected')),
        );
        return;
      }
    }

    try {
      final chart = RepositioningChart(
        serviceUserId: widget.serviceUserId,
        chartDate: _chartDate,
        entries: _entries,
        totalRepositions: _entries.length,
        notes: _notes,
      );

      await _repositioningService.createChart(chart, widget.carerId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repositioning chart created successfully')),
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
        title: const Text('Repositioning Chart'),
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

            // Position codes reference
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Position Codes Reference',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _buildPositionCodeRow('L', 'Left side'),
                    _buildPositionCodeRow('R', 'Right side'),
                    _buildPositionCodeRow('B', 'Back (supine)'),
                    _buildPositionCodeRow('S', 'Sitting'),
                    _buildPositionCodeRow('S30', '30° tilt left'),
                    _buildPositionCodeRow('S30R', '30° tilt right'),
                    _buildPositionCodeRow('U', 'Up in chair'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Staff initials
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Staff Initials',
                hintText: 'Enter your initials',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your initials';
                }
                return null;
              },
              onChanged: (value) {
                _staffInitials = value;
                // Update all entries with the same initials
                setState(() {
                  _entries = _entries.map((entry) => entry.copyWith(staffInitials: value)).toList();
                });
              },
            ),

            const SizedBox(height: 16),

            // Entries
            const Text(
              'Repositioning Entries',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),

            if (_entries.isEmpty)
              const Text('No entries added yet. Tap "Add Entry" to begin.'),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
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
                              'Entry ${index + 1}',
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

                        // Position code
                        DropdownButtonFormField<String>(
                          value: entry.positionCode,
                          decoration: const InputDecoration(
                            labelText: 'Position Code',
                          ),
                          items: RepositioningConstants.positionOptions.map((code) {
                            return DropdownMenuItem(
                              value: code,
                              child: Text('$code - ${RepositioningConstants.positionCodes[code]}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            _updateEntry(index, entry.copyWith(positionCode: value!));
                          },
                        ),

                        const SizedBox(height: 8),

                        // Skin check
                        DropdownButtonFormField<String>(
                          value: entry.skinCheck,
                          decoration: const InputDecoration(
                            labelText: 'Skin Check',
                          ),
                          items: RepositioningConstants.skinCheckOptions.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Row(
                                children: [
                                  Icon(
                                    option == 'Yes-NAD' ? Icons.check_circle : 
                                    option == 'Yes-Concern' ? Icons.warning : Icons.remove_circle,
                                    color: option == 'Yes-NAD' ? Colors.green :
                                           option == 'Yes-Concern' ? Colors.red : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(option),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            _updateEntry(index, entry.copyWith(skinCheck: value!));
                          },
                        ),

                        const SizedBox(height: 8),

                        // Skin check notes (only if concern)
                        if (entry.skinCheck == 'Yes-Concern')
                          TextFormField(
                            initialValue: entry.skinCheckNotes,
                            decoration: const InputDecoration(
                              labelText: 'Skin Check Notes',
                              hintText: 'Describe the concern...',
                            ),
                            maxLines: 3,
                            onChanged: (value) {
                              _updateEntry(index, entry.copyWith(skinCheckNotes: value));
                            },
                          ),

                        const SizedBox(height: 8),

                        // Staff initials for this entry
                        TextFormField(
                          initialValue: entry.staffInitials,
                          decoration: const InputDecoration(
                            labelText: 'Staff Initials (this entry)',
                          ),
                          onChanged: (value) {
                            _updateEntry(index, entry.copyWith(staffInitials: value));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Add entry button
            ElevatedButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            ),

            const SizedBox(height: 16),

            // Total repositions
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Total Repositions:'),
                    const SizedBox(width: 16),
                    Text(
                      _entries.length.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              initialValue: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional observations...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: (value) {
                _notes = value;
              },
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

  Widget _buildPositionCodeRow(String code, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(description),
        ],
      ),
    );
  }
}

// Extension to make RepositioningEntry mutable
extension RepositioningEntryExtensions on RepositioningEntry {
  RepositioningEntry copyWith({
    DateTime? time,
    String? positionCode,
    String? skinCheck,
    String? skinCheckNotes,
    String? staffInitials,
  }) {
    return RepositioningEntry(
      time: time ?? this.time,
      positionCode: positionCode ?? this.positionCode,
      skinCheck: skinCheck ?? this.skinCheck,
      skinCheckNotes: skinCheckNotes ?? this.skinCheckNotes,
      staffInitials: staffInitials ?? this.staffInitials,
    );
  }
}