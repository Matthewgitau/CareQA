import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/subscription_service.dart';
import '../paywall/paywall_screen.dart';
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
  bool _checksStarted = false;

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

  /// One-time hook that starts the subscription watchdog the moment a
  /// signed-in user's profile has loaded - regardless of whether they
  /// end up on the paywall or the dashboard (so a trial that expires
  /// while using the app bounces them back to the paywall).
  void _ensureChecksStarted() {
    if (_checksStarted) return;
    final authService = context.read<SupabaseAuthService>();
    if (!authService.isAuthenticated || authService.userRole == null) return;

    _checksStarted = true;
    final subscriptionService = context.read<SubscriptionService>();
    subscriptionService.startPeriodicChecks();
    // Defer the first refresh until after the current frame. Calling
    // refresh() during build() would synchronously fire
    // notifyListeners(), which throws "setState() or markNeedsBuild()
    // called during build" - and since the throw happens before the
    // HTTP call, the user can stay on the paywall forever even with an
    // active org.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      subscriptionService.refresh(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureChecksStarted();

    if (_checkingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final authService = context.watch<SupabaseAuthService>();
    final subscriptionService = context.watch<SubscriptionService>();

    // Has a valid Supabase session — route through the paywall gate.
    if (authService.isAuthenticated) {
      return _buildPaywallGate(authService, subscriptionService);
    }

    // Has cached session + biometric available — show biometric unlock
    if (_showBiometric) {
      return const BiometricUnlockScreen();
    }

    // No session — show login
    return const LoginScreen();
  }

  Widget _buildPaywallGate(
    SupabaseAuthService authService,
    SubscriptionService subscriptionService,
  ) {
    // Block until the profile (and therefore org/billing info) has loaded.
    if (authService.userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Paywall unless the server says the organisation has access.
    // Fails closed: an unreachable backend or unknown state keeps the
    // user on the paywall.
    if (!subscriptionService.hasAccess) {
      return const PaywallScreen();
    }

    // ACCESS GRANTED → show the authenticated app shell. This is the
    // dashboard (AdminDashboard) configured in main.dart:85
    //   AuthWrapper(authenticatedChild: AdminDashboard())
    // It appears automatically the moment the Stripe webhook flips the
    // org to active/trialing and subscription-status reports
    // hasAccess=true. No manual navigation happens here - the widget
    // swap IS the routing.
    debugPrint(
      'PAYWALL_GATE: access granted (status=${subscriptionService.status.status}) '
      '→ showing authenticatedChild (AdminDashboard)',
    );
    return widget.authenticatedChild;
  }
}
