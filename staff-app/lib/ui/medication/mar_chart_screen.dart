import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MarChartScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const MarChartScreen({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
  }) : super(key: key);

  @override
  State<MarChartScreen> createState() => _MarChartScreenState();
}

class _MarChartScreenState extends State<MarChartScreen> {
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
        .from('mar_administrations')
        .select('*, mar_medications(medication_name, times)')
        .eq('administered_date', DateFormat('yyyy-MM-dd').format(_selectedDate));

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

  Future<void> _recordAdministration(
    String medicationId,
    String scheduledTime,
    String status,
  ) async {
    if (status == 'refused') {
      final reason = await _showRefusalReasonDialog();
      if (reason == null) return;
      
      await Supabase.instance.client.from('mar_administrations').insert({
        'medication_id': medicationId,
        'scheduled_time': scheduledTime,
        'administered_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'administered_time': TimeOfDay.now().hour.toString().padLeft(2, '0') + ':' + TimeOfDay.now().minute.toString().padLeft(2, '0'),
        'status': status,
        'refusal_reason': reason,
      });
    } else {
      await Supabase.instance.client.from('mar_administrations').insert({
        'medication_id': medicationId,
        'scheduled_time': scheduledTime,
        'administered_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'administered_time': TimeOfDay.now().hour.toString().padLeft(2, '0') + ':' + TimeOfDay.now().minute.toString().padLeft(2, '0'),
        'status': status,
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medication marked as $status')),
      );
      await _loadData();
    }
  }

  Future<String?> _showRefusalReasonDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refusal Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for refusal',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String? _getAdministrationStatus(String medicationId, String time) {
    final admin = _administrations.where((a) {
      final med = a['mar_medications'] as Map<String, dynamic>?;
      return a['medication_id'] == medicationId && 
             (med?['times'] as List?)?.contains(time) == true;
    }).firstOrNull;
    
    return admin?['status'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MAR Chart', style: Theme.of(context).textTheme.titleLarge),
            Text(
              widget.serviceUserName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
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
                      final times = List<String>.from(med['times'] ?? []);
                      
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
                                  return _buildTimeSlotButton(med['id'], time, status);
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

  Widget _buildTimeSlotButton(String medicationId, String time, String? status) {
    final isPast = _isTimePast(time);
    final hasRecord = status != null && status != 'pending';

    Color buttonColor;
    IconData icon;
    String label;

    if (hasRecord) {
      switch (status) {
        case 'given':
          buttonColor = Colors.green;
          icon = Icons.check_circle;
          label = 'Given';
          break;
        case 'missed':
          buttonColor = Colors.red;
          icon = Icons.cancel;
          label = 'Missed';
          break;
        case 'refused':
          buttonColor = Colors.orange;
          icon = Icons.block;
          label = 'Refused';
          break;
        case 'withheld':
          buttonColor = Colors.grey;
          icon = Icons.pause_circle;
          label = 'Withheld';
          break;
        default:
          buttonColor = Colors.blue;
          icon = Icons.access_time;
          label = time;
      }
    } else {
      buttonColor = isPast ? Colors.orange : Colors.blue;
      icon = Icons.access_time;
      label = time;
    }

    return GestureDetector(
      onTap: hasRecord
          ? null
          : () => _showAdministrationOptions(medicationId, time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(8),
          border: hasRecord ? Border.all(color: Colors.white24) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  bool _isTimePast(String time) {
    final now = TimeOfDay.now();
    final parts = time.split(':');
    final scheduledHour = int.parse(parts[0]);
    final scheduledMinute = int.parse(parts[1]);
    return now.hour > scheduledHour || 
           (now.hour == scheduledHour && now.minute >= scheduledMinute);
  }

  void _showAdministrationOptions(String medicationId, String time) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark as Given'),
              onTap: () {
                Navigator.pop(context);
                _recordAdministration(medicationId, time, 'given');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Mark as Missed'),
              onTap: () {
                Navigator.pop(context);
                _recordAdministration(medicationId, time, 'missed');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Mark as Refused'),
              onTap: () {
                Navigator.pop(context);
                _recordAdministration(medicationId, time, 'refused');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle, color: Colors.grey),
              title: const Text('Mark as Withheld'),
              onTap: () {
                Navigator.pop(context);
                _recordAdministration(medicationId, time, 'withheld');
              },
            ),
          ],
        ),
      ),
    );
  }
}