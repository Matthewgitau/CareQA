import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FallsRiskForm extends StatefulWidget {
  final String? assessmentId;

  const FallsRiskForm({
    super.key,
    this.assessmentId,
  });

  @override
  State<FallsRiskForm> createState() => _FallsRiskFormState();
}

class _FallsRiskFormState extends State<FallsRiskForm> {
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

  // Scoring
  int? _ageScore;
  int? _fallHistoryScore;
  int? _eliminationScore;
  int? _medicationScore;
  int? _equipmentScore;
  int? _mobilityScore;
  int? _cognitionScore;

  // Mobility Test & Grip Strength
  bool? _mobilityTestCompleted;
  DateTime? _mobilityTestDate;
  bool? _mobilityChanged;
  final _gripStrengthController = TextEditingController();
  String? _gripStrengthRisk;
  bool _mobilityRiskTriggered = false;

  // Selected labels for display
  String _ageLabel = '';
  String _fallHistoryLabel = '';
  String _eliminationLabel = '';
  String _medicationLabel = '';
  String _equipmentLabel = '';
  String _mobilityLabel = '';
  String _cognitionLabel = '';

  // Scoring options
  final List<Map<String, dynamic>> _ageOptions = [
    {'label': 'Under 60 years', 'score': 0},
    {'label': '60-69 years', 'score': 1},
    {'label': '70-79 years', 'score': 2},
    {'label': '80+ years', 'score': 3},
  ];

  final List<Map<String, dynamic>> _fallHistoryOptions = [
    {'label': 'No falls in 6 months', 'score': 0},
    {'label': 'One fall in 6 months', 'score': 5},
  ];

  final List<Map<String, dynamic>> _eliminationOptions = [
    {'label': 'No elimination issues', 'score': 0},
    {'label': 'Incontinence', 'score': 2},
    {'label': 'Urgency', 'score': 3},
    {'label': 'Both incontinence and urgency', 'score': 5},
  ];

  final List<Map<String, dynamic>> _medicationOptions = [
    {'label': 'No high-risk medications', 'score': 0},
    {'label': '1 high-risk drug', 'score': 3},
    {'label': '2+ high-risk drugs', 'score': 5},
    {'label': 'Sedation', 'score': 7},
  ];

  final List<Map<String, dynamic>> _equipmentOptions = [
    {'label': 'No patient care equipment', 'score': 0},
    {'label': '1 item of patient care equipment', 'score': 1},
    {'label': '2 items of patient care equipment', 'score': 2},
    {'label': '3+ items of patient care equipment', 'score': 3},
  ];

  final List<Map<String, dynamic>> _mobilityOptions = [
    {'label': 'No mobility issues', 'score': 0},
    {'label': 'Requires assistance to mobilize', 'score': 2},
    {'label': 'Unsteady gait', 'score': 3},
    {'label': 'Visual impairment', 'score': 4},
    {'label': 'Requires equipment to mobilize', 'score': 5},
    {'label': 'Bed care only', 'score': 7},
  ];

  final List<Map<String, dynamic>> _cognitionOptions = [
    {'label': 'No cognitive issues', 'score': 0},
    {'label': 'Altered awareness', 'score': 1},
    {'label': 'Impulsive behavior', 'score': 2},
    {'label': 'Lack of understanding of own safety', 'score': 4},
  ];

