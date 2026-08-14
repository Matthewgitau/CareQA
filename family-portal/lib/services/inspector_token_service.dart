import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'dart:math';
import '../models/inspector_token.dart';
import '../utils/supabase_client.dart';

class InspectorTokenService {
  final SupabaseClient _client = SupabaseManager.instance.client;

  Future<InspectorToken> generateToken(String serviceUserId, int maxViews, 
      DateTime expiresAt, String organisationId) async {
    try {
      final token = InspectorToken(
        id: '',
        serviceUserId: serviceUserId,
        token: _generateRandomToken(),
        expiresAt: expiresAt,
        maxViews: maxViews,
        currentViews: 0,
        organisationId: organisationId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _client
          .from('inspector_tokens')
          .insert(token.toJson())
          .single();

      return InspectorToken.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to generate inspector token: $e');
    }
  }

  Future<InspectorToken> getTokenByCode(String tokenCode) async {
    try {
      final response = await _client
          .from('inspector_tokens')
          .select()
          .eq('token', tokenCode)
          .single();

      return InspectorToken.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load inspector token: $e');
    }
  }

  Future<void> incrementViews(String tokenId) async {
    try {
      await _client.rpc('increment_token_views', params: {'token_id': tokenId});
    } catch (e) {
      throw Exception('Failed to increment token views: $e');
    }
  }

  Future<void> revokeToken(String tokenId) async {
    try {
      await _client
          .from('inspector_tokens')
          .update({'max_views': 0, 'current_views': 999})
          .eq('id', tokenId);
    } catch (e) {
      throw Exception('Failed to revoke token: $e');
    }
  }

  String _generateRandomToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (i) => chars[random.nextInt(chars.length)]).join();
  }
}