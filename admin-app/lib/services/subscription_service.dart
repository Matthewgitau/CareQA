import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription_status.dart';

/// Talks to the Supabase edge functions that own the subscription
/// lifecycle (signup, start-trial, create-checkout,
/// subscription-status). Exposes a ChangeNotifier so the auth gate
/// can react the moment access is granted/revoked.
class SubscriptionService extends ChangeNotifier {
  final SupabaseClient _client;

  SubscriptionService(this._client);

  SubscriptionStatus _status = const SubscriptionStatus();
  SubscriptionStatus get status => _status;
  bool get hasAccess => _status.hasAccess;
  bool get isLoading => _loading;
  bool _loading = false;

  Timer? _refreshTimer;

  /// Begin periodic status checks. Call from the app shell after the
  /// user is authenticated (e.g. every 15 minutes + on resume).
  void startPeriodicChecks({Duration interval = const Duration(minutes: 15)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => refresh(force: true));
  }

  /// Poll `subscription-status` until the backend grants access (i.e.
  /// the Stripe webhook has flipped the org to `active` / `trialing`).
  ///
  /// After Stripe Checkout redirects the browser back to the app, the
  /// webhook can lag by a second or two. A single refresh often hits
  /// before the webhook has landed, leaving the user on the paywall
  /// until the next 15-minute poll. This waits up to
  /// `maxAttempts * interval` for access and returns as soon as it's
  /// granted. When access flips, notifyListeners() makes the auth gate
  /// swap to the dashboard immediately.
  Future<bool> pollUntilAccess({
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 10,
  }) async {
    if (hasAccess) return true;
    for (var i = 0; i < maxAttempts; i++) {
      await refresh(force: true);
      if (hasAccess) return true;
      await Future.delayed(interval);
    }
    return hasAccess;
  }

  /// Re-check the backend state. `force` skips the short in-memory
  /// cache used to keep build-triggered calls cheap.
  Future<SubscriptionStatus> refresh({bool force = false}) async {
    if (!force && _hasFreshCache()) return _status;
    if (_loading) return _status;

    _loading = true;
    _deferNotify();
    try {
      final result = await _invoke('subscription-status', body: const {});
      if (!result.isError && result.data != null) {
        _status = SubscriptionStatus.fromJson(result.data!);
      }
    } finally {
      _loading = false;
      _lastRefresh = DateTime.now();
      _deferNotify();
    }
    return _status;
  }

  /// Notify listeners after the current synchronous build phase.
  ///
  /// refresh() can be triggered from build-time paths
  /// (AuthWrapper._ensureChecksStarted runs inside build();
  /// PaywallScreen.initState runs while the element tree is mounting).
  /// Calling ChangeNotifier.notifyListeners() synchronously at that point
  /// marks dependents dirty *during* the build phase and throws
  /// "setState() or markNeedsBuild() called during build". Scheduling
  /// the notification as a microtask defers it until the current
  /// synchronous work (and therefore the build phase) has finished.
  void _deferNotify() {
    scheduleMicrotask(notifyListeners);
  }

  /// Base URL used for Stripe's success/cancel redirect.
  ///
  /// Native apps register the `careqa://` custom scheme (Android
  /// manifest / iOS Info.plist), but the web build has NO registered
  /// handler for it - Stripe's redirect would fail with
  /// "Failed to launch 'careqa://...' because the scheme does not
  /// have a registered handler." On web we redirect back to the app's
  /// own origin instead; the Flutter SPA reloads and re-checks the
  /// subscription-status edge function.
  String get _redirectBase {
    if (kIsWeb) {
      final base = Uri.base;
      return '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    }
    return 'careqa://paywall';
  }

  /// Start the trial. Returns null on success, or an error message.
  /// The trial flow now opens a Stripe Checkout page (so we can
  /// collect a payment method for the post-trial renewal); the
  /// subscription_status flips to 'trialing' via webhook when the
  /// user finishes Checkout.
  Future<String?> startTrial() async {
    final result = await _invoke('start-trial', body: {
      'successUrl': '$_redirectBase?status=success',
      'cancelUrl': '$_redirectBase?status=cancelled',
    });
    if (result.isError) return result.error;
    final data = result.data;
    if (data == null) return null;
    final url = data['url'] as String?;
    if (url != null && url.isNotEmpty) {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) return 'Could not open the trial sign-up page.';
    }
    // Optimistically refresh so the paywall swaps to the dashboard
    // the moment Stripe confirms the trial via webhook.
    await refresh(force: true);
    return null;
  }

  /// Create a Stripe Checkout session for [plan] ('monthly'|'annual').
  /// Opens the returned URL in the system browser. Returns an error
  /// message on failure, null when the browser was launched.
  Future<String?> openCheckout(String plan) async {
    final result = await _invoke('create-checkout', body: {
      'plan': plan,
      'successUrl': '$_redirectBase?status=success&source=checkout',
      'cancelUrl': '$_redirectBase?status=cancelled&source=checkout',
    });
    if (result.isError) return result.error;

    final url = (result.data as Map<String, dynamic>?)?['url'] as String?;
    if (url == null || url.isEmpty)
      return 'Stripe did not return a checkout URL.';
    final launched =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return launched ? null : 'Could not open the payment page.';
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String organisationName,
    String? phone,
  }) async {
    final fullName = '$firstName $lastName'.trim();
    final result = await _invoke('signup', body: {
      'email': email,
      'password': password,
      'fullName': fullName.isEmpty ? null : fullName,
      'organisationName': organisationName,
      'phone': phone ?? '',
    });
    if (result.isError) return result.error;
    return null;
  }

  // ─── Internals ────────────────────────────────────────────────

  Future<FunctionInvokeResult> _invoke(
    String name, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client.functions.invoke(
        name,
        body: body ?? const {},
      );
      final data = response.data;
      final merged = data is Map<String, dynamic> ? data : <String, dynamic>{};
      if (response.status >= 400 || merged['error'] != null) {
        return FunctionInvokeResult.error(
          (merged['error'] as String?) ??
              'Server error (HTTP ${response.status})',
        );
      }
      return FunctionInvokeResult.ok(merged);
    } on FunctionException catch (e) {
      // Supabase functions_client 2.5.0 dropped the .message getter -
      // the human-readable body lives in e.details (often a JSON
      // {error: "..."} map or a raw string).
      final details = e.details;
      String? fromDetails;
      if (details is Map && details['error'] is String) {
        fromDetails = details['error'] as String;
      } else if (details is String && details.isNotEmpty) {
        fromDetails = details;
      }
      return FunctionInvokeResult.error(
        fromDetails ?? e.reasonPhrase ?? 'Server error (HTTP ${e.status})',
      );
    } catch (e) {
      return FunctionInvokeResult.error(e.toString());
    }
  }

  DateTime? _lastRefresh;

  bool _hasFreshCache() {
    if (_status.status == 'error') return false;
    if (_lastRefresh == null) return false;
    return DateTime.now().difference(_lastRefresh!) <
        const Duration(seconds: 10);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Minimal result wrapper for edge-function calls.
class FunctionInvokeResult {
  final Map<String, dynamic>? data;
  final bool isError;
  final String? error;

  const FunctionInvokeResult._({this.data, this.isError = false, this.error});

  factory FunctionInvokeResult.ok(Map<String, dynamic> data) =>
      FunctionInvokeResult._(data: data);

  factory FunctionInvokeResult.error(String error) =>
      FunctionInvokeResult._(isError: true, error: error);
}
