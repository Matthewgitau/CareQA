import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../models/receipt_entry.dart';
import '../../services/receipt_service.dart';

class ReceiptViewScreen extends StatefulWidget {
  final String receiptId;

  const ReceiptViewScreen({super.key, required this.receiptId});

  @override
  State<ReceiptViewScreen> createState() => _ReceiptViewScreenState();
}

class _ReceiptViewScreenState extends State<ReceiptViewScreen> {
  final ReceiptService _receiptService = ReceiptService(Supabase.instance.client);
  ReceiptEntry? _receipt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    setState(() => _isLoading = true);
    try {
      _receipt = await _receiptService.getReceipt(widget.receiptId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading receipt: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePDF() async {
    if (_receipt == null) return;

    try {
      final pdf = await _createPDF(_receipt!);
      final bytes = await pdf.save();

      // Save to temp directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/receipt_${_receipt!.id}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share the PDF file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Receipt from ${_receipt!.merchantName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<pw.Document> _createPDF(ReceiptEntry receipt) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'RECEIPT',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),

              // Merchant Info
              pw.Text('Merchant:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(receipt.merchantName),
              if (receipt.merchantAddress != null) pw.Text(receipt.merchantAddress!),
              if (receipt.merchantPhone != null) pw.Text('Phone: ${receipt.merchantPhone}'),
              if (receipt.merchantTaxId != null) pw.Text('Tax ID: ${receipt.merchantTaxId}'),
              pw.SizedBox(height: 16),

              // Transaction Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('dd/MM/yyyy').format(receipt.receiptDate)),
                    ],
                  ),
                  if (receipt.receiptTime != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Time:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(receipt.receiptTime!),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Items Table
              if (receipt.items.isNotEmpty) ...[
                pw.Text('Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Items
                    ...receipt.items.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['description'] ?? ''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['quantity']?.toString() ?? '1'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('£${(item['unit_price'] ?? 0).toStringAsFixed(2)}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('£${(item['total'] ?? 0).toStringAsFixed(2)}'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 16),
              ],

              // Totals
              pw.Divider(),
              pw.SizedBox(height: 8),
              if (receipt.subtotal != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:'),
                    pw.Text('£${receipt.subtotal!.toStringAsFixed(2)}'),
                  ],
                ),
              if (receipt.taxAmount != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax:'),
                    pw.Text('£${receipt.taxAmount!.toStringAsFixed(2)}'),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text(
                    '£${receipt.totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Payment Method
              if (receipt.paymentMethod != null)
                pw.Text('Payment Method: ${receipt.paymentMethod!.toUpperCase()}'),
              pw.SizedBox(height: 16),

              // Notes
              if (receipt.expenseNotes != null) ...[
                pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(receipt.expenseNotes!),
                pw.SizedBox(height: 16),
              ],

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(fontStyle: pw.FontItalic),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _printReceipt() async {
    if (_receipt == null) return;

    try {
      final pdf = await _createPDF(_receipt!);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_receipt != null) ...[
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printReceipt,
              tooltip: 'Print',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _generatePDF,
              tooltip: 'Share PDF',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _receipt == null
              ? const Center(child: Text('Receipt not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Receipt Preview Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'RECEIPT',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1565C0),
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),

                              // Merchant Info
                              _buildSection('Merchant Information'),
                              Text(_receipt!.merchantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              if (_receipt!.merchantAddress != null) Text(_receipt!.merchantAddress!),
                              if (_receipt!.merchantPhone != null) Text('Phone: ${_receipt!.merchantPhone}'),
                              if (_receipt!.merchantTaxId != null) Text('Tax ID: ${_receipt!.merchantTaxId}'),
                              const SizedBox(height: 16),

                              // Transaction Details
                              _buildSection('Transaction Details'),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(DateFormat('dd/MM/yyyy').format(_receipt!.receiptDate)),
                                    ],
                                  ),
                                  if (_receipt!.receiptTime != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(_receipt!.receiptTime!),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Items
                              if (_receipt!.items.isNotEmpty) ...[
                                _buildSection('Items'),
                                ..._receipt!.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Text(item['description'] ?? ''),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text('x${item['quantity'] ?? 1}'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('£${(item['unit_price'] ?? 0).toStringAsFixed(2)}'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '£${(item['total'] ?? 0).toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(),
                              ],

                              // Totals
                              if (_receipt!.subtotal != null)
                                _buildTotalRow('Subtotal', '£${_receipt!.subtotal!.toStringAsFixed(2)}'),
                              if (_receipt!.taxAmount != null)
                                _buildTotalRow('Tax', '£${_receipt!.taxAmount!.toStringAsFixed(2)}'),
                              _buildTotalRow(
                                'Total',
                                '£${_receipt!.totalAmount.toStringAsFixed(2)}',
                                isBold: true,
                                fontSize: 18,
                              ),
                              const SizedBox(height: 16),

                              // Payment Method
                              if (_receipt!.paymentMethod != null)
                                _buildInfoRow('Payment Method', _receipt!.paymentMethod!.toUpperCase()),
                              if (_receipt!.category != null)
                                _buildInfoRow('Category', _receipt!.category!.replaceAll('_', ' ').toUpperCase()),
                              const SizedBox(height: 16),

                              // Notes
                              if (_receipt!.expenseNotes != null) ...[
                                _buildSection('Notes'),
                                Text(_receipt!.expenseNotes!),
                                const SizedBox(height: 16),
                              ],

                              // Status
                              _buildSection('Status'),
                              _StatusBadge(status: _receipt!.status),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Original Photo
                      if (_receipt!.originalPhotoUrl != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Original Photo',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Image.network(
                                  _receipt!.originalPhotoUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(32),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Text('Failed to load image'),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'audited':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}