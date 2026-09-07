class Shift {
  final String id;
  final String? serviceUserId;
  final String? serviceUserName;
  final String? serviceUserAddress;
  final String? carerId;
  final String? carerName;
  final String? scheduledDate;
  final String startTime;
  final String endTime;
  final String status;
  final String? location;
  final int? staffRequired;
  final String? staffType;
  final String? notes;
  final String? clientOrganisationId;
  final String? organisationId;
  final String? routeName;
  final String source;

  Shift({
    required this.id,
    this.serviceUserId,
    this.serviceUserName,
    this.serviceUserAddress,
    this.carerId,
    this.carerName,
    this.scheduledDate,
    required this.startTime,
    required this.endTime,
    this.status = 'scheduled',
    this.location,
    this.staffRequired,
    this.staffType,
    this.notes,
    this.clientOrganisationId,
    this.organisationId,
    this.routeName,
    this.source = 'shift',
  });

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_users']?['name'] ?? map['service_user_name'],
      serviceUserAddress: map['service_users']?['address'] ?? map['service_user_address'],
      carerId: map['carer_id'],
      carerName: map['carers']?['name'] ?? map['carer_name'],
      scheduledDate: map['scheduled_date'],
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      status: map['status'] ?? 'scheduled',
      location: map['location'],
      staffRequired: map['staff_required'],
      staffType: map['staff_type'],
      notes: map['notes'],
      clientOrganisationId: map['client_organisation_id'],
      organisationId: map['organisation_id'],
      routeName: map['routes']?['name'] ?? map['route_name'],
      source: map['source'] ?? 'shift',
    );
  }

  /// Builds a Shift-like card from a `route_visits` row (the Dom Care call
  /// record written by the ADMIN app). Staff see these as "route calls".
  /// The staff-app previously ONLY read the legacy `shifts` table, so these
  /// permanent-route visits never appeared on the staff dashboard.
  factory Shift.fromRouteCall(Map<String, dynamic> map) {
    final visitTime = map['visit_time'] as String?;
    final duration = (map['duration_minutes'] as num?)?.toInt() ?? 60;
    final start = visitTime?.substring(11, 16); // "HH:mm" from ISO timestamp

    // Compute end time from start + duration for display purposes.
    String? endTime;
    if (visitTime != null) {
      final startDt = DateTime.tryParse(visitTime);
      if (startDt != null) {
        final endDt = startDt.add(Duration(minutes: duration));
        endTime =
            '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Shift(
      id: map['id'] as String? ?? '',
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_users']?['name'] ?? map['service_user_name'],
      serviceUserAddress: map['service_users']?['address'] ?? map['service_user_address'],
      carerId: map['carer_id'],
      carerName: map['carers']?['name'] ?? map['carer_name'],
      scheduledDate: map['visit_date']?.toString(),
      startTime: start ?? '',
      endTime: endTime ?? '',
      status: map['status'] ?? 'scheduled',
      notes: map['notes'],
      clientOrganisationId: map['client_organisation_id'],
      organisationId: map['organisation_id'],
      routeName: map['routes']?['name'],
      source: 'route',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'carer_id': carerId,
      'scheduled_date': scheduledDate,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'location': location,
      'staff_required': staffRequired,
      'staff_type': staffType,
      'notes': notes,
      'client_organisation_id': clientOrganisationId,
      'organisation_id': organisationId,
    };
  }
}