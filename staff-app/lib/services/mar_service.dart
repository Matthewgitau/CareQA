import 'package:supabase_flutter/supabase_flutter.dart';

/// Staff-app MAR (Medication Administration Record) service.
/// Reads medications from `mar_medications` and logs administration
/// events into `mar_administration_logs`.
class MarService {
  final SupabaseClient _client;
  MarService(this._client);

  /// Get active medications for a service user on a given date.
  Future<List<Map<String, dynamic>>> getMedicationsForDate({
    required String serviceUserId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await _client
        .from('mar_medications')
        .select('*')
        .eq('service_user_id', serviceUserId)
        .eq('is_active', true)
        .lte('start_date', dateStr)
        .or('end_date.is.null,end_date.gte.$dateStr')
        .order('medication_name');
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Get all admin logs for a service user on a given date.
  Future<List<Map<String, dynamic>>> getLogsForDate({
    required String serviceUserId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await _client
        .from('mar_administration_logs')
        .select('*')
        .eq('service_user_id', serviceUserId)
        .gte('scheduled_time', '${dateStr}T00:00:00Z')
        .lte('scheduled_time', '${dateStr}T23:59:59Z')
        .order('scheduled_time');
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Record or update an administration event.
  Future<void> logAdministration({
    required String medicationId,
    required String serviceUserId,
    required String scheduledTime, // ISO timestamp
    required String status, // 'administered', 'missed', 'refused', 'held'
    String? notes,
    String? refusalReason,
    required String carerId,
    String? carerName,
  }) async {
    // Check if a log already exists for this medication + scheduled time
    final existing = await _client
        .from('mar_administration_logs')
        .select('id')
        .eq('medication_id', medicationId)
        .eq('scheduled_time', scheduledTime)
        .maybeSingle();

    final now = DateTime.now().toIso8601String();

    if (existing != null) {
      // Update existing log
      await _client
          .from('mar_administration_logs')
          .update({
            'status': status,
            'administered_at': status == 'administered' ? now : null,
            'administered_by': carerId,
            'administered_by_name': carerName,
            'notes': notes,
            'refusal_reason': refusalReason,
          })
          .eq('id', existing['id'] as String);
    } else {
      // Create new log
      await _client.from('mar_administration_logs').insert({
        'medication_id': medicationId,
        'service_user_id': serviceUserId,
        'scheduled_time': scheduledTime,
        'administered_at': status == 'administered' ? now : null,
        'administered_by': carerId,
        'administered_by_name': carerName,
        'status': status,
        'notes': notes,
        'refusal_reason': refusalReason,
        'created_at': now,
      });
    }
  }

  /// Submit a medication change suggestion for admin review.
  Future<void> submitSuggestion({
    required String serviceUserId,
    required String serviceUserName,
    String? originalMedicationId,
    required String suggestionType, // 'create','update','delete','stop'
    String? medicationName,
    String? dosage,
    String? dosageUnit,
    String? strength,
    String? form,
    String? frequency,
    List<String>? frequencyTimes,
    DateTime? startDate,
    DateTime? endDate,
    bool? isOngoing,
    String? specialInstructions,
    String? administrationRoute,
    required String suggestedById,
    required String suggestedByName,
    String? suggestionReason,
  }) async {
    await _client.from('mar_suggestions').insert({
      'original_medication_id': originalMedicationId,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'suggestion_type': suggestionType,
      'medication_name': medicationName,
      'dosage': dosage,
      'dosage_unit': dosageUnit,
      'strength': strength,
      'form': form,
      'frequency': frequency,
      'frequency_times': frequencyTimes,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'is_ongoing': isOngoing,
      'special_instructions': specialInstructions,
      'administration_route': administrationRoute,
      'suggested_by': suggestedById,
      'suggested_by_name': suggestedByName,
      'suggested_at': DateTime.now().toIso8601String(),
      'suggestion_reason': suggestionReason,
      'status': 'pending',
    });
  }
}