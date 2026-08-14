import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/auth/auth_wrapper.dart';
import 'services/supabase_auth_service.dart';
import 'utils/supabase_client.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseAuthService>(
          create: (_) => SupabaseAuthService(SupabaseManager.instance.client),
        ),
      ],
      child: const CareQAFamilyApp(),
    ),
  );
}

class CareQAFamilyApp extends StatelessWidget {
  const CareQAFamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareQA Family',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}