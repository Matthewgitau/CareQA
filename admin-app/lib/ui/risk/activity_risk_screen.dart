import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/activity_risk_assessment.dart';
import 'package:admin_app/services/activity_risk_service.dart';
import 'package:admin_app/ui/risk/activity_risk_form.dart';

class ActivityRiskScreen extends StatefulWidget {
  final String? serviceUserId;
  const ActivityRiskScreen({super.key, this.serviceUserId});
  @override
  State<ActivityRiskScreen> createState() => _ActivityRiskScreenState();
}

class _ActivityRiskScreenState extends State<ActivityRiskScreen> {
  final _service = ActivityRiskService(Supabase.instance.client);
  List<ActivityRiskAssessment> _assessments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = widget.serviceUserId != null
          ? await _service.getAssessmentsByServiceUser(widget.serviceUserId!)
          : await _service.getAllAssessments();
      setState(() { _assessments = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Risk Assessments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ActivityRiskForm(serviceUserId: widget.serviceUserId)))
          .then((_) => _load()),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assessments.isEmpty
              ? const Center(child: Text('No activity risk assessments found'))
              : ListView.builder(
                  itemCount: _assessments.length,
                  itemBuilder: (_, i) {
                    final a = _assessments[i];
                    return ListTile(
                      title: Text(a.getActivityTypeDisplay()),
                      subtitle: Text('Risk: ${a.riskLevel} — Review: ${a.reviewDate.toString().split(' ').first}'),
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ActivityRiskForm(assessmentId: a.id, serviceUserId: widget.serviceUserId)))
                        .then((_) => _load()),
                    );
                  },
                ),
    );
  }
}