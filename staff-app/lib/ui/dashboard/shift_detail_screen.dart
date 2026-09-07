import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:staff_app/models/shift.dart';
import 'package:staff_app/services/shift_service.dart';
import 'package:staff_app/ui/care/record_care_screen.dart';
import 'package:staff_app/services/care_log_summary_service.dart';

class ShiftDetailScreen extends StatefulWidget {
  final Shift shift;
  final VoidCallback onShiftUpdated;

  const ShiftDetailScreen({
    super.key,
    required this.shift,
    required this.onShiftUpdated,
  });

  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen> {
  final ShiftService _shiftService = ShiftService(Supabase.instance.client);
  final CareLogSummaryService _logService = CareLogSummaryService(Supabase.instance.client);
  bool _isLoading = false;
  Map<String, dynamic> _logs = {};
  bool _logsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    // Route calls (from public.route_visits) are managed by the admin/office --
    // accept/decline only applies to booked `public.shifts` rows.
    final isRouteCall = shift.source == 'route';
    final isActionable =
        !isRouteCall && (shift.status == 'scheduled' || shift.status == 'pending');
    final hasAddress = (shift.serviceUserAddress != null &&
            shift.serviceUserAddress!.isNotEmpty) ||
        (shift.location != null && shift.location!.isNotEmpty);
    final displayAddress = shift.serviceUserAddress?.isNotEmpty == true
        ? shift.serviceUserAddress!
        : (shift.location ?? '');

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recordCare',
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.edit_note, color: Colors.white),
        label: const Text('Record Care', style: TextStyle(color: Colors.white)),
        onPressed: () => _openRecordCare(),
      ),
      appBar: AppBar(
        title: const Text('Shift Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Chip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(shift.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(shift.status)),
                  ),
                  child: Text(
                    shift.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(shift.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (shift.scheduledDate != null)
                  Text(
                    shift.scheduledDate!,
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Service User
            if (shift.serviceUserName != null) ...[
              _buildInfoRow('Service User', shift.serviceUserName!),
              const SizedBox(height: 8),
            ],

            // Route name (only present for route calls)
            if (isRouteCall && shift.routeName != null) ...[
              _buildInfoRow('Route', shift.routeName!),
              const SizedBox(height: 8),
            ],

            // Time
            _buildInfoRow('Time', '${shift.startTime} - ${shift.endTime}'),
            const SizedBox(height: 8),

            // Address with copy + map actions
            if (hasAddress) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text('Address',
                        style:
                            TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onLongPress: () => _copyAddress(displayAddress),
                      child: Text(displayAddress),
                    ),
                  ),
                  // Copy button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _copyAddress(displayAddress),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(Icons.copy,
                            size: 18, color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                  // Map button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openMapPicker(context, displayAddress),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(Icons.map,
                            size: 18, color: Colors.blue.shade400),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Location (shown only if distinct from address)
            if (shift.location != null &&
                shift.location!.isNotEmpty &&
                shift.location != shift.serviceUserAddress) ...[
              _buildInfoRow('Location', shift.location!),
              const SizedBox(height: 8),
            ],

            // --- Logged Care Records (clickable cards) ---
            if (_logsLoaded) ...[
              const Divider(),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Care Logged Today',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                    onPressed: _loadLogs,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildLogCards(),
              const SizedBox(height: 8),
            ],

            // Notes
            if (shift.notes != null && shift.notes!.isNotEmpty) ...[
              const Divider(),
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(shift.notes!),
              const SizedBox(height: 12),
            ],

            // Action buttons for booked shifts
            if (isActionable) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _acceptShift,
                      icon: const Icon(Icons.check),
                      label: const Text('Accept Shift'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _declineShift,
                      icon: const Icon(Icons.close),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (!isRouteCall) ...[
              const Text(
                'This shift is no longer actionable',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'declined':
        return Colors.red;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 250,
      ),
    );
  }

  void _openMapPicker(BuildContext context, String address) {
    final encoded = Uri.encodeComponent(address);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Open in Maps',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.map, color: Colors.green.shade700),
              ),
              title: const Text('Google Maps'),
              subtitle: const Text('Open in browser or app'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$encoded'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            if (Theme.of(context).platform == TargetPlatform.iOS)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.map, color: Colors.blue.shade700),
                ),
                title: const Text('Apple Maps'),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse('https://maps.apple.com/?q=$encoded'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.navigation, color: Colors.blue.shade700),
              ),
              title: const Text('Waze'),
              subtitle: const Text('Open in Waze app'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri.parse('https://waze.com/ul?q=$encoded&navigate=yes'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptShift() async {
    setState(() => _isLoading = true);
    try {
      await _shiftService.acceptShift(widget.shift.id);
      widget.onShiftUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shift confirmed!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _declineShift() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Shift?'),
        content: const Text('Are you sure you want to decline this shift?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _shiftService.declineShift(widget.shift.id);
      widget.onShiftUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shift declined'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _resolveCarerId() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return null;
    final direct = await Supabase.instance.client.from('carers').select('id').eq('id', uid).maybeSingle();
    if (direct != null) return uid;
    final legacy = await Supabase.instance.client.from('carers').select('id').eq('auth_user_id', uid).maybeSingle();
    return legacy?['id'] as String?;
  }

  void _openRecordCare() async {
    final carerId = await _resolveCarerId() ?? Supabase.instance.client.auth.currentUser?.id;
    if (carerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot identify carer')));
      return;
    }
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => RecordCareScreen(shift: widget.shift, carerId: carerId)));
    _loadLogs(); // always refresh after returning from Record Care
  }

  Future<void> _loadLogs() async {
    final suId = widget.shift.serviceUserId;
    if (suId == null) return;
    final date = widget.shift.scheduledDate != null
        ? DateTime.tryParse(widget.shift.scheduledDate!) ?? DateTime.now()
        : DateTime.now();
    final logs = await _logService.getLogs(serviceUserId: suId, date: date);
    if (mounted) setState(() { _logs = logs; _logsLoaded = true; });
  }

  Widget _buildLogCards() {
    final items = <_LogItem>[
      _LogItem('Daily Notes', Icons.edit_note, Colors.indigo, (_logs['daily_notes'] as int? ?? 0)),
      _LogItem('Food & Fluid', Icons.restaurant, Colors.orange, (_logs['food_fluid'] as int? ?? 0)),
      _LogItem('Bowel & Bladder', Icons.wc, Colors.brown, (_logs['bowel_bladder'] as int? ?? 0)),
      _LogItem('Repositioning', Icons.airline_seat_flat, Colors.teal, (_logs['repositioning'] as int? ?? 0)),
      _LogItem('Sleep Check', Icons.bedtime, Colors.deepPurple, (_logs['sleep'] as int? ?? 0)),
      _LogItem('Body Map', Icons.accessibility_new, Colors.red, (_logs['body_map'] as int? ?? 0)),
      _LogItem('MAR Chart', Icons.medication, Colors.pink, (_logs['mar'] as int? ?? 0)),
    ];
    final hasAny = items.any((i) => i.count > 0);
    if (!hasAny) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('No care records logged today. Tap \"Record Care\" to add.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.where((i) => i.count > 0).map((i) => _logCard(i)).toList(),
    );
  }

  Widget _logCard(_LogItem item) {
    return Material(
      color: item.color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openRecordCare(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(item.icon, size: 16, color: item.color),
            const SizedBox(width: 4),
            Text(item.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: item.color)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(10)),
              child: Text('${item.count}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LogItem {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  const _LogItem(this.label, this.icon, this.color, this.count);
}