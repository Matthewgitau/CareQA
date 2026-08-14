import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/mar_medication.dart';
import 'package:admin_app/services/mar_service.dart';
import 'package:admin_app/ui/medication/mar_medication_form.dart';
import 'package:admin_app/ui/medication/mar_suggestions_screen.dart';

class MarChartScreen extends StatefulWidget {
  const MarChartScreen({super.key});

  @override
  State<MarChartScreen> createState() => _MarChartScreenState();
}

class _MarChartScreenState extends State<MarChartScreen> {
  final _service = MarService(Supabase.instance.client);

  // Service user selection
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;
  String? _selectedServiceUserName;

  // Date range
  DateTime _currentMonth = DateTime.now();
  late DateTime _startDate;
  late DateTime _endDate;

  // Data
  List<MarMedication> _medications = [];
  List<Map<String, dynamic>> _administrationLogs = [];
  bool _isLoading = false;

  // Scroll controller for horizontal scrolling
  final _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateDateRange();
    _loadServiceUsers();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _updateDateRange() {
    _startDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    _endDate = DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response);
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadData() async {
    if (_selectedServiceUserId == null) return;

    debugPrint('=== MAR Chart _loadData ===');
    debugPrint('Selected user: $_selectedServiceUserId');
    debugPrint('Date range: ${_startDate.toIso8601String().split('T').first} to ${_endDate.toIso8601String().split('T').first}');

    setState(() => _isLoading = true);
    try {
      final medications = await _service.getMedications(
        serviceUserId: _selectedServiceUserId!,
        startDate: _startDate,
        endDate: _endDate,
      );

      debugPrint('Medications found: ${medications.length}');
      for (final med in medications) {
        debugPrint('  - ${med.medicationName} (${med.dosage}), active: ${med.isActive}, start: ${med.startDate}, end: ${med.endDate}');
      }

      final logs = await _service.getAdministrationLogs(
        serviceUserId: _selectedServiceUserId!,
        startDate: _startDate,
        endDate: _endDate,
      );

      debugPrint('Administration logs found: ${logs.length}');

      setState(() {
        _medications = medications;
        _administrationLogs = logs;
        _isLoading = false;
      });
      debugPrint('=== _loadData complete ===');
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _navigateToForm({MarMedication? medication}) async {
    if (_selectedServiceUserId == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MarMedicationForm(
          medication: medication,
          serviceUserId: _selectedServiceUserId,
          serviceUserName: _selectedServiceUserName,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToSuggestions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarSuggestionsScreen()),
    );
  }

  Future<void> _deleteMedication(MarMedication med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete "${med.medicationName}"?'),
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

    if (confirmed == true && med.id != null) {
      try {
        await _service.softDeleteMedication(med.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medication deleted'), backgroundColor: Colors.green),
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

  Future<void> _stopMedication(MarMedication med) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Stop "${med.medicationName}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select reason for stopping:'),
              const SizedBox(height: 12),
              ...StoppedReasonHelper.values.map((r) => RadioListTile<String>(
                    title: Text(StoppedReasonHelper.labels[r] ?? r),
                    value: r,
                    groupValue: null,
                    onChanged: (v) {
                      Navigator.pop(ctx, v);
                    },
                  )),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Other reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        );
      },
    );

    if (reason != null && med.id != null) {
      try {
        await _service.stopMedication(med.id!, reason: reason);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medication stopped'), backgroundColor: Colors.green),
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

  Future<void> _updateAdministrationStatus(
      Map<String, dynamic> log, String newStatus) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await _service.updateAdministrationStatus(log['id'], {
        'status': newStatus,
        'administered_at': newStatus == 'administered' ? DateTime.now().toIso8601String() : null,
        'administered_by': user?.id,
        'administered_by_name': user?.email?.split('@').first ?? 'Admin',
      });
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAdministrationDialog(Map<String, dynamic> log) {
    final currentStatus = log['status'] as String? ?? 'pending';
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Administration Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _statusOption(ctx, log, 'administered', '✅ Administered', Colors.green, currentStatus),
              _statusOption(ctx, log, 'missed', '❌ Missed', Colors.red, currentStatus),
              _statusOption(ctx, log, 'held', '⏸️ Held', Colors.orange, currentStatus),
              _statusOption(ctx, log, 'refused', '⚠️ Refused', Colors.amber, currentStatus),
              _statusOption(ctx, log, 'pending', '🔄 Reset to Pending', Colors.grey, currentStatus),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusOption(BuildContext ctx, Map<String, dynamic> log, String status,
      String label, Color color, String currentStatus) {
    final isSelected = currentStatus == status;
    return Card(
      color: isSelected ? color.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: color,
        ),
        title: Text(label, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: () {
          Navigator.pop(ctx);
          _updateAdministrationStatus(log, status);
        },
      ),
    );
  }

  String? _getAdministrationStatus(String medicationId, DateTime date, String time) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final scheduledStr = '${dateStr}T${time}:00';
    final log = _administrationLogs.where((l) =>
        l['medication_id'] == medicationId &&
        (l['scheduled_time'] as String?)?.startsWith(scheduledStr) == true).firstOrNull;
    return log?['status'] as String?;
  }

  Map<String, dynamic>? _getAdministrationLog(String medicationId, DateTime date, String time) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final scheduledStr = '${dateStr}T${time}:00';
    return _administrationLogs.where((l) =>
        l['medication_id'] == medicationId &&
        (l['scheduled_time'] as String?)?.startsWith(scheduledStr) == true).firstOrNull;
  }

  List<DateTime> _getDaysInRange() {
    final days = <DateTime>[];
    final lastDay = DateTime(_endDate.year, _endDate.month, _endDate.day);
    var day = _startDate;
    while (!day.isAfter(lastDay)) {
      days.add(day);
      day = day.add(const Duration(days: 1));
    }
    return days;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'administered':
        return Colors.green;
      case 'missed':
        return Colors.red;
      case 'held':
        return Colors.orange;
      case 'refused':
        return Colors.amber;
      default:
        return Colors.grey.shade300;
    }
  }

  String _getStatusIcon(String? status) {
    switch (status) {
      case 'administered':
        return '✅';
      case 'missed':
        return '❌';
      case 'held':
        return '⏸️';
      case 'refused':
        return '⚠️';
      default:
        return '⬜';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAR Chart'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Medication Suggestions',
            onPressed: _navigateToSuggestions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Service user selector
          _buildServiceUserSelector(),

          // Month navigation
          _buildMonthNavigation(),

          // Main content
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: _selectedServiceUserId != null
          ? FloatingActionButton(
              onPressed: () => _navigateToForm(),
              backgroundColor: const Color(0xFF1976D2),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildServiceUserSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: _loadingUsers
          ? const Center(child: CircularProgressIndicator())
          : DropdownButtonFormField<String>(
              value: _selectedServiceUserId,
              decoration: const InputDecoration(
                labelText: 'Select Service User *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _serviceUsers.map((u) => DropdownMenuItem(
                    value: u['id'] as String,
                    child: Text(u['name'] as String),
                  )).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedServiceUserId = v;
                  _selectedServiceUserName = v != null
                      ? _serviceUsers.firstWhere((u) => u['id'] == v)['name'] as String
                      : null;
                });
                _loadData();
              },
            ),
    );
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                _updateDateRange();
              });
              _loadData();
            },
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _currentMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) {
                  setState(() {
                    _currentMonth = DateTime(picked.year, picked.month, 1);
                    _updateDateRange();
                  });
                  _loadData();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                _updateDateRange();
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedServiceUserId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a service user to view MAR chart',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_medications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No medications found for this period',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Tap + to add a medication',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    final days = _getDaysInRange();
    final dayColumnWidth = 40.0;
    final totalTableWidth = 200.0 + (days.length * dayColumnWidth);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        child: SizedBox(
          width: totalTableWidth,
          child: Column(
            children: [
              // Header row
              _buildHeaderRow(days, dayColumnWidth),
              // Medication rows
              Expanded(
                child: ListView.builder(
                  itemCount: _medications.length,
                  itemBuilder: (context, index) {
                    return _buildMedicationRow(
                        _medications[index], days, dayColumnWidth, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(List<DateTime> days, double colWidth) {
    return Container(
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          // Medication info column
          Container(
            width: 200,
            padding: const EdgeInsets.all(8),
            child: const Text('Medication',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          // Day columns
          ...days.map((day) {
            final isWeekend = day.weekday == 6 || day.weekday == 7;
            final isToday = DateFormat('yyyy-MM-dd').format(day) ==
                DateFormat('yyyy-MM-dd').format(DateTime.now());
            return Container(
              width: colWidth,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isToday
                    ? Colors.white.withOpacity(0.2)
                    : isWeekend
                        ? Colors.white.withOpacity(0.05)
                        : null,
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.2), width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Text('${day.day}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(
                    DateFormat('E').format(day).substring(0, 2),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 10),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMedicationRow(
      MarMedication med, List<DateTime> days, double colWidth, int index) {
    final isEven = index % 2 == 0;
    final times = med.frequencyTimes ?? ['08:00'];

    return Column(
      children: [
        // Medication info row
        Container(
          color: isEven ? Colors.white : Colors.grey.shade50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication info
              Container(
                width: 200,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (med.isPrn)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.warning_amber_rounded,
                                size: 16, color: Colors.orange),
                          ),
                        if (med.isEndingSoon)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.access_time,
                                size: 16, color: Colors.red),
                          ),
                        if (med.isLowStock)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.inventory_2,
                                size: 16, color: Colors.orange),
                          ),
                        Expanded(
                          child: Text(
                            med.medicationName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${med.dosage}${med.dosageUnit != null ? ' ${med.dosageUnit}' : ''}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                    ),
                    if (med.specialInstructions != null)
                      Text(
                        med.specialInstructions!,
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (med.isPrn)
                      Text(
                        'PRN - ${med.frequencyLabel}',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 10),
                      ),
                    // Action buttons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => _navigateToForm(medication: med),
                          tooltip: 'Edit',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.stop_circle, size: 16),
                          onPressed: () => _stopMedication(med),
                          tooltip: 'Stop',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          onPressed: () => _deleteMedication(med),
                          tooltip: 'Delete',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Day columns
              ...days.map((day) {
                return Container(
                  width: colWidth,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: Colors.grey.shade200, width: 0.5),
                    ),
                  ),
                  child: Column(
                    children: times.map((time) {
                      final status = _getAdministrationStatus(med.id!, day, time);
                      final log = _getAdministrationLog(med.id!, day, time);
                      return GestureDetector(
                        onTap: () {
                          if (log != null) {
                            _showAdministrationDialog(log);
                          }
                        },
                        child: Container(
                          height: 24,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Text(
                              _getStatusIcon(status),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade300),
      ],
    );
  }
}
