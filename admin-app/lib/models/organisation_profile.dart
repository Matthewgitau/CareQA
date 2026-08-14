class OrganisationProfile {
  final String? id;
  final String organisationId;
  final String legalName;
  final String? tradingName;
  final String? registrationNumber;
  final String? vatNumber;
  final String? cqcRegistrationNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? county;
  final String? postcode;
  final String country;
  final String? phone;
  final String? email;
  final String? website;
  final String invoicePrefix;
  final String invoiceTerms;
  final String? bankName;
  final String? bankAccountName;
  final String? bankSortCode;
  final String? bankAccountNumber;
  final double taxRate;
  final String? logoUrl;
  final String primaryColor;

  OrganisationProfile({
    this.id,
    required this.organisationId,
    required this.legalName,
    this.tradingName,
    this.registrationNumber,
    this.vatNumber,
    this.cqcRegistrationNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.county,
    this.postcode,
    this.country = 'United Kingdom',
    this.phone,
    this.email,
    this.website,
    this.invoicePrefix = 'INV-',
    this.invoiceTerms = '30 days',
    this.bankName,
    this.bankAccountName,
    this.bankSortCode,
    this.bankAccountNumber,
    this.taxRate = 20.0,
    this.logoUrl,
    this.primaryColor = '#1565C0',
  });

  factory OrganisationProfile.fromJson(Map<String, dynamic> json) {
    return OrganisationProfile(
      id: json['id']?.toString(),
      organisationId: json['organisation_id']?.toString() ?? '',
      legalName: json['legal_name'] ?? '',
      tradingName: json['trading_name'],
      registrationNumber: json['registration_number'],
      vatNumber: json['vat_number'],
      cqcRegistrationNumber: json['cqc_registration_number'],
      addressLine1: json['address_line_1'],
      addressLine2: json['address_line_2'],
      city: json['city'],
      county: json['county'],
      postcode: json['postcode'],
      country: json['country'] ?? 'United Kingdom',
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      invoicePrefix: json['invoice_prefix'] ?? 'INV-',
      invoiceTerms: json['invoice_terms'] ?? '30 days',
      bankName: json['bank_name'],
      bankAccountName: json['bank_account_name'],
      bankSortCode: json['bank_sort_code'],
      bankAccountNumber: json['bank_account_number'],
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 20.0,
      logoUrl: json['logo_url'],
      primaryColor: json['primary_color'] ?? '#1565C0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'organisation_id': organisationId,
      'legal_name': legalName,
      'trading_name': tradingName,
      'registration_number': registrationNumber,
      'vat_number': vatNumber,
      'cqc_registration_number': cqcRegistrationNumber,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'county': county,
      'postcode': postcode,
      'country': country,
      'phone': phone,
      'email': email,
      'website': website,
      'invoice_prefix': invoicePrefix,
      'invoice_terms': invoiceTerms,
      'bank_name': bankName,
      'bank_account_name': bankAccountName,
      'bank_sort_code': bankSortCode,
      'bank_account_number': bankAccountNumber,
      'tax_rate': taxRate,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
    };
  }
}