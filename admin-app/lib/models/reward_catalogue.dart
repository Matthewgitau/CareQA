class RewardCatalogue {
  final String id;
  final String rewardName;
  final String rewardType;
  final String? description;
  final int pointsRequired;
  final double? monetaryValue;
  final String? imageUrl;
  final String? supplier;
  final bool isAvailable;
  final int? stockQuantity;
  final int maxPerEmployee;
  final String? organisationId;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  RewardCatalogue({
    required this.id,
    required this.rewardName,
    required this.rewardType,
    this.description,
    required this.pointsRequired,
    this.monetaryValue,
    this.imageUrl,
    this.supplier,
    this.isAvailable = true,
    this.stockQuantity,
    this.maxPerEmployee = 1,
    this.organisationId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RewardCatalogue.fromJson(Map<String, dynamic> json) {
    return RewardCatalogue(
      id: json['id'] ?? '',
      rewardName: json['reward_name'] ?? '',
      rewardType: json['reward_type'] ?? 'other',
      description: json['description'],
      pointsRequired: json['points_required'] ?? 0,
      monetaryValue: json['monetary_value']?.toDouble(),
      imageUrl: json['image_url'],
      supplier: json['supplier'],
      isAvailable: json['is_available'] ?? true,
      stockQuantity: json['stock_quantity'],
      maxPerEmployee: json['max_per_employee'] ?? 1,
      organisationId: json['organisation_id'],
      createdById: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'reward_name': rewardName,
      'reward_type': rewardType,
      'description': description,
      'points_required': pointsRequired,
      'monetary_value': monetaryValue,
      'image_url': imageUrl,
      'supplier': supplier,
      'is_available': isAvailable,
      'stock_quantity': stockQuantity,
      'max_per_employee': maxPerEmployee,
      'organisation_id': organisationId,
      'created_by': createdById,
    };
  }

  String getRewardTypeDisplay() {
    switch (rewardType) {
      case 'gift_card': return 'Gift Card';
      case 'voucher': return 'Voucher';
      case 'merchandise': return 'Merchandise';
      case 'experience': return 'Experience';
      case 'donation': return 'Charity Donation';
      case 'training_course': return 'Training Course';
      case 'extra_holiday': return 'Extra Holiday';
      case 'flexible_hours': return 'Flexible Hours';
      case 'parking_spot': return 'Reserved Parking Spot';
      default: return rewardType;
    }
  }

  bool get isInStock => stockQuantity == null || stockQuantity! > 0;
}