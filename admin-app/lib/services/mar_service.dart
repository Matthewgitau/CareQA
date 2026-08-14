import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mar_medication.dart';
import '../models/mar_suggestion.dart';

class MarService {
  final SupabaseClient _client;

  MarService(this._client);

  // ============================================================
  // MAR MEDICATIONS
  // ============================================================

  /// Get all active medications for a service user (excluding soft-deleted)
  Future<List<MarMedication>> getMedications({
    required String serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeInactive = false,
  }) async {
    var query = _client
        .from('mar_medications')
        .select()
        .eq('service_user_id', serviceUserId)
        .isFilter('deleted_at', null);

    if (!includeInactive) {
      query = query.eq('is_active', true);
    }

    if (endDate != null) {
      query = query
          .lte('start_date', endDate.toIso8601String().split('T').first);
    }

    if (endDate != null) {
      query = query.or(
        'end_date.is.null,end_date.gte.${endDate.toIso8601String().split('T').first}',
      );
    }

    final data = await query.order('medication_name');
    return (data as List)
        .map((item) => MarMedication.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Get a single medication by ID
  Future<MarMedication> getMedication(String id) async {
    final data = await _client
        .from('mar_medications')
        .select()
        .eq('id', id)
        .single();
    return MarMedication.fromMap(data as Map<String, dynamic>);
  }

  /// Create a new medication record
  Future<MarMedication> createMedication(MarMedication medication) async {
    final data = await _client
        .from('mar_medications')
        .insert(medication.toMap())
        .select()
        .single();
    return MarMedication.fromMap(data as Map<String, dynamic>);
  }

  /// Update an existing medication record
  Future<MarMedication> updateMedication(
      String id, MarMedication medication) async {
    final data = await _client
        .from('mar_medications')
        .update(medication.toMap())
        .eq('id', id)
        .select()
        .single();
    return MarMedication.fromMap(data as Map<String, dynamic>);
  }

  /// Soft delete a medication (sets deleted_at timestamp)
  Future<void> softDeleteMedication(String id, {String? deletedBy}) async {
    await _client.from('mar_medications').update({
      'deleted_at': DateTime.now().toIso8601String(),
      'deleted_by': deletedBy,
      'is_active': false,
    }).eq('id', id);
  }

  /// Stop a medication (sets end_date and is_ongoing = false)
  Future<void> stopMedication(String id,
      {DateTime? stopDate, String? reason, String? stoppedBy}) async {
    await _client.from('mar_medications').update({
      'end_date': (stopDate ?? DateTime.now()).toIso8601String().split('T').first,
      'is_ongoing': false,
      'is_active': false,
      'stopped_date': DateTime.now().toIso8601String().split('T').first,
      'stopped_reason': reason,
      'updated_by': stoppedBy,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Permanently delete a medication (use with caution)
  Future<void> hardDeleteMedication(String id) async {
    await _client.from('mar_medications').delete().eq('id', id);
  }

  // ============================================================
  // MAR ADMINISTRATION LOGS
  // ============================================================

  /// Get administration logs for a date range
  Future<List<Map<String, dynamic>>> getAdministrationLogs({
    required String serviceUserId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final data = await _client
        .from('mar_administration_logs')
        .select()
        .eq('service_user_id', serviceUserId)
        .gte('scheduled_time', startDate.toIso8601String())
        .lte('scheduled_time', endDate.toIso8601String())
        .order('scheduled_time');
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Get administration logs for a specific medication and date
  Future<List<Map<String, dynamic>>> getAdministrationLogsForMedication({
    required String medicationId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await _client
        .from('mar_administration_logs')
        .select()
        .eq('medication_id', medicationId)
        .gte('scheduled_time', '${dateStr}T00:00:00')
        .lte('scheduled_time', '${dateStr}T23:59:59')
        .order('scheduled_time');
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Create an administration log entry
  Future<Map<String, dynamic>> createAdministrationLog(
      Map<String, dynamic> log) async {
    final data = await _client
        .from('mar_administration_logs')
        .insert(log)
        .select()
        .single();
    return data as Map<String, dynamic>;
  }

  /// Update administration status (administer, miss, refuse, hold)
  Future<Map<String, dynamic>> updateAdministrationStatus(
      String logId, Map<String, dynamic> updates) async {
    final data = await _client
        .from('mar_administration_logs')
        .update(updates)
        .eq('id', logId)
        .select()
        .single();
    return data as Map<String, dynamic>;
  }

  /// Get or create administration log for a specific time slot
  Future<Map<String, dynamic>> getOrCreateAdministrationLog({
    required String medicationId,
    required String serviceUserId,
    required DateTime scheduledTime,
  }) async {
    // Try to find existing log
    final existing = await _client
        .from('mar_administration_logs')
        .select()
        .eq('medication_id', medicationId)
        .eq('scheduled_time', scheduledTime.toIso8601String())
        .maybeSingle();

    if (existing != null) {
      return existing as Map<String, dynamic>;
    }

    // Create new log
    final newLog = await _client
        .from('mar_administration_logs')
        .insert({
          'medication_id': medicationId,
          'service_user_id': serviceUserId,
          'scheduled_time': scheduledTime.toIso8601String(),
          'status': 'pending',
        })
        .select()
        .single();

    return newLog as Map<String, dynamic>;
  }

  // ============================================================
  // MAR SUGGESTIONS
  // ============================================================

  /// Get all suggestions, optionally filtered by status
  Future<List<MarSuggestion>> getSuggestions({String? status}) async {
    var query = _client
        .from('mar_suggestions')
        .select();

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query.order('suggested_at', ascending: false);
    return (data as List)
        .map((item) => MarSuggestion.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Get suggestions for a specific service user
  Future<List<MarSuggestion>> getSuggestionsForServiceUser(
      String serviceUserId) async {
    final data = await _client
        .from('mar_suggestions')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('suggested_at', ascending: false);
    return (data as List)
        .map((item) => MarSuggestion.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Get a single suggestion by ID
  Future<MarSuggestion> getSuggestion(String id) async {
    final data = await _client
        .from('mar_suggestions')
        .select()
        .eq('id', id)
        .single();
    return MarSuggestion.fromMap(data as Map<String, dynamic>);
  }

  /// Approve a suggestion — performs the action and updates the suggestion
  Future<Map<String, dynamic>> approveSuggestion(
    String suggestionId, {
    required String reviewedBy,
    required String reviewedByName,
    String? reviewNotes,
  }) async {
    // Get the suggestion
    final suggestion = await getSuggestion(suggestionId);

    String? approvedActionId;

    switch (suggestion.suggestionType) {
      case 'create':
        // Create new medication from suggestion data
        final newMed = MarMedication(
          serviceUserId: suggestion.serviceUserId,
          serviceUserName: suggestion.serviceUserName,
          medicationName: suggestion.medicationName ?? '',
          dosage: suggestion.dosage ?? '',
          dosageUnit: suggestion.dosageUnit,
          strength: suggestion.strength,
          form: suggestion.form,
          frequency: suggestion.frequency ?? 'once_daily',
          frequencyTimes: suggestion.frequencyTimes,
          startDate: suggestion.startDate ?? DateTime.now(),
          endDate: suggestion.endDate,
          isOngoing: suggestion.isOngoing ?? true,
          specialInstructions: suggestion.specialInstructions,
          administrationRoute: suggestion.administrationRoute,
          createdBy: reviewedBy,
          organisationId: suggestion.organisationId,
        );
        final created = await createMedication(newMed);
        approvedActionId = created.id;
        break;

      case 'update':
        // Update existing medication
        if (suggestion.originalMedicationId != null) {
          final existing = await getMedication(suggestion.originalMedicationId!);
          final updated = existing.copyWith(
            medicationName: suggestion.medicationName,
            dosage: suggestion.dosage,
            dosageUnit: suggestion.dosageUnit,
            strength: suggestion.strength,
            form: suggestion.form,
            frequency: suggestion.frequency,
            frequencyTimes: suggestion.frequencyTimes,
            startDate: suggestion.startDate,
            endDate: suggestion.endDate,
            isOngoing: suggestion.isOngoing,
            specialInstructions: suggestion.specialInstructions,
            administrationRoute: suggestion.administrationRoute,
            updatedBy: reviewedBy,
            updatedAt: DateTime.now(),
          );
          final result = await updateMedication(
              suggestion.originalMedicationId!, updated);
          approvedActionId = result.id;
        }
        break;

      case 'delete':
        // Soft delete the medication
        if (suggestion.originalMedicationId != null) {
          await softDeleteMedication(
            suggestion.originalMedicationId!,
            deletedBy: reviewedBy,
          );
          approvedActionId = suggestion.originalMedicationId;
        }
        break;

      case 'stop':
        // Stop the medication
        if (suggestion.originalMedicationId != null) {
          await stopMedication(
            suggestion.originalMedicationId!,
            stopDate: suggestion.endDate,
            reason: suggestion.suggestionReason,
            stoppedBy: reviewedBy,
          );
          approvedActionId = suggestion.originalMedicationId;
        }
        break;
    }

    // Update the suggestion record
    final data = await _client
        .from('mar_suggestions')
        .update({
          'status': 'approved',
          'reviewed_by': reviewedBy,
          'reviewed_by_name': reviewedByName,
          'reviewed_at': DateTime.now().toIso8601String(),
          'review_notes': reviewNotes,
          'approved_action_id': approvedActionId,
        })
        .eq('id', suggestionId)
        .select()
        .single();

    return data as Map<String, dynamic>;
  }

  /// Reject a suggestion
  Future<Map<String, dynamic>> rejectSuggestion(
    String suggestionId, {
    required String reviewedBy,
    required String reviewedByName,
    String? reviewNotes,
  }) async {
    final data = await _client
        .from('mar_suggestions')
        .update({
          'status': 'rejected',
          'reviewed_by': reviewedBy,
          'reviewed_by_name': reviewedByName,
          'reviewed_at': DateTime.now().toIso8601String(),
          'review_notes': reviewNotes,
        })
        .eq('id', suggestionId)
        .select()
        .single();

    return data as Map<String, dynamic>;
  }

  /// Get count of pending suggestions
  Future<int> getPendingSuggestionsCount() async {
    final response = await _client
        .from('mar_suggestions')
        .select('id')
        .eq('status', 'pending');
    return (response as List).length;
  }
}
