import 'dart:convert';

class ServiceUserCall {
  final String id;
  final String serviceUserId;
  final String? organisationId;
  final int callsPerDay;
  final List<String> callTimes;
  final bool respite;
  final bool hospital;
  final bool holiday;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serviceUserName;

  const ServiceUserCall({
    required this.id,
    required this.serviceUserId,
    this.organisationId,
    this.callsPerDay = 1,
    this.callTimes = const [],
    this.respite = false,
    this.hospital = false,
    this.holiday = false,
    required this.createdAt,
    required this.updatedAt,
    this.serviceUserName,
  });

  /// Whether this call schedule is flagged as non-billable
  /// (respite, hospital, or holiday).
  bool get isNonBillable => respite || hospital || holiday;

  /// Total planned minutes across all call times.
  /// Each call is assumed to be 60 minutes unless otherwise configured.
  int get totalPlannedMinutes => callsPerDay * 60;

  /// Total planned hours (decimal).
  double get totalPlannedHours => totalPlannedMinutes / 60;

  /// Billable minutes (excludes non-billable flags).
  int get billableMinutes => isNonBillable ? 0 : totalPlannedMinutes;

  /// Billable hours (decimal).
  double get billableHours => billableMinutes / 60;

  factory ServiceUserCall.fromJson(Map<String, dynamic> json) {
    // call_times is stored as a JSON string like "[\"06:14\", \"11:14\"]"
    List<String> times = [];
    final rawTimes = json['call_times'];
    if (rawTimes is String) {
      try {
        final decoded = jsonDecode(rawTimes);
        if (decoded is List) {
          times = decoded.map((t) => t.toString()).toList();
        }
      } catch (_) {
        // Fall back to splitting on commas
        times = rawTimes
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
      }
    } else if (rawTimes is List) {
      times = rawTimes.map((t) => t.toString()).toList();
    }

    final serviceUsers = json['service_users'];
    return ServiceUserCall(
      id: json['id'] as String,
      serviceUserId: json['service_user_id'] as String,
      organisationId: json['organisation_id'] as String?,
      callsPerDay: json['calls_per_day'] as int? ?? 1,
      callTimes: times,
      respite: json['respite'] as bool? ?? false,
      hospital: json['hospital'] as bool? ?? false,
      holiday: json['holiday'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      serviceUserName: serviceUsers is Map<String, dynamic>
          ? serviceUsers['name'] as String?
          : null,
    );
  }
}