import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_auth_service.dart';
import 'login_screen.dart';
import 'biometric_unlock_screen.dart';

class AuthWrapper extends StatefulWidget {
  final Widget authenticatedChild;

  const AuthWrapper({super.key, required this.authenticatedChild});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checkingSession = true;
  bool _showBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkSessionOnStartup();
  }

  Future<void> _checkSessionOnStartup() async {
    final authService = context.read<SupabaseAuthService>();
    final hasCached = await authService.hasSessionCached();
    final biometricAvailable = await authService.isBiometricAvailable();

    setState(() {
      _checkingSession = false;
      _showBiometric = hasCached && biometricAvailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final authService = context.watch<SupabaseAuthService>();

    // Has a valid Supabase session — go to app
    if (authService.isAuthenticated) {
      return _buildRoleGate(authService);
    }

    // Has cached session + biometric available — show biometric unlock
    if (_showBiometric) {
      return const BiometricUnlockScreen();
    }

    // No session — show login
    return const LoginScreen();
  }

  Widget _buildRoleGate(SupabaseAuthService authService) {
    // Block access if profile hasn't loaded yet (role is null)
    if (authService.userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.authenticatedChild;
  }
}