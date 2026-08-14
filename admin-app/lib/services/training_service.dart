import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/training_course.dart';
import '../models/carer_training_record.dart';
import '../models/carer_training_history.dart';

/// Service for managing training courses, carer training records, and history
class TrainingService {
  final SupabaseClient _client;

  TrainingService(this._client);

  // ==================== TRAINING COURSES ====================

  Future<List<TrainingCourse>> getAllCourses() async {
    try {
      final response = await _client
          .from('training_courses')
          .select('*')
          .order('name', ascending: true);
      return (response as List).map((json) => TrainingCourse.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching training courses: $e');
      return [];
    }
  }

  Future<TrainingCourse?> getCourseById(String id) async {
    try {
      final response = await _client
          .from('training_courses')
          .select('*')
          .eq('id', id)
          .single();
      return TrainingCourse.fromJson(response);
    } catch (e) {
      print('Error fetching course: $e');
      return null;
    }
  }

  Future<TrainingCourse?> createCourse(TrainingCourse course) async {
    try {
      final data = course.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('training_courses')
          .insert(data)
          .select()
          .single();
      return TrainingCourse.fromJson(response);
    } catch (e) {
      print('Error creating course: $e');
      rethrow;
    }
  }

  Future<TrainingCourse?> updateCourse(TrainingCourse course) async {
    try {
      final data = course.toJson();
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('training_courses')
          .update(data)
          .eq('id', course.id)
          .select()
          .single();
      return TrainingCourse.fromJson(response);
    } catch (e) {
      print('Error updating course: $e');
      rethrow;
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      await _client.from('training_courses').delete().eq('id', id);
    } catch (e) {
      print('Error deleting course: $e');
      rethrow;
    }
  }

  // ==================== CARER TRAINING RECORDS ====================

  Future<List<CarerTrainingRecord>> getAllRecords() async {
    try {
      final response = await _client
          .from('carer_training_records')
          .select('''
            *,
            carer:carer_id(name),
            course:training_course_id(name)
          ''')
          .order('completed_date', ascending: false);
      return (response as List).map((json) {
        return CarerTrainingRecord.fromJson({
          ...json,
          'carer_name': json['carer']?['name'],
          'course_name': json['course']?['name'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching training records: $e');
      return [];
    }
  }

  Future<List<CarerTrainingRecord>> getRecordsForCarer(String carerId) async {
    try {
      final response = await _client
          .from('carer_training_records')
          .select('''
            *,
            course:training_course_id(name, default_renewal_interval_months)
          ''')
          .eq('carer_id', carerId)
          .order('completed_date', ascending: false);
      return (response as List).map((json) {
        return CarerTrainingRecord.fromJson({
          ...json,
          'course_name': json['course']?['name'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching records for carer: $e');
      return [];
    }
  }

  Future<CarerTrainingRecord?> getRecordById(String id) async {
    try {
      final response = await _client
          .from('carer_training_records')
          .select('''
            *,
            carer:carer_id(name),
            course:training_course_id(name)
          ''')
          .eq('id', id)
          .single();
      return CarerTrainingRecord.fromJson({
        ...response,
        'carer_name': response['carer']?['name'],
        'course_name': response['course']?['name'],
      });
    } catch (e) {
      print('Error fetching record: $e');
      return null;
    }
  }

  Future<CarerTrainingRecord?> createRecord(CarerTrainingRecord record) async {
    try {
      final data = record.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      // Get current user's organisation_id for RLS
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
          .from('carer_training_records')
          .insert(data)
          .select()
          .single();

      // Log history
      await _logHistory(response['id'], 'created', null, response);

      return CarerTrainingRecord.fromJson(response);
    } catch (e) {
      print('Error creating record: $e');
      rethrow;
    }
  }

  Future<CarerTrainingRecord?> updateRecord(CarerTrainingRecord record) async {
    try {
      // Get previous data for history
      final previous = await _client
          .from('carer_training_records')
          .select('*')
          .eq('id', record.id)
          .single();

      final data = record.toJson();
      data.remove('created_at');
      data.remove('updated_at');

      // Ensure organisation_id is set for RLS
      final user = _client.auth.currentUser;
      if (user != null && !data.containsKey('organisation_id')) {
        final profile = await _client
            .from('profiles')
            .select('organisation_id')
            .eq('id', user.id)
            .single();
        data['organisation_id'] = profile['organisation_id'];
      }

      final response = await _client
          .from('carer_training_records')
          .update(data)
          .eq('id', record.id)
          .select()
          .single();

      // Log history
      await _logHistory(record.id, 'updated', previous, response);

      return CarerTrainingRecord.fromJson(response);
    } catch (e) {
      print('Error updating record: $e');
      rethrow;
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      // Get previous data for history
      final previous = await _client
          .from('carer_training_records')
          .select('*')
          .eq('id', id)
          .single();

      await _client.from('carer_training_records').delete().eq('id', id);

      // Log history
      await _logHistory(id, 'deleted', previous, null);
    } catch (e) {
      print('Error deleting record: $e');
      rethrow;
    }
  }

  Future<void> uploadCertificate(String recordId, String certificateUrl) async {
    try {
      final previous = await _client
          .from('carer_training_records')
          .select('*')
          .eq('id', recordId)
          .single();

      final response = await _client
          .from('carer_training_records')
          .update({'certificate_url': certificateUrl})
          .eq('id', recordId)
          .select()
          .single();

      // Log history
      await _logHistory(recordId, 'uploaded_certificate', previous, response);
    } catch (e) {
      print('Error uploading certificate: $e');
      rethrow;
    }
  }

  // ==================== HISTORY ====================

  Future<List<CarerTrainingHistory>> getHistoryForRecord(String recordId) async {
    try {
      final response = await _client
          .from('carer_training_history')
          .select('*')
          .eq('training_record_id', recordId)
          .order('changed_at', ascending: false);
      return (response as List).map((json) => CarerTrainingHistory.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  Future<void> _logHistory(String recordId, String action, Map<String, dynamic>? previous, Map<String, dynamic>? newData) async {
    try {
      final user = _client.auth.currentUser;
      await _client.from('carer_training_history').insert({
        'training_record_id': recordId,
        'action': action,
        'previous_data': previous,
        'new_data': newData,
        'changed_by': user?.id,
      });
    } catch (e) {
      print('Error logging history: $e');
    }
  }

  // ==================== HELPERS ====================

  Future<List<Map<String, dynamic>>> getAllCarers() async {
    try {
      final data = await _client
          .from('carers')
          .select('id, name, employee_number, job_role, phone, date_of_birth');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching carers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllCoursesForDropdown() async {
    try {
      final data = await _client
          .from('training_courses')
          .select('id, name, is_mandatory, default_renewal_interval_months')
          .eq('is_active', true)
          .order('name');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  /// Upload certificate to Supabase Storage bucket 'training-certificates'
  Future<String?> uploadCertificateFile(File file, String recordId) async {
    try {
      final ext = p.extension(file.path);
      final fileName = '${recordId}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final fileBytes = await file.readAsBytes();

      await _client.storage
          .from('training-certificates')
          .uploadBinary(fileName, fileBytes);

      final publicUrl = _client.storage
          .from('training-certificates')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading certificate: $e');
      return null;
    }
  }
}
