import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/ui/assessments/falls_risk_form.dart';

class FallsRiskScreen extends StatefulWidget {
  const FallsRiskScreen({super.key});
  @override
  State<FallsRiskScreen> createState() => _FallsRiskScreenState();
}

class _FallsRiskScreenState extends State<FallsRiskScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _assessments = [];
  List<Map<String, dynamic>> _serviceUsers = [];
  String? _selectedServiceUserId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await _client
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
      });
      _load();
    } catch (_) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      var query = _client
          .from('falls_risk_assessments')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      if (_selectedServiceUserId != null) {
        final userId = _selectedServiceUserId!;
        query = _client
            .from('falls_risk_assessments')
            .select()
            .eq('service_user_id', userId)
            .order('created_at', ascending: false)
            .limit(50);
      }

      final data = await query;
      setState(() {
        _assessments = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  int _calcTotalScore(Map<String, dynamic> a) {
    return ((a['age_score'] as int?) ?? 0) +
        ((a['fall_history_score'] as int?) ?? 0) +
        ((a['elimination_score'] as int?) ?? 0) +
        ((a['medication_score'] as int?) ?? 0) +
        ((a['equipment_score'] as int?) ?? 0) +
        ((a['mobility_score'] as int?) ?? 0) +
        ((a['cognition_score'] as int?) ?? 0);
  }

  String _getRiskLevel(int score) {
    if (score >= 13) return 'High';
    if (score >= 9) return 'Moderate';
    if (score >= 6) return 'Low';
    return 'N/A';
  }

  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel) {
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

  IconData _getRiskIcon(String? riskLevel) {
    switch (riskLevel) {
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

  String _badgeText(String? riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return 'LOW';
      case 'Moderate':
        return 'MOD';
      case 'High':
        return 'HIGH';
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Falls Risk Assessments'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Service user filter
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: DropdownButtonFormField<String?>(
              value: _selectedServiceUserId,
              decoration: InputDecoration(
                labelText: 'Filter by Service User',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.filter_list),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Service Users')),
                ..._serviceUsers.map((user) => DropdownMenuItem(
                  value: user['id'] as String,
                  child: Text(user['name'] as String),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedServiceUserId = value;
                  _loading = true;
                });
                _load();
              },
            ),
          ),

          // Assessment list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _assessments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.air, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No falls risk assessments found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _assessments.length,
                        itemBuilder: (_, i) {
                          final a = _assessments[i];
                          final totalScore = _calcTotalScore(a);
                          final riskLevel = _getRiskLevel(totalScore);
                          final riskColor = _getRiskColor(riskLevel);
                          final riskIcon = _getRiskIcon(riskLevel);
                          final serviceUserName = a['service_user_name'] as String? ?? 'Unknown';

                          final gripStrengthKg = (a['grip_strength_kg'] as num?)?.toDouble();
                          final gripStrengthRisk = a['grip_strength_risk'] as String?;
                          final mobilityTestCompleted = a['mobility_test_completed'] as bool?;
                          final gripColor = gripStrengthRisk == 'High' ? const Color(0xFFF44336) : gripStrengthRisk == 'Medium' ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: riskColor.withOpacity(0.1),
                                child: Icon(riskIcon, color: riskColor, size: 24),
                              ),
                              title: Text(
                                serviceUserName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: ${(a['assessment_date'] ?? '').toString().split('T').first}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (gripStrengthKg != null) ...[
                                        Icon(Icons.fitness_center, size: 12, color: gripColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${gripStrengthKg}kg',
                                          style: TextStyle(fontSize: 11, color: gripColor, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Icon(
                                        mobilityTestCompleted == true ? Icons.check_circle : Icons.cancel,
                                        size: 12,
                                        color: mobilityTestCompleted == true ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        mobilityTestCompleted == true ? 'Mobility OK' : 'Mobility Due',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: mobilityTestCompleted == true ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$totalScore',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: riskColor),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: riskColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _badgeText(riskLevel),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
                                    ),
                                  ),
                                  if (gripStrengthRisk != null) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: gripColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        gripStrengthRisk.toUpperCase(),
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: gripColor),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () => _showForm(context, a),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, [Map<String, dynamic>? existing]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FallsRiskForm(
          assessmentId: existing?['id'] as String?,
        ),
      ),
    ).then((_) => _load());
  }
}