import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/services/firestore_service.dart';
import 'package:staff_app/ui/auth/auth_wrapper.dart';
import 'package:staff_app/ui/dashboard/staff_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  // Initialize Supabase using environment variables - never hardcode credentials
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const CareQAStaffApp());
}

class CareQAStaffApp extends StatelessWidget {
  const CareQAStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    
    return MultiProvider(
      providers: [
        Provider<SupabaseAuthService>(
          create: (_) => SupabaseAuthService(supabase),
          lazy: false,
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(supabase),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'CareQA Staff',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const AuthWrapper(
          authenticatedChild: StaffDashboard(),
        ),
      ),
    );
  }
}