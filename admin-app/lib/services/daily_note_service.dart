import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_note.dart';

class DailyNoteService {
  final SupabaseClient _client;

  DailyNoteService(this._client);

  Future<List<DailyNote>> getNotes({String? serviceUserId, DateTime? date}) async {
    var query = _client.from('daily_notes').select();
    if (serviceUserId != null) query = query.eq('service_user_id', serviceUserId);
    if (date != null) {
      final d = date.toIso8601String().split('T').first;
      query = query.eq('visit_date', d);
    }
    final data = await query.order('visit_time', ascending: false);
    return (data as List).map((item) => DailyNote.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<DailyNote> getNote(String id) async {
    final data = await _client.from('daily_notes').select().eq('id', id).single();
    return DailyNote.fromMap(data as Map<String, dynamic>);
  }

  Future<DailyNote> createNote(DailyNote note) async {
    final data = await _client.from('daily_notes').insert(note.toMap()).select().single();
    return DailyNote.fromMap(data as Map<String, dynamic>);
  }

  Future<DailyNote> updateNote(String id, DailyNote note) async {
    final data = await _client.from('daily_notes').update(note.toMap()).eq('id', id).select().single();
    return DailyNote.fromMap(data as Map<String, dynamic>);
  }

  Future<void> deleteNote(String id) async {
    await _client.from('daily_notes').delete().eq('id', id);
  }
}