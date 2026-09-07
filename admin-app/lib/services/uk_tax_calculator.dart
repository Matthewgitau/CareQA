import 'dart:math' as math;

/// UK tax & deduction calculator for the CareQA payroll system.
///
/// Implements 2025/26 HMRC rates:
///  - PAYE income tax (tax-free allowance derived from the employee's tax code)
///  - National Insurance (categories A, B, C, J)
///  - Workplace pension (auto-enrolment style, employee + employer)
///  - Student loan repayments (Plans 1, 2, 4, 5 and Postgraduate)
///
/// All rules use annually-pro-rated thresholds scaled by the number of
/// calendar days in the pay period (periodDays / 365). This keeps a
/// weekly, fortnightly or monthly payslip consistent with the annual
/// figures HMRC publish.
class UkTaxResult {
  const UkTaxResult({
    required this.grossPay,
    required this.pensionContribution,
    required this.incomeTax,
    required this.nationalInsurance,
    required this.studentLoan,
    required this.employerPension,
    required this.employerNi,
    required this.netPay,
  });

  final double grossPay;
  final double pensionContribution;
  final double incomeTax;
  final double nationalInsurance;
  final double studentLoan;
  final double employerPension;
  final double employerNi;
  final double netPay;

  double get totalEmployeeDeductions =>
      pensionContribution + incomeTax + nationalInsurance + studentLoan;

  Map<String, dynamic> toDbRow() => {
        'gross_pay': _r(grossPay),
        'pension_contribution': _r(pensionContribution),
        'tax_deducted': _r(incomeTax),
        'ni_deducted': _r(nationalInsurance),
        'student_loan_repayment': _r(studentLoan),
        'employer_pension': _r(employerPension),
        'employer_ni': _r(employerNi),
        'net_pay': _r(netPay),
      };

  static double _r(double v) => (v * 100).roundToDouble() / 100;
}

class UkTaxCalculator {
  // ── 2025/26 annual thresholds ───────────────────────────────
  static const double stdPersonalAllowance = 12570;
  static const double basicRateBand = 37700; // taxable income taxed at 20%
  static const double higherRateLimit = 125140; // 40% band ceiling
  static const double additionalRateLimit = double.infinity;

  // NI (2025/26)
  static const double niPrimaryThreshold = 12570; // Annual PT
  static const double niUpperLimit = 50270; // Annual UEL
  static const double niMainRateA = 0.08;
  static const double niMainRateB = 0.0585; // married women's reduced rate
  static const double niHighRate = 0.02;

  // Employer NI (2025/26)
  static const double employerNiRate = 0.15;
  static const double employerNiSecondaryThreshold = 5000; // annual

  // Workplace pension defaults (auto-enrolment)
  static const double defaultPensionRate = 0.05; // employee
  static const double defaultEmployerPensionRate = 0.03; // employer

  // Student loan plans: annual threshold -> repayment rate
  static const Map<String, double> studentLoanPlan = {
    'plan1': 24990,
    'plan2': 27295,
    'plan4': 31395,
    'plan5': 25000,
    'pgl': 21000,
  };
  static const double studentLoanRate = 0.09;
  static const double pglRate = 0.06;

  // ── Tax code parsing ────────────────────────────────────────
  /// Extracts the annual tax-free allowance from a tax code.
  /// Examples: 1257L -> £12,570 · BR -> £0 · D0/D1 -> £0 (band only)
  /// 0T -> £0 · NT -> no tax (returns infinity) · K1257 -> -£12,570.
  static double taxCodeAllowance(String code) {
    final c = (code ?? '1257L').toUpperCase().trim();
    if (c == 'NT') return double.infinity;
    if (c == 'BR' || c == 'D0' || c == 'D1' || c == 'OT' || c == '0T') return 0;
    if (c.startsWith('K')) {
      final n = double.tryParse(c.substring(1).replaceAll(RegExp(r'[^0-9]'), ''));
      return n == null ? 0 : -n * 10;
    }
    final m = RegExp(r'^([0-9]+)').firstMatch(c);
    return m == null ? stdPersonalAllowance : double.parse(m.group(1)!) * 10;
  }

  static bool isBandOnlyCode(String code) {
    final c = (code ?? '').toUpperCase().trim();
    return c == 'BR' || c == 'D0' || c == 'D1';
  }

  static double bandRateForCode(String code) {
    final c = (code ?? '').toUpperCase().trim();
    if (c == 'D1') return 0.45;
    if (c == 'D0') return 0.40;
    return 0.20; // BR
  }

