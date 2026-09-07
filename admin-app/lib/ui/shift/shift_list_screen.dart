import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_app/services/shift_service.dart';
import 'package:admin_app/services/route_service.dart';
import 'package:admin_app/services/shift_rota_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/route_visit.dart';
import 'package:admin_app/ui/shift/route_form_screen.dart';

class ShiftListScreen extends StatefulWidget {
  const ShiftListScreen({super.key});
  @override
  State<ShiftListScreen> createState() => _ShiftListScreenState();
}

class _ShiftListScreenState extends State<ShiftListScreen> {
  // View mode toggle: 0 = Client Shifts, 1 = Route Schedule
  int _viewMode = 0;

  DateTime _selectedDate = DateTime.now();

  List<Shift> _shifts = [];
  List<RouteVisit> _visits = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _carers = [];
  bool _loading = true;
  bool _buildingRoutes = false;
  String? _error;

  final ShiftService _shiftService = ShiftService();
  final RouteService _routeService = RouteService();
  final ShiftRotaService _rotaService = ShiftRotaService(Supabase.instance.client);

  Map<String, String> _activeStatuses = {};

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
      if (_viewMode == 0) {
        final shifts = await _shiftService.getShiftsForDate(_selectedDate);
        if (!mounted) return;
        setState(() {
          _shifts = shifts;
          _visits = [];
          _loading = false;
        });
      } else {
        final visits = await _routeService.getRouteVisitsForDate(_selectedDate);
        final routes = await _routeService.getRoutesForDate(_selectedDate);
        final generated = await _routeService.getGeneratedVisitsForDate(_selectedDate);
        final statuses = await _rotaService.getActiveStatuses();

        // Merge stored visits with recurring-generated ones (dedupe).
        final seen = <String>{};
        for (final v in visits) {
          seen.add('${v.routeId}|${v.serviceUserId}|${v.visitDate.toIso8601String().split('T')[0]}|${v.visitTime}');
        }
        final combined = List<RouteVisit>.from(visits);
        for (final g in generated) {
          final key =
              '${g.routeId}|${g.serviceUserId}|${g.visitDate.toIso8601String().split('T')[0]}|${g.visitTime}';
          if (!seen.contains(key)) {
            combined.add(g);
            seen.add(key);
          }
        }
        combined.sort((a, b) => a.visitTime.compareTo(b.visitTime));

        if (!mounted) return;
        setState(() {
          _visits = combined;
          _routes = routes;
          _activeStatuses = statuses;
          _shifts = [];
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadCarers() async {
    try {
      final carers = await _routeService.getCarers();
      if (!mounted) return;
      setState(() => _carers = carers);
    } catch (_) {}
  }

  void _changeView(int value) {
    setState(() => _viewMode = value);
    if (value == 1) {
      _loadCarers();
    }
    _load();
  }

  void _prevDay() {
    setState(() => _selectedDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day - 1));
    _load();
  }

  void _nextDay() {
    setState(() => _selectedDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1));
    _load();
  }

  void _goToday() {
    setState(() => _selectedDate = DateTime.now());
    _load();
  }

  Future<void> _buildRoutesFromPreferences() async {
    setState(() => _buildingRoutes = true);
    try {
      final created = await _routeService.buildRoutesFromPreferences(
        fromDate: _selectedDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created > 0
                ? 'Routes built from preferences ($created new visits created)'
                : 'Routes built from preferences (existing visits updated)',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to build routes: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _buildingRoutes = false);
    }
  }

  Future<void> _showChangeHistory() async {
    try {
      final log = await _routeService.getChangeLog(_selectedDate);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _ChangeHistorySheet(entries: log),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load change history: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showEditVisitTime(RouteVisit visit) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditVisitTimeDialog(visit: visit),
    );

    if (result != null && mounted) {
      try {
        await _routeService.updateVisitTime(
          visitId: visit.id,
          newTime: result['time'] as DateTime,
          durationMinutes: result['duration'] as int,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit time updated')),
        );
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update visit time: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _assignCarerToVisit(RouteVisit visit, String? carerId) async {
    try {
      await _routeService.assignCarerToVisit(visit.id, carerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            carerId != null ? 'Carer assigned to visit' : 'Carer unassigned from visit',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign carer: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleVisitRespite(RouteVisit visit, bool respite) async {
    try {
      await _routeService.toggleVisitRespite(visit.id, respite);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respite ? 'Marked as respite' : 'Respite removed'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update respite: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelVisit(RouteVisit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Visit'),
        content: Text(
          'Cancel the visit for ${visit.serviceUserName ?? 'this service user'} at '
          '${DateFormat('HH:mm').format(visit.visitTime)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _routeService.cancelVisit(visit.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit cancelled')),
        );
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel visit: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showMoveVisit(RouteVisit visit) async {
    if (_routes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No routes available to move to')),
      );
      return;
    }

    final selectedRouteId = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Move Visit to Route'),
        children: [
          ..._routes
              .where((r) => r['id'] != visit.routeId)
              .map((r) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, r['id'] as String),
                    child: Text(r['name'] as String? ?? 'Unnamed Route'),
                  )),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedRouteId != null && mounted) {
      try {
        await _routeService.moveVisitToRoute(visit.id, selectedRouteId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit moved to route')),
        );
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move visit: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showMergeRoute() async {
    if (_routes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 2 routes to merge')),
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _MergeRouteDialog(routes: _routes),
    );

    if (result != null && mounted) {
      try {
        await _routeService.mergeRoute(
          result['source']!,
          result['target']!,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routes merged successfully')),
        );
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to merge routes: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showSplitVisit(RouteVisit visit) async {
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Split Visit to New Route'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New Route Name (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Split'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _routeService.splitVisitToNewRoute(
          visit.id,
          newRouteName: nameController.text.trim().isEmpty
              ? null
              : nameController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit split into new route')),
        );
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to split visit: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ------------------------------------------------------------
  // ROUTE CLUSTER OPERATIONS
  // ------------------------------------------------------------

  /// Assigns (or clears) a carer to the route cluster for that day.
  Future<void> _assignCarerToRouteCluster(Map<String, dynamic> route, String? carerId) async {
    final routeId = route['id'] as String;
    try {
      await _routeService.assignCarerToRouteCluster(routeId, carerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            carerId != null ? 'Carer assigned to route' : 'Carer unassigned from route',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign carer: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Sets or clears the DRIVER flag on a route cluster.
  Future<void> _toggleRouteDriver(Map<String, dynamic> route, bool isDriver) async {
    final routeId = route['id'] as String;
    try {
      await _routeService.setRouteDriverFlag(routeId, isDriver);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isDriver ? 'Carer flagged as driver' : 'Driver flag removed')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update driver flag: $e'), backgroundColor: Colors.red),
      );
    }
  }

  final Set<String> _collapsedRouteIds = {};

  String _statusLabel(String status) {
    switch (status) {
      case 'respite':
        return 'Respite';
      case 'hospital':
        return 'Hospital';
      case 'holiday':
        return 'Holiday';
      default:
        return status;
    }
  }

  String _driverModeLabel(String mode, String? carerName) {
    switch (mode) {
      case 'second':
        return 'Driver: Second Carer';
      case 'both':
        return 'Driver: Both Carers';
      case 'primary':
      default:
        return 'Driver: $carerName';
    }
  }

  Future<void> _openAddRoute() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteFormScreen(initialDate: _selectedDate),
      ),
    );
    await _load();
  }

  Future<void> _openEditRoute(Map<String, dynamic> route) async {
    final routeId = route['id'] as String;
    if (routeId.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteFormScreen(routeId: routeId),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shifts')),
      floatingActionButton: _viewMode == 1
          ? FloatingActionButton.extended(
              onPressed: _openAddRoute,
              icon: const Icon(Icons.route),
              label: const Text('Add Route'),
            )
          : null,
      body: Column(
        children: [
          // View mode toggle (SegmentedButton)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Client Shifts'),
                  icon: Icon(Icons.schedule),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Route Schedule'),
                  icon: Icon(Icons.route),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (selection) => _changeView(selection.first),
            ),
          ),

          // Date navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevDay,
                ),
                Column(
                  children: [
                    Text(
                      DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: _goToday,
                      child: const Text('Today'),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextDay,
                ),
              ],
            ),
          ),
          const Divider(),

          // Route Schedule action bar
          if (_viewMode == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _buildingRoutes ? null : _buildRoutesFromPreferences,
                      icon: _buildingRoutes
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: const Text('Build from Prefs'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _showMergeRoute,
                    icon: const Icon(Icons.merge),
                    tooltip: 'Merge Routes',
                  ),
                  IconButton(
                    onPressed: _showChangeHistory,
                    icon: const Icon(Icons.history),
                    tooltip: 'Change History',
                  ),
                  IconButton.filled(
                    onPressed: _openAddRoute,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Route',
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 8),
                              Text('Error: $_error',
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _viewMode == 0
                        ? _buildShiftList()
                        : _buildRouteList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftList() {
    if (_shifts.isEmpty) {
      return const Center(
        child: Text('No client shifts for this date.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _shifts.length,
        itemBuilder: (context, index) {
          final shift = _shifts[index];
          return _buildShiftCard(context, shift);
        },
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, Shift shift) {
    final serviceUserName = shift.serviceUserName ?? 'Unknown';
    final carerName = shift.carerName ?? 'Unassigned';
    final status = shift.status ?? 'scheduled';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showAssignCarerBottomSheet(context, shift),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(Icons.medical_services, color: statusColor),
          ),
          title: Text(
            '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service User: $serviceUserName'),
              Text('Location: ${shift.location ?? 'TBC'}'),
              Text('Staff: ${shift.staffType ?? 'carer'} '
                  '(${shift.staffRequired ?? 1} required)'),
              Text('Carer: $carerName'),
            ],
          ),
          trailing: Chip(
            label: Text(
              status.toUpperCase(),
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: statusColor.withOpacity(0.1),
            labelStyle: TextStyle(color: statusColor),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteList() {
    // Group visits by route id so we can attach them to their container.
    final visitsByRoute = <String?, List<RouteVisit>>{};
    for (final v in _visits) {
      visitsByRoute.putIfAbsent(v.routeId, () => []).add(v);
    }

    final knownRouteIds = _routes.map((r) => r['id'] as String?).toSet();
    final cards = <Widget>[];

    // Render every route container for the day — even ones with zero visits,
    // so a saved route is always visible on the schedule.
    for (final route in _routes) {
      final routeId = route['id'] as String?;
      cards.add(_buildRouteGroup(context, route, visitsByRoute[routeId] ?? const []));
    }

    // Any visits that don't belong to a known route are shown under one group.
    final orphanVisits = _visits
        .where((v) => v.routeId == null || !knownRouteIds.contains(v.routeId))
        .toList();
    if (orphanVisits.isNotEmpty) {
      cards.add(
        _buildRouteGroup(context, const {'name': 'Unassigned Visits'}, orphanVisits),
      );
    }

    if (cards.isEmpty) {
      return const Center(
        child: Text('No routes scheduled for this date.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: cards,
      ),
    );
  }

  Widget _buildRouteGroup(
    BuildContext context,
    Map<String, dynamic> route,
    List<RouteVisit> visits,
  ) {
    final routeName = route['name'] as String? ?? 'Unassigned Visits';
    final String? routeId = route['id'] as String?;
    final routeCarerId = route['carer_id'] as String?;
    final routeSecondCarerId = route['second_carer_id'] as String?;
    final routeCarerName = _carers
        .firstWhere((c) => c['id'] == routeCarerId, orElse: () => const <String, dynamic>{})['name']
        as String?;
    final routeSecondCarerName = _carers
        .firstWhere((c) => c['id'] == routeSecondCarerId, orElse: () => const <String, dynamic>{})['name']
        as String?;
    final driverMode = route['driver_mode'] as String? ?? 'primary';
    final isDriver = route['is_driver'] as bool? ?? false;
    final totalDuration = visits.fold<int>(
      0,
      (sum, v) => sum + v.durationMinutes,
    );

    // Sort visits by time to represent route order
    final sortedVisits = [...visits]..sort((a, b) => a.visitTime.compareTo(b.visitTime));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route header (always visible)
            Row(
              children: [
                const Icon(Icons.route, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    routeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => _openEditRoute(route),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Route',
                ),
                ActionChip(
                  avatar: Icon(
                    _collapsedRouteIds.contains(routeId) ? Icons.expand_more : Icons.expand_less,
                    size: 18,
                  ),
                  label: Text('${sortedVisits.length} visits · ${totalDuration} min'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final id = route['id'] as String?;
                    if (id == null) return;
                    setState(() {
                      if (_collapsedRouteIds.contains(id)) {
                        _collapsedRouteIds.remove(id);
                      } else {
                        _collapsedRouteIds.add(id);
                      }
                    });
                  },
                ),
              ],
            ),
            // Collapsible section
            if (!_collapsedRouteIds.contains(routeId)) ...[
            // Driver mode indicator
            if (isDriver || driverMode != 'primary') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    driverMode == 'both'
                        ? Icons.directions_car_filled
                        : Icons.directions_car,
                    color: Colors.green,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _driverModeLabel(driverMode, routeCarerName),
                      style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
            // Second carer indicator
            if (routeSecondCarerId != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.group, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Second Carer: ${routeSecondCarerName ?? 'Assigned'}',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            if (isDriver) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Driver',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  if (routeCarerName != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      ': $routeCarerName',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Route-level carer assignment (day-by-day)
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String?>(
                    value: routeCarerId,
                    hint: Text(routeCarerId != null ? 'Assign Carer' : 'Assign Carer to Route'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ..._carers.map((carer) {
                        final carerId = carer['id'] as String;
                        final name = carer['name'] as String? ?? 'Unknown';
                        return DropdownMenuItem<String?>(
                          value: carerId,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      if (value != routeCarerId) {
                        _assignCarerToRouteCluster(route, value);
                      }
                    },
                  ),
                ),
                // Driver flag toggle
                IconButton(
                  onPressed: routeCarerId == null
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Assign a carer to the route first')),
                          );
                        }
                      : () => _toggleRouteDriver(route, !isDriver),
                  icon: Icon(
                    isDriver ? Icons.directions_car : Icons.directions_car_outlined,
                    color: isDriver ? Colors.green : Colors.grey,
                  ),
                  tooltip: isDriver ? 'Remove Driver Flag' : 'Flag as Driver',
                ),
              ],
            ),
            const Divider(height: 16),
            if (sortedVisits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No visits added yet — tap the edit icon to attach service users.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            // Ordered visits
            ...sortedVisits.asMap().entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildVisitCard(context, entry.value),
                      ),
                    ],
                  ),
                ],
              );
            }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, RouteVisit visit) {
    final carerName = visit.carerName ?? 'Unassigned';
    final statusColor = _getStatusColor(visit.status);
    final awayStatus = _activeStatuses[visit.serviceUserId];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('HH:mm').format(visit.visitTime)} - '
                        '${DateFormat('HH:mm').format(visit.endTime)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(visit.serviceUserName ?? 'Unknown'),
                      Text('Carer: $carerName'),
                      if (awayStatus != null)
                        Text(
                          '⛔ ${_statusLabel(awayStatus)} (away)',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (visit.requiresTwoCarers)
                        const Text('👥 Requires Two Carers',
                            style: TextStyle(color: Colors.orange, fontSize: 12)),
                      if (visit.respite)
                        const Text('🏥 Respite',
                            style: TextStyle(color: Colors.purple, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit_time':
                        _showEditVisitTime(visit);
                        break;
                      case 'move':
                        _showMoveVisit(visit);
                        break;
                      case 'split':
                        _showSplitVisit(visit);
                        break;
                      case 'cancel':
                        _cancelVisit(visit);
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit_time', child: Text('Edit Time')),
                    PopupMenuItem(value: 'move', child: Text('Move to Route')),
                    PopupMenuItem(value: 'split', child: Text('Split to New Route')),
                    PopupMenuItem(value: 'cancel', child: Text('Cancel Visit')),
                  ],
                ),
              ],
            ),
            const Divider(height: 12),
            // Carer assignment dropdown
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String?>(
                    value: visit.carerId,
                    hint: const Text('Assign Carer'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ..._carers.map((carer) {
                        final carerId = carer['id'] as String;
                        final name = carer['name'] as String? ?? 'Unknown';
                        return DropdownMenuItem<String?>(
                          value: carerId,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      if (value != visit.carerId) {
                        _assignCarerToVisit(visit, value);
                      }
                    },
                  ),
                ),
              ],
            ),
            // Respite toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Respite (Hospital Stay)'),
              value: visit.respite,
              onChanged: (value) => _toggleVisitRespite(visit, value),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time) {
    // time is in HH:MM:SS format
    if (time.isEmpty) return '--:--';
    final parts = time.split(':');
    if (parts.length < 2) return time;
    return '${parts[0]}:${parts[1]}';
  }

  Future<void> _showAssignCarerBottomSheet(BuildContext context, Shift shift) async {
    if (shift.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot assign carer: Shift ID is missing')),
      );
      return;
    }

    try {
      // Load carers
      final carers = await _shiftService.getCarers();
      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _CarerSelectionBottomSheet(
          shift: shift,
          carers: carers,
          onCarerSelected: (carerId) async {
            Navigator.pop(context);
            try {
              await _shiftService.assignCarerToShift(shift.id!, carerId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Carer assigned successfully!')),
                );
                await _load();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to assign carer: $e')),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load carers: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'booked':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      case 'in_progress':
        return Colors.teal;
      case 'merged':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _CarerSelectionBottomSheet extends StatelessWidget {
  final Shift shift;
  final List<Map<String, dynamic>> carers;
  final Function(String) onCarerSelected;

  const _CarerSelectionBottomSheet({
    required this.shift,
    required this.carers,
    required this.onCarerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Carer to Shift',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Divider(),
              ],
            ),
          ),
          Expanded(
            child: carers.isEmpty
                ? const Center(child: Text('No carers available'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: carers.length,
                    itemBuilder: (context, index) {
                      final carer = carers[index];
                      final carerId = carer['id'] as String;
                      final name = carer['name'] as String? ?? 'Unknown';
                      final employeeNumber = carer['employee_number'] as String?;
                      final jobRole = carer['job_role'] as String?;
                      final photoUrl = carer['photo_url'] as String?;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: photoUrl != null && photoUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    photoUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, color: Colors.blue);
                                    },
                                  ),
                                )
                              : const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          [employeeNumber, jobRole].where((s) => s != null && s.isNotEmpty).join(' • '),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            debugPrint('Assigning carer ID: $carerId (type: ${carerId.runtimeType})');
                            onCarerSelected(carerId);
                          },
                          child: const Text('Assign'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '--:--';
    final parts = time.split(':');
    if (parts.length < 2) return time;
    return '${parts[0]}:${parts[1]}';
  }
}

class _CreateRouteDialog extends StatefulWidget {
  final List<Map<String, dynamic>> serviceUsers;
  final List<Map<String, dynamic>> carers;
  final DateTime initialDate;

  const _CreateRouteDialog({
    required this.serviceUsers,
    required this.carers,
    required this.initialDate,
  });

  @override
  State<_CreateRouteDialog> createState() => _CreateRouteDialogState();
}

class _CreateRouteDialogState extends State<_CreateRouteDialog> {
  String? _selectedServiceUserId;
  String? _selectedCarerId;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _respite = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Route'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedServiceUserId,
              decoration: const InputDecoration(
                labelText: 'Service User *',
                border: OutlineInputBorder(),
              ),
              items: widget.serviceUsers.map((user) {
                return DropdownMenuItem(
                  value: user['id'] as String,
                  child: Text(user['name'] as String? ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedServiceUserId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCarerId,
              decoration: const InputDecoration(
                labelText: 'Carer (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                ...widget.carers.map((carer) {
                  return DropdownMenuItem(
                    value: carer['id'] as String,
                    child: Text(carer['name'] as String? ?? 'Unknown'),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _selectedCarerId = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate)),
              trailing: TextButton(
                onPressed: _pickStartDate,
                child: const Text('Pick'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Start Time'),
              subtitle: Text(_startTime.format(context)),
              trailing: TextButton(
                onPressed: _pickStartTime,
                child: const Text('Pick'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('End Time'),
              subtitle: Text(_endTime.format(context)),
              trailing: TextButton(
                onPressed: _pickEndTime,
                child: const Text('Pick'),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Respite (Hospital Stay)'),
              value: _respite,
              onChanged: (v) => setState(() => _respite = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedServiceUserId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a service user')),
              );
              return;
            }
            Navigator.pop(context, {
              'service_user_id': _selectedServiceUserId,
              'carer_id': _selectedCarerId,
              'start_time': _combine(_startDate, _startTime),
              'end_time': _combine(_startDate, _endTime),
              'respite': _respite,
              'notes': _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _EditVisitTimeDialog extends StatefulWidget {
  final RouteVisit visit;

  const _EditVisitTimeDialog({required this.visit});

  @override
  State<_EditVisitTimeDialog> createState() => _EditVisitTimeDialogState();
}

class _EditVisitTimeDialogState extends State<_EditVisitTimeDialog> {
  late DateTime _date;
  late TimeOfDay _time;
  late int _duration;

  static const _durationOptions = [30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _date = widget.visit.visitDate;
    _time = TimeOfDay.fromDateTime(widget.visit.visitTime);
    _duration = widget.visit.durationMinutes;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Visit Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(DateFormat('dd MMM yyyy').format(_date)),
            trailing: TextButton(
              onPressed: _pickDate,
              child: const Text('Pick'),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time),
            title: const Text('Visit Time'),
            subtitle: Text(_time.format(context)),
            trailing: TextButton(
              onPressed: _pickTime,
              child: const Text('Pick'),
            ),
          ),
          DropdownButtonFormField<int>(
            value: _durationOptions.contains(_duration) ? _duration : 60,
            decoration: const InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
            ),
            items: _durationOptions
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('$d minutes'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _duration = v ?? 60),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final combined = DateTime(
              _date.year,
              _date.month,
              _date.day,
              _time.hour,
              _time.minute,
            );
            Navigator.pop(context, {
              'time': combined,
              'duration': _duration,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _MergeRouteDialog extends StatefulWidget {
  final List<Map<String, dynamic>> routes;

  const _MergeRouteDialog({required this.routes});

  @override
  State<_MergeRouteDialog> createState() => _MergeRouteDialogState();
}

class _MergeRouteDialogState extends State<_MergeRouteDialog> {
  String? _sourceRouteId;
  String? _targetRouteId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Merge Routes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _sourceRouteId,
            decoration: const InputDecoration(
              labelText: 'Source Route (to merge from)',
              border: OutlineInputBorder(),
            ),
            items: widget.routes.map((r) {
              return DropdownMenuItem(
                value: r['id'] as String,
                child: Text(r['name'] as String? ?? 'Unnamed Route'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _sourceRouteId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _targetRouteId,
            decoration: const InputDecoration(
              labelText: 'Target Route (to merge into)',
              border: OutlineInputBorder(),
            ),
            items: widget.routes
                .where((r) => r['id'] != _sourceRouteId)
                .map((r) {
              return DropdownMenuItem(
                value: r['id'] as String,
                child: Text(r['name'] as String? ?? 'Unnamed Route'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _targetRouteId = v),
          ),
          const SizedBox(height: 8),
          const Text(
            'All visits from the source route will be moved to the target route.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_sourceRouteId == null || _targetRouteId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select both routes')),
              );
              return;
            }
            Navigator.pop(context, {
              'source': _sourceRouteId,
              'target': _targetRouteId,
            });
          },
          child: const Text('Merge'),
        ),
      ],
    );
  }
}

class _ChangeHistorySheet extends StatelessWidget {
  final List<RouteChangeLogEntry> entries;

  const _ChangeHistorySheet({required this.entries});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No changes recorded for this date.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _typeColor(entry.changeType).withOpacity(0.1),
                              child: Icon(
                                _typeIcon(entry.changeType),
                                color: _typeColor(entry.changeType),
                                size: 20,
                              ),
                            ),
                            title: Text(_typeLabel(entry.changeType)),
                            subtitle: Text(
                              entry.description ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              DateFormat('HH:mm').format(entry.createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'visit_created':
        return 'Visit Created';
      case 'visit_deleted':
        return 'Visit Deleted';
      case 'time_adjusted':
        return 'Time Adjusted';
      case 'date_changed':
        return 'Date Changed';
      case 'carer_assigned':
        return 'Carer Assigned';
      case 'carer_unassigned':
        return 'Carer Unassigned';
      case 'route_created':
        return 'Route Created';
      case 'route_merged':
        return 'Route Merged';
      case 'route_split':
        return 'Route Split';
      case 'cancelled':
        return 'Cancelled';
      case 'respite_toggled':
        return 'Respite Toggled';
      default:
        return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'visit_created':
        return Icons.add_circle;
      case 'visit_deleted':
        return Icons.delete;
      case 'time_adjusted':
        return Icons.access_time;
      case 'date_changed':
        return Icons.date_range;
      case 'carer_assigned':
        return Icons.person_add;
      case 'carer_unassigned':
        return Icons.person_remove;
      case 'route_created':
        return Icons.route;
      case 'route_merged':
        return Icons.merge;
      case 'route_split':
        return Icons.call_split;
      case 'cancelled':
        return Icons.cancel;
      case 'respite_toggled':
        return Icons.local_hospital;
      default:
        return Icons.info;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'visit_created':
      case 'route_created':
        return Colors.green;
      case 'visit_deleted':
      case 'cancelled':
        return Colors.red;
      case 'time_adjusted':
      case 'date_changed':
        return Colors.orange;
      case 'carer_assigned':
        return Colors.blue;
      case 'carer_unassigned':
        return Colors.grey;
      case 'route_merged':
        return Colors.purple;
      case 'route_split':
        return Colors.teal;
      case 'respite_toggled':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}