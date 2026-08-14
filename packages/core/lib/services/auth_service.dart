import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<User?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      return session?.user;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final session = _client.auth.currentSession;
      return session != null && session.user != null;
    } catch (e) {
      return false;
    }
  }
}