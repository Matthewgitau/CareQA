import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meeting.dart';
import '../../services/meeting_service.dart';
import '../../widgets/reusable_form_widgets.dart';

class MeetingFormScreen extends StatefulWidget {
  final Meeting? meeting;

  const MeetingFormScreen({super.key, this.meeting});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _service = MeetingService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _agendaController = TextEditingController();
  final _minutesController = TextEditingController();
  final _discussionController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedType;
  String _status = 'scheduled';
  DateTime _meetingDate = DateTime.now();
  String _startTime = '09:00';
  String _endTime = '10:00';
  bool _isOnline = false;
  String? _meetingLink;
  bool _isConfidential = false;
  bool _isSaving = false;

  final List<String> _meetingTypes = [
    'team_meeting', 'handover', 'supervision', 'training_session',
    'emergency_meeting', 'management_meeting', 'care_plan_review',
    'service_user_review', 'incident_review', 'audit_review', 'other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.meeting != null) {
      _populateForm(widget.meeting!);
    } else {
      _selectedType = _meetingTypes.first;
    }
  }

  void _populateForm(Meeting meeting) {
    _selectedType = meeting.meetingType;
    _titleController.text = meeting.meetingTitle;
    _meetingDate = meeting.meetingDate;
    _startTime = meeting.startTime;
    _endTime = meeting.endTime;
    _locationController.text = meeting.location ?? '';
    _isOnline = meeting.isOnline;
    _meetingLink = meeting.meetingLink;
    _agendaController.text = meeting.agenda ?? '';
    _minutesController.text = meeting.minutes ?? '';
    _discussionController.text = meeting.keyDiscussionPoints ?? '';
    _status = meeting.status;
    _isConfidential = meeting.isConfidential;
    _notesController.text = meeting.notes ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _agendaController.dispose();
    _minutesController.dispose();
    _discussionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final meeting = Meeting(
        id: widget.meeting?.id ?? '',
        meetingTitle: _titleController.text,
        meetingType: _selectedType ?? 'other',
        meetingDate: _meetingDate,
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        isOnline: _isOnline,
        meetingLink: _meetingLink,
        agenda: _agendaController.text.isNotEmpty ? _agendaController.text : null,
        minutes: _minutesController.text.isNotEmpty ? _minutesController.text : null,
        keyDiscussionPoints: _discussionController.text.isNotEmpty ? _discussionController.text : null,
        status: _status,
        isConfidential: _isConfidential,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: widget.meeting?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.meeting != null) {
        await _service.updateMeeting(widget.meeting!.id, meeting);
      } else {
        await _service.createMeeting(meeting);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.meeting != null ? 'Meeting updated' : 'Meeting created'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meeting != null ? 'Edit Meeting' : 'New Meeting'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.meeting != null ? 'Update' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Meeting Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Meeting Title *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Meeting Type
            StaticDropdown(
              selectedValue: _selectedType,
              onChanged: (v) => setState(() => _selectedType = v),
              labelText: 'Meeting Type *',
              options: _meetingTypes,
              required: true,
            ),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _meetingDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _meetingDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Meeting Date *',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_meetingDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Time
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(DateTime.parse('2000-01-01 $_startTime')),
                      );
                      if (picked != null) {
                        setState(() => _startTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_startTime),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(DateTime.parse('2000-01-01 $_endTime')),
                      );
                      if (picked != null) {
                        setState(() => _endTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_endTime),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Online Meeting
            SwitchListTile(
              title: const Text('Online Meeting'),
              subtitle: const Text('This is a virtual meeting'),
              value: _isOnline,
              onChanged: (v) => setState(() => _isOnline = v),
            ),
            if (_isOnline) ...[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Meeting Link',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _meetingLink = v,
              ),
              const SizedBox(height: 16),
            ],

            // Agenda
            TextFormField(
              controller: _agendaController,
              decoration: const InputDecoration(
                labelText: 'Agenda',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Minutes
            TextFormField(
              controller: _minutesController,
              decoration: const InputDecoration(
                labelText: 'Minutes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Key Discussion Points
            TextFormField(
              controller: _discussionController,
              decoration: const InputDecoration(
                labelText: 'Key Discussion Points',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Status
            StaticDropdown(
              selectedValue: _status,
              onChanged: (v) => setState(() => _status = v ?? 'scheduled'),
              labelText: 'Status *',
              options: ['scheduled', 'in_progress', 'completed', 'cancelled', 'postponed'],
              required: true,
            ),
            const SizedBox(height: 16),

            // Confidential
            SwitchListTile(
              title: const Text('Confidential'),
              subtitle: const Text('Mark as confidential'),
              value: _isConfidential,
              onChanged: (v) => setState(() => _isConfidential = v),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.meeting != null ? 'Update Meeting' : 'Create Meeting', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}