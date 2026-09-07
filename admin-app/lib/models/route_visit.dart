class RouteVisit {
  final String id;
  final String? clientOrganisationId;
  final String? routeId;
  final String serviceUserId;
  final String? carerId;
  final DateTime visitDate;
  final DateTime visitTime;
  final int durationMinutes;
  final String status;
  final bool respite;
  final bool requiresTwoCarers;
  final int sortOrder;
  final String? notes;
  final String? serviceUserName;
  final String? carerName;
  final String? routeName;

  const RouteVisit({
    required this.id,
    this.clientOrganisationId,
    this.routeId,
    required this.serviceUserId,
    this.carerId,
    required this.visitDate,
    required this.visitTime,
    this.durationMinutes = 60,
    this.status = 'scheduled',
    this.respite = false,
    this.requiresTwoCarers = false,
    this.sortOrder = 1,
    this.notes,
    this.serviceUserName,
    this.carerName,
    this.routeName,
  });

  DateTime get endTime => visitTime.add(Duration(minutes: durationMinutes));

  factory RouteVisit.fromJson(Map<String, dynamic> json) {
    final serviceUsers = json['service_users'];
    final carers = json['carers'];
    final routes = json['routes'];
    return RouteVisit(
      id: json['id'] as String,
      clientOrganisationId: json['client_organisation_id'] as String?,
      routeId: json['route_id'] as String?,
      serviceUserId: json['service_user_id'] as String,
      carerId: json['carer_id'] as String?,
      visitDate: DateTime.tryParse(json['visit_date'] ?? '') ?? DateTime.now(),
      visitTime: DateTime.tryParse(json['visit_time'] ?? '') ?? DateTime.now(),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      status: json['status'] as String? ?? 'scheduled',
      respite: json['respite'] as bool? ?? false,
      requiresTwoCarers: json['requires_two_carers'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 1,
      notes: json['notes'] as String?,
      serviceUserName: _extractName(serviceUsers),
      carerName: _extractName(carers),
      routeName: _extractName(routes),
    );
  }

  static String? _extractName(dynamic joined) {
    if (joined is Map<String, dynamic>) {
      return joined['name'] as String?;
    }
    return null;
  }
}

class RouteChangeLogEntry {
  final String id;
  final String? clientOrganisationId;
  final String? visitId;
  final String? routeId;
  final String? changedBy;
  final String changeType;
  final String? description;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final DateTime createdAt;

  const RouteChangeLogEntry({
    required this.id,
    this.clientOrganisationId,
    this.visitId,
    this.routeId,
    this.changedBy,
    required this.changeType,
    this.description,
    this.oldValue,
    this.newValue,
    required this.createdAt,
  });

  factory RouteChangeLogEntry.fromJson(Map<String, dynamic> json) {
    return RouteChangeLogEntry(
      id: json['id'] as String,
      clientOrganisationId: json['client_organisation_id'] as String?,
      visitId: json['visit_id'] as String?,
      routeId: json['route_id'] as String?,
      changedBy: json['changed_by'] as String?,
      changeType: json['change_type'] as String? ?? 'unknown',
      description: json['description'] as String?,
      oldValue: json['old_value'] != null
          ? Map<String, dynamic>.from(json['old_value'] as Map)
          : null,
      newValue: json['new_value'] != null
          ? Map<String, dynamic>.from(json['new_value'] as Map)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}