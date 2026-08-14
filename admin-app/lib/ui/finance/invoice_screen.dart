import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/invoice.dart';
import '../../models/organisation_profile.dart';
import '../../services/invoice_service.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = InvoiceService(Supabase.instance.client);
  bool _loading = true;
  bool _saving = false;
  bool _isEditing = false;

  // Client selection
  String? _selectedClientType;
  String? _selectedClientId;
  String _clientName = '';
  String? _clientAddress;
  String? _clientEmail;
  String? _clientReference;

  // Period
  DateTime _periodStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _periodEnd = DateTime.now();
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  // Line items
  List<Map<String, dynamic>> _lineItems = [];

  // Notes
  String _notes = '';
  String _terms = '30 days';

  // Organisation profile
  OrganisationProfile? _orgProfile;

  // Clients data
  List<Map<String, dynamic>> _serviceUsers = [];
  List<Map<String, dynamic>> _careHomes = [];
  List<Map<String, dynamic>> _councils = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await _service.getOrganisationProfile();
      setState(() => _orgProfile = profile);

      // Load clients
      final su = await Supabase.instance.client.from('service_users').select('id, name, address, email').order('name');
      final ch = await Supabase.instance.client.from('care_homes').select('id, name, address, email').order('name');
      final co = await Supabase.instance.client.from('councils').select('id, name, address, email').order('name');

      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(su);
        _careHomes = List<Map<String, dynamic>>.from(ch);
        _councils = List<Map<String, dynamic>>.from(co);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _saveInvoice({String? status}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientType == null || _clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a client'), backgroundColor: Colors.red));
      return;
    }
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one line item'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _saving = true);
    try {
      final subtotal = _lineItems.fold<double>(0, (sum, item) => sum + ((item['total'] as double?) ?? 0));
      final taxRate = _orgProfile?.taxRate ?? 20.0;
      final taxAmount = subtotal * taxRate / 100;
      final totalAmount = subtotal + taxAmount;

      final invoice = Invoice(
        invoiceNumber: '', // Will be auto-generated
        clientType: _selectedClientType!,
        clientId: _selectedClientId,
        clientName: _clientName,
        clientAddress: _clientAddress,
        clientEmail: _clientEmail,
        clientReference: _clientReference,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        lineItems: _lineItems,
        subtotal: subtotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        status: status ?? 'draft',
        notes: _notes.isEmpty ? null : _notes,
        terms: _terms.isEmpty ? null : _terms,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        organisationId: '', // Will be set by service
      );

      await _service.createInvoice(invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice ${status ?? 'draft'} saved'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _generatePdf() async {
    if (_orgProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set up organisation profile first'), backgroundColor: Colors.orange));
      return;
    }

    try {
      final subtotal = _lineItems.fold<double>(0, (sum, item) => sum + ((item['total'] as double?) ?? 0));
      final taxRate = _orgProfile!.taxRate;
      final taxAmount = subtotal * taxRate / 100;
      final totalAmount = subtotal + taxAmount;

      final invoice = Invoice(
        invoiceNumber: 'PREVIEW',
        clientType: _selectedClientType ?? 'other',
        clientId: _selectedClientId,
        clientName: _clientName,
        clientAddress: _clientAddress,
        clientEmail: _clientEmail,
        clientReference: _clientReference,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        lineItems: _lineItems,
        subtotal: subtotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        status: 'draft',
        notes: _notes.isEmpty ? null : _notes,
        terms: _terms.isEmpty ? null : _terms,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        organisationId: '',
      );

      final pdfBytes = await InvoicePDFGenerator().generateInvoicePDF(invoice, _orgProfile!);

      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add({
        'description': '',
        'quantity': 1,
        'unit_price': 0.0,
        'total': 0.0,
      });
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
    });
  }

  void _updateLineItem(int index, String field, dynamic value) {
    setState(() {
      _lineItems[index][field] = value;
      if (field == 'quantity' || field == 'unit_price') {
        final qty = _lineItems[index]['quantity'] as int? ?? 1;
        final price = _lineItems[index]['unit_price'] as double? ?? 0.0;
        _lineItems[index]['total'] = qty * price;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Invoice' : 'New Invoice'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _generatePdf, icon: const Icon(Icons.picture_as_pdf)),
          IconButton(onPressed: () => _saveInvoice(status: 'draft'), icon: const Icon(Icons.save)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _clientSection(),
                  const SizedBox(height: 16),
                  _periodSection(),
                  const SizedBox(height: 16),
                  _lineItemsSection(),
                  const SizedBox(height: 16),
                  _notesSection(),
                  const SizedBox(height: 24),
                  _totalsSummary(),
                  const SizedBox(height: 24),
                  _actionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _clientSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Client Type *', border: OutlineInputBorder()),
              value: _selectedClientType,
              items: const [
                DropdownMenuItem(value: 'service_user', child: Text('Service User')),
                DropdownMenuItem(value: 'care_home', child: Text('Care Home')),
                DropdownMenuItem(value: 'council', child: Text('Council')),
                DropdownMenuItem(value: 'other', child: Text('Manual Entry')),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedClientType = v;
                  _selectedClientId = null;
                  _clientName = '';
                  _clientAddress = null;
                  _clientEmail = null;
                });
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            if (_selectedClientType == 'service_user' && _serviceUsers.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Service User', border: OutlineInputBorder()),
                value: _selectedClientId,
                items: _serviceUsers.map((su) => DropdownMenuItem(value: su['id']?.toString(), child: Text(su['name'] ?? 'Unknown'))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedClientId = v;
                    final user = _serviceUsers.firstWhere((su) => su['id']?.toString() == v, orElse: () => {});
                    _clientName = user['name'] ?? '';
                    _clientAddress = user['address'];
                    _clientEmail = user['email'];
                  });
                },
              ),
            if (_selectedClientType == 'care_home' && _careHomes.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Care Home', border: OutlineInputBorder()),
                value: _selectedClientId,
                items: _careHomes.map((ch) => DropdownMenuItem(value: ch['id']?.toString(), child: Text(ch['name'] ?? 'Unknown'))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedClientId = v;
                    final home = _careHomes.firstWhere((ch) => ch['id']?.toString() == v, orElse: () => {});
                    _clientName = home['name'] ?? '';
                    _clientAddress = home['address'];
                    _clientEmail = home['email'];
                  });
                },
              ),
            if (_selectedClientType == 'council' && _councils.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Council', border: OutlineInputBorder()),
                value: _selectedClientId,
                items: _councils.map((co) => DropdownMenuItem(value: co['id']?.toString(), child: Text(co['name'] ?? 'Unknown'))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedClientId = v;
                    final council = _councils.firstWhere((co) => co['id']?.toString() == v, orElse: () => {});
                    _clientName = council['name'] ?? '';
                    _clientAddress = council['address'];
                    _clientEmail = council['email'];
                  });
                },
              ),
            if (_selectedClientType == 'other' || _selectedClientType == null)
              TextFormField(
                decoration: const InputDecoration(labelText: 'Client Name *', border: OutlineInputBorder()),
                initialValue: _clientName,
                onChanged: (v) => setState(() => _clientName = v),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Client Address', border: OutlineInputBorder()),
              initialValue: _clientAddress,
              onChanged: (v) => setState(() => _clientAddress = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Client Email', border: OutlineInputBorder()),
              initialValue: _clientEmail,
              onChanged: (v) => setState(() => _clientEmail = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: _periodStart, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (date != null) setState(() => _periodStart = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Period Start', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd/MM/yyyy').format(_periodStart)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: _periodEnd, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (date != null) setState(() => _periodEnd = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Period End', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd/MM/yyyy').format(_periodEnd)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: _invoiceDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (date != null) setState(() => _invoiceDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Invoice Date', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd/MM/yyyy').format(_invoiceDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (date != null) setState(() => _dueDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Line Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(onPressed: _addLineItem, icon: const Icon(Icons.add), label: const Text('Add Item')),
              ],
            ),
            const SizedBox(height: 12),
            if (_lineItems.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('No line items added', style: TextStyle(color: Colors.grey)))
            else
              ..._lineItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                          initialValue: item['description']?.toString(),
                          onChanged: (v) => _updateLineItem(index, 'description', v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                          initialValue: item['quantity']?.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _updateLineItem(index, 'quantity', int.tryParse(v) ?? 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Unit Price', border: OutlineInputBorder()),
                          initialValue: item['unit_price']?.toString(),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => _updateLineItem(index, 'unit_price', double.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text('£${(item['total'] as double? ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      IconButton(onPressed: () => _removeLineItem(index), icon: const Icon(Icons.delete, color: Colors.red)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _notesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notes & Terms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), alignLabelWithHint: true),
              initialValue: _notes,
              maxLines: 3,
              onChanged: (v) => setState(() => _notes = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Payment Terms', border: OutlineInputBorder()),
              initialValue: _terms,
              onChanged: (v) => setState(() => _terms = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsSummary() {
    final subtotal = _lineItems.fold<double>(0, (sum, item) => sum + ((item['total'] as double?) ?? 0));
    final taxRate = _orgProfile?.taxRate ?? 20.0;
    final taxAmount = subtotal * taxRate / 100;
    final totalAmount = subtotal + taxAmount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _totalRow('Subtotal', subtotal),
            _totalRow('Tax ($taxRate%)', taxAmount),
            const Divider(),
            _totalRow('Total', totalAmount, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
          const SizedBox(width: 16),
          Text('£${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _saveInvoice(status: 'draft'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
            child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save as Draft', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _saveInvoice(status: 'sent'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save & Send', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class InvoicePDFGenerator {
  Future<Uint8List> generateInvoicePDF(Invoice invoice, OrganisationProfile profile) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(profile.legalName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      if (profile.addressLine1 != null) pw.Text(profile.addressLine1!),
                      if (profile.city != null) pw.Text(profile.city!),
                      if (profile.postcode != null) pw.Text(profile.postcode!),
                      if (profile.phone != null) pw.Text('Phone: ${profile.phone}'),
                      if (profile.email != null) pw.Text('Email: ${profile.email}'),
                      if (profile.vatNumber != null) pw.Text('VAT: ${profile.vatNumber}'),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Invoice No: ${invoice.invoiceNumber}'),
                    pw.Text('Date: ${_formatDate(invoice.invoiceDate)}'),
                    pw.Text('Due Date: ${_formatDate(invoice.dueDate)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.clientName),
                      if (invoice.clientAddress != null) pw.Text(invoice.clientAddress!),
                      if (invoice.clientReference != null) pw.Text('Ref: ${invoice.clientReference}'),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Period: ${_formatDate(invoice.periodStart)} - ${_formatDate(invoice.periodEnd)}'),
                      pw.Text('Terms: ${invoice.terms ?? profile.invoiceTerms}'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
                ...invoice.lineItems.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(item['description'] ?? '')),
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text((item['quantity'] ?? 1).toString(), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('£${(item['unit_price'] ?? 0).toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('£${(item['total'] ?? 0).toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: £${invoice.subtotal.toStringAsFixed(2)}'),
                    pw.Text('Tax (${invoice.taxRate}%): £${invoice.taxAmount.toStringAsFixed(2)}'),
                    pw.Divider(),
                    pw.Text('Total: £${invoice.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
            if (invoice.notes != null) ...[
              pw.SizedBox(height: 20),
              pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.notes!),
            ],
            pw.SizedBox(height: 20),
            pw.Text('Payment Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Bank: ${profile.bankName ?? ''}'),
            pw.Text('Account Name: ${profile.bankAccountName ?? ''}'),
            pw.Text('Sort Code: ${profile.bankSortCode ?? ''}'),
            pw.Text('Account No: ${profile.bankAccountNumber ?? ''}'),
            pw.Text('Reference: ${invoice.invoiceNumber}'),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}