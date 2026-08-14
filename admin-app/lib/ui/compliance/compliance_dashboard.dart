import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:admin_app/services/compliance_service.dart';
import 'package:admin_app/models/compliance_flag.dart';
import 'package:admin_app/models/compliance_score.dart';
import 'package:admin_app/models/teaching_moment.dart';
import 'package:admin_app/models/regulatory_report.dart';

// ─── Constants ───────────────────────────────────────────────
const _kCategories = <_CategoryDef>[
  _CategoryDef('mar_audit', 'MAR Audit', Icons.medication),
  _CategoryDef('care_log_audit', 'Care Log Audit', Icons.article),
  _CategoryDef('care_plan_audit', 'Care Plan Audit', Icons.assignment),
  _CategoryDef('spot_check', 'Spot Check', Icons.fact_check),
  _CategoryDef('safeguarding', 'Safeguarding', Icons.shield),
  _CategoryDef('accidents_log', 'Accidents Log', Icons.warning_amber),
  _CategoryDef('complaints', 'Complaints', Icons.thumb_down_alt),
  _CategoryDef('compliments', 'Compliments', Icons.thumb_up_alt),
  _CategoryDef('whistleblowers', 'Whistleblowers', Icons.record_voice_over),
  _CategoryDef('serious_incidents', 'Serious Incidents', Icons.error_outline),
  _CategoryDef('disciplinary', 'Disciplinary', Icons.gavel),
  _CategoryDef('employee_welfare', 'Employee Welfare', Icons.favorite),
  _CategoryDef('training_matrix', 'Training Matrix', Icons.school),
  _CategoryDef('appraisals', 'Appraisals', Icons.person_search),
  _CategoryDef('supervision_matrix', 'Supervision Matrix', Icons.supervisor_account),
  _CategoryDef('competency_dashboard', 'Competency Dashboard', Icons.workspace_premium),
];

class _CategoryDef {
  final String key;
  final String label;
  final IconData icon;
  const _CategoryDef(this.key, this.label, this.icon);
}

// ─── Risk level helpers ──────────────────────────────────────
String _riskLabel(double score) {
  if (score >= 80) return 'Low';
  if (score >= 60) return 'Medium';
  if (score >= 40) return 'High';
  return 'Critical';
}

Color _riskColor(double score) {
  if (score >= 80) return Colors.green;
  if (score >= 60) return Colors.orange;
  if (score >= 40) return Colors.deepOrange;
  return Colors.red;
}

Color _scoreColor(double score) {
  if (score >= 80) return Colors.green;
  if (score >= 60) return Colors.orange;
  if (score >= 40) return Colors.deepOrange;
  return Colors.red;
}

// ─── Date-range presets ──────────────────────────────────────
enum _DateRange { last30, lastQuarter, lastYear, custom }

class _DateRangeValue {
  final DateTime start;
  final DateTime end;
  const _DateRangeValue(this.start, this.end);
}

_DateRangeValue _resolveRange(_DateRange range, {DateTime? customStart, DateTime? customEnd}) {
  final now = DateTime.now();
  switch (range) {
    case _DateRange.last30:
      return _DateRangeValue(now.subtract(const Duration(days: 30)), now);
    case _DateRange.lastQuarter:
      return _DateRangeValue(now.subtract(const Duration(days: 90)), now);
    case _DateRange.lastYear:
      return _DateRangeValue(now.subtract(const Duration(days: 365)), now);
    case _DateRange.custom:
      return _DateRangeValue(
        customStart ?? now.subtract(const Duration(days: 30)),
        customEnd ?? now,
      );
  }
}

// ═════════════════════════════════════════════════════════════
//  WIDGET
// ═════════════════════════════════════════════════════════════
class ComplianceDashboard extends StatefulWidget {
  const ComplianceDashboard({super.key});

  @override
  State<ComplianceDashboard> createState() => _ComplianceDashboardState();
}

class _ComplianceDashboardState extends State<ComplianceDashboard> {
  late ComplianceService _svc;

