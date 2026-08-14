import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/models/visit.dart';
import 'package:admin_app/services/database_service.dart';

class VisitListScreen extends StatefulWidget {
  const VisitListScreen({super.key});

  @override
  State<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen> {
  List<Visit> _visits = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = context.read<DatabaseService>();
      final data = await db.getVisits();
      setState(() {
        _visits = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visits'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading visits: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _visits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No visits found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _visits.length,
                        itemBuilder: (context, index) {
                          final visit = _visits[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: visit.checkOutTime != null
                                    ? Colors.green
                                    : visit.checkInTime != null
                                        ? Colors.orange
                                        : Colors.grey,
                                child: Icon(
                                  visit.checkOutTime != null
                                      ? Icons.check_circle
                                      : visit.checkInTime != null
                                          ? Icons.play_arrow
                                          : Icons.schedule,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text('Visit ${index + 1}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Check-in: ${visit.checkInTime != null ? _formatDateTime(visit.checkInTime!) : 'Not checked in'}',
                                    style: TextStyle(
                                      color: visit.checkInTime != null
                                          ? Colors.green[700]
                                          : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Check-out: ${visit.checkOutTime != null ? _formatDateTime(visit.checkOutTime!) : 'Not checked out'}',
                                    style: TextStyle(
                                      color: visit.checkOutTime != null
                                          ? Colors.green[700]
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (visit.notes.isNotEmpty)
                                    Text(
                                      'Notes: ${visit.notes}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              isThreeLine: visit.notes.isNotEmpty,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}