import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/bed_railing_assessment.dart';
import 'package:admin_app/services/bed_railing_service.dart';
import 'package:admin_app/ui/risk/bed_railing_form.dart';

class BedRailingScreen extends StatefulWidget {
  final String? serviceUserId;
  const BedRailingScreen({super.key, this.serviceUserId});
  @override
  State<BedRailingScreen> createState() => _BedRailingScreenState();
}

class _BedRailingScreenState extends State<BedRailingScreen> {
  final _service = BedRailingService(Supabase.instance.client);
  List<BedRailingAssessment> _assessments = [];
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
    } catch (_) {
      // ignore
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getAssessments(serviceUserId: widget.serviceUserId);
      setState(() { _assessments = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bed Railing Risk Assessments (LOLER)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BedRailingForm(serviceUserId: widget.serviceUserId),
            ),
          ).then((_) => _load());
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assessments.isEmpty
              ? const Center(child: Text('No bed railing assessments found'))
              : ListView.builder(
                  itemCount: _assessments.length,
                  itemBuilder: (_, i) {
                    final a = _assessments[i];
                    final userName = a.serviceUserId != null
                        ? _serviceUserNames[a.serviceUserId] ?? 'Unknown'
                        : 'Unknown';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: a.isHighRisk
                              ? Colors.red.withOpacity(0.1)
                              : a.riskOfFallingOutOfBed == 'medium' || a.riskOfEntrapment == 'medium'
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                          child: Icon(
                            a.isHighRisk ? Icons.warning : Icons.check_circle,
                            color: a.isHighRisk ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Bed: ${a.bedTypeText} | Fall risk: ${a.riskOfFallingOutOfBed.toUpperCase()} | Entrapment: ${a.riskOfEntrapment.toUpperCase()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(a.isLOLERCompliant ? '✅ LOLER' : '⚠️ Non-compliant'),
                      ),
                    );
                  },
                ),
    );
  }
}