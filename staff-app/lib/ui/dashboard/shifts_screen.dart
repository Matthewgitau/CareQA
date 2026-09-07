import 'package:flutter/material.dart' hide DateUtils;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/shift.dart';
import 'package:staff_app/services/shift_service.dart';
import 'package:staff_app/ui/dashboard/shift_detail_screen.dart';
import 'package:staff_app/utils/date_utils.dart';
import 'package:staff_app/widgets/shift_card.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final ShiftService _shiftService = ShiftService(Supabase.instance.client);
  List<Shift> _shifts = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  // Filter tabs
  final List<String> _statusFilters = ['All', 'Scheduled', 'Confirmed', 'Completed', 'Declined'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    setState(() => _isLoading = true);
    try {
      // TWO data sources power this screen:
      //  1. public.shifts  - client-app bookings, confirmed by admin
      //  2. public.route_visits - ongoing/one-off ROUTE calls written by admin
      //     (see ShiftService.getRouteCallsForCurrentCarer)
      // Merge the lists so a carer sees their booked shifts AND route calls
      // together, then sort by date/time.
      final results = await Future.wait([
        _shiftService.getShiftsForCurrentCarer(),
        _shiftService.getRouteCallsForCurrentCarer(),
      ]);
      final combined = <Shift>[...results[0], ...results[1]]
        ..sort((a, b) {
          final da = a.scheduledDate ?? '';
          final db = b.scheduledDate ?? '';
          if (da != db) return da.compareTo(db);
          return a.startTime.compareTo(b.startTime);
        });
      setState(() {
        _shifts = combined;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshShifts() async {
    await _loadShifts();
  }

  List<Shift> _getFilteredShifts() {
    var filtered = _shifts;

    // Filter by status
    if (_selectedFilter != 'All') {
      filtered = filtered.where((s) => s.status == _selectedFilter.toLowerCase()).toList();
    }

    // Filter by date
    final dateStr = _selectedDate.toIso8601String().split('T').first;
    filtered = filtered.where((s) => s.scheduledDate == dateStr).toList();

    return filtered;
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _goToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shifts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshShifts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadShifts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Date Navigation
                    _buildDateNavigation(),
                    // Status Filter
                    _buildStatusFilter(),
                    // Shift List
                    Expanded(
                      child: _getFilteredShifts().isEmpty
                          ? const Center(
                              child: Text(
                                'No shifts assigned for this day',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshShifts,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _getFilteredShifts().length,
                                itemBuilder: (context, index) {
                                  final shift = _getFilteredShifts()[index];
                                  return ShiftCard(
                                    shift: shift,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ShiftDetailScreen(
                                            shift: shift,
                                            onShiftUpdated: _refreshShifts,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDateNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeDate(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          TextButton(
            onPressed: _goToday,
            child: Text(
              DateUtils.isToday(_selectedDate)
                  ? 'Today, ${DateUtils.formatDate(_selectedDate)}'
                  : DateUtils.formatDate(_selectedDate),
            ),
          ),
          IconButton(
            onPressed: () => _changeDate(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _statusFilters.map((status) {
          final isSelected = _selectedFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = status),
              backgroundColor: Colors.grey.shade200,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}