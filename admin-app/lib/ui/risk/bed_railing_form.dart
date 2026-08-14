import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BedRailingForm extends StatefulWidget {
  final String? serviceUserId;

  const BedRailingForm({super.key, this.serviceUserId});

  @override
  State<BedRailingForm> createState() => _BedRailingFormState();
}

class _BedRailingFormState extends State<BedRailingForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  DateTime _assessmentDate = DateTime.now();
  String _bedType = 'standard';
  String _bedRailsType = 'half';
  String _railCondition = 'good';
  bool _manufacturerInstructionsAvailable = true;
  String _railHeightAndFit = 'correct';
  bool _entrapmentRiskAssessed = false;
  String _patientMobility = 'independent';
  bool _cognitiveImpairment = false;
  bool _agitationRestlessness = false;
  bool _alternativeMeasuresConsidered = false;
  bool _familyConsentObtained = false;
  bool _staffTrainedInBedRailUse = false;
  bool _railRegularlyChecked = false;
  DateTime? _lastCheckDate;
  DateTime? _nextCheckDate;
  String? _actionPlan;
  DateTime? _reviewDate;

  final List<String> _bedTypes = ['standard', 'profiling', 'hospital', 'other'];
  final List<String> _bedRailsTypes = ['full', 'half', 'mobile', 'other'];
  final List<String> _railConditions = ['good', 'worn', 'damaged'];
  final List<String> _railHeightOptions = ['correct', 'incorrect'];
  final List<String> _mobilityOptions = ['independent', 'assisted', 'bedbound'];

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

  String _calculateFallRisk() {
    int score = 0;
    // Mobility: bedbound = higher risk
    if (_patientMobility == 'assisted') score += 2;
    if (_patientMobility == 'bedbound') score += 3;
    // Cognitive impairment
    if (_cognitiveImpairment) score += 3;
    // Agitation/restlessness
    if (_agitationRestlessness) score += 3;
    // Rail height incorrect
    if (_railHeightAndFit == 'incorrect') score += 2;
    // Rail condition worn/damaged
    if (_railCondition == 'worn') score += 1;
    if (_railCondition == 'damaged') score += 3;
    // No entrapment assessment
    if (!_entrapmentRiskAssessed) score += 2;
    // No family consent
    if (!_familyConsentObtained) score += 1;
    // No regular checks
    if (!_railRegularlyChecked) score += 1;

    if (score >= 8) return 'high';
    if (score >= 4) return 'medium';
    return 'low';
  }

  String _calculateEntrapmentRisk() {
    int score = 0;
    // Rail type: full rails = higher risk
    if (_bedRailsType == 'full') score += 2;
    // Rail condition
    if (_railCondition == 'worn') score += 1;
    if (_railCondition == 'damaged') score += 3;
    // Rail height incorrect
    if (_railHeightAndFit == 'incorrect') score += 2;
    // No manufacturer instructions
    if (!_manufacturerInstructionsAvailable) score += 2;
    // No entrapment assessment
    if (!_entrapmentRiskAssessed) score += 3;
    // Staff not trained
    if (!_staffTrainedInBedRailUse) score += 2;

    if (score >= 8) return 'high';
    if (score >= 4) return 'medium';
    return 'low';
  }

  String _calculateOverallRisk() {
    final fallRisk = _calculateFallRisk();
    final entrapmentRisk = _calculateEntrapmentRisk();

    if (fallRisk == 'high' || entrapmentRisk == 'high') return 'high';
    if (fallRisk == 'medium' || entrapmentRisk == 'medium') return 'medium';
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _assessmentDate,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _assessmentDate = picked);
  }

  Future<void> _selectLastCheckDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _lastCheckDate ?? DateTime.now(),
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _lastCheckDate = picked);
  }

  Future<void> _selectNextCheckDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _nextCheckDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _nextCheckDate = picked);
  }

  Future<void> _selectReviewDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _reviewDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
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
        await Supabase.instance.client.from('bed_railing_risk_assessments').insert({
          'service_user_id': _selectedServiceUserId,
          'assessment_date': _assessmentDate.toIso8601String(),
          'bed_type': _bedType,
          'bed_rails_type': _bedRailsType,
          'rail_condition': _railCondition,
          'manufacturer_instructions_available': _manufacturerInstructionsAvailable,
          'rail_height_and_fit': _railHeightAndFit,
          'entrapment_risk_assessed': _entrapmentRiskAssessed,
          'patient_mobility': _patientMobility,
          'cognitive_impairment': _cognitiveImpairment,
          'agitation_restlessness': _agitationRestlessness,
          'risk_of_falling_out_of_bed': _calculateFallRisk(),
          'risk_of_entrapment': _calculateEntrapmentRisk(),
          'overall_risk_level': _calculateOverallRisk(),
          'alternative_measures_considered': _alternativeMeasuresConsidered,
          'family_consent_obtained': _familyConsentObtained,
          'staff_trained_in_bed_rail_use': _staffTrainedInBedRailUse,
          'rail_regularly_checked': _railRegularlyChecked,
          'last_check_date': _lastCheckDate?.toIso8601String(),
          'next_check_date': _nextCheckDate?.toIso8601String(),
          'action_plan': _actionPlan,
          'review_date': _reviewDate?.toIso8601String(),
          'assessor_name': 'Current User',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment completed successfully')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)));
  }

  Widget _buildDateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_today)),
      child: Text(date != null ? '${date.day}/${date.month}/${date.year}' : 'Select date'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bed Railing Risk Assessment')),
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
        _buildDateTile('Assessment Date', _assessmentDate, _selectDate),
        const SizedBox(height: 16),

        // Bed Type
        _buildSectionTitle('Bed Type'),
        DropdownButtonFormField<String>(value: _bedType, decoration: const InputDecoration(labelText: 'Bed Type'),
          items: _bedTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.capitalize()))).toList(),
          onChanged: (v) => setState(() => _bedType = v!)),
        const SizedBox(height: 16),

        // Bed Rails Type
        _buildSectionTitle('Bed Rails Type'),
        DropdownButtonFormField<String>(value: _bedRailsType, decoration: const InputDecoration(labelText: 'Bed Rails Type'),
          items: _bedRailsTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.capitalize()))).toList(),
          onChanged: (v) => setState(() => _bedRailsType = v!)),
        const SizedBox(height: 16),

        // Rail Condition
        _buildSectionTitle('Rail Condition'),
        DropdownButtonFormField<String>(value: _railCondition, decoration: const InputDecoration(labelText: 'Rail Condition'),
          items: _railConditions.map((c) => DropdownMenuItem(value: c, child: Text(c.capitalize()))).toList(),
          onChanged: (v) => setState(() => _railCondition = v!)),
        const SizedBox(height: 16),

        // Manufacturer Instructions
        SwitchListTile(title: const Text('Manufacturer instructions available'),
          value: _manufacturerInstructionsAvailable, onChanged: (v) => setState(() => _manufacturerInstructionsAvailable = v)),
        const SizedBox(height: 8),

        // Rail Height and Fit
        DropdownButtonFormField<String>(value: _railHeightAndFit, decoration: const InputDecoration(labelText: 'Rail Height and Fit'),
          items: _railHeightOptions.map((o) => DropdownMenuItem(value: o, child: Text(o.capitalize()))).toList(),
          onChanged: (v) => setState(() => _railHeightAndFit = v!)),
        const SizedBox(height: 16),

        // Entrapment Risk Assessed
        SwitchListTile(title: const Text('Entrapment risk assessed'),
          value: _entrapmentRiskAssessed, onChanged: (v) => setState(() => _entrapmentRiskAssessed = v)),
        const SizedBox(height: 16),

        // Patient Mobility
        _buildSectionTitle('Patient Mobility'),
        DropdownButtonFormField<String>(value: _patientMobility, decoration: const InputDecoration(labelText: 'Mobility Level'),
          items: _mobilityOptions.map((m) => DropdownMenuItem(value: m, child: Text(m == 'assisted' ? 'Requires Assistance' : m.capitalize()))).toList(),
          onChanged: (v) => setState(() => _patientMobility = v!)),
        const SizedBox(height: 16),

        // Cognitive Impairment & Agitation
        SwitchListTile(title: const Text('Cognitive impairment'),
          value: _cognitiveImpairment, onChanged: (v) => setState(() => _cognitiveImpairment = v)),
        SwitchListTile(title: const Text('Agitation/restlessness'),
          value: _agitationRestlessness, onChanged: (v) => setState(() => _agitationRestlessness = v)),
        const SizedBox(height: 16),

        // Auto-calculated Risk Assessment (Read-only display)
        _buildSectionTitle('Auto-Calculated Risk Assessment'),
        Card(
          color: _getRiskColor(_calculateFallRisk()).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_getRiskIcon(_calculateFallRisk()), color: _getRiskColor(_calculateFallRisk())),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fall Risk', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _calculateFallRisk().toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(_calculateFallRisk()),
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
        Card(
          color: _getRiskColor(_calculateEntrapmentRisk()).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_getRiskIcon(_calculateEntrapmentRisk()), color: _getRiskColor(_calculateEntrapmentRisk())),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Entrapment Risk', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _calculateEntrapmentRisk().toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(_calculateEntrapmentRisk()),
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
        Card(
          color: _getRiskColor(_calculateOverallRisk()).withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_getRiskIcon(_calculateOverallRisk()), color: _getRiskColor(_calculateOverallRisk()), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overall Risk Level (Auto-calculated)', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _calculateOverallRisk().toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(_calculateOverallRisk()),
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

        // Alternative Measures & Family Consent
        SwitchListTile(title: const Text('Alternative measures considered'),
          value: _alternativeMeasuresConsidered, onChanged: (v) => setState(() => _alternativeMeasuresConsidered = v)),
        SwitchListTile(title: const Text('Family consent obtained'),
          value: _familyConsentObtained, onChanged: (v) => setState(() => _familyConsentObtained = v)),
        const SizedBox(height: 16),

        // Staff Training & Regular Checks
        SwitchListTile(title: const Text('Staff trained in bed rail use'),
          value: _staffTrainedInBedRailUse, onChanged: (v) => setState(() => _staffTrainedInBedRailUse = v)),
        SwitchListTile(title: const Text('Rail regularly checked'),
          value: _railRegularlyChecked, onChanged: (v) => setState(() => _railRegularlyChecked = v)),
        const SizedBox(height: 16),

        // Check Dates
        Row(children: [
          Expanded(child: _buildDateTile('Last Check Date', _lastCheckDate, _selectLastCheckDate)),
          const SizedBox(width: 16),
          Expanded(child: _buildDateTile('Next Check Date', _nextCheckDate, _selectNextCheckDate)),
        ]),
        const SizedBox(height: 16),

        // Action Plan
        TextFormField(decoration: const InputDecoration(labelText: 'Action Plan'), maxLines: 3, onChanged: (v) => _actionPlan = v),
        const SizedBox(height: 16),

        // Review Date
        _buildDateTile('Review Date', _reviewDate, _selectReviewDate),
        const SizedBox(height: 24),

        // Submit
        ElevatedButton(onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _isSubmitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit Assessment', style: TextStyle(fontSize: 16))),
      ])),
    );
  }
}

extension StringExt on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}