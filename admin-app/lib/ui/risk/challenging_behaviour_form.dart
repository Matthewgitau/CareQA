import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengingBehaviourForm extends StatefulWidget {
  final String? serviceUserId;

  const ChallengingBehaviourForm({super.key, this.serviceUserId});

  @override
  State<ChallengingBehaviourForm> createState() => _ChallengingBehaviourFormState();
}

class _ChallengingBehaviourFormState extends State<ChallengingBehaviourForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  DateTime _assessmentDate = DateTime.now();
  String _behaviourType = 'aggression';
  String _behaviourFrequency = 'daily';
  int _behaviourDurationMinutes = 0;
  String _intensity = 'moderate';
  List<String> _triggers = [];
  List<String> _warningSigns = [];
  List<String> _deEscalationStrategies = [];
  String _medicationUsed = 'none';
  String _injuriesCaused = 'none';
  bool _injuriesToSelf = false;
  bool _injuriesToOthers = false;
  bool _propertyDamage = false;
  bool _staffTrainedDeEscalation = false;
  bool _pbsPlanInPlace = false;
  String? _environmentalModificationsNeeded;
  String _supportNeeds = 'none';
  String? _actionPlan;
  DateTime? _reviewDate;

  final List<String> _behaviourTypes = [
    'aggression', 'self_harm', 'wandering', 'sexual',
    'inappropriate', 'vocal', 'withdrawal'
  ];
  final List<String> _frequencies = ['hourly', 'daily', 'weekly', 'monthly'];
  final List<String> _intensities = ['mild', 'moderate', 'severe'];
  final List<String> _medicationOptions = ['none', 'prn', 'regular'];
  final List<String> _supportOptions = ['none', '1:1', '2:1', 'specialist'];

  final List<String> _triggerOptionLabels = [
    'Noise', 'Change in routine', 'Pain/discomfort',
    'Social interaction', 'Environmental', 'Other',
  ];
  final List<String> _warningSignOptionLabels = [
    'Agitation', 'Pacing', 'Verbal threats',
    'Clenched fists', 'Raised voice', 'Withdrawal',
  ];
  final List<String> _deEscalationOptionLabels = [
    'Calm approach', 'Distraction', 'Give space',
    'Reassurance', 'Remove triggers', 'PRN medication',
  ];

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
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

  Color _getRiskColor(String level) {
    switch (level) {
      case 'critical': return Colors.red[900]!;
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getRiskIcon(String level) {
    switch (level) {
      case 'critical': return Icons.gpp_bad;
      case 'high': return Icons.warning;
      case 'medium': return Icons.info;
      case 'low': return Icons.check_circle;
      default: return Icons.help;
    }
  }

  String _calculateRiskLevel() {
    int score = 0;

    // Intensity scoring
    switch (_intensity) {
      case 'mild': score += 1; break;
      case 'moderate': score += 2; break;
      case 'severe': score += 4; break;
    }

    // Frequency scoring
    switch (_behaviourFrequency) {
      case 'hourly': score += 4; break;
      case 'daily': score += 3; break;
      case 'weekly': score += 2; break;
      case 'monthly': score += 1; break;
    }

    // Duration scoring
    if (_behaviourDurationMinutes >= 60) score += 3;
    else if (_behaviourDurationMinutes >= 30) score += 2;
    else if (_behaviourDurationMinutes >= 15) score += 1;

    // Injuries
    if (_injuriesToSelf) score += 3;
    if (_injuriesToOthers) score += 4;
    if (_propertyDamage) score += 2;

    // Support needs
    switch (_supportNeeds) {
      case '1:1': score += 2; break;
      case '2:1': score += 3; break;
      case 'specialist': score += 4; break;
    }

    // Medication
    if (_medicationUsed == 'prn') score += 1;
    if (_medicationUsed == 'regular') score += 2;

    // Protective factors (reduce risk)
    if (_pbsPlanInPlace) score -= 1;
    if (_staffTrainedDeEscalation) score -= 1;
    if (_deEscalationStrategies.isNotEmpty) score -= 1;

    // Risk level determination
    if (score >= 10) return 'critical';
    if (score >= 7) return 'high';
    if (score >= 4) return 'medium';
    return 'low';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _assessmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _assessmentDate = picked);
  }

  Future<void> _selectReviewDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _reviewDate = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedServiceUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a service user')),
        );
        return;
      }
      setState(() => _isSubmitting = true);

      try {
        await Supabase.instance.client.from('challenging_behaviour_risk_assessments').insert({
          'service_user_id': _selectedServiceUserId,
          'assessment_date': _assessmentDate.toIso8601String(),
          'behaviour_type': _behaviourType,
          'behaviour_frequency': _behaviourFrequency,
          'behaviour_duration_minutes': _behaviourDurationMinutes,
          'intensity': _intensity,
          'triggers': _triggers,
          'warning_signs': _warningSigns,
          'de_escalation_strategies': _deEscalationStrategies,
          'medication_used': _medicationUsed,
          'injuries_caused': _injuriesCaused,
          'injuries_to_self': _injuriesToSelf,
          'injuries_to_others': _injuriesToOthers,
          'property_damage': _propertyDamage,
          'staff_trained_de_escalation': _staffTrainedDeEscalation,
          'pbs_plan_in_place': _pbsPlanInPlace,
          'environmental_modifications_needed': _environmentalModificationsNeeded,
          'support_needs': _supportNeeds,
          'risk_level': _calculateRiskLevel(),
          'action_plan': _actionPlan,
          'review_date': _reviewDate?.toIso8601String(),
          'assessor_name': 'Current User',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assessment completed successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  Widget _buildCheckboxGroup(List<String> labels, List<String> selectedList, Function(String, bool) onChanged) {
    return Column(
      children: labels.map((label) {
        return CheckboxListTile(
          title: Text(label),
          value: selectedList.contains(label),
          onChanged: (value) {
            onChanged(label, value ?? false);
            setState(() {});
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = _calculateRiskLevel();
    return Scaffold(
      appBar: AppBar(title: const Text('Challenging Behaviour Assessment')),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
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
        InkWell(onTap: _selectDate, child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Assessment Date', prefixIcon: Icon(Icons.calendar_today)),
          child: Text('${_assessmentDate.day}/${_assessmentDate.month}/${_assessmentDate.year}'),
        )),
        const SizedBox(height: 16),

        // Behaviour Type
        _buildSectionTitle('Behaviour Type'),
        DropdownButtonFormField<String>(
          value: _behaviourType,
          decoration: const InputDecoration(labelText: 'Type'),
          items: _behaviourTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').capitalize()))).toList(),
          onChanged: (v) => setState(() => _behaviourType = v!),
        ),
        const SizedBox(height: 16),

        // Frequency
        _buildSectionTitle('Frequency'),
        DropdownButtonFormField<String>(
          value: _behaviourFrequency,
          decoration: const InputDecoration(labelText: 'Frequency'),
          items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f.capitalize()))).toList(),
          onChanged: (v) => setState(() => _behaviourFrequency = v!),
        ),
        const SizedBox(height: 16),

        // Duration
        TextFormField(
          initialValue: _behaviourDurationMinutes.toString(),
          decoration: const InputDecoration(labelText: 'Duration (minutes)', prefixIcon: Icon(Icons.timer)),
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _behaviourDurationMinutes = int.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 16),

        // Intensity
        _buildSectionTitle('Intensity'),
        DropdownButtonFormField<String>(
          value: _intensity,
          decoration: const InputDecoration(labelText: 'Intensity'),
          items: _intensities.map((i) => DropdownMenuItem(value: i, child: Text(i.capitalize()))).toList(),
          onChanged: (v) => setState(() => _intensity = v!),
        ),
        const SizedBox(height: 16),

        // Triggers
        _buildSectionTitle('Triggers'),
        _buildCheckboxGroup(_triggerOptionLabels, _triggers, (key, value) {
          if (value) { _triggers.add(key); } else { _triggers.remove(key); }
        }),
        const SizedBox(height: 16),

        // Warning Signs
        _buildSectionTitle('Warning Signs'),
        _buildCheckboxGroup(_warningSignOptionLabels, _warningSigns, (key, value) {
          if (value) { _warningSigns.add(key); } else { _warningSigns.remove(key); }
        }),
        const SizedBox(height: 16),

        // De-escalation Strategies
        _buildSectionTitle('De-escalation Strategies'),
        _buildCheckboxGroup(_deEscalationOptionLabels, _deEscalationStrategies, (key, value) {
          if (value) { _deEscalationStrategies.add(key); } else { _deEscalationStrategies.remove(key); }
        }),
        const SizedBox(height: 16),

        // Medication Used
        _buildSectionTitle('Medication'),
        DropdownButtonFormField<String>(
          value: _medicationUsed,
          decoration: const InputDecoration(labelText: 'Medication Used'),
          items: _medicationOptions.map((m) => DropdownMenuItem(value: m, child: Text(m == 'prn' ? 'PRN (As Needed)' : m.capitalize()))).toList(),
          onChanged: (v) => setState(() => _medicationUsed = v!),
        ),
        const SizedBox(height: 16),

        // Injuries
        _buildSectionTitle('Injuries'),
        SwitchListTile(title: const Text('Injuries to self'), value: _injuriesToSelf, onChanged: (v) => setState(() => _injuriesToSelf = v)),
        SwitchListTile(title: const Text('Injuries to others'), value: _injuriesToOthers, onChanged: (v) => setState(() => _injuriesToOthers = v)),
        SwitchListTile(title: const Text('Property damage'), value: _propertyDamage, onChanged: (v) => setState(() => _propertyDamage = v)),
        const SizedBox(height: 16),

        // PBS Plan
        _buildSectionTitle('PBS Plan'),
        SwitchListTile(title: const Text('PBS Plan in place'), value: _pbsPlanInPlace, onChanged: (v) => setState(() => _pbsPlanInPlace = v)),
        SwitchListTile(title: const Text('Staff trained in de-escalation'), value: _staffTrainedDeEscalation, onChanged: (v) => setState(() => _staffTrainedDeEscalation = v)),
        const SizedBox(height: 16),

        // Environmental Modifications
        TextFormField(
          decoration: const InputDecoration(labelText: 'Environmental modifications needed'),
          onChanged: (v) => _environmentalModificationsNeeded = v,
        ),
        const SizedBox(height: 16),

        // Support Needs
        _buildSectionTitle('Support Needs'),
        DropdownButtonFormField<String>(
          value: _supportNeeds,
          decoration: const InputDecoration(labelText: 'Support needs'),
          items: _supportOptions.map((s) => DropdownMenuItem(value: s, child: Text(s == '1:1' ? '1:1 Support' : s == '2:1' ? '2:1 Support' : s.capitalize()))).toList(),
          onChanged: (v) => setState(() => _supportNeeds = v!),
        ),
        const SizedBox(height: 16),

        // Auto-calculated Risk Level (Read-only display)
        _buildSectionTitle('Overall Risk Level'),
        Card(
          color: _getRiskColor(riskLevel).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_getRiskIcon(riskLevel), color: _getRiskColor(riskLevel), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Auto-calculated Risk Level', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        riskLevel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(riskLevel),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Action Plan
        TextFormField(
          decoration: const InputDecoration(labelText: 'Action plan'),
          maxLines: 3,
          onChanged: (v) => _actionPlan = v,
        ),
        const SizedBox(height: 16),

        // Review Date
        InkWell(onTap: _selectReviewDate, child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Review date', prefixIcon: Icon(Icons.calendar_today)),
          child: Text(_reviewDate != null ? '${_reviewDate!.day}/${_reviewDate!.month}/${_reviewDate!.year}' : 'Select date'),
        )),
        const SizedBox(height: 24),

        // Submit
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _isSubmitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit Assessment', style: TextStyle(fontSize: 16)),
        ),
      ])),
    );
  }
}

extension StringExt on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}