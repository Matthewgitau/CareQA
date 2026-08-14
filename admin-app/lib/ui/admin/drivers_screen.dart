import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/driver.dart';
import '../../services/driver_service.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DriverService _driverService;
  late SupabaseClient _supabaseClient;
  final GlobalKey<_DriversListTabState> _driversListKey = GlobalKey<_DriversListTabState>();

  @override
  void initState() {
    super.initState();
    _supabaseClient = Supabase.instance.client;
    _driverService = DriverService(_supabaseClient);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Management'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Drivers', icon: Icon(Icons.people)),
            Tab(text: 'Vehicle Sign-Out', icon: Icon(Icons.directions_car)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Get the state from the DriversListTab and call _addDriver
          final state = _driversListKey.currentState;
          if (state != null) {
            state._addDriver();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DriversListTab(driverService: _driverService, supabaseClient: _supabaseClient, key: _driversListKey),
          VehicleSignOutTab(driverService: _driverService, supabaseClient: _supabaseClient),
        ],
      ),
    );
  }
}

// ==================== TAB 1: DRIVER MANAGEMENT ====================

class DriversListTab extends StatefulWidget {
  final DriverService driverService;
  final SupabaseClient supabaseClient;

  const DriversListTab({
    super.key,
    required this.driverService,
    required this.supabaseClient,
  });

  @override
  State<DriversListTab> createState() => _DriversListTabState();
}

class _DriversListTabState extends State<DriversListTab> {
  List<Driver> _drivers = [];
  List<Map<String, dynamic>> _carers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load drivers using service
      final drivers = await widget.driverService.getDrivers();
      
      // Load carers for linking - get more fields for auto-fill
      final carers = await widget.supabaseClient
          .from('carers')
          .select('id, name, employee_number, job_role, phone, date_of_birth');
      
