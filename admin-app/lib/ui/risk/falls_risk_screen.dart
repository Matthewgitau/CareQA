import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/falls_risk_assessment.dart';
import 'package:admin_app/services/falls_risk_service.dart';
import 'package:admin_app/ui/risk/falls_risk_form.dart';

class FallsRiskScreen extends StatefulWidget {
  final String? serviceUserId;
  const FallsRiskScreen({super.key, this.serviceUserId});

  @override
  State<FallsRiskScreen> createState() => _FallsRiskScreenState();
}

class _FallsRiskScreenState extends State<FallsRiskScreen> {
  final _service = FallsRiskService(Supabase.instance.client);
  List<FallsRiskHistoryItem> _assessments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = widget.serviceUserId != null
          ? await _service.getAssessmentsForServiceUser(widget.serviceUserId!)
          : await _service.searchAssessments();
      setState(() {
        _assessments = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return Colors.green;
      case 'Moderate':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.grey;
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FallsRiskForm(serviceUserId: widget.serviceUserId),
          ),
        ).then((_) => _load()),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assessments.isEmpty
              ? const Center(child: Text('No falls risk assessments found'))
              : ListView.builder(
                  itemCount: _assessments.length,
                  itemBuilder: (_, i) {
                    final a = _assessments[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRiskColor(a.riskLevel),
                          child: Text(
                            a.riskLevel.substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(a.serviceUserName),
                        subtitle: Text(
                          'Risk: ${a.riskLevel} | Score: ${a.totalScore} | ${a.assessmentDate.toString().split(' ').first}',
                        ),
                        trailing: Chip(
                          label: Text(
                            a.status,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: a.status == 'completed' ? Colors.green : Colors.orange,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FallsRiskForm(
                              assessmentId: a.assessmentId,
                              serviceUserId: widget.serviceUserId,
                            ),
                          ),
                        ).then((_) => _load()),
                      ),
                    );
                  },
                ),
    );
  }
}