import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/shift_rota.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/models/carer.dart';
import 'package:admin_app/services/shift_rota_service.dart';
import 'package:admin_app/services/database_service.dart';

class ShiftRotaFormScreen extends StatefulWidget {
  final SupabaseClient supabaseClient;
  final ShiftRotaService shiftRotaService;
  final DatabaseService firestoreService;
  final VoidCallback onShiftCreated;

  const ShiftRotaFormScreen({
    Key? key,
    required this.supabaseClient,
    required this.shiftRotaService,
    required this.firestoreService,
    required this.onShiftCreated,
  }) : super(key: key);

  @override
  _ShiftRotaFormScreenState createState() => _ShiftRotaFormScreenState();
}

class _ShiftRotaFormScreenState extends State<ShiftRotaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  String _selectedServiceUserId = '';
  String _selectedCarerId = '';
  String _selectedShiftType = 'Morning';
  String _selectedDayOfWeek = 'Monday';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(hours: 4));
  bool _isRecurring = false;
  int _recurringWeeks = 1;

  late Stream<List<ServiceUser>> _serviceUsersStream;
  late Stream<List<Carer>> _carersStream;

  @override
  void initState() {
    super.initState();
    _serviceUsersStream = widget.firestoreService.getServiceUsers();
    _carersStream = widget.firestoreService.getCarers();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2030, 12),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _endDate = picked.add(Duration(hours: _endDate.difference(_startDate).inHours));
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030, 12),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          picked.hour,
          picked.minute,
        );
        _endDate = _startDate.add(Duration(hours: _endDate.difference(_startDate).inHours));
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDate),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _createShift() async {
    if (_formKey.currentState!.validate()) {
      try {
        final shiftRota = ShiftRota(
          id: '',
          serviceUserId: _selectedServiceUserId,
          carerId: _selectedCarerId,
          startDate: _startDate,
          endDate: _endDate,
          shiftType: _selectedShiftType,
          dayOfWeek: _selectedDayOfWeek,
          weekRange: _getWeekRange(_startDate),
          notes: _notesController.text,
          isRecurring: _isRecurring,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: widget.supabaseClient.auth.currentUser?.id ?? '',
          status: 'Scheduled',
        );

        await widget.shiftRotaService.createShiftRota(shiftRota);
        
        if (_isRecurring && _recurringWeeks > 1) {
          await widget.shiftRotaService.createRecurringShifts(shiftRota, _recurringWeeks);
        }

        widget.onShiftCreated();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating shift: $e')),
        );
      }
    }
  }

  String _getWeekRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    
    final startDay = startOfWeek.day;
    final startMonth = startOfWeek.month;
    final startYear = startOfWeek.year;
    
    return "w/c ${startDay} ${_getMonthName(startMonth)} ${startYear}";
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Shift'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Service User Selection
              StreamBuilder<List<ServiceUser>>(
                stream: _serviceUsersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final serviceUsers = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: _selectedServiceUserId.isEmpty ? null : _selectedServiceUserId,
                      decoration: const InputDecoration(
                        labelText: 'Service User',
                        border: OutlineInputBorder(),
                      ),
                      items: serviceUsers.map((user) => DropdownMenuItem(
                        value: user.id,
                        child: Text(user.name),
                      )).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a service user';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedServiceUserId = value ?? '';
                        });
                      },
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
              
              const SizedBox(height: 16),

              // Carer Selection
              StreamBuilder<List<Carer>>(
                stream: _carersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final carers = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: _selectedCarerId.isEmpty ? null : _selectedCarerId,
                      decoration: const InputDecoration(
                        labelText: 'Carer',
                        border: OutlineInputBorder(),
                      ),
                      items: carers.map((carer) => DropdownMenuItem(
                        value: carer.id,
                        child: Text(carer.name),
                      )).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a carer';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedCarerId = value ?? '';
                        });
                      },
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
              
              const SizedBox(height: 16),

              // Shift Type
              DropdownButtonFormField<String>(
                value: _selectedShiftType,
                decoration: const InputDecoration(
                  labelText: 'Shift Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                  DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'Tea', child: Text('Tea')),
                  DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedShiftType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),

              // Day of Week
              DropdownButtonFormField<String>(
                value: _selectedDayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Monday', child: Text('Monday')),
                  DropdownMenuItem(value: 'Tuesday', child: Text('Tuesday')),
                  DropdownMenuItem(value: 'Wednesday', child: Text('Wednesday')),
                  DropdownMenuItem(value: 'Thursday', child: Text('Thursday')),
                  DropdownMenuItem(value: 'Friday', child: Text('Friday')),
                  DropdownMenuItem(value: 'Saturday', child: Text('Saturday')),
                  DropdownMenuItem(value: 'Sunday', child: Text('Sunday')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDayOfWeek = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),

              // Start Date and Time
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectStartDate(context),
                      child: Text('Start Date: ${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectStartTime(context),
                      child: Text('Start Time: ${_startDate.hour.toString().padLeft(2, '0')}:${_startDate.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // End Date and Time
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectEndDate(context),
                      child: Text('End Date: ${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectEndTime(context),
                      child: Text('End Time: ${_endDate.hour.toString().padLeft(2, '0')}:${_endDate.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Recurring Shift
              Row(
                children: [
                  Checkbox(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value!;
                      });
                    },
                  ),
                  const Text('Recurring Shift'),
                  const SizedBox(width: 16),
                  if (_isRecurring)
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _recurringWeeks,
                        decoration: const InputDecoration(
                          labelText: 'Number of Weeks',
                          border: OutlineInputBorder(),
                        ),
                        items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((weeks) => DropdownMenuItem(
                          value: weeks,
                          child: Text('$weeks weeks'),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _recurringWeeks = value!;
                          });
                        },
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Any special instructions or notes',
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _createShift,
                child: const Text('Create Shift'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}