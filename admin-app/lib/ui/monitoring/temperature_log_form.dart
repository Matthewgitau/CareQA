import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TemperatureLogForm extends StatefulWidget {
  final String? serviceUserId;

  const TemperatureLogForm({super.key, this.serviceUserId});

  @override
  State<TemperatureLogForm> createState() => _TemperatureLogFormState();
}

class _TemperatureLogFormState extends State<TemperatureLogForm> {
  final _formKey = GlobalKey<FormState>();
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  DateTime _logTime = DateTime.now();
  String? _location;
  bool _isSubmitting = false;

  final List<String> _locationOptions = ['Oral', 'Axillary', 'Tympanic', 'Rectal', 'Forehead'];

  // Symptoms checklist
  bool _symptomFever = false;
  bool _symptomChills = false;
  bool _symptomSweating = false;
  bool _symptomHeadache = false;
  bool _symptomBodyAches = false;
  bool _symptomFatigue = false;
  bool _symptomCough = false;
  bool _symptomSoreThroat = false;

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    if (widget.serviceUserId != null) {
      _selectedServiceUserId = widget.serviceUserId;
    }
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_logTime));
    if (picked != null) {
      setState(() => _logTime = DateTime(
        _logTime.year, _logTime.month, _logTime.day,
        picked.hour, picked.minute,
      ));
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _logTime,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _logTime = DateTime(
        picked.year, picked.month, picked.day,
        _logTime.hour, _logTime.minute,
      ));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service user')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final temperature = double.parse(_temperatureController.text);

      final symptoms = <String>[];
      if (_symptomFever) symptoms.add('Fever');
      if (_symptomChills) symptoms.add('Chills');
      if (_symptomSweating) symptoms.add('Sweating');
      if (_symptomHeadache) symptoms.add('Headache');
      if (_symptomBodyAches) symptoms.add('Body Aches');
      if (_symptomFatigue) symptoms.add('Fatigue');
      if (_symptomCough) symptoms.add('Cough');
      if (_symptomSoreThroat) symptoms.add('Sore Throat');

      await Supabase.instance.client.from('temperature_logs').insert({
        'service_user_id': _selectedServiceUserId,
        'time': _logTime.toIso8601String(),
        'temperature': temperature,
        'location': _location,
        'symptoms': symptoms,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry saved successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temperature Log'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service user selector
            if (_loadingUsers)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedServiceUserId,
                decoration: const InputDecoration(
                  labelText: 'Service User *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String))).toList(),
                onChanged: (v) => setState(() => _selectedServiceUserId = v),
                validator: (v) => v == null ? 'Please select a service user' : null,
              ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                '${_logTime.day}/${_logTime.month}/${_logTime.year}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Time',
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                '${_logTime.hour.toString().padLeft(2, '0')}:${_logTime.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _temperatureController,
                      decoration: const InputDecoration(
                        labelText: 'Temperature (°C)',
                        prefixIcon: Icon(Icons.thermostat),
                        suffixText: '°C',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final temp = double.tryParse(value);
                        if (temp == null) return 'Invalid number';
                        if (temp < 34 || temp > 42) return 'Temperature out of range (34-42°C)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _location,
                      decoration: const InputDecoration(
                        labelText: 'Measurement Location',
                        prefixIcon: Icon(Icons.place),
                      ),
                      items: _locationOptions.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                      onChanged: (value) => setState(() => _location = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Symptoms (check all that apply)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(title: const Text('Fever'), value: _symptomFever, onChanged: (v) => setState(() => _symptomFever = v ?? false)),
                    CheckboxListTile(title: const Text('Chills'), value: _symptomChills, onChanged: (v) => setState(() => _symptomChills = v ?? false)),
                    CheckboxListTile(title: const Text('Sweating'), value: _symptomSweating, onChanged: (v) => setState(() => _symptomSweating = v ?? false)),
                    CheckboxListTile(title: const Text('Headache'), value: _symptomHeadache, onChanged: (v) => setState(() => _symptomHeadache = v ?? false)),
                    CheckboxListTile(title: const Text('Body Aches'), value: _symptomBodyAches, onChanged: (v) => setState(() => _symptomBodyAches = v ?? false)),
                    CheckboxListTile(title: const Text('Fatigue'), value: _symptomFatigue, onChanged: (v) => setState(() => _symptomFatigue = v ?? false)),
                    CheckboxListTile(title: const Text('Cough'), value: _symptomCough, onChanged: (v) => setState(() => _symptomCough = v ?? false)),
                    CheckboxListTile(title: const Text('Sore Throat'), value: _symptomSoreThroat, onChanged: (v) => setState(() => _symptomSoreThroat = v ?? false)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Entry', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}