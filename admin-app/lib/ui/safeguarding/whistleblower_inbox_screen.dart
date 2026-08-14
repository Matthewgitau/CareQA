import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:admin_app/services/safeguarding_service.dart';
import 'package:admin_app/models/whistleblower_report.dart';

class WhistleblowerInboxScreen extends StatefulWidget {
  const WhistleblowerInboxScreen({super.key});

  @override
  State<WhistleblowerInboxScreen> createState() => _WhistleblowerInboxScreenState();
}

class _WhistleblowerInboxScreenState extends State<WhistleblowerInboxScreen> {
  late SafeguardingService _svc;
  bool _isLoading = true;
  List<WhistleblowerReport> _reports = [];
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _svc = Provider.of<SafeguardingService>(context, listen: false);
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final data = await _svc.getWhistleblowerReports();
      if (!mounted) return;
      setState(() {
        _reports = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<WhistleblowerReport> get _filteredReports {
    if (_statusFilter == 'all') return _reports;
    return _reports.where((r) => r.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // ── Status filter chips ────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all'),
                _filterChip('Pending', 'pending'),
                _filterChip('Under Review', 'under_review'),
                _filterChip('Investigating', 'investigating'),
                _filterChip('Actioned', 'actioned'),
                _filterChip('Dismissed', 'dismissed'),
              ],
            ),
          ),
        ),

