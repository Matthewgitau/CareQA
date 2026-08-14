import 'package:flutter/material.dart';

class FoodFluidChart {
  final String? id;
  final String serviceUserId;
  final DateTime chartDate;
  final Map<String, dynamic> entries; // breakfast, midMorning, lunch, afternoon, eveningMeal, supper
  final int? totalFluidMl;
  final bool? fluidTargetMet;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  FoodFluidChart({
    this.id,
    required this.serviceUserId,
    required this.chartDate,
    required this.entries,
    this.totalFluidMl,
    this.fluidTargetMet,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory FoodFluidChart.fromJson(Map<String, dynamic> json) => FoodFluidChart(
    id: json['id'],
    serviceUserId: json['service_user_id'],
    chartDate: DateTime.parse(json['chart_date']),
    entries: Map<String, dynamic>.from(json['entries'] ?? {}),
    totalFluidMl: json['total_fluid_ml'],
    fluidTargetMet: json['fluid_target_met'],
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
    'entries': entries,
    'total_fluid_ml': totalFluidMl,
    'fluid_target_met': fluidTargetMet,
    'notes': notes,
  };

  // Calculate total fluid from entries
  int calculateTotalFluid() {
    int total = 0;
    for (final meal in entries.values) {
      if (meal is Map<String, dynamic>) {
        final fluidAmount = meal['fluidAmount'] as int?;
        if (fluidAmount != null) {
          total += fluidAmount;
        }
      }
    }
    return total;
  }

  // Check if fluid target is met (assuming 1500ml target)
  bool checkFluidTargetMet() {
    return calculateTotalFluid() >= 1500;
  }

  // Get meal entries with default structure
  Map<String, dynamic> getMealEntry(String mealKey) {
    return entries[mealKey] ?? {
      'time': '',
      'foodOffered': '',
      'foodEaten': 'All',
      'fluidType': '',
      'fluidAmount': 0,
    };
  }
}

class FoodFluidChartSummary {
  final String id;
  final String serviceUserId;
  final DateTime chartDate;
  final int totalFluidMl;
  final bool fluidTargetMet;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  FoodFluidChartSummary({
    required this.id,
    required this.serviceUserId,
    required this.chartDate,
    required this.totalFluidMl,
    required this.fluidTargetMet,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory FoodFluidChartSummary.fromJson(Map<String, dynamic> json) => FoodFluidChartSummary(
    id: json['id'],
    serviceUserId: json['service_user_id'],
    chartDate: DateTime.parse(json['chart_date']),
    totalFluidMl: json['total_fluid_ml'] ?? 0,
    fluidTargetMet: json['fluid_target_met'] ?? false,
    createdBy: json['created_by'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedBy: json['updated_by'],
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );
}

// Constants for food eaten options
class FoodFluidConstants {
  static final List<String> foodEatenOptions = [
    'All',
    '3/4',
    '1/2',
    '1/4',
    'Minimal',
    'None',
    'Refused',
  ];

  static final List<String> fluidTypes = [
    'Water',
    'Tea',
    'Coffee',
    'Juice',
    'Milk',
    'Soft Drink',
    'Soup',
    'Other',
  ];
}