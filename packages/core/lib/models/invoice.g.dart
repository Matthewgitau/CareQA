// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invoice _$InvoiceFromJson(Map<String, dynamic> json) => Invoice(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      shiftId: json['shift_id'] as String?,
      invoiceNumber: json['invoice_number'] as String,
      amount: (json['amount'] as num).toDouble(),
      vat: (json['vat'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: InvoiceStatus.fromString(json['status'] as String),
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      sentDate: json['sent_date'] == null
          ? null
          : DateTime.parse(json['sent_date'] as String),
      paidDate: json['paid_date'] == null
          ? null
          : DateTime.parse(json['paid_date'] as String),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      pdfUrl: json['pdf_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$InvoiceToJson(Invoice instance) => <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'shift_id': instance.shiftId,
      'invoice_number': instance.invoiceNumber,
      'amount': instance.amount,
      'vat': instance.vat,
      'total': instance.total,
      'status': instance.status.value,
      'period_start': instance.periodStart.toIso8601String(),
      'period_end': instance.periodEnd.toIso8601String(),
      'sent_date': instance.sentDate?.toIso8601String(),
      'paid_date': instance.paidDate?.toIso8601String(),
      'due_date': instance.dueDate?.toIso8601String(),
      'pdf_url': instance.pdfUrl,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };