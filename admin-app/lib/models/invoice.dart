class Invoice {
  final String? id;
  final String invoiceNumber;
  final String clientType;
  final String? clientId;
  final String clientName;
  final String? clientAddress;
  final String? clientEmail;
  final String? clientReference;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<Map<String, dynamic>> lineItems;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final String status;
  final String? paymentMethod;
  final String? paymentReference;
  final DateTime? paidDate;
  final String? notes;
  final String? terms;
  final String? pdfUrl;
  final String? createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime updatedAt;
  final String organisationId;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.clientType,
    this.clientId,
    required this.clientName,
    this.clientAddress,
    this.clientEmail,
    this.clientReference,
    required this.periodStart,
    required this.periodEnd,
    required this.invoiceDate,
    required this.dueDate,
    this.lineItems = const [],
    this.subtotal = 0,
    this.taxRate = 20.0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.status = 'draft',
    this.paymentMethod,
    this.paymentReference,
    this.paidDate,
    this.notes,
    this.terms,
    this.pdfUrl,
    this.createdBy,
    required this.createdAt,
    this.updatedBy,
    required this.updatedAt,
    required this.organisationId,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString(),
      invoiceNumber: json['invoice_number'] ?? '',
      clientType: json['client_type'] ?? 'other',
      clientId: json['client_id']?.toString(),
      clientName: json['client_name'] ?? '',
      clientAddress: json['client_address'],
      clientEmail: json['client_email'],
      clientReference: json['client_reference'],
      periodStart: json['period_start'] != null ? DateTime.parse(json['period_start']) : DateTime.now(),
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : DateTime.now(),
      invoiceDate: json['invoice_date'] != null ? DateTime.parse(json['invoice_date']) : DateTime.now(),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : DateTime.now(),
      lineItems: json['line_items'] != null ? List<Map<String, dynamic>>.from(json['line_items']) : [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 20.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'draft',
      paymentMethod: json['payment_method'],
      paymentReference: json['payment_reference'],
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date']) : null,
      notes: json['notes'],
      terms: json['terms'],
      pdfUrl: json['pdf_url'],
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedBy: json['updated_by']?.toString(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      organisationId: json['organisation_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'client_type': clientType,
      'client_id': clientId,
      'client_name': clientName,
      'client_address': clientAddress,
      'client_email': clientEmail,
      'client_reference': clientReference,
      'period_start': periodStart.toIso8601String().split('T')[0],
      'period_end': periodEnd.toIso8601String().split('T')[0],
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'line_items': lineItems,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'status': status,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'paid_date': paidDate?.toIso8601String().split('T')[0],
      'notes': notes,
      'terms': terms,
      'pdf_url': pdfUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt.toIso8601String(),
      'organisation_id': organisationId,
    };
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? clientType,
    String? clientId,
    String? clientName,
    String? clientAddress,
    String? clientEmail,
    String? clientReference,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<Map<String, dynamic>>? lineItems,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
    String? status,
    String? paymentMethod,
    String? paymentReference,
    DateTime? paidDate,
    String? notes,
    String? terms,
    String? pdfUrl,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? organisationId,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientType: clientType ?? this.clientType,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientAddress: clientAddress ?? this.clientAddress,
      clientEmail: clientEmail ?? this.clientEmail,
      clientReference: clientReference ?? this.clientReference,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
    );
  }
}