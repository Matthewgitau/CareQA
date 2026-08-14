import 'package:supabase_flutter/supabase_flutter.dart';

class PreAdmission {
  final String id;
  final String? familyName;
  final String? firstName;
  final String? preferredName;
  final String? title;
  final DateTime? dateOfBirth;
  final String? addressStreet;
  final String? addressTown;
  final String? addressPostcode;
  final String? currentAddressStreet;
  final String? currentAddressTown;
  final String? currentAddressPostcode;
  final String? telephone;
  final String? ethnicity;
  
  // Main Carer
  final String? mainCarerName;
  final String? mainCarerStreet;
  final String? mainCarerTown;
  final String? mainCarerPostcode;
  final String? mainCarerTelephone;
  
  // Next of Kin
  final String? nextOfKinName;
  final String? nextOfKinStreet;
  final String? nextOfKinTown;
  final String? nextOfKinPostcode;
  final String? nextOfKinTelephone;
  
  // GP Details
  final String? gpName;
  final String? gpSurgery;
  final String? gpStreet;
  final String? gpTown;
  final String? gpPostcode;
  final String? gpTelephone;
  
  // Communication
  final String? firstLanguage;
  final String? communicationNeeds;
  final bool? capacityDoubts;
  final bool? requiresImca;
  
  // Assessment People (JSON)
  final List<Map<String, dynamic>>? assessmentPeople;
  
  // Background
  final String? backgroundReason;
  final String? serviceUserViews;
  final String? carerViews;
  final String? lifeHistory;
  
  // Medical
  final String? medicalConditions;
  final bool? antibioticLast3Months;
  final String? antibioticDetails;
  final bool? vaccinationInfluenza;
  final bool? vaccinationPneumonia;
  final bool? vaccinationShingles;
  final bool? vaccinationCovid;
  final String? invasiveDevices;
  final String? wounds;
  
  // Physical Health
  final String? physicalHealth;
  
  // ADL Assessments (JSON)
  final List<Map<String, dynamic>>? adlAssessments;
  
  // Financial
  final String? fundingSource;
  
  // Metadata
  final String? serviceUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? status;
  final DateTime? submittedAt;
  final String? submittedBy;

  PreAdmission({
    required this.id,
    this.familyName,
    this.firstName,
    this.preferredName,
    this.title,
    this.dateOfBirth,
    this.addressStreet,
    this.addressTown,
    this.addressPostcode,
    this.currentAddressStreet,
    this.currentAddressTown,
    this.currentAddressPostcode,
    this.telephone,
    this.ethnicity,
    this.mainCarerName,
    this.mainCarerStreet,
    this.mainCarerTown,
    this.mainCarerPostcode,
    this.mainCarerTelephone,
    this.nextOfKinName,
    this.nextOfKinStreet,
    this.nextOfKinTown,
    this.nextOfKinPostcode,
    this.nextOfKinTelephone,
    this.gpName,
    this.gpSurgery,
    this.gpStreet,
    this.gpTown,
    this.gpPostcode,
    this.gpTelephone,
    this.firstLanguage,
    this.communicationNeeds,
    this.capacityDoubts,
    this.requiresImca,
    this.assessmentPeople,
    this.backgroundReason,
    this.serviceUserViews,
    this.carerViews,
    this.lifeHistory,
    this.medicalConditions,
    this.antibioticLast3Months,
    this.antibioticDetails,
    this.vaccinationInfluenza,
    this.vaccinationPneumonia,
    this.vaccinationShingles,
    this.vaccinationCovid,
    this.invasiveDevices,
    this.wounds,
    this.physicalHealth,
    this.adlAssessments,
    this.fundingSource,
    this.serviceUserId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.status,
    this.submittedAt,
    this.submittedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'family_name': familyName,
      'first_name': firstName,
      'preferred_name': preferredName,
      'title': title,
      'date_of_birth': dateOfBirth,
      'address_street': addressStreet,
      'address_town': addressTown,
      'address_postcode': addressPostcode,
      'current_address_street': currentAddressStreet,
      'current_address_town': currentAddressTown,
      'current_address_postcode': currentAddressPostcode,
      'telephone': telephone,
      'ethnicity': ethnicity,
      'main_carer_name': mainCarerName,
      'main_carer_street': mainCarerStreet,
      'main_carer_town': mainCarerTown,
      'main_carer_postcode': mainCarerPostcode,
      'main_carer_telephone': mainCarerTelephone,
      'next_of_kin_name': nextOfKinName,
      'next_of_kin_street': nextOfKinStreet,
      'next_of_kin_town': nextOfKinTown,
      'next_of_kin_postcode': nextOfKinPostcode,
      'next_of_kin_telephone': nextOfKinTelephone,
      'gp_name': gpName,
      'gp_surgery': gpSurgery,
      'gp_street': gpStreet,
      'gp_town': gpTown,
      'gp_postcode': gpPostcode,
      'gp_telephone': gpTelephone,
      'first_language': firstLanguage,
      'communication_needs': communicationNeeds,
      'capacity_doubts': capacityDoubts,
      'requires_imca': requiresImca,
      'assessment_people': assessmentPeople,
      'background_reason': backgroundReason,
      'service_user_views': serviceUserViews,
      'carer_views': carerViews,
      'life_history': lifeHistory,
      'medical_conditions': medicalConditions,
      'antibiotic_last_3_months': antibioticLast3Months,
      'antibiotic_details': antibioticDetails,
      'vaccination_influenza': vaccinationInfluenza,
      'vaccination_pneumonia': vaccinationPneumonia,
      'vaccination_shingles': vaccinationShingles,
      'vaccination_covid': vaccinationCovid,
      'invasive_devices': invasiveDevices,
      'wounds': wounds,
      'physical_health': physicalHealth,
      'adl_assessments': adlAssessments,
      'funding_source': fundingSource,
      'service_user_id': serviceUserId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by': createdBy,
      'status': status,
      'submitted_at': submittedAt,
      'submitted_by': submittedBy,
    };
  }

