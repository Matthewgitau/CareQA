import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/ui/monitoring/temperature_log_form.dart';

class TemperatureLogScreen extends StatefulWidget {
  final String? serviceUserId;
  const TemperatureLogScreen({super.key, this.serviceUserId});

  @override
  State<TemperatureLogScreen> createState() => _TemperatureLogScreenState();
}

class _TemperatureLogScreenState extends State<TemperatureLogScreen> {
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
      var query = Supabase.instance.client.from('temperature_logs').select();
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

  Color _getTemperatureColor(double temp) {
    if (temp >= 38.0) return Colors.red;
    if (temp >= 37.5) return Colors.orange;
    if (temp < 36.0) return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temperature Log'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('No temperature log entries found'))
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
                      final temp = (entry['temperature'] as num?)?.toDouble();
                      final location = entry['location']?.toString() ?? '';
                      final userName = _serviceUserNames[entry['service_user_id']] ?? 'Unknown';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: temp != null
                                ? _getTemperatureColor(temp)
                                : Colors.grey,
                            child: Text(
                              temp != null ? '${temp.toStringAsFixed(1)}°' : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${time?.day}/${time?.month}/${time?.year} ${time?.hour.toString().padLeft(2, '0')}:${time?.minute.toString().padLeft(2, '0')}'
                            '${location.isNotEmpty ? " • $location" : ""}',
                          ),
                          trailing: (entry['symptoms'] as List?)?.isNotEmpty == true
                              ? const Icon(Icons.warning, color: Colors.orange)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TemperatureLogForm(serviceUserId: widget.serviceUserId),
            ),
          ).then((_) => _load());
        },
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}