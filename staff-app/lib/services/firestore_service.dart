import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/shift.dart';
import 'package:staff_app/models/visit.dart';

class FirestoreService {
  final SupabaseClient _supabase;

  FirestoreService(this._supabase);

  // Shifts table
  Future<List<Shift>> getShiftsForCurrentUser(String carerId) async {
    try {
      final response = await _supabase
          .from('shifts')
          .select()
          .eq('carerId', carerId);
      
      return (response as List<dynamic>)
          .map((item) => Shift.fromMap(item as Map<String, dynamic>, item['id']))
          .toList();
    } catch (e) {
      print('Error getting shifts: $e');
      return [];
    }
  }

  // Visits table
  Future<void> addVisit(Visit visit) async {
    try {
      await _supabase.from('visits').insert(visit.toMap());
    } catch (e) {
      print('Error adding visit: $e');
      throw e;
    }
  }

  Future<void> updateVisit(Visit visit) async {
    try {
      await _supabase
          .from('visits')
          .update(visit.toMap())
          .eq('id', visit.id);
    } catch (e) {
      print('Error updating visit: $e');
      throw e;
    }
  }

  Future<List<Visit>> getVisitsByCarer(String carerId) async {
    try {
      final response = await _supabase
          .from('visits')
          .select()
          .eq('carerId', carerId);
      
      return (response as List<dynamic>)
          .map((item) => Visit.fromMap(item as Map<String, dynamic>, item['id']))
          .toList();
    } catch (e) {
      print('Error getting visits: $e');
      return [];
    }
  }
}
