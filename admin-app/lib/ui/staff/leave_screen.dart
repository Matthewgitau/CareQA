import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/leave_request.dart';
import '../../services/leave_service.dart';
import '../../services/uk_tax_calculator.dart';
import 'leave_request_form.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> with SingleTickerProviderStateMixin {
  final _service = LeaveService(Supabase.instance.client);
  late TabController _tabController;
  List<LeaveRequest> _leaveRequests = [];
  List<LeaveRequest> _filteredRequests = [];
  bool _isLoading = true;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => _loadLeaveRequests());
    _loadLeaveRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _hoursEditors.values) { c.dispose(); }
    for (final c in _routeHoursEditors.values) { c.dispose(); }
    for (final c in _rateEditors.values) { c.dispose(); }
    for (final c in _routeRateEditors.values) { c.dispose(); }
    for (final c in _taxCodeEditors.values) { c.dispose(); }
    for (final c in _pensionRateEditors.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _service.getLeaveRequests();
      if (mounted) {
        setState(() {
          _leaveRequests = requests;
          _filteredRequests = requests;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leave requests: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterRequests(String? status) {
    setState(() {
      _selectedStatus = status;
      if (status == null) {
        _filteredRequests = _leaveRequests;
      } else {
        _filteredRequests = _leaveRequests.where((r) => r.status == status).toList();
      }
    });
  }

  Future<void> _approveLeave(String id) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _service.approveLeave(id, user.id);
        _loadLeaveRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave approved'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectLeave(String id) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      try {
        await _service.rejectLeave(id, reason);
        _loadLeaveRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave rejected'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave & Pay'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Leave Requests', icon: Icon(Icons.event_note)),
            Tab(text: 'Payroll', icon: Icon(Icons.payments)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaveTab(),
                _buildPayrollTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _addLeaveRequest,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildLeaveTab() {
    return Column(
      children: [
        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildFilterChip('All', null),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Approved', 'approved'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'rejected'),
              const SizedBox(width: 8),
              _buildFilterChip('Cancelled', 'cancelled'),
            ],
          ),
        ),
        Expanded(
          child: _filteredRequests.isEmpty
              ? const Center(child: Text('No leave requests found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = _filteredRequests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(request.staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(request.getLeaveTypeDisplay()),
                            Text('${DateFormat('dd/MM/yyyy').format(request.startDate)} - ${DateFormat('dd/MM/yyyy').format(request.endDate)}'),
                            Text('${request.totalDays.toStringAsFixed(1)} days'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(request.status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                request.getStatusDisplay(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            if (request.status == 'pending') ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _approveLeave(request.id),
                                    child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _rejectLeave(request.id),
                                    child: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        onTap: () => _viewLeaveDetails(request),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Payroll Tab: Admin processes payslips based on shift/route hours ───
  List<Map<String, dynamic>>? _payrollEntries;
  DateTime _payPeriodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _payPeriodEnd = DateTime.now();
  bool _payLoading = false;
  // Editable state per staff
  Set<String> _editingStaff = {};
  Map<String, TextEditingController> _hoursEditors = {};
  Map<String, TextEditingController> _routeHoursEditors = {}; // separate hours for route visits
  Map<String, TextEditingController> _rateEditors = {};
  Map<String, TextEditingController> _routeRateEditors = {}; // separate rate for route visits
  // Tax & deduction editors per staff (used when "Review & Generate" is open)
  Map<String, TextEditingController> _taxCodeEditors = {};
  Map<String, TextEditingController> _pensionRateEditors = {};
  Map<String, String> _niCategory = {};
  Map<String, String> _studentLoanPlan = {};

  Future<void> _loadPayroll() async {
    setState(() => _payLoading = true);
    try {
      final s = _payPeriodStart.toIso8601String().split('T')[0];
      final e = _payPeriodEnd.toIso8601String().split('T')[0];
      final client = Supabase.instance.client;

      // ── Load carers (may not all have profiles — identity-linkage) ──
      // NOTE: auth_user_id only exists if migration 147 was applied, so
      // select it defensively with a fallback query if the column is missing.
      List<Map<String, dynamic>> carerList = [];
      try {
        carerList = (await client.from('carers').select('id, name, employee_number, is_active').order('name'))
            .cast<Map<String, dynamic>>();
      } catch (_) {}

      // ── Load profiles ──
      // NOTE: employee_number is NOT a profiles column (it's on carers),
      // so only select columns that actually exist.
      List<Map<String, dynamic>> staffList = [];
      try {
        staffList = (await client.from('profiles').select('id, full_name, name, email, role').order('full_name'))
            .cast<Map<String, dynamic>>();
      } catch (_) {}

      // ── Carer-to-profile identity bridge ──
      // shifts.carer_id = carers.id, but payData is keyed by profiles.id.
      // This map translates carers.id → profile.id so shift hours land correctly.
      final Map<String, String> carerToProfile = {};
      for (final c in carerList) {
        final cid = c['id'] as String;
        // Case 1: direct match (carers.id = profiles.id)
        if (staffList.any((s) => s['id'] == cid)) { carerToProfile[cid] = cid; continue; }
        // Case 2: auth_user_id bridge (migration 147) — guard because the
        // column may not exist if migration 147 was never applied.
        String? auid;
        try {
          final g = (await client.from('carers').select('auth_user_id').eq('id', cid).maybeSingle());
          auid = g?['auth_user_id'] as String?;
        } catch (_) {}
        if (auid != null && auid.isNotEmpty && staffList.any((s) => s['id'] == auid)) { carerToProfile[cid] = auid; continue; }
        // Case 3: name match (loose)
        final cname = (c['name'] as String?)?.toLowerCase().trim();
        if (cname != null && cname.isNotEmpty) {
          final matches = staffList.where((s) {
            final sn = ((s['full_name'] ?? s['name'] ?? '') as String).toLowerCase().trim();
            return sn == cname || sn.startsWith(cname) || cname.startsWith(sn);
          }).toList();
          if (matches.length == 1) { carerToProfile[cid] = matches.first['id'] as String; continue; }
        }
        // Case 4: no match — still include as synthetic staff entry
        carerToProfile[cid] = cid;
        staffList.add({'id': cid, 'name': c['name'] ?? 'Carer', 'full_name': c['name'], 'email': '', 'role': 'carer', '_from_carers': true});
      }

      // Load shifts
      List<Map<String, dynamic>> shiftList = [];
      try {
        final shifts = await client.from('shifts')
            .select('carer_id, start_time, end_time').not('carer_id', 'is', null)
            .gte('scheduled_date', s).lte('scheduled_date', e);
        shiftList = (shifts as List).cast<Map<String, dynamic>>();
      } catch (_) {}

      // Load route visits
      List<Map<String, dynamic>> visitList = [];
      try {
        final rv = await client.from('route_visits')
            .select('carer_id, duration_minutes').not('carer_id', 'is', null)
            .gte('visit_date', s).lte('visit_date', e);
        visitList = (rv as List).cast<Map<String, dynamic>>();
      } catch (_) {}

      // Load existing payroll
      List<Map<String, dynamic>> existingList = [];
      try {
        final ep = await client.from('payroll_history')
            .select('*').gte('period_start', s).lte('period_end', e);
        existingList = (ep as List).cast<Map<String, dynamic>>();
      } catch (_) {}

      final Map<String, Map<String, dynamic>> payData = {};
      for (final st in staffList) {
        final sid = st['id'] as String;
        payData[sid] = {'staff': st, 'shiftHours': 0.0, 'routeHours': 0.0, 'existingPay': <Map<String, dynamic>>[], 'carerId': null};
      }
      for (final sh in shiftList) {
        final rawCarerId = sh['carer_id'] as String?;
        if (rawCarerId == null) continue;
        final profileId = carerToProfile[rawCarerId] ?? rawCarerId;
        if (!payData.containsKey(profileId)) continue;
        final h = _shiftHours(sh['start_time'] ?? '', sh['end_time'] ?? '');
        payData[profileId]!['shiftHours'] = (payData[profileId]!['shiftHours'] as double) + h;
        payData[profileId]!['carerId'] = rawCarerId;
      }
      for (final rv in visitList) {
        final rawCarerId = rv['carer_id'] as String?;
        if (rawCarerId == null) continue;
        final profileId = carerToProfile[rawCarerId] ?? rawCarerId;
        if (!payData.containsKey(profileId)) continue;
        final mins = (rv['duration_minutes'] as num?)?.toDouble() ?? 60;
        payData[profileId]!['routeHours'] = (payData[profileId]!['routeHours'] as double) + (mins / 60.0);
        payData[profileId]!['carerId'] = rawCarerId;
      }
      for (final pe in existingList) {
        final sid = pe['staff_id'] as String?;
        final cid = pe['carer_id'] as String?;
        if (sid != null && payData.containsKey(sid)) {
          (payData[sid]!['existingPay'] as List).add(pe);
        } else if (cid != null && payData.containsKey(cid)) {
          (payData[cid]!['existingPay'] as List).add(pe);
        }
      }

      final entries = <Map<String, dynamic>>[];
      for (final entry in payData.entries) {
        final d = entry.value;
        final sh = (d['shiftHours'] as double);
        final rh = (d['routeHours'] as double);
        final existing = (d['existingPay'] as List);
        // Show ALL staff — even with 0 hours — so admin can see everyone
        final st = d['staff'] as Map<String, dynamic>;
        final sid = st['id'] as String;
        final carerId = d['carerId'] as String?;
        // Whether the payData key is a real profiles.id (if not, staff_id must be null on insert)
        // Synthetic carer-only entries are flagged with _from_carers == true.
        final isProfile = !(st['_from_carers'] == true);
        double? rate;
        try {
          final last = await client.from('payroll_history')
              .select('hourly_rate')
              .or('staff_id.eq.$sid,carer_id.eq.$sid')
              .order('period_end', ascending: false).limit(1).maybeSingle();
          if (last != null) rate = (last['hourly_rate'] as num?)?.toDouble();
        } catch (_) {}
        final totalH = sh + rh;
        entries.add({
          'staff': st, 'shiftHours': sh, 'routeHours': rh,
          'totalHours': totalH, 'rate': rate ?? 11.44,
          'routeRate': rate ?? 11.44, 'existing': existing,
          'profileId': isProfile ? sid : null,
          // Guard: carer_id must exist in cares to satisfy the FK.
          'carerId': (carerId != null && carerList.any((c) => c['id'] == carerId)) ? carerId : null,
        });
      }
      if (mounted) setState(() { _payrollEntries = entries; _payLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _payLoading = false);
      debugPrint('Payroll load error: $e');
    }
  }

  double _shiftHours(String startTime, String endTime) {
    try {
      final s = startTime.split(':'), e = endTime.split(':');
      if (s.length < 2 || e.length < 2) return 1.0;
      final sm = (int.tryParse(s[0]) ?? 0) * 60 + (int.tryParse(s[1]) ?? 0);
      final em = (int.tryParse(e[0]) ?? 0) * 60 + (int.tryParse(e[1]) ?? 0);
      return (em - sm) > 0 ? (em - sm) / 60.0 : 1.0;
    } catch (_) { return 1.0; }
  }

  Future<void> _runPayrollSplit(
      String staffId, String staffName,
      double shiftHours, double shiftRate, double routeHours, double routeRate,
      String? profileId, String? carerId,
      {String taxCode = '1257L', String niCategory = 'A',
       double pensionRate = 0.0, String studentLoanPlan = 'none'}) async {
    try {
      final s = _payPeriodStart.toIso8601String().split('T')[0];
      final e = _payPeriodEnd.toIso8601String().split('T')[0];
      final shiftPay = shiftHours * shiftRate;
      final routePay = routeHours * routeRate;
      final grossPay = shiftPay + routePay;

      // Compute UK tax & deductions (2025/26 rates).
      final periodDays = _payPeriodEnd.difference(_payPeriodStart).inDays + 1;
      final tax = UkTaxCalculator.calculate(
        grossPay: grossPay,
        periodDays: periodDays.toDouble(),
        taxCode: taxCode,
        niCategory: niCategory,
        studentLoan: studentLoanPlan,
        pensionRate: pensionRate > 0 ? pensionRate : 0,
      );

      // staff_id must reference profiles(id) or be NULL; carer_id references
      // carers(id) so carer-only workers can be paid without a profile row.
      await Supabase.instance.client.from('payroll_history').insert({
        'staff_id': profileId,
        'carer_id': carerId,
        'staff_name': staffName,
        'period_start': s, 'period_end': e,
        'regular_hours': shiftHours, 'hourly_rate': shiftRate, 'regular_pay': shiftPay,
        'overtime_hours': routeHours, 'overtime_rate': routeRate, 'overtime_pay': routePay,
        'holiday_pay': 0, 'sick_pay': 0, 'bonus_pay': 0, 'deductions': 0,
        'gross_pay': grossPay, 'net_pay': tax.netPay,
        'tax_code': taxCode.toUpperCase(),
        'ni_category': niCategory.toUpperCase(),
        'pension_rate': pensionRate,
        'pension_contribution': tax.pensionContribution,
        'employer_pension': tax.employerPension,
        'employer_ni': tax.employerNi,
        'tax_deducted': tax.incomeTax,
        'ni_deducted': tax.nationalInsurance,
        'student_loan_plan': studentLoanPlan,
        'student_loan_repayment': tax.studentLoan,
        'status': 'processed', 'processed_at': DateTime.now().toIso8601String(),
        'notes': 'Shifts: ${shiftHours.toStringAsFixed(1)}h@£${shiftRate.toStringAsFixed(2)} | Routes: ${routeHours.toStringAsFixed(1)}h@£${routeRate.toStringAsFixed(2)}',
        'created_at': DateTime.now().toIso8601String(),
      });
      _editingStaff.remove(staffId);
      _hoursEditors.remove(staffId); _routeHoursEditors.remove(staffId);
      _rateEditors.remove(staffId); _routeRateEditors.remove(staffId);
      _taxCodeEditors.remove(staffId); _pensionRateEditors.remove(staffId);
      _niCategory.remove(staffId); _studentLoanPlan.remove(staffId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payslip for $staffName: Net £${tax.netPay.toStringAsFixed(2)} (gross £${grossPay.toStringAsFixed(2)})'),
              backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        _payrollEntries = null; _loadPayroll();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _runPayroll(String staffId, String staffName, double hours, double rate) async {
    try {
      final s = _payPeriodStart.toIso8601String().split('T')[0];
      final e = _payPeriodEnd.toIso8601String().split('T')[0];
      final pay = hours * rate;
      await Supabase.instance.client.from('payroll_history').insert({
        'staff_id': staffId, 'staff_name': staffName,
        'period_start': s, 'period_end': e,
        'regular_hours': hours, 'hourly_rate': rate, 'regular_pay': pay,
        'overtime_hours': 0, 'overtime_pay': 0, 'holiday_pay': 0,
        'sick_pay': 0, 'bonus_pay': 0, 'deductions': 0,
        'status': 'processed', 'processed_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      _editingStaff.remove(staffId);
      _hoursEditors[staffId]?.dispose(); _rateEditors[staffId]?.dispose();
      _hoursEditors.remove(staffId); _rateEditors.remove(staffId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payslip for $staffName: £${pay.toStringAsFixed(2)}'),
              backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        _payrollEntries = null; _loadPayroll();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildPayrollTab() {
    if (_payrollEntries == null && !_payLoading) _loadPayroll();
    final entries = _payrollEntries;

    return _payLoading || entries == null
        ? const Center(child: CircularProgressIndicator())
        : Column(children: [
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Expanded(child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _payPeriodStart, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) { setState(() => _payPeriodStart = d); _payrollEntries = null; _loadPayroll(); }
                  },
                  child: Text('From: ${_fmtD(_payPeriodStart)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                )),
                Expanded(child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _payPeriodEnd, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) { setState(() => _payPeriodEnd = d); _payrollEntries = null; _loadPayroll(); }
                  },
                  child: Text('To: ${_fmtD(_payPeriodEnd)}', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue.shade700)),
                )),
                IconButton(icon: const Icon(Icons.refresh), onPressed: () { _payrollEntries = null; _loadPayroll(); }),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No staff found or no hours in this period.\nEnsure migration 150 has been run for RLS.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))))
                  : ListView.builder(padding: const EdgeInsets.all(12), itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        final st = e['staff'] as Map<String, dynamic>;
                        final sid = st['id'] as String;
                        final name = (st['full_name'] ?? st['name'] ?? st['email'] ?? 'Staff').toString();
                        final sh = (e['shiftHours'] as double);
                        final rh = (e['routeHours'] as double);
                        final rate = (e['rate'] as double);
                        final routeRate = (e['routeRate'] as double?) ?? rate;
                        final existing = (e['existing'] as List);
                        final paid = existing.isNotEmpty
                            ? existing.fold<double>(0, (s, p) => s + ((p['regular_pay'] as num?)?.toDouble() ?? 0))
                            : 0.0;

                        if (_editingStaff.contains(sid)) {
                          _hoursEditors.putIfAbsent(sid, () => TextEditingController(text: sh.toStringAsFixed(1)));
                          _routeHoursEditors.putIfAbsent(sid, () => TextEditingController(text: rh.toStringAsFixed(1)));
                          _rateEditors.putIfAbsent(sid, () => TextEditingController(text: rate.toStringAsFixed(2)));
                          _routeRateEditors.putIfAbsent(sid, () => TextEditingController(text: routeRate.toStringAsFixed(2)));
                          _taxCodeEditors.putIfAbsent(sid, () => TextEditingController(text: e['tax_code'] ?? '1257L'));
                          _pensionRateEditors.putIfAbsent(sid, () => TextEditingController(text: (e['pension_rate'] as num?)?.toStringAsFixed(1) ?? '0'));
                        }
                        final editedShiftHours = _editingStaff.contains(sid) ? (double.tryParse(_hoursEditors[sid]!.text.trim()) ?? sh) : sh;
                        final editedRouteHours = _editingStaff.contains(sid) ? (double.tryParse(_routeHoursEditors[sid]!.text.trim()) ?? rh) : rh;
                        final editedShiftRate = _editingStaff.contains(sid) ? (double.tryParse(_rateEditors[sid]!.text.trim()) ?? rate) : rate;
                        final editedRouteRate = _editingStaff.contains(sid) ? (double.tryParse(_routeRateEditors[sid]!.text.trim()) ?? routeRate) : routeRate;
                        final editedPay = (editedShiftHours * editedShiftRate) + (editedRouteHours * editedRouteRate);
                        // Live UK tax & deductions preview for this payslip.
                        final editingTaxCode = _editingStaff.contains(sid) ? (_taxCodeEditors[sid]!.text.trim().isEmpty ? '1257L' : _taxCodeEditors[sid]!.text.trim()) : '1257L';
                        final editingNiCat = _editingStaff.contains(sid) ? (_niCategory[sid] ?? 'A') : 'A';
                        final editingPlan = _editingStaff.contains(sid) ? (_studentLoanPlan[sid] ?? 'none') : 'none';
                        final editingPensionRate = _editingStaff.contains(sid) ? ((double.tryParse(_pensionRateEditors[sid]!.text.trim()) ?? 0.0) / 100.0) : 0.0;
                        final periodDays = _payPeriodEnd.difference(_payPeriodStart).inDays + 1;
                        final taxPreview = UkTaxCalculator.calculate(
                          grossPay: editedPay,
                          periodDays: periodDays.toDouble(),
                          taxCode: editingTaxCode,
                          niCategory: editingNiCat,
                          studentLoan: editingPlan,
                          pensionRate: editingPensionRate > 0 ? editingPensionRate : 0,
                        );
                        return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              CircleAvatar(radius: 14, backgroundColor: Colors.teal.shade100,
                                child: Icon(Icons.person, size: 16, color: Colors.teal.shade700)),
                              const SizedBox(width: 8),
                              Expanded(child: Row(children: [
                                Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                if (st['_from_carers'] == true)
                                  Container(margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                                    child: Text('carers', style: TextStyle(fontSize: 9, color: Colors.orange.shade800, fontWeight: FontWeight.w600))),
                              ])),
                              if (paid > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
                                  child: Text('Paid £${paid.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600))),
                            ]),
                            const SizedBox(height: 8),
                            if (_editingStaff.contains(sid)) ...[
                              // Row 1: Editable HOURS (shifts + routes)
                              Row(children: [
                                Expanded(child: TextField(
                                  controller: _hoursEditors[sid], keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Shift hrs', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                  style: const TextStyle(fontSize: 13),
                                )),
                                SizedBox(width: 50, child: Text('£${(editedShiftHours * editedShiftRate).toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.blue.shade700))),
                                const SizedBox(width: 8),
                                Expanded(child: TextField(
                                  controller: _routeHoursEditors[sid], keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Route hrs', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                  style: const TextStyle(fontSize: 13),
                                )),
                                SizedBox(width: 50, child: Text('£${(editedRouteHours * editedRouteRate).toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.teal.shade700))),
                              ]),
                              const SizedBox(height: 4),
                              // Row 2: Editable RATES (shifts + routes)
                              Row(children: [
                                Expanded(child: TextField(
                                  controller: _rateEditors[sid], keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Shift rate', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                  style: const TextStyle(fontSize: 13),
                                )),
                                const SizedBox(width: 8),
                                Expanded(child: TextField(
                                  controller: _routeRateEditors[sid], keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Route rate', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                  style: const TextStyle(fontSize: 13),
                                )),
                              ]),
                              const SizedBox(height: 6),
                              // ── Tax & Deductions section ──
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.indigo.shade200),
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Icon(Icons.receipt_long, size: 14, color: Colors.indigo.shade700),
                                    const SizedBox(width: 4),
                                    Text('Tax & Deductions (UK PAYE)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.indigo.shade800)),
                                  ]),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Expanded(child: TextField(
                                      controller: _taxCodeEditors[sid], textCapitalization: TextCapitalization.characters,
                                      decoration: const InputDecoration(labelText: 'Tax code', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                      style: const TextStyle(fontSize: 13),
                                    )),
                                    const SizedBox(width: 8),
                                    Expanded(child: DropdownButtonFormField<String>(
                                      initialValue: _niCategory[sid] ?? 'A',
                                      decoration: const InputDecoration(labelText: 'NI cat', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                      items: UkTaxCalculator.niCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                                      onChanged: (v) => setState(() => _niCategory[sid] = v ?? 'A'),
                                    )),
                                  ]),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Expanded(child: TextField(
                                      controller: _pensionRateEditors[sid], keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Pension %', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                      style: const TextStyle(fontSize: 13),
                                    )),
                                    const SizedBox(width: 8),
                                    Expanded(child: DropdownButtonFormField<String>(
                                      initialValue: _studentLoanPlan[sid] ?? 'none',
                                      decoration: const InputDecoration(labelText: 'Student loan', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true),
                                      items: UkTaxCalculator.studentLoanPlans
                                          .map((p) => DropdownMenuItem(value: p, child: Text(UkTaxCalculator.studentLoanPlanLabel(p), style: const TextStyle(fontSize: 12))))
                                          .toList(),
                                      onChanged: (v) => setState(() => _studentLoanPlan[sid] = v ?? 'none'),
                                    )),
                                  ]),
                                const SizedBox(height: 8),
                                  // Live deduction preview
                                  _payTaxLine('Gross', taxPreview.grossPay, color: Colors.grey.shade800),
                                  if (taxPreview.pensionContribution > 0) _payTaxLine('Pension', taxPreview.pensionContribution, color: Colors.orange.shade800),
                                  _payTaxLine('Income Tax', taxPreview.incomeTax, color: Colors.red.shade800),
                                  _payTaxLine('National Insurance', taxPreview.nationalInsurance, color: Colors.red.shade800),
                                  if (taxPreview.studentLoan > 0) _payTaxLine('Student Loan', taxPreview.studentLoan, color: Colors.purple.shade800),
                                  const Divider(height: 8),
                                  _payTaxLine('Take-home (Net)', taxPreview.netPay, color: Colors.green.shade800, bold: true),
                                ]),
                              ),
                              const SizedBox(height: 6),
                              Row(children: [
                                Text('Gross: £${editedPay.toStringAsFixed(2)} · Net: £${taxPreview.netPay.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                                const Spacer(),
                                TextButton.icon(onPressed: () => setState(() { _editingStaff.remove(sid); }),
                                  icon: const Icon(Icons.close, size: 16), label: const Text('Cancel'), style: TextButton.styleFrom(foregroundColor: Colors.grey)),
                                const SizedBox(width: 4),
                                ElevatedButton.icon(
                                  onPressed: () => _runPayrollSplit(sid, name, editedShiftHours, editedShiftRate, editedRouteHours, editedRouteRate, e['profileId'] as String?, e['carerId'] as String?,
                                      taxCode: editingTaxCode, niCategory: editingNiCat, pensionRate: editingPensionRate > 0 ? editingPensionRate : 0, studentLoanPlan: editingPlan),
                                  icon: const Icon(Icons.check, size: 16), label: const Text('Generate Payslip', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                ),
                              ]),
                            ] else ...[
                              Row(children: [
                                _pwMetric('Shifts', '${sh.toStringAsFixed(1)}h'), const SizedBox(width: 16),
                                _pwMetric('Routes', '${rh.toStringAsFixed(1)}h'),
                              ]),
                              Row(children: [
                                _pwMetric('Shift rate', '£${rate.toStringAsFixed(2)}/hr'), const SizedBox(width: 16),
                                _pwMetric('Route rate', '£${routeRate.toStringAsFixed(2)}/hr'),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                Text('Est: £${((sh * rate) + (rh * routeRate)).toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                if (paid == 0)
                                  TextButton.icon(
                                    onPressed: () => setState(() => _editingStaff.add(sid)),
                                    icon: const Icon(Icons.edit, size: 16), label: const Text('Review & Generate', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                                  ),
                              ]),
                            ],
                          ]),
                        ));
                      }),
            ),
          ]);
  }

  Widget _pwMetric(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  String _fmtD(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]} ${d.year}';
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _filterRequests(isSelected ? null : status),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      case 'withdrawn': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  void _viewLeaveDetails(LeaveRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${request.getLeaveTypeDisplay()} - ${request.getStatusDisplay()}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Staff', request.staffName),
              _buildDetailRow('Type', request.getLeaveTypeDisplay()),
              _buildDetailRow('Start', DateFormat('dd/MM/yyyy').format(request.startDate)),
              _buildDetailRow('End', DateFormat('dd/MM/yyyy').format(request.endDate)),
              _buildDetailRow('Days', '${request.totalDays.toStringAsFixed(1)}'),
              _buildDetailRow('Pay Rate', request.payRateType),
              _buildDetailRow('Pay %', '${request.payPercentage}%'),
              if (request.notes != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Notes:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(request.notes!),
              ],
              if (request.rejectedReason != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Text('Rejection Reason:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Text(request.rejectedReason!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (request.status == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _approveLeave(request.id);
              },
              child: const Text('Approve', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectLeave(request.id);
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ── Tax line row helper (used in payslip editing) ────────────
  Widget _payTaxLine(String label, double amount, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '£${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: color ?? Colors.black87,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _addLeaveRequest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaveRequestFormScreen()),
    );
    if (result == true) {
      _loadLeaveRequests();
    }
  }
}