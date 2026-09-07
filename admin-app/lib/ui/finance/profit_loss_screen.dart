import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../services/expense_tracking_service.dart';

// -------- Period Helper ----------
class _Period {
  final String label;
  final DateTime start;
  final DateTime end;
  const _Period(this.label, this.start, this.end);
}

// -------- P&L Data ----------
class _PnLData {
  final double revenueDomCare;
  final int domCareVisitCount;
  final double revenueAgency;
  final int agencyPlacementCount;
  final double revenueOther;
  final double totalExpenses;
  final Map<String, double> expensesByCategory;
  final List<_RouteSummary> routes;
  final List<Map<String, dynamic>> recentReceipts;
  final double prevRevenue;
  final double prevExpenses;
  _PnLData({
    this.revenueDomCare = 0,
    this.domCareVisitCount = 0,
    this.revenueAgency = 0,
    this.agencyPlacementCount = 0,
    this.revenueOther = 0,
    this.totalExpenses = 0,
    this.expensesByCategory = const {},
    this.routes = const [],
    this.recentReceipts = const [],
    this.prevRevenue = 0,
    this.prevExpenses = 0,
  });
  double get totalRevenue => revenueDomCare + revenueAgency + revenueOther;
  double get profit => totalRevenue - totalExpenses;
  double get margin => totalRevenue > 0 ? profit / totalRevenue * 100 : 0;
}

class _RouteSummary {
  final String name;
  final double revenue;
  final double expenses;
  final int visits;
  _RouteSummary(this.name, this.revenue, this.expenses, this.visits);
  double get profit => revenue - expenses;
  double get margin => revenue > 0 ? profit / revenue * 100 : 0;
  double get profitPerVisit => visits > 0 ? profit / visits : 0;
}

// -------- Colors & Helpers ----------
const _primary = Color(0xFF1565C0);
final _format = NumberFormat('#,##0.00', 'en_GB');

String _fmt(double v) => '£${_format.format(v)}';
String _pct(double v) => '${v.toStringAsFixed(1)}%';

final _expenseColors = <String, Color>{
  'wages': Colors.red.shade600,
  'fuel': Colors.orange,
  'ppe': Colors.teal,
  'uniforms': Colors.indigo,
  'training': Colors.purple,
  'vehicle_maintenance': Colors.brown,
  'insurance': Colors.blueGrey,
  'rent': Colors.pink,
  'utilities': Colors.cyan,
  'marketing': Colors.deepOrange,
  'office_supplies': Colors.deepPurple,
  'equipment': Colors.lightGreen,
  'cleaning': Colors.lime,
  'food': Colors.amber,
  'staff': Colors.deepPurple.shade300,
  'administration': Colors.grey,
  'other': Colors.grey.shade400,
};

String _catDisplay(String k) => ExpenseTrackingService.getExpenseCategoryDisplay(k);

