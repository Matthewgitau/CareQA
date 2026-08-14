import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/nutrition_assessment.dart';
import 'package:admin_app/services/nutrition_service.dart';
import 'package:admin_app/ui/risk/nutrition_risk_form.dart';

class NutritionRiskScreen extends StatefulWidget {
  final String? serviceUserId;
  const NutritionRiskScreen({super.key, this.serviceUserId});
  @override
  State<NutritionRiskScreen> createState() => _NutritionRiskScreenState();
}

class _NutritionRiskScreenState extends State<NutritionRiskScreen> {
  final _service = NutritionService(Supabase.instance.client);
  List<NutritionAssessment> _assessments = [];
  Map<String, String> _serviceUserNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final data = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      final users = List<Map<String, dynamic>>.from(data as List);
      _serviceUserNames = {
        for (final u in users) u['id'] as String: u['name'] as String,
      };
    } catch (_) {}
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getAssessments(serviceUserId: widget.serviceUserId);
      setState(() { _assessments = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _riskColor(String category) {
    switch (category) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Risk Assessments (MUST)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionRiskForm()))
              .then((_) => _load());
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assessments.isEmpty
              ? const Center(child: Text('No nutrition assessments found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _assessments.length,
                  itemBuilder: (_, i) {
                    final a = _assessments[i];
                    final userName = a.serviceUserId != null
                        ? _serviceUserNames[a.serviceUserId] ?? a.serviceUserName ?? 'Unknown'
                        : 'Unknown';
                    final riskColor = _riskColor(a.riskCategory);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: riskColor.withOpacity(0.1),
                          child: Icon(
                            a.riskCategory == 'high' ? Icons.warning : Icons.check_circle,
                            color: riskColor,
                          ),
                        ),
                        title: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'MUST Score: ${a.mustTotalScore} | ${a.riskCategory.toUpperCase()} | ${a.assessmentDate.toString().split(' ').first}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            a.riskCategory.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}