  factory PreAdmission.fromMap(Map<String, dynamic> map) {
    return PreAdmission(
      id: map['id'] ?? '',
      familyName: map['family_name'],
      firstName: map['first_name'],
      preferredName: map['preferred_name'],
      title: map['title'],
      dateOfBirth: map['date_of_birth'] as DateTime?,
      addressStreet: map['address_street'],
      addressTown: map['address_town'],
      addressPostcode: map['address_postcode'],
      currentAddressStreet: map['current_address_street'],
      currentAddressTown: map['current_address_town'],
      currentAddressPostcode: map['current_address_postcode'],
      telephone: map['telephone'],
      ethnicity: map['ethnicity'],
      mainCarerName: map['main_carer_name'],
      mainCarerStreet: map['main_carer_street'],
      mainCarerTown: map['main_carer_town'],
      mainCarerPostcode: map['main_carer_postcode'],
      mainCarerTelephone: map['main_carer_telephone'],
      nextOfKinName: map['next_of_kin_name'],
      nextOfKinStreet: map['next_of_kin_street'],
      nextOfKinTown: map['next_of_kin_town'],
      nextOfKinPostcode: map['next_of_kin_postcode'],
      nextOfKinTelephone: map['next_of_kin_telephone'],
      gpName: map['gp_name'],
      gpSurgery: map['gp_surgery'],
      gpStreet: map['gp_street'],
      gpTown: map['gp_town'],
      gpPostcode: map['gp_postcode'],
      gpTelephone: map['gp_telephone'],
      firstLanguage: map['first_language'],
      communicationNeeds: map['communication_needs'],
      capacityDoubts: map['capacity_doubts'] as bool?,
      requiresImca: map['requires_imca'] as bool?,
      assessmentPeople: map['assessment_people'] as List<Map<String, dynamic>>?,
      backgroundReason: map['background_reason'],
      serviceUserViews: map['service_user_views'],
      carerViews: map['carer_views'],
      lifeHistory: map['life_history'],
      medicalConditions: map['medical_conditions'],
      antibioticLast3Months: map['antibiotic_last_3_months'] as bool?,
      antibioticDetails: map['antibiotic_details'],
      vaccinationInfluenza: map['vaccination_influenza'] as bool?,
      vaccinationPneumonia: map['vaccination_pneumonia'] as bool?,
      vaccinationShingles: map['vaccination_shingles'] as bool?,
      vaccinationCovid: map['vaccination_covid'] as bool?,
      invasiveDevices: map['invasive_devices'],
      wounds: map['wounds'],
      physicalHealth: map['physical_health'],
      adlAssessments: map['adl_assessments'] as List<Map<String, dynamic>>?,
      fundingSource: map['funding_source'],
      serviceUserId: map['service_user_id'],
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
      createdBy: map['created_by'],
      status: map['status'],
      submittedAt: map['submitted_at'] as DateTime?,
      submittedBy: map['submitted_by'],
    );
  }
}

class ADLCategory {
  final int id;
  final String categoryName;
  final int displayOrder;
  final String? description;

  ADLCategory({
    required this.id,
    required this.categoryName,
    required this.displayOrder,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_name': categoryName,
      'display_order': displayOrder,
      'description': description,
    };
  }

  factory ADLCategory.fromMap(Map<String, dynamic> map) {
    return ADLCategory(
      id: map['id'] as int,
      categoryName: map['category_name'] as String,
      displayOrder: map['display_order'] as int,
      description: map['description'],
    );
  }
}

class PreAdmissionSummary {
  final int totalAdlCategories;
  final int completedAdlCategories;
  final bool hasMedicalConditions;
  final bool hasVaccinationInfo;
  final String status;
  final DateTime? createdDate;
  final DateTime? submittedDate;

  PreAdmissionSummary({
    required this.totalAdlCategories,
    required this.completedAdlCategories,
    required this.hasMedicalConditions,
    required this.hasVaccinationInfo,
    required this.status,
    this.createdDate,
    this.submittedDate,
  });

  factory PreAdmissionSummary.fromMap(Map<String, dynamic> map) {
    return PreAdmissionSummary(
      totalAdlCategories: map['total_adl_categories'] as int,
      completedAdlCategories: map['completed_adl_categories'] as int,
      hasMedicalConditions: map['has_medical_conditions'] as bool,
      hasVaccinationInfo: map['has_vaccination_info'] as bool,
      status: map['status'] as String,
      createdDate: map['created_date'] as DateTime?,
      submittedDate: map['submitted_date'] as DateTime?,
    );
  }
}

class PreAdmissionValidation {
  final bool isComplete;
  final List<String> missingSections;
  final List<String> warnings;

  PreAdmissionValidation({
    required this.isComplete,
    required this.missingSections,
    required this.warnings,
  });

  factory PreAdmissionValidation.fromMap(Map<String, dynamic> map) {
    return PreAdmissionValidation(
      isComplete: map['is_complete'] as bool,
      missingSections: List<String>.from(map['missing_sections'] ?? []),
      warnings: List<String>.from(map['warnings'] ?? []),
    );
  }
}