      setState(() {
        _drivers = drivers;
        _carers = List<Map<String, dynamic>>.from(carers);
        _loading = false;
      });
    } catch (e) {
      setState(() { 
        _loading = false; 
        _error = e.toString(); 
      });
    }
  }

  // Helper to handle carer selection and auto-fill fields
  void _onCarerSelected(Function(Map<String, dynamic>?) onCarerFound) {
    // This will be called from the dialog with the selected carer ID
  }

  Future<void> _addDriver() async {
    final formKey = GlobalKey<FormState>();
    
    // Controllers for form fields
    final staffNameController = TextEditingController();
    final employeeIdController = TextEditingController();
    final jobRoleController = TextEditingController();
    final contactPhoneController = TextEditingController();
    final licenseNumberController = TextEditingController();
    final licenseCategoriesController = TextEditingController();
    final specialInstructionsController = TextEditingController();
    
    String? selectedCarerId;
    bool isExclusiveDriver = false;
    DateTime? dob;
    DateTime? licenseExpiry;
    DateTime? licenseIssueDate;
    bool fieldsLocked = false; // True when linked to a carer

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Handler for carer selection - ONLY sets staff_name, no duplication
          void handleCarerChange(String? carerId) {
            setDialogState(() {
              selectedCarerId = carerId;
              if (carerId != null && carerId.isNotEmpty) {
                // Find the selected carer
                final selectedCarer = _carers.firstWhere(
                  (c) => c['id'] == carerId,
                  orElse: () => <String, dynamic>{},
                );
                
                if (selectedCarer.isNotEmpty) {
                  // ONLY set staff_name - do NOT duplicate other fields
                  staffNameController.text = selectedCarer['name'] ?? '';
                  fieldsLocked = true;
                }
              } else {
                // No carer selected - exclusive driver mode
                staffNameController.clear();
                employeeIdController.clear();
                jobRoleController.clear();
                contactPhoneController.clear();
                dob = null;
                fieldsLocked = false;
              }
            });
          }

          final isExclusive = selectedCarerId == null || selectedCarerId!.isEmpty;

          return AlertDialog(
            title: const Text('Add Driver'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Link to Existing Carer (Optional)'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('-- None (Exclusive Driver) --')),
                        ..._carers.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? 'Unknown'))),
                      ],
                      value: selectedCarerId?.isEmpty ?? true ? null : selectedCarerId,
                      onChanged: handleCarerChange,
                    ),
                    const SizedBox(height: 12),
                    // Staff Name - always shown
                    TextFormField(
                      controller: staffNameController,
                      enabled: !fieldsLocked,
                      decoration: InputDecoration(
                        labelText: 'Staff Name *',
                        hintText: fieldsLocked ? 'Auto-filled from carer' : 'Enter staff name',
                      ),
                      validator: isExclusive
                          ? (v) => v?.isEmpty ?? true ? 'Required for exclusive drivers' : null
                          : null,
                    ),
                    // Fields only shown for Exclusive Drivers (not linked to carer)
                    if (isExclusive) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: employeeIdController,
                        decoration: const InputDecoration(labelText: 'Employee ID'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: jobRoleController,
                        decoration: const InputDecoration(labelText: 'Job Role'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactPhoneController,
                        decoration: const InputDecoration(labelText: 'Contact Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1940),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setDialogState(() => dob = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date of Birth'),
                          child: Text(dob != null ? DateFormat('dd/MM/yyyy').format(dob!) : 'Select date'),
                        ),
                      ),
                    ],
                    // License fields - always shown
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: licenseNumberController,
                      decoration: const InputDecoration(labelText: 'Driving Licence Number'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (date != null) setDialogState(() => licenseExpiry = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Licence Expiry'),
                        child: Text(licenseExpiry != null ? DateFormat('dd/MM/yyyy').format(licenseExpiry!) : 'Select date'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: licenseCategoriesController,
                      decoration: const InputDecoration(labelText: 'Licence Categories (e.g., B, B+E)'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365)),
                          firstDate: DateTime(1990),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setDialogState(() => licenseIssueDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Licence Issue Date'),
                        child: Text(licenseIssueDate != null ? DateFormat('dd/MM/yyyy').format(licenseIssueDate!) : 'Select date'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Exclusive Driver (not a carer)'),
                      value: isExclusiveDriver,
                      onChanged: (v) => setDialogState(() => isExclusiveDriver = v ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _saveDriver(
                      carerId: selectedCarerId?.isEmpty ?? true ? null : selectedCarerId,
                      staffName: staffNameController.text,
                      isExclusive: isExclusiveDriver || isExclusive,
                      employeeId: isExclusive ? employeeIdController.text : null,
                      jobRole: isExclusive ? jobRoleController.text : null,
                      contactPhone: isExclusive ? contactPhoneController.text : null,
                      dob: isExclusive ? dob : null,
                      licenseNumber: licenseNumberController.text.isNotEmpty ? licenseNumberController.text : null,
                      licenseExpiry: licenseExpiry,
                      licenseCategories: licenseCategoriesController.text.isNotEmpty ? licenseCategoriesController.text : null,
                      licenseIssueDate: licenseIssueDate,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveDriver({
    required String? carerId,
    required String staffName,
    required bool isExclusive,
    String? employeeId,
    String? jobRole,
    String? contactPhone,
    DateTime? dob,
    String? licenseNumber,
    DateTime? licenseExpiry,
    String? licenseCategories,
    DateTime? licenseIssueDate,
  }) async {
    try {
      final driver = Driver(
        id: '', // Will be generated by database
        carerId: carerId,
        isExclusiveDriver: isExclusive,
        staffName: staffName,
        employeeId: employeeId?.isNotEmpty ?? false ? employeeId : null,
        jobRole: jobRole?.isNotEmpty ?? false ? jobRole : null,
        contactPhone: contactPhone?.isNotEmpty ?? false ? contactPhone : null,
        dateOfBirth: dob,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        licenseCategories: licenseCategories,
        licenseIssueDate: licenseIssueDate,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await widget.driverService.addDriver(driver);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver added')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _editDriver(Driver driver) async {
    final formKey = GlobalKey<FormState>();
    
    // Controllers for form fields
    final staffNameController = TextEditingController(text: driver.staffName);
    final employeeIdController = TextEditingController(text: driver.employeeId ?? '');
    final jobRoleController = TextEditingController(text: driver.jobRole ?? '');
    final contactPhoneController = TextEditingController(text: driver.contactPhone ?? '');
    final licenseNumberController = TextEditingController(text: driver.licenseNumber ?? '');
    final licenseCategoriesController = TextEditingController(text: driver.licenseCategories ?? '');
    
    String? selectedCarerId = driver.carerId;
    bool isExclusiveDriver = driver.isExclusiveDriver;
    DateTime? dob = driver.dateOfBirth;
    DateTime? licenseExpiry = driver.licenseExpiry;
    DateTime? licenseIssueDate = driver.licenseIssueDate;
    bool fieldsLocked = selectedCarerId != null && selectedCarerId!.isNotEmpty;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Handler for carer selection - ONLY sets staff_name, no duplication
          void handleCarerChange(String? carerId) {
            setDialogState(() {
              selectedCarerId = carerId;
              if (carerId != null && carerId.isNotEmpty) {
                final selectedCarer = _carers.firstWhere(
                  (c) => c['id'] == carerId,
                  orElse: () => <String, dynamic>{},
                );
                
                if (selectedCarer.isNotEmpty) {
                  // ONLY set staff_name - do NOT duplicate other fields
                  staffNameController.text = selectedCarer['name'] ?? '';
                  fieldsLocked = true;
                }
              } else {
                // No carer selected - restore original values or clear
                staffNameController.text = driver.staffName;
                employeeIdController.text = driver.employeeId ?? '';
                jobRoleController.text = driver.jobRole ?? '';
                contactPhoneController.text = driver.contactPhone ?? '';
                dob = driver.dateOfBirth;
                fieldsLocked = false;
              }
            });
          }

          final isExclusive = selectedCarerId == null || selectedCarerId!.isEmpty;

          return AlertDialog(
            title: const Text('Edit Driver'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCarerId?.isEmpty ?? true ? null : selectedCarerId,
                      decoration: const InputDecoration(labelText: 'Link to Existing Carer (Optional)'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('-- None (Exclusive Driver) --')),
                        ..._carers.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? 'Unknown'))),
                      ],
                      onChanged: handleCarerChange,
                    ),
                    const SizedBox(height: 12),
                    // Staff Name - always shown
                    TextFormField(
                      controller: staffNameController,
                      enabled: !fieldsLocked,
                      decoration: InputDecoration(
                        labelText: 'Staff Name *',
                        hintText: fieldsLocked ? 'Auto-filled from carer' : null,
                      ),
                      validator: isExclusive
                          ? (v) => v?.isEmpty ?? true ? 'Required for exclusive drivers' : null
                          : null,
                    ),
                    // Fields only shown for Exclusive Drivers (not linked to carer)
                    if (isExclusive) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: employeeIdController,
                        decoration: const InputDecoration(labelText: 'Employee ID'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: jobRoleController,
                        decoration: const InputDecoration(labelText: 'Job Role'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactPhoneController,
                        decoration: const InputDecoration(labelText: 'Contact Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dob ?? DateTime.now(),
                            firstDate: DateTime(1940),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setDialogState(() => dob = date);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                          ),
                          child: Text(dob != null ? DateFormat('dd/MM/yyyy').format(dob!) : 'Select date'),
                        ),
                      ),
                    ],
                    // License fields - always shown
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: licenseNumberController,
                      decoration: const InputDecoration(labelText: 'Driving Licence Number'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: licenseExpiry ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (date != null) setDialogState(() => licenseExpiry = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Licence Expiry'),
                        child: Text(licenseExpiry != null ? DateFormat('dd/MM/yyyy').format(licenseExpiry!) : 'Select date'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: licenseCategoriesController,
                      decoration: const InputDecoration(labelText: 'Licence Categories (e.g., B, B+E)'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: licenseIssueDate ?? DateTime.now().subtract(const Duration(days: 365)),
                          firstDate: DateTime(1990),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setDialogState(() => licenseIssueDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Licence Issue Date'),
                        child: Text(licenseIssueDate != null ? DateFormat('dd/MM/yyyy').format(licenseIssueDate!) : 'Select date'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Exclusive Driver (not a carer)'),
                      value: isExclusiveDriver,
                      onChanged: (v) => setDialogState(() => isExclusiveDriver = v ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _updateDriver(
                      driverId: driver.id,
                      carerId: selectedCarerId?.isEmpty ?? true ? null : selectedCarerId,
                      staffName: staffNameController.text,
                      isExclusive: isExclusiveDriver || isExclusive,
                      employeeId: isExclusive ? employeeIdController.text : null,
                      jobRole: isExclusive ? jobRoleController.text : null,
                      contactPhone: isExclusive ? contactPhoneController.text : null,
                      dob: isExclusive ? dob : null,
                      licenseNumber: licenseNumberController.text.isNotEmpty ? licenseNumberController.text : null,
                      licenseExpiry: licenseExpiry,
                      licenseCategories: licenseCategoriesController.text.isNotEmpty ? licenseCategoriesController.text : null,
                      licenseIssueDate: licenseIssueDate,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateDriver({
    required String driverId,
    required String? carerId,
    required String staffName,
    required bool isExclusive,
    String? employeeId,
    String? jobRole,
    String? contactPhone,
    DateTime? dob,
    String? licenseNumber,
    DateTime? licenseExpiry,
    String? licenseCategories,
    DateTime? licenseIssueDate,
  }) async {
    try {
      final updatedDriver = Driver(
        id: driverId,
        carerId: carerId != null && carerId.isNotEmpty ? carerId : null,
        isExclusiveDriver: isExclusive,
        staffName: staffName,
        employeeId: employeeId?.isNotEmpty ?? false ? employeeId : null,
        jobRole: jobRole?.isNotEmpty ?? false ? jobRole : null,
        contactPhone: contactPhone?.isNotEmpty ?? false ? contactPhone : null,
        dateOfBirth: dob,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        licenseCategories: licenseCategories,
        licenseIssueDate: licenseIssueDate,
        isActive: true,
        createdAt: DateTime.now(), // Keep original created_at in real implementation
      );

      await widget.driverService.updateDriver(updatedDriver);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver updated')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteDriver(Driver driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete ${driver.staffName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.driverService.deleteDriver(driver.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver deleted')));
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addDriver,
            icon: const Icon(Icons.add),
            label: const Text('Add Driver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _drivers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No drivers found'),
                      SizedBox(height: 8),
                      Text('Tap the + button to add a driver'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _drivers.length,
                  itemBuilder: (context, index) {
                    final driver = _drivers[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            driver.staffName.isNotEmpty 
                                ? driver.staffName.substring(0, 1).toUpperCase() 
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(driver.staffName, 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('License: ${driver.licenseNumber ?? 'Not set'}',
                                style: TextStyle(color: Colors.grey[700])),
                            if (driver.licenseExpiry != null)
                              Text('Expires: ${DateFormat('dd/MM/yyyy').format(driver.licenseExpiry!)}',
                                  style: TextStyle(color: Colors.grey[700])),
                            if (driver.isExclusiveDriver) 
                              const Chip(
                                label: Text('Exclusive Driver', 
                                    style: TextStyle(color: Colors.white, fontSize: 12)),
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editDriver(driver),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDriver(driver),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==================== TAB 2: VEHICLE SIGN-OUT FORM ====================

class VehicleSignOutTab extends StatefulWidget {
  final DriverService driverService;
  final SupabaseClient supabaseClient;

  const VehicleSignOutTab({
    super.key,
    required this.driverService,
    required this.supabaseClient,
  });

  @override
  State<VehicleSignOutTab> createState() => _VehicleSignOutTabState();
}

class _VehicleSignOutTabState extends State<VehicleSignOutTab> {
  final _formKey = GlobalKey<FormState>();
  
  List<Driver> _drivers = [];
  List<Map<String, dynamic>> _vehicles = [];
  
  // Form fields
  String? _selectedDriverId;
  String? _selectedVehicleId;
  
  // Sign-Out Details
  DateTime? _signOutDate;
  TimeOfDay? _signOutTime;
  String? _startMileage;
  String? _fuelLevel;
  String? _existingDamage;
  String? _purpose;
  DateTime? _expectedReturnDate;
  
  // Liability
  bool _liabilityAccepted = false;
  bool _readPolicy = false;
  bool _insuranceConfirmed = false;
  bool _phonePolicyAccepted = false;
  bool _smokingPolicyAccepted = false;
  String? _specialInstructions;
  
  // Signatures
  String? _signedOutBy;
  String? _signedOutTo;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load drivers using service
      final drivers = await widget.driverService.getDrivers();
      
      // Load available vehicles
      final vehicles = await widget.supabaseClient
          .from('vehicles')
          .select('id, registration, make_model')
          .eq('status', 'available');
      
      setState(() {
        _drivers = drivers;
        _vehicles = List<Map<String, dynamic>>.from(vehicles);
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _submitSignOut() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_liabilityAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must accept liability terms')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get driver details for snapshot
      final driver = _drivers.isEmpty || _selectedDriverId == null
          ? null
          : _drivers.firstWhere(
              (d) => d.id == _selectedDriverId,
              orElse: () => Driver(
                id: '',
                staffName: 'Unknown',
                isActive: true,
                createdAt: DateTime.now(),
              ),
            );
      
      await widget.supabaseClient.from('vehicle_assignments').insert({
        'driver_id': _selectedDriverId,
        'vehicle_id': _selectedVehicleId,
        'sign_out_date': _signOutDate?.toIso8601String(),
        'sign_out_time': '${_signOutTime?.hour}:${_signOutTime?.minute}',
        'start_mileage': int.tryParse(_startMileage ?? '0'),
        'fuel_level_start': _fuelLevel,
        'existing_damage': _existingDamage,
        'purpose': _purpose,
        'expected_return_date': _expectedReturnDate?.toIso8601String(),
        'liability_accepted': _liabilityAccepted,
        'read_policy': _readPolicy,
        'insurance_confirmed': _insuranceConfirmed,
        'phone_policy_accepted': _phonePolicyAccepted,
        'smoking_policy_accepted': _smokingPolicyAccepted,
        'special_instructions': _specialInstructions,
        'signed_out_by': _signedOutBy,
        'signed_out_to': _signedOutTo,
        'status': 'active',
        // Driver snapshot data
        'driver_name': driver?.staffName ?? 'Unknown',
        'employee_id': driver?.employeeId,
        'job_role': driver?.jobRole,
        'contact_phone': driver?.contactPhone,
        'license_number': driver?.licenseNumber,
        'license_expiry': driver?.licenseExpiry?.toIso8601String(),
        'license_categories': driver?.licenseCategories,
        'license_checked': driver?.licenseChecked,
        'has_endorsements': driver?.hasEndorsements,
        'endorsement_details': driver?.endorsementDetails,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle signed out successfully')));
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedDriverId = null;
      _selectedVehicleId = null;
      _signOutDate = null;
      _signOutTime = null;
      _startMileage = null;
      _fuelLevel = null;
      _existingDamage = null;
      _purpose = null;
      _expectedReturnDate = null;
      _liabilityAccepted = false;
      _readPolicy = false;
      _insuranceConfirmed = false;
      _phonePolicyAccepted = false;
      _smokingPolicyAccepted = false;
      _specialInstructions = null;
      _signedOutBy = null;
      _signedOutTo = null;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Driver & Vehicle Selection'),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Driver *', border: OutlineInputBorder()),
              items: _drivers.isEmpty
                  ? [const DropdownMenuItem<String>(value: null, child: Text('No drivers available'))]
                  : _drivers.map((d) => DropdownMenuItem<String>(value: d.id, child: Text(d.staffName))).toList(),
              onChanged: _drivers.isEmpty ? null : (v) => setState(() => _selectedDriverId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Vehicle *', border: OutlineInputBorder()),
              items: _vehicles.isEmpty
                  ? [const DropdownMenuItem<String>(value: null, child: Text('No vehicles available'))]
                  : _vehicles.map((v) => DropdownMenuItem<String>(value: v['id'].toString(), child: Text('${v['registration']} - ${v['make_model']}'))).toList(),
              onChanged: _vehicles.isEmpty ? null : (v) => setState(() => _selectedVehicleId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            
            _buildSection('Sign-Out Details'),
            _buildDateField('Sign-Out Date', (d) => _signOutDate = d, required: true),
            _buildTimeField('Sign-Out Time', (t) => _signOutTime = t, required: true),
            _buildTextField('Starting Mileage', (v) => _startMileage = v, keyboardType: TextInputType.number),
            _buildDropdown('Fuel Level', ['Full', '¾', '½', '¼', 'Empty'], (v) => _fuelLevel = v),
            _buildTextField('Existing Damage', (v) => _existingDamage = v, maxLines: 2),
            _buildTextField('Purpose of Journey', (v) => _purpose = v, maxLines: 2),
            _buildDateField('Expected Return Date', (d) => _expectedReturnDate = d),
            
            _buildSection('Liability Acknowledgement'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  const Text(
                    'I acknowledge that I am personally liable for any legal issues, accidents, damage, '
                    'fines, penalties, or claims that arise during my use of this vehicle. I will drive safely, '
                    'comply with all road traffic laws, and report any incident immediately.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('I have read, understood, and agree to the liability terms.'),
                    value: _liabilityAccepted,
                    onChanged: (v) => setState(() => _liabilityAccepted = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('I have read the company\'s Vehicle/Driving Policy'),
                    value: _readPolicy,
                    onChanged: (v) => setState(() => _readPolicy = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Valid business insurance cover confirmed'),
                    value: _insuranceConfirmed,
                    onChanged: (v) => setState(() => _insuranceConfirmed = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Mobile phone / hands-free policy acknowledged'),
                    value: _phonePolicyAccepted,
                    onChanged: (v) => setState(() => _phonePolicyAccepted = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Smoking / vaping / eating/drinking in vehicle policy acknowledged'),
                    value: _smokingPolicyAccepted,
                    onChanged: (v) => setState(() => _smokingPolicyAccepted = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  _buildTextField('Special Instructions', (v) => _specialInstructions = v, maxLines: 2),
                ],
              ),
            ),
            
            _buildSection('Signatures'),
            _buildTextField('Signed Out By (Company Representative)', (v) => _signedOutBy = v, required: true),
            _buildTextField('Signed Out To (Driver)', (v) => _signedOutTo = v, required: true),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSignOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting ? const CircularProgressIndicator() : const Text('Sign Out Vehicle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
    );
  }

  Widget _buildTextField(String label, Function(String) onSaved, {TextInputType? keyboardType, int maxLines = 1, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixText: required ? '*' : null),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required ? (v) => v?.isEmpty ?? true ? 'Required' : null : null,
        onSaved: (v) => onSaved(v ?? ''),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField(String label, Function(DateTime) onSelected, {bool required = false}) {
    DateTime? _selectedDate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
          if (date != null) { _selectedDate = date; onSelected(date); setState(() {}); }
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixText: required ? '*' : null),
          child: Text(_selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Select date'),
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, Function(TimeOfDay) onSelected, {bool required = false}) {
    TimeOfDay? _selectedTime;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (time != null) { _selectedTime = time; onSelected(time); setState(() {}); }
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixText: required ? '*' : null),
          child: Text(_selectedTime != null ? _selectedTime!.format(context) : 'Select time'),
        ),
      ),
    );
  }
}