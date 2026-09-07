import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription_status.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_auth_service.dart';

/// Paywall shown to any signed-in user without an active
/// subscription or running trial. There is intentionally NO skip
/// path - the only exits are Start Trial, Subscribe, or Sign out.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with WidgetsBindingObserver {
  bool _busy = false;

  /// True while we believe the user has been sent to Stripe and hasn't
  /// returned yet. Set when a trial/checkout launch succeeds; used to
  /// trigger a poll-for-access when the app next resumes (native).
  bool _awaitingCheckout = false;

  /// True while polling subscription-status after a successful Stripe
  /// return, waiting for the webhook to flip the org to active/trialing.
  bool _checkingAfterPayment = false;

  // Pricing shown in the UI. MUST match the Stripe prices used by the
  // create-checkout edge function.
  //   monthly  -> price_1UAb7qLZNCdxsglRmSOvP9uI  (£750.00 / month)
  //   annual   -> price_1UAb9DLZNCdxsglRRIz1ZM41  (£6,000.00 / year)
  static const double _monthlyPrice = 750;
  static const double _annualPrice = 6000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Provider.of<SubscriptionService>(context, listen: false)
        .refresh(force: true);
    // Web: Stripe redirects the browser back to this same URL with
    // ?status=success&source=...  The page has reloaded, so the only
    // evidence we were just at Stripe is the URL query parameters.
    if (_isWebSuccessReturn()) {
      _pollUntilAccess();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final service = Provider.of<SubscriptionService>(context, listen: false);
      service.refresh(force: true);
      // Native: Stripe returns to the app via the careqa:// custom
      // scheme (or Chrome custom tab closing), which triggers a resume.
      // If we had just launched a checkout, start polling for access.
      if (_awaitingCheckout) {
        _awaitingCheckout = false;
        _pollUntilAccess();
      }
    }
  }

  /// Returns true when the browser URL indicates we just returned from
  /// a successful Stripe Checkout (web builds only - native uses the
  /// custom careqa:// scheme so this won't apply there).
  bool _isWebSuccessReturn() {
    if (!kIsWeb) return false;
    final status = Uri.base.queryParameters['status'];
    return status == 'success';
  }

  /// Poll subscription-status until the webhook grants access (org is
  /// active/trialing) or ~30s elapse. Caller must set _awaitingCheckout
  /// before launching Stripe on native, or the query param will be used
  /// on web.
  Future<void> _pollUntilAccess() async {
    // Guard against entering twice (web init + resume both firing).
    if (_checkingAfterPayment) return;
    setState(() => _checkingAfterPayment = true);

    final service = Provider.of<SubscriptionService>(context, listen: false);
    final granted = await service.pollUntilAccess();
    if (!mounted) return;
    setState(() => _checkingAfterPayment = false);

    if (!granted) {
      debugPrint(
        'Payment flew back successfully but access was not granted '
        'within the poll window - Stripe webhook may not be configured.',
      );
      _showMessage(
        'Payment received but access is not confirmed yet. '
        'The Stripe webhook may not be configured on the server, '
        'so the organisation cannot be unlocked.',
        isError: true,
      );
    }
    // If granted, SubscriptionService.notifyListeners() has already
    // flipped AuthWrapper to the dashboard - nothing else to do.
  }

  Future<void> _startTrial() async {
    if (_busy || _checkingAfterPayment) return;
    setState(() => _busy = true);
    final service = Provider.of<SubscriptionService>(context, listen: false);
    final error = await service.startTrial();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) _awaitingCheckout = true;
    });
    if (error != null) _showMessage(error, isError: true);
  }

  Future<void> _openCheckout(SubscriptionService service, String plan) async {
    if (_busy || _checkingAfterPayment) return;
    setState(() => _busy = true);
    final error = await service.openCheckout(plan);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) _awaitingCheckout = true;
    });
    if (error != null) _showMessage(error, isError: true);
  }

  Future<void> _signOut() async {
    final auth = Provider.of<SupabaseAuthService>(context, listen: false);
    await auth.signOut();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = context.watch<SubscriptionService>();
    final status = subscriptionService.status;
    final isTrialing = status.isTrialing;
    return _PaywallBody(
      busy: _busy,
      checkingAfterPayment: _checkingAfterPayment,
      isTrialing: isTrialing,
      status: status,
      onCheckStatus: _pollUntilAccess,
      onStartTrial: _startTrial,
      onOpenCheckout: (plan) => _openCheckout(subscriptionService, plan),
      onSignOut: _signOut,
    );
  }
}

class _PaywallBody extends StatelessWidget {
  final bool busy;
  final bool checkingAfterPayment;
  final bool isTrialing;
  final SubscriptionStatus status;
  final VoidCallback onCheckStatus;
  final VoidCallback onStartTrial;
  final ValueChanged<String> onOpenCheckout;
  final VoidCallback onSignOut;

