import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invoice.g.dart';

enum InvoiceStatus {
  draft('draft'),
  sent('sent'),
  paid('paid'),
  overdue('overdue'),
  cancelled('cancelled'),
  refunded('refunded');

  final String value;

  const InvoiceStatus(this.value);

  factory InvoiceStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'sent':
        return InvoiceStatus.sent;
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      case 'refunded':
        return InvoiceStatus.refunded;
      default:
        throw ArgumentError('Invalid invoice status: $value');
    }
  }

  @override
  String toString() => value;
}

@JsonSerializable()
class Invoice extends Equatable {
  final String id;
  final String clientId;
  final String? shiftId;
  final String invoiceNumber;
  final double amount;
  final double vat;
  final double total;
  final InvoiceStatus status;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime? sentDate;
  final DateTime? paidDate;
  final DateTime? dueDate;
  final String? pdfUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.clientId,
    this.shiftId,
    required this.invoiceNumber,
    required this.amount,
    required this.vat,
    required this.total,
    required this.status,
    required this.periodStart,
    required this.periodEnd,
    this.sentDate,
    this.paidDate,
    this.dueDate,
    this.pdfUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

  Invoice copyWith({
    String? id,
    String? clientId,
    String? shiftId,
    String? invoiceNumber,
    double? amount,
    double? vat,
    double? total,
    InvoiceStatus? status,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? sentDate,
    DateTime? paidDate,
    DateTime? dueDate,
    String? pdfUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      shiftId: shiftId ?? this.shiftId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      amount: amount ?? this.amount,
      vat: vat ?? this.vat,
      total: total ?? this.total,
      status: status ?? this.status,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      sentDate: sentDate ?? this.sentDate,
      paidDate: paidDate ?? this.paidDate,
      dueDate: dueDate ?? this.dueDate,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, invoiceNumber, total, status];

  bool get isPaid => status == InvoiceStatus.paid;
  bool get isOverdue => status == InvoiceStatus.overdue;
  bool get isDraft => status == InvoiceStatus.draft;
  bool get isSent => status == InvoiceStatus.sent;
  bool get isCancelled => status == InvoiceStatus.cancelled;
  bool get isRefunded => status == InvoiceStatus.refunded;

  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
  bool get isDue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;
}