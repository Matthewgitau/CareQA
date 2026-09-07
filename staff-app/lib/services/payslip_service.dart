import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight UK PAYE tax preview for the staff-app payslip view.
/// Mirrors admin-app/lib/services/uk_tax_calculator.dart so staff
/// see the same numbers as admin entered.
class UkTaxPreview {
  final double grossPay;
  final double incomeTax;
  final double nationalInsurance;
  final double pensionContribution;
  final double studentLoan;
  final double netPay;

  const UkTaxPreview({
    required this.grossPay,
    required this.incomeTax,
    required this.nationalInsurance,
    required this.pensionContribution,
    required this.studentLoan,
    required this.netPay,
  });
}

class UkPayslipTax {
  /// Standard UK PAYE estimate. Personal allowance tapers above Â£100k.
  static UkTaxPreview estimate({
    required double grossPay,
    String taxCode = '1257L',
    String niCategory = 'A',
    String studentLoanPlan = 'none',
    double pensionPercent = 0.0,
  }) {
    // '1257L' = Â£12,570 personal allowance.
    final numeric = int.tryParse(taxCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1257;
    final personalAllowance = numeric;
    final taxable = (grossPay - personalAllowance).clamp(0, double.infinity);

    // Income Tax (England/Wales/NI basic + higher rates)
    double tax = 0;
    if (taxable > 0) {
      final basic = taxable.clamp(0, 37700);
      tax += basic * 0.20;
      if (taxable > 37700) {
        final higher = (taxable - 37700).clamp(0, 100000);
        tax += higher * 0.40;
      }
    }

    // National Insurance (Class 1, category A approximation)
    double ni = 0;
    if (grossPay > 1048) {
      ni += (grossPay - 1048) * 0.08;
    }
    if (grossPay > 4189) {
      ni += (grossPay - 4189) * 0.02;
    }

    // Pension (employee % of gross)
    final pension = grossPay * (pensionPercent / 100.0);

    // Student loan plans
    double sl = 0;
    switch (studentLoanPlan) {
      case 'plan1':
      case 'plan2':
      case 'plan5':
        if (grossPay > 2490) sl = (grossPay - 2490) * 0.09;
        break;
      case 'plan4':
        if (grossPay > 2080) sl = (grossPay - 2080) * 0.09;
        break;
      case 'postgrad':
        if (grossPay > 2100) sl = (grossPay - 2100) * 0.06;
        break;
    }

    final net = grossPay - tax - ni - pension - sl;
    return UkTaxPreview(
      grossPay: grossPay,
      incomeTax: tax,
      nationalInsurance: ni,
      pensionContribution: pension,
      studentLoan: sl,
      netPay: net,
    );
  }
}

class PayslipEntry {
  final String id;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double regularHours;
  final double hourlyRate;
  final double regularPay;
  final double overtimeHours;
  final double overtimeRate;
  final double overtimePay;
  final String? taxCode;
  final String? niCategory;
  final String? studentLoanPlan;
  final double? pensionEmployeePercent;
  final double? incomeTax;
  final double? nationalInsurance;
  final double? pensionContribution;
  final double? studentLoanRepayment;
  final double? netPay;
  final String status;
  final String? notes;

  const PayslipEntry({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.regularHours,
    required this.hourlyRate,
    required this.regularPay,
    required this.overtimeHours,
    required this.overtimeRate,
    required this.overtimePay,
    this.taxCode,
    this.niCategory,
    this.studentLoanPlan,
    this.pensionEmployeePercent,
    this.incomeTax,
    this.nationalInsurance,
    this.pensionContribution,
    this.studentLoanRepayment,
    this.netPay,
    required this.status,
    this.notes,
  });

  double get grossPay => regularPay + overtimePay;

  /// If the admin pre-calculated the net, use that. Otherwise estimate
  /// it on the staff side so the payslip is always populated.
  UkTaxPreview taxPreview() {
    final cachedNet = netPay;
    if (cachedNet != null && cachedNet > 0) {
      return UkTaxPreview(
        grossPay: grossPay,
        incomeTax: incomeTax ?? 0,
        nationalInsurance: nationalInsurance ?? 0,
        pensionContribution: pensionContribution ?? 0,
        studentLoan: studentLoanRepayment ?? 0,
        netPay: cachedNet,
      );
    }
    return UkPayslipTax.estimate(
      grossPay: grossPay,
      taxCode: taxCode ?? '1257L',
      niCategory: niCategory ?? 'A',
      studentLoanPlan: studentLoanPlan ?? 'none',
      pensionPercent: pensionEmployeePercent ?? 0,
    );
  }
}

class PayslipService {
  final SupabaseClient _client;

  PayslipService(this._client);

  /// Resolves auth.uid() to either profiles.id (= staff_id) or
  /// carers.id (= carer_id). Returns both for an OR query.
  Future<List<String>> _resolveMyIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final ids = <String>{uid};
    try {
      final c = await _client
          .from('carers')
          .select('id')
          .eq('auth_user_id', uid)
          .maybeSingle();
      if (c != null && c['id'] != null) ids.add(c['id'] as String);
    } catch (_) {}
    return ids.toList();
  }

  /// Fetches all payslips for the current staff member, newest first.
  Future<List<PayslipEntry>> getMyPayslips() async {
    final ids = await _resolveMyIds();
    if (ids.isEmpty) return [];

    final response = await _client
        .from('payroll_history')
        .select(
            'id, period_start, period_end, regular_hours, hourly_rate, regular_pay, '
            'overtime_hours, overtime_rate, overtime_pay, tax_code, ni_category, '
            'student_loan_plan, pension_employee_percent, income_tax, national_insurance, '
            'pension_contribution, student_loan_repayment, net_pay, status, notes')
        .or('staff_id.in.(${ids.join(',')}),carer_id.in.(${ids.join(',')})')
        .order('period_end', ascending: false);

    return (response as List)
        .map((j) => _fromMap(j as Map<String, dynamic>))
        .toList();
  }

  /// YTD totals for the current UK tax year (Apr 6 -> today).
  Future<Map<String, double>> getYtdTotals() async {
    final entries = await getMyPayslips();
    final yearStart = DateTime(DateTime.now().year, 4, 6);
    final ytd = entries.where((e) => e.periodEnd.isAfter(yearStart));
    double gross = 0, tax = 0, ni = 0, pension = 0, sl = 0, net = 0;
    for (final e in ytd) {
      final p = e.taxPreview();
      gross += p.grossPay;
      tax += p.incomeTax;
      ni += p.nationalInsurance;
      pension += p.pensionContribution;
      sl += p.studentLoan;
      net += p.netPay;
    }
    return {
      'gross': gross,
      'tax': tax,
      'ni': ni,
      'pension': pension,
      'student_loan': sl,
      'net': net,
      'count': ytd.length.toDouble(),
    };
  }

  PayslipEntry _fromMap(Map<String, dynamic> j) {
    double d(dynamic v) => v == null ? 0.0 : (v as num).toDouble();
    return PayslipEntry(
      id: j['id'] as String,
      periodStart: DateTime.parse(j['period_start'] as String),
      periodEnd: DateTime.parse(j['period_end'] as String),
      regularHours: d(j['regular_hours']),
      hourlyRate: d(j['hourly_rate']),
      regularPay: d(j['regular_pay']),
      overtimeHours: d(j['overtime_hours']),
      overtimeRate: d(j['overtime_rate']),
      overtimePay: d(j['overtime_pay']),
      taxCode: j['tax_code'] as String?,
      niCategory: j['ni_category'] as String?,
      studentLoanPlan: j['student_loan_plan'] as String?,
      pensionEmployeePercent: j['pension_employee_percent'] == null
          ? null
          : d(j['pension_employee_percent']),
      incomeTax: j['income_tax'] == null ? null : d(j['income_tax']),
      nationalInsurance:
          j['national_insurance'] == null ? null : d(j['national_insurance']),
      pensionContribution: j['pension_contribution'] == null
          ? null
          : d(j['pension_contribution']),
      studentLoanRepayment: j['student_loan_repayment'] == null
          ? null
          : d(j['student_loan_repayment']),
      netPay: j['net_pay'] == null ? null : d(j['net_pay']),
      status: (j['status'] as String?) ?? 'processed',
      notes: j['notes'] as String?,
    );
  }
}

