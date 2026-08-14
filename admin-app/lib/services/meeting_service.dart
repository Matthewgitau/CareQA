import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meeting.dart';
import '../models/meeting_type.dart';
import '../models/meeting_template.dart';

class MeetingService {
  final SupabaseClient _client;

  MeetingService(this._client);

  // ==================== MEETINGS ====================

  Future<Meeting?> createMeeting(Meeting meeting) async {
    try {
      final data = meeting.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');
      data.remove('duration_minutes');
      data.remove('attendees_count');
      data.remove('apologies_count');

      // Get organisation_id for RLS
      final user = _client.auth.currentUser;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('organisation_id')
            .eq('id', user.id)
            .single();
        data['organisation_id'] = profile['organisation_id'];
        data['created_by'] = user.id;
      }

      final response = await _client
          .from('meetings')
          .insert(data)
          .select()
          .single();

      return Meeting.fromJson(response);
    } catch (e) {
      print('Error creating meeting: $e');
      rethrow;
    }
  }

  Future<List<Meeting>> getMeetings() async {
    try {
      final response = await _client
          .from('meetings')
          .select('*')
          .order('meeting_date', ascending: false);
      return (response as List).map((json) => Meeting.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching meetings: $e');
      return [];
    }
  }

  Future<Meeting?> getMeeting(String id) async {
    try {
      final response = await _client
          .from('meetings')
          .select('*')
          .eq('id', id)
          .single();
      return Meeting.fromJson(response);
    } catch (e) {
      print('Error fetching meeting: $e');
      return null;
    }
  }

  Future<Meeting?> updateMeeting(String id, Meeting meeting) async {
    try {
      final data = meeting.toJson();
      data.remove('created_at');
      data.remove('updated_at');
      data.remove('duration_minutes');
      data.remove('attendees_count');
      data.remove('apologies_count');

      final response = await _client
          .from('meetings')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return Meeting.fromJson(response);
    } catch (e) {
      print('Error updating meeting: $e');
      rethrow;
    }
  }

  Future<void> deleteMeeting(String id) async {
    try {
      await _client
          .from('meetings')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting meeting: $e');
      rethrow;
    }
  }

  // ==================== MEETING TYPES ====================

  Future<List<MeetingType>> getMeetingTypes() async {
    try {
      final response = await _client
          .from('meeting_type_reference')
          .select('*')
          .eq('is_active', true)
          .order('display_name', ascending: true);
      return (response as List).map((json) => MeetingType.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching meeting types: $e');
      return [];
    }
  }

  // ==================== MEETING TEMPLATES ====================

  Future<List<MeetingTemplate>> getMeetingTemplates() async {
    try {
      final response = await _client
          .from('meeting_templates')
          .select('*')
          .eq('is_active', true)
          .order('template_name', ascending: true);
      return (response as List).map((json) => MeetingTemplate.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching meeting templates: $e');
      return [];
    }
  }

  Future<MeetingTemplate?> createMeetingTemplate(MeetingTemplate template) async {
    try {
      final data = template.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      final user = _client.auth.currentUser;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('organisation_id')
            .eq('id', user.id)
            .single();
        data['organisation_id'] = profile['organisation_id'];
      }

      final response = await _client
          .from('meeting_templates')
          .insert(data)
          .select()
          .single();

      return MeetingTemplate.fromJson(response);
    } catch (e) {
      print('Error creating meeting template: $e');
      rethrow;
    }
  }

  Future<Meeting?> createMeetingFromTemplate(String templateId) async {
    try {
      final template = await _client
          .from('meeting_templates')
          .select('*')
          .eq('id', templateId)
          .single();

      final meeting = Meeting(
        id: '',
        meetingTitle: 'New ${template['meeting_type']}',
        meetingType: template['meeting_type'],
        meetingDate: DateTime.now(),
        startTime: '09:00',
        endTime: '10:00',
        agenda: template['default_agenda'],
        location: template['default_location'],
        isOnline: template['is_online'] ?? false,
        meetingLink: template['meeting_link_template'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return createMeeting(meeting);
    } catch (e) {
      print('Error creating meeting from template: $e');
      rethrow;
    }
  }

  // ==================== ACTION ITEMS ====================

  Future<void> addActionItem(String meetingId, Map<String, dynamic> actionItem) async {
    try {
      final meeting = await getMeeting(meetingId);
      if (meeting == null) return;

      final actionItems = List<dynamic>.from(meeting.actionItems);
      actionItems.add(actionItem);

      await _client
          .from('meetings')
          .update({'action_items': actionItems})
          .eq('id', meetingId);
    } catch (e) {
      print('Error adding action item: $e');
      rethrow;
    }
  }

  // ==================== APPROVALS ====================

  Future<void> approveMinutes(String meetingId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client
          .from('meetings')
          .update({
            'minuted_approved': true,
            'minuted_approved_at': DateTime.now().toIso8601String(),
            'minuted_approved_by': user.id,
          })
          .eq('id', meetingId);
    } catch (e) {
      print('Error approving minutes: $e');
      rethrow;
    }
  }

  // ==================== SUMMARY ====================

  Future<Map<String, dynamic>> getMeetingSummary() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return {};

      final profile = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', user.id)
          .single();

      final orgId = profile['organisation_id'];

      // Use the database function
      final response = await _client
          .rpc('get_meeting_summary', params: {
        'p_org_id': orgId,
        'p_start_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T').first,
        'p_end_date': DateTime.now().toIso8601String().split('T').first,
      });

      if (response.isNotEmpty) {
        return response.first;
      }
      return {};
    } catch (e) {
      print('Error fetching meeting summary: $e');
      return {};
    }
  }

  // ==================== HELPERS ====================

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final allEmployees = <Map<String, dynamic>>[];

      // Get non-carer staff from profiles
      final staffResponse = await _client
          .from('profiles')
          .select('id, full_name, email, role')
          .neq('role', 'carer')
          .order('full_name', ascending: true);
      
      for (final staff in staffResponse) {
        allEmployees.add({
          'id': staff['id'],
          'name': staff['full_name'],
          'type': 'staff',
        });
      }

      // Get carers from carers table
      final carersResponse = await _client
          .from('carers')
          .select('id, name, employee_number')
          .eq('is_active', true)
          .order('name', ascending: true);
      
      for (final carer in carersResponse) {
        allEmployees.add({
          'id': carer['id'],
          'name': carer['name'],
          'type': 'carer',
        });
      }

      return allEmployees;
    } catch (e) {
      print('Error fetching staff: $e');
      return [];
    }
  }
}