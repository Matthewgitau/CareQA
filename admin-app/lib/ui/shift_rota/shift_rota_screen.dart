import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/shift_rota.dart';
import 'package:admin_app/services/shift_rota_service.dart';
import 'package:admin_app/ui/shift/shift_form_screen.dart';
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
      List<ShiftRota> data;
      switch (_selectedView) {
        case ShiftViewType.domCareRoutes:
          data = await service.getDomCareRoutes();
          break;
        case ShiftViewType.careHomeShifts:
          data = await service.getCareHomeShifts();
          break;
        case ShiftViewType.warehouseShifts:
          data = await service.getWarehouseShifts();
          break;
      }
      setState(() {
        _rotas = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shifts: $e')),
        );
      }
    }
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
          // Shift list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rotas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No ${_selectedView.name.replaceAll('_', ' ')} found',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
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
                                  child: Icon(Icons.schedule, color: color),
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
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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