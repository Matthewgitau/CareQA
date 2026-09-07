import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_app/services/route_service.dart';
import 'package:admin_app/utils/dropdown_utils.dart';

/// A form for creating/editing a Dom Care Route cluster.
///
/// A route is a named cluster of service users that are visited in
/// a specific order (chronological by time OR manually ordered).
/// Carers are assigned to the route (primary + optional second) and
/// the driver mode tracks who was driving (for mileage attribution).
class RouteFormScreen extends StatefulWidget {
  /// The route id when editing an existing route (null = create new).
  final String? routeId;

  /// Route date for new routes (defaults to the selected day).
  final DateTime? initialDate;

  const RouteFormScreen({super.key, this.routeId, this.initialDate});

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends State<RouteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RouteService _routeService = RouteService();

  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;

  // Route details
  final _nameController = TextEditingController();
  DateTime _routeDate = DateTime.now();
  bool _ongoing = true;

  // Carers
  List<Map<String, dynamic>> _carers = [];
  String? _primaryCarerId;
  String? _secondCarerId;
  String _driverMode = 'primary'; // primary | second | both

  // Service users
  List<Map<String, dynamic>> _availableUsers = [];
  List<Map<String, dynamic>> _allUsers = []; // full list for restoring on remove
  final List<_RouteVisitDraft> _visits = [];