  // Date range
  _DateRange _selectedRange = _DateRange.last30;
  DateTime? _customStart;
  DateTime? _customEnd;

  // Loaded data
  Map<String, dynamic> _categoryData = {};
  List<ComplianceFlag> _flags = [];
  List<TeachingMoment> _teachingMoments = [];
  List<RegulatoryReport> _reports = [];
  List<Map<String, dynamic>> _trends = [];

  // Trend interval
  String _trendInterval = 'weekly';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _svc = Provider.of<ComplianceService>(context, listen: false);
    _loadAll();
  }

  _DateRangeValue get _range => _resolveRange(_selectedRange, customStart: _customStart, customEnd: _customEnd);

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final r = _range;
    try {
      final results = await Future.wait([
        _svc.getDashboardCategoryScores(startDate: r.start, endDate: r.end),
        _svc.getComplianceFlags(),
        _svc.getTeachingMoments(),
        _svc.getRegulatoryReports(),
        _svc.getComplianceTrends(interval: _trendInterval, startDate: r.start, endDate: r.end),
      ]);
      if (!mounted) return;
      setState(() {
        _categoryData = results[0] as Map<String, dynamic>;
        _flags = results[1] as List<ComplianceFlag>;
        _teachingMoments = results[2] as List<TeachingMoment>;
        _reports = results[3] as List<RegulatoryReport>;
        _trends = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onRangeChanged(_DateRange value) async {
    if (value == _DateRange.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() {
          _customStart = picked.start;
          _customEnd = picked.end;
          _selectedRange = value;
        });
        _loadAll();
      }
    } else {
      setState(() => _selectedRange = value);
      _loadAll();
    }
  }

  bool get _isDataAvailable {
    // Data is available if category data is non-empty and has meaningful keys
    return _categoryData.isNotEmpty &&
        (_categoryData.containsKey('overall_score') ||
         _categoryData.containsKey('category_scores'));
  }

  // ─── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compliance Dashboard')),
        body: _buildSkeleton(),
      );
    }

    if (!_isDataAvailable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compliance Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.build, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Compliance Dashboard Coming Soon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This feature will be available once all compliance modules are complete.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ─── Skeleton loader ────────────────────────────────────
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _shimmerBox(height: 220),
          const SizedBox(height: 16),
          _shimmerBox(height: 40, width: 200),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: _gridColumns(context),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: List.generate(16, (_) => _shimmerBox(height: 100)),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({double height = 80, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ─── Main body ──────────────────────────────────────────
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Overall Compliance Score
            _buildOverallScoreCard(),
            const SizedBox(height: 20),

            // 2. Category Scores grid
            _buildSectionTitle('Category Scores'),
            const SizedBox(height: 8),
            _buildCategoryGrid(),
            const SizedBox(height: 20),

            // 3. Recent Compliance Flags
            _buildSectionTitle('Recent Compliance Flags'),
            const SizedBox(height: 8),
            _buildFlagsSection(),
            const SizedBox(height: 20),

            // 4. Teaching Moments
            _buildSectionTitle('Teaching Moments'),
            const SizedBox(height: 8),
            _buildTeachingSection(),
            const SizedBox(height: 20),

            // 5. Regulatory Reports
            _buildSectionTitle('Regulatory Reports'),
            const SizedBox(height: 8),
            _buildReportsSection(),
            const SizedBox(height: 20),

            // 6. Compliance Trends
            _buildSectionTitle('Compliance Trends'),
            const SizedBox(height: 8),
            _buildTrendsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Section title ──────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  1. OVERALL COMPLIANCE SCORE (TOP CARD)
  // ──────────────────────────────────────────────────────────
  Widget _buildOverallScoreCard() {
    final score = (_categoryData['overall_score'] as num?)?.toDouble() ?? 0;
    final risk = _riskLabel(score);
    final riskCol = _riskColor(score);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Date range selector
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _rangeChip('Last 30 days', _DateRange.last30),
                _rangeChip('Last quarter', _DateRange.lastQuarter),
                _rangeChip('Last year', _DateRange.lastYear),
                _rangeChip('Custom', _DateRange.custom),
              ],
            ),
            const SizedBox(height: 20),
            // Circular score + risk badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(riskCol),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${score.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold, color: riskCol),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: riskCol.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              risk,
                              style: TextStyle(color: riskCol, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Summary stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statRow('Total Carers', '${_categoryData['carer_count'] ?? 0}'),
                      const SizedBox(height: 6),
                      _statRow('Period Start', DateFormat.yMMMd().format(_range.start)),
                      const SizedBox(height: 6),
                      _statRow('Period End', DateFormat.yMMMd().format(_range.end)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(String label, _DateRange value) {
    final selected = _selectedRange == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
      selected: selected,
      selectedColor: Theme.of(context).colorScheme.primary,
      onSelected: (_) => _onRangeChanged(value),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  //  2. CATEGORY SCORES (GRID OF 16 CARDS)
  // ──────────────────────────────────────────────────────────
  Widget _buildCategoryGrid() {
    final scores = _categoryData['category_scores'] as Map<String, dynamic>? ?? {};
    final columns = _gridColumns(context);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _kCategories.length,
      itemBuilder: (context, i) => _buildCategoryCard(_kCategories[i], scores),
    );
  }

  int _gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 4;
    if (w >= 800) return 3;
    if (w >= 500) return 2;
    return 2;
  }

  Widget _buildCategoryCard(_CategoryDef cat, Map<String, dynamic> scores) {
    final score = (scores[cat.key] as num?)?.toDouble() ?? 0;
    final color = _scoreColor(score);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Future: navigate to category detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${cat.label}: ${score.toStringAsFixed(1)}%')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status ring
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 5,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Text(
                      '${score.round()}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cat.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Icon(cat.icon, size: 14, color: color.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  3. RECENT COMPLIANCE FLAGS
  // ──────────────────────────────────────────────────────────
  Widget _buildFlagsSection() {
    final openFlags = _flags.where((f) => f.status != 'resolved').toList();

    if (openFlags.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No open compliance flags 🎉')),
        ),
      );
    }

    return Column(
      children: openFlags.take(10).map((flag) => _buildFlagTile(flag)).toList(),
    );
  }

  Widget _buildFlagTile(ComplianceFlag flag) {
    Color sevCol;
    IconData sevIcon;
    switch (flag.severity) {
      case 'CRITICAL':
        sevCol = Colors.red;
        sevIcon = Icons.error;
        break;
      case 'WARNING':
        sevCol = Colors.orange;
        sevIcon = Icons.warning;
        break;
      default:
        sevCol = Colors.blue;
        sevIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(sevIcon, color: sevCol, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flag.ruleName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: sevCol.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    flag.severity,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sevCol),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(flag.message, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                if (flag.carerId != null)
                  Text('Carer: ${flag.carerId}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const Spacer(),
                Text(
                  DateFormat.yMMMd().add_jm().format(flag.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Action buttons
            Row(
              children: [
                _actionButton('Acknowledge', Icons.check, Colors.blue, () async {
                  await _svc.updateComplianceFlagStatus(flag.id, 'investigating', null, null);
                  _loadAll();
                }),
                const SizedBox(width: 8),
                _actionButton('Resolve', Icons.done_all, Colors.green, () async {
                  await _svc.resolveComplianceFlag(flag.id, 'admin', 'Resolved from dashboard');
                  _loadAll();
                }),
                const SizedBox(width: 8),
                _actionButton('Escalate', Icons.arrow_upward, Colors.deepOrange, () async {
                  await _svc.escalateComplianceIssue(flag.id, 'admin', 'Escalated from dashboard');
                  _loadAll();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 30,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label: Text(label, style: TextStyle(fontSize: 11, color: color)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  4. TEACHING MOMENTS
  // ──────────────────────────────────────────────────────────
  Widget _buildTeachingSection() {
    if (_teachingMoments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No teaching moments')),
        ),
      );
    }

    final pending = _teachingMoments.where((m) => m.quizPassed != true).toList();
    final completed = _teachingMoments.where((m) => m.quizPassed == true).toList();
    final total = _teachingMoments.length;
    final completionRate = total > 0 ? (completed.length * 100.0 / total) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary row
            Row(
              children: [
                _miniStat('Pending', '${pending.length}', Colors.orange),
                const SizedBox(width: 16),
                _miniStat('Completed', '${completed.length}', Colors.green),
                const SizedBox(width: 16),
                _miniStat('Rate', '${completionRate.toStringAsFixed(0)}%', Colors.blue),
              ],
            ),
            const Divider(height: 24),
            // Pending list
            if (pending.isEmpty)
              const Text('All teaching moments completed!', style: TextStyle(color: Colors.green))
            else
              ...pending.take(5).map((m) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.school, size: 18, color: Colors.orange),
                    ),
                    title: Text(m.title, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      m.quizRequired ? 'Quiz required' : 'No quiz',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      DateFormat.yMMMd().format(m.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  //  5. REGULATORY REPORTS
  // ──────────────────────────────────────────────────────────
  Widget _buildReportsSection() {
    if (_reports.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No regulatory reports')),
        ),
      );
    }

    return Column(
      children: _reports.take(5).map((r) => _buildReportTile(r)).toList(),
    );
  }

  Widget _buildReportTile(RegulatoryReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: report.submitted ? Colors.green.shade50 : Colors.blue.shade50,
          child: Icon(
            report.submitted ? Icons.check_circle : Icons.description,
            color: report.submitted ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          '${report.reportType} Report',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${DateFormat.yMMMd().format(report.reportingPeriodStart)} – ${DateFormat.yMMMd().format(report.reportingPeriodEnd)}\nGenerated: ${DateFormat.yMMMd().add_jm().format(report.generatedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              tooltip: 'View',
              onPressed: () {
                // Future: open report viewer
              },
            ),
            if (!report.submitted)
              IconButton(
                icon: const Icon(Icons.send, size: 20, color: Colors.blue),
                tooltip: 'Submit to regulator',
                onPressed: () async {
                  await _svc.submitRegulatoryReport(report.id);
                  _loadAll();
                },
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  6. COMPLIANCE TRENDS (LINE CHART)
  // ──────────────────────────────────────────────────────────
  Widget _buildTrendsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interval toggles
            Row(
              children: [
                _trendChip('Weekly', 'weekly'),
                const SizedBox(width: 8),
                _trendChip('Monthly', 'monthly'),
                const SizedBox(width: 8),
                _trendChip('Quarterly', 'quarterly'),
              ],
            ),
            const SizedBox(height: 16),
            if (_trends.isEmpty)
              const SizedBox(
                height: 200,
                child: Center(child: Text('No trend data available')),
              )
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  _buildChartData(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _trendChip(String label, String value) {
    final selected = _trendInterval == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
      selected: selected,
      selectedColor: Theme.of(context).colorScheme.primary,
      onSelected: (_) {
        setState(() => _trendInterval = value);
        _loadAll();
      },
    );
  }

  LineChartData _buildChartData() {
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (var i = 0; i < _trends.length; i++) {
      final avg = (_trends[i]['avg_score'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), avg));
      final periodStr = _trends[i]['period']?.toString() ?? '';
      if (periodStr.isNotEmpty) {
        try {
          final d = DateTime.parse(periodStr);
          labels.add(DateFormat.MMMd().format(d));
        } catch (_) {
          labels.add(periodStr.substring(0, math.min(periodStr.length, 8)));
        }
      } else {
        labels.add('');
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 20,
            getTitlesWidget: (value, meta) => Text(
              '${value.round()}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
              if (_trends.length > 12 && idx % 2 != 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(labels[idx], style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: _trends.length <= 20,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(radius: 3, color: Theme.of(context).colorScheme.primary),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((ts) {
              final idx = ts.x.toInt();
              final flagCount = idx < _trends.length
                  ? (_trends[idx]['flag_count'] as num?)?.toInt() ?? 0
                  : 0;
              return LineTooltipItem(
                '${ts.y.toStringAsFixed(1)}%\n$flagCount flags',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}