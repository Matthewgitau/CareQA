import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GrabsheetScreen extends StatefulWidget {
  const GrabsheetScreen({super.key});
  @override
  State<GrabsheetScreen> createState() => _GrabsheetScreenState();
}

class _GrabsheetScreenState extends State<GrabsheetScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('service_users')
          .select('id, name, date_of_birth, address, emergency_contact_name, emergency_contact_phone, gp_name, gp_phone')
          .eq('is_active', true)
          .order('name');
      setState(() { _users = List<Map<String, dynamic>>.from(data as List); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service User Grab Sheets')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No service users found'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ExpansionTile(
                        title: Text(u['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(u['date_of_birth'] ?? ''),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (u['address'] != null) Text('Address: ${u['address']}'),
                              if (u['emergency_contact_name'] != null) Text('Emergency Contact: ${u['emergency_contact_name']}'),
                              if (u['emergency_contact_phone'] != null) Text('Emergency Phone: ${u['emergency_contact_phone']}'),
                              if (u['gp_name'] != null) Text('GP: ${u['gp_name']}'),
                              if (u['gp_phone'] != null) Text('GP Phone: ${u['gp_phone']}'),
                            ]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}