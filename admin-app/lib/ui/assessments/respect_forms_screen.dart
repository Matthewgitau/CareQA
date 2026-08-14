import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/ui/assessments/respect_form.dart';

class RespectFormsScreen extends StatefulWidget {
  const RespectFormsScreen({super.key});
  @override
  State<RespectFormsScreen> createState() => _RespectFormsScreenState();
}

class _RespectFormsScreenState extends State<RespectFormsScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _forms = [];
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
          .from('respect_forms')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      if (_selectedServiceUserId != null) {
        final userId = _selectedServiceUserId!;
        query = _client
            .from('respect_forms')
            .select()
            .eq('service_user_id', userId)
            .order('created_at', ascending: false)
            .limit(50);
      }

      final data = await query;
      setState(() {
        _forms = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RESPECT Forms'),
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

          // Forms list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _forms.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No RESPECT forms found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _forms.length,
                        itemBuilder: (_, i) {
                          final f = _forms[i];
                          final serviceUserName = f['service_user_name'] as String? ?? 'Unknown';
                          final status = f['status'] as String? ?? 'draft';
                          final statusColor = status == 'completed' ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
                          final assessmentDate = (f['assessment_date'] ?? '').toString().split('T').first;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                                child: const Icon(Icons.favorite, color: Color(0xFF1565C0), size: 24),
                              ),
                              title: Text(
                                serviceUserName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Date: $assessmentDate',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              onTap: () => _showForm(context, f),
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
        builder: (_) => RespectForm(
          assessmentId: existing?['id'] as String?,
        ),
      ),
    ).then((_) => _load());
  }
}