/// Server-driven subscription state for the paywall.
///
/// Mirrors what the `subscription-status` edge function returns and
/// what is stored on `organisations` / `profiles`.
class SubscriptionStatus {
  final bool hasAccess;
  final String status; // incomplete | trialing | active | past_due | canceled | error
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final String? plan; // monthly | annual
  final String? stripeCustomerId;
  final String? organisationId;
  final String? role;
  final String? error;

  const SubscriptionStatus({
    this.hasAccess = false,
    this.status = 'incomplete',
    this.trialStartedAt,
    this.trialEndsAt,
    this.plan,
    this.stripeCustomerId,
    this.organisationId,
    this.role,
    this.error,
  });

  /// True while a trial is still running.
  bool get isTrialing => status == 'trialing';
  bool get isActive => status == 'active';
  bool get isPastDue => status == 'past_due';

  /// Remaining trial duration (null when not trialing).
  Duration? get trialRemaining {
    if (!isTrialing || trialEndsAt == null) return null;
    return trialEndsAt!.difference(DateTime.now());
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) =>
        raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);

    return SubscriptionStatus(
      hasAccess: json['hasAccess'] == true,
      status: (json['status'] as String?) ?? 'incomplete',
      trialStartedAt: parse(json['trialStartedAt'] as String?),
      trialEndsAt: parse(json['trialEndsAt'] as String?),
      plan: json['plan'] as String?,
      stripeCustomerId: json['stripeCustomerId'] as String?,
      organisationId: json['organisationId'] as String?,
      role: json['role'] as String?,
      error: json['error'] as String?,
    );
  }
}