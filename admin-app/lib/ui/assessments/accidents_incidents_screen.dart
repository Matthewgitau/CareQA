import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/ui/safeguarding/accidents_incidents_form.dart';

class AccidentsIncidentsScreen extends StatefulWidget {
  const AccidentsIncidentsScreen({super.key});

  @override
  State<AccidentsIncidentsScreen> createState() =>
      _AccidentsIncidentsScreenState();
}

class _AccidentsIncidentsScreenState
    extends State<AccidentsIncidentsScreen> {
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
          .from('accidents_incidents')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      setState(() {
        _items = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accidents & Incidents')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No records found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) => Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          _items[i]['incident_type']?.toString() ??
                              'Unknown Type',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Date: ${_items[i]['incident_date']?.toString() ?? 'Unknown'}'),
                            Text(
                                'Severity: ${_items[i]['severity']?.toString() ?? 'Unknown'}'),
                            Text(
                              'Status: ${_items[i]['status']?.toString() ?? 'Unknown'}',
                              style: TextStyle(
                                color: _items[i]['status'] == 'closed'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing:
                            const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AccidentsIncidentsForm(),
            ),
          );
          if (result == true) _load();
        },
        tooltip: 'New Incident',
        child: const Icon(Icons.add),
      ),
    );
  }
}