        // ── Summary bar ────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${_filteredReports.length} report(s)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              if (_reports.where((r) => r.status == 'pending').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_reports.where((r) => r.status == 'pending').length} pending',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                  ),
                ),
            ],
          ),
        ),

        // ── Report list ────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadReports,
            child: _filteredReports.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.record_voice_over, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No whistleblower reports', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filteredReports.length,
                    itemBuilder: (ctx, i) => _buildReportCard(_filteredReports[i]),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Filter chip ──────────────────────────────────────
  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
        selected: selected,
        selectedColor: Theme.of(context).colorScheme.primary,
        onSelected: (_) => setState(() => _statusFilter = value),
      ),
    );
  }

  // ─── Report card ──────────────────────────────────────
  Widget _buildReportCard(WhistleblowerReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showReportDetail(report),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Reference
                  if (report.reportReference != null)
                    Text(
                      report.reportReference!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  const Spacer(),
                  // Priority badge
                  _priorityBadge(report.priority),
                ],
              ),
              const SizedBox(height: 6),

              // Category & date
              Row(
                children: [
                  _categoryBadge(report.categoryDisplayName),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd().format(report.reportDate),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  // Anonymous indicator
                  if (report.anonymous)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text('Anonymous', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Description preview
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),

              // Status & action row
              Row(
                children: [
                  _statusBadge(report.status),
                  const Spacer(),
                  if (report.status == 'pending')
                    _smallButton('Review', Colors.blue, () => _showReportDetail(report)),
                  if (report.status == 'under_review' || report.status == 'investigating')
                    _smallButton('Action', Colors.green, () => _showActionDialog(report)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    Color col;
    switch (priority) {
      case 'urgent':
        col = Colors.red;
        break;
      case 'high':
        col = Colors.deepOrange;
        break;
      case 'medium':
        col = Colors.orange;
        break;
      default:
        col = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: col.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(priority, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col)),
    );
  }

  Widget _categoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(category, style: TextStyle(fontSize: 10, color: Colors.purple.shade700)),
    );
  }

  Widget _statusBadge(String status) {
    Color col;
    switch (status) {
      case 'actioned':
        col = Colors.green;
        break;
      case 'investigating':
        col = Colors.orange;
        break;
      case 'pending':
        col = Colors.red;
        break;
      case 'dismissed':
        col = Colors.grey;
        break;
      default:
        col = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: col.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col)),
    );
  }

  Widget _smallButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: color)),
      ),
    );
  }

  // ─── Report Detail Dialog ─────────────────────────────
  void _showReportDetail(WhistleblowerReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reference & status
            Row(
              children: [
                if (report.reportReference != null)
                  Text(report.reportReference!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                _priorityBadge(report.priority),
                const SizedBox(width: 6),
                _statusBadge(report.status),
              ],
            ),
            const SizedBox(height: 12),

            // Info
            _detailRow('Date Reported', DateFormat.yMMMd().format(report.reportDate)),
            _detailRow('Category', report.categoryDisplayName),
            if (report.location != null) _detailRow('Location', report.location!),
            if (report.serviceUserName != null)
              _detailRow('Service User', report.serviceUserName!),
            if (report.carerName != null) _detailRow('Carer', report.carerName!),
            if (report.dateTimeOccurred != null)
              _detailRow('Date/Time Occurred', DateFormat.yMMMd().add_jm().format(report.dateTimeOccurred!)),
            if (report.witnesses != null) _detailRow('Witnesses', report.witnesses!),

            const Divider(height: 24),

            // Description
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text(report.description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),

            // Evidence
            if (report.evidenceProvided) ...[
              const Text('Evidence',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(report.evidenceDetails ?? 'Provided', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
            ],

            // Internal notes
            if (report.reviewNotes != null) ...[
              const Text('Internal Review Notes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(report.reviewNotes!, style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            // Investigation outcome
            if (report.investigationOutcome != null) ...[
              const Text('Investigation Outcome',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(report.investigationOutcome!, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
            ],

            // Actions taken
            if (report.actionsTaken != null) ...[
              const Text('Actions Taken',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(report.actionsTaken!, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
            ],

            // Feedback to reporter
            if (report.feedbackToReporter != null) ...[
              const Text('Feedback to Reporter (Anonymized)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(report.feedbackToReporter!, style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            // ── Action buttons ──────────────────
            const Divider(height: 24),
            Row(
              children: [
                if (report.status == 'pending') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _assignReport(report);
                      },
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Assign'),
                    ),
                  ),
                ],
                if (report.status == 'under_review' || report.status == 'investigating') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showActionDialog(report);
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Action'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _updatePriority(report);
                      },
                      icon: const Icon(Icons.flag, size: 18),
                      label: const Text('Priority'),
                    ),
                  ),
                ],
                if (report.status == 'actioned') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _archiveReport(report);
                      },
                      icon: const Icon(Icons.archive, size: 18),
                      label: const Text('Archive'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ─── Assign dialog ─────────────────────────────────────
  Future<void> _assignReport(WhistleblowerReport report) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Report'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Assign to (staff ID or name)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _svc.assignWhistleblowerReport(report.id, result);
      _loadReports();
    }
  }

  // ─── Action dialog ─────────────────────────────────────
  Future<void> _showActionDialog(WhistleblowerReport report) async {
    final outcomeCtrl = TextEditingController(text: report.investigationOutcome ?? '');
    final actionsCtrl = TextEditingController(text: report.actionsTaken ?? '');
    final notesCtrl = TextEditingController(text: report.reviewNotes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Investigation Outcome'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: outcomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Investigation Outcome',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: actionsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Actions Taken',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Review Notes (internal)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _svc.actionWhistleblowerReport(
        report.id,
        outcome: outcomeCtrl.text,
        actions: actionsCtrl.text,
        reviewNotes: notesCtrl.text,
      );
      _loadReports();
    }
  }

  // ─── Priority update ───────────────────────────────────
  Future<void> _updatePriority(WhistleblowerReport report) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Set Priority'),
        children: ['low', 'medium', 'high', 'urgent'].map((p) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, p),
            child: Text(p.toUpperCase()),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      await _svc.updateWhistleblowerReport(report.id, {'priority': result});
      _loadReports();
    }
  }

  // ─── Archive ───────────────────────────────────────────
  Future<void> _archiveReport(WhistleblowerReport report) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Report'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Archive reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'archived'),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _svc.archiveWhistleblowerReport(report.id, reason: result);
      _loadReports();
    }
  }
}