// -------- Main Screen ----------
class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  _Period _period = _monthPeriod(DateTime.now());
  _Period? _prevPeriod;
  bool _compare = false;
  _PnLData _data = _PnLData();
  Set<String> _processedStaffIds = {}; // avoids double-counting wages

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  static _Period _monthPeriod(DateTime d) => _Period(
    DateFormat('MMM yyyy').format(d),
    DateTime(d.year, d.month, 1),
    DateTime(d.year, d.month + 1, 0),
  );

  List<_Period> _quickPeriods() {
    final n = DateTime.now();
    return [
      _Period('Today', n, n),
      _Period('This Week', n.subtract(Duration(days: n.weekday - 1)), n),
      _Period('This Month', DateTime(n.year, n.month, 1), n),
      _Period('This Quarter', DateTime(n.year, (n.month - 1) ~/ 3 * 3 + 1, 1), n),
      _Period('This Year', DateTime(n.year, 1, 1), n),
    ];
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final s = _period.start.toIso8601String().split('T')[0];
      final e = _period.end.toIso8601String().split('T')[0];

      // ── REVENUE: from paid invoices ──
      double revenueDomCare = 0;
      int domCareCount = 0;
      // Completed shifts (Dom Care visits billed as work)
      try {
        final shifts = await _supabase.from('shifts')
            .select('start_time, end_time')
            .eq('status', 'completed')
            .gte('scheduled_date', s)
            .lte('scheduled_date', e);
        for (final sh in (shifts as List).cast<Map<String, dynamic>>()) {
          revenueDomCare += _shiftHours(sh['start_time'] ?? '', sh['end_time'] ?? '') * 20.0;
          domCareCount++;
        }
      } catch (_) {}
      // Route visits
      try {
        final rv = await _supabase.from('route_visits')
            .select('duration_minutes').gte('visit_date', s).lte('visit_date', e);
        for (final v in (rv as List).cast<Map<String, dynamic>>()) {
          final mins = (v['duration_minutes'] as num?)?.toDouble() ?? 60.0;
          revenueDomCare += (mins / 60.0) * 20.0;
          domCareCount++;
        }
      } catch (_) {}
      // Paid invoices in this period
      double revenueAgency = 0;
      try {
        final inv = await _supabase.from('invoices')
            .select('total_amount').eq('status', 'paid')
            .gte('period_end', s).lte('period_end', e);
        for (final i in (inv as List)) {
          revenueAgency += ((i['total_amount'] as num?)?.toDouble() ?? 0);
        }
      } catch (_) {}

      // Expenses from receipts
      final expByCat = <String, double>{};
      double totalExp = 0;
      try {
        final receipts = await _supabase.from('receipt_entries')
            .select('total_amount, expense_category')
            .gte('receipt_date', s).lte('receipt_date', e);
        for (final r in (receipts as List).cast<Map<String, dynamic>>()) {
          final amt = (r['total_amount'] as num?)?.toDouble() ?? 0;
          totalExp += amt;
          final cat = r['expense_category'] as String? ?? 'other';
          expByCat[cat] = (expByCat[cat] ?? 0) + amt;
        }
      } catch (_) {}
      try {
        final pay = await _supabase.from('payroll_history')
            .select('staff_id, regular_pay, overtime_pay, holiday_pay, sick_pay, bonus_pay, deductions, period_start')
            .gte('period_start', s).lte('period_end', e);
        double payFromPayroll = 0;
        final paidStaffIds = <String>{};
        for (final p in (pay as List).cast<Map<String, dynamic>>()) {
          final rp = (p['regular_pay'] as num?)?.toDouble() ?? 0;
          final op = (p['overtime_pay'] as num?)?.toDouble() ?? 0;
          final hp = (p['holiday_pay'] as num?)?.toDouble() ?? 0;
          final sp = (p['sick_pay'] as num?)?.toDouble() ?? 0;
          final bp = (p['bonus_pay'] as num?)?.toDouble() ?? 0;
          final ded = (p['deductions'] as num?)?.toDouble() ?? 0;
          final total = rp + op + hp + sp + bp - ded;
          payFromPayroll += total;
          final sid = p['staff_id'] as String?;
          if (sid != null) paidStaffIds.add(sid);
        }
        totalExp += payFromPayroll;
        expByCat['wages'] = (expByCat['wages'] ?? 0) + payFromPayroll;
        _processedStaffIds = paidStaffIds;
      } catch (_) {}

      // Estimate unprocessed wages from completed shifts (carers who haven't
      // had payroll run yet). Reads the carer's last known hourly_rate from
      // payroll_history; falls back to £11.44/hr (UK National Living Wage 2024).
      try {
        final estWages = await _supabase.from('shifts')
            .select('carer_id, start_time, end_time')
            .eq('status', 'completed')
            .not('carer_id', 'is', null)
            .gte('scheduled_date', s).lte('scheduled_date', e);
        double estimatedWages = 0;
        // Cache rates per carer so we only look up once
        final Map<String, double> carerRates = {};
        for (final sh in (estWages as List).cast<Map<String, dynamic>>()) {
          final carerId = sh['carer_id'] as String?;
          if (carerId == null || _processedStaffIds.contains(carerId)) continue;
          // Look up this carer's last known rate (cache it)
          double rate = carerRates[carerId] ?? 11.44;
          if (!carerRates.containsKey(carerId)) {
            try {
              final lastPay = await _supabase.from('payroll_history')
                  .select('hourly_rate').eq('staff_id', carerId)
                  .order('period_end', ascending: false).limit(1).maybeSingle();
              if (lastPay != null) {
                rate = ((lastPay['hourly_rate'] as num?)?.toDouble() ?? 11.44);
              }
            } catch (_) {}
            carerRates[carerId] = rate;
          }
          final hours = _shiftHours(sh['start_time'] ?? '', sh['end_time'] ?? '');
          estimatedWages += hours * rate;
        }
        if (estimatedWages > 0) {
          totalExp += estimatedWages;
          expByCat['wages'] = (expByCat['wages'] ?? 0) + estimatedWages;
        }
      } catch (_) {}

      // Routes
      final routes = await _supabase.from('routes').select('id, name');
      final routeList = routes as List;
      final routeSummaries = <_RouteSummary>[];
      for (final r in routeList) {
        final rid = r['id'] as String;
        final rname = r['name'] as String;
        double rRev = 0; int rVisCt = 0;
        try {
          final rv = await _supabase.from('route_visits')
              .select('duration_minutes').eq('route_id', rid)
              .gte('visit_date', s).lte('visit_date', e);
          for (final v in (rv as List).cast<Map<String, dynamic>>()) {
            final mins = (v['duration_minutes'] as num?)?.toDouble() ?? 60;
            rRev += (mins / 60) * 20; rVisCt++;
          }
        } catch (_) {}
        double rExp = 0;
        try {
          final re = await _supabase.from('receipt_entries')
              .select('total_amount').eq('route_id', rid)
              .gte('receipt_date', s).lte('receipt_date', e);
          for (final e2 in (re as List).cast<Map<String, dynamic>>()) {
            rExp += (e2['total_amount'] as num?)?.toDouble() ?? 0;
          }
        } catch (_) {}
        if (rVisCt > 0 || rExp > 0) routeSummaries.add(_RouteSummary(rname, rRev, rExp, rVisCt));
      }

      // Previous period
      double prevRev = 0, prevExp = 0;
      if (_compare && _prevPeriod != null) {
        final ps = _prevPeriod!.start.toIso8601String().split('T')[0];
        final pe = _prevPeriod!.end.toIso8601String().split('T')[0];
        final pi = await _supabase.from('invoices')
            .select('total_amount').eq('status', 'paid')
            .gte('period_end', ps).lte('period_end', pe);
        for (final i in (pi as List)) {
          prevRev += ((i['total_amount'] as num?)?.toDouble() ?? 0);
        }
        try {
          final pr = await _supabase.from('receipt_entries')
              .select('total_amount')
              .gte('receipt_date', ps).lte('receipt_date', pe);
          for (final r in (pr as List).cast<Map<String, dynamic>>()) {
            prevExp += ((r['total_amount'] as num?)?.toDouble() ?? 0);
          }
        } catch (_) {}
      }

      setState(() {
        _data = _PnLData(
          revenueDomCare: revenueDomCare,
          domCareVisitCount: domCareCount,
          revenueAgency: revenueAgency,
          agencyPlacementCount: 0,
          totalExpenses: totalExp,
          expensesByCategory: expByCat,
          routes: routeSummaries, recentReceipts: [],
          prevRevenue: prevRev,
          prevExpenses: prevExp,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  double _shiftHours(String startTime, String endTime) {
    try {
      final s = startTime.split(':'), e = endTime.split(':');
      if (s.length < 2 || e.length < 2) return 1.0;
      final sm = (int.tryParse(s[0]) ?? 0) * 60 + (int.tryParse(s[1]) ?? 0);
      final em = (int.tryParse(e[0]) ?? 0) * 60 + (int.tryParse(e[1]) ?? 0);
      final diff = em - sm;
      return diff > 0 ? diff / 60.0 : 1.0;
    } catch (_) { return 1.0; }
  }

  void _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _period.start, end: _period.end),
    );
    if (picked != null) {
      setState(() {
        _period = _Period(
          '${DateFormat('dd/MM').format(picked.start)} - ${DateFormat('dd/MM/yy').format(picked.end)}',
          picked.start, picked.end,
        );
      });
      _fetch();
    }
  }

  void _selectQuickPeriod(_Period p) {
    setState(() {
      _period = p;
      _prevPeriod = _Period('Prev', DateTime(p.start.year, p.start.month - 1, p.start.day), p.start.subtract(const Duration(days: 1)));
    });
    _fetch();
  }

  String _changeLabel(double current, double previous) {
    if (previous == 0) return '—';
    final pct = ((current - previous) / previous * 100).abs();
    return '${current >= previous ? '+' : '-'}$pct% vs prev';
  }

  Color _changeColor(double current, double previous, {bool reverse = false}) {
    if (previous == 0) return Colors.grey;
    final up = current >= previous;
    if (reverse) return up ? Colors.red : Colors.green;
    return up ? Colors.green : Colors.red;
  }

  // ---------- PDF Export ----------
  Future<void> _exportPdf() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text('Profit & Loss Statement', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text('${DateFormat('dd/MM/yyyy').format(_period.start)} - ${DateFormat('dd/MM/yyyy').format(_period.end)}')),
        pw.SizedBox(height: 16),
        pw.Text('Revenue: ${_fmt(_data.totalRevenue)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Expenses: ${_fmt(_data.totalExpenses)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Profit: ${_fmt(_data.profit)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _data.profit >= 0 ? PdfColors.green : PdfColors.red)),
        pw.Text('Margin: ${_pct(_data.margin)}'),
        pw.SizedBox(height: 12),
        pw.Text('Revenue Breakdown:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('  Dom Care Visits: ${_fmt(_data.revenueDomCare)} (${_data.domCareVisitCount} visits)'),
        pw.Text('  Agency Placements: ${_fmt(_data.revenueAgency)} (${_data.agencyPlacementCount} placements)'),
        pw.SizedBox(height: 12),
        pw.Text('Expenses by Category:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ..._data.expensesByCategory.entries.map((e) => pw.Text('  ${_catDisplay(e.key)}: ${_fmt(e.value)}')),
      ])));
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/profit_loss_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Profit & Loss Report');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
    }
  }

  Future<void> _exportCsv() async {
    try {
      final buf = StringBuffer();
      buf.writeln('Profit & Loss - ${DateFormat('dd/MM/yyyy').format(_period.start)} to ${DateFormat('dd/MM/yyyy').format(_period.end)}');
      buf.writeln();
      buf.writeln('Revenue');
      buf.writeln('Dom Care Visits,${_fmt(_data.revenueDomCare)},$_period.start');
      buf.writeln('Revenue/Visit,${_data.domCareVisitCount > 0 ? _fmt(_data.revenueDomCare / _data.domCareVisitCount) : '\u00a30.00'}');
      buf.writeln('Agency Placements,${_fmt(_data.revenueAgency)}');
      buf.writeln('Total Revenue,${_fmt(_data.totalRevenue)}');
      buf.writeln();
      buf.writeln('Expenses');
      for (final e in _data.expensesByCategory.entries) {
        buf.writeln('${_catDisplay(e.key)},${_fmt(e.value)}');
      }
      buf.writeln('Total Expenses,${_fmt(_data.totalExpenses)}');
      buf.writeln();
      buf.writeln('Net Profit,${_fmt(_data.profit)}');
      buf.writeln('Profit Margin,${_pct(_data.margin)}');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/profit_loss_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Profit & Loss Data');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
    }
  }

  Future<void> _printReport() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (ctx) => pw.Center(child: pw.Text('Print report - use Export PDF'))));
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (_) {}
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'pdf') _exportPdf();
              if (v == 'csv') _exportCsv();
              if (v == 'print') _printReport();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('Export PDF'))),
              PopupMenuItem(value: 'csv', child: ListTile(leading: Icon(Icons.table_chart), title: Text('Export CSV'))),
              PopupMenuItem(value: 'print', child: ListTile(leading: Icon(Icons.print), title: Text('Print'))),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _periodSelector(),
                  const SizedBox(height: 12),
                  if (_compare && _prevPeriod != null) _compareBar(),
                  if (_compare && _prevPeriod != null) const SizedBox(height: 12),
                  _summaryRow(),
                  const SizedBox(height: 16),
                  _incomeSection(),
                  const SizedBox(height: 16),
                  _expenseSection(),
                  const SizedBox(height: 16),
                  if (_data.routes.isNotEmpty) ...[
                    _routeSection(),
                    const SizedBox(height: 16),
                  ],
                  _chartSection(),
                ],
              ),
            ),
    );
  }

  Widget _periodSelector() {
    final q = _quickPeriods();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, size: 18, color: _primary),
                const SizedBox(width: 8),
                Expanded(child: Text(_period.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Switch(
                  value: _compare,
                  onChanged: (v) {
                    setState(() {
                      _compare = v;
                      if (v && _prevPeriod == null) {
                        _prevPeriod = _Period('Prev',
                          DateTime(_period.start.year, _period.start.month - 1, _period.start.day),
                          _period.start.subtract(const Duration(days: 1)));
                      }
                    });
                    _fetch();
                  },
                  activeColor: _primary,
                ),
                Text('Compare', style: TextStyle(fontSize: 12, color: _compare ? _primary : Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in q)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.label, style: const TextStyle(fontSize: 12)),
                        selected: p.start == _period.start && p.end == _period.end,
                        onSelected: (_) => _selectQuickPeriod(p),
                        selectedColor: _primary,
                        labelStyle: TextStyle(color: p.start == _period.start && p.end == _period.end ? Colors.white : null),
                      ),
                    ),
                  ChoiceChip(
                    label: const Text('Custom', style: TextStyle(fontSize: 12)),
                    selected: false,
                    onSelected: (_) => _pickCustom(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compareBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Text('vs ${_prevPeriod!.label}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 16),
          Text('Rev: ${_changeLabel(_data.totalRevenue, _data.prevRevenue)}',
            style: TextStyle(fontSize: 12, color: _changeColor(_data.totalRevenue, _data.prevRevenue))),
          const SizedBox(width: 12),
          Text('Exp: ${_changeLabel(_data.totalExpenses, _data.prevExpenses)}',
            style: TextStyle(fontSize: 12, color: _changeColor(_data.totalExpenses, _data.prevExpenses, reverse: true))),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    final d = _data;
    return Row(
      children: [
        Expanded(child: _metric('Revenue', _fmt(d.totalRevenue), Colors.green, d.prevRevenue > 0 ? _changeLabel(d.totalRevenue, d.prevRevenue) : null, d.prevRevenue > 0 ? _changeColor(d.totalRevenue, d.prevRevenue) : null)),
        const SizedBox(width: 8),
        Expanded(child: _metric('Expenses', _fmt(d.totalExpenses), Colors.red, d.prevExpenses > 0 ? _changeLabel(d.totalExpenses, d.prevExpenses) : null, d.prevExpenses > 0 ? _changeColor(d.totalExpenses, d.prevExpenses, reverse: true) : null)),
        const SizedBox(width: 8),
        Expanded(child: _metric('Profit', _fmt(d.profit), d.profit >= 0 ? Colors.green : Colors.red, null, null)),
        const SizedBox(width: 8),
        Expanded(child: _metric('Margin', _pct(d.margin), d.margin >= 0 ? Colors.green : Colors.red, null, null)),
      ],
    );
  }

  Widget _metric(String label, String value, Color color, String? change, Color? changeColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            if (change != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(change, style: TextStyle(fontSize: 9, color: changeColor ?? Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _incomeSection() {
    final d = _data;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text('Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                const Spacer(),
                Text(_fmt(d.totalRevenue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            _incomeRow('Dom Care Visits', _fmt(d.revenueDomCare), '${d.domCareVisitCount} visits'),
            _incomeRow('Agency Placements', _fmt(d.revenueAgency), '${d.agencyPlacementCount} placements'),
            _incomeRow('Other Income', _fmt(d.revenueOther), ''),
          ],
        ),
      ),
    );
  }

  Widget _incomeRow(String label, String amount, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _expenseSection() {
    final d = _data;
    final sorted = d.expensesByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_down, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                const Spacer(),
                Text(_fmt(d.totalExpenses), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            for (final e in sorted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _expenseColors[e.key] ?? Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_catDisplay(e.key), style: const TextStyle(fontSize: 14))),
                    Text(_fmt(e.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(width: 40, child: Text(
                      d.totalExpenses > 0 ? '${(e.value / d.totalExpenses * 100).toStringAsFixed(1)}%' : '',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    )),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: d.totalExpenses > 0 ? (e.value / d.totalExpenses) : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_expenseColors[e.key] ?? Colors.grey),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeSection() {
    final d = _data.routes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.route, color: _primary, size: 20),
                SizedBox(width: 8),
                Text('Route Profitability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            DataTable(
              columnSpacing: 8,
              headingRowHeight: 32,
              dataRowMinHeight: 28,
              columns: const [
                DataColumn(label: Text('Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
                DataColumn(label: Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
                DataColumn(label: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
                DataColumn(label: Text('Margin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
                DataColumn(label: Text('Visits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
                DataColumn(label: Text('/Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
              ],
              rows: d.map((r) => DataRow(cells: [
                DataCell(Text(r.name, style: const TextStyle(fontSize: 11))),
                DataCell(Text(_fmt(r.revenue), style: const TextStyle(fontSize: 11))),
                DataCell(Text(_fmt(r.expenses), style: const TextStyle(fontSize: 11))),
                DataCell(Text(_fmt(r.profit), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: r.profit >= 0 ? Colors.green : Colors.red))),
                DataCell(Text(_pct(r.margin), style: TextStyle(fontSize: 11, color: r.margin >= 0 ? Colors.green : Colors.red))),
                DataCell(Text('${r.visits}', style: const TextStyle(fontSize: 11))),
                DataCell(Text(_fmt(r.profitPerVisit), style: const TextStyle(fontSize: 11))),
              ])).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartSection() {
    final d = _data;
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expense Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _pieLegend(d.expensesByCategory),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Revenue Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _pieLegend({
                  'Dom Care Visits': d.revenueDomCare,
                  'Agency Placements': d.revenueAgency,
                  'Other': d.revenueOther,
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pieLegend(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return const Text('No data');
    final colors = [Colors.green, Colors.orange, Colors.blue, Colors.red, Colors.purple, Colors.teal, Colors.pink, Colors.cyan, Colors.amber, Colors.indigo];
    int i = 0;
    return Column(
      children: data.entries.map((e) {
        final pct = e.value / total;
        final c = colors[i % colors.length];
        i++;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
              Text(_fmt(e.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(width: 40, child: Text('${(pct * 100).toStringAsFixed(1)}%', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
            ],
          ),
        );
      }).toList(),
    );
  }
}