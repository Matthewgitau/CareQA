import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarehomeDetailsScreen extends StatefulWidget {
  const CarehomeDetailsScreen({super.key});

  @override
  State<CarehomeDetailsScreen> createState() => _CarehomeDetailsScreenState();
}

class _CarehomeDetailsScreenState extends State<CarehomeDetailsScreen> {
  List<Map<String, dynamic>> _organisations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('client_organisations')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _organisations = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Organisations')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _organisations.isEmpty
              ? const Center(child: Text('No organisations found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _organisations.length,
                    itemBuilder: (_, i) {
                      final org = _organisations[i];
                      final types = (org['organisation_types'] as List?)
                              ?.map((t) => t.toString())
                              .join(', ') ??
                          '';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            org['name']?.toString() ?? 'Unknown',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (types.isNotEmpty) Text('Type: $types'),
                              if (org['address'] != null)
                                Text(org['address'].toString()),
                              if (org['billing_rate_per_hour'] != null)
                                Text(
                                    'Rate: £${org['billing_rate_per_hour']}/hr'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClientOrganisationForm(
                                      existing: org),
                                ),
                              );
                              if (result == true) _load();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ClientOrganisationForm(),
            ),
          );
          if (result == true) _load();
        },
        tooltip: 'Add Organisation',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ClientOrganisationForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const ClientOrganisationForm({super.key, this.existing});

  @override
  State<ClientOrganisationForm> createState() =>
      _ClientOrganisationFormState();
}

class _ClientOrganisationFormState extends State<ClientOrganisationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _billingRateController = TextEditingController();
  final _notesController = TextEditingController();

  List<String> _selectedTypes = [];
  List<Map<String, dynamic>> _shiftTypes = [];
  List<Map<String, dynamic>> _contacts = [];
  String? _size;

  static const List<String> _organisationTypeOptions = [
    'Care Home',
    'Warehouse',
    'Domiciliary',
    'Supported Living',
    'Custom',
  ];

  static const List<String> _presetShiftNames = [
    'Early',
    'Long Day',
    'Late',
    'Night',
    'Waking Night',
    'Live In',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e['name'] ?? '';
      _addressController.text = e['address'] ?? '';
      _emailController.text = e['email'] ?? '';
      _phoneController.text = e['phone'] ?? '';
      _billingRateController.text =
          e['billing_rate_per_hour']?.toString() ?? '';
      _notesController.text = e['notes'] ?? '';
      _size = e['size'];
      _selectedTypes = e['organisation_types'] != null
          ? List<String>.from(e['organisation_types'])
          : [];
      _shiftTypes = e['shift_types'] != null
          ? List<Map<String, dynamic>>.from(e['shift_types'])
          : [];
      _contacts = e['associated_contacts'] != null
          ? List<Map<String, dynamic>>.from(e['associated_contacts'])
          : [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _billingRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addShiftType() {
    final nameCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    String selectedPreset = _presetShiftNames[0];
    bool isLiveIn = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Shift Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPreset,
                  decoration:
                      const InputDecoration(labelText: 'Shift Name'),
                  items: _presetShiftNames
                      .map((n) =>
                          DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedPreset = v!;
                      isLiveIn = v == 'Live In';
                      if (v != 'Custom') nameCtrl.text = v;
                    });
                  },
                ),
                if (selectedPreset == 'Custom') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Custom Name'),
                  ),
                ],
                if (!isLiveIn) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Start Time (e.g. 07:00)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(
                        labelText: 'End Time (e.g. 14:00)'),
                  ),
                ],
                if (isLiveIn)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Live In shifts are measured in days/weeks. Dates are set when booking.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final shiftName = selectedPreset == 'Custom'
                    ? nameCtrl.text.trim()
                    : selectedPreset;
                if (shiftName.isNotEmpty) {
                  setState(() {
                    _shiftTypes.add({
                      'name': shiftName,
                      'start_time':
                          isLiveIn ? null : startCtrl.text.trim(),
                      'end_time': isLiveIn ? null : endCtrl.text.trim(),
                      'is_live_in': isLiveIn,
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeShiftType(int index) {
    setState(() => _shiftTypes.removeAt(index));
  }

  void _addContact() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'Phone (optional)')),
            TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Role (e.g. Manager)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                setState(() {
                  _contacts.add({
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'role': roleCtrl.text.trim(),
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

  void _removeContact(int index) {
    setState(() => _contacts.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one organisation type')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final payload = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'organisation_types': _selectedTypes,
        'billing_rate_per_hour': _billingRateController.text.trim().isEmpty
            ? null
            : double.tryParse(_billingRateController.text.trim()),
        'shift_types': _shiftTypes,
        'associated_contacts': _contacts,
        'size': _size,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.existing != null) {
        await Supabase.instance.client
            .from('client_organisations')
            .update(payload)
            .eq('id', widget.existing!['id']);
      } else {
        await Supabase.instance.client
            .from('client_organisations')
            .insert(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.existing != null
                  ? 'Organisation updated'
                  : 'Organisation created')),
        );
        Navigator.pop(context, true);
      }
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
        title: Text(widget.existing != null
            ? 'Edit Organisation'
            : 'Add Organisation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _sectionHeader('Organisation Type'),
              const Text(
                'Select all that apply (required)',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _organisationTypeOptions.map((type) {
                  final selected = _selectedTypes.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              _sectionHeader('Basic Details'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Organisation Name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Primary Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _billingRateController,
                decoration: const InputDecoration(
                  labelText: 'Billing Rate Per Hour (£)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _size,
                decoration: const InputDecoration(
                  labelText: 'Size (optional)',
                  prefixIcon: Icon(Icons.people),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Not specified')),
                  DropdownMenuItem(value: 'small', child: Text('Small')),
                  DropdownMenuItem(value: 'large', child: Text('Large')),
                ],
                onChanged: (v) => setState(() => _size = v),
              ),
              _sectionHeader('Shift Types'),
              ..._shiftTypes.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(s['name'] ?? ''),
                    subtitle: s['is_live_in'] == true
                        ? const Text('Live In — billed by days/weeks')
                        : Text(
                            '${s['start_time'] ?? '-'} — ${s['end_time'] ?? '-'}'),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeShiftType(i),
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addShiftType,
                icon: const Icon(Icons.add),
                label: const Text('Add Shift Type'),
              ),
              _sectionHeader('Associated Contacts'),
              const Text(
                'Contacts who can view and book shifts',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._contacts.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(c['name'] ?? ''),
                    subtitle: Text(
                        '${c['email'] ?? ''}${c['role'] != null && c['role'].toString().isNotEmpty ? ' — ${c['role']}' : ''}'),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeContact(i),
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addContact,
                icon: const Icon(Icons.add),
                label: const Text('Add Contact'),
              ),
              _sectionHeader('Notes'),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(widget.existing != null
                            ? 'Update Organisation'
                            : 'Create Organisation'),
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