import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicationRiskForm extends StatefulWidget {
  final String? assessmentId;

  const MedicationRiskForm({
    super.key,
    this.assessmentId,
  });

  @override
  State<MedicationRiskForm> createState() => _MedicationRiskFormState();
}

class _MedicationRiskFormState extends State<MedicationRiskForm> {
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
  final _notesController = TextEditingController();
  final _medicationsListController = TextEditingController();
  bool _signatureConfirmed = false;

  // Scoring (0-2 each)
  int? _medicationCountScore;
  int? _highRiskMedsScore;
  int? _sedationScore;
  int? _adherenceScore;
  int? _sideEffectsScore;
  int? _polypharmacyScore;

  // Selected labels
  String _medicationCountLabel = '';
  String _highRiskMedsLabel = '';
  String _sedationLabel = '';
  String _adherenceLabel = '';
  String _sideEffectsLabel = '';
  String _polypharmacyLabel = '';

  // Scoring options
  final List<Map<String, dynamic>> _medicationCountOptions = [
    {'label': '0-4 medications', 'score': 0},
    {'label': '5-7 medications', 'score': 1},
    {'label': '8+ medications', 'score': 2},
  ];

  final List<Map<String, dynamic>> _highRiskMedsOptions = [
    {'label': 'None', 'score': 0},
    {'label': '1-2 high-risk medications', 'score': 1},
    {'label': '3+ high-risk medications', 'score': 2},
  ];

  final List<Map<String, dynamic>> _sedationOptions = [
    {'label': 'No sedation risk', 'score': 0},
    {'label': 'Mild sedation risk', 'score': 1},
    {'label': 'Significant sedation risk', 'score': 2},
  ];

  final List<Map<String, dynamic>> _adherenceOptions = [
    {'label': 'Good adherence', 'score': 0},
    {'label': 'Occasional misses', 'score': 1},
    {'label': 'Regular misses', 'score': 2},
  ];

  final List<Map<String, dynamic>> _sideEffectsOptions = [
    {'label': 'No side effects', 'score': 0},
    {'label': 'Mild side effects', 'score': 1},
    {'label': 'Severe side effects', 'score': 2},
  ];

  final List<Map<String, dynamic>> _polypharmacyOptions = [
    {'label': 'Low risk', 'score': 0},
    {'label': 'Medium risk', 'score': 1},
    {'label': 'High risk', 'score': 2},
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
    _notesController.dispose();
    _medicationsListController.dispose();
    super.dispose();
  }

  int get _totalScore {
    return (_medicationCountScore ?? 0) +
        (_highRiskMedsScore ?? 0) +
        (_sedationScore ?? 0) +
        (_adherenceScore ?? 0) +
        (_sideEffectsScore ?? 0) +
        (_polypharmacyScore ?? 0);
  }

  String get _riskLevel {
    final score = _totalScore;
    if (score >= 8) return 'High';
    if (score >= 4) return 'Medium';
    if (score >= 1) return 'Low';
    return 'Low';
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

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
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
      final totalScore = _totalScore;
      final riskLevel = _riskLevel;

      final payload = {
        'service_user_id': _selectedServiceUserId,
        'service_user_name': serviceUserName,
        'date_of_birth': dateOfBirth,
        'assessor_name': _assessorNameController.text.trim(),
        'assessment_date': _assessmentDate.toIso8601String(),
        'medication_count_score': _medicationCountScore,
        'high_risk_meds_score': _highRiskMedsScore,
        'sedation_score': _sedationScore,
        'adherence_score': _adherenceScore,
        'side_effects_score': _sideEffectsScore,
        'polypharmacy_score': _polypharmacyScore,
        'medications_list': _medicationsListController.text.trim().isEmpty ? null : _medicationsListController.text.trim(),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'total_score': totalScore,
        'risk_level': riskLevel,
        'signature_data': signatureData,
        'status': status,
      };

      if (_assessmentId == null) {
        final data = await _client.from('medication_risk_assessments').insert({
          ...payload,
          'created_by': _client.auth.currentUser?.id,
        }).select().single();
        _assessmentId = data['id'] as String?;
      } else if (_assessmentId != null) {
        await _client.from('medication_risk_assessments').update({
          ...payload,
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
    if (score == 1) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Risk Assessment'),
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
                      const Text('Total Medication Risk Score', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$_totalScore / 12',
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
                        value: _totalScore / 12.0,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                        strokeWidth: 4,
                      ),
                      Center(
                        child: Text(
                          '${(_totalScore / 12.0 * 100).round()}%',
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
                _buildScoreDropdown('Medication Count', Icons.sort, _medicationCountScore, _medicationCountLabel, _medicationCountOptions,
                    (v) => setState(() => _medicationCountScore = v), (v) => _medicationCountLabel = v),

                _buildScoreDropdown('High-Risk Medications', Icons.warning_amber, _highRiskMedsScore, _highRiskMedsLabel, _highRiskMedsOptions,
                    (v) => setState(() => _highRiskMedsScore = v), (v) => _highRiskMedsLabel = v),

                _buildScoreDropdown('Sedation Risk', Icons.bedtime, _sedationScore, _sedationLabel, _sedationOptions,
                    (v) => setState(() => _sedationScore = v), (v) => _sedationLabel = v),

                _buildScoreDropdown('Adherence', Icons.checklist, _adherenceScore, _adherenceLabel, _adherenceOptions,
                    (v) => setState(() => _adherenceScore = v), (v) => _adherenceLabel = v),

                _buildScoreDropdown('Side Effects', Icons.report_problem, _sideEffectsScore, _sideEffectsLabel, _sideEffectsOptions,
                    (v) => setState(() => _sideEffectsScore = v), (v) => _sideEffectsLabel = v),

                _buildScoreDropdown('Polypharmacy Risk', Icons.medication, _polypharmacyScore, _polypharmacyLabel, _polypharmacyOptions,
                    (v) => setState(() => _polypharmacyScore = v), (v) => _polypharmacyLabel = v),

                const SizedBox(height: 12),

                // Medications List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _medicationsListController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Current Medications List',
                      hintText: 'Enter medications (comma-separated or one per line)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.list_alt),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Additional Notes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.notes),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),

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