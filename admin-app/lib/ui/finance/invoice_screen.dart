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

  // Billing rate - pulled from client_organisation.billing_rate_per_hour,
  // editable and used by auto-calculate hours.
  final _hourlyRateController = TextEditingController(text: '20.00');
  double _selectedClientRate = 20.0;

  // Billing accuracy - only bill completed (or optionally confirmed) shifts
  // that are assigned to a carer AND signed off on the digital timesheet.
  bool _includeConfirmed = false; // "billing in advance" mode

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

  // Clients data - unified billable clients (service users + care homes/factories/warehouses)
  List<Map<String, dynamic>> _serviceUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await _service.getOrganisationProfile();
      setState(() => _orgProfile = profile);

      // Load each source independently so one failure doesn't blank the whole list.
      final merged = <Map<String, dynamic>>[];

      // 1. Service users (individual billable clients)
      try {
        final su = await Supabase.instance.client.from('service_users')
            .select('id, name, address, email')
            .order('name');
        for (final u in (su as List).cast<Map<String, dynamic>>()) {
          merged.add({
            'id': u['id'],
            'name': u['name'],
            'address': u['address'],
            'email': u['email'],
            'client_type': 'service_user',
            'rate': null, // no per-user rate; defaults used
          });
        }
      } catch (_) {
        // Ignore - service_users may be empty or RLS-restricted
      }

      // 2. Client organisations (care homes / factories / warehouses / hospitals)
      //    NOTE: schema drift — migration 129 inserts via organisation_types / email,
      //    migration 029 used type / contact_email. Use SELECT * defensively.
      try {
        final clients = await Supabase.instance.client.from('client_organisations')
            .select('*')
            .eq('is_active', true)
            .order('name');
        for (final c in (clients as List).cast<Map<String, dynamic>>()) {
          // Resolve type from either schema (organisation_types JSONB array OR type text)
          String clientType = 'other';
          final t = c['organisation_types'] ?? c['type'];
          if (t is List && t.isNotEmpty) {
            clientType = t.first.toString();
          } else if (t is String && t.isNotEmpty) {
            clientType = t;
          }
          merged.add({
            'id': c['id'],
            'name': c['name'],
            'address': c['address'],
            'email': (c['email'] ?? c['contact_email'])?.toString(),
            'client_type': clientType, // care_home / warehouse / hospital / other
            'rate': (c['billing_rate_per_hour'] as num?)?.toDouble() ?? 20.0,
          });
        }
      } catch (_) {
        // If client_organisations RLS blocks (missing helper functions), skip
      }

      merged.sort((a, b) => (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase()));

      setState(() {
        _serviceUsers = merged;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Auto-calculates billable hours for the selected client within the date range.
  /// Reads from public.shifts (completed) and public.route_visits.
  Future<void> _autoCalculateHours() async {
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client first'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    try {
      final clientId = _selectedClientId; // local non-nullable copy
      if (clientId == null) {
        setState(() => _saving = false);
        return;
      }
      final start = _periodStart.toIso8601String().split('T').first;
      final end = _periodEnd.toIso8601String().split('T').first;

      // Determine filter mode based on selected client type and pull the rate
      final selected = _serviceUsers.firstWhere(
        (u) => u['id']?.toString() == clientId,
        orElse: () => {},
      );
      final clientType = (selected['client_type'] as String?) ?? 'service_user';
      final clientRate = (selected['rate'] as double?) ?? 20.0;
      // Allow admin to override the rate on screen (falls back to client's stored rate)
      final rate = double.tryParse(_hourlyRateController.text.trim()) ?? clientRate;
      setState(() => _selectedClientRate = rate);

      // Build the shift + route_visit queries
      // Shift query joins the digital timesheet (`visits`) so we can verify
      // sign-off / dispute status exactly as the invoice-accuracy rules require.
      var shiftQuery = Supabase.instance.client.from('shifts')
          .select('*, service_users(name), carers(name), visits(sign_off_status, disputed, check_in_time, check_out_time)')
          .not('carer_id', 'is', null); // must be assigned to a carer
      var visitQuery = Supabase.instance.client.from('route_visits')
          .select('*, routes(name), service_users(name)');

      if (clientType == 'service_user') {
        // Bill the individual service user
        shiftQuery = shiftQuery.eq('service_user_id', clientId);
        visitQuery = visitQuery.eq('service_user_id', clientId);
      } else {
        // Bill the client organisation (care home/factory/warehouse) -
        // match shifts and visits that carry the client_organisation_id
        shiftQuery = shiftQuery.eq('client_organisation_id', clientId);
        visitQuery = visitQuery.eq('client_organisation_id', clientId);
      }

      // Status strategy - only billable statuses. Default = completed only.
      // Optionally include confirmed for in-advance billing.
      final statuses = _includeConfirmed
          ? ['completed', 'confirmed']
          : ['completed'];
      final shifts = await shiftQuery
          .inFilter('status', statuses)
          .gte('scheduled_date', start)
          .lte('scheduled_date', end);

      // Route visits for this client
      final routeVisits = await visitQuery
          .not('status', 'eq', 'cancelled')
          .gte('visit_date', start)
          .lte('visit_date', end);

      final lineItems = <Map<String, dynamic>>[];

      // ── Process shifts (with invoice-accuracy rules) ──
      for (final s in (shifts as List).cast<Map<String, dynamic>>()) {
        final status = (s['status'] as String?) ?? '';
        final carerId = s['carer_id'] as String?;

        // Rule: must be assigned to a carer.
        if (carerId == null || carerId.isEmpty) continue;

        // For completed shifts the care home must have signed off the digital
        // timesheet: a visit with check_in_time present, not disputed,
        // and not voided/delined.
        if (status == 'completed') {
          final visits = (s['visits'] as List?) ?? [];
          bool signedOff = false;
          for (final v in visits.cast<Map<String, dynamic>>()) {
            final checkIn = v['check_in_time'];
            final disputed = v['disputed'] == true;
            final signOff = (v['sign_off_status'] as String?) ?? 'pending';
            if (checkIn != null && !disputed &&
                signOff != 'voided' && signOff != 'disputed') {
              signedOff = true;
              break;
            }
          }
          if (!signedOff) continue; // NOT signed off → exclude from invoice
        }

        // Compute hours: prefer actual clocked visit times when available,
        // fall back to the scheduled shift window.
        double hours = 0;
        String window = '';
        if (status == 'completed') {
          final visits = (s['visits'] as List?) ?? [];
          double? actualMinutes;
          for (final v in visits.cast<Map<String, dynamic>>()) {
            final inT = DateTime.tryParse(v['check_in_time']?.toString() ?? '');
            final outT = DateTime.tryParse(v['check_out_time']?.toString() ?? '');
            if (inT != null && outT != null && outT.isAfter(inT)) {
              final m = outT.difference(inT).inMinutes;
              actualMinutes = (actualMinutes ?? 0) + m;
            }
          }
          if (actualMinutes != null && actualMinutes! > 0) {
            hours = actualMinutes / 60.0;
            window = ' (clocked ${hours.toStringAsFixed(2)}h)';
          }
        }
        if (hours == 0) {
          final startTime = s['start_time'] as String? ?? '';
          final endTime = s['end_time'] as String? ?? '';
          hours = _calculateHours(startTime, endTime);
          window = ' ($startTime-$endTime)';
        }

        final suName = (s['service_users'] as Map<String, dynamic>?)?['name'] ?? 'SU';
        final carerName = (s['carers'] as Map<String, dynamic>?)?['name'] ?? 'Staff';
        lineItems.add({
          'description': 'Shift - ${s['scheduled_date']}$window - $suName ($carerName)',
          'quantity': 1,
          'unit_price': rate, // per-hour rate from care home / override
          'total': hours * rate,
          'hours': hours,
          'type': 'shift',
          'source_id': s['id'],
        });
      }

      // Process route visits
      for (final rv in (routeVisits as List).cast<Map<String, dynamic>>()) {
        final minutes = (rv['duration_minutes'] as num?)?.toDouble() ?? 60.0;
        final hours = minutes / 60.0;
        final routeName = (rv['routes'] as Map<String, dynamic>?)?['name'] ?? 'Route';
        final suName = (rv['service_users'] as Map<String, dynamic>?)?['name'] ?? 'SU';
        lineItems.add({
          'description': 'Route call - ${rv['visit_date']} - ${routeName} - $suName',
          'quantity': 1,
          'unit_price': rate,
          'total': hours * rate,
          'hours': hours,
          'type': 'route_visit',
          'source_id': rv['id'],
        });
      }

      if (lineItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No billed shifts or route visits found for this period'), backgroundColor: Colors.orange));
        }
        setState(() => _saving = false);
        return;
      }

      // Add a summary row
      final totalHours = lineItems.fold<double>(0, (sum, item) => sum + ((item['hours'] as double?) ?? 0));
      final totalAmount = lineItems.fold<double>(0, (sum, item) => sum + ((item['total'] as double?) ?? 0));
      lineItems.add({
        'description': 'Total - ${lineItems.length} entries, ${totalHours.toStringAsFixed(1)} hours @ £${rate.toStringAsFixed(2)}/hr',
        'quantity': 1,
        'unit_price': totalAmount,
        'total': totalAmount,
        'hours': totalHours,
        'type': 'summary',
      });

      setState(() {
        _lineItems = lineItems;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calculated ${lineItems.length - 1} entries (${totalHours.toStringAsFixed(1)} hours)'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  double _calculateHours(String startTime, String endTime) {
    try {
      final start = startTime.split(':');
      final end = endTime.split(':');
      if (start.length < 2 || end.length < 2) return 1.0;
      final startH = int.tryParse(start[0]) ?? 0;
      final startM = int.tryParse(start[1]) ?? 0;
      final endH = int.tryParse(end[0]) ?? 0;
      final endM = int.tryParse(end[1]) ?? 0;
      final totalMinutes = (endH * 60 + endM) - (startH * 60 + startM);
      return totalMinutes > 0 ? totalMinutes / 60.0 : 1.0;
    } catch (_) {
      return 1.0;
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
            const Text('Billable Client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Unified client dropdown - all billable service users / care homes
            if (_serviceUsers.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Client *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                value: _selectedClientId,
                items: _serviceUsers.map((su) {
                  final clientType = su['client_type'] ?? 'service_user';
                  String label = su['name'] ?? 'Unknown';
                  switch (clientType) {
                    case 'care_home': label = '🏠 $label (Care Home)'; break;
                    case 'warehouse': label = '🏭 $label (Warehouse)'; break;
                    case 'hospital': label = '🏥 $label (Hospital)'; break;
                    case 'council': label = '🏛 $label (Council)'; break;
                    default: break;
                  }
                  return DropdownMenuItem(
                    value: su['id']?.toString(),
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final user = _serviceUsers.firstWhere((u) => u['id']?.toString() == v, orElse: () => {});
                  final clientRate = (user['rate'] as num?)?.toDouble() ?? 20.0;
                  setState(() {
                    _selectedClientId = v;
                    _selectedClientType = (user['client_type'] as String?) ?? 'service_user';
                    _clientName = user['name'] ?? '';
                    _clientAddress = user['address'];
                    _clientEmail = user['email'];
                    _selectedClientRate = clientRate;
                    _hourlyRateController.text = clientRate.toStringAsFixed(2);
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              )
            else
              const Center(child: Text('No billable clients found', style: TextStyle(color: Colors.grey))),
            const SizedBox(height: 12),
            if (_selectedClientId != null) ...[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Client Name *', border: OutlineInputBorder()),
                initialValue: _clientName,
                onChanged: (v) => setState(() => _clientName = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Client Address', border: OutlineInputBorder()),
                initialValue: _clientAddress ?? '',
                onChanged: (v) => setState(() => _clientAddress = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Client Email', border: OutlineInputBorder()),
                initialValue: _clientEmail ?? '',
                onChanged: (v) => setState(() => _clientEmail = v),
              ),
              const SizedBox(height: 12),
              // Hourly rate - pulled from care home's billing_rate_per_hour,
              // editable so admin can override per invoice.
              TextFormField(
                controller: _hourlyRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (£ per hour)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                ),
                onChanged: (v) {
                  final r = double.tryParse(v.trim());
                  if (r != null) setState(() => _selectedClientRate = r);
                },
              ),
              const SizedBox(height: 12),
              // Auto-calculate hours
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _autoCalculateHours,
                  icon: const Icon(Icons.calculate),
                  label: Text(_saving ? 'Calculating…' : 'Auto-Calculate Hours for Selected Period'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              // In-advance billing toggle (confirmed shifts)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Include confirmed shifts (billing in advance)',
                    style: TextStyle(fontSize: 13)),
                subtitle: const Text('Unticked = only completed + signed-off shifts',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                value: _includeConfirmed,
                onChanged: (v) => setState(() => _includeConfirmed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 4),
              // Accuracy explanation
              Text(
                'Only shifts that are assigned to a carer and signed off on the digital '
                'timesheet (check-in recorded, not disputed/voided) are invoiced.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
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