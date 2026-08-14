import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meeting_type.dart';
import '../../services/meeting_service.dart';

class MeetingTypeManagementScreen extends StatefulWidget {
  const MeetingTypeManagementScreen({super.key});

  @override
  State<MeetingTypeManagementScreen> createState() => _MeetingTypeManagementScreenState();
}

class _MeetingTypeManagementScreenState extends State<MeetingTypeManagementScreen> {
  final _service = MeetingService(Supabase.instance.client);
  List<MeetingType> _meetingTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetingTypes();
  }

  Future<void> _loadMeetingTypes() async {
    setState(() => _isLoading = true);
    try {
      final types = await _service.getMeetingTypes();
      if (mounted) {
        setState(() {
          _meetingTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meeting types: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Types'),
        actions: [
          IconButton(
            onPressed: _loadMeetingTypes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meetingTypes.isEmpty
              ? const Center(child: Text('No meeting types found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _meetingTypes.length,
                  itemBuilder: (context, index) {
                    final type = _meetingTypes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: type.cqcRelevant ? Colors.red : Colors.blue,
                          child: Icon(type.cqcRelevant ? Icons.verified : Icons.meeting_room, color: Colors.white),
                        ),
                        title: Text(
                          type.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (type.description != null) Text(type.description!),
                            Text('Duration: ${type.defaultDurationMinutes} min'),
                            Row(
                              children: [
                                if (type.requiresAgenda) const Icon(Icons.check, size: 16, color: Colors.green),
                                if (type.requiresAgenda) const SizedBox(width: 4),
                                if (type.requiresAgenda) const Text('Agenda'),
                                if (type.requiresAgenda && type.requiresMinutes) const SizedBox(width: 12),
                                if (type.requiresMinutes) const Icon(Icons.check, size: 16, color: Colors.green),
                                if (type.requiresMinutes) const SizedBox(width: 4),
                                if (type.requiresMinutes) const Text('Minutes'),
                              ],
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: type.isActive,
                          onChanged: (v) {
                            // Toggle active status
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}