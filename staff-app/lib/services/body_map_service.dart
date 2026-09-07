import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes body-map assessments into `public.body_map_assessments`
/// (created by migration 144).
class BodyMapService {
  final SupabaseClient _client;
  BodyMapService(this._client);

  Future<Map<String, dynamic>> createAssessment({
    required String serviceUserId,
    required String assessedById,
    required String? organisationId,
    bool noNewMarks = true,
    String? notes,
    List<Map<String, dynamic>>? marks,
  }) async {
    final data = await _client
        .from('body_map_assessments')
        .insert({
          'service_user_id': serviceUserId,
          'assessed_by': assessedById,
          'organisation_id': organisationId,
          'no_new_marks': noNewMarks,
          'notes': notes,
          'marks': marks ?? [],
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return data as Map<String, dynamic>;
  }
}