  @override
  void initState() {
    super.initState();
    _assessmentId = widget.assessmentId;
    _loadServiceUsers();
    final user = _client.auth.currentUser;
    if (user != null) {
      _assessorNameController.text = user.email?.split('@').first ?? user.id ?? '';
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

  Future<Map<String, dynamic>?> _getServiceUserDetails(String userId) async {
    try {
      final response = await _client
          .from('service_users')
          .select('name, date_of_birth')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
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

  @override
  void dispose() {
    _assessorNameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  int get _gripStrengthScore {
    final kgStr = _gripStrengthController.text.trim();
    if (kgStr.isEmpty) return 0;
    final kg = double.tryParse(kgStr);
    if (kg == null) return 0;
    if (kg < 16) return 3;
    if (kg < 20) return 2;
    return 0;
  }

  int get _totalScore {
    return (_ageScore ?? 0) +
        (_fallHistoryScore ?? 0) +
        (_eliminationScore ?? 0) +
        (_medicationScore ?? 0) +
        (_equipmentScore ?? 0) +
        (_mobilityScore ?? 0) +
        (_cognitionScore ?? 0) +
        _gripStrengthScore;
  }

  String get _riskLevel {
    final score = _totalScore;
    if (score >= 13) return 'High';
    if (score >= 9) return 'Moderate';
    if (score >= 6) return 'Low';
    return 'Not Calculated';
  }

  Color get _riskColor {
    switch (_riskLevel) {
      case 'Low':
        return const Color(0xFF4CAF50);
      case 'Moderate':
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
      case 'Moderate':
        return Icons.warning;
      case 'High':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<bool> _showEditWarningDialog() async {
    if (widget.assessmentId == null) return true;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Existing Assessment'),
        content: const Text(
          'You are about to update information on an already submitted form. '
          'Please make sure you are sure you want to edit this file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, leave it as is'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, edit this file'),
          ),
        ],
      ),
    ) ?? false;
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

    final shouldContinue = await _showEditWarningDialog();
    if (!shouldContinue) return;

    final serviceUserDetails = await _getServiceUserDetails(_selectedServiceUserId!);
    if (serviceUserDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find service user details')),
      );
      return;
    }
    final serviceUserName = (serviceUserDetails['name'] as String?) ?? '';
    final dateOfBirth = serviceUserDetails['date_of_birth']?.toString() ?? DateTime.now().toIso8601String();

    setState(() => _saving = true);
    try {
      final status = _signatureConfirmed ? 'completed' : 'draft';
      final signatureData = _signatureConfirmed ? _signatureController.text.trim() : null;

      if (_assessmentId == null) {
        final data = await _client.from('falls_risk_assessments').insert({
          'service_user_id': _selectedServiceUserId,
          'service_user_name': serviceUserName,
          'date_of_birth': dateOfBirth,
          'assessor_name': _assessorNameController.text.trim(),
          'assessment_date': _assessmentDate.toIso8601String(),
          'age_score': _ageScore,
          'fall_history_score': _fallHistoryScore,
          'elimination_score': _eliminationScore,
          'medication_score': _medicationScore,
          'equipment_score': _equipmentScore,
          'mobility_score': _mobilityScore,
          'cognition_score': _cognitionScore,
          'signature_data': signatureData,
          'created_by': _client.auth.currentUser?.id,
          'status': status,
        }).select().single();
        _assessmentId = data['id'] as String?;
      } else if (_assessmentId != null) {
        await _client.from('falls_risk_assessments').update({
          'service_user_name': serviceUserName,
          'date_of_birth': dateOfBirth,
          'age_score': _ageScore,
          'fall_history_score': _fallHistoryScore,
          'elimination_score': _eliminationScore,
          'medication_score': _medicationScore,
          'equipment_score': _equipmentScore,
          'mobility_score': _mobilityScore,
          'cognition_score': _cognitionScore,
          'mobility_test_completed': _mobilityTestCompleted,
          'mobility_test_date': _mobilityTestDate?.toIso8601String(),
          'mobility_changed': _mobilityChanged,
          'grip_strength_kg': _gripStrengthController.text.trim().isEmpty ? null : double.tryParse(_gripStrengthController.text.trim()),
          'grip_strength_risk': _gripStrengthRisk,
          'mobility_risk_triggered': _mobilityRiskTriggered,
          'assessor_name': _assessorNameController.text.trim(),
          'assessment_date': _assessmentDate.toIso8601String(),
          'signature_data': signatureData,
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

  Widget _buildScoreDropdown(String title, IconData icon, int? currentScore, String currentLabel, List<Map<String, dynamic>> options, ValueChanged<int?> onScoreChanged, ValueChanged<String> onLabelChanged) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 20),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: currentScore != null ? _getScoreBadgeColor(currentScore).withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                currentScore != null ? '$currentScore' : '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: currentScore != null ? _getScoreBadgeColor(currentScore) : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: currentScore,
                  hint: Text('Select...', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  items: options.map((opt) {
                    final score = opt['score'] as int;
                    return DropdownMenuItem(
                      value: score,
                      child: Text(
                        opt['label']?.toString() ?? 'Unknown',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    onScoreChanged(value);
                    if (value != null) {
                      final selected = options.firstWhere((o) => o['score'] == value);
                      onLabelChanged(selected['label'] as String);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreBadgeColor(int score) {
    if (score == 0) return const Color(0xFF4CAF50);
    if (score <= 3) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  void _updateGripStrengthRisk() {
    final kgStr = _gripStrengthController.text.trim();
    if (kgStr.isEmpty) {
      _gripStrengthRisk = null;
      return;
    }
    final kg = double.tryParse(kgStr);
    if (kg == null) {
      _gripStrengthRisk = null;
      return;
    }
    if (kg < 16) {
      _gripStrengthRisk = 'High';
    } else if (kg < 20) {
      _gripStrengthRisk = 'Medium';
    } else {
      _gripStrengthRisk = 'Low';
    }
  }

  Widget _buildGripStrengthIndicator(String label, String range, Color color) {
    final isActive = _gripStrengthRisk == label;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : Colors.grey.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? color : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              range,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? color : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Falls Risk Assessment'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
              border: Border(bottom: BorderSide(color: _riskColor.withOpacity(0.3), width: 2)),
            ),
            child: Row(
              children: [
                Icon(_riskIcon, color: _riskColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Fall Risk Score', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$_totalScore',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _riskColor),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: _riskColor, borderRadius: BorderRadius.circular(16)),
                            child: Text(
                              _riskLevel.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _totalScore / 26.0,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                        strokeWidth: 4,
                      ),
                      Center(
                        child: Text(
                          '${(_totalScore / 26.0 * 100).round()}%',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _riskColor),
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
                        child: Text(user['name']?.toString() ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedServiceUserId = value),
                  ),
          ),

          // Assessment Date + Assessor Name row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Assessment Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(_formatDate(_assessmentDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _assessorNameController,
                    decoration: InputDecoration(
                      labelText: 'Assessor',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.badge, size: 18),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Scoring sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildScoreDropdown('Age', Icons.calendar_today, _ageScore, _ageLabel, _ageOptions,
                    (v) => setState(() => _ageScore = v), (v) => _ageLabel = v),

                _buildScoreDropdown('Fall History', Icons.history, _fallHistoryScore, _fallHistoryLabel, _fallHistoryOptions,
                    (v) => setState(() => _fallHistoryScore = v), (v) => _fallHistoryLabel = v),

                _buildScoreDropdown('Elimination', Icons.water_drop, _eliminationScore, _eliminationLabel, _eliminationOptions,
                    (v) => setState(() => _eliminationScore = v), (v) => _eliminationLabel = v),

                _buildScoreDropdown('Medication', Icons.medication, _medicationScore, _medicationLabel, _medicationOptions,
                    (v) => setState(() => _medicationScore = v), (v) => _medicationLabel = v),

                _buildScoreDropdown('Equipment', Icons.medical_services, _equipmentScore, _equipmentLabel, _equipmentOptions,
                    (v) => setState(() => _equipmentScore = v), (v) => _equipmentLabel = v),

                _buildScoreDropdown('Mobility', Icons.directions_walk, _mobilityScore, _mobilityLabel, _mobilityOptions,
                    (v) => setState(() => _mobilityScore = v), (v) => _mobilityLabel = v),

                _buildScoreDropdown('Cognition', Icons.psychology, _cognitionScore, _cognitionLabel, _cognitionOptions,
                    (v) => setState(() => _cognitionScore = v), (v) => _cognitionLabel = v),

                const SizedBox(height: 12),

                // === Mobility Test Section ===
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_walk, color: Color(0xFF1565C0), size: 20),
                            const SizedBox(width: 8),
                            const Text('Mobility Test', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Has a mobility test been completed in the last 3 months?',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Yes', style: TextStyle(fontSize: 13)),
                                value: true,
                                groupValue: _mobilityTestCompleted,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: const Color(0xFF1565C0),
                                onChanged: (v) {
                                  setState(() {
                                    _mobilityTestCompleted = v;
                                    _mobilityRiskTriggered = false;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('No', style: TextStyle(fontSize: 13)),
                                value: false,
                                groupValue: _mobilityTestCompleted,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: const Color(0xFF1565C0),
                                onChanged: (v) {
                                  setState(() {
                                    _mobilityTestCompleted = v;
                                    _mobilityRiskTriggered = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_mobilityTestCompleted == true) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _mobilityTestDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _mobilityTestDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Test Date',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const Icon(Icons.calendar_today, size: 18),
                                isDense: true,
                              ),
                              child: Text(
                                _mobilityTestDate != null
                                    ? '${_mobilityTestDate!.day}/${_mobilityTestDate!.month}/${_mobilityTestDate!.year}'
                                    : 'Select date',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            title: const Text('Mobility has changed since last test', style: TextStyle(fontSize: 12)),
                            value: _mobilityChanged ?? false,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF1565C0),
                            onChanged: (v) {
                              setState(() {
                                _mobilityChanged = v;
                                _mobilityRiskTriggered = v == true;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // === Grip Strength Section ===
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fitness_center, color: Color(0xFF1565C0), size: 20),
                            const SizedBox(width: 8),
                            const Text('Grip Strength Test', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _gripStrengthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Grip Strength (kg)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.monitor_weight, size: 18),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (_) => setState(() => _updateGripStrengthRisk()),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildGripStrengthIndicator('Low', '>20 kg', const Color(0xFF4CAF50)),
                            const SizedBox(width: 8),
                            _buildGripStrengthIndicator('Medium', '16-20 kg', const Color(0xFFFF9800)),
                            const SizedBox(width: 8),
                            _buildGripStrengthIndicator('High', '<16 kg', const Color(0xFFF44336)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // === Risk Trigger Warning ===
                if (_mobilityRiskTriggered)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF44336).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF44336).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFF44336), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mobility Risk Assessment Required',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF44336),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _mobilityTestCompleted == false
                                    ? 'No mobility test has been completed in the last 3 months.'
                                    : 'Mobility has changed since the last test. Re-assessment needed.',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFF44336)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),


                // Signature
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
                          onChanged: (v) => setState(() => _signatureConfirmed = v ?? false),
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

                const SizedBox(height: 16),

                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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