import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/shift_rota.dart';
import 'package:admin_app/models/service_user_call.dart';
import 'package:admin_app/services/shift_rota_service.dart';
import 'package:admin_app/services/shift_service.dart';
import 'package:admin_app/ui/shift/shift_form_screen.dart';
import 'package:admin_app/ui/shift/route_form_screen.dart';
import 'package:intl/intl.dart';

/// Shift View Type Enum
enum ShiftViewType { domCareRoutes, careHomeShifts, warehouseShifts }

class ShiftRotaScreen extends StatefulWidget {
  const ShiftRotaScreen({super.key});

  @override
  State<ShiftRotaScreen> createState() => _ShiftRotaScreenState();
}

class _ShiftRotaScreenState extends State<ShiftRotaScreen> {
  List<ShiftRota> _rotas = [];
  List<ServiceUserCall> _domCareCalls = [];
  List<Shift> _careHomeShifts = [];
  bool _loading = true;
  ShiftViewType _selectedView = ShiftViewType.domCareRoutes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = ShiftRotaService(Supabase.instance.client);
      switch (_selectedView) {
        case ShiftViewType.domCareRoutes:
          final data = await service.getDomCareRoutes();
          setState(() {
            _domCareCalls = data;
            _rotas = [];
            _careHomeShifts = [];
            _loading = false;
          });
          break;
        case ShiftViewType.careHomeShifts:
          final data = await service.getCareHomeShifts();
          setState(() {
            _careHomeShifts = data;
            _rotas = [];
            _domCareCalls = [];
            _loading = false;
          });
          break;
        case ShiftViewType.warehouseShifts:
          final data = await service.getWarehouseShifts();
          setState(() {
            _rotas = data;
            _domCareCalls = [];
            _careHomeShifts = [];
            _loading = false;
          });
          break;
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shifts: $e')),
        );
      }
    }
  }

  Future<void> _setStatus(ServiceUserCall call, String value) async {
    if (value == 'none') {
      await _markBack(call);
      return;
    }
    try {
      final service = ShiftRotaService(Supabase.instance.client);
      await service.setServiceUserStatus(call.serviceUserId, value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as ${_statusLabel(value)}')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markBack(ServiceUserCall call) async {
    try {
      final service = ShiftRotaService(Supabase.instance.client);
      final closed = await service.markServiceUserBack(call.serviceUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service user marked back')),
      );
      if (closed != null) {
        await _promptBodyMap(call, closed);
      }
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark back: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _promptBodyMap(ServiceUserCall call, Map<String, dynamic> statusPeriod) async {
    final typeLabel = _statusLabel(statusPeriod['status_type'] as String? ?? '');
    final notesController = TextEditingController();
    var noNewMarks = true;
    var shouldSave = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Body-map assessment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$typeLabel ended — good practice: check for new marks/bruises and record the result.',
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('No new marks identified'),
                    value: noNewMarks,
                    onChanged: (v) => setDialogState(() => noNewMarks = v),
                  ),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () {
                    shouldSave = true;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave && mounted) {
      final service = ShiftRotaService(Supabase.instance.client);
      try {
        await service.saveBodyMapAssessment(
          serviceUserId: call.serviceUserId,
          statusId: statusPeriod['id'] as String?,
          noNewMarks: noNewMarks,
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Body-map assessment recorded')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save assessment: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
    notesController.dispose();
  }

  Future<void> _showCallHistory(ServiceUserCall call) async {
    try {
      final service = ShiftRotaService(Supabase.instance.client);
      final entries = await service.getServiceUserCallLog(call.id);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _CallHistorySheet(entries: entries),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _currentStatus(ServiceUserCall c) {
    if (c.hospital) return 'hospital';
    if (c.respite) return 'respite';
    if (c.holiday) return 'holiday';
    return 'none';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'respite':
        return 'Respite';
      case 'hospital':
        return 'Hospital';
      case 'holiday':
        return 'Holiday';
      default:
        return 'Active';
    }
  }

  Widget _statusChip(
    ServiceUserCall call,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final selected = _currentStatus(call) == value;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
      label: Text(label),
      selectedColor: color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontSize: 12,
      ),
      onSelected: (_) => _setStatus(call, value),
    );
  }

  Color _getShiftColor(ShiftRota shift) {
    if (shift.status == 'cancelled') return Colors.grey;
    if (shift.status == 'confirmed') return Colors.blue;
    if (shift.status == 'booked') return Colors.orange;
    if (shift.carerId == null || shift.carerId!.isEmpty) return Colors.red;
    return Colors.grey;
  }

  String _getShiftStatusLabel(ShiftRota shift) {
    if (shift.status == 'cancelled') return 'Cancelled';
    if (shift.status == 'confirmed') return 'Confirmed';
    if (shift.status == 'booked') return 'Booked (Unconfirmed)';
    if (shift.carerId == null || shift.carerId!.isEmpty) return 'Uncovered';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Rota'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Toggle for shift types
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ShiftViewType>(
              segments: const [
                ButtonSegment(
                  value: ShiftViewType.domCareRoutes,
                  label: Text('Dom Care Routes'),
                  icon: Icon(Icons.route),
                ),
                ButtonSegment(
                  value: ShiftViewType.careHomeShifts,
                  label: Text('Care Home'),
                  icon: Icon(Icons.home),
                ),
                ButtonSegment(
                  value: ShiftViewType.warehouseShifts,
                  label: Text('Warehouse'),
                  icon: Icon(Icons.warehouse),
                ),
              ],
              selected: {_selectedView},
              onSelectionChanged: (Set<ShiftViewType> newSelection) {
                setState(() => _selectedView = newSelection.first);
                _load();
              },
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _legendDot(Colors.blue, 'Confirmed'),
                const SizedBox(width: 8),
                _legendDot(Colors.orange, 'Booked'),
                const SizedBox(width: 8),
                _legendDot(Colors.red, 'Uncovered'),
                const SizedBox(width: 8),
                _legendDot(Colors.grey, 'Cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _selectedView == ShiftViewType.domCareRoutes
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RouteFormScreen(),
                  ),
                ).then((_) => _load());
              },
              icon: const Icon(Icons.route),
              label: const Text('Add Route'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShiftFormScreen()),
                ).then((_) => _load());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Shift'),
            ),
    );
  }

  Widget _buildContent() {
    switch (_selectedView) {
      case ShiftViewType.domCareRoutes:
        return _buildDomCareList();
      case ShiftViewType.careHomeShifts:
        return _buildCareHomeList();
      case ShiftViewType.warehouseShifts:
        return _buildWarehouseList();
    }
  }

  // ------------------------------------------------------------
  // DOM CARE ROUTES — from public.service_user_calls
  // ------------------------------------------------------------
  Widget _buildDomCareList() {
    if (_domCareCalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No Dom Care Routes found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    // Calculate totals
    final totalCalls = _domCareCalls.fold<int>(0, (sum, c) => sum + c.callsPerDay);
    final totalPlannedHours = _domCareCalls.fold<double>(
      0,
      (sum, c) => sum + c.totalPlannedHours,
    );
    final totalBillableHours = _domCareCalls.fold<double>(
      0,
      (sum, c) => sum + c.billableHours,
    );
    final nonBillableCount = _domCareCalls.where((c) => c.isNonBillable).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Summary card
          Card(
            color: const Color(0xFF1565C0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryItem('Service Users', '${_domCareCalls.length}'),
                      _summaryItem('Total Calls', '$totalCalls'),
                      _summaryItem('Planned Hrs', totalPlannedHours.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryItem('Billable Hrs', totalBillableHours.toStringAsFixed(1)),
                      _summaryItem('Non-Billable', '$nonBillableCount'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._domCareCalls.map((call) => _buildDomCareCard(call)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDomCareCard(ServiceUserCall call) {
    final userName = call.serviceUserName ?? 'Unknown Service User';
    final isNonBillable = call.isNonBillable;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isNonBillable ? Colors.orange.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isNonBillable
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.1),
                  child: Icon(
                    isNonBillable ? Icons.pause_circle : Icons.person,
                    color: isNonBillable ? Colors.orange : Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${call.callsPerDay} calls/day · ${call.totalPlannedHours.toStringAsFixed(1)} hrs',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isNonBillable)
                  Chip(
                    label: Text(
                      call.respite
                          ? 'Respite'
                          : call.hospital
                              ? 'Hospital'
                              : 'Holiday',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    labelStyle: const TextStyle(color: Colors.orange),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Call times
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: call.callTimes.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 16),
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _statusChip(call, 'none', 'Active', Icons.check_circle, Colors.green),
                _statusChip(call, 'respite', 'Respite', Icons.local_hospital, Colors.purple),
                _statusChip(call, 'hospital', 'Hospital', Icons.medical_services, Colors.red),
                _statusChip(call, 'holiday', 'Holiday', Icons.beach_access, Colors.teal),
              ],
            ),
            if (_currentStatus(call) != 'none')
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton.icon(
                  onPressed: () => _markBack(call),
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Mark back'),
                ),
              ),
            // Audit history of planned-call flag changes (duty-of-care record)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showCallHistory(call),
                icon: const Icon(Icons.history, size: 16),
                label: const Text('History'),
              ),
            ),
            if (isNonBillable) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '⚠️ ${call.totalPlannedHours.toStringAsFixed(1)} hrs excluded from billable total '
                  '(${call.billableHours.toStringAsFixed(1)} hrs billable)',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  

  // ------------------------------------------------------------
  // CARE HOME — from public.shifts
  // ------------------------------------------------------------
  Widget _buildCareHomeList() {
    if (_careHomeShifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No Care Home shifts found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _careHomeShifts.length,
        itemBuilder: (_, i) {
          final shift = _careHomeShifts[i];
          final status = shift.status ?? 'scheduled';
          final color = _getShiftStatusColor(status);
          final serviceUserName = shift.serviceUserName ?? 'Unknown';
          final carerName = shift.carerName ?? 'Unassigned';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.home, color: color),
              ),
              title: Text(
                '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('EEE, dd MMM yyyy').format(shift.scheduledDate)}',
                  ),
                  Text('Service User: $serviceUserName'),
                  Text('Carer: $carerName'),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Color _getShiftStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'booked':
        return Colors.orange;
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

  String _formatTime(String time) {
    if (time.isEmpty) return '--:--';
    final parts = time.split(':');
    if (parts.length < 2) return time;
    return '${parts[0]}:${parts[1]}';
  }

  // ------------------------------------------------------------
  // WAREHOUSE — from shift_rotas
  // ------------------------------------------------------------
  Widget _buildWarehouseList() {
    if (_rotas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No Warehouse shifts found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _rotas.length,
        itemBuilder: (_, i) {
          final r = _rotas[i];
          final color = _getShiftColor(r);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warehouse, color: color),
              ),
              title: Text(
                r.shiftType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${DateFormat('EEE, dd MMM').format(r.startDate)} — ${DateFormat('HH:mm').format(r.startDate)}'),
                  if (r.carerName != null && r.carerName!.isNotEmpty)
                    Text('Carer: ${r.carerName}', style: TextStyle(color: Colors.grey[600])),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getShiftStatusLabel(r),
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

/// Bottom sheet showing the audit history of planned-call flag changes
/// (respite/hospital/holiday) for a single service user's call schedule.
/// This is the duty-of-care / billing record surfaced in the UI.
class _CallHistorySheet extends StatelessWidget {
  final List<Map<String, dynamic>> entries;

  const _CallHistorySheet({required this.entries});

  static String _nameFor(String flag) {
    switch (flag) {
      case 'respite':
        return 'Respite';
      case 'hospital':
        return 'Hospital';
      case 'holiday':
        return 'Holiday';
      default:
        return flag;
    }
  }

  static String _boolLabel(dynamic v) {
    if (v == null) return 'unknown';
    return v == true ? 'ON' : 'OFF';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Flag History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Record of respite / hospital / holiday changes for this client.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No changes recorded yet.')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final flag = e['flag_type'] as String? ?? 'unknown';
                      final oldV = e['old_value'];
                      final newV = e['new_value'];
                      final createdAt = DateTime.tryParse(e['created_at']?.toString() ?? '');
                      final time = createdAt != null
                          ? DateFormat('EEE, dd MMM yyyy · HH:mm').format(createdAt.toLocal())
                          : 'unknown time';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history, color: Colors.blue),
                        title: Text('${_nameFor(flag)}: ${_boolLabel(oldV)} → ${_boolLabel(newV)}'),
                        subtitle: Text(time),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}