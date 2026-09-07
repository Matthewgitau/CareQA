class _PayslipCard extends StatelessWidget {
  final PayslipEntry payslip;
  const _PayslipCard({required this.payslip});

  @override
  Widget build(BuildContext context) {
    final period = '${_fmt(payslip.periodStart)} - ${_fmt(payslip.periodEnd)}';
    final status = payslip.status.toLowerCase();
    final statusColor = status == 'paid'
        ? Colors.green
        : status == 'cancelled'
            ? Colors.red
            : Colors.orange;
    final preview = payslip.taxPreview();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(period,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _row('Gross pay', preview.grossPay, bold: true),
            if (payslip.regularHours > 0) ...[
              const SizedBox(height: 6),
              _row(
                '  Shifts: ${payslip.regularHours.toStringAsFixed(2)}h @ \u00a3${payslip.hourlyRate.toStringAsFixed(2)}/hr',
                payslip.regularPay,
                small: true,
              ),
            ],
            if (payslip.overtimeHours > 0) ...[
              const SizedBox(height: 2),
              _row(
                '  Routes: ${payslip.overtimeHours.toStringAsFixed(2)}h @ \u00a3${payslip.overtimeRate.toStringAsFixed(2)}/hr',
                payslip.overtimePay,
                small: true,
              ),
            ],
            const SizedBox(height: 8),
            if (preview.incomeTax > 0)
              _row('Income Tax', -preview.incomeTax,
                  color: Colors.red.shade700),
            if (preview.nationalInsurance > 0)
              _row('National Insurance', -preview.nationalInsurance,
                  color: Colors.red.shade700),
            if (preview.pensionContribution > 0)
              _row('Pension', -preview.pensionContribution,
                  color: Colors.orange.shade800),
            if (preview.studentLoan > 0)
              _row('Student Loan', -preview.studentLoan,
                  color: Colors.purple.shade700),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Take-home (Net)',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '\u00a3${preview.netPay.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double amount,
      {bool bold = false, bool small = false, Color? color}) {
    final style = TextStyle(
      fontSize: small ? 13 : 14,
      fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          Text('\u00a3${amount.abs().toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
