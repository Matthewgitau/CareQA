// Pure Dart model — no Flutter imports to avoid web compilation issues

class FoodFluidIntakeLog {
  final String? id;
  final String? serviceUserId;
  final String? serviceUserName;
  final DateTime logDate;
  final DateTime logTime;
  final String assessorName;
  final String logType; // 'fluid' or 'food'
  final String? fluidType; // 'water', 'juice', 'hot_drink', 'other'
  final int? amountPerServingMl;
  final int? numberOfServings;
  final int? totalFluidMl; // computed
  final String? mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final bool? foodObserved;
  final String? platePercentage; // 'none', 'quarter', 'third', 'half', 'three_quarters', 'all'
  final int? foodEatenPercent; // computed from plate
  final int? foodWastePercent; // 100 - eaten
  final String? foodDetails;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodFluidIntakeLog({
    this.id,
    this.serviceUserId,
    this.serviceUserName,
    required this.logDate,
    required this.logTime,
    required this.assessorName,
    required this.logType,
    this.fluidType,
    this.amountPerServingMl,
    this.numberOfServings,
    this.totalFluidMl,
    this.mealType,
    this.foodObserved,
    this.platePercentage,
    this.foodEatenPercent,
    this.foodWastePercent,
    this.foodDetails,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodFluidIntakeLog.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value.toLocal();
      return DateTime.parse(value).toLocal();
    }

    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return FoodFluidIntakeLog(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_user_name'],
      logDate: _parseDate(map['log_date']),
      logTime: _parseDate(map['log_time']),
      assessorName: map['assessor_name'] as String? ?? '',
      logType: map['log_type'] as String? ?? 'fluid',
      fluidType: map['fluid_type'],
      amountPerServingMl: _parseInt(map['amount_per_serving_ml']),
      numberOfServings: _parseInt(map['number_of_servings']),
      totalFluidMl: _parseInt(map['total_fluid_ml']),
      mealType: map['meal_type'],
      foodObserved: map['food_observed'] as bool?,
      platePercentage: map['plate_percentage'],
      foodEatenPercent: _parseInt(map['food_eaten_percent']),
      foodWastePercent: _parseInt(map['food_waste_percent']),
      foodDetails: map['food_details'],
      notes: map['notes'],
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'log_date': logDate.toIso8601String().split('T').first,
      'log_time': logTime.toIso8601String(),
      'assessor_name': assessorName,
      'log_type': logType,
      'fluid_type': fluidType,
      'amount_per_serving_ml': amountPerServingMl,
      'number_of_servings': numberOfServings,
      'total_fluid_ml': totalFluidMl,
      'meal_type': mealType,
      'food_observed': foodObserved,
      'plate_percentage': platePercentage,
      'food_eaten_percent': foodEatenPercent,
      'food_waste_percent': foodWastePercent,
      'food_details': foodDetails,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helpers - return strings (icons resolved in UI layer)
  static int percentageFromPlate(String? plate) {
    switch (plate) {
      case 'quarter': return 25;
      case 'third': return 33;
      case 'half': return 50;
      case 'three_quarters': return 75;
      case 'all': return 100;
      default: return 0;
    }
  }

  static String fluidLabel(String? type) {
    switch (type) {
      case 'juice': return 'Juice';
      case 'hot_drink': return 'Hot Drink';
      case 'other': return 'Other';
      default: return 'Water';
    }
  }

  static String mealLabel(String? type) {
    switch (type) {
      case 'breakfast': return 'Breakfast';
      case 'lunch': return 'Lunch';
      case 'dinner': return 'Dinner';
      case 'snack': return 'Snack';
      default: return 'Meal';
    }
  }
}