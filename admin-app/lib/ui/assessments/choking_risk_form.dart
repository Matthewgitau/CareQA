import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/choking_risk_assessment.dart';

class ChokingRiskForm extends StatefulWidget {
  final String? assessmentId;
  final ChokingRiskAssessment? existingAssessment;

  const ChokingRiskForm({
    super.key,
    this.assessmentId,
    this.existingAssessment,
  });

  @override
  State<ChokingRiskForm> createState() => _ChokingRiskFormState();
}

class _ChokingRiskFormState extends State<ChokingRiskForm> {
  final _client = Supabase.instance.client;
  bool _saving = false;
  String? _assessmentId;
  String? _selectedServiceUserId;
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;

  // Assessment metadata
  DateTime _assessmentDate = DateTime.now();
  final _assessorNameController = TextEditingController();
  final _signatureController = TextEditingController();
  bool _signatureConfirmed = false;

  // All 36 risk factor scores
  final Map<String, int> _riskFactors = {};

  // Section expansion states
  final Map<String, bool> _expandedSections = {
    'Physical Conditions': true,
    'Neurological Conditions': false,
    'Physical Limitations': false,
    'Behavioral Factors': false,
    'Eating/Drinking Independence': false,
    'Dental/Oral Health': false,
    'Physical/Mental State': false,
    'Medication': false,
  };

  @override
  void initState() {
    super.initState();
    _assessmentId = widget.assessmentId;
    _loadServiceUsers();
    // Auto-fill assessor name from current user
    final user = _client.auth.currentUser;
    if (user != null) {
      _assessorNameController.text = user.email?.split('@').first ?? user.id ?? '';
    }
    if (widget.existingAssessment != null) {
      _selectedServiceUserId = widget.existingAssessment!.serviceUserId;
      _riskFactors.addAll(widget.existingAssessment!.riskFactors);
      _assessmentDate = widget.existingAssessment!.assessmentDate;
      _assessorNameController.text = widget.existingAssessment!.assessorName;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _assessmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _assessmentDate = picked);
    }
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await _client
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