  const _PaywallBody({
    required this.busy,
    this.checkingAfterPayment = false,
    required this.isTrialing,
    required this.status,
    required this.onCheckStatus,
    required this.onStartTrial,
    required this.onOpenCheckout,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Always-visible sign-out so the user can never be trapped on the
      // paywall (e.g. when their account's organisation_id is NULL and a
      // plan/checkout call fails). Also pinned in the body below.
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        title: const Text('CareQA',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            key: const Key('paywall_sign_out_top'),
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, size: 18, color: Colors.white),
            label:
                const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 260,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Icon(Icons.verified_user,
                      size: 56, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'CareQA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose how to unlock your platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  _TrialBanner(status: status),
                  const SizedBox(height: 12),
                  // Manual fallback: after paying, if the auto-redirect
                  // hasn't fired (webhook delay > poll window, or the
                  // user closed/reopened the app), they can re-check
                  // the server state instead of waiting 15 min.
                  TextButton.icon(
                    key: const Key('paywall_check_status'),
                    onPressed: checkingAfterPayment ? null : onCheckStatus,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Check payment status'),
                  ),
                  const SizedBox(height: 8),
                  if (checkingAfterPayment) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.green),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Payment received — checking your subscription…',
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _PlanCard(
                    title: 'Start Free Trial',
                    price: '£0',
                    period: '3 days',
                    accentColor: Colors.green.shade700,
                    subtitle:
                        'Full access. Card required for the post-trial renewal.',
                    buttonLabel: busy ? 'Starting…' : 'Start 3-Day Free Trial',
                    buttonIcon: Icons.rocket_launch,
                    enabled: !isTrialing && !busy && !checkingAfterPayment,
                    onPressed: onStartTrial,
                  ),
                  const SizedBox(height: 16),
                  _PlanCard(
                    title: 'Monthly',
                    price: '£750',
                    period: 'per month',
                    accentColor: const Color(0xFF1565C0),
                    subtitle: 'Cancel anytime. Great for getting started.',
                    buttonLabel: busy ? 'Opening…' : 'Subscribe Monthly',
                    buttonIcon: Icons.lock_open,
                    enabled: !busy && !checkingAfterPayment,
                    onPressed: () => onOpenCheckout('monthly'),
                  ),
                  const SizedBox(height: 16),
                  _PlanCard(
                    title: 'Annual',
                    price: '£6000',
                    period: 'per year · save 17%',
                    accentColor: const Color(0xFF00695C),
                    highlighted: true,
                    subtitle: 'Best value for established care teams.',
                    buttonLabel: busy ? 'Opening…' : 'Subscribe Annual',
                    buttonIcon: Icons.workspace_premium,
                    enabled: !busy && !checkingAfterPayment,
                    onPressed: () => onOpenCheckout('annual'),
                  ),
                  const SizedBox(height: 24),
                  const _TermsRow(),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('paywall_sign_out_bottom'),
                    onPressed: onSignOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D47A1),
                      side: const BorderSide(color: Color(0xFF0D47A1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final Color accentColor;
  final bool enabled;
  final bool highlighted;
  final VoidCallback onPressed;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.accentColor,
    required this.enabled,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? accentColor : Colors.grey.shade300,
          width: highlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(buttonIcon, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(period, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: enabled ? onPressed : null,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  final SubscriptionStatus status;
  const _TrialBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final remaining = status.trialRemaining;
    final trialing = status.isTrialing;

    Color bg;
    IconData icon;
    String text;
    if (status.isActive) {
      bg = Colors.green.shade50;
      icon = Icons.check_circle;
      text = 'Your subscription is active.';
    } else if (trialing) {
      bg = Colors.amber.shade50;
      icon = Icons.hourglass_top;
      final days = remaining?.inDays ?? 3;
      final hours = remaining?.inHours.remainder(24) ?? 0;
      text = 'Trial running — $days d $hours h left. Subscribe before it ends.';
    } else if (status.isPastDue) {
      bg = Colors.red.shade50;
      icon = Icons.warning_amber;
      text = 'Payment failed. Please update your details to continue.';
    } else {
      bg = Colors.blue.shade50;
      icon = Icons.info_outline;
      text = 'Start your free trial to explore the full platform.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child:
                Text(text, style: TextStyle(color: Colors.blueGrey.shade800)),
          ),
        ],
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Terms of Service link goes here')),
            );
          },
          child: const Text('Terms of Service'),
        ),
        const Text('·'),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy Policy link goes here')),
            );
          },
          child: const Text('Privacy Policy'),
        ),
      ],
    );
  }
}
