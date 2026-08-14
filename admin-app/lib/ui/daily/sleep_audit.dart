import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/sleep_service.dart';
import 'package:admin_app/models/sleep_chart.dart';

class SleepAuditScreen extends StatefulWidget {
  final String chartId;

  const SleepAuditScreen({
    Key? key,
    required this.chartId,
  }) : super(key: key);

  @override
  _SleepAuditScreenState createState() => _SleepAuditScreenState();
}

class _SleepAuditScreenState extends State<SleepAuditScreen> {
  final _sleepService = SleepService(Supabase.instance.client);
  List<SleepAuditLog> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      _auditLogs = await _sleepService.getAuditLog(widget.chartId);
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

  Widget _buildAuditEntry(SleepAuditLog log) {
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

  Widget _buildChangesSummary(SleepAuditLog log) {
    final changes = <String>[];

    // Check for specific field changes
    if (log.previousData.containsKey('bedtime_time') && log.newData.containsKey('bedtime_time')) {
      final prevTime = log.previousData['bedtime_time'] as String?;
      final newTime = log.newData['bedtime_time'] as String?;
      if (prevTime != newTime) {
        changes.add('Bedtime: $prevTime → $newTime');
      }
    }

    if (log.previousData.containsKey('bedtime_routine') && log.newData.containsKey('bedtime_routine')) {
      final prevRoutine = log.previousData['bedtime_routine'] as String?;
      final newRoutine = log.newData['bedtime_routine'] as String?;
      if (prevRoutine != newRoutine) {
        changes.add('Bedtime routine updated');
      }
    }

    if (log.previousData.containsKey('sleep_quality') && log.newData.containsKey('sleep_quality')) {
      final prevQuality = log.previousData['sleep_quality'] as String?;
      final newQuality = log.newData['sleep_quality'] as String?;
      if (prevQuality != newQuality) {
        changes.add('Sleep Quality: $prevQuality → $newQuality');
      }
    }

    if (log.previousData.containsKey('morning_notes') && log.newData.containsKey('morning_notes')) {
      final prevNotes = log.previousData['morning_notes'] as String?;
      final newNotes = log.newData['morning_notes'] as String?;
      if (prevNotes != newNotes) {
        changes.add('Morning notes updated');
      }
    }

    // Check for overnight entry changes
    if (log.previousData.containsKey('overnight_entries') && log.newData.containsKey('overnight_entries')) {
      final prevEntries = (log.previousData['overnight_entries'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      final newEntries = (log.newData['overnight_entries'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      
      for (int i = 0; i < newEntries.length; i++) {
        if (i < prevEntries.length) {
          final prevEntry = prevEntries[i];
          final newEntry = newEntries[i];
          
          if (prevEntry['status'] != newEntry['status']) {
            changes.add('Observation ${i + 1}: ${prevEntry['status']} → ${newEntry['status']}');
          }
          if (prevEntry['notes'] != newEntry['notes']) {
            changes.add('Observation ${i + 1}: Notes updated');
          }
        } else {
          changes.add('Observation ${i + 1}: Added');
        }
      }
      
      if (newEntries.length < prevEntries.length) {
        changes.add('Observation removed');
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
        if (data.containsKey('bedtime_time'))
          Text('Bedtime: ${data['bedtime_time'] ?? 'Not set'}'),
        if (data.containsKey('bedtime_routine') && data['bedtime_routine'] != null)
          Text('Bedtime Routine: ${data['bedtime_routine']}'),
        if (data.containsKey('sleep_quality'))
          Text('Sleep Quality: ${data['sleep_quality'] ?? 'Not set'}'),
        if (data.containsKey('morning_notes') && data['morning_notes'] != null)
          Text('Morning Notes: ${data['morning_notes']}'),
        if (data.containsKey('overnight_entries'))
          _buildOvernightEntriesList(data['overnight_entries'] as List),
      ],
    );
  }

  Widget _buildOvernightEntriesList(List entries) {
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
                'Observation: ${_formatTime(DateTime.parse(entryData['time']))} - ${entryData['status']}',
                style: const TextStyle(fontSize: 12),
              ),
              if (entryData['notes'] != null && entryData['notes'].isNotEmpty)
                Text(
                  '  Notes: ${entryData['notes']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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