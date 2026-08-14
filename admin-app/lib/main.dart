import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/supabase_auth_service.dart';
import 'package:admin_app/services/database_service.dart';
import 'package:admin_app/services/compliance_service.dart';
import 'package:admin_app/services/mar_audit_service.dart';
import 'package:admin_app/services/mca_service.dart';
import 'package:admin_app/services/safeguarding_service.dart';
import 'package:admin_app/ui/auth/auth_wrapper.dart';
import 'package:admin_app/ui/dashboard/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const CareQAAdminApp());
}

class CareQAAdminApp extends StatelessWidget {
  const CareQAAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SupabaseAuthService>(
          create: (_) => SupabaseAuthService(supabase),
        ),
        Provider<DatabaseService>(
          create: (_) => DatabaseService(supabase),
        ),
        Provider<ComplianceService>(
          create: (_) => ComplianceService(supabase),
        ),
        Provider<MarAuditService>(
          create: (_) => MarAuditService(supabase),
        ),
        Provider<McaService>(
          create: (_) => McaService(supabase),
        ),
        Provider<SafeguardingService>(
          create: (_) => SafeguardingService(supabase),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'CareQA Admin',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(
          authenticatedChild: AdminDashboard(),
        ),
      ),
    );
  }
}