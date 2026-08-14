import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core/core.dart';

class RouteService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetches all routes for a given service user.
  Future<List<Route>> getRoutesForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('routes')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('call_number', ascending: true);

    return (response as List)
        .map((json) => Route.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Saves a list of routes for a service user.
  /// This replaces all existing routes (delete missing, update existing, insert new).
  Future<void> saveRoutesForServiceUser(
    String serviceUserId,
    List<Route> routes,
  ) async {
    // Fetch existing routes for this service user
    final existing = await _client
        .from('routes')
        .select('id')
        .eq('service_user_id', serviceUserId);

    final existingIds = (existing as List)
        .map((e) => e['id'] as String)
        .toSet();

    final newIds = routes.map((r) => r.id).toSet();

    // Delete routes that are no longer present
    final toDelete = existingIds.difference(newIds);
    for (final id in toDelete) {
      await _client.from('routes').delete().eq('id', id);
    }

    // Insert/update each route
    for (final route in routes) {
      final json = route.toJson();
      // Remove server-managed fields for upsert
      json.remove('created_at');
      json.remove('updated_at');

      if (route.id.isNotEmpty && existingIds.contains(route.id)) {
        // Update existing
        await _client
            .from('routes')
            .update(json)
            .eq('id', route.id);
      } else {
        // Insert new (let DB generate id)
        json.remove('id');
        await _client.from('routes').insert(json);
      }
    }
  }
}