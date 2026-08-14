import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/repositioning_service.dart';
import 'package:admin_app/models/repositioning_chart.dart';

class RepositioningAuditScreen extends StatefulWidget {
  final String chartId;

  const RepositioningAuditScreen({
    Key? key,
    required this.chartId,
  }) : super(key: key);

  @override
  _RepositioningAuditScreenState createState() => _RepositioningAuditScreenState();
}

class _RepositioningAuditScreenState extends State<RepositioningAuditScreen> {
  final _repositioningService = RepositioningService(Supabase.instance.client);
  List<RepositioningAuditLog> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      _auditLogs = await _repositioningService.getAuditLog(widget.chartId);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading audit logs: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAuditEntry(RepositioningAuditLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.editedByName ?? log.editedBy,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDateTime(log.editedAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.history, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 8),

            // Changes summary
            _buildChangesSummary(log),

            const SizedBox(height: 8),

            // Previous data
            if (log.previousData.isNotEmpty)
              _buildDataSection('Previous Data', log.previousData),

            const SizedBox(height: 8),

            // New data
            if (log.newData.isNotEmpty)
              _buildDataSection('New Data', log.newData),
          ],
        ),
      ),
    );
  }

  Widget _buildChangesSummary(RepositioningAuditLog log) {
    final changes = <String>[];

    // Check for specific field changes
    if (log.previousData.containsKey('entries') && log.newData.containsKey('entries')) {
      final prevEntries = (log.previousData['entries'] as List?)?.length ?? 0;
      final newEntries = (log.newData['entries'] as List?)?.length ?? 0;
      if (prevEntries != newEntries) {
        changes.add('Entries: $prevEntries → $newEntries');
      }
    }

    if (log.previousData.containsKey('total_repositions') && log.newData.containsKey('total_repositions')) {
      final prevTotal = log.previousData['total_repositions'] as int?;
      final newTotal = log.newData['total_repositions'] as int?;
      if (prevTotal != newTotal) {
        changes.add('Total Repositions: $prevTotal → $newTotal');
      }
    }

    if (log.previousData.containsKey('notes') && log.newData.containsKey('notes')) {
      final prevNotes = log.previousData['notes'] as String?;
      final newNotes = log.newData['notes'] as String?;
      if (prevNotes != newNotes) {
        changes.add('Notes updated');
      }
    }

    // Check for entry-level changes
    if (log.previousData.containsKey('entries') && log.newData.containsKey('entries')) {
      final prevEntries = (log.previousData['entries'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      final newEntries = (log.newData['entries'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      
      for (int i = 0; i < newEntries.length; i++) {
        if (i < prevEntries.length) {
          final prevEntry = prevEntries[i];
          final newEntry = newEntries[i];
          
          if (prevEntry['position_code'] != newEntry['position_code']) {
            changes.add('Entry ${i + 1}: Position ${prevEntry['position_code']} → ${newEntry['position_code']}');
          }
          if (prevEntry['skin_check'] != newEntry['skin_check']) {
            changes.add('Entry ${i + 1}: Skin Check ${prevEntry['skin_check']} → ${newEntry['skin_check']}');
          }
          if (prevEntry['staff_initials'] != newEntry['staff_initials']) {
            changes.add('Entry ${i + 1}: Staff ${prevEntry['staff_initials']} → ${newEntry['staff_initials']}');
          }
        } else {
          changes.add('Entry ${i + 1}: Added');
        }
      }
      
      if (newEntries.length < prevEntries.length) {
        changes.add('Entry removed');
      }
    }

    if (changes.isEmpty) {
      changes.add('Data updated');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: changes.map((change) => Text(change, style: const TextStyle(fontSize: 12))).toList(),
    );
  }

  Widget _buildDataSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        if (data.containsKey('entries'))
          _buildEntriesList(data['entries'] as List),
        if (data.containsKey('total_repositions'))
          Text('Total Repositions: ${data['total_repositions']}'),
        if (data.containsKey('notes') && data['notes'] != null)
          Text('Notes: ${data['notes']}'),
      ],
    );
  }

  Widget _buildEntriesList(List entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        final entryData = entry as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entry: ${_formatTime(DateTime.parse(entryData['time']))} - ${entryData['position_code']} - ${entryData['skin_check']} - ${entryData['staff_initials']}',
                style: const TextStyle(fontSize: 12),
              ),
              if (entryData['skin_check_notes'] != null && entryData['skin_check_notes'].isNotEmpty)
                Text(
                  '  Notes: ${entryData['skin_check_notes']}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuditLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _auditLogs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No audit history found', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Changes will appear here when the chart is edited'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAuditLogs,
                  child: ListView.builder(
                    itemCount: _auditLogs.length,
                    itemBuilder: (context, index) {
                      return _buildAuditEntry(_auditLogs[index]);
                    },
                  ),
                ),
    );
  }
}