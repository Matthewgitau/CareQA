import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_app/services/shift_service.dart';
import 'shift_form_screen.dart';

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
  List<RouteSchedule> _routes = [];
  bool _loading = true;
  String? _error;

  final ShiftService _shiftService = ShiftService();

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
          _routes = [];
          _loading = false;
        });
      } else {
        final routes = await _shiftService.getRoutesForDate(_selectedDate);
        if (!mounted) return;
        setState(() {
          _routes = routes;
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

  void _changeView(int value) {
    setState(() => _viewMode = value);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shifts')),
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
    if (_routes.isEmpty) {
      return const Center(
        child: Text('No routes scheduled for this date.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];
          return _buildRouteCard(context, route);
        },
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, RouteSchedule route) {
    final carerName = route.carerName ?? 'Unassigned';
    final statusColor = _getStatusColor(route.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.route, color: statusColor),
        ),
        title: Text(
          'Call #${route.callNumber} · '
          '${DateFormat('HH:mm').format(route.proposedStartTime)} - '
          '${DateFormat('HH:mm').format(route.proposedEndTime)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service User: ${route.serviceUserName ?? 'Unknown'}'),
            Text('Carer: $carerName'),
            if (route.respite) const Text('Respite: Yes'),
          ],
        ),
        trailing: Chip(
          label: Text(
            route.status.toUpperCase(),
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: statusColor.withOpacity(0.1),
          labelStyle: TextStyle(color: statusColor),
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
