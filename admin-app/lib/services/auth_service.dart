import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/profile.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  Stream<User?> get authStateChanges => _client.auth.onAuthStateChange.map((event) => event.session?.user);

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Future<Profile?> getCurrentProfile() async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      return Profile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      await _client
          .from('profiles')
          .update(profile.toMap())
          .eq('id', profile.id);
    } catch (e) {
      print('Error updating profile: $e');
      throw e;
    }
  }
}