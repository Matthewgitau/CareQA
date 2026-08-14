/// Represents an audit log entry for carer training record changes
class CarerTrainingHistory {
  final String id;
  final String trainingRecordId;
  final String action; // 'created', 'updated', 'deleted', 'uploaded_certificate'
  final Map<String, dynamic>? previousData;
  final Map<String, dynamic>? newData;
  final String? changedBy;
  final DateTime changedAt;
  final String? organisationId;

  CarerTrainingHistory({
    required this.id,
    required this.trainingRecordId,
    required this.action,
    this.previousData,
    this.newData,
    this.changedBy,
    required this.changedAt,
    this.organisationId,
  });

  factory CarerTrainingHistory.fromJson(Map<String, dynamic> json) {
    return CarerTrainingHistory(
      id: json['id'] ?? '',
      trainingRecordId: json['training_record_id'] ?? '',
      action: json['action'] ?? '',
      previousData: json['previous_data'] != null ? Map<String, dynamic>.from(json['previous_data']) : null,
      newData: json['new_data'] != null ? Map<String, dynamic>.from(json['new_data']) : null,
      changedBy: json['changed_by'],
      changedAt: json['changed_at'] != null ? DateTime.parse(json['changed_at']) : DateTime.now(),
      organisationId: json['organisation_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'training_record_id': trainingRecordId,
      'action': action,
      'previous_data': previousData,
      'new_data': newData,
      'changed_by': changedBy,
      'changed_at': changedAt.toIso8601String(),
      'organisation_id': organisationId,
    };
  }

  String getActionDisplay() {
    switch (action) {
      case 'created':
        return 'Created';
      case 'updated':
        return 'Updated';
      case 'deleted':
        return 'Deleted';
      case 'uploaded_certificate':
        return 'Certificate Uploaded';
      default:
        return action;
    }
  }

  CarerTrainingHistory copyWith({
    String? id,
    String? trainingRecordId,
    String? action,
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? newData,
    String? changedBy,
    DateTime? changedAt,
    String? organisationId,
  }) {
    return CarerTrainingHistory(
      id: id ?? this.id,
      trainingRecordId: trainingRecordId ?? this.trainingRecordId,
      action: action ?? this.action,
      previousData: previousData ?? this.previousData,
      newData: newData ?? this.newData,
      changedBy: changedBy ?? this.changedBy,
      changedAt: changedAt ?? this.changedAt,
      organisationId: organisationId ?? this.organisationId,
    );
  }
}