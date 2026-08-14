import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_learnt.dart';

class LessonLearntService {
  final SupabaseClient _client;

  LessonLearntService(this._client);

  Future<List<LessonLearnt>> getLessons({
    String? status,
    String? severity,
    String? category,
    String? sourceType,
  }) async {
    try {
      var query = _client.from('lessons_learnt').select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (sourceType != null) {
        query = query.eq('source_type', sourceType);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => LessonLearnt.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch lessons: $e');
    }
  }

  Future<LessonLearnt?> getLesson(String id) async {
    try {
      final response = await _client.from('lessons_learnt').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return LessonLearnt.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch lesson: $e');
    }
  }

  Future<LessonLearnt> createLesson(LessonLearnt lesson) async {
    try {
      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      final data = lesson.toJson();
      data['organisation_id'] = orgId;
      data['created_by'] = _client.auth.currentUser?.id;
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _client.from('lessons_learnt').insert(data).select().single();
      return LessonLearnt.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create lesson: $e');
    }
  }

  Future<LessonLearnt> updateLesson(String id, Map<String, dynamic> data) async {
    try {
      data['updated_by'] = _client.auth.currentUser?.id;
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client.from('lessons_learnt').update(data).eq('id', id).select().single();
      return LessonLearnt.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update lesson: $e');
    }
  }

  Future<void> deleteLesson(String id) async {
    try {
      await _client.from('lessons_learnt').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete lesson: $e');
    }
  }

  Future<List<LessonLearnt>> getLessonsBySource(String sourceType, String sourceId) async {
    try {
      final response = await _client.from('lessons_learnt')
          .select()
          .eq('source_type', sourceType)
          .eq('source_id', sourceId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => LessonLearnt.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch lessons by source: $e');
    }
  }

  Future<List<LessonLearnt>> getLessonsByCategory(String category) async {
    try {
      final response = await _client.from('lessons_learnt')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);
      return (response as List).map((json) => LessonLearnt.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch lessons by category: $e');
    }
  }

  Future<List<LessonLearnt>> getImplementedLessons() async {
    try {
      final response = await _client.from('lessons_learnt')
          .select()
          .eq('implemented', true)
          .order('implementation_date', ascending: false);
      return (response as List).map((json) => LessonLearnt.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch implemented lessons: $e');
    }
  }

  Future<List<LessonLearnt>> getLessonsForTraining() async {
    try {
      final response = await _client.from('lessons_learnt')
          .select()
          .eq('is_training_required', true)
          .order('created_at', ascending: false);
      return (response as List).map((json) => LessonLearnt.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch lessons for training: $e');
    }
  }

  Future<void> shareLesson(String id, String method, {String? notes}) async {
    try {
      await _client.from('lessons_learnt').update({
        'shared_with_team': true,
        'shared_date': DateTime.now().toIso8601String().split('T')[0],
        'shared_method': method,
        'shared_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to share lesson: $e');
    }
  }

  Future<void> implementLesson(String id, String notes, {String? implementedBy}) async {
    try {
      await _client.from('lessons_learnt').update({
        'implemented': true,
        'implementation_date': DateTime.now().toIso8601String().split('T')[0],
        'implemented_by': implementedBy ?? _client.auth.currentUser?.id,
        'implementation_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to implement lesson: $e');
    }
  }

  Future<Map<String, int>> getLessonStats() async {
    try {
      final response = await _client.from('lessons_learnt').select('status, severity, implemented');
      final lessons = response as List;

      int draft = 0, reviewPending = 0, approved = 0, implemented = 0, shared = 0, closed = 0;
      int critical = 0, high = 0, medium = 0, low = 0;
      int implementedCount = 0;

      for (final lesson in lessons) {
        final status = lesson['status'] as String? ?? 'draft';
        final severity = lesson['severity'] as String? ?? 'medium';
        final isImplemented = lesson['implemented'] as bool? ?? false;

        switch (status) {
          case 'draft':
            draft++;
            break;
          case 'review_pending':
            reviewPending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'implemented':
            implemented++;
            break;
          case 'shared':
            shared++;
            break;
          case 'closed':
            closed++;
            break;
        }

        switch (severity) {
          case 'critical':
            critical++;
            break;
          case 'high':
            high++;
            break;
          case 'medium':
            medium++;
            break;
          case 'low':
            low++;
            break;
        }

        if (isImplemented) implementedCount++;
      }

      return {
        'draft': draft,
        'review_pending': reviewPending,
        'approved': approved,
        'implemented': implemented,
        'shared': shared,
        'closed': closed,
        'total': lessons.length,
        'critical': critical,
        'high': high,
        'medium': medium,
        'low': low,
        'implemented_count': implementedCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch lesson stats: $e');
    }
  }

  Future<Map<String, int>> getRootCauseAnalysis() async {
    try {
      final response = await _client.from('lessons_learnt').select('root_cause_category');
      final lessons = response as List;

      final rootCauses = <String, int>{};
      for (final lesson in lessons) {
        final category = lesson['root_cause_category'] as String? ?? 'other';
        rootCauses[category] = (rootCauses[category] ?? 0) + 1;
      }

      return rootCauses;
    } catch (e) {
      throw Exception('Failed to fetch root cause analysis: $e');
    }
  }

  Future<String?> _getOrganisationId() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['organisation_id']?.toString();
    } catch (e) {
      return null;
    }
  }
}