  @override
  void dispose() {
    _assessorNameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  int get _totalScore => _riskFactors.values.fold(0, (sum, s) => sum + s);

  String get _riskLevel {
    final score = _totalScore;
    if (score <= 24) return 'Low';
    if (score <= 49) return 'Medium';
    return 'High';
  }

  Color get _riskColor {
    switch (_riskLevel) {
      case 'Low':
        return const Color(0xFF4CAF50);
      case 'Medium':
        return const Color(0xFFFF9800);
      case 'High':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get _riskIcon {
    switch (_riskLevel) {
      case 'Low':
        return Icons.check_circle;
      case 'Medium':
        return Icons.warning;
      case 'High':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Future<void> _save() async {
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service user')),
      );
      return;
    }

    if (_assessorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the assessor name')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final status = _signatureConfirmed ? 'completed' : 'draft';
      final assessorSignature = _signatureConfirmed ? _signatureController.text.trim() : null;

      if (_assessmentId == null) {
        final data = await _client.from('choking_risk_assessments').insert({
          'service_user_id': _selectedServiceUserId,
          'risk_factors': _riskFactors,
          'assessment_date': _assessmentDate.toIso8601String(),
          'assessor_name': _assessorNameController.text.trim(),
          'sfarr_signature': assessorSignature,
          'created_by': _client.auth.currentUser?.id,
          'status': status,
        }).select().single();
        _assessmentId = data['id'] as String?;
      } else if (_assessmentId != null) {
        await _client.from('choking_risk_assessments').update({
          'risk_factors': _riskFactors,
          'service_user_id': _selectedServiceUserId,
          'assessment_date': _assessmentDate.toIso8601String(),
          'assessor_name': _assessorNameController.text.trim(),
          'sfarr_signature': assessorSignature,
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', _assessmentId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'completed' ? 'Assessment completed successfully' : 'Assessment saved as draft')),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> questions) {
    final isExpanded = _expandedSections[title] ?? true;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _expandedSections[title] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF1565C0), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${questions.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...questions,
          if (isExpanded)
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuestion(String key, String label) {
    final score = _riskFactors[key] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [0, 1, 2].map((val) {
                final isSelected = score == val;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _riskFactors[key] = val;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _getScoreColor(val) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$val',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    switch (score) {
      case 0:
        return const Color(0xFF4CAF50);
      case 1:
        return const Color(0xFFFF9800);
      case 2:
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choking Risk Assessment'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scoring header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_riskColor.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: _riskColor.withOpacity(0.3), width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(_riskIcon, color: _riskColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Risk Score',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$_totalScore / 72',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _riskColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _riskColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _riskLevel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Progress indicator
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _totalScore / 72,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                        strokeWidth: 4,
                      ),
                      Center(
                        child: Text(
                          '${(_totalScore / 72 * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _riskColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Service user dropdown
          Padding(
            padding: const EdgeInsets.all(12),
            child: _loadingUsers
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedServiceUserId,
                    decoration: InputDecoration(
                      labelText: 'Service User *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    items: _serviceUsers.map((user) {
                      return DropdownMenuItem(
                        value: user['id'] as String,
                        child: Text(user['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedServiceUserId = value);
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
          ),

          // Assessment Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Assessment Date *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  '${_assessmentDate.day}/${_assessmentDate.month}/${_assessmentDate.year}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Assessor Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _assessorNameController,
              decoration: InputDecoration(
                labelText: 'Assessor Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.badge),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Signature confirmation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text(
                      'I confirm that I have completed this assessment to the best of my knowledge',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _signatureConfirmed,
                    activeColor: const Color(0xFF1565C0),
                    onChanged: (value) => setState(() => _signatureConfirmed = value ?? false),
                  ),
                  if (_signatureConfirmed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _signatureController,
                        decoration: InputDecoration(
                          labelText: 'Assessor Signature (type your name)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.edit_note),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Physical Conditions (6)
                _buildSectionCard('Physical Conditions', Icons.air, [
                  _buildQuestion('weak_cough', '1. Weak cough and/or inability to clear throat'),
                  _buildQuestion('chest_infections', '2. History of chest infections'),
                  _buildQuestion('breathing_difficulties', '3. Breathing difficulties/COPD'),
                  _buildQuestion('known_to_aspirate', '4. Known to aspirate'),
                  _buildQuestion('history_of_choking', '5. History of choking/requiring intervention'),
                  _buildQuestion('gurgly_wet_voice', '6. Gurgly or wet voice after swallowing'),
                ]),

                // Neurological Conditions (6)
                _buildSectionCard('Neurological Conditions', Icons.psychology, [
                  _buildQuestion('epilepsy', '7. Epilepsy'),
                  _buildQuestion('cerebral_palsy', '8. Cerebral palsy'),
                  _buildQuestion('dementia_confusion', '9. Dementia/confusion'),
                  _buildQuestion('mental_health_history', '10. Mental health history'),
                  _buildQuestion('neurological_conditions', '11. Known neurological conditions (CVA, Parkinson\'s, Huntington\'s)'),
                  _buildQuestion('learning_disabilities', '12. Learning disabilities'),
                ]),

                // Physical Limitations (6)
                _buildSectionCard('Physical Limitations', Icons.accessible, [
                  _buildQuestion('postural_problems', '13. Postural problems/increased rigidity/severe flexion/cannot sit upright'),
                  _buildQuestion('poor_head_control', '14. Poor head control'),
                  _buildQuestion('tongue_thrust', '15. Tongue thrust'),
                  _buildQuestion('chewing_difficulties', '16. Difficulties chewing or prolonged chewing time'),
                  _buildQuestion('slurred_speech', '17. Slurred speech and/or facial weakness'),
                  _buildQuestion('neck_throat_injury', '18. Any known injury/trauma to neck or throat'),
                ]),

                // Behavioral Factors (8)
                _buildSectionCard('Behavioral Factors', Icons.restaurant, [
                  _buildQuestion('eats_rapidly', '19. Eats rapidly'),
                  _buildQuestion('drinks_rapidly', '20. Drinks rapidly'),
                  _buildQuestion('continues_eating_while_coughing', '21. Continues to eat whilst coughing'),
                  _buildQuestion('continues_drinking_while_coughing', '22. Continues to drink whilst coughing'),
                  _buildQuestion('cramming_food', '23. Cramming food in mouth'),
                  _buildQuestion('pocketing_food', '24. Pocketing food or drink in mouth'),
                  _buildQuestion('swallowing_without_chewing', '25. Swallowing without chewing'),
                  _buildQuestion('takes_food_from_others', '26. Would take food from others/cupboards if not supervised'),
                ]),

                // Eating/Drinking Independence (2)
                _buildSectionCard('Eating/Drinking Independence', Icons.free_breakfast, [
                  _buildQuestion('drinks_independently', '27. Drinks independently and safely'),
                  _buildQuestion('eats_independently', '28. Eats independently and safely'),
                ]),

                // Dental/Oral Health (1)
                _buildSectionCard('Dental/Oral Health', Icons.face, [
                  _buildQuestion('dental_issues', '29. Poor fitting/missing dentures/poor dentition/dental pain'),
                ]),

                // Physical/Mental State (6)
                _buildSectionCard('Physical/Mental State', Icons.bedtime, [
                  _buildQuestion('fatigue_at_meals', '30. Fatigue at meal times'),
                  _buildQuestion('needs_food_prepared', '31. Needs food cutting up or prepared prior to eating'),
                  _buildQuestion('modified_consistency_diet', '32. Is on a modified consistency diet'),
                  _buildQuestion('requires_thickened_fluids', '33. Requires thickened fluids'),
                  _buildQuestion('requires_specialist_aids', '34. Requires specialist feeding aids'),
                  _buildQuestion('puts_non_food_items_in_mouth', '35. Will accept/put any item into mouth including non-food items'),
                ]),

                // Medication (1)
                _buildSectionCard('Medication', Icons.medication, [
                  _buildQuestion('medication_affects_swallowing', '36. Taking medication that can affect swallowing'),
                ]),

                const SizedBox(height: 16),

                // Save button at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save Assessment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}