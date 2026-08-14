import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meeting.dart';
import '../../services/meeting_service.dart';
import 'meeting_form.dart';

class MeetingsLogScreen extends StatefulWidget {
  const MeetingsLogScreen({super.key});

  @override
  State<MeetingsLogScreen> createState() => _MeetingsLogScreenState();
}

class _MeetingsLogScreenState extends State<MeetingsLogScreen> with SingleTickerProviderStateMixin {
  final _service = MeetingService(Supabase.instance.client);
  List<Meeting> _meetings = [];
  List<Meeting> _filteredMeetings = [];
  bool _isLoading = true;
  String? _selectedType;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    try {
      final meetings = await _service.getMeetings();
      if (mounted) {
        setState(() {
          _meetings = meetings;
          _filteredMeetings = meetings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meetings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterMeetings() {
    setState(() {
      _filteredMeetings = _meetings.where((meeting) {
        final matchesType = _selectedType == null || meeting.meetingType == _selectedType;
        final matchesStatus = _selectedStatus == null || meeting.status == _selectedStatus;
        final matchesDateRange = (_startDate == null || meeting.meetingDate.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
            (_endDate == null || meeting.meetingDate.isBefore(_endDate!.add(const Duration(days: 1))));
        final matchesSearch = _searchController.text.isEmpty ||
            meeting.meetingTitle.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (meeting.chairPersonName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
        return matchesType && matchesStatus && matchesDateRange && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings Log'),
        actions: [
          IconButton(
            onPressed: _loadMeetings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                _buildFilters(),
                // Meetings List
                Expanded(
                  child: _filteredMeetings.isEmpty
                      ? const Center(child: Text('No meetings found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredMeetings.length,
                          itemBuilder: (context, index) {
                            final meeting = _filteredMeetings[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getMeetingTypeColor(meeting.meetingType),
                                  child: Icon(_getMeetingTypeIcon(meeting.meetingType), color: Colors.white),
                                ),
                                title: Text(
                                  meeting.meetingTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(meeting.getMeetingTypeDisplay()),
                                    Text('${DateFormat('dd/MM/yyyy').format(meeting.meetingDate)} • ${meeting.startTime} - ${meeting.endTime}'),
                                    if (meeting.attendeesCount != null)
                                      Text('Attendees: ${meeting.attendeesCount}'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(meeting.status),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        meeting.getStatusDisplay(),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (meeting.cqcComplianceChecked)
                                      const Icon(Icons.verified, size: 16, color: Colors.green),
                                  ],
                                ),
                                onTap: () => _viewMeetingDetails(meeting),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMeeting,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search meetings',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => _filterMeetings(),
          ),
          const SizedBox(height: 12),
          // Filters Row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Types')),
                    ...['team_meeting', 'handover', 'supervision', 'training_session', 'emergency_meeting', 'management_meeting', 'care_plan_review', 'service_user_review', 'incident_review', 'audit_review'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type.replaceAll('_', ' ').toUpperCase()));
                    }),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedType = v);
                    _filterMeetings();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    DropdownMenuItem(value: 'postponed', child: Text('Postponed')),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedStatus = v);
                    _filterMeetings();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMeetingTypeColor(String type) {
    switch (type) {
      case 'team_meeting': return Colors.blue;
      case 'handover': return Colors.orange;
      case 'supervision': return Colors.purple;
      case 'training_session': return Colors.green;
      case 'emergency_meeting': return Colors.red;
      case 'management_meeting': return Colors.teal;
      case 'care_plan_review': return Colors.pink;
      case 'service_user_review': return Colors.indigo;
      case 'incident_review': return Colors.deepOrange;
      case 'audit_review': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getMeetingTypeIcon(String type) {
    switch (type) {
      case 'team_meeting': return Icons.people;
      case 'handover': return Icons.swap_horiz;
      case 'supervision': return Icons.person;
      case 'training_session': return Icons.school;
      case 'emergency_meeting': return Icons.warning;
      case 'management_meeting': return Icons.business;
      case 'care_plan_review': return Icons.favorite;
      case 'service_user_review': return Icons.visibility;
      case 'incident_review': return Icons.report;
      case 'audit_review': return Icons.assignment;
      default: return Icons.meeting_room;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'postponed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  void _viewMeetingDetails(Meeting meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meeting.meetingTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', meeting.getMeetingTypeDisplay()),
              _buildDetailRow('Date', DateFormat('dd/MM/yyyy').format(meeting.meetingDate)),
              _buildDetailRow('Time', '${meeting.startTime} - ${meeting.endTime}'),
              if (meeting.durationMinutes != null)
                _buildDetailRow('Duration', '${meeting.durationMinutes} minutes'),
              if (meeting.location != null)
                _buildDetailRow('Location', meeting.location!),
              _buildDetailRow('Status', meeting.getStatusDisplay()),
              if (meeting.chairPersonName != null)
                _buildDetailRow('Chair', meeting.chairPersonName!),
              if (meeting.attendeesCount != null)
                _buildDetailRow('Attendees', '${meeting.attendeesCount}'),
              if (meeting.minutes != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Minutes:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(meeting.minutes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editMeeting(meeting);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addMeeting() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MeetingFormScreen()),
    );
    if (result == true) {
      _loadMeetings();
    }
  }

  void _editMeeting(Meeting meeting) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeetingFormScreen(meeting: meeting)),
    );
    if (result == true) {
      _loadMeetings();
    }
  }
}