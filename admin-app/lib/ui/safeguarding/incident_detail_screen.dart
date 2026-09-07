import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String incidentType;
  final String mode; // 'create' or 'edit'
  final String? incidentId;
  final Map<String, dynamic>? rawData;

  const IncidentDetailScreen({
    super.key,
    required this.incidentType,
    required this.mode,
    this.incidentId,
    this.rawData,
  });

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _isCreate = false;

  // Common fields
  String _description = '';
  String _severity = 'death'; // will be set per-type in initState
  String _status = 'reported';
  DateTime _incidentDate = DateTime.now();
  String _location = '';
  String _serviceUserName = '';
  String? _serviceUserId;
  List<Map<String, dynamic>> _serviceUsers = [];
  final Map<String, dynamic> _extraFields = {};

  @override
  void initState() {
    super.initState();
    _isCreate = widget.mode == 'create';

    // Set sensible defaults based on incident type
    _severity = _defaultSeverity(widget.incidentType);

    if (!_isCreate && widget.rawData != null) {
      _populateFromRawData(widget.rawData!);
    }
    _loadServiceUsers();
  }

  /// Returns the first dropdown value for each incident type.
  String _defaultSeverity(String type) {
    switch (type) {
      case 'accident': return 'none';
      case 'complaint': return 'care_quality';
      case 'medication': return 'low';
      case 'missing_person': return 'low';
      case 'serious': return 'death';
      case 'missing_item': return 'low';
      default: return 'none';
    }
  }

  Future<void> _loadServiceUsers() async {
    try {
      final data = await _client.from('service_users').select('id, name').order('name');
      if (mounted) setState(() => _serviceUsers = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  void _populateFromRawData(Map<String, dynamic> data) {
    _status = _normalizeStatus(data['status']?.toString() ?? 'reported');
    _severity = _normalizeSeverity(
      _readSeverityFromData(data, widget.incidentType),
      widget.incidentType,
    );
    _description = data['description']?.toString() ?? '';
    _location = data['location']?.toString() ?? '';
    _serviceUserName = data['service_user_name']?.toString() ?? '';
    _serviceUserId = data['service_user_id']?.toString();

    final dateKey = _dateKeyForType(widget.incidentType);
    _incidentDate = _tryParseDate(data[dateKey]) ?? DateTime.now();
    _extraFields.addAll(data);
    // Normalize type-specific dropdown values so they match
    _normalizeExtraFields(widget.incidentType);
  }

  /// Ensure _extraFields values match the dropdown items for each type.
  void _normalizeExtraFields(String type) {
    switch (type) {
      case 'accident':
        if (!['fall','slip','burn','medication_error','equipment','other']
            .contains(_extraFields['accident_type']?.toString()))
          _extraFields['accident_type'] = 'other';
        break;
      case 'complaint':
        if (!['care_quality','staff_conduct','facilities','communication','food','safeguarding','other']
            .contains(_extraFields['complaint_category']?.toString()))
          _extraFields['complaint_category'] = 'care_quality';
        break;
      case 'medication':
        if (!['wrong_medication','wrong_dose','missed_dose','double_dose','wrong_time','allergic_reaction','other']
            .contains(_extraFields['incident_type']?.toString()))
          _extraFields['incident_type'] = 'wrong_medication';
        break;
    }
  }

  /// Reads the severity/category value from the correct DB field for each type.
  String _readSeverityFromData(Map<String, dynamic> data, String type) {
    switch (type) {
      case 'accident':
        return (data['injury_severity'] ?? data['severity'])?.toString() ?? 'none';
      case 'complaint':
        return (data['complaint_category'] ?? data['severity'])?.toString() ?? 'care_quality';
      case 'medication':
        return (data['severity'])?.toString() ?? 'low';
      case 'missing_person':
        return (data['risk_assessment'] ?? data['severity'])?.toString() ?? 'low';
      case 'serious':
        return (data['incident_type'] ?? data['severity'])?.toString() ?? 'death';
      default:
        return data['severity']?.toString() ?? 'none';
    }
  }

  /// Map stored status values to dropdown-compatible values.
  String _normalizeStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'open': return 'reported';
      case 'investigating': return 'investigating';
      case 'active': return 'active';
      case 'resolved': return 'resolved';
      case 'closed': return 'closed';
      default: return 'reported';
    }
  }

  /// Map stored severity values to exactly match one dropdown value per type.
  String _normalizeSeverity(String raw, String type) {
    final lower = raw.toLowerCase();
    switch (type) {
      case 'accident':
        // dropdown: none, minor, moderate, major, critical
        if (['none','minor','moderate','major','critical'].contains(lower)) return lower;
        if (lower == 'low') return 'minor';
        if (lower == 'medium') return 'moderate';
        if (lower == 'high') return 'major';
        return 'none';
      case 'complaint':
        // dropdown: care_quality, staff_conduct, facilities, communication, safeguarding, other
        if (['care_quality','staff_conduct','facilities','communication','safeguarding','other'].contains(lower)) return lower;
        if (lower == 'food') return 'other';
        return 'care_quality';
      case 'medication':
      case 'missing_person':
        // medication: low, medium, high, critical
        // missing_person: low, medium, high
        if (['low','medium','high','critical'].contains(lower)) return lower;
        if (lower == 'minor' || lower == 'none') return 'low';
        if (lower == 'moderate') return 'medium';
        if (lower == 'major') return 'high';
        return 'low';
      case 'serious':
        // dropdown: death, serious_injury, abuse, police_involvement, safeguarding_alert, other
        if (['death','serious_injury','abuse','police_involvement','safeguarding_alert','other'].contains(lower)) return lower;
        if (lower == 'physical' || lower == 'physical abuse') return 'abuse';
        if (lower == 'neglect') return 'abuse';
        if (lower == 'self-harm' || lower == 'self_harm') return 'safeguarding_alert';
        return 'other';
      default:
        return raw;
    }
  }

  // ─── Table routing ─────────────────────────────────────
  String _tableName() {
    switch (widget.incidentType) {
      case 'accident':
        return 'accident_logs';
      case 'complaint':
        return 'complaints_logs';
      case 'medication':
        return 'medication_incidents';
      case 'missing_person':
        return 'missing_persons';
      case 'serious':
        return 'serious_incidents';
      case 'missing_item':
        return 'missing_items';
      default:
        return 'accident_logs';
    }
  }

  String _dateKeyForType(String type) {
    switch (type) {
      case 'accident':
        return 'accident_date';
      case 'complaint':
        return 'complaint_date';
      case 'medication':
      case 'serious':
        return 'incident_date';
      case 'missing_person':
      case 'missing_item':
        return 'missing_date';
      default:
        return 'incident_date';
    }
  }

  String _typeDisplayName() {
    switch (widget.incidentType) {
      case 'accident':
        return 'Accident';
      case 'complaint':
        return 'Complaint';
      case 'medication':
        return 'Medication Incident';
      case 'missing_person':
        return 'Missing Person';
      case 'serious':
        return 'Serious Incident';
      case 'missing_item':
        return 'Missing Item';
      default:
        return widget.incidentType;
    }
  }

  // ─── Build save data ───────────────────────────────────
  Map<String, dynamic> _buildInsertData() {
    final dateKey = _dateKeyForType(widget.incidentType);
    final base = <String, dynamic>{
      dateKey: _incidentDate.toIso8601String().split('T').first,
      'status': _status,
      'service_user_id': _serviceUserId,
      'service_user_name': _serviceUserName.isNotEmpty ? _serviceUserName : null,
      'created_by': _client.auth.currentUser?.id,
      'organisation_id': _client.auth.currentUser?.userMetadata?['organisation_id'],
    };

    switch (widget.incidentType) {
      case 'accident':
        base.addAll({
          'description': _description,
          'location': _location.isNotEmpty ? _location : null,
          'injury_severity': _severity,
                    'accident_type': _extraFields['accident_type'] ?? 'other',
          'first_aid_given': _extraFields['first_aid_given'] ?? false,
          'first_aid_details': _extraFields['first_aid_details'],
          'medical_attention_sought': _extraFields['medical_attention_sought'] ?? false,
          'medical_provider': _extraFields['medical_provider'],
          'reported_to_family': _extraFields['reported_to_family'] ?? false,
        });
        break;

      case 'complaint':
        base.addAll({
          'description': _description,
          'complaint_category': _severity,
          'complainant_name': _extraFields['complainant_name'],
          'complainant_type': _extraFields['complainant_type'],
                  });
        break;

      case 'medication':
        base.addAll({
          'description': _description,
          'severity': _severity,
          'medication_name': _extraFields['medication_name'],
          'prescribed_dosage': _extraFields['prescribed_dosage'],
          'actual_dosage': _extraFields['actual_dosage'],
          'incident_type': _extraFields['incident_type'] ?? 'error',
          'immediate_action': _extraFields['immediate_action'],
          'reported_to_family': _extraFields['reported_to_family'] ?? false,
                  });
        break;

      case 'missing_person':
        base.addAll({
          'circumstances': _description,
          'last_seen_location': _location.isNotEmpty ? _location : null,
          'risk_assessment': _severity,
                    'police_informed': _extraFields['police_informed'] ?? false,
          'family_informed': _extraFields['family_informed'] ?? false,
        });
        break;

      case 'serious':
        base.addAll({
          'description': _description,
          'incident_type': _severity,
          'notification_required': _extraFields['notification_required'] ?? true,
                    'police_involved': _extraFields['police_involved'] ?? false,
          'investigation_lead': _extraFields['investigation_lead'],
        });
        break;

      case 'missing_item':
        base.addAll({
          'item_name': _description,
          'item_description': _extraFields['item_description'],
          'item_value': _extraFields['item_value'],
          'last_seen_location': _location.isNotEmpty ? _location : null,
          'circumstances': _extraFields['circumstances'],
                    'police_informed': _extraFields['police_informed'] ?? false,
          'family_informed': _extraFields['family_informed'] ?? false,
        });
        break;
    }

    return base;
  }

  // ─── Save ──────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);
    try {
      final tableName = _tableName();
      final data = _buildInsertData();

      if (_isCreate) {
        await _client.from(tableName).insert(data);
      } else {
        await _client
            .from(tableName)
            .update(data)
            .eq('id', widget.incidentId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully')),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Update status (resolve / close) ───────────────────
  Future<void> _updateStatus(String newStatus) async {
    try {
      final tableName = _tableName();
      final updates = <String, dynamic>{
        'status': newStatus,
      };
      if (newStatus == 'resolved') {
        updates['resolved_at'] = DateTime.now().toIso8601String();
      }

      await _client
          .from(tableName)
          .update(updates)
          .eq('id', widget.incidentId!);

      setState(() => _status = newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEdit = !_isCreate && widget.incidentId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreate ? 'New ${_typeDisplayName()}' : _typeDisplayName()),
        actions: [
          if (isEdit && _status != 'resolved' && _status != 'closed')
            PopupMenuButton<String>(
              onSelected: _updateStatus,
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'resolved', child: Text('Mark Resolved')),
                const PopupMenuItem(value: 'closed', child: Text('Close')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Service User
              if (_serviceUsers.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _serviceUserId,
                  decoration: const InputDecoration(
                    labelText: 'Service User',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: _serviceUsers.map((u) => DropdownMenuItem(
                    value: u['id'] as String,
                    child: Text(u['name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final su = _serviceUsers.firstWhere((u) => u['id'] == v);
                      setState(() {
                        _serviceUserId = v;
                        _serviceUserName = (su['name'] as String?) ?? '';
                      });
                    }
                  },
                )
              else
                TextFormField(
                  initialValue: _serviceUserName,
                  decoration: const InputDecoration(
                    labelText: 'Service User Name',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => _serviceUserName = v?.trim() ?? '',
                ),
              const SizedBox(height: 16),

              // Date picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(_incidentDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _incidentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _incidentDate = picked);
                },
              ),
              const SizedBox(height: 16),

              // Type-specific severity
              _buildSeverityDropdown(),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                initialValue: _location,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _location = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Status dropdown (for edit mode)
              if (isEdit)
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'reported', child: Text('Reported')),
                    DropdownMenuItem(
                        value: 'investigating', child: Text('Investigating')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),

              // Type-specific extra fields
              ..._buildTypeSpecificFields(),

              const SizedBox(height: 24),

              // Save button
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isCreate ? 'Create Incident' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Severity / category dropdown ──────────────────────
  Widget _buildSeverityDropdown() {
    switch (widget.incidentType) {
      case 'accident':
        return DropdownButtonFormField<String>(
          value: _severity,
          decoration: const InputDecoration(
            labelText: 'Injury Severity',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('None')),
            DropdownMenuItem(value: 'minor', child: Text('Minor')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
            DropdownMenuItem(value: 'major', child: Text('Major')),
            DropdownMenuItem(value: 'critical', child: Text('Critical')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _severity = v);
          },
        );
      case 'complaint':
        return DropdownButtonFormField<String>(
          value: _severity,
          decoration: const InputDecoration(
            labelText: 'Complaint Category',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'care_quality', child: Text('Care Quality')),
            DropdownMenuItem(value: 'staff_conduct', child: Text('Staff Conduct')),
            DropdownMenuItem(value: 'facilities', child: Text('Facilities')),
            DropdownMenuItem(value: 'communication', child: Text('Communication')),
            DropdownMenuItem(value: 'safeguarding', child: Text('Safeguarding')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _severity = v);
          },
        );
      case 'medication':
        return DropdownButtonFormField<String>(
          value: _severity,
          decoration: const InputDecoration(
            labelText: 'Severity',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(value: 'high', child: Text('High')),
            DropdownMenuItem(value: 'critical', child: Text('Critical')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _severity = v);
          },
        );
      case 'missing_person':
        return DropdownButtonFormField<String>(
          value: _severity,
          decoration: const InputDecoration(
            labelText: 'Risk Assessment',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low Risk')),
            DropdownMenuItem(value: 'medium', child: Text('Medium Risk')),
            DropdownMenuItem(value: 'high', child: Text('High Risk')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _severity = v);
          },
        );
      case 'serious':
        return DropdownButtonFormField<String>(
          value: _severity,
          decoration: const InputDecoration(
            labelText: 'Incident Type',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'death', child: Text('Death')),
            DropdownMenuItem(value: 'serious_injury', child: Text('Serious Injury')),
            DropdownMenuItem(value: 'abuse', child: Text('Abuse / Allegation')),
            DropdownMenuItem(value: 'police_involvement', child: Text('Police Involvement')),
            DropdownMenuItem(value: 'safeguarding_alert', child: Text('Safeguarding Alert')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _severity = v);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Type-specific extra fields ────────────────────────
  List<Widget> _buildTypeSpecificFields() {
    switch (widget.incidentType) {
      case 'accident':
        return [
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _extraFields['accident_type'] ?? 'other',
            decoration: const InputDecoration(
              labelText: 'Accident Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'fall', child: Text('Fall')),
              DropdownMenuItem(value: 'slip', child: Text('Slip')),
              DropdownMenuItem(value: 'burn', child: Text('Burn / Scald')),
              DropdownMenuItem(value: 'medication_error', child: Text('Medication Error')),
              DropdownMenuItem(value: 'equipment', child: Text('Equipment Related')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _extraFields['accident_type'] = v);
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('First Aid Given'),
            value: _extraFields['first_aid_given'] == true,
            onChanged: (v) =>
                setState(() => _extraFields['first_aid_given'] = v),
          ),
          if (_extraFields['first_aid_given'] == true)
            TextFormField(
              initialValue: _extraFields['first_aid_details']?.toString(),
              decoration: const InputDecoration(
                labelText: 'First Aid Details',
                border: OutlineInputBorder(),
              ),
              onSaved: (v) => _extraFields['first_aid_details'] = v,
            ),
          SwitchListTile(
            title: const Text('Medical Attention Sought'),
            value: _extraFields['medical_attention_sought'] == true,
            onChanged: (v) =>
                setState(() => _extraFields['medical_attention_sought'] = v),
          ),
          if (_extraFields['medical_attention_sought'] == true)
            TextFormField(
              initialValue: _extraFields['medical_provider']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Medical Provider',
                border: OutlineInputBorder(),
              ),
              onSaved: (v) => _extraFields['medical_provider'] = v,
            ),
          SwitchListTile(
            title: const Text('Family Notified'),
            value: _extraFields['reported_to_family'] == true,
            onChanged: (v) =>
                setState(() => _extraFields['reported_to_family'] = v),
          ),
        ];

      case 'complaint':
        return [
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['complainant_name']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Complainant Name',
              border: OutlineInputBorder(),
            ),
            onSaved: (v) => _extraFields['complainant_name'] = v,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _extraFields['complainant_type'] ?? 'service_user',
            decoration: const InputDecoration(
              labelText: 'Complainant Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'service_user', child: Text('Service User')),
              DropdownMenuItem(value: 'family', child: Text('Family Member')),
              DropdownMenuItem(value: 'staff', child: Text('Staff Member')),
              DropdownMenuItem(value: 'visitor', child: Text('Visitor')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _extraFields['complainant_type'] = v);
            },
          ),
        ];

      case 'medication':
        return [
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['medication_name']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Medication Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onSaved: (v) => _extraFields['medication_name'] = v?.trim(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['prescribed_dosage']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Prescribed Dosage',
              border: OutlineInputBorder(),
            ),
            onSaved: (v) => _extraFields['prescribed_dosage'] = v,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['actual_dosage']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Actual Dosage Given',
              border: OutlineInputBorder(),
            ),
            onSaved: (v) => _extraFields['actual_dosage'] = v,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: (_extraFields['incident_type']?.toString().isNotEmpty == true)
                ? _extraFields['incident_type']
                : 'wrong_medication',
            decoration: const InputDecoration(
              labelText: 'Incident Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'wrong_dose', child: Text('Wrong Dose')),
              DropdownMenuItem(value: 'missed_dose', child: Text('Missed Dose')),
              DropdownMenuItem(value: 'wrong_medication', child: Text('Wrong Medication')),
              DropdownMenuItem(value: 'wrong_time', child: Text('Wrong Time')),
              DropdownMenuItem(value: 'adverse_reaction', child: Text('Adverse Reaction')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _extraFields['incident_type'] = v);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['immediate_action']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Immediate Action Taken',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onSaved: (v) => _extraFields['immediate_action'] = v,
          ),
          SwitchListTile(
            title: const Text('Family Notified'),
            value: _extraFields['reported_to_family'] == true,
            onChanged: (v) =>
                setState(() => _extraFields['reported_to_family'] = v),
          ),
        ];

      case 'missing_person':
        return [
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['missing_time']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Time Missing',
              border: OutlineInputBorder(),
              hintText: 'e.g. 14:30',
            ),
            onSaved: (v) => _extraFields['missing_time'] = v,
          ),
          SwitchListTile(
            title: const Text('Police Informed'),
            value: _extraFields['police_informed'] == true,
            onChanged: (v) =>
                setState(() => _extraFields['police_informed'] = v),
          ),
          SwitchListTile(
            title: const Text('Family Informed'),
            value: _extraFields['family_informed'] == true,
            onChanged: (v) =>
                setState(() => _extraFields['family_informed'] = v),
          ),
        ];

      case 'serious':
        return [
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Notification Required'),
            subtitle: const Text('CQC notification within 24 hours'),
            value: _extraFields['notification_required'] != false,
            onChanged: (v) =>
                setState(() => _extraFields['notification_required'] = v),
          ),
          SwitchListTile(
            title: const Text('Police Involved'),
            value: _extraFields['police_involved'] == true,
            onChanged: (v) =>
                setState(() => _extraFields['police_involved'] = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['investigation_lead']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Investigation Lead',
              border: OutlineInputBorder(),
            ),
            onSaved: (v) => _extraFields['investigation_lead'] = v,
          ),
        ];

      case 'missing_item':
        return [
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['item_description']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Item Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onSaved: (v) => _extraFields['item_description'] = v,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['item_value']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Estimated Value (£)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSaved: (v) => _extraFields['item_value'] = v,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _extraFields['circumstances']?.toString(),
            decoration: const InputDecoration(
              labelText: 'Circumstances',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onSaved: (v) => _extraFields['circumstances'] = v,
          ),
          SwitchListTile(
            title: const Text('Police Informed'),
            value: _extraFields['police_informed'] == true,
            onChanged: (v) =>
                setState(() => _extraFields['police_informed'] = v),
          ),
        ];

      default:
        return [];
    }
  }

  // ─── Helpers ──────────────────────────────────────────
  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}