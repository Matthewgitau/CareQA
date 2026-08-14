class ReceiptEntry {
  final String id;
  final String merchantName;
  final String? merchantAddress;
  final String? merchantPhone;
  final String? merchantTaxId;
  final DateTime receiptDate;
  final String? receiptTime;
  final double? subtotal;
  final double? taxRate;
  final double? taxAmount;
  final double totalAmount;
  final String currency;
  final String? paymentMethod;
  final String? cardLastFour;
  final List<dynamic> items;
  final String? ocrRawText;
  final int? ocrConfidence;
  final String? ocrProvider;
  final String? originalPhotoUrl;
  final String? category;
  final List<String>? tags;
  final bool isBillable;
  final String? billableTo;
  final String? expenseNotes;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final Map<String, dynamic>? receiptData;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final String? organisationId;

  ReceiptEntry({
    required this.id,
    required this.merchantName,
    this.merchantAddress,
    this.merchantPhone,
    this.merchantTaxId,
    required this.receiptDate,
    this.receiptTime,
    this.subtotal,
    this.taxRate,
    this.taxAmount,
    required this.totalAmount,
    this.currency = 'GBP',
    this.paymentMethod,
    this.cardLastFour,
    this.items = const [],
    this.ocrRawText,
    this.ocrConfidence,
    this.ocrProvider,
    this.originalPhotoUrl,
    this.category,
    this.tags,
    this.isBillable = false,
    this.billableTo,
    this.expenseNotes,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.receiptData,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.organisationId,
  });

  factory ReceiptEntry.fromJson(Map<String, dynamic> json) {
    return ReceiptEntry(
      id: json['id'] as String,
      merchantName: json['merchant_name'] as String,
      merchantAddress: json['merchant_address'] as String?,
      merchantPhone: json['merchant_phone'] as String?,
      merchantTaxId: json['merchant_tax_id'] as String?,
      receiptDate: json['receipt_date'] != null
        ? DateTime.parse(json['receipt_date'] as String)
        : DateTime.now(),
      receiptTime: json['receipt_time'] as String?,
      subtotal: json['subtotal'] != null
        ? (json['subtotal'] as num).toDouble()
        : null,
      taxRate: json['tax_rate'] != null
        ? (json['tax_rate'] as num).toDouble()
        : null,
      taxAmount: json['tax_amount'] != null
        ? (json['tax_amount'] as num).toDouble()
        : null,
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'GBP',
      paymentMethod: json['payment_method'] as String?,
      cardLastFour: json['card_last_four'] as String?,
      items: json['items'] as List<dynamic>? ?? [],
      ocrRawText: json['ocr_raw_text'] as String?,
      ocrConfidence: json['ocr_confidence'] as int?,
      ocrProvider: json['ocr_provider'] as String?,
      originalPhotoUrl: json['original_photo_url'] as String?,
      category: json['category'] as String?,
      tags: json['tags'] != null
        ? List<String>.from(json['tags'] as List)
        : null,
      isBillable: json['is_billable'] as bool? ?? false,
      billableTo: json['billable_to'] as String?,
      expenseNotes: json['expense_notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
        ? DateTime.parse(json['approved_at'] as String)
        : null,
      rejectionReason: json['rejection_reason'] as String?,
      receiptData: json['receipt_data'] as Map<String, dynamic>?,
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
      'merchant_name': merchantName,
      'merchant_address': merchantAddress,
      'merchant_phone': merchantPhone,
      'merchant_tax_id': merchantTaxId,
      'receipt_date': receiptDate.toIso8601String().split('T')[0],
      'receipt_time': receiptTime,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'currency': currency,
      'payment_method': paymentMethod,
      'card_last_four': cardLastFour,
      'items': items,
      'ocr_raw_text': ocrRawText,
      'ocr_confidence': ocrConfidence,
      'ocr_provider': ocrProvider,
      'original_photo_url': originalPhotoUrl,
      'category': category,
      'tags': tags,
      'is_billable': isBillable,
      'billable_to': billableTo,
      'expense_notes': expenseNotes,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'receipt_data': receiptData,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt?.toIso8601String(),
      'organisation_id': organisationId,
    };
  }

  ReceiptEntry copyWith({
    String? id,
    String? merchantName,
    String? merchantAddress,
    String? merchantPhone,
    String? merchantTaxId,
    DateTime? receiptDate,
    String? receiptTime,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
    String? currency,
    String? paymentMethod,
    String? cardLastFour,
    List<dynamic>? items,
    String? ocrRawText,
    int? ocrConfidence,
    String? ocrProvider,
    String? originalPhotoUrl,
    String? category,
    List<String>? tags,
    bool? isBillable,
    String? billableTo,
    String? expenseNotes,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    Map<String, dynamic>? receiptData,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? organisationId,
  }) {
    return ReceiptEntry(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      merchantTaxId: merchantTaxId ?? this.merchantTaxId,
      receiptDate: receiptDate ?? this.receiptDate,
      receiptTime: receiptTime ?? this.receiptTime,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardLastFour: cardLastFour ?? this.cardLastFour,
      items: items ?? this.items,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      ocrProvider: ocrProvider ?? this.ocrProvider,
      originalPhotoUrl: originalPhotoUrl ?? this.originalPhotoUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isBillable: isBillable ?? this.isBillable,
      billableTo: billableTo ?? this.billableTo,
      expenseNotes: expenseNotes ?? this.expenseNotes,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      receiptData: receiptData ?? this.receiptData,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
    );
  }
}