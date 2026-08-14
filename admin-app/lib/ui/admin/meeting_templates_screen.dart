import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meeting_template.dart';\r\nimport '../../ui/admin/meeting_form.dart';
import '../../services/meeting_service.dart';

class MeetingTemplatesScreen extends StatefulWidget {
  const MeetingTemplatesScreen({super.key});

  @override
  State<MeetingTemplatesScreen> createState() => _MeetingTemplatesScreenState();
}

class _MeetingTemplatesScreenState extends State<MeetingTemplatesScreen> {
  final _service = MeetingService(Supabase.instance.client);
  List<MeetingTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _service.getMeetingTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Templates'),
        actions: [
          IconButton(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? const Center(child: Text('No templates found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: const Icon(Icons.description, color: Colors.white),
                        ),
                        title: Text(
                          template.templateName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(template.meetingType.replaceAll('_', ' ').toUpperCase()),
                            if (template.defaultAgenda != null)
                              Text(
                                template.defaultAgenda!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (template.defaultAttendees.isNotEmpty)
                              Text('${template.defaultAttendees.length} default attendees'),
                          ],
                        ),
                        trailing: Icon(
                          template.isOnline ? Icons.video_call : Icons.location_on,
                          color: Colors.grey,
                        ),
                        onTap: () => _useTemplate(template),
                      ),
                    );
                  },
                ),
    );
  }

  void _useTemplate(MeetingTemplate template) async {
    try {
      final meeting = await _service.createMeetingFromTemplate(template.id);
      if (mounted && meeting != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting created from template'), backgroundColor: Colors.green),
        );
        // Navigate to meeting form to edit
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeetingFormScreen(meeting: meeting),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
