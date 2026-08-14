import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/care_log_audit.dart';
import 'package:admin_app/services/care_log_audit_service.dart';
import 'package:admin_app/ui/audit/care_log_audit_form.dart';

class CareLogAuditScreen extends StatefulWidget {
  const CareLogAuditScreen({super.key});

  @override
  State<CareLogAuditScreen> createState() => _CareLogAuditScreenState();
}

class _CareLogAuditScreenState extends State<CareLogAuditScreen> {
  final _service = CareLogAuditService(Supabase.instance.client);

  // Filters
  List<Map<String, dynamic>> _serviceUsers = [];
  String? _filterServiceUserId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _filterStatus = 'all';
  String _filterRiskLevel = 'all';

  // Data
  List<CareLogAudit> _audits = [];
  bool _isLoading = true;

  final List<String> _statusOptions = ['all', 'draft', 'completed', 'reviewed', 'action_required'];
  final List<String> _riskLevelOptions = ['all', 'low', 'medium', 'high', 'critical'];

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
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        status: _filterStatus,
        riskLevel: _filterRiskLevel,
      );
      setState(() {
        _audits = audits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _navigateToForm({CareLogAudit? audit}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CareLogAuditForm(audit: audit),
      ),
    );
    if (result == true) {
      _loadAudits();
    }
  }

  Future<void> _deleteAudit(CareLogAudit audit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Audit'),
        content: Text('Delete audit for ${audit.serviceUserName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && audit.id != null) {
      try {
        await _service.deleteAudit(audit.id!);
        _loadAudits();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audit deleted'), backgroundColor: Colors.green),
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
        title: const Text('Care Log Audits'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAudits,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          Expanded(child: _buildAuditList()),
        ],
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Service user filter
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: _filterServiceUserId,
                decoration: const InputDecoration(
                  labelText: 'Service User',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ..._serviceUsers.map((u) => DropdownMenuItem(
                    value: u['id'] as String,
                    child: Text(u['name'] as String, overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (v) {
                  setState(() => _filterServiceUserId = v);
                  _loadAudits();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Status filter
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<String>(
                value: _filterStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
                items: _statusOptions.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s == 'all' ? 'All' : s.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')),
                )).toList(),
                onChanged: (v) {
                  setState(() => _filterStatus = v!);
                  _loadAudits();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Risk level filter
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<String>(
                value: _filterRiskLevel,
                decoration: const InputDecoration(
                  labelText: 'Risk Level',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                ),
                items: _riskLevelOptions.map((r) => DropdownMenuItem(
                  value: r,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (r != 'all') ...[
                        Icon(AuditRiskHelper.getRiskIcon(r), size: 14, color: AuditRiskHelper.getRiskColor(r)),
                        const SizedBox(width: 4),
                      ],
                      Text(r == 'all' ? 'All' : AuditRiskHelper.getRiskLabel(r)),
                    ],
                  ),
                )).toList(),
                onChanged: (v) {
                  setState(() => _filterRiskLevel = v!);
                  _loadAudits();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_audits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No audits found', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Tap + to create a new audit', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAudits,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _audits.length,
        itemBuilder: (context, index) {
          final audit = _audits[index];
          return _buildAuditCard(audit);
        },
      ),
    );
  }

  Widget _buildAuditCard(CareLogAudit audit) {
    final riskColor = AuditRiskHelper.getRiskColor(audit.riskLevel);
    final riskIcon = AuditRiskHelper.getRiskIcon(audit.riskLevel);
    final percentage = audit.overallPercentage ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _navigateToForm(audit: audit),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: riskColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${percentage.round()}%',
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audit.serviceUserName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy').format(audit.auditDate),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Risk level badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(riskIcon, size: 12, color: riskColor),
                              const SizedBox(width: 2),
                              Text(
                                AuditRiskHelper.getRiskLabel(audit.riskLevel),
                                style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(audit.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            audit.status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                            style: TextStyle(
                              color: _getStatusColor(audit.status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (audit.requiresAction) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.warning, size: 14, color: Colors.red),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'completed':
        return Colors.green;
      case 'reviewed':
        return Colors.blue;
      case 'action_required':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}