import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/services/mar_service.dart';

class MarChartScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;
  final String carerId;
  final String? carerName;

  const MarChartScreen({
    super.key,
    required this.serviceUserId,
    required this.serviceUserName,
    required this.carerId,
    this.carerName,
  });

  @override
  State<MarChartScreen> createState() => _MarChartScreenState();
}

class _MarChartScreenState extends State<MarChartScreen> {
  final _service = MarService(Supabase.instance.client);
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _medications = [];
  Map<String, Map<String, String>> _logs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dateStr = _selectedDate.toIso8601String().split('T').first;
      final meds = await _service.getMedicationsForDate(serviceUserId: widget.serviceUserId, date: _selectedDate);
      final adminLogs = await _service.getLogsForDate(serviceUserId: widget.serviceUserId, date: _selectedDate);

      final logMap = <String, Map<String, String>>{};
      for (final log in adminLogs) {
        final medId = log['medication_id'] as String;
        final schedTime = log['scheduled_time'] as String;
        final timeKey = schedTime.substring(11, 16);
        logMap.putIfAbsent(medId, () => {});
        logMap[medId]![timeKey] = log['status'] as String? ?? 'pending';
      }

      if (mounted) {
        setState(() { _medications = meds; _logs = logMap; _loading = false; });
      }
    } catch (e) {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  Future<void> _recordAdministration({
    required String medicationId,
    required String scheduledTime,
    required String status,
    String? notes,
    String? refusalReason,
  }) async {
    try {
      await _service.logAdministration(
        medicationId: medicationId,
        serviceUserId: widget.serviceUserId,
        scheduledTime: scheduledTime,
        status: status,
        notes: notes,
        refusalReason: refusalReason,
        carerId: widget.carerId,
        carerName: widget.carerName,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showRecordDialog(Map<String, dynamic> med, String timeSlot) {
    final medId = med['id'] as String;
    final currentStatus = _logs[medId]?[timeSlot] ?? 'pending';
    final schedTime = '${_selectedDate.toIso8601String().split('T').first}T$timeSlot:00Z';
    final notesCtrl = TextEditingController();
    String selectedStatus = currentStatus == 'pending' ? 'administered' : currentStatus;
    String? refusalReason;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${med['medication_name']} - ${med['dosage']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Scheduled: $timeSlot', style: TextStyle(color: Colors.grey.shade600)),
            ),
            const SizedBox(height: 12),
            // Status chips
            Wrap(spacing: 8, children: [
              _statusChip('administered', 'Given', Colors.green, selectedStatus, (s) => setSheetState(() => selectedStatus = s)),
              _statusChip('missed', 'Missed', Colors.red, selectedStatus, (s) => setSheetState(() => selectedStatus = s)),
              _statusChip('refused', 'Refused', Colors.orange, selectedStatus, (s) => setSheetState(() => selectedStatus = s)),
              _statusChip('held', 'Held', Colors.grey, selectedStatus, (s) => setSheetState(() => selectedStatus = s)),
            ]),
            if (selectedStatus == 'refused') ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Refusal reason', border: OutlineInputBorder()),
                  items: ['Patient refused', 'Drowsy/asleep', 'Nauseous', 'Not available', 'Other'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => refusalReason = v,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()), maxLines: 2),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _recordAdministration(
                      medicationId: medId,
                      scheduledTime: schedTime,
                      status: selectedStatus,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                      refusalReason: refusalReason,
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _getStatusColor(selectedStatus), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text('Save ${_statusLabel(selectedStatus)}'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label, Color color, String selected, ValueChanged<String> onSelect) {
    final isSel = selected == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSel ? Colors.white : color, fontSize: 12)),
      selected: isSel,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      onSelected: (_) => onSelect(value),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'administered': return Colors.green;
      case 'missed': return Colors.red;
      case 'refused': return Colors.orange;
      case 'held': return Colors.grey;
      default: return Colors.blue.shade200;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'administered': return 'Given';
      case 'missed': return 'Missed';
      case 'refused': return 'Refused';
      case 'held': return 'Held';
      default: return 'Pending';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'administered': return Icons.check_circle;
      case 'missed': return Icons.cancel;
      case 'refused': return Icons.block;
      case 'held': return Icons.pause_circle;
      default: return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MAR - ${widget.serviceUserName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Date navigation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade50,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))); _load(); }),
                  TextButton(
                    onPressed: () { setState(() => _selectedDate = DateTime.now()); _load(); },
                    child: Text(
                      _isToday ? 'Today, ${_formatDate(_selectedDate)}' : _formatDate(_selectedDate),
                      style: TextStyle(fontWeight: FontWeight.bold, color: _isToday ? Colors.blue : Colors.black),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))); _load(); }),
                ]),
              ),
              const Divider(height: 1),
              // Medication list
              Expanded(
                child: _medications.isEmpty
                    ? Center(child: Text('No active medications for this date', style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _medications.length,
                        itemBuilder: (_, i) => _buildMedicationCard(_medications[i]),
                      ),
              ),
            ]),
    );
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
  }

  String _formatDate(DateTime d) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _buildMedicationCard(Map<String, dynamic> med) {
    final medId = med['id'] as String;
    final times = (med['frequency_times'] as List?)?.cast<String>() ?? [];
    final isPrn = med['is_prn'] == true;
    final route = med['administration_route'] as String? ?? '';
    final instructions = med['special_instructions'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Medication name + dosage
          Row(children: [
            Icon(Icons.medication, size: 20, color: Colors.indigo.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(med['medication_name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            if (isPrn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                child: Text('PRN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
              ),
          ]),
          const SizedBox(height: 4),
          Text('${med['dosage']}${med['dosage_unit'] != null ? ' ${med['dosage_unit']}' : ''}${route.isNotEmpty ? ' - ${_routeLabel(route)}' : ''}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          if (instructions != null && instructions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(instructions, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 8),
          // Administration time slots
          if (times.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: times.map((t) {
              final logStatus = _logs[medId]?[t] ?? 'pending';
              return GestureDetector(
                onTap: () => _showRecordDialog(med, t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(logStatus).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(logStatus).withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_statusIcon(logStatus), size: 16, color: _getStatusColor(logStatus)),
                    const SizedBox(width: 6),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _getStatusColor(logStatus))),
                      Text(_statusLabel(logStatus), style: TextStyle(fontSize: 10, color: _getStatusColor(logStatus))),
                    ]),
                  ]),
                ),
              );
            }).toList())
          else
            GestureDetector(
              onTap: () => _showRecordDialog(med, 'PRN'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_circle_outline, size: 18, color: Colors.orange),
                  SizedBox(width: 6),
                  Text('Record PRN Administration', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  String _routeLabel(String route) {
    const map = {
      'oral': 'Oral', 'sublingual': 'Sublingual', 'topical': 'Topical',
      'subcutaneous': 'SC', 'intramuscular': 'IM', 'intravenous': 'IV',
      'rectal': 'Rectal', 'ophthalmic': 'Eye', 'otic': 'Ear', 'inhaled': 'Inhaled',
    };
    return map[route] ?? route;
  }
}