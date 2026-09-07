import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple daily-note CRUD for the staff-app.
/// Writes into `public.daily_notes` (created by migration 083).
class DailyNoteService {
  final SupabaseClient _client;
  DailyNoteService(this._client);

  Future<List<Map<String, dynamic>>> getNotesForUserAndDate({
    required String serviceUserId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await _client
        .from('daily_notes')
        .select()
        .eq('service_user_id', serviceUserId)
        .eq('visit_date', dateStr)
        .order('visit_time', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createNote(Map<String, dynamic> note) async {
    final data = await _client
        .from('daily_notes')
        .insert(note)
        .select()
        .single();
    return data as Map<String, dynamic>;
  }
}