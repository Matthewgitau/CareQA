import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver.dart';

class DriverService {
  final SupabaseClient _client;

  DriverService(this._client);

  Future<List<Driver>> getDrivers() async {
    final response = await _client
        .from('drivers')
        .select('*')
        .order('created_at', ascending: false);
    return (response as List).map((d) => Driver.fromMap(d)).toList();
  }

  Future<Driver?> getDriver(String id) async {
    final response = await _client
        .from('drivers')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    return response != null ? Driver.fromMap(response) : null;
  }

  Future<void> addDriver(Driver driver) async {
    await _client.from('drivers').insert(driver.toMap());
  }

  Future<void> updateDriver(Driver driver) async {
    await _client
        .from('drivers')
        .update(driver.toMap())
        .eq('id', driver.id);
  }

  Future<void> deleteDriver(String id) async {
    await _client.from('drivers').delete().eq('id', id);
  }
}