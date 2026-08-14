import 'package:flutter/material.dart';

class BowelBladderChart {
  final String? id;
  final String serviceUserId;
  final DateTime chartDate;
  final List<BowelEntry> bowelEntries;
  final List<BladderEntry> bladderEntries;
  final int daysSinceLastBowel;
  final bool warningTriggered;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  BowelBladderChart({
    this.id,
    required this.serviceUserId,
    required this.chartDate,
    required this.bowelEntries,
    required this.bladderEntries,
    required this.daysSinceLastBowel,
    this.warningTriggered = false,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory BowelBladderChart.fromJson(Map<String, dynamic> json) => BowelBladderChart(
    id: json['id'],
    serviceUserId: json['service_user_id'],
    chartDate: DateTime.parse(json['chart_date']),
    bowelEntries: (json['entries']['bowel'] as List).map((e) => BowelEntry.fromJson(e)).toList(),
    bladderEntries: (json['entries']['bladder'] as List).map((e) => BladderEntry.fromJson(e)).toList(),
    daysSinceLastBowel: json['days_since_last_bowel'],
    warningTriggered: json['warning_triggered'] ?? false,
    notes: json['notes'],
    createdBy: json['created_by'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedBy: json['updated_by'],
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'service_user_id': serviceUserId,
    'chart_date': chartDate.toIso8601String(),
    'entries': {
      'bowel': bowelEntries.map((e) => e.toJson()).toList(),
      'bladder': bladderEntries.map((e) => e.toJson()).toList(),
    },
    'days_since_last_bowel': daysSinceLastBowel,
    'warning_triggered': warningTriggered,
    'notes': notes,
  };

  // Calculate warning status
  bool checkWarningTriggered() {
    return daysSinceLastBowel > 3;
  }

  // Get total bladder volume
  int getTotalBladderVolume() {
    return bladderEntries.fold(0, (sum, entry) => sum + entry.volumeMl);
  }

  // Check if any incontinence events
  bool hasIncontinenceEvents() {
    return bladderEntries.any((entry) => entry.incontinence);
  }
}

class BowelEntry {
  final DateTime time;
  final int bristolStoolType; // 1-7
  final String consistency;
  final String colour;
  final String amount;

  BowelEntry({
    required this.time,
    required this.bristolStoolType,
    required this.consistency,
    required this.colour,
    required this.amount,
  });

  factory BowelEntry.fromJson(Map<String, dynamic> json) => BowelEntry(
    time: DateTime.parse(json['time']),
    bristolStoolType: json['bristol_stool_type'],
    consistency: json['consistency'],
    colour: json['colour'],
    amount: json['amount'],
  );

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'bristol_stool_type': bristolStoolType,
    'consistency': consistency,
    'colour': colour,
    'amount': amount,
  };

  // Get Bristol Stool Scale description
  String getBristolDescription() {
    switch (bristolStoolType) {
      case 1: return 'Separate hard lumps (severe constipation)';
      case 2: return 'Lumpy and sausage-like (mild constipation)';
      case 3: return 'Sausage shape with cracks (normal)';
      case 4: return 'Smooth, soft sausage (normal)';
      case 5: return 'Soft blobs with clear edges (lacking fiber)';
      case 6: return 'Mushy consistency (mild diarrhea)';
      case 7: return 'Liquid (severe diarrhea)';
      default: return 'Unknown';
    }
  }

  Color getBristolColor() {
    switch (bristolStoolType) {
      case 1:
      case 2:
        return Colors.red; // Constipation
      case 3:
      case 4:
        return Colors.green; // Normal
      case 5:
      case 6:
      case 7:
        return Colors.orange; // Diarrhea
      default:
        return Colors.grey;
    }
  }
}

class BladderEntry {
  final DateTime time;
  final String urineColour;
  final int volumeMl;
  final bool incontinence;

  BladderEntry({
    required this.time,
    required this.urineColour,
    required this.volumeMl,
    required this.incontinence,
  });

  factory BladderEntry.fromJson(Map<String, dynamic> json) => BladderEntry(
    time: DateTime.parse(json['time']),
    urineColour: json['urine_colour'],
    volumeMl: json['volume_ml'],
    incontinence: json['incontinence'],
  );

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'urine_colour': urineColour,
    'volume_ml': volumeMl,
    'incontinence': incontinence,
  };
}

// Constants for Bristol Stool Scale
class BristolStoolScale {
  static const Map<int, String> descriptions = {
    1: 'Separate hard lumps (severe constipation)',
    2: 'Lumpy and sausage-like (mild constipation)',
    3: 'Sausage shape with cracks (normal)',
    4: 'Smooth, soft sausage (normal)',
    5: 'Soft blobs with clear edges (lacking fiber)',
    6: 'Mushy consistency (mild diarrhea)',
    7: 'Liquid (severe diarrhea)',
  };

  static const List<String> consistencies = [
    'Hard',
    'Lumpy',
    'Cracked',
    'Smooth',
    'Soft',
    'Mushy',
    'Liquid',
  ];

  static const List<String> colours = [
    'Brown',
    'Dark Brown',
    'Light Brown',
    'Green',
    'Yellow',
    'Black',
    'Red',
    'Other',
  ];

  static const List<String> amounts = [
    'Small',
    'Medium',
    'Large',
    'Minimal',
    'Excessive',
  ];
}

// Constants for urine colours
class UrineColours {
  static const List<String> colours = [
    'Clear',
    'Pale Yellow',
    'Dark Yellow',
    'Amber',
    'Orange',
    'Red',
    'Pink',
    'Brown',
    'Cloudy',
    'Other',
  ];
}