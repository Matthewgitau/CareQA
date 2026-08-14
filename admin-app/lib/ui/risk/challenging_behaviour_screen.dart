import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/challenging_behaviour_assessment.dart';
import 'package:admin_app/services/challenging_behaviour_service.dart';
import 'package:admin_app/ui/risk/challenging_behaviour_form.dart';

class ChallengingBehaviourScreen extends StatefulWidget {
  final String? serviceUserId;
  const ChallengingBehaviourScreen({super.key, this.serviceUserId});
  @override
  State<ChallengingBehaviourScreen> createState() => _ChallengingBehaviourScreenState();
}

class _ChallengingBehaviourScreenState extends State<ChallengingBehaviourScreen> {
  final _service = ChallengingBehaviourService(Supabase.instance.client);
  List<ChallengingBehaviourAssessment> _assessments = [];
  Map<String, String> _serviceUserNames = {};
  bool _loading = true;
  String? _error;

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
    } catch (_) {
      // ignore
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAssessments(serviceUserId: widget.serviceUserId);
      setState(() { _assessments = data; _loading = false; _error = null; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'critical': return Colors.red[900]!;
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Challenging Behaviour Assessments (PBS)')),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengingBehaviourForm(serviceUserId: widget.serviceUserId),
              ),
            ).then((_) => _load());
          },
          child: const Icon(Icons.add),
        ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading assessments', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _assessments.isEmpty
                  ? const Center(child: Text('No challenging behaviour assessments found'))
                  : ListView.builder(
                      itemCount: _assessments.length,
                      itemBuilder: (_, i) {
                        final a = _assessments[i];
                        final userName = a.serviceUserId != null
                            ? _serviceUserNames[a.serviceUserId] ?? 'Unknown'
                            : 'Unknown';
                        final riskColor = _riskColor(a.riskLevel);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: riskColor.withOpacity(0.1),
                              child: Icon(
                                a.riskLevel == 'critical' ? Icons.gpp_bad :
                                a.riskLevel == 'high' ? Icons.warning : Icons.check_circle,
                                color: riskColor,
                              ),
                            ),
                            title: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              'Behaviour: ${a.behaviourTypeText} | Risk: ${a.riskLevel.toUpperCase()} | ${a.assessmentDate.toString().split(' ').first}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: riskColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                a.riskLevel.toUpperCase(),
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