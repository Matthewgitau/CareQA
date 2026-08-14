import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/services/food_fluid_service.dart';
import 'package:admin_app/models/food_fluid_chart.dart';

class FoodFluidAuditScreen extends StatefulWidget {
  final String chartId;

  const FoodFluidAuditScreen({
    super.key,
    required this.chartId,
  });

  @override
  State<FoodFluidAuditScreen> createState() => _FoodFluidAuditScreenState();
}

class _FoodFluidAuditScreenState extends State<FoodFluidAuditScreen> {
  late FoodFluidService _foodFluidService;
  List<FoodFluidAuditLog> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _foodFluidService = Provider.of<FoodFluidService>(context, listen: false);
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _foodFluidService.getAuditLog(widget.chartId);
      
      setState(() {
        _auditLogs = logs.map((log) => FoodFluidAuditLog.fromJson(log as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading audit logs: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit History'),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _auditLogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No audit history found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAuditLogs,
              child: ListView.builder(
                itemCount: _auditLogs.length,
                itemBuilder: (context, index) {
                  final log = _auditLogs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          const Icon(Icons.history, size: 20, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            log.editedByName ?? log.editedBy,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            '${log.editedAt.day}/${log.editedAt.month}/${log.editedAt.year} ${log.editedAt.hour}:${log.editedAt.minute}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Changes Made:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildChangesList(log),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildChangesList(FoodFluidAuditLog log) {
    final changes = <String>[];
    
    // Check for changes in entries
    if (log.previousData['entries'] != log.newData['entries']) {
      changes.add('Meal entries updated');
    }
    
    // Check for changes in total fluid
    if (log.previousData['total_fluid_ml'] != log.newData['total_fluid_ml']) {
      final prevTotal = log.previousData['total_fluid_ml'] ?? 0;
      final newTotal = log.newData['total_fluid_ml'] ?? 0;
      changes.add('Total fluid: $prevTotal ml → $newTotal ml');
    }
    
    // Check for changes in fluid target met
    if (log.previousData['fluid_target_met'] != log.newData['fluid_target_met']) {
      final prevTarget = log.previousData['fluid_target_met'] ?? false;
      final newTarget = log.newData['fluid_target_met'] ?? false;
      changes.add('Fluid target met: ${prevTarget ? 'Yes' : 'No'} → ${newTarget ? 'Yes' : 'No'}');
    }
    
    // Check for changes in notes
    if (log.previousData['notes'] != log.newData['notes']) {
      final prevNotes = log.previousData['notes'] ?? '';
      final newNotes = log.newData['notes'] ?? '';
      changes.add('Notes: "$prevNotes" → "$newNotes"');
    }

    // Check for deletion
    if (log.newData['deleted'] == true) {
      changes.add('Chart deleted');
    }

    if (changes.isEmpty) {
      return const Text('No specific changes identified', style: TextStyle(color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: changes.map((change) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text('• $change'),
      )).toList(),
    );
  }
}