  bool _autoOrderByTime = true;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.routeId != null;
    _routeDate = widget.initialDate ?? DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _routeService.getCarers(),
        _routeService.getServiceUsersWithCalls(),
      ]);
      if (!mounted) return;

      setState(() {
        _carers = results[0];
        _availableUsers = List<Map<String, dynamic>>.from(results[1]);
        _allUsers = List<Map<String, dynamic>>.from(results[1]);
      });

      if (_isEdit) {
        await _loadExistingRoute();
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Failed to load: $e');
    }
  }

  Future<void> _loadExistingRoute() async {
    try {
      final route = await _routeService.getRouteWithVisits(widget.routeId!);
      if (route == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showError('Route not found');
        return;
      }

      if (!mounted) return;
      setState(() {
        _nameController.text = route['name'] as String? ?? '';
        _routeDate = DateTime.tryParse(route['route_date'] ?? '') ?? DateTime.now();
        _primaryCarerId = route['carer_id'] as String?;
        _secondCarerId = route['second_carer_id'] as String?;
        _driverMode = route['driver_mode'] as String? ?? 'primary';

        // Load existing visits
        final routeVisits = route['route_visits'] as List? ?? [];
        _visits.clear();
        for (final v in routeVisits.cast<Map<String, dynamic>>()) {
          final suId = v['service_user_id'] as String? ?? '';
          final suName = (v['service_users'] is Map<String, dynamic>)
              ? (v['service_users'] as Map<String, dynamic>)['name'] as String?
              : null;
          _visits.add(_RouteVisitDraft(
            id: v['id'] as String?,
            serviceUserId: suId,
            serviceUserName: suName ?? 'Unknown',
            visitTime: DateTime.tryParse(v['visit_time'] ?? '') ?? DateTime.now(),
            durationMinutes: v['duration_minutes'] as int? ?? 60,
            notes: v['notes'] as String?,
          ));
        }

        // Remove already-assigned users from available list
        final assignedIds = _visits.map((v) => v.serviceUserId).toSet();
        _availableUsers.removeWhere((u) => assignedIds.contains(u['id']));

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Failed to load route: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  

  /// Adds a service user to the route using their FULL weekly timetable
  /// (all 7 weekdays, each with its own time + duration).
  void _addServiceUser(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final userName = user['name'] as String? ?? 'Unknown';
    final weekly = user['weekly_calls'] as Map<int, List<Map<String, dynamic>>>? ?? const {};

    setState(() {
      var added = 0;
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
        final slots = weekly[weekday] ?? const <Map<String, dynamic>>[];
        for (final slot in slots) {
          final parts = (slot['time'] as String? ?? '09:00').split(':');
          final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 9) : 9;
          final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          final duration = (slot['duration_minutes'] as num?)?.toInt() ?? 60;
          final day = _routeDate.add(Duration(days: (weekday - _routeDate.weekday) % 7));
          _visits.add(_RouteVisitDraft(
            serviceUserId: userId,
            serviceUserName: userName,
            visitTime: DateTime(day.year, day.month, day.day, hour, minute),
            durationMinutes: duration,
          ));
          added++;
        }
      }

      if (added == 0) {
        _visits.add(_RouteVisitDraft(
          serviceUserId: userId,
          serviceUserName: userName,
          visitTime: DateTime(_routeDate.year, _routeDate.month, _routeDate.day, 9, 0),
          durationMinutes: 60,
        ));
      }

      _availableUsers.removeWhere((u) => u['id'] == userId);
      if (_autoOrderByTime) _sortVisitsByTime();
    });
  }

  void _removeVisit(int index) {
    final removed = _visits.removeAt(index);
    setState(() {
      // Restore the user to the available list with their call data
      // Find the original user data from the loaded list
      final originalUser = _allUsers.firstWhere(
        (u) => u['id'] == removed.serviceUserId,
        orElse: () => {'id': removed.serviceUserId, 'name': removed.serviceUserName, 'weekly_calls': const <int, List<Map<String, dynamic>>>{}},
      );
      // Only add back if not already in available list
      if (!_availableUsers.any((u) => u['id'] == removed.serviceUserId)) {
        _availableUsers.add(originalUser);
      }
      if (_autoOrderByTime) _sortVisitsByTime();
    });
  }

  void _moveVisit(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _visits.length) return;
    setState(() {
      final tmp = _visits[index];
      _visits[index] = _visits[newIndex];
      _visits[newIndex] = tmp;
    });
  }

  void _sortVisitsByTime() {
    _visits.sort((a, b) => a.visitTime.compareTo(b.visitTime));
  }

  Future<void> _pickVisitTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_visits[index].visitTime),
    );
    if (picked != null) {
      setState(() {
        _visits[index] = _visits[index].copyWith(
          visitTime: DateTime(
            _routeDate.year,
            _routeDate.month,
            _routeDate.day,
            picked.hour,
            picked.minute,
          ),
        );
        if (_autoOrderByTime) _sortVisitsByTime();
      });
    }
  }

  Future<void> _pickDuration(int index) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Visit Duration'),
        children: [30, 45, 60, 90, 120]
            .map((d) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, d),
                  child: Text('$d minutes'),
                ))
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        _visits[index] = _visits[index].copyWith(durationMinutes: selected);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_visits.isEmpty) {
      _showError('Add at least one service user to the route');
      return;
    }

    setState(() => _saving = true);
    try {
      final visitsPayload = _visits
          .map((v) => {
                'id': v.id,
                'service_user_id': v.serviceUserId,
                'visit_time': v.visitTime,
                'duration_minutes': v.durationMinutes,
                'notes': v.notes,
              })
          .toList();

      if (_isEdit) {
        await _routeService.updateRouteWithVisits(
          routeId: widget.routeId!,
          name: _nameController.text.trim(),
          carerId: _primaryCarerId,
          secondCarerId: _secondCarerId,
          isDriver: _driverMode == 'primary' || _driverMode == 'both',
          driverMode: _driverMode,
          visits: visitsPayload,
        );
      } else {
        await _routeService.createRouteWithVisits(
          name: _nameController.text.trim(),
          routeDate: _routeDate,
          visits: visitsPayload,
          carerId: _primaryCarerId,
          isRecurring: _ongoing,
        );
        if (_primaryCarerId != null) {
          // Route was just created; assign second carer + driver mode via updates
          final routeResp = await _routeService.getRoutesForDate(_routeDate);
          // Find the route we just created (latest by name + date)
          final created = routeResp.lastWhere(
            (r) => r['name'] == _nameController.text.trim() && r['route_date'] == _routeDate.toIso8601String().split('T')[0],
            orElse: () => <String, dynamic>{},
          );
          if (created['id'] != null) {
            final routeId = created['id'] as String;
            await _routeService.assignSecondCarerToRouteCluster(routeId, _secondCarerId);
            await _routeService.setRouteDriverMode(routeId, _driverMode);
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Failed to save route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Route' : 'Add Route'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionHeader('Route Details'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Route Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.route),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a route name' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_ongoing ? 'Start Date' : 'Route Date'),
                    subtitle: Text(DateFormat('EEE, dd MMM yyyy').format(_routeDate)),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _routeDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _routeDate = picked);
                        }
                      },
                      child: const Text('Pick'),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ongoing (permanent)'),
                    subtitle: Text(_ongoing
                        ? 'Recurs daily from ${DateFormat('EEE, dd MMM yyyy').format(_routeDate)} until deleted'
                        : 'One-off route on ${DateFormat('EEE, dd MMM yyyy').format(_routeDate)}'),
                    value: _ongoing,
                    onChanged: (v) => setState(() => _ongoing = v),
                  ),
                  const Divider(height: 24),

                  _sectionHeader('Carer Assignment'),
                  DropdownButtonFormField<String>(
                    value: safeDropdownValue<String>(_primaryCarerId, _carers.map((c) => c['id'] as String).toList()),
                    decoration: const InputDecoration(
                      labelText: 'Primary Carer',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Unassigned')),
                      ..._carers.map((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(c['name'] as String? ?? 'Unknown'),
                          )),
                    ],
                    onChanged: (v) => setState(() => _primaryCarerId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: safeDropdownValue<String>(_secondCarerId, _carers.where((c) => c['id'] != _primaryCarerId).map((c) => c['id'] as String).toList()),
                    decoration: const InputDecoration(
                      labelText: 'Second Carer (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No second carer')),
                      ..._carers
                          .where((c) => c['id'] != _primaryCarerId)
                          .map((c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(c['name'] as String? ?? 'Unknown'),
                              )),
                    ],
                    onChanged: (v) => setState(() => _secondCarerId = v),
                  ),
                  const SizedBox(height: 12),
                  const Text('Who was driving?',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'primary', label: Text('Primary'), icon: Icon(Icons.directions_car)),
                      ButtonSegment(value: 'second', label: Text('Second'), icon: Icon(Icons.directions_car_outlined)),
                      ButtonSegment(value: 'both', label: Text('Both'), icon: Icon(Icons.directions_car_filled)),
                    ],
                    selected: {_driverMode},
                    onSelectionChanged: (sel) => setState(() => _driverMode = sel.first),
                  ),
                  const Divider(height: 24),

                  _sectionHeader('Service Users (Visits)'),
                  Row(
                    children: [
                      const Icon(Icons.sort, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Auto-order by visit time',
                            style: TextStyle(fontSize: 13)),
                      ),
                      Switch(
                        value: _autoOrderByTime,
                        onChanged: (v) {
                          setState(() {
                            _autoOrderByTime = v;
                            if (v) _sortVisitsByTime();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_visits.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'No service users added yet. Use "Add Service User" below.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._visits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final visit = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              // Order number
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      visit.serviceUserName,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _pickVisitTime(index),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 16, color: Colors.blue),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('HH:mm').format(visit.visitTime),
                                                style: const TextStyle(fontSize: 13, color: Colors.blue),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          onTap: () => _pickDuration(index),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.timer, size: 16, color: Colors.orange),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${visit.durationMinutes} min',
                                                style: const TextStyle(fontSize: 13, color: Colors.orange),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Order up/down (only when not auto-ordering)
                              if (!_autoOrderByTime) ...[
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward, size: 18),
                                  onPressed: index == 0 ? null : () => _moveVisit(index, -1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward, size: 18),
                                  onPressed: index == _visits.length - 1
                                      ? null
                                      : () => _moveVisit(index, 1),
                                ),
                              ],
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                onPressed: () => _removeVisit(index),
                                tooltip: 'Remove',
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 8),
                  // Add service user
                  DropdownButtonFormField<String>(
                    value: null,
                    hint: const Text('Add Service User to Route'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    items: _availableUsers.isEmpty
                        ? const [DropdownMenuItem(value: '', child: Text('No more users available'))]
                        : _availableUsers.map((u) {
                              final name = u['name'] as String? ?? 'Unknown';
                              final weekly = u['weekly_calls'] as Map<int, List<Map<String, dynamic>>>? ?? const <int, List<Map<String, dynamic>>>{};
                              final totalCalls = weekly.values.fold<int>(0, (sum, slots) => sum + slots.length);
                              final hasCalls = totalCalls > 0 || u['has_calls'] == true;
                              final label = hasCalls
                                  ? '$name ($totalCalls calls, ${weekly.length} days)'
                                  : name;
                              return DropdownMenuItem(
                                value: u['id'] as String,
                                child: Text(label),
                              );
                            }).toList(),
                    onChanged: (v) {
                      if (v == null || v.isEmpty) return;
                      final user = _availableUsers.firstWhere((u) => u['id'] == v);
                      _addServiceUser(user);
                    },
                  ),
                  const SizedBox(height: 24),

                  _saving
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save),
                            label: Text(_isEdit ? 'Update Route' : 'Create Route'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Draft visit entry in the form.
class _RouteVisitDraft {
  final String? id;
  final String serviceUserId;
  final String serviceUserName;
  final DateTime visitTime;
  final int durationMinutes;
  final String? notes;

  const _RouteVisitDraft({
    this.id,
    required this.serviceUserId,
    required this.serviceUserName,
    required this.visitTime,
    this.durationMinutes = 60,
    this.notes,
  });

  _RouteVisitDraft copyWith({
    String? id,
    String? serviceUserId,
    String? serviceUserName,
    DateTime? visitTime,
    int? durationMinutes,
    String? notes,
  }) {
    return _RouteVisitDraft(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      serviceUserName: serviceUserName ?? this.serviceUserName,
      visitTime: visitTime ?? this.visitTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
    );
  }
}