import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/daily_note.dart';
import 'package:admin_app/services/daily_note_service.dart';
import 'package:admin_app/ui/monitoring/daily_note_form.dart';

class DailyNoteScreen extends StatefulWidget {
  final String? serviceUserId;
  const DailyNoteScreen({super.key, this.serviceUserId});

  @override
  State<DailyNoteScreen> createState() => _DailyNoteScreenState();
}

class _DailyNoteScreenState extends State<DailyNoteScreen> {
  final _service = DailyNoteService(Supabase.instance.client);
  List<DailyNote> _notes = [];
  List<Map<String, dynamic>> _serviceUsers = [];
  Map<String, String> _serviceUserNames = {};
  String? _selectedServiceUserId;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedServiceUserId = widget.serviceUserId;
    _loadServiceUsers();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final data = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      final users = List<Map<String, dynamic>>.from(data as List);
      _serviceUserNames = {for (final u in users) u['id'] as String: u['name'] as String};
      setState(() => _serviceUsers = users);
    } catch (_) {}
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _notes = await _service.getNotes(serviceUserId: _selectedServiceUserId);
    } catch (_) {
      _notes = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  String _visitIcon(String type) {
    switch (type) {
      case 'morning': return '🌅';
      case 'lunch': return '🍽️';
      case 'tea': return '☕';
      case 'evening': return '🌙';
      default: return '📝';
    }
  }

  String _careIcon(String status) {
    switch (status) {
      case 'accepted': return '✅';
      case 'partial': return '⚠️';
      case 'refused': return '❌';
      default: return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Notes'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyNoteForm())).then((_) => _load()),
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: DropdownButtonFormField<String?>(
              value: _selectedServiceUserId,
              decoration: InputDecoration(
                labelText: 'Service User',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ..._serviceUsers.map((u) => DropdownMenuItem(
                  value: u['id'] as String,
                  child: Text(u['name'] as String),
                )),
              ],
              onChanged: (v) { setState(() => _selectedServiceUserId = v); _load(); },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? const Center(child: Text('No daily notes found'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _notes.length,
                          itemBuilder: (_, i) {
                            final n = _notes[i];
                            final name = n.serviceUserId != null
                                ? _serviceUserNames[n.serviceUserId] ?? n.serviceUserName ?? 'Unknown'
                                : 'Unknown';
                            final emojis = n.emotionalState?.map((e) => EmotionalStateHelper.emojis[e] ?? '').join(' ') ?? '';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(_visitIcon(n.visitType), style: const TextStyle(fontSize: 20)),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${_visitIcon(n.visitType)} ${n.visitType.toUpperCase()} • ${_careIcon(n.careAccepted)} ${n.careAccepted} | ${n.visitDate.toString().split(' ').first}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: emojis.isNotEmpty
                                    ? Text(emojis, style: const TextStyle(fontSize: 16))
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}