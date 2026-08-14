import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/care_plan_audit.dart';
import 'package:admin_app/services/care_plan_audit_service.dart';
import 'package:admin_app/ui/audit/careplan_audit_form.dart';

class CarePlanAuditScreen extends StatefulWidget {
  const CarePlanAuditScreen({super.key});

  @override
  State<CarePlanAuditScreen> createState() => _CarePlanAuditScreenState();
}

class _CarePlanAuditScreenState extends State<CarePlanAuditScreen> {
  final _service = CarePlanAuditService(Supabase.instance.client);

  List<Map<String, dynamic>> _serviceUsers = [];
  String? _filterServiceUserId;
  String _filterStatus = 'all';
  String _filterRiskLevel = 'all';

  List<CarePlanAudit> _audits = [];
  bool _isLoading = true;

  final _statusOptions = ['all', 'draft', 'completed', 'action_required', 'clinical_review', 'manager_review'];
  final _riskLevelOptions = ['all', 'low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    _loadAudits();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final users = await _service.getServiceUsers();
      setState(() => _serviceUsers = users);
    } catch (_) {}
  }

  Future<void> _loadAudits() async {
    setState(() => _isLoading = true);
    try {
      final audits = await _service.getAudits(
        serviceUserId: _filterServiceUserId,
        status: _filterStatus,
        riskLevel: _filterRiskLevel,
      );
      setState(() { _audits = audits; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToForm({CarePlanAudit? audit}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CarePlanAuditFormView(audit: audit)),
    );
    if (result == true) _loadAudits();
  }

  Future<void> _deleteAudit(CarePlanAudit audit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Audit'),
        content: Text('Delete audit for ${audit.serviceUserName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && audit.id != null) {
      try {
        await _service.deleteAudit(audit.id!);
        _loadAudits();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Care Plan Audits'), backgroundColor: const Color(0xFF1976D2), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAudits),
      ]),
      body: Column(children: [
        _buildFilters(),
        const Divider(height: 1),
        Expanded(child: _buildList()),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          SizedBox(width: 180, child: DropdownButtonFormField<String>(
            value: _filterServiceUserId,
            decoration: const InputDecoration(labelText: 'Service User', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), isDense: true),
            items: [const DropdownMenuItem(value: null, child: Text('All')), ..._serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String, overflow: TextOverflow.ellipsis)))],
            onChanged: (v) { setState(() => _filterServiceUserId = v); _loadAudits(); },
          )),
          const SizedBox(width: 8),
          SizedBox(width: 150, child: DropdownButtonFormField<String>(
            value: _filterStatus,
            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), isDense: true),
            items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s == 'all' ? 'All' : s.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')))).toList(),
            onChanged: (v) { setState(() => _filterStatus = v!); _loadAudits(); },
          )),
          const SizedBox(width: 8),
          SizedBox(width: 150, child: DropdownButtonFormField<String>(
            value: _filterRiskLevel,
            decoration: const InputDecoration(labelText: 'Risk Level', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), isDense: true),
            items: _riskLevelOptions.map((r) => DropdownMenuItem(value: r, child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (r != 'all') ...[Icon(CarePlanAuditRiskHelper.getRiskIcon(r), size: 14, color: CarePlanAuditRiskHelper.getRiskColor(r)), const SizedBox(width: 4)],
              Text(r == 'all' ? 'All' : CarePlanAuditRiskHelper.getRiskLabel(r)),
            ]))).toList(),
            onChanged: (v) { setState(() => _filterRiskLevel = v!); _loadAudits(); },
          )),
        ]),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_audits.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.assignment, size: 64, color: Colors.grey), SizedBox(height: 16),
      Text('No care plan audits found', style: TextStyle(color: Colors.grey, fontSize: 16)),
      SizedBox(height: 8), Text('Tap + to create a new audit', style: TextStyle(color: Colors.grey, fontSize: 14)),
    ]));

    return RefreshIndicator(
      onRefresh: _loadAudits,
      child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: _audits.length, itemBuilder: (_, i) => _buildCard(_audits[i])),
    );
  }

  Widget _buildCard(CarePlanAudit audit) {
    final rc = CarePlanAuditRiskHelper.getRiskColor(audit.riskLevel);
    final ri = CarePlanAuditRiskHelper.getRiskIcon(audit.riskLevel);
    final pct = audit.overallPercentage ?? 0;

    return Card(margin: const EdgeInsets.symmetric(vertical: 4), child: InkWell(
      onTap: () => _navigateToForm(audit: audit),
      child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: rc.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: rc, width: 2)),
          child: Center(child: Text('${pct.round()}%', style: TextStyle(color: rc, fontWeight: FontWeight.bold, fontSize: 13)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(audit.serviceUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(DateFormat('dd MMM yyyy').format(audit.auditDate), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: rc.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(ri, size: 12, color: rc), const SizedBox(width: 2),
                Text(CarePlanAuditRiskHelper.getRiskBadge(audit.riskLevel), style: TextStyle(color: rc, fontSize: 10, fontWeight: FontWeight.bold)),
              ])),
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statusColor(audit.status).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(audit.status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '), style: TextStyle(color: _statusColor(audit.status), fontSize: 10, fontWeight: FontWeight.bold))),
            if (audit.criticalFlagsCount > 0) ...[const SizedBox(width: 6), Icon(Icons.flag, size: 14, color: Colors.red)],
          ]),
        ])),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ])),
    ));
  }

  Color _statusColor(String? s) {
    switch (s) { case 'draft': return Colors.grey; case 'completed': return Colors.green; case 'action_required': return Colors.red; case 'clinical_review': return Colors.blue; case 'manager_review': return Colors.purple; default: return Colors.grey; }
  }
}