  // ── Main calculation ────────────────────────────────────────
  /// [grossPay] is the period gross (shifts + routes + holiday + sick + bonus).
  /// [periodDays] number of calendar days the pay covers (e.g. 31 for monthly)
  /// — used to pro-rate annual thresholds.
  static UkTaxResult calculate({
    required double grossPay,
    double periodDays = 30,
    String taxCode = '1257L',
    String niCategory = 'A',
    String studentLoan = 'none',
    double pensionRate = defaultPensionRate,
    double employerPensionRate = defaultEmployerPensionRate,
  }) {
    if (grossPay < 0) grossPay = 0;
    if (periodDays <= 0) periodDays = 30;

    // Scale annual thresholds to the period.
    final factor = (periodDays / 365).clamp(0.0, 1.0);
    final allowance = taxCodeAllowance(taxCode) == double.infinity
        ? double.infinity
        : taxCodeAllowance(taxCode) * factor;

    // Employee pension first (auto-enrolment: deducted before tax/NI).
    final pension = grossPay * pensionRate;
    final taxableGross = math.max(0.0, grossPay - pension);

    // Income tax.
    final incomeTax = _incomeTax(taxableGross, allowance, taxCode, factor);

    // National Insurance (post-pension gross).
    final ni = _nationalInsurance(taxableGross, niCategory, factor);

    // Student loan (post-pension gross).
    final sl = _studentLoan(taxableGross, studentLoan, factor);

    // Employer side (company cost, not deducted from employee).
    final employerPension = grossPay * employerPensionRate;
    final employerNi = grossPay > employerNiSecondaryThreshold * factor
        ? (grossPay - employerNiSecondaryThreshold * factor) * employerNiRate
        : 0.0;

    final netPay = math.max(0.0, grossPay - pension - incomeTax - ni - sl);

    return UkTaxResult(
      grossPay: grossPay,
      pensionContribution: pension,
      incomeTax: incomeTax,
      nationalInsurance: ni,
      studentLoan: sl,
      employerPension: employerPension,
      employerNi: employerNi,
      netPay: netPay,
    );
  }

  static double _incomeTax(
      double taxable, double allowance, String code, double factor) {
    if (code.toUpperCase().trim() == 'NT') return 0;
    if (isBandOnlyCode(code)) return math.max(0, taxable) * bandRateForCode(code);

    final taxableIncome = math.max(0.0, taxable - allowance);
    if (taxableIncome <= 0) return 0;

    final basic = math.min(taxableIncome, basicRateBand * factor) * 0.20;
    final higher = taxableIncome > basicRateBand * factor
        ? math.min(taxableIncome - basicRateBand * factor,
              (higherRateLimit - basicRateBand) * factor) *
            0.40
        : 0.0;
    final additional = taxableIncome > higherRateLimit * factor
        ? (taxableIncome - higherRateLimit * factor) * 0.45
        : 0.0;
    return basic + higher + additional;
  }

  static double _nationalInsurance(double gross, String category, double factor) {
    if (gross <= 0) return 0;
    final pt = niPrimaryThreshold * factor;
    final uel = niUpperLimit * factor;
    if (gross <= pt) return 0;

    final mainBand = math.max(0.0, math.min(gross, uel) - pt);
    final highBand = math.max(0.0, gross - uel);

    switch ((category ?? 'A').toUpperCase()) {
      case 'C': // pensioners pay no NI
        return 0;
      case 'B': // married women / widows reduced rate
        return mainBand * niMainRateB + highBand * niHighRate;
      case 'J':
      case 'A':
      default:
        return mainBand * niMainRateA + highBand * niHighRate;
    }
  }

  static double _studentLoan(double gross, String plan, double factor) {
    final key = (plan ?? 'none').toLowerCase();
    final threshold = studentLoanPlan[key];
    if (threshold == null || gross <= 0) return 0;
    final adjusted = threshold * factor;
    if (gross <= adjusted) return 0;
    final rate = key == 'pgl' ? pglRate : studentLoanRate;
    return (gross - adjusted) * rate;
  }

  /// Label for a student-loan plan code.
  static String studentLoanPlanLabel(String plan) {
    switch ((plan ?? 'none').toLowerCase()) {
      case 'plan1': return 'Plan 1 (pre-2012)';
      case 'plan2': return 'Plan 2 (2012-2023)';
      case 'plan4': return 'Plan 4 (Scotland)';
      case 'plan5': return 'Plan 5 (2023+)';
      case 'pgl': return 'Postgraduate';
      default: return 'None';
    }
  }

  /// Names of supported student-loan plans (for dropdowns).
  static const List<String> studentLoanPlans = [
    'none', 'plan1', 'plan2', 'plan4', 'plan5', 'pgl'
  ];

  static const List<String> niCategories = ['A', 'B', 'C', 'J'];
}