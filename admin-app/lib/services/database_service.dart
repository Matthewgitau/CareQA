import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/carer.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/models/shift.dart';
import 'package:admin_app/models/visit.dart';

class DatabaseService {
  final SupabaseClient _client;

  DatabaseService(this._client);

  /// Get the current user's organisation ID
  Future<String?> _getOrganisationId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final response = await _client
        .from('profiles')
        .select('organisation_id')
        .eq('id', user.id)
        .single();
    return response['organisation_id'];
  }

  /// Add organisation_id to a map
  Future<Map<String, dynamic>> _withOrgId(Map<String, dynamic> data) async {
    final orgId = await _getOrganisationId();
    final result = {
      ...data,
      if (orgId != null) 'organisation_id': orgId,
    };
    // Remove any null id field - Supabase should auto-generate
    if (result.containsKey('id') && result['id'] == null) {
      result.remove('id');
    }
    return result;
  }

  Future<void> addCarer(Carer carer) async {
    try {
      final data = await _withOrgId(carer.toMap());
      print('=== DEBUG: Carer data being inserted ===');
      print(data);
      print('=== Does it have an "id" field? ===');
      print(data.containsKey('id') ? 'YES: ${data['id']}' : 'NO');
      await _client.from('carers').insert(data);
    } on PostgrestException catch (e) {
      print('=== ERROR ===');
      print(e.message);
      throw Exception(e.message);
    }
  }

  Future<void> updateCarer(Carer carer) async {
    try {
      await _client.from('carers').update(carer.toMap()).eq('id', carer.id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteCarer(String carerId) async {
    try {
      await _client.from('carers').delete().eq('id', carerId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Carer>> getCarers() async {
    try {
      final data = await _client.from('carers').select().order('created_at', ascending: false);
      return (data as List).map((e) => Carer.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> addServiceUser(ServiceUser serviceUser) async {
    try {
      final data = await _withOrgId(serviceUser.toMap());
      await _client.from('service_users').insert(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateServiceUser(ServiceUser serviceUser) async {
    try {
      await _client.from('service_users').update(serviceUser.toMap()).eq('id', serviceUser.id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteServiceUser(String serviceUserId) async {
    try {
      await _client.from('service_users').delete().eq('id', serviceUserId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<ServiceUser>> getServiceUsers() async {
    try {
      final data = await _client.from('service_users').select().order('created_at', ascending: false);
      return (data as List).map((e) => ServiceUser.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> addShift(Shift shift) async {
    try {
      final data = await _withOrgId(shift.toMap());
      await _client.from('shifts').insert(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateShift(Shift shift) async {
    try {
      await _client.from('shifts').update(shift.toMap()).eq('id', shift.id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteShift(String shiftId) async {
    try {
      await _client.from('shifts').delete().eq('id', shiftId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Shift>> getShifts() async {
    try {
      final data = await _client.from('shifts').select('*, service_users(name), carers(name)').order('date', ascending: false);
      return (data as List).map((e) => Shift.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> addVisit(Visit visit) async {
    try {
      final data = await _withOrgId(visit.toMap());
      await _client.from('visits').insert(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateVisit(Visit visit) async {
    try {
      await _client.from('visits').update(visit.toMap()).eq('id', visit.id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Visit>> getVisits() async {
    try {
      final data = await _client.from('visits').select('*, shifts(date, service_users(name)), carers(name)').order('created_at', ascending: false);
      return (data as List).map((e) => Visit.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Visit>> getVisitsByCarer(String carerId) async {
    try {
      final data = await _client.from('visits').select('*, shifts(date, service_users(name))').eq('carer_id', carerId).order('created_at', ascending: false);
      return (data as List).map((e) => Visit.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> addDocument(String carerId, String documentType, String fileUrl, DateTime expiryDate) async {
    try {
      final docData = await _withOrgId({
        'carer_id': carerId,
        'document_type': documentType,
        'file_url': fileUrl,
        'expiry_date': expiryDate.toIso8601String(),
        'verified': false,
      });
      await _client.from('documents').insert(docData);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentsByCarer(String carerId) async {
    try {
      final data = await _client.from('documents').select().eq('carer_id', carerId).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> addNotification(String userId, String type, String title, String body, Map<String, dynamic>? notificationData) async {
    try {
      final data = await _withOrgId({
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': notificationData ?? {},
        'read': false,
      });
      await _client.from('notifications').insert(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationsForUser(String userId) async {
    try {
      final data = await _client.from('notifications').select().eq('user_id', userId).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({'read': true, 'read_at': DateTime.now().toIso8601String()}).eq('id', notificationId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final data = await _client.from('settings').select().single();
      return data;
    } on PostgrestException catch (_) {
      return null;
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      await _client.from('settings').update(settings).eq('id', 1);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
