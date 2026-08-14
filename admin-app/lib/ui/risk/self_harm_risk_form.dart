import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelfHarmRiskForm extends StatefulWidget {
  final String? serviceUserId;

  const SelfHarmRiskForm({super.key, this.serviceUserId});

  @override
  State<SelfHarmRiskForm> createState() => _SelfHarmRiskFormState();
}

class _SelfHarmRiskFormState extends State<SelfHarmRiskForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  // Current suicidal ideation
  String _currentSuicidalIdeation = 'never';
  String? _currentSuicidalIdeationDetails;

  // Previous self-harm attempts
  int _previousAttempts = 0;
  String? _previousAttemptsDetails;

  // Method of self-harm
  String? _selfHarmMethod;
  String? _selfHarmMethodOther;
  bool _methodPlanned = false;

  // Frequency of thoughts
  String? _frequencyOfThoughts;

  // Triggers
  bool _relationshipTriggers = false;
  bool _financialTriggers = false;
  bool _healthTriggers = false;
  bool _otherTriggers = false;
  String? _triggerDetails;

  // Protective factors
  bool _familySupport = false;
  bool _friendSupport = false;
  bool _routineStructure = false;
  bool _otherProtectiveFactors = false;
  String? _protectiveFactorsDetails;

  // Risk factors
  bool _accessToMeans = false;
  String? _accessToMeansDetails;
  String? _mentalHealthDiagnosis;
  String? _currentTreatment;
  String? _treatmentDetails;

  // Recent life events
  String? _recentLifeEvents;
  String? _substanceUse;
  String? _substanceDetails;

  // Behavioral indicators
  bool _sleepDisturbances = false;
  bool _withdrawalFromActivities = false;
  bool _givingAwayPossessions = false;
  bool _makingPlansArrangements = false;

  // Risk assessment
  List<String> _riskFactorsIdentified = [];
  List<String> _protectiveFactorsIdentified = [];

  // Action plan
  bool _immediateActionsRequired = false;
  String? _immediateActions;
  String? _followUpActions;
  String? _crisisContacts;
  DateTime? _nextReviewDate;

  final List<String> _suicidalIdeationOptions = ['never', 'sometimes', 'frequently', 'constant'];
  final List<String> _frequencyOptions = ['never', 'rarely', 'sometimes', 'often', 'constant'];
  final List<String> _methodOptions = ['cutting', 'overdose', 'hanging', 'jumping', 'other'];
  final List<String> _treatmentOptions = ['none', 'medication', 'therapy', 'both'];
  final List<String> _substanceUseOptions = ['none', 'occasional', 'regular', 'problematic'];

  String _calculateRiskLevel() {
    int riskScore = 0;

    // Suicidal ideation (weighted heavily)
    switch (_currentSuicidalIdeation) {
      case 'never': riskScore += 0; break;
      case 'sometimes': riskScore += 2; break;
      case 'frequently': riskScore += 4; break;
      case 'constant': riskScore += 6; break;
    }

    // Frequency of thoughts
    switch (_frequencyOfThoughts) {
      case 'never': riskScore += 0; break;
      case 'rarely': riskScore += 1; break;
      case 'sometimes': riskScore += 2; break;
      case 'often': riskScore += 4; break;
      case 'constant': riskScore += 6; break;
    }

    // Previous attempts
    if (_previousAttempts >= 1) riskScore += 2;
    if (_previousAttempts >= 3) riskScore += 2;

    // Method planned
    if (_methodPlanned) riskScore += 3;

    // Access to means
    if (_accessToMeans) riskScore += 3;

    // Recent life events
    if (_recentLifeEvents != null && _recentLifeEvents!.isNotEmpty) riskScore += 2;

    // Substance use
    switch (_substanceUse) {
      case 'occasional': riskScore += 1; break;
      case 'regular': riskScore += 2; break;
      case 'problematic': riskScore += 3; break;
    }

    // Behavioral indicators
    if (_sleepDisturbances) riskScore += 1;
    if (_withdrawalFromActivities) riskScore += 1;
    if (_givingAwayPossessions) riskScore += 2;
    if (_makingPlansArrangements) riskScore += 2;

    // Protective factors (reduce risk)
    int protectiveCount = 0;
    if (_familySupport) protectiveCount++;
    if (_friendSupport) protectiveCount++;
    if (_routineStructure) protectiveCount++;
    if (_otherProtectiveFactors) protectiveCount++;
    if (protectiveCount >= 2) riskScore -= 2;

    // Risk level determination
    if (riskScore >= 12) return 'immediate';
    if (riskScore >= 8) return 'high';
    if (riskScore >= 4) return 'medium';
    return 'low';
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'immediate': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow[700]!;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getRiskIcon(String level) {
    switch (level) {
      case 'immediate': return Icons.warning_amber_rounded;
      case 'high': return Icons.warning;
      case 'medium': return Icons.info;
      case 'low': return Icons.check_circle;
      default: return Icons.help;
    }
  }

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

  Future<void> _selectReviewDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _nextReviewDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedServiceUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a service user')),
        );
        return;
      }

      final autoRiskLevel = _calculateRiskLevel();

      setState(() => _isSubmitting = true);

      try {
        await Supabase.instance.client.from('self_harm_assessments').insert({
          'service_user_id': _selectedServiceUserId,
          'assessor_id': Supabase.instance.client.auth.currentUser?.id,
          'current_suicidal_ideation': _currentSuicidalIdeation,
          'current_suicidal_ideation_details': _currentSuicidalIdeationDetails,
          'previous_self_harm_attempts': _previousAttempts,
          'previous_self_harm_details': _previousAttemptsDetails,
          'self_harm_method': _selfHarmMethod,
          'self_harm_method_other': _selfHarmMethodOther,
          'method_planned': _methodPlanned,
          'frequency_of_thoughts': _frequencyOfThoughts,
          'relationship_triggers': _relationshipTriggers,
          'financial_triggers': _financialTriggers,
          'health_triggers': _healthTriggers,
          'other_triggers': _otherTriggers,
          'trigger_details': _triggerDetails,
          'family_support': _familySupport,
          'friend_support': _friendSupport,
          'routine_structure': _routineStructure,
          'other_protective_factors': _otherProtectiveFactors,
          'protective_factors_details': _protectiveFactorsDetails,
          'access_to_means': _accessToMeans,
          'access_to_means_details': _accessToMeansDetails,
          'mental_health_diagnosis': _mentalHealthDiagnosis,
          'current_treatment': _currentTreatment,
          'treatment_details': _treatmentDetails,
          'recent_life_events': _recentLifeEvents,
          'substance_use': _substanceUse,
          'substance_details': _substanceDetails,
          'sleep_disturbances': _sleepDisturbances,
          'withdrawal_from_activities': _withdrawalFromActivities,
          'giving_away_possessions': _givingAwayPossessions,
          'making_plans_arrangements': _makingPlansArrangements,
          'overall_risk_level': autoRiskLevel,
          'risk_factors_identified': _riskFactorsIdentified,
          'protective_factors_identified': _protectiveFactorsIdentified,
          'immediate_actions_required': _immediateActionsRequired,
          'immediate_actions': _immediateActions,
          'follow_up_actions': _followUpActions,
          'crisis_contacts': _crisisContacts,
          'next_review_date': _nextReviewDate?.toIso8601String(),
          'status': 'completed',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Self harm risk assessment completed successfully')),
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
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Harm Risk Assessment'),
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

            // Current Suicidal Ideation
            _buildSectionTitle('Current Suicidal Ideation'),
            DropdownButtonFormField<String>(
              value: _currentSuicidalIdeation,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: _suicidalIdeationOptions
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.capitalize())))
                  .toList(),
              onChanged: (value) => setState(() => _currentSuicidalIdeation = value!),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Details (optional)'),
              onChanged: (value) => _currentSuicidalIdeationDetails = value,
            ),
            const SizedBox(height: 16),

            // Previous Self-Harm Attempts
            _buildSectionTitle('Previous Self-Harm Attempts'),
            DropdownButtonFormField<int>(
              value: _previousAttempts,
              decoration: const InputDecoration(labelText: 'Number of attempts'),
              items: List.generate(10, (i) => i)
                  .map((i) => DropdownMenuItem(value: i, child: Text(i.toString())))
                  .toList(),
              onChanged: (value) => setState(() => _previousAttempts = value!),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Details (optional)'),
              onChanged: (value) => _previousAttemptsDetails = value,
            ),
            const SizedBox(height: 16),

            // Method of Self-Harm
            _buildSectionTitle('Method of Self-Harm'),
            DropdownButtonFormField<String>(
              value: _selfHarmMethod,
              decoration: const InputDecoration(labelText: 'Method'),
              items: _methodOptions
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.capitalize())))
                  .toList(),
              onChanged: (value) => setState(() => _selfHarmMethod = value),
            ),
            if (_selfHarmMethod == 'other') ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Other method'),
                onChanged: (value) => _selfHarmMethodOther = value,
              ),
            ],
            SwitchListTile(
              title: const Text('Method was planned'),
              value: _methodPlanned,
              onChanged: (value) => setState(() => _methodPlanned = value),
            ),
            const SizedBox(height: 16),

            // Frequency of Thoughts
            _buildSectionTitle('Frequency of Thoughts'),
            DropdownButtonFormField<String>(
              value: _frequencyOfThoughts,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: _frequencyOptions
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.capitalize())))
                  .toList(),
              onChanged: (value) => setState(() => _frequencyOfThoughts = value),
            ),
            const SizedBox(height: 16),

            // Triggers
            _buildSectionTitle('Triggers'),
            CheckboxListTile(
              title: const Text('Relationship triggers'),
              value: _relationshipTriggers,
              onChanged: (value) => setState(() => _relationshipTriggers = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Financial triggers'),
              value: _financialTriggers,
              onChanged: (value) => setState(() => _financialTriggers = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Health triggers'),
              value: _healthTriggers,
              onChanged: (value) => setState(() => _healthTriggers = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Other triggers'),
              value: _otherTriggers,
              onChanged: (value) => setState(() => _otherTriggers = value ?? false),
            ),
            if (_otherTriggers) ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Trigger details'),
                onChanged: (value) => _triggerDetails = value,
              ),
            ],
            const SizedBox(height: 16),

            // Protective Factors
            _buildSectionTitle('Protective Factors'),
            CheckboxListTile(
              title: const Text('Family support'),
              value: _familySupport,
              onChanged: (value) => setState(() => _familySupport = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Friend support'),
              value: _friendSupport,
              onChanged: (value) => setState(() => _friendSupport = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Routine structure'),
              value: _routineStructure,
              onChanged: (value) => setState(() => _routineStructure = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Other protective factors'),
              value: _otherProtectiveFactors,
              onChanged: (value) => setState(() => _otherProtectiveFactors = value ?? false),
            ),
            if (_otherProtectiveFactors) ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Protective factors details'),
                onChanged: (value) => _protectiveFactorsDetails = value,
              ),
            ],
            const SizedBox(height: 16),

            // Risk Factors
            _buildSectionTitle('Risk Factors'),
            SwitchListTile(
              title: const Text('Access to means'),
              value: _accessToMeans,
              onChanged: (value) => setState(() => _accessToMeans = value),
            ),
            if (_accessToMeans) ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Access details'),
                onChanged: (value) => _accessToMeansDetails = value,
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Mental health diagnosis'),
              onChanged: (value) => _mentalHealthDiagnosis = value,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _currentTreatment,
              decoration: const InputDecoration(labelText: 'Current treatment'),
              items: _treatmentOptions
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.capitalize())))
                  .toList(),
              onChanged: (value) => setState(() => _currentTreatment = value),
            ),
            const SizedBox(height: 16),

            // Behavioral Indicators
            _buildSectionTitle('Behavioral Indicators'),
            CheckboxListTile(
              title: const Text('Sleep disturbances'),
              value: _sleepDisturbances,
              onChanged: (value) => setState(() => _sleepDisturbances = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Withdrawal from activities'),
              value: _withdrawalFromActivities,
              onChanged: (value) => setState(() => _withdrawalFromActivities = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Giving away possessions'),
              value: _givingAwayPossessions,
              onChanged: (value) => setState(() => _givingAwayPossessions = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Making plans/arrangements'),
              value: _makingPlansArrangements,
              onChanged: (value) => setState(() => _makingPlansArrangements = value ?? false),
            ),
            const SizedBox(height: 16),

            // Overall Risk Level (Auto-calculated)
            _buildSectionTitle('Overall Risk Level'),
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
            const SizedBox(height: 16),

            // Action Plan
            _buildSectionTitle('Action Plan'),
            SwitchListTile(
              title: const Text('Immediate actions required'),
              value: _immediateActionsRequired,
              onChanged: (value) => setState(() => _immediateActionsRequired = value),
            ),
            if (_immediateActionsRequired) ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Immediate actions'),
                onChanged: (value) => _immediateActions = value,
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Follow-up actions'),
              onChanged: (value) => _followUpActions = value,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Crisis contacts'),
              onChanged: (value) => _crisisContacts = value,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectReviewDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Next review date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _nextReviewDate != null
                      ? '${_nextReviewDate!.day}/${_nextReviewDate!.month}/${_nextReviewDate!.year}'
                      : 'Select date',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Assessment', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}