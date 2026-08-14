import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/shift_rota.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/models/carer.dart';
import 'package:admin_app/services/shift_rota_service.dart';
import 'package:admin_app/services/database_service.dart';

class ShiftRotaViewScreen extends StatefulWidget {
  final SupabaseClient supabaseClient;
  final ShiftRotaService shiftRotaService;
  final ShiftRota shiftRota;
  final VoidCallback onShiftUpdated;

  const ShiftRotaViewScreen({
    Key? key,
    required this.supabaseClient,
    required this.shiftRotaService,
    required this.shiftRota,
    required this.onShiftUpdated,
  }) : super(key: key);

  @override
  _ShiftRotaViewScreenState createState() => _ShiftRotaViewScreenState();
}

class _ShiftRotaViewScreenState extends State<ShiftRotaViewScreen> {
  late ShiftRota _currentShift;
  late Stream<List<ServiceUser>> _serviceUsersStream;
  late Stream<List<Carer>> _carersStream;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentShift = widget.shiftRota;
    _serviceUsersStream = widget.shiftRotaService.databaseService.getServiceUsers();
    _carersStream = widget.shiftRotaService.databaseService.getCarers();
  }

  Future<void> _updateShift() async {
    try {
      await widget.shiftRotaService.updateShiftRota(_currentShift.id, _currentShift);
      widget.onShiftUpdated();
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating shift: $e')),
      );
    }
  }

  Future<void> _deleteShift() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shift'),
        content: const Text('Are you sure you want to delete this shift?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.shiftRotaService.deleteShiftRota(_currentShift.id);
        widget.onShiftUpdated();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting shift: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _currentShift = _currentShift.copyWith(status: newStatus);
    });
    await _updateShift();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateShift,
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteShift,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Shift Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shift Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Shift Type
                    Row(
                      children: [
                        const Text('Shift Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_isEditing)
                          DropdownButton<String>(
                            value: _currentShift.shiftType,
                            items: const [
                              DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                              DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                              DropdownMenuItem(value: 'Tea', child: Text('Tea')),
                              DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _currentShift = _currentShift.copyWith(shiftType: value!);
                              });
                            },
                          )
                        else
                          Text(_currentShift.shiftType),
                      ],
                    ),
                    
                    const SizedBox(height: 8),

                    // Day of Week
                    Row(
                      children: [
                        const Text('Day of Week:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_isEditing)
                          DropdownButton<String>(
                            value: _currentShift.dayOfWeek,
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
                                _currentShift = _currentShift.copyWith(dayOfWeek: value!);
                              });
                            },
                          )
                        else
                          Text(_currentShift.dayOfWeek),
                      ],
                    ),
                    
                    const SizedBox(height: 8),

                    // Week Range
                    Row(
                      children: [
                        const Text('Week Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(_currentShift.weekRange),
                      ],
                    ),
                    
                    const SizedBox(height: 8),

                    // Status
                    Row(
                      children: [
                        const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_isEditing)
                          DropdownButton<String>(
                            value: _currentShift.status,
                            items: const [
                              DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                              DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                              DropdownMenuItem(value: 'Swapped', child: Text('Swapped')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _currentShift = _currentShift.copyWith(status: value!);
                              });
                            },
                          )
                        else
                          Chip(
                            label: Text(_currentShift.status),
                            backgroundColor: _getStatusColor(_currentShift.status),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date and Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date and Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        const Text('Start:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _currentShift.startDate,
                                firstDate: DateTime(2020, 1),
                                lastDate: DateTime(2030, 12),
                              );
                              if (picked != null) {
                                setState(() {
                                  _currentShift = _currentShift.copyWith(
                                    startDate: picked,
                                    endDate: picked.add(Duration(hours: _currentShift.endDate.difference(_currentShift.startDate).inHours)),
                                  );
                                });
                              }
                            },
                            child: Text('Date: ${_currentShift.startDate.day}/${_currentShift.startDate.month}/${_currentShift.startDate.year}'),
                          )
                        else
                          Text('${_currentShift.startDate.day}/${_currentShift.startDate.month}/${_currentShift.startDate.year}'),
                      ],
                    ),
                    
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Text('Start Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_currentShift.startDate),
                              );
                              if (picked != null) {
                                setState(() {
                                  _currentShift = _currentShift.copyWith(
                                    startDate: DateTime(
                                      _currentShift.startDate.year,
                                      _currentShift.startDate.month,
                                      _currentShift.startDate.day,
                                      picked.hour,
                                      picked.minute,
                                    ),
                                  );
                                });
                              }
                            },
                            child: Text('${_currentShift.startDate.hour.toString().padLeft(2, '0')}:${_currentShift.startDate.minute.toString().padLeft(2, '0')}'),
                          )
                        else
                          Text('${_currentShift.startDate.hour.toString().padLeft(2, '0')}:${_currentShift.startDate.minute.toString().padLeft(2, '0')}'),
                      ],
                    ),
                    
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Text('End:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _currentShift.endDate,
                                firstDate: _currentShift.startDate,
                                lastDate: DateTime(2030, 12),
                              );
                              if (picked != null) {
                                setState(() {
                                  _currentShift = _currentShift.copyWith(endDate: picked);
                                });
                              }
                            },
                            child: Text('Date: ${_currentShift.endDate.day}/${_currentShift.endDate.month}/${_currentShift.endDate.year}'),
                          )
                        else
                          Text('${_currentShift.endDate.day}/${_currentShift.endDate.month}/${_currentShift.endDate.year}'),
                      ],
                    ),
                    
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Text('End Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_currentShift.endDate),
                              );
                              if (picked != null) {
                                setState(() {
                                  _currentShift = _currentShift.copyWith(
                                    endDate: DateTime(
                                      _currentShift.endDate.year,
                                      _currentShift.endDate.month,
                                      _currentShift.endDate.day,
                                      picked.hour,
                                      picked.minute,
                                    ),
                                  );
                                });
                              }
                            },
                            child: Text('${_currentShift.endDate.hour.toString().padLeft(2, '0')}:${_currentShift.endDate.minute.toString().padLeft(2, '0')}'),
                          )
                        else
                          Text('${_currentShift.endDate.hour.toString().padLeft(2, '0')}:${_currentShift.endDate.minute.toString().padLeft(2, '0')}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Service User
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    StreamBuilder<List<ServiceUser>>(
                      stream: _serviceUsersStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final serviceUsers = snapshot.data!;
                          final serviceUser = serviceUsers.firstWhere(
                            (user) => user.id == _currentShift.serviceUserId,
                            orElse: () => ServiceUser(
                              id: _currentShift.serviceUserId,
                              name: 'Unknown Service User',
                              address: '',
                              notes: '',
                              createdAt: DateTime.now(),
                            ),
                          );
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  if (_isEditing)
                                    DropdownButton<String>(
                                      value: _currentShift.serviceUserId,
                                      items: serviceUsers.map((user) => DropdownMenuItem(
                                        value: user.id,
                                        child: Text(user.name),
                                      )).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _currentShift = _currentShift.copyWith(serviceUserId: value ?? '');
                                        });
                                      },
                                    )
                                  else
                                    Text(serviceUser.name),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Row(
                                children: [
                                  const Text('Address:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(serviceUser.address),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Row(
                                children: [
                                  const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(serviceUser.notes),
                                ],
                              ),
                            ],
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Carer
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    StreamBuilder<List<Carer>>(
                      stream: _carersStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final carers = snapshot.data!;
                          final carer = carers.firstWhere(
                            (c) => c.id == _currentShift.carerId,
                            orElse: () => Carer(
                              id: _currentShift.carerId,
                              name: 'Unknown Carer',
                              email: '',
                              phone: '',
                              employeeNumber: '',
                              dbsNumber: '',
                              dbsExpiryDate: null,
                              dbsCertificateUrl: '',
                              idDocumentUrl: '',
                              idExpiryDate: null,
                              rightToWorkExpiry: null,
                              trainingRecords: {},
                              isActive: true,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                          );
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  if (_isEditing)
                                    DropdownButton<String>(
                                      value: _currentShift.carerId,
                                      items: carers.map((carer) => DropdownMenuItem(
                                        value: carer.id,
                                        child: Text(carer.name ?? ''),
                                      )).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _currentShift = _currentShift.copyWith(carerId: value ?? '');
                                        });
                                      },
                                    )
                                  else
                                    Text(carer.name ?? ''),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Row(
                                children: [
                                  const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(carer.email ?? ''),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Row(
                                children: [
                                  const Text('Phone:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(carer.phone ?? ''),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Row(
                                children: [
                                  const Text('Employee No:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(carer.employeeNumber ?? ''),
                                ],
                              ),
                            ],
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isEditing)
                      TextField(
                        controller: TextEditingController(text: _currentShift.notes),
                        onChanged: (value) {
                          setState(() {
                            _currentShift = _currentShift.copyWith(notes: value);
                          });
                        },
                        maxLines: 4,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Any special instructions or notes',
                        ),
                      )
                    else
                      Text(_currentShift.notes.isNotEmpty ? _currentShift.notes : 'No notes'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions
            if (!_isEditing)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus('Completed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Mark Complete'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus('Cancelled'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus('Scheduled'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Reschedule'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus('Swapped'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('Swap'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.orange.withOpacity(0.2);
      case 'Completed':
        return Colors.green.withOpacity(0.2);
      case 'Cancelled':
        return Colors.red.withOpacity(0.2);
      case 'Swapped':
        return Colors.blue.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }
}