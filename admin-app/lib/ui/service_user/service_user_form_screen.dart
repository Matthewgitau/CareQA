import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/services/database_service.dart';
import 'package:admin_app/services/shift_rota_service.dart';
import 'package:admin_app/ui/assessments/respect_form_screen.dart';
import 'package:admin_app/ui/risk_assessment/risk_assessment_screen.dart';

class ServiceUserFormScreen extends StatefulWidget {
  final ServiceUser? serviceUser;
  const ServiceUserFormScreen({super.key, this.serviceUser});

  @override
  State<ServiceUserFormScreen> createState() => _ServiceUserFormScreenState();
}

class _ServiceUserFormScreenState extends State<ServiceUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _referenceCodeController = TextEditingController();
  final _dobController = TextEditingController();
  final _nhsController = TextEditingController();
  DateTime? _selectedDob;

  final _gpNameController = TextEditingController();
  final _gpPhoneController = TextEditingController();

  final _familyNameController = TextEditingController();
  final _familyPhoneController = TextEditingController();
  final _familyRelationController = TextEditingController();
  final _familyEmailController = TextEditingController();

  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  Map<int, List<(TimeOfDay, int)>> _weeklyCallTimes = {};
  List<Map<String, dynamic>> _medications = [];

  // Visit preferences (stored in care_plan JSON)
  TimeOfDay? _preferredVisitTime;
  int _durationMinutes = 60;
  final Set<String> _visitDays = {};
  bool _requiresTwoCarers = false;
  final _visitNotesController = TextEditingController();

  static const _durationOptions = [30, 45, 60, 90, 120];
  static const _dayOptions = [
    ('monday', 'Mon'),
    ('tuesday', 'Tue'),
    ('wednesday', 'Wed'),
    ('thursday', 'Thu'),
    ('friday', 'Fri'),
    ('saturday', 'Sat'),
    ('sunday', 'Sun'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serviceUser != null) {
      final su = widget.serviceUser!;
      _nameController.text = su.name;
      _addressController.text = su.address;
      _referenceCodeController.text = su.referenceCode ?? '';
      _nhsController.text = su.nhsNumber ?? '';
      _gpNameController.text = su.gpName ?? '';
      _gpPhoneController.text = su.gpPhone ?? '';
      _familyNameController.text = su.familyContactName ?? '';
      _familyPhoneController.text = su.familyContactPhone ?? '';
      _familyRelationController.text = su.familyContactRelation ?? '';
      _familyEmailController.text = su.familyContactEmail ?? '';
      _emergencyNameController.text = su.emergencyContactName ?? '';
      _emergencyPhoneController.text = su.emergencyContactPhone ?? '';
      _emergencyRelationController.text = su.emergencyContactRelation ?? '';
      _medications = List<Map<String, dynamic>>.from(su.medicationList);
      if (su.dateOfBirth != null) {
        _selectedDob = su.dateOfBirth;
        _dobController.text =
            '${su.dateOfBirth!.day}/${su.dateOfBirth!.month}/${su.dateOfBirth!.year}';
      }
      _loadCallTimes();
      _loadVisitPreferences();
    }
  }

  void _loadVisitPreferences() {
    final prefs = widget.serviceUser!.visitPreferences;
    if (prefs.preferredTime != null) {
      final parts = prefs.preferredTime!.split(':');
      if (parts.length >= 2) {
        _preferredVisitTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    _durationMinutes = prefs.durationMinutes ?? 60;
    _visitDays.addAll(prefs.visitDays);
    _requiresTwoCarers = prefs.requiresTwoCarers;
    _visitNotesController.text = prefs.notes ?? '';
  }

  Future<void> _loadCallTimes() async {
    if (widget.serviceUser == null) return;
    try {
      final weekly = await ShiftRotaService(Supabase.instance.client)
          .getServiceUserWeeklyCalls(widget.serviceUser!.id);
      final map = <int, List<(TimeOfDay, int)>>{};
      weekly.forEach((weekday, slots) {
        map[weekday] = slots.map((s) {
          final parts = (s['time'] as String? ?? '').split(':');
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          return (
            TimeOfDay(hour: hour, minute: minute),
            (s['duration_minutes'] as num?)?.toInt() ?? 60,
          );
        }).toList();
      });
      if (!mounted) return;
      setState(() => _weeklyCallTimes = map);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _referenceCodeController.dispose();
    _dobController.dispose();
    _nhsController.dispose();
    _gpNameController.dispose();
    _gpPhoneController.dispose();
    _familyNameController.dispose();
    _familyPhoneController.dispose();
    _familyRelationController.dispose();
    _familyEmailController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _visitNotesController.dispose();
    super.dispose();
  }

  void _autoGenerateReferenceCode() {
    if (widget.serviceUser != null) {
      setState(() {
        _referenceCodeController.text =
            widget.serviceUser!.id.replaceAll('-', '').substring(0, 8).toUpperCase();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Save the service user first to auto-generate a reference code.')),
      );
    }
  }

  Future<void> _selectDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1970),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  int _weekdayInt(String dayName) {
    const map = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    return map[dayName] ?? DateTime.monday;
  }

  Future<void> _addWeeklyCallTime(int weekday) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;

    final duration = await _pickDuration();
    if (duration == null) return;

    setState(() {
      _weeklyCallTimes.putIfAbsent(weekday, () => []).add((picked, duration));
    });
  }

  Future<int?> _pickDuration() {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Call duration'),
        children: [
          ..._durationOptions.map((d) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, d),
                child: Text('$d minutes'),
              )),
          SimpleDialogOption(
            onPressed: () async {
              final custom = await _pickCustomDuration();
              if (custom != null && dialogContext.mounted) {
                Navigator.pop(dialogContext, custom);
              }
            },
            child: const Text('Custom…'),
          ),
        ],
      ),
    );
  }

  Future<int?> _pickCustomDuration() {
    final ctrl = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Custom duration (minutes)'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final m = int.tryParse(ctrl.text.trim());
              Navigator.pop(d, (m != null && m > 0) ? m : null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _removeWeeklyCallTime(int weekday, int index) {
    setState(() {
      _weeklyCallTimes[weekday]?.removeAt(index);
    });
  }

  Widget _buildDayCallEditor(int weekday, String label) {
    final times = _weeklyCallTimes[weekday] ?? const <(TimeOfDay, int)>[];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addWeeklyCallTime(weekday),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add time'),
                ),
              ],
            ),
            if (times.isEmpty)
              const Text('No calls',
                  style: TextStyle(color: Colors.grey, fontSize: 12))
            else
              ...times.asMap().entries.map((e) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text('${e.value.$1.format(context)} · ${e.value.$2} min'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeWeeklyCallTime(weekday, e.key),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  void _addMedication() {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Medication Name')),
            TextField(
                controller: doseCtrl,
                decoration: const InputDecoration(labelText: 'Dose')),
            TextField(
                controller: freqCtrl,
                decoration: const InputDecoration(labelText: 'Frequency')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _medications.add({
                    'name': nameCtrl.text.trim(),
                    'dose': doseCtrl.text.trim(),
                    'frequency': freqCtrl.text.trim(),
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  Future<void> _saveCallTimes(String serviceUserId) async {
    try {
      final weekly = <int, List<Map<String, dynamic>>>{};
      _weeklyCallTimes.forEach((weekday, slots) {
        if (slots.isEmpty) return;
        weekly[weekday] = slots
            .map((s) => {
                  'time':
                      '${s.$1.hour.toString().padLeft(2, '0')}:${s.$1.minute.toString().padLeft(2, '0')}',
                  'duration_minutes': s.$2,
                })
            .toList();
      });
      await ShiftRotaService(Supabase.instance.client)
          .saveServiceUserWeeklyCalls(serviceUserId, weekly);
    } catch (_) {}
  }

  Future<void> _saveServiceUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    try {
      // Build visit preferences from the form
      final visitPrefs = VisitPreferences(
        preferredTime: _preferredVisitTime != null
            ? '${_preferredVisitTime!.hour.toString().padLeft(2, '0')}:'
                '${_preferredVisitTime!.minute.toString().padLeft(2, '0')}'
            : null,
        durationMinutes: _durationMinutes,
        visitDays: _visitDays.toList(),
        requiresTwoCarers: _requiresTwoCarers,
        notes: _visitNotesController.text.trim().isEmpty
            ? null
            : _visitNotesController.text.trim(),
      );

      // Merge visit preferences into the existing care_plan
      final existingCarePlan = widget.serviceUser?.carePlan ?? {};
      final updatedCarePlan = Map<String, dynamic>.from(existingCarePlan);
      updatedCarePlan['visit_preferences'] = visitPrefs.toJson();

      final serviceUser = ServiceUser(
        id: widget.serviceUser?.id ?? '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        referenceCode: _referenceCodeController.text.trim().isEmpty
            ? null
            : _referenceCodeController.text.trim(),
        dateOfBirth: _selectedDob,
        nhsNumber: _nhsController.text.trim().isEmpty
            ? null
            : _nhsController.text.trim(),
        gpName: _gpNameController.text.trim().isEmpty
            ? null
            : _gpNameController.text.trim(),
        gpPhone: _gpPhoneController.text.trim().isEmpty
            ? null
            : _gpPhoneController.text.trim(),
        familyContactName: _familyNameController.text.trim().isEmpty
            ? null
            : _familyNameController.text.trim(),
        familyContactPhone: _familyPhoneController.text.trim().isEmpty
            ? null
            : _familyPhoneController.text.trim(),
        familyContactRelation: _familyRelationController.text.trim().isEmpty
            ? null
            : _familyRelationController.text.trim(),
        familyContactEmail: _familyEmailController.text.trim().isEmpty
            ? null
            : _familyEmailController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        emergencyContactRelation:
            _emergencyRelationController.text.trim().isEmpty
                ? null
                : _emergencyRelationController.text.trim(),
        medicationList: _medications,
        carePlan: updatedCarePlan,
        createdAt: widget.serviceUser?.createdAt ?? DateTime.now(),
      );

      String savedId;
      if (widget.serviceUser != null) {
        await db.updateServiceUser(serviceUser);
        savedId = widget.serviceUser!.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Service User updated successfully')),
          );
        }
      } else {
        final result = await Supabase.instance.client
            .from('service_users')
            .insert(serviceUser.toMap())
            .select('id')
            .single();
        savedId = result['id'] as String;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Service User created successfully')),
          );
        }
      }

      await _saveCallTimes(savedId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceUser != null
            ? 'Edit Service User'
            : 'Add Service User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _sectionHeader('Basic Information'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.home)),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _referenceCodeController,
                      decoration: const InputDecoration(
                          labelText: 'Reference Code (optional)',
                          prefixIcon: Icon(Icons.tag)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _autoGenerateReferenceCode,
                    child: const Text('Auto'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _selectDob,
                decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.cake)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nhsController,
                decoration: const InputDecoration(
                    labelText: 'NHS Number',
                    prefixIcon: Icon(Icons.local_hospital)),
              ),
              _sectionHeader('GP Details'),
              TextFormField(
                controller: _gpNameController,
                decoration: const InputDecoration(
                    labelText: 'GP Name',
                    prefixIcon: Icon(Icons.medical_services)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gpPhoneController,
                decoration: const InputDecoration(
                    labelText: 'GP Phone',
                    prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              _sectionHeader('Family Contact'),
              TextFormField(
                controller: _familyNameController,
                decoration: const InputDecoration(
                    labelText: 'Family Contact Name',
                    prefixIcon: Icon(Icons.people)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _familyPhoneController,
                decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _familyRelationController,
                decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.family_restroom)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _familyEmailController,
                decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              _sectionHeader('Emergency Contact'),
              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                    labelText: 'Emergency Contact Name',
                    prefixIcon: Icon(Icons.emergency)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyPhoneController,
                decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyRelationController,
                decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.family_restroom)),
              ),
              _sectionHeader('Calls & Rota — Weekly Timetable'),
              const Text(
                'Set call times for each day. Leave a day empty for no calls that day.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ..._dayOptions.map((day) =>
                  _buildDayCallEditor(_weekdayInt(day.$1), day.$2)),
              _sectionHeader('Visit Preferences'),
              const Text(
                'These preferences are used to auto-build routes on the Route Schedule screen.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Preferred Visit Time'),
                subtitle: Text(
                  _preferredVisitTime != null
                      ? _preferredVisitTime!.format(context)
                      : 'Not set',
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _preferredVisitTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => _preferredVisitTime = picked);
                    }
                  },
                  child: const Text('Pick'),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _durationOptions.contains(_durationMinutes)
                    ? _durationMinutes
                    : 60,
                decoration: const InputDecoration(
                  labelText: 'Visit Duration',
                  prefixIcon: Icon(Icons.timer),
                  border: OutlineInputBorder(),
                ),
                items: _durationOptions
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text('$d minutes'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _durationMinutes = v ?? 60),
              ),
              const SizedBox(height: 16),
              const Text('Visit Days',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _dayOptions.map((day) {
                  final (value, label) = day;
                  final selected = _visitDays.contains(value);
                  return FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _visitDays.add(value);
                        } else {
                          _visitDays.remove(value);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Requires Two Carers'),
                value: _requiresTwoCarers,
                onChanged: (v) => setState(() => _requiresTwoCarers = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _visitNotesController,
                decoration: const InputDecoration(
                  labelText: 'Visit Notes (optional)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              _sectionHeader('Medication List'),
              ..._medications.asMap().entries.map((entry) {
                final i = entry.key;
                final med = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(med['name'] ?? ''),
                    subtitle: Text(
                        'Dose: ${med['dose'] ?? '-'}  |  Frequency: ${med['frequency'] ?? '-'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle,
                          color: Colors.red),
                      onPressed: () => _removeMedication(i),
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addMedication,
                icon: const Icon(Icons.add),
                label: const Text('Add Medication'),
              ),
              _sectionHeader('Risk Assessments'),
              OutlinedButton.icon(
                icon: const Icon(Icons.assessment),
                label: const Text('View / Create Risk Assessment'),
                onPressed: () {
                  if (widget.serviceUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              RiskAssessmentHubScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Save the service user first to access risk assessments.')),
                    );
                  }
                },
              ),
              _sectionHeader('ReSPECT Form'),
              OutlinedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text('View / Complete ReSPECT Form'),
                onPressed: () {
                  if (widget.serviceUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RespectFormScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Save the service user first to access the ReSPECT form.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload ReSPECT Form (Coming Soon)'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'File upload will be available once storage is configured.')),
                  );
                },
              ),
              _sectionHeader('Care Plan'),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Care Plan (Coming Soon)'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'File upload will be available once storage is configured.')),
                  );
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Auto-Generate Care Plan (Coming Soon)'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Care plan auto-generation will be available once risk assessments are complete.')),
                  );
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveServiceUser,
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(widget.serviceUser != null
                            ? 'Update Service User'
                            : 'Create Service User'),
                      ),
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}