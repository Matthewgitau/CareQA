class Supplier {
  final String id;
  final String supplierName;
  final String? tradingName;
  final String? supplierType;
  final String supplierStatus;
  final String? contactName;
  final String? contactTitle;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactMobile;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? county;
  final String? postcode;
  final String? country;
  final String? websiteUrl;
  final String? companyRegistrationNumber;
  final String? vatNumber;
  final String? cqcRegistrationNumber;
  final String? nhsSupplierCode;
  final List<String>? isoCertifications;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final DateTime? publicLiabilityExpiry;
  final DateTime? employersLiabilityExpiry;
  final DateTime? professionalIndemnityExpiry;
  final String? contractUrl;
  final String? dataSharingAgreementUrl;
  final String? dbsPolicyUrl;
  final String? healthSafetyPolicyUrl;
  final String? qualityPolicyUrl;
  final String? equalOpportunitiesPolicyUrl;
  final String? environmentalPolicyUrl;
  final String? safeguardingPolicyUrl;
  final String? whistleblowingPolicyUrl;
  final String? paymentTerms;
  final String? bankName;
  final String? bankAccountName;
  final String? bankSortCode;
  final String? bankAccountNumber;
  final String? invoicingNotes;
  final int? performanceRating;
  final String? riskRating;
  final DateTime? lastPerformanceReviewDate;
  final DateTime? nextPerformanceReviewDate;
  final int? qualityRating;
  final int? valueRating;
  final DateTime? lastComplianceCheckDate;
  final DateTime? nextComplianceCheckDate;
  final String? complianceStatus;
  final String? complianceNotes;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final double? contractValue;
  final String? contractRenewalTerms;
  final int? noticePeriodWeeks;
  final List<String>? servicesProvided;
  final String? specialRequirements;
  final String? hoursOfOperation;
  final String? emergencyContactProcedure;
  final List<dynamic>? incidentHistory;
  final List<dynamic>? complaintHistory;
  final String? notes;
  final String? internalNotes;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final String? organisationId;

  Supplier({
    required this.id,
    required this.supplierName,
    this.tradingName,
    this.supplierType,
    this.supplierStatus = 'active',
    this.contactName,
    this.contactTitle,
    this.contactEmail,
    this.contactPhone,
    this.contactMobile,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.county,
    this.postcode,
    this.country = 'United Kingdom',
    this.websiteUrl,
    this.companyRegistrationNumber,
    this.vatNumber,
    this.cqcRegistrationNumber,
    this.nhsSupplierCode,
    this.isoCertifications,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.publicLiabilityExpiry,
    this.employersLiabilityExpiry,
    this.professionalIndemnityExpiry,
    this.contractUrl,
    this.dataSharingAgreementUrl,
    this.dbsPolicyUrl,
    this.healthSafetyPolicyUrl,
    this.qualityPolicyUrl,
    this.equalOpportunitiesPolicyUrl,
    this.environmentalPolicyUrl,
    this.safeguardingPolicyUrl,
    this.whistleblowingPolicyUrl,
    this.paymentTerms = '30_days',
    this.bankName,
    this.bankAccountName,
    this.bankSortCode,
    this.bankAccountNumber,
    this.invoicingNotes,
    this.performanceRating,
    this.riskRating,
    this.lastPerformanceReviewDate,
    this.nextPerformanceReviewDate,
    this.qualityRating,
    this.valueRating,
    this.lastComplianceCheckDate,
    this.nextComplianceCheckDate,
    this.complianceStatus = 'pending',
    this.complianceNotes,
    this.contractStartDate,
    this.contractEndDate,
    this.contractValue,
    this.contractRenewalTerms,
    this.noticePeriodWeeks = 4,
    this.servicesProvided,
    this.specialRequirements,
    this.hoursOfOperation,
    this.emergencyContactProcedure,
    this.incidentHistory,
    this.complaintHistory,
    this.notes,
    this.internalNotes,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.organisationId,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      supplierName: json['supplier_name'] as String,
      tradingName: json['trading_name'] as String?,
      supplierType: json['supplier_type'] as String?,
      supplierStatus: json['supplier_status'] as String? ?? 'active',
      contactName: json['contact_name'] as String?,
      contactTitle: json['contact_title'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactMobile: json['contact_mobile'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String?,
      county: json['county'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String? ?? 'United Kingdom',
      websiteUrl: json['website_url'] as String?,
      companyRegistrationNumber: json['company_registration_number'] as String?,
      vatNumber: json['vat_number'] as String?,
      cqcRegistrationNumber: json['cqc_registration_number'] as String?,
      nhsSupplierCode: json['nhs_supplier_code'] as String?,
      isoCertifications: json['iso_certifications'] != null 
        ? List<String>.from(json['iso_certifications'] as List)
        : null,
      insuranceProvider: json['insurance_provider'] as String?,
      insurancePolicyNumber: json['insurance_policy_number'] as String?,
      publicLiabilityExpiry: json['public_liability_expiry'] != null
        ? DateTime.parse(json['public_liability_expiry'] as String)
        : null,
      employersLiabilityExpiry: json['employers_liability_expiry'] != null
        ? DateTime.parse(json['employers_liability_expiry'] as String)
        : null,
      professionalIndemnityExpiry: json['professional_indemnity_expiry'] != null
        ? DateTime.parse(json['professional_indemnity_expiry'] as String)
        : null,
      contractUrl: json['contract_url'] as String?,
      dataSharingAgreementUrl: json['data_sharing_agreement_url'] as String?,
      dbsPolicyUrl: json['dbs_policy_url'] as String?,
      healthSafetyPolicyUrl: json['health_safety_policy_url'] as String?,
      qualityPolicyUrl: json['quality_policy_url'] as String?,
      equalOpportunitiesPolicyUrl: json['equal_opportunities_policy_url'] as String?,
      environmentalPolicyUrl: json['environmental_policy_url'] as String?,
      safeguardingPolicyUrl: json['safeguarding_policy_url'] as String?,
      whistleblowingPolicyUrl: json['whistleblowing_policy_url'] as String?,
      paymentTerms: json['payment_terms'] as String? ?? '30_days',
      bankName: json['bank_name'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      bankSortCode: json['bank_sort_code'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      invoicingNotes: json['invoicing_notes'] as String?,
      performanceRating: json['performance_rating'] as int?,
      riskRating: json['risk_rating'] as String?,
      lastPerformanceReviewDate: json['last_performance_review_date'] != null
        ? DateTime.parse(json['last_performance_review_date'] as String)
        : null,
      nextPerformanceReviewDate: json['next_performance_review_date'] != null
        ? DateTime.parse(json['next_performance_review_date'] as String)
        : null,
      qualityRating: json['quality_rating'] as int?,
      valueRating: json['value_rating'] as int?,
      lastComplianceCheckDate: json['last_compliance_check_date'] != null
        ? DateTime.parse(json['last_compliance_check_date'] as String)
        : null,
      nextComplianceCheckDate: json['next_compliance_check_date'] != null
        ? DateTime.parse(json['next_compliance_check_date'] as String)
        : null,
      complianceStatus: json['compliance_status'] as String? ?? 'pending',
      complianceNotes: json['compliance_notes'] as String?,
      contractStartDate: json['contract_start_date'] != null
        ? DateTime.parse(json['contract_start_date'] as String)
        : null,
      contractEndDate: json['contract_end_date'] != null
        ? DateTime.parse(json['contract_end_date'] as String)
        : null,
      contractValue: json['contract_value'] != null
        ? (json['contract_value'] as num).toDouble()
        : null,
      contractRenewalTerms: json['contract_renewal_terms'] as String?,
      noticePeriodWeeks: json['notice_period_weeks'] as int? ?? 4,
      servicesProvided: json['services_provided'] != null
        ? List<String>.from(json['services_provided'] as List)
        : null,
      specialRequirements: json['special_requirements'] as String?,
      hoursOfOperation: json['hours_of_operation'] as String?,
      emergencyContactProcedure: json['emergency_contact_procedure'] as String?,
      incidentHistory: json['incident_history'] as List<dynamic>?,
      complaintHistory: json['complaint_history'] as List<dynamic>?,
      notes: json['notes'] as String?,
      internalNotes: json['internal_notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
      updatedBy: json['updated_by'] as String?,
      updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
      organisationId: json['organisation_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_name': supplierName,
      'trading_name': tradingName,
      'supplier_type': supplierType,
      'supplier_status': supplierStatus,
      'contact_name': contactName,
      'contact_title': contactTitle,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'contact_mobile': contactMobile,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'county': county,
      'postcode': postcode,
      'country': country,
      'website_url': websiteUrl,
      'company_registration_number': companyRegistrationNumber,
      'vat_number': vatNumber,
      'cqc_registration_number': cqcRegistrationNumber,
      'nhs_supplier_code': nhsSupplierCode,
      'iso_certifications': isoCertifications,
      'insurance_provider': insuranceProvider,
      'insurance_policy_number': insurancePolicyNumber,
      'public_liability_expiry': publicLiabilityExpiry?.toIso8601String(),
      'employers_liability_expiry': employersLiabilityExpiry?.toIso8601String(),
      'professional_indemnity_expiry': professionalIndemnityExpiry?.toIso8601String(),
      'contract_url': contractUrl,
      'data_sharing_agreement_url': dataSharingAgreementUrl,
      'dbs_policy_url': dbsPolicyUrl,
      'health_safety_policy_url': healthSafetyPolicyUrl,
      'quality_policy_url': qualityPolicyUrl,
      'equal_opportunities_policy_url': equalOpportunitiesPolicyUrl,
      'environmental_policy_url': environmentalPolicyUrl,
      'safeguarding_policy_url': safeguardingPolicyUrl,
      'whistleblowing_policy_url': whistleblowingPolicyUrl,
      'payment_terms': paymentTerms,
      'bank_name': bankName,
      'bank_account_name': bankAccountName,
      'bank_sort_code': bankSortCode,
      'bank_account_number': bankAccountNumber,
      'invoicing_notes': invoicingNotes,
      'performance_rating': performanceRating,
      'risk_rating': riskRating,
      'last_performance_review_date': lastPerformanceReviewDate?.toIso8601String(),
      'next_performance_review_date': nextPerformanceReviewDate?.toIso8601String(),
      'quality_rating': qualityRating,
      'value_rating': valueRating,
      'last_compliance_check_date': lastComplianceCheckDate?.toIso8601String(),
      'next_compliance_check_date': nextComplianceCheckDate?.toIso8601String(),
      'compliance_status': complianceStatus,
      'compliance_notes': complianceNotes,
      'contract_start_date': contractStartDate?.toIso8601String(),
      'contract_end_date': contractEndDate?.toIso8601String(),
      'contract_value': contractValue,
      'contract_renewal_terms': contractRenewalTerms,
      'notice_period_weeks': noticePeriodWeeks,
      'services_provided': servicesProvided,
      'special_requirements': specialRequirements,
      'hours_of_operation': hoursOfOperation,
      'emergency_contact_procedure': emergencyContactProcedure,
      'incident_history': incidentHistory,
      'complaint_history': complaintHistory,
      'notes': notes,
      'internal_notes': internalNotes,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt?.toIso8601String(),
      'organisation_id': organisationId,
    };
  }

  Supplier copyWith({
    String? id,
    String? supplierName,
    String? tradingName,
    String? supplierType,
    String? supplierStatus,
    String? contactName,
    String? contactTitle,
    String? contactEmail,
    String? contactPhone,
    String? contactMobile,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? county,
    String? postcode,
    String? country,
    String? websiteUrl,
    String? companyRegistrationNumber,
    String? vatNumber,
    String? cqcRegistrationNumber,
    String? nhsSupplierCode,
    List<String>? isoCertifications,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    DateTime? publicLiabilityExpiry,
    DateTime? employersLiabilityExpiry,
    DateTime? professionalIndemnityExpiry,
    String? contractUrl,
    String? dataSharingAgreementUrl,
    String? dbsPolicyUrl,
    String? healthSafetyPolicyUrl,
    String? qualityPolicyUrl,
    String? equalOpportunitiesPolicyUrl,
    String? environmentalPolicyUrl,
    String? safeguardingPolicyUrl,
    String? whistleblowingPolicyUrl,
    String? paymentTerms,
    String? bankName,
    String? bankAccountName,
    String? bankSortCode,
    String? bankAccountNumber,
    String? invoicingNotes,
    int? performanceRating,
    String? riskRating,
    DateTime? lastPerformanceReviewDate,
    DateTime? nextPerformanceReviewDate,
    int? qualityRating,
    int? valueRating,
    DateTime? lastComplianceCheckDate,
    DateTime? nextComplianceCheckDate,
    String? complianceStatus,
    String? complianceNotes,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    double? contractValue,
    String? contractRenewalTerms,
    int? noticePeriodWeeks,
    List<String>? servicesProvided,
    String? specialRequirements,
    String? hoursOfOperation,
    String? emergencyContactProcedure,
    List<dynamic>? incidentHistory,
    List<dynamic>? complaintHistory,
    String? notes,
    String? internalNotes,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? organisationId,
  }) {
    return Supplier(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      tradingName: tradingName ?? this.tradingName,
      supplierType: supplierType ?? this.supplierType,
      supplierStatus: supplierStatus ?? this.supplierStatus,
      contactName: contactName ?? this.contactName,
      contactTitle: contactTitle ?? this.contactTitle,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      contactMobile: contactMobile ?? this.contactMobile,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      county: county ?? this.county,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      companyRegistrationNumber: companyRegistrationNumber ?? this.companyRegistrationNumber,
      vatNumber: vatNumber ?? this.vatNumber,
      cqcRegistrationNumber: cqcRegistrationNumber ?? this.cqcRegistrationNumber,
      nhsSupplierCode: nhsSupplierCode ?? this.nhsSupplierCode,
      isoCertifications: isoCertifications ?? this.isoCertifications,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePolicyNumber: insurancePolicyNumber ?? this.insurancePolicyNumber,
      publicLiabilityExpiry: publicLiabilityExpiry ?? this.publicLiabilityExpiry,
      employersLiabilityExpiry: employersLiabilityExpiry ?? this.employersLiabilityExpiry,
      professionalIndemnityExpiry: professionalIndemnityExpiry ?? this.professionalIndemnityExpiry,
      contractUrl: contractUrl ?? this.contractUrl,
      dataSharingAgreementUrl: dataSharingAgreementUrl ?? this.dataSharingAgreementUrl,
      dbsPolicyUrl: dbsPolicyUrl ?? this.dbsPolicyUrl,
      healthSafetyPolicyUrl: healthSafetyPolicyUrl ?? this.healthSafetyPolicyUrl,
      qualityPolicyUrl: qualityPolicyUrl ?? this.qualityPolicyUrl,
      equalOpportunitiesPolicyUrl: equalOpportunitiesPolicyUrl ?? this.equalOpportunitiesPolicyUrl,
      environmentalPolicyUrl: environmentalPolicyUrl ?? this.environmentalPolicyUrl,
      safeguardingPolicyUrl: safeguardingPolicyUrl ?? this.safeguardingPolicyUrl,
      whistleblowingPolicyUrl: whistleblowingPolicyUrl ?? this.whistleblowingPolicyUrl,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankSortCode: bankSortCode ?? this.bankSortCode,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      invoicingNotes: invoicingNotes ?? this.invoicingNotes,
      performanceRating: performanceRating ?? this.performanceRating,
      riskRating: riskRating ?? this.riskRating,
      lastPerformanceReviewDate: lastPerformanceReviewDate ?? this.lastPerformanceReviewDate,
      nextPerformanceReviewDate: nextPerformanceReviewDate ?? this.nextPerformanceReviewDate,
      qualityRating: qualityRating ?? this.qualityRating,
      valueRating: valueRating ?? this.valueRating,
      lastComplianceCheckDate: lastComplianceCheckDate ?? this.lastComplianceCheckDate,
      nextComplianceCheckDate: nextComplianceCheckDate ?? this.nextComplianceCheckDate,
      complianceStatus: complianceStatus ?? this.complianceStatus,
      complianceNotes: complianceNotes ?? this.complianceNotes,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      contractValue: contractValue ?? this.contractValue,
      contractRenewalTerms: contractRenewalTerms ?? this.contractRenewalTerms,
      noticePeriodWeeks: noticePeriodWeeks ?? this.noticePeriodWeeks,
      servicesProvided: servicesProvided ?? this.servicesProvided,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      hoursOfOperation: hoursOfOperation ?? this.hoursOfOperation,
      emergencyContactProcedure: emergencyContactProcedure ?? this.emergencyContactProcedure,
      incidentHistory: incidentHistory ?? this.incidentHistory,
      complaintHistory: complaintHistory ?? this.complaintHistory,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
    );
  }
}