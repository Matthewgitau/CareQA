import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/services/database_service.dart';
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

  final _callsPerDayController = TextEditingController(text: '1');
  List<TimeOfDay> _callTimes = [];
  List<Map<String, dynamic>> _medications = [];

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
    }
  }

  Future<void> _loadCallTimes() async {
    if (widget.serviceUser == null) return;
    try {
      final data = await Supabase.instance.client
          .from('service_user_calls')
          .select('calls_per_day, call_times')
          .eq('service_user_id', widget.serviceUser!.id)
          .maybeSingle();
      if (data != null) {
        _callsPerDayController.text = data['calls_per_day'].toString();
        final times = data['call_times'] as List<dynamic>;
        setState(() {
          _callTimes = times.map((t) {
            final parts = t.toString().split(':');
            return TimeOfDay(
                hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }).toList();
        });
      }
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
    _callsPerDayController.dispose();
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

  Future<void> _addCallTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _callTimes.add(picked);
      });
    }
  }

  void _removeCallTime(int index) {
    setState(() {
      _callTimes.removeAt(index);
    });
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
      final callTimesJson = _callTimes
          .map((t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList();
      final existing = await Supabase.instance.client
          .from('service_user_calls')
          .select('id')
          .eq('service_user_id', serviceUserId)
          .maybeSingle();
      if (existing != null) {
        await Supabase.instance.client
            .from('service_user_calls')
            .update({
              'calls_per_day': int.tryParse(_callsPerDayController.text) ?? 1,
              'call_times': callTimesJson,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('service_user_id', serviceUserId);
      } else {
        await Supabase.instance.client
            .from('service_user_calls')
            .insert({
          'service_user_id': serviceUserId,
          'calls_per_day': int.tryParse(_callsPerDayController.text) ?? 1,
          'call_times': callTimesJson,
        });
      }
    } catch (_) {}
  }

  Future<void> _saveServiceUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    try {
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
              _sectionHeader('Calls & Rota'),
              TextFormField(
                controller: _callsPerDayController,
                decoration: const InputDecoration(
                    labelText: 'Number of Calls Per Day',
                    prefixIcon: Icon(Icons.schedule)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text('Planned Call Times',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ..._callTimes.asMap().entries.map((entry) {
                final i = entry.key;
                final t = entry.value;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.access_time),
                  title: Text(t.format(context)),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle,
                        color: Colors.red),
                    onPressed: () => _removeCallTime(i),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addCallTime,
                icon: const Icon(Icons.add),
                label: const Text('Add Call Time'),
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