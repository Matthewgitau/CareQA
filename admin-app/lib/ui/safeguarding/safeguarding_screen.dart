import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:admin_app/ui/safeguarding/incident_detail_screen.dart';
import 'package:admin_app/ui/safeguarding/whistleblower_inbox_screen.dart';

class SafeguardingScreen extends StatefulWidget {
  const SafeguardingScreen({super.key});
  @override
  State<SafeguardingScreen> createState() => _SafeguardingScreenState();
}

class _SafeguardingScreenState extends State<SafeguardingScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;
  TabController? _tabController;

  // Raw data from each table
  List<Map<String, dynamic>> _accidents = [];
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _medicationIncidents = [];
  List<Map<String, dynamic>> _missingPersons = [];
  List<Map<String, dynamic>> _seriousIncidents = [];
  List<Map<String, dynamic>> _missingItems = [];
  List<Map<String, dynamic>> _whistleblowerReports = [];

  // Filters for Tab 3 (All Logs)
  String? _filterType;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // ─── Real Data Loading ─────────────────────────────────
  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _client
            .from('accident_logs')
            .select('*, service_users(name)')
            .order('accident_date', ascending: false)
            .limit(20),
        _client
            .from('complaints_logs')
            .select('*, service_users(name)')
            .order('complaint_date', ascending: false)
            .limit(20),
        _client
            .from('medication_incidents')
            .select('*, service_users(name)')
            .order('incident_date', ascending: false)
            .limit(20),
        _client
            .from('missing_persons')
            .select('*, service_users(name)')
            .order('missing_date', ascending: false)
            .limit(20),
        _client
            .from('serious_incidents')
            .select('*, service_users(name)')
            .order('incident_date', ascending: false)
            .limit(20),
        _client
            .from('missing_items')
            .select('*, service_users(name)')
            .order('missing_date', ascending: false)
            .limit(20),
        _client
            .from('whistleblower_reports')
            .select()
            .order('created_at', ascending: false)
            .limit(20),
      ]);
      if (!mounted) return;
      setState(() {
        _accidents = List<Map<String, dynamic>>.from(results[0]);
        _complaints = List<Map<String, dynamic>>.from(results[1]);
        _medicationIncidents = List<Map<String, dynamic>>.from(results[2]);
        _missingPersons = List<Map<String, dynamic>>.from(results[3]);
        _seriousIncidents = List<Map<String, dynamic>>.from(results[4]);
        _missingItems = List<Map<String, dynamic>>.from(results[5]);
        _whistleblowerReports = List<Map<String, dynamic>>.from(results[6]);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ─── Computed counts ───────────────────────────────────
  int _openCount(List<Map<String, dynamic>> list) =>
      list.where((i) => i['status'] != 'resolved' && i['status'] != 'closed').length;

  int get _criticalCount {
    return _seriousIncidents
        .where((i) => i['status'] != 'resolved' && i['status'] != 'closed')
        .length;
  }

  bool get _needsCqcNotification =>
      _seriousIncidents
          .any((i) => i['status'] != 'resolved' && i['status'] != 'closed');

  int get _pendingWhistleblowers =>
      _whistleblowerReports.where((r) => r['status'] == 'pending').length;

  // ─── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safeguarding Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Whistleblower', icon: Icon(Icons.record_voice_over)),
            Tab(text: 'All Logs', icon: Icon(Icons.list_alt)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                const WhistleblowerInboxScreen(),
                _buildAllLogsTab(),
              ],
            ),
      floatingActionButton: _buildFab(),
    );
  }

  // ─── Skeleton ──────────────────────────────────────────
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── FAB + Add Menu ────────────────────────────────────
  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _showAddIncidentMenu,
      icon: const Icon(Icons.add),
      label: const Text('New Incident'),
    );
  }

  void _showAddIncidentMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx2, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _addOption(Icons.warning_amber, 'Accident', Colors.red, 'accident'),
              _addOption(Icons.thumb_down, 'Complaint', Colors.orange, 'complaint'),
              _addOption(Icons.medication, 'Medication Incident', Colors.purple, 'medication'),
              _addOption(Icons.person_search, 'Missing Person', Colors.blue, 'missing_person'),
              _addOption(Icons.error_outline, 'Serious Incident', Colors.red.shade800, 'serious'),
              _addOption(Icons.inventory_2, 'Missing Item', Colors.teal, 'missing_item'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addOption(IconData icon, String label, Color color, String type) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        _addIncident(type);
      },
    );
  }

  void _addIncident(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentDetailScreen(
          incidentType: type,
          mode: 'create',
        ),
      ),
    ).then((_) => _loadAll());
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: DASHBOARD (Summary Cards + Open Incidents)
  // ═══════════════════════════════════════════════════════
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Critical alerts
            if (_criticalCount > 0) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$_criticalCount critical incident(s) requiring immediate attention',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Summary cards grid
            GridView.count(
              crossAxisCount: _gridColumns(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _summaryCard('Accidents', _openCount(_accidents), Colors.red,
                    Icons.warning_amber, 'accident'),
                _summaryCard('Complaints', _openCount(_complaints), Colors.orange,
                    Icons.thumb_down_alt, 'complaint'),
                _summaryCard('Medication', _openCount(_medicationIncidents),
                    Colors.purple, Icons.medication, 'medication'),
                _summaryCard('Missing Persons', _openCount(_missingPersons),
                    Colors.blue, Icons.person_search, 'missing_person'),
                _summaryCard('Serious Incidents', _openCount(_seriousIncidents),
                    Colors.red.shade800, Icons.error_outline, 'serious'),
                _summaryCard('Missing Items', _openCount(_missingItems),
                    Colors.teal, Icons.inventory_2, 'missing_item'),
                _summaryCard('Whistleblowers', _pendingWhistleblowers,
                    Colors.indigo, Icons.record_voice_over, 'whistleblower'),
              ],
            ),
            const SizedBox(height: 20),

            // CQC compliance alert
            if (_needsCqcNotification)
              _buildComplianceAlert(
                'CQC Notification Required',
                'Some incidents require CQC notification within 24 hours.',
                Colors.red,
              ),

            // Combined open incidents list
            const SizedBox(height: 16),
            const Text('Recent Open Incidents',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._buildCombinedIncidentList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCombinedIncidentList() {
    // Merge all open incidents into a single sorted list
    final all = <_MergedIncident>[];

    for (final a in _accidents) {
      if (a['status'] != 'resolved' && a['status'] != 'closed') {
        all.add(_MergedIncident(
          type: 'accident',
          title: 'Accident',
          date: _tryParse(a['accident_date']),
          description: a['description']?.toString() ?? '',
          status: a['status']?.toString() ?? 'open',
          data: a,
          table: 'accident_logs',
        ));
      }
    }
    for (final c in _complaints) {
      if (c['status'] != 'resolved' && c['status'] != 'closed') {
        all.add(_MergedIncident(
          type: 'complaint',
          title: 'Complaint',
          date: _tryParse(c['complaint_date']),
          description: c['description']?.toString() ?? '',
          status: c['status']?.toString() ?? 'open',
          data: c,
          table: 'complaints_logs',
        ));
      }
    }
    for (final m in _medicationIncidents) {
      if (m['status'] != 'resolved' && m['status'] != 'closed') {
        all.add(_MergedIncident(
          type: 'medication',
          title: 'Medication Incident',
          date: _tryParse(m['incident_date']),
          description: m['description']?.toString() ?? '',
          status: m['status']?.toString() ?? 'open',
          data: m,
          table: 'medication_incidents',
        ));
      }
    }
    for (final mp in _missingPersons) {
      if (mp['status'] != 'resolved' && mp['status'] != 'closed') {
        all.add(_MergedIncident(
          type: 'missing_person',
          title: 'Missing Person',
          date: _tryParse(mp['missing_date']),
          description: mp['circumstances']?.toString() ?? '',
          status: mp['status']?.toString() ?? 'open',
          data: mp,
          table: 'missing_persons',
        ));
      }
    }
    for (final si in _seriousIncidents) {
      if (si['status'] != 'resolved' && si['status'] != 'closed') {
        all.add(_MergedIncident(
          type: 'serious',
          title: 'Serious Incident',
          date: _tryParse(si['incident_date']),
          description: si['description']?.toString() ?? '',
          status: si['status']?.toString() ?? 'open',
          data: si,
          table: 'serious_incidents',
        ));
      }
    }
    for (final mi in _missingItems) {
      if (mi['status'] != 'resolved' && mi['status'] != 'closed') {
        all.add(_MergedIncident(
          type: 'missing_item',
          title: 'Missing Item',
          date: _tryParse(mi['missing_date']),
          description: mi['item_name']?.toString() ?? '',
          status: mi['status']?.toString() ?? 'open',
          data: mi,
          table: 'missing_items',
        ));
      }
    }

    all.sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));

    if (all.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No open incidents 🎉')),
          ),
        ),
      ];
    }

    return all.take(10).map((i) => _buildMergedIncidentTile(i)).toList();
  }

  // ─── Summary card (clickable to filter Tab 3) ──────────
  Widget _summaryCard(
      String title, int count, Color color, IconData icon, String type) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _filterByType(type);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterByType(String type) {
    _tabController?.animateTo(2);
    setState(() {
      _filterType = type;
      _filterStatus = null;
    });
  }

  Widget _buildComplianceAlert(String title, String message, Color color) {
    return Card(
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.notifications_active, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: color)),
                  Text(message,
                      style: TextStyle(fontSize: 12, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMergedIncidentTile(_MergedIncident incident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _typeColor(incident.type).withOpacity(0.15),
          child: Icon(_typeIcon(incident.type),
              color: _typeColor(incident.type), size: 20),
        ),
        title: Text(incident.title,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          incident.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusChip(incident.status),
            const SizedBox(width: 4),
            Text(
              incident.date != null
                  ? DateFormat.yMMMd().format(incident.date!)
                  : 'N/A',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IncidentDetailScreen(
              incidentType: incident.type,
              mode: 'edit',
              incidentId: incident.data['id']?.toString(),
              rawData: incident.data,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 3: ALL INCIDENT LOGS (filterable)
  // ═══════════════════════════════════════════════════════
  Widget _buildAllLogsTab() {
    final filtered = _getFilteredResults();

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  value: _filterType,
                  hint: const Text('All Types',
                      style: TextStyle(fontSize: 13)),
                  items: const [
                    DropdownMenuItem(
                        value: null, child: Text('All Types')),
                    DropdownMenuItem(
                        value: 'accident', child: Text('Accident')),
                    DropdownMenuItem(
                        value: 'complaint', child: Text('Complaint')),
                    DropdownMenuItem(
                        value: 'medication', child: Text('Medication')),
                    DropdownMenuItem(
                        value: 'missing_person',
                        child: Text('Missing Person')),
                    DropdownMenuItem(
                        value: 'serious', child: Text('Serious')),
                    DropdownMenuItem(
                        value: 'missing_item',
                        child: Text('Missing Item')),
                  ],
                  onChanged: (v) => setState(() => _filterType = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  value: _filterStatus,
                  hint: const Text('All Statuses',
                      style: TextStyle(fontSize: 13)),
                  items: const [
                    DropdownMenuItem(
                        value: null, child: Text('All Statuses')),
                    DropdownMenuItem(
                        value: 'investigating',
                        child: Text('Investigating')),
                    DropdownMenuItem(
                        value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(
                        value: 'closed', child: Text('Closed')),
                    DropdownMenuItem(
                        value: 'reported', child: Text('Reported')),
                  ],
                  onChanged: (v) => setState(() => _filterStatus = v),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No incidents match the filters'))
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) =>
                        _buildMergedIncidentTile(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  List<_MergedIncident> _getFilteredResults() {
    final all = <_MergedIncident>[];

    void addAll(
        List<Map<String, dynamic>> source, String type, String title,
        String dateKey, String descKey, String table) {
      for (final item in source) {
        final itemType = type;
        if (_filterType != null && itemType != _filterType) continue;
        if (_filterStatus != null &&
            item['status']?.toString() != _filterStatus) continue;
        all.add(_MergedIncident(
          type: itemType,
          title: title,
          date: _tryParse(item[dateKey]),
          description: item[descKey]?.toString() ?? '',
          status: item['status']?.toString() ?? 'unknown',
          data: item,
          table: table,
        ));
      }
    }

    addAll(_accidents, 'accident', 'Accident', 'accident_date', 'description', 'accident_logs');
    addAll(_complaints, 'complaint', 'Complaint', 'complaint_date', 'description', 'complaints_logs');
    addAll(_medicationIncidents, 'medication', 'Medication Incident', 'incident_date', 'description', 'medication_incidents');
    addAll(_missingPersons, 'missing_person', 'Missing Person', 'missing_date', 'circumstances', 'missing_persons');
    addAll(_seriousIncidents, 'serious', 'Serious Incident', 'incident_date', 'description', 'serious_incidents');
    addAll(_missingItems, 'missing_item', 'Missing Item', 'missing_date', 'item_name', 'missing_items');

    all.sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));
    return all;
  }

  // ─── Helpers ──────────────────────────────────────────
  int _gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 4;
    if (w >= 800) return 3;
    return 2;
  }

  Widget _statusChip(String status) {
    Color col;
    switch (status) {
      case 'resolved':
      case 'closed':
        col = Colors.green;
        break;
      case 'investigating':
      case 'active':
        col = Colors.orange;
        break;
      case 'reported':
        col = Colors.red;
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
      child: Text(status,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: col)),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'accident':
        return Colors.red;
      case 'complaint':
        return Colors.orange;
      case 'medication':
        return Colors.purple;
      case 'missing_person':
        return Colors.blue;
      case 'serious':
        return Colors.red.shade800;
      case 'missing_item':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'accident':
        return Icons.warning_amber;
      case 'complaint':
        return Icons.thumb_down_alt;
      case 'medication':
        return Icons.medication;
      case 'missing_person':
        return Icons.person_search;
      case 'serious':
        return Icons.error_outline;
      case 'missing_item':
        return Icons.inventory_2;
      default:
        return Icons.help_outline;
    }
  }

  static DateTime? _tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Lightweight merged model for displaying incidents from multiple tables.
class _MergedIncident {
  final String type;
  final String title;
  final DateTime? date;
  final String description;
  final String status;
  final Map<String, dynamic> data;
  final String table;
  const _MergedIncident({
    required this.type,
    required this.title,
    this.date,
    required this.description,
    required this.status,
    required this.data,
    required this.table,
  });
}