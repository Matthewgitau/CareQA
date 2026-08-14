import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/models/shift.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/models/carer.dart';
import 'package:admin_app/services/database_service.dart';

class ShiftFormScreen extends StatefulWidget {
  final Shift? shift;

  const ShiftFormScreen({super.key, this.shift});

  @override
  State<ShiftFormScreen> createState() => _ShiftFormScreenState();
}

class _ShiftFormScreenState extends State<ShiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  
  // Dropdown selections
  ServiceUser? _selectedServiceUser;
  Carer? _selectedCarer;
  String? _selectedStatus;
  
  // Lists for dropdowns
  List<ServiceUser> _serviceUsers = [];
  List<Carer> _carers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.shift != null) {
      _selectedDate = widget.shift!.date;
      _selectedStartTime = TimeOfDay.fromDateTime(widget.shift!.startTime);
      _selectedEndTime = TimeOfDay.fromDateTime(widget.shift!.endTime);
      _selectedStatus = widget.shift!.status;
      _notesController.text = widget.shift!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    try {
      // Load service users and carers
      _serviceUsers = await databaseService.getServiceUsers();
      _carers = await databaseService.getCarers();
      
      // Set default selections for new shifts
      if (widget.shift == null) {
        if (_serviceUsers.isNotEmpty) _selectedServiceUser = _serviceUsers.first;
        if (_carers.isNotEmpty) _selectedCarer = _carers.first;
        _selectedStatus = 'scheduled';
      } else {
        // For editing, find the existing selections
        _selectedServiceUser = _serviceUsers.firstWhere(
          (su) => su.id == widget.shift!.serviceUserId,
orElse: () => _serviceUsers.first,
        );
        if (widget.shift!.carerId != null) {
          _selectedCarer = _carers.firstWhere(
            (c) => c.id == widget.shift!.carerId,
orElse: () => _carers.first,
          );
        } else {
          _selectedCarer = _carers.isNotEmpty ? _carers.first : null;
        }
      }
      
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  String? _validateEndTime(String? value) {
    if (_selectedStartTime != null && _selectedEndTime != null) {
      final start = DateTime(
        _selectedDate?.year ?? DateTime.now().year,
        _selectedDate?.month ?? DateTime.now().month,
        _selectedDate?.day ?? DateTime.now().day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );
      
      final end = DateTime(
        _selectedDate?.year ?? DateTime.now().year,
        _selectedDate?.month ?? DateTime.now().month,
        _selectedDate?.day ?? DateTime.now().day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );
      
      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        return 'End time must be after start time';
      }
    }
    return null;
  }

  String? _validateDate(String? value) {
    if (_selectedDate != null) {
      final today = DateTime.now();
      final selected = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      
      if (selected.isBefore(todayDate)) {
        return 'Date cannot be in the past';
      }
    }
    return null;
  }

  Future<void> _saveShift() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      try {
        if (_selectedDate == null || _selectedStartTime == null || _selectedEndTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select date and times')),
          );
          return;
        }

        if (_selectedServiceUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a service user')),
          );
          return;
        }

        // Combine date and time
        final startTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedStartTime!.hour,
          _selectedStartTime!.minute,
        );
        
        final endTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedEndTime!.hour,
          _selectedEndTime!.minute,
        );

        final shift = Shift(
          id: widget.shift?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          serviceUserId: _selectedServiceUser!.id,
          carerId: _selectedCarer?.id,
          date: _selectedDate!,
          startTime: startTime,
          endTime: endTime,
          status: _selectedStatus ?? 'scheduled',
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        if (widget.shift != null) {
          await databaseService.updateShift(shift);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shift updated successfully')),
          );
        } else {
          await databaseService.addShift(shift);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shift created successfully')),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shift != null ? 'Edit Shift' : 'Add Shift'),
      ),
      body: _serviceUsers.isEmpty || _carers.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Service User Dropdown
                  DropdownButtonFormField<ServiceUser>(
                    value: _selectedServiceUser,
                    decoration: const InputDecoration(
                      labelText: 'Service User',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _serviceUsers.map((serviceUser) {
                      return DropdownMenuItem(
                        value: serviceUser,
                        child: Text(serviceUser.name),
                      );
                    }).toList(),
                    onChanged: (ServiceUser? newValue) {
                      setState(() {
                        _selectedServiceUser = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a service user';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Carer Dropdown
                  DropdownButtonFormField<Carer>(
                    value: _selectedCarer,
                    decoration: const InputDecoration(
                      labelText: 'Carer',
                      prefixIcon: Icon(Icons.health_and_safety),
                    ),
                    items: _carers.map((carer) {
                      return DropdownMenuItem(
                        value: carer,
                        child: Text(carer.name ?? 'Unknown Carer'),
                      );
                    }).toList(),
                    onChanged: (Carer? newValue) {
                      setState(() {
                        _selectedCarer = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      hintText: _selectedDate != null 
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select date',
                    ),
                    readOnly: true,
                    onTap: _selectDate,
                    validator: (value) => _validateDate(value),
                  ),
                  const SizedBox(height: 20),

                  // Start Time Picker
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Start Time',
                      prefixIcon: const Icon(Icons.access_time),
                      hintText: _selectedStartTime != null 
                        ? _selectedStartTime!.format(context)
                        : 'Select start time',
                    ),
                    readOnly: true,
                    onTap: _selectStartTime,
                    validator: (value) {
                      if (_selectedStartTime == null) {
                        return 'Please select start time';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // End Time Picker
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'End Time',
                      prefixIcon: const Icon(Icons.access_time),
                      hintText: _selectedEndTime != null 
                        ? _selectedEndTime!.format(context)
                        : 'Select end time',
                    ),
                    readOnly: true,
                    onTap: _selectEndTime,
                    validator: (value) {
                      if (_selectedEndTime == null) {
                        return 'Please select end time';
                      }
                      return _validateEndTime(value);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.assignment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(value: 'in-progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a status';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Notes Field
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes),
                      hintText: 'Optional notes about this shift',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      // Notes are optional, so no validation needed
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Save Button
                  _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveShift,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                          ),
                          child: Text(widget.shift != null ? 'Update Shift' : 'Create Shift'),
                        ),
                      ),
                ],
              ),
            ),
          ),
    );
  }
}