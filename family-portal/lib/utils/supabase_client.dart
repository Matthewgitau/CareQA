import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseManager {
  static final SupabaseManager _instance = SupabaseManager._internal();
  late SupabaseClient client;

  SupabaseManager._internal() {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception('Supabase URL and Key must be set in .env file');
    }

    client = SupabaseClient(supabaseUrl, supabaseKey);
  }

  static SupabaseManager get instance => _instance;
}