import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/ui/monitoring/stool_log_form.dart';

class StoolLogScreen extends StatefulWidget {
  final String? serviceUserId;
  const StoolLogScreen({super.key, this.serviceUserId});

  @override
  State<StoolLogScreen> createState() => _StoolLogScreenState();
}

class _StoolLogScreenState extends State<StoolLogScreen> {
  List<Map<String, dynamic>> _entries = [];
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
    setState(() => _loading = true);
    try {
      var query = Supabase.instance.client.from('stool_logs').select();
      if (widget.serviceUserId != null) {
        query = query.eq('service_user_id', widget.serviceUserId!);
      }
      final data = await query.order('time', ascending: false).limit(50);
      setState(() {
        _entries = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  IconData _getBristolIcon(int? scale) {
    switch (scale) {
      case 1: return Icons.sentiment_very_dissatisfied;
      case 2: return Icons.sentiment_dissatisfied;
      case 3: return Icons.sentiment_satisfied;
      case 4: return Icons.sentiment_satisfied;
      case 5: return Icons.sentiment_dissatisfied;
      case 6: return Icons.sentiment_very_dissatisfied;
      case 7: return Icons.sentiment_very_dissatisfied;
      default: return Icons.help_outline;
    }
  }

  Color _getBristolColor(int? scale) {
    switch (scale) {
      case 1: return Colors.brown.shade800;
      case 2: return Colors.brown.shade700;
      case 3: return Colors.green.shade600;
      case 4: return Colors.green.shade400;
      case 5: return Colors.orange.shade400;
      case 6: return Colors.orange.shade600;
      case 7: return Colors.blue.shade400;
      default: return Colors.grey;
    }
  }

  String _getBristolDescription(int? scale) {
    switch (scale) {
      case 1: return 'Hard lumps';
      case 2: return 'Lumpy sausage';
      case 3: return 'Cracked sausage';
      case 4: return 'Smooth sausage';
      case 5: return 'Soft blobs';
      case 6: return 'Mushy';
      case 7: return 'Liquid';
      default: return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stool Log'), backgroundColor: const Color(0xFF4CAF50)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => StoolLogForm(serviceUserId: widget.serviceUserId)))
              .then((_) => _load());
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('No stool log entries found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) {
                      final entry = _entries[i];
                      final time = entry['time'] != null
                          ? DateTime.parse(entry['time'])
                          : null;
                      final scale = entry['bristol_stool_type'];
                      final userName = entry['service_user_name'] ?? _serviceUserNames[entry['service_user_id']] ?? 'Unknown';
                      final colour = entry['colour'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getBristolColor(scale).withOpacity(0.2),
                            child: Icon(_getBristolIcon(scale), color: _getBristolColor(scale)),
                          ),
                          title: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${time?.day}/${time?.month}/${time?.year} ${time?.hour.toString().padLeft(2, '0')}:${time?.minute.toString().padLeft(2, '0')}'),
                              Text('Type: ${_getBristolDescription(scale)} • ${colour ?? "N/A"}'),
                            ],
                          ),
                          trailing: entry['notes'] != null && entry['notes'].toString().isNotEmpty
                              ? const Icon(Icons.notes, color: Colors.grey)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}