import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase project details
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authCallbackUrlHostname: 'localhost',
      debug: true,
    );
  }

  static SupabaseClient getClient() {
    return Supabase.instance.client;
  }

  static SupabaseAuth getAuth() {
    return Supabase.instance.client.auth;
  }

  static SupabaseStorageClient getStorage() {
    return Supabase.instance.client.storage;
  }
}