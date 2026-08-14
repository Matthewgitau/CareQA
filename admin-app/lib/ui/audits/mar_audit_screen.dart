import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/supabase_auth_service.dart';
import 'package:admin_app/services/mar_audit_service.dart';
import 'package:admin_app/ui/audit/mar_audit_form.dart';

class MarAuditScreen extends StatefulWidget {
  const MarAuditScreen({super.key});
  @override
  State<MarAuditScreen> createState() => _MarAuditScreenState();
}

class _MarAuditScreenState extends State<MarAuditScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('mar_audits')
          .select('id, service_user_name, audit_date, assessor_name, status, created_at')
          .order('audit_date', ascending: false)
          .limit(50);
      setState(() { 
        _items = List<Map<String, dynamic>>.from(data); 
        _loading = false; 
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _openAuditForm() async {
    final supabase = Supabase.instance.client;
    final serviceUsers = await supabase
        .from('service_users')
        .select('id, name')
        .order('name');

    if (!mounted) return;

    if (serviceUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No service users found. Please add a service user first.')),
      );
      return;
    }

    String? selectedId;
    String? selectedName;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Service User'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: serviceUsers.length,
              itemBuilder: (context, index) {
                final su = serviceUsers[index];
                final name = su['name']?.toString() ?? 'Unknown';
                return ListTile(
                  title: Text(name),
                  onTap: () {
                    selectedId = su['id'].toString();
                    selectedName = name;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedId == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarAuditForm(
          serviceUserId: selectedId!,
          serviceUserName: selectedName!,
        ),
      ),
    ).then((result) {
      if (result == true) _load();
    });
  }

  void _viewAuditDetails(String auditId) {
    // Navigate to audit details view
    // This would be implemented based on your audit details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing audit details for ID: $auditId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAR Audit'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No MAR audits found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          _items[i]['service_user_name']?.toString() ?? 'Unknown Service User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Auditor: ${_items[i]['assessor_name'] ?? 'Unknown'}'),
                            Text('Date: ${_items[i]['audit_date']?.toString() ?? 'Unknown'}'),
                            Text(
                              'Status: ${_items[i]['status']?.toString() ?? 'Unknown'}',
                              style: TextStyle(
                                color: _items[i]['status'] == 'completed' 
                                  ? Colors.green 
                                  : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _viewAuditDetails(_items[i]['id'].toString()),
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAuditForm,
        tooltip: 'Create New MAR Audit',
        child: const Icon(Icons.add),
      ),
    );
  }
}
