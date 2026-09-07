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

  /// PERFORMANCE FIX (-d edge / web hot restarts):
  /// This runs in initState, so it re-executes on EVERY hot restart. The two
  /// startup checks used to run SEQUENTIALLY (await one, then the other),
  /// roughly doubling the spinner time before the UI could decide what to
  /// show. They are independent lookups, so they now run concurrently via
  /// Future.wait. Behaviour is identical — we still need BOTH results before
  /// deciding between login / biometric unlock / the app.
  Future<void> _checkSessionOnStartup() async {
    final authService = context.read<SupabaseAuthService>();
    final results = await Future.wait<bool>([
      authService.hasSessionCached(),
      authService.isBiometricAvailable(), // returns instantly on web (see service)
    ]);
    if (!mounted) return;
    setState(() {
      _checkingSession = false;
      _showBiometric = results[0] && results[1];
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
    // Show spinner while profile is still loading after auth
    if (!authService.isProfileLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Profile load finished but role is unknown (e.g. no profiles row / RLS error).
    // Do NOT spin forever — sign out and return to login so the user can retry.
    if (authService.userRole == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        authService.signOut();
      });
      return const LoginScreen();
    }

    return widget.authenticatedChild;
  }
}