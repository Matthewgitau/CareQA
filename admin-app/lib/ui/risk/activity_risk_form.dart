import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/activity_risk_assessment.dart';
import 'package:admin_app/services/activity_risk_service.dart';

class ActivityRiskForm extends StatefulWidget {
  final String? assessmentId;
  final String? serviceUserId;
  final String? assessorId;
  const ActivityRiskForm({super.key, this.assessmentId, this.serviceUserId, this.assessorId});
  @override
  State<ActivityRiskForm> createState() => _ActivityRiskFormState();
}

class _ActivityRiskFormState extends State<ActivityRiskForm> {
  final _service = ActivityRiskService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _emergencyController = TextEditingController();
  final _notesController = TextEditingController();
  final _assessorNameController = TextEditingController();
  final _signatureController = TextEditingController();

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  ActivityType? _activityType;
  FrequencyType? _frequency;
  SupportLevelType? _supportLevel;
  DateTime? _reviewDate;
  String _riskLevel = 'low';
  List<String> _equipmentRequired = [];
  List<String> _identifiedRisks = [];
  List<String> _controlMeasures = [];
  List<String> _staffCompetencyRequired = [];
  bool _loading = false;
  bool _isEditing = false;
  bool _signatureConfirmed = false;

  // Assessment date
  DateTime _assessmentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    if (widget.assessmentId != null) _loadAssessment();
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
    } catch (e) {
      setState(() => _loadingUsers = false);
    }
  }

  @override
  void dispose() {
    _emergencyController.dispose();
    _notesController.dispose();
    _assessorNameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _loadAssessment() async {
    setState(() => _loading = true);
    try {
      final a = await _service.getAssessment(widget.assessmentId!);
      setState(() {
        _selectedServiceUserId = a.serviceUserId;
        _activityType = a.activityType;
        _frequency = a.frequency;
        _supportLevel = a.supportLevel;
        _reviewDate = a.reviewDate;
        _riskLevel = a.riskLevel;
        _equipmentRequired = a.equipmentRequired;
        _identifiedRisks = a.identifiedRisks;
        _controlMeasures = a.controlMeasures;
        _staffCompetencyRequired = a.staffCompetencyRequired;
        _emergencyController.text = a.emergencyProcedures;
        _notesController.text = a.notes ?? '';
        _isEditing = true;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      if (mounted) Navigator.pop(context);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAssessmentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _assessmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _assessmentDate = picked);
  }

  String _calculateRiskLevel() {
    int riskScore = 0;

    // Frequency scoring
    switch (_frequency) {
      case FrequencyType.daily: riskScore += 4; break;
      case FrequencyType.weekly: riskScore += 3; break;
      case FrequencyType.monthly: riskScore += 2; break;
      case FrequencyType.occasionally: riskScore += 1; break;
      default: riskScore += 0;
    }

    // Support level scoring
    switch (_supportLevel) {
      case SupportLevelType.independent: riskScore += 1; break;
      case SupportLevelType.supervision: riskScore += 2; break;
      case SupportLevelType.assistance: riskScore += 3; break;
      case SupportLevelType.fullAssistance: riskScore += 4; break;
      default: riskScore += 0;
    }

    // Number of identified risks
    riskScore += _identifiedRisks.length;

    // Equipment complexity
    riskScore += _equipmentRequired.length ~/ 2;

    // Risk level determination
    if (riskScore >= 10) return 'high';
    if (riskScore >= 5) return 'medium';
    return 'low';
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getRiskIcon(String level) {
    switch (level) {
      case 'high': return Icons.warning;
      case 'medium': return Icons.info;
      case 'low': return Icons.check_circle;
      default: return Icons.help;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service user')));
      return;
    }
    if (_activityType == null || _frequency == null || _supportLevel == null || _reviewDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields')));
      return;
    }
    setState(() => _loading = true);
    try {
      final serviceUserName = _serviceUsers
          .firstWhere((u) => u['id'] == _selectedServiceUserId)['name'] as String;

      final assessmentData = <String, dynamic>{
        'service_user_name': serviceUserName,
        'assessor_name': _assessorNameController.text,
        'assessment_date': _assessmentDate.toIso8601String().split('T').first,
        'risk_score': _calculateRiskLevel() == 'high' ? 10 : (_calculateRiskLevel() == 'medium' ? 5 : 0),
        if (_signatureConfirmed && _signatureController.text.isNotEmpty)
          'assessor_signature': _signatureController.text,
      };

      final assessment = ActivityRiskAssessment(
        serviceUserId: _selectedServiceUserId!,
        assessorId: widget.assessorId ?? Supabase.instance.client.auth.currentUser?.id ?? '',
        activityType: _activityType!,
        frequency: _frequency!,
        supportLevel: _supportLevel!,
        equipmentRequired: _equipmentRequired,
        identifiedRisks: _identifiedRisks,
        riskLevel: _calculateRiskLevel(),
        controlMeasures: _controlMeasures,
        staffCompetencyRequired: _staffCompetencyRequired,
        emergencyProcedures: _emergencyController.text,
        reviewDate: _reviewDate!,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        assessmentData: assessmentData,
      );
      if (_isEditing) {
        await _service.updateAssessment(widget.assessmentId!, assessment);
      } else {
        await _service.createAssessment(assessment);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment saved')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addToList(List<String> list, TextEditingController ctrl) {
    if (ctrl.text.trim().isNotEmpty) {
      setState(() { list.add(ctrl.text.trim()); ctrl.clear(); });
    }
  }

  Widget _buildListSection(String title, List<String> items, TextEditingController ctrl) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(controller: ctrl, decoration: InputDecoration(labelText: 'Add item', border: const OutlineInputBorder()))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () => _addToList(items, ctrl), child: const Text('Add')),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: items.map((item) =>
              Chip(label: Text(item), onDeleted: () => setState(() => items.remove(item)))).toList()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Activity Risk Assessment' : 'New Activity Risk Assessment'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                      items: _serviceUsers.map((user) {
                        return DropdownMenuItem(
                          value: user['id'] as String,
                          child: Text(user['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedServiceUserId = value),
                      validator: (value) => value == null ? 'Please select a service user' : null,
                    ),
                  const SizedBox(height: 16),

                  // Assessment Date
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Assessment Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickAssessmentDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text('${_assessmentDate.day}/${_assessmentDate.month}/${_assessmentDate.year}'),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Activity Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Activity Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ActivityType>(
                          value: _activityType,
                          decoration: const InputDecoration(labelText: 'Activity Type *', border: OutlineInputBorder()),
                          items: ActivityType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                          onChanged: (v) => setState(() => _activityType = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<FrequencyType>(
                          value: _frequency,
                          decoration: const InputDecoration(labelText: 'Frequency *', border: OutlineInputBorder()),
                          items: FrequencyType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                          onChanged: (v) => setState(() => _frequency = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<SupportLevelType>(
                          value: _supportLevel,
                          decoration: const InputDecoration(labelText: 'Support Level *', border: OutlineInputBorder()),
                          items: SupportLevelType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                          onChanged: (v) => setState(() => _supportLevel = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 180)), firstDate: DateTime.now(), lastDate: DateTime(2030));
                            if (d != null) setState(() => _reviewDate = d);
                          },
                          child: Text(_reviewDate != null ? 'Review: ${_reviewDate!.toString().split(' ').first}' : 'Select Review Date *'),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Risk Level Display (Auto-calculated)
                  Card(
                    color: _getRiskColor(_calculateRiskLevel()).withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(_getRiskIcon(_calculateRiskLevel()), color: _getRiskColor(_calculateRiskLevel())),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Auto-calculated Risk Level', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  _calculateRiskLevel().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getRiskColor(_calculateRiskLevel()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildListSection('Equipment Required', _equipmentRequired, TextEditingController()),
                  _buildListSection('Identified Risks', _identifiedRisks, TextEditingController()),
                  _buildListSection('Control Measures', _controlMeasures, TextEditingController()),
                  _buildListSection('Staff Competency Required', _staffCompetencyRequired, TextEditingController()),

                  // Emergency Procedures
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Emergency Procedures', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(controller: _emergencyController, decoration: const InputDecoration(border: OutlineInputBorder()), maxLines: 3),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Additional Notes
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Additional Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(controller: _notesController, decoration: const InputDecoration(border: OutlineInputBorder()), maxLines: 3),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Assessor Name
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Assessor', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _assessorNameController,
                          decoration: const InputDecoration(labelText: 'Assessor Name', border: OutlineInputBorder()),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Signature Confirmation
                  Card(
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('I confirm this assessment is accurate'),
                          value: _signatureConfirmed,
                          onChanged: (v) => setState(() => _signatureConfirmed = v ?? false),
                        ),
                        if (_signatureConfirmed)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextField(
                              controller: _signatureController,
                              decoration: const InputDecoration(
                                labelText: 'Assessor Signature (type your name)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(_isEditing ? 'Update Assessment' : 'Save Assessment'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}