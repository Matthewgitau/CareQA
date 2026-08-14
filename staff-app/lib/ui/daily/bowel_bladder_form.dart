import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/services/bowel_bladder_service.dart';
import 'package:staff_app/models/bowel_bladder_chart.dart';

class BowelBladderForm extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const BowelBladderForm({
    super.key,
    required this.serviceUserId,
    required this.serviceUserName,
  });

  @override
  State<BowelBladderForm> createState() => _BowelBladderFormState();
}

class _BowelBladderFormState extends State<BowelBladderForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<BowelEntry> _bowelEntries = [];
  List<BladderEntry> _bladderEntries = [];
  int _daysSinceLastBowel = 0;
  bool _warningTriggered = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousData();
  }

  Future<void> _loadPreviousData() async {
    setState(() => _isLoading = true);
    try {
      final bowelBladderService = Provider.of<BowelBladderService>(context, listen: false);
      final charts = await bowelBladderService.getChartsForServiceUser(widget.serviceUserId);
      
      if (charts.isNotEmpty) {
        final latestChart = charts.first;
        _daysSinceLastBowel = latestChart.daysSinceLastBowel + 1;
        _warningTriggered = _daysSinceLastBowel > 3;
      }
    } catch (e) {
      // Ignore errors for loading previous data
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addBowelEntry() {
    setState(() {
      _bowelEntries.add(BowelEntry(
        time: DateTime.now(),
        bristolStoolType: 4, // Default to normal
        consistency: 'Smooth',
        colour: 'Brown',
        amount: 'Medium',
      ));
    });
  }

  void _removeBowelEntry(int index) {
    setState(() {
      _bowelEntries.removeAt(index);
    });
  }

  void _addBladderEntry() {
    setState(() {
      _bladderEntries.add(BladderEntry(
        time: DateTime.now(),
        urineColour: 'Pale Yellow',
        volumeMl: 200,
        incontinence: false,
      ));
    });
  }

  void _removeBladderEntry(int index) {
    setState(() {
      _bladderEntries.removeAt(index);
    });
  }

  void _updateBowelEntry(int index, BowelEntry updatedEntry) {
    setState(() {
      _bowelEntries[index] = updatedEntry;
    });
  }

  void _updateBladderEntry(int index, BladderEntry updatedEntry) {
    setState(() {
      _bladderEntries[index] = updatedEntry;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final bowelBladderService = Provider.of<BowelBladderService>(context, listen: false);
      final chart = BowelBladderChart(
        serviceUserId: widget.serviceUserId,
        chartDate: _selectedDate,
        bowelEntries: _bowelEntries,
        bladderEntries: _bladderEntries,
        daysSinceLastBowel: _daysSinceLastBowel,
        warningTriggered: _warningTriggered,
        notes: _notesController.text.trim(),
      );

      await bowelBladderService.createChart(chart, ''); // Would come from auth context
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bowel & Bladder chart created successfully')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating chart: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bowel & Bladder Chart - ${widget.serviceUserName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Picker
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chart Date',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () => _selectDate(context),
                                  child: const Text('Change Date'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bristol Stool Scale Reference
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bristol Stool Scale Reference',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            _buildBristolScaleReference(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Warning Indicator
                    if (_warningTriggered)
                      Card(
                        color: Colors.red[50],
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[800]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'WARNING: ${_daysSinceLastBowel} days since last bowel movement. Monitor closely for constipation.',
                                  style: TextStyle(
                                    color: Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Bowel Entries
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Bowel Entries',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: _addBowelEntry,
                                  child: const Text('+ Add Entry'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_bowelEntries.isEmpty)
                              const Center(
                                child: Text(
                                  'No bowel entries yet. Tap "Add Entry" to add one.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _bowelEntries.length,
                              itemBuilder: (context, index) => _buildBowelEntryCard(index),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bladder Entries
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Bladder Entries',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: _addBladderEntry,
                                  child: const Text('+ Add Entry'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_bladderEntries.isEmpty)
                              const Center(
                                child: Text(
                                  'No bladder entries yet. Tap "Add Entry" to add one.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _bladderEntries.length,
                              itemBuilder: (context, index) => _buildBladderEntryCard(index),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Summary',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text('Bowel entries: ${_bowelEntries.length}'),
                            Text('Bladder entries: ${_bladderEntries.length}'),
                            Text('Total bladder volume: ${_bladderEntries.fold(0, (sum, entry) => sum + entry.volumeMl)} ml'),
                            Text('Days since last bowel: $_daysSinceLastBowel'),
                            if (_bladderEntries.any((e) => e.incontinence))
                              Text('Incontinence events: Yes', style: const TextStyle(color: Colors.orange)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Additional observations, concerns, or notes...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Submit Chart',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBristolScaleReference() {
    return Column(
      children: BristolStoolScale.descriptions.entries.map((entry) {
      final color = _getBristolColor(entry.key);
      return Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Type ${entry.key}: ${entry.value}',
              style: TextStyle(color: color),
            ),
          ),
        ],
      );
    }).toList(),
    );
  }

  Color _getBristolColor(int type) {
    switch (type) {
      case 1:
      case 2:
        return Colors.red; // Constipation
      case 3:
      case 4:
        return Colors.green; // Normal
      case 5:
      case 6:
      case 7:
        return Colors.orange; // Diarrhea
      default:
        return Colors.grey;
    }
  }

  Widget _buildBowelEntryCard(int index) {
    final entry = _bowelEntries[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bowel Entry ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeBowelEntry(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Time
            Row(
              children: [
                const Text('Time:'),
                const SizedBox(width: 8),
                Text(entry.time.formatTime()),
              ],
            ),
            
            // Bristol Stool Type
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Bristol Type:'),
                const SizedBox(width: 8),
                Text('${entry.bristolStoolType} - ${entry.getBristolDescription()}'),
              ],
            ),
            
            // Consistency
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Consistency:'),
                const SizedBox(width: 8),
                Text(entry.consistency),
              ],
            ),
            
            // Colour
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Colour:'),
                const SizedBox(width: 8),
                Text(entry.colour),
              ],
            ),
            
            // Amount
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Amount:'),
                const SizedBox(width: 8),
                Text(entry.amount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBladderEntryCard(int index) {
    final entry = _bladderEntries[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bladder Entry ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeBladderEntry(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Time
            Row(
              children: [
                const Text('Time:'),
                const SizedBox(width: 8),
                Text(entry.time.formatTime()),
              ],
            ),
            
            // Urine Colour
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Urine Colour:'),
                const SizedBox(width: 8),
                Text(entry.urineColour),
              ],
            ),
            
            // Volume
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Volume:'),
                const SizedBox(width: 8),
                Text('${entry.volumeMl} ml'),
              ],
            ),
            
            // Incontinence
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Incontinence:'),
                const SizedBox(width: 8),
                Text(entry.incontinence ? 'Yes' : 'No'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension TimeFormatting on DateTime {
  String formatTime() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}