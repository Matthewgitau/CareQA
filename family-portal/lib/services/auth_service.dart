import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import '../utils/supabase_client.dart';

class AuthService {
  final SupabaseClient _client = SupabaseManager.instance.client;

  Future<User?> getCurrentUser() async {
    try {
      final response = await _client.auth.getUser();
      return response.user;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final session = _client.auth.currentSession;
      return session != null && !session.isExpired;
    } catch (e) {
      return false;
    }
  }
}