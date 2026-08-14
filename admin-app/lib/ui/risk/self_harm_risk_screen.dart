import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'self_harm_risk_form.dart';

class SelfHarmRiskScreen extends StatefulWidget {
  const SelfHarmRiskScreen({super.key});

  @override
  State<SelfHarmRiskScreen> createState() => _SelfHarmRiskScreenState();
}

class _SelfHarmRiskScreenState extends State<SelfHarmRiskScreen> {
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
      _loadAssessments();
    } catch (_) {
      _loadAssessments();
    }
  }

  Future<void> _loadAssessments() async {
    setState(() => _loading = true);
    try {
      Future<dynamic> query;

      if (_selectedServiceUserId != null) {
        query = _client
            .from('self_harm_assessments')
            .select()
            .eq('service_user_id', _selectedServiceUserId!)
            .order('created_at', ascending: false);
      } else {
        query = _client
            .from('self_harm_assessments')
            .select()
            .order('created_at', ascending: false);
      }

      final data = await query;
      setState(() {
        _assessments = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assessments: $e')),
        );
      }
    }
  }

  String _getRiskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'immediate': return '#F44336';
      case 'high': return '#FF9800';
      case 'medium': return '#FFC107';
      case 'low': return '#4CAF50';
      default: return '#9E9E9E';
    }
  }

  void _createNewAssessment() {
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service user first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelfHarmRiskForm(),
      ),
    ).then((_) => _loadAssessments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Harm Risk Assessments'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewAssessment,
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
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4),
              ],
            ),
            child: DropdownButtonFormField<String?>(
              value: _selectedServiceUserId,
              decoration: InputDecoration(
                labelText: 'Filter by Service User',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.filter_list),
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
                _loadAssessments();
              },
            ),
          ),
          // Assessments list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _assessments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No self-harm risk assessments found'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _assessments.length,
                        itemBuilder: (_, i) {
                          final a = _assessments[i];
                          final riskLevel = a['overall_risk_level'] as String? ?? 'unknown';
                          final riskColor = _getRiskColor(riskLevel);
                          final serviceUserName = a['service_user_id'] != null 
                              ? _serviceUsers.firstWhere(
                                  (u) => u['id'] == a['service_user_id'],
                                  orElse: () => {'name': 'Unknown'},
                                )['name'] as String
                              : 'Unknown';
                          final createdAt = a['created_at'] != null
                              ? DateTime.parse(a['created_at']).toLocal()
                              : DateTime.now();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Color(int.parse('0xFF${riskColor.substring(1)}')).withOpacity(0.1),
                                child: Icon(
                                  riskLevel == 'immediate' ? Icons.warning_amber_rounded :
                                  riskLevel == 'high' ? Icons.warning :
                                  Icons.check_circle,
                                  color: Color(int.parse('0xFF${riskColor.substring(1)}')),
                                ),
                              ),
                              title: Text(
                                serviceUserName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Date: ${DateFormat('dd/MM/yyyy').format(createdAt)} | Risk: ${riskLevel.toUpperCase()}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(int.parse('0xFF${riskColor.substring(1)}')).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  riskLevel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(int.parse('0xFF${riskColor.substring(1)}')),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}