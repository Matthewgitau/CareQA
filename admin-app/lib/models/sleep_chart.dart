import 'package:flutter/material.dart';

class SleepChart {
  final String? id;
  final String serviceUserId;
  final DateTime chartDate;
  final TimeOfDay? bedtimeTime;
  final String? bedtimeRoutine;
  final List<OvernightObservation> overnightEntries;
  final String? sleepQuality; // Good, Fair, Poor, Very Poor, Unsettled throughout
  final String? morningNotes;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final bool? hasDistressingObservations;

  SleepChart({
    this.id,
    required this.serviceUserId,
    required this.chartDate,
    this.bedtimeTime,
    this.bedtimeRoutine,
    required this.overnightEntries,
    this.sleepQuality,
    this.morningNotes,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.hasDistressingObservations,
  });

  factory SleepChart.fromJson(Map<String, dynamic> json) => SleepChart(
    id: json['id'],
    serviceUserId: json['service_user_id'],
    chartDate: DateTime.parse(json['chart_date']),
    bedtimeTime: json['bedtime_time'] != null ? _parseTime(json['bedtime_time']) : null,
    bedtimeRoutine: json['bedtime_routine'],
    overnightEntries: (json['overnight_entries'] as List).map((e) => OvernightObservation.fromJson(e)).toList(),
    sleepQuality: json['sleep_quality'],
    morningNotes: json['morning_notes'],
    createdBy: json['created_by'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedBy: json['updated_by'],
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    hasDistressingObservations: json['has_distressing_observations'],
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'service_user_id': serviceUserId,
    'chart_date': chartDate.toIso8601String(),
    'bedtime_time': bedtimeTime != null ? '${bedtimeTime!.hour.toString().padLeft(2, '0')}:${bedtimeTime!.minute.toString().padLeft(2, '0')}' : null,
    'bedtime_routine': bedtimeRoutine,
    'overnight_entries': overnightEntries.map((e) => e.toJson()).toList(),
    'sleep_quality': sleepQuality,
    'morning_notes': morningNotes,
    'has_distressing_observations': hasDistressingObservations,
  };

  // Get sleep quality color
  Color getSleepQualityColor() {
    switch (sleepQuality) {
      case 'Good':
        return Colors.green;
      case 'Fair':
        return Colors.yellow;
      case 'Poor':
        return Colors.orange;
      case 'Very Poor':
      case 'Unsettled throughout':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get sleep quality icon
  IconData getSleepQualityIcon() {
    switch (sleepQuality) {
      case 'Good':
        return Icons.bedtime;
      case 'Fair':
        return Icons.bedtime;
      case 'Poor':
        return Icons.bedtime;
      case 'Very Poor':
      case 'Unsettled throughout':
        return Icons.bedtime;
      default:
        return Icons.bedtime;
    }
  }

  // Count observations by status
  Map<String, int> getObservationCounts() {
    final counts = <String, int>{};
    for (final observation in overnightEntries) {
      counts[observation.status] = (counts[observation.status] ?? 0) + 1;
    }
    return counts;
  }

  // Check if any distressing observations
  bool hasAnyDistressingObservations() {
    return overnightEntries.any((obs) => 
      obs.status == 'Distressed' || 
      obs.status == 'Pain reported' || 
      obs.status == 'Fall' ||
      obs.status == 'Confused-wandering'
    );
  }

  // Get distressing observations
  List<OvernightObservation> getDistressingObservations() {
    return overnightEntries.where((obs) => 
      obs.status == 'Distressed' || 
      obs.status == 'Pain reported' || 
      obs.status == 'Fall' ||
      obs.status == 'Confused-wandering'
    ).toList();
  }

  // Get observation statistics
  Map<String, int> getObservationStatistics() {
    final stats = <String, int>{};
    for (final observation in overnightEntries) {
      stats[observation.status] = (stats[observation.status] ?? 0) + 1;
    }
    return stats;
  }
}

class OvernightObservation {
  final DateTime time;
  final String status; // One of the 9 observation types
  final String? notes;

  OvernightObservation({
    required this.time,
    required this.status,
    this.notes,
  });

  factory OvernightObservation.fromJson(Map<String, dynamic> json) => OvernightObservation(
    time: DateTime.parse(json['time']),
    status: json['status'],
    notes: json['notes'],
  );

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'status': status,
    'notes': notes,
  };

  // Get observation color
  Color getStatusColor() {
    switch (status) {
      case 'Asleep':
        return Colors.green;
      case 'Awake-settled':
        return Colors.blue;
      case 'Awake-disturbed':
      case 'Confused-wandering':
        return Colors.orange;
      case 'Up-toilet':
        return Colors.purple;
      case 'Repositioned':
        return Colors.teal;
      case 'Distressed':
      case 'Pain reported':
      case 'Fall':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get observation icon
  IconData getStatusIcon() {
    switch (status) {
      case 'Asleep':
        return Icons.bedtime;
      case 'Awake-settled':
        return Icons.accessibility;
      case 'Awake-disturbed':
        return Icons.accessibility_new;
      case 'Up-toilet':
        return Icons.bathtub;
      case 'Repositioned':
        return Icons.rotate_left;
      case 'Distressed':
        return Icons.warning;
      case 'Confused-wandering':
        return Icons.directions_walk;
      case 'Pain reported':
        return Icons.health_and_safety;
      case 'Fall':
        return Icons.warning_amber;
      default:
        return Icons.circle;
    }
  }

  // Get observation description
  String getStatusDescription() {
    return SleepConstants.observationDescriptions[status] ?? 'Unknown observation';
  }
}

class SleepAuditLog {
  final String id;
  final String chartId;
  final String editedBy;
  final Map<String, dynamic> previousData;
  final Map<String, dynamic> newData;
  final DateTime editedAt;
  final String? editedByName;

  SleepAuditLog({
    required this.id,
    required this.chartId,
    required this.editedBy,
    required this.previousData,
    required this.newData,
    required this.editedAt,
    this.editedByName,
  });

  factory SleepAuditLog.fromJson(Map<String, dynamic> json) => SleepAuditLog(
    id: json['id'],
    chartId: json['chart_id'],
    editedBy: json['edited_by'],
    previousData: Map<String, dynamic>.from(json['previous_data'] ?? {}),
    newData: Map<String, dynamic>.from(json['new_data'] ?? {}),
    editedAt: DateTime.parse(json['edited_at']),
    editedByName: json['profiles']?['full_name'],
  );
}

class SleepChartSummary {
  final String id;
  final String serviceUserId;
  final DateTime chartDate;
  final String? sleepQuality;
  final int overnightEntryCount;
  final bool hasDistressingObservations;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  SleepChartSummary({
    required this.id,
    required this.serviceUserId,
    required this.chartDate,
    this.sleepQuality,
    required this.overnightEntryCount,
    required this.hasDistressingObservations,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory SleepChartSummary.fromJson(Map<String, dynamic> json) => SleepChartSummary(
    id: json['id'],
    serviceUserId: json['service_user_id'],
    chartDate: DateTime.parse(json['chart_date']),
    sleepQuality: json['sleep_quality'],
    overnightEntryCount: json['overnight_entry_count'] ?? 0,
    hasDistressingObservations: json['has_distressing_observations'] ?? false,
    createdBy: json['created_by'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedBy: json['updated_by'],
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );
}

// Constants for sleep chart
class SleepConstants {
  static const List<String> sleepQualityOptions = [
    'Good',
    'Fair',
    'Poor',
    'Very Poor',
    'Unsettled throughout',
  ];

  static const List<String> observationTypes = [
    'Asleep',
    'Awake-settled',
    'Awake-disturbed',
    'Up-toilet',
    'Repositioned',
    'Distressed',
    'Confused-wandering',
    'Pain reported',
    'Fall',
  ];

  static const Map<String, String> observationDescriptions = {
    'Asleep': 'Resting peacefully',
    'Awake-settled': 'Awake but calm',
    'Awake-disturbed': 'Agitated or restless',
    'Up-toilet': 'Used bathroom',
    'Repositioned': 'Repositioned in bed',
    'Distressed': 'In distress',
    'Confused-wandering': 'Wandering, confused',
    'Pain reported': 'Complained of pain',
    'Fall': 'Had a fall',
  };

  static const Map<String, Color> observationColors = {
    'Asleep': Colors.green,
    'Awake-settled': Colors.blue,
    'Awake-disturbed': Colors.orange,
    'Up-toilet': Colors.purple,
    'Repositioned': Colors.teal,
    'Distressed': Colors.red,
    'Confused-wandering': Colors.orange,
    'Pain reported': Colors.red,
    'Fall': Colors.red,
  };
}

// Helper function to parse time
TimeOfDay _parseTime(String timeStr) {
  final parts = timeStr.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}