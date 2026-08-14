import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/mar_medication.dart';
import 'package:admin_app/services/mar_service.dart';

class MarMedicationForm extends StatefulWidget {
  final MarMedication? medication;
  final String? serviceUserId;
  final String? serviceUserName;

  const MarMedicationForm({
    super.key,
    this.medication,
    this.serviceUserId,
    this.serviceUserName,
  });

  @override
  State<MarMedicationForm> createState() => _MarMedicationFormState();
}

class _MarMedicationFormState extends State<MarMedicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = MarService(Supabase.instance.client);

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;
  String? _selectedServiceUserName;

  // Medication details
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  String? _dosageUnit;
  final _strengthController = TextEditingController();
  String? _form;

  // Schedule
  String? _frequency;
  List<TimeOfDay> _selectedTimes = [];
  List<int> _selectedDaysOfWeek = [];

  // Duration
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isOngoing = true;

  // Instructions
  final _specialInstructionsController = TextEditingController();
  String? _administrationRoute;

  // Prescriber
  final _prescribedByController = TextEditingController();
  DateTime? _prescribedDate;

  // Pharmacy
  final _pharmacyNameController = TextEditingController();
  final _pharmacyPhoneController = TextEditingController();

  // PRN
  bool _isPrn = false;

  // Stock
  final _stockQuantityController = TextEditingController();
  String? _stockUnit;
  final _reorderLevelController = TextEditingController();
  DateTime? _lastOrderedDate;
  DateTime? _nextRefillDue;

  bool _isSubmitting = false;

  final List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    _initialize();
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _strengthController.dispose();
    _specialInstructionsController.dispose();
    _prescribedByController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyPhoneController.dispose();
    _stockQuantityController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response);
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  void _initialize() {
    if (widget.serviceUserId != null) {
      _selectedServiceUserId = widget.serviceUserId;
      _selectedServiceUserName = widget.serviceUserName;
    }

    if (widget.medication != null) {
      final m = widget.medication!;
      _medicationNameController.text = m.medicationName;
      _dosageController.text = m.dosage;
      _dosageUnit = m.dosageUnit;
      _strengthController.text = m.strength ?? '';
      _form = m.form;
      _frequency = m.frequency;
      _selectedTimes = (m.frequencyTimes ?? [])
          .map((t) {
            final parts = t.split(':');
            return TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
            );
          })
          .toList();
      _selectedDaysOfWeek = m.daysOfWeek ?? [];
      _startDate = m.startDate;
      _endDate = m.endDate;
      _isOngoing = m.isOngoing;
      _specialInstructionsController.text = m.specialInstructions ?? '';
      _administrationRoute = m.administrationRoute;
      _prescribedByController.text = m.prescribedBy ?? '';
      _prescribedDate = m.prescribedDate;
      _pharmacyNameController.text = m.pharmacyName ?? '';
      _pharmacyPhoneController.text = m.pharmacyPhone ?? '';
      _isPrn = m.isPrn;
      _stockQuantityController.text = m.stockQuantity?.toString() ?? '';
      _stockUnit = m.stockUnit;
      _reorderLevelController.text = m.reorderLevel?.toString() ?? '';
      _lastOrderedDate = m.lastOrderedDate;
      _nextRefillDue = m.nextRefillDue;
    }
  }

  void _updateTimesForFrequency() {
    if (_frequency == null) return;
    final count = FrequencyHelper.timesCount(_frequency!);
    while (_selectedTimes.length < count) {
      _selectedTimes.add(TimeOfDay.now());
    }
    while (_selectedTimes.length > count) {
      _selectedTimes.removeLast();
    }
  }

  Future<void> _pickTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (time != null) {
      setState(() {
        _selectedTimes[index] = time;
      });
    }
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null) {
      onPicked(date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service user'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_frequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a frequency'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userName = _selectedServiceUserName ??
          _serviceUsers
              .firstWhere((u) => u['id'] == _selectedServiceUserId)['name']
              as String;

      final timeStrings = _selectedTimes
          .map((t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();

      final medication = MarMedication(
        id: widget.medication?.id,
        serviceUserId: _selectedServiceUserId,
        serviceUserName: userName,
        medicationName: _medicationNameController.text.trim(),
        dosage: _dosageController.text.trim(),
        dosageUnit: _dosageUnit,
        strength: _strengthController.text.trim().isNotEmpty
            ? _strengthController.text.trim()
            : null,
        form: _form,
        frequency: _frequency!,
        frequencyTimes: timeStrings,
        timesPerDay: timeStrings.length,
        daysOfWeek:
            _selectedDaysOfWeek.isNotEmpty ? _selectedDaysOfWeek : null,
        startDate: _startDate,
        endDate: _isOngoing ? null : _endDate,
        isOngoing: _isOngoing,
        specialInstructions:
            _specialInstructionsController.text.trim().isNotEmpty
                ? _specialInstructionsController.text.trim()
                : null,
        administrationRoute: _administrationRoute,
        prescribedBy: _prescribedByController.text.trim().isNotEmpty
            ? _prescribedByController.text.trim()
            : null,
        prescribedDate: _prescribedDate,
        pharmacyName: _pharmacyNameController.text.trim().isNotEmpty
            ? _pharmacyNameController.text.trim()
            : null,
        pharmacyPhone: _pharmacyPhoneController.text.trim().isNotEmpty
            ? _pharmacyPhoneController.text.trim()
            : null,
        isPrn: _isPrn,
        stockQuantity: _stockQuantityController.text.trim().isNotEmpty
            ? int.tryParse(_stockQuantityController.text.trim())
            : null,
        stockUnit: _stockUnit,
        reorderLevel: _reorderLevelController.text.trim().isNotEmpty
            ? int.tryParse(_reorderLevelController.text.trim())
            : null,
        lastOrderedDate: _lastOrderedDate,
        nextRefillDue: _nextRefillDue,
        createdBy: Supabase.instance.client.auth.currentUser?.id,
        updatedBy: Supabase.instance.client.auth.currentUser?.id,
        createdAt: widget.medication?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.medication?.id != null) {
        await _service.updateMedication(widget.medication!.id!, medication);
      } else {
        await _service.createMedication(medication);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.medication != null
                ? 'Medication updated successfully'
                : 'Medication added successfully'),
            backgroundColor: Colors.green,
          ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication != null ? 'Edit Medication' : 'Add Medication'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service User
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
                items: _serviceUsers
                    .map((u) => DropdownMenuItem(
                          value: u['id'] as String,
                          child: Text(u['name'] as String),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedServiceUserId = v;
                    _selectedServiceUserName = v != null
                        ? _serviceUsers.firstWhere((u) => u['id'] == v)['name']
                            as String
                        : null;
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
            const SizedBox(height: 16),

            // Medication Details
            _buildSectionTitle('Medication Details'),
            TextFormField(
              controller: _medicationNameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage *',
                      hintText: 'e.g. 10mg',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _dosageUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: DosageUnitHelper.values
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(DosageUnitHelper.labels[u] ?? u),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _dosageUnit = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _strengthController,
              decoration: const InputDecoration(
                labelText: 'Strength (optional)',
                hintText: 'e.g. 10mg/5ml',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _form,
              decoration: const InputDecoration(
                labelText: 'Form',
                border: OutlineInputBorder(),
              ),
              items: FormHelper.values
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(FormHelper.labels[f] ?? f),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _form = v),
            ),

            // Schedule
            _buildSectionTitle('Schedule'),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: FrequencyHelper.values
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(FrequencyHelper.labels[f] ?? f),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _frequency = v;
                  _updateTimesForFrequency();
                });
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            if (_frequency != null && _frequency != 'as_required') ...[
              const SizedBox(height: 12),
              const Text('Administration Times:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_selectedTimes.length, (index) {
                  final time = _selectedTimes[index];
                  return Chip(
                    avatar: const Icon(Icons.access_time, size: 18),
                    label: Text(time.format(context)),
                    onDeleted: () {
                      setState(() {
                        _selectedTimes.removeAt(index);
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }),
              ),
              if (_selectedTimes.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _pickTime(_selectedTimes.length - 1),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Times'),
                ),
            ],
            const SizedBox(height: 12),
            const Text('Days of Week (optional — leave empty for daily):',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: List.generate(7, (index) {
                // Convert 0=Monday to match our display
                final dayIndex = index; // 0=Mon, 1=Tue, ..., 6=Sun
                final isSelected = _selectedDaysOfWeek.contains(dayIndex);
                return FilterChip(
                  label: Text(_dayLabels[index]),
                  selected: isSelected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedDaysOfWeek.add(dayIndex);
                      } else {
                        _selectedDaysOfWeek.remove(dayIndex);
                      }
                    });
                  },
                );
              }),
            ),

            // Duration
            _buildSectionTitle('Duration'),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(
                      initial: _startDate,
                      onPicked: (d) => setState(() => _startDate = d),
                    ),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                    ),
                  ),
                ),
                if (!_isOngoing) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(
                        initial: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                        onPicked: (d) => setState(() => _endDate = d),
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Select date'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Ongoing medication (no end date)'),
              value: _isOngoing,
              activeColor: const Color(0xFF1976D2),
              onChanged: (v) {
                setState(() {
                  _isOngoing = v ?? true;
                  if (_isOngoing) _endDate = null;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // PRN
            CheckboxListTile(
              title: const Text('As Required (PRN)'),
              subtitle: const Text('Medication given only when needed'),
              value: _isPrn,
              activeColor: const Color(0xFF1976D2),
              onChanged: (v) {
                setState(() {
                  _isPrn = v ?? false;
                  if (_isPrn) _frequency = 'as_required';
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Administration Instructions
            _buildSectionTitle('Administration'),
            TextFormField(
              controller: _specialInstructionsController,
              decoration: const InputDecoration(
                labelText: 'Special Instructions',
                hintText: 'e.g. Take with food, Avoid dairy',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _administrationRoute,
              decoration: const InputDecoration(
                labelText: 'Administration Route',
                border: OutlineInputBorder(),
              ),
              items: RouteHelper.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(RouteHelper.labels[r] ?? r),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _administrationRoute = v),
            ),

            // Prescriber
            _buildSectionTitle('Prescriber'),
            TextFormField(
              controller: _prescribedByController,
              decoration: const InputDecoration(
                labelText: 'Prescribed By',
                hintText: 'Doctor name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_hospital),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(
                initial: _prescribedDate ?? DateTime.now(),
                onPicked: (d) => setState(() => _prescribedDate = d),
              ),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Prescribed Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(_prescribedDate != null
                    ? DateFormat('dd/MM/yyyy').format(_prescribedDate!)
                    : 'Select date'),
              ),
            ),

            // Pharmacy
            _buildSectionTitle('Pharmacy (Optional)'),
            TextFormField(
              controller: _pharmacyNameController,
              decoration: const InputDecoration(
                labelText: 'Pharmacy Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pharmacyPhoneController,
              decoration: const InputDecoration(
                labelText: 'Pharmacy Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),

            // Stock Information
            _buildSectionTitle('Stock Information (Optional)'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _stockUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: ['tablets', 'ml', 'patches', 'capsules', 'inhalations']
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _stockUnit = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reorderLevelController,
              decoration: const InputDecoration(
                labelText: 'Reorder Level (alert when stock reaches this)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(
                      initial: _lastOrderedDate ?? DateTime.now(),
                      onPicked: (d) => setState(() => _lastOrderedDate = d),
                    ),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Last Ordered',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_lastOrderedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_lastOrderedDate!)
                          : 'Select date'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(
                      initial: _nextRefillDue ?? DateTime.now().add(const Duration(days: 30)),
                      onPicked: (d) => setState(() => _nextRefillDue = d),
                    ),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Next Refill Due',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_nextRefillDue != null
                          ? DateFormat('dd/MM/yyyy').format(_nextRefillDue!)
                          : 'Select date'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit
            ElevatedButton(
              onPressed: _isSubmitting ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.medication != null
                          ? 'Update Medication'
                          : 'Add Medication',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
