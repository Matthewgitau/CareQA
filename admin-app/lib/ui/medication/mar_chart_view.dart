import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MarChartViewScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const MarChartViewScreen({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
  }) : super(key: key);

  @override
  State<MarChartViewScreen> createState() => _MarChartViewScreenState();
}

class _MarChartViewScreenState extends State<MarChartViewScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _administrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadMedications(),
        _loadAdministrations(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMedications() async {
    final response = await Supabase.instance.client
        .from('mar_medications')
        .select('*')
        .eq('service_user_id', widget.serviceUserId)
        .eq('is_active', true)
        .lte('start_date', DateFormat('yyyy-MM-dd').format(_selectedDate))
        .or('end_date.is.null,end_date.gte.${DateFormat('yyyy-MM-dd').format(_selectedDate)}')
        .order('medication_name');

    setState(() {
      _medications = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _loadAdministrations() async {
    final response = await Supabase.instance.client
        .from('mar_administration_logs')
        .select('*, mar_medications(medication_name, frequency_times)')
        .gte('scheduled_time', '${DateFormat('yyyy-MM-dd').format(_selectedDate)}T00:00:00')
        .lte('scheduled_time', '${DateFormat('yyyy-MM-dd').format(_selectedDate)}T23:59:59');

    setState(() {
      _administrations = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadData();
    }
  }

  String? _getAdministrationStatus(String medicationId, String time) {
    final admin = _administrations.where((a) {
      final med = a['mar_medications'] as Map<String, dynamic>?;
      return a['medication_id'] == medicationId && 
             (med?['frequency_times'] as List?)?.contains(time) == true;
    }).firstOrNull;
    
    return admin?['status'] as String?;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'given':
        return Colors.green;
      case 'missed':
        return Colors.red;
      case 'refused':
        return Colors.orange;
      case 'withheld':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'given':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      case 'refused':
        return Icons.block;
      case 'withheld':
        return Icons.pause_circle;
      default:
        return Icons.access_time;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'given':
        return 'Given';
      case 'missed':
        return 'Missed';
      case 'refused':
        return 'Refused';
      case 'withheld':
        return 'Withheld';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MAR Chart (Read Only)'),
            Text(
              widget.serviceUserName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
              ? const Center(child: Text('No active medications found'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _medications.length,
                    itemBuilder: (context, index) {
                      final med = _medications[index];
                      final times = List<String>.from(med['frequency_times'] ?? []);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med['medication_name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${med['dosage']} - ${med['route']} - ${med['frequency']}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (med['prescribed_by'] != null)
                                Text(
                                  'Prescribed by: ${med['prescribed_by']}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              const Divider(height: 24),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: times.map((time) {
                                  final status = _getAdministrationStatus(med['id'], time);
                                  return _buildTimeSlotChip(time, status);
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildTimeSlotChip(String time, String? status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$time - $label',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}