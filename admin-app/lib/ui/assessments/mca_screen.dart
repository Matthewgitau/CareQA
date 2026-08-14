import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/mca_assessment.dart';
import 'package:admin_app/services/mca_service.dart';
import 'package:admin_app/ui/assessments/mca_form.dart';

class McaScreen extends StatefulWidget {
  const McaScreen({super.key});
  @override
  State<McaScreen> createState() => _McaScreenState();
}

class _McaScreenState extends State<McaScreen> {
  List<Map<String, dynamic>> _serviceUsers = [];
  List<McaAssessment> _recentAssessments = [];
  bool _loading = true;
  final _mcaService = McaService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      final assessments = await _mcaService.getAllAssessments();
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(users as List);
        _recentAssessments = assessments;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showServiceUserPicker(String decisionType, String decisionLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Service User — $decisionLabel',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _serviceUsers.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_serviceUsers[i]['name'] ?? ''),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => McaForm(
                        serviceUserId: _serviceUsers[i]['id'] as String,
                        serviceUserName: _serviceUsers[i]['name'] as String,
                        decisionType: decisionType,
                      ),
                    )).then((_) => _load());
                  },
                ),
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
      appBar: AppBar(title: const Text('Mental Capacity Assessments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Select Assessment Type',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the decision area to assess under the Mental Capacity Act 2005.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ...McaAssessment.decisionTypeLabels.entries.map((entry) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology, color: Colors.white, size: 22),
                      ),
                      title: Text(entry.value,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('MCA 2005 — ${entry.value} decision'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showServiceUserPicker(entry.key, entry.value),
                    ),
                  )),
                  const SizedBox(height: 24),
                  if (_recentAssessments.isNotEmpty) ...[
                    const Text('Recent Assessments',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._recentAssessments.take(10).map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => McaForm(
                                serviceUserId: a.serviceUserId,
                                serviceUserName: a.serviceUserName,
                                decisionType: a.decisionType,
                                existing: a,
                              ),
                            ),
                          ).then((_) => _load());
                        },
                        title: Text(a.serviceUserName),
                        subtitle: Text('${a.decisionTypeLabel} — ${a.assessmentDate.toString().split(' ').first}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: a.lacksCapacity ? Colors.red[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            a.lacksCapacity ? 'Lacks Capacity' : 'Has Capacity',
                            style: TextStyle(
                              fontSize: 11,
                              color: a.lacksCapacity ? Colors.red[800] : Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
    );
  }
}