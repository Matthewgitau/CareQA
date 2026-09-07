import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/models/carer.dart';
import 'package:admin_app/services/database_service.dart';
import 'package:admin_app/services/carer_invite_service.dart';
import 'package:admin_app/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CarerFormScreen extends StatefulWidget {
  final Carer? carer;

  const CarerFormScreen({super.key, this.carer});

  @override
  State<CarerFormScreen> createState() => _CarerFormScreenState();
}

class _CarerFormScreenState extends State<CarerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Information
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Employment
  final _employeeNumberController = TextEditingController();
  
  // Documents
  final _dbsNumberController = TextEditingController();
  final _dbsCertificateUrlController = TextEditingController();
  final _proofOfIdUrlController = TextEditingController();
  final _proofOfResidenceUrlController = TextEditingController();
  
  // Training Certificates
  final _infectionControlUrlController = TextEditingController();
  final _manualHandlingUrlController = TextEditingController();
  final _safeguardingUrlController = TextEditingController();
  
  // Employment Details
  final _sortCodeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _photoUrlController = TextEditingController();

  // Staff Login
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _staffRole = 'carer';
  bool _createLogin = false;

  bool _isLoading = false;
  
  // Date selections
  DateTime? _dbsExpiryDate;
  DateTime? _proofOfIdExpiry;
  DateTime? _proofOfResidenceExpiry;
  DateTime? _infectionControlExpiry;
  DateTime? _manualHandlingExpiry;
  DateTime? _safeguardingExpiry;
  DateTime? _fitnessToWorkExpiry;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    if (widget.carer != null) {
      _nameController.text = widget.carer!.name ?? '';
      _emailController.text = widget.carer!.email ?? '';
      _phoneController.text = widget.carer!.phone ?? '';
      _employeeNumberController.text = widget.carer!.employeeNumber ?? '';
      _dbsNumberController.text = widget.carer!.dbsNumber ?? '';
      _dbsCertificateUrlController.text = widget.carer!.dbsCertificateUrl ?? '';
      _proofOfIdUrlController.text = widget.carer!.idDocumentUrl ?? '';
      _proofOfResidenceUrlController.text = widget.carer!.proofOfResidenceUrl ?? '';
      _infectionControlUrlController.text = widget.carer!.infectionControlUrl ?? '';
      _manualHandlingUrlController.text = widget.carer!.manualHandlingUrl ?? '';
      _safeguardingUrlController.text = widget.carer!.safeguardingUrl ?? '';
      _sortCodeController.text = widget.carer!.sortCode ?? '';
      _accountNumberController.text = widget.carer!.accountNumber ?? '';
      _photoUrlController.text = widget.carer!.photoUrl ?? '';
      
      _dbsExpiryDate = widget.carer!.dbsExpiryDate;
      _proofOfIdExpiry = widget.carer!.idExpiryDate;
      _proofOfResidenceExpiry = widget.carer!.proofOfResidenceExpiry;
      _infectionControlExpiry = widget.carer!.infectionControlExpiry;
      _manualHandlingExpiry = widget.carer!.manualHandlingExpiry;
      _safeguardingExpiry = widget.carer!.safeguardingExpiry;
      _fitnessToWorkExpiry = widget.carer!.fitnessToWorkExpiry;
      _dateOfBirth = widget.carer!.dateOfBirth;
      _addressController.text = widget.carer!.address ?? '';
      _staffRole = widget.carer!.staffType ?? widget.carer!.jobRole ?? 'carer';
      if (_staffRole != 'carer' && _staffRole != 'senior_carer' &&
          _staffRole != 'team_leader' && _staffRole != 'manager' &&
          _staffRole != 'admin' && _staffRole != 'super_admin') {
        _staffRole = 'carer';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeNumberController.dispose();
    _dbsNumberController.dispose();
    _dbsCertificateUrlController.dispose();
    _proofOfIdUrlController.dispose();
    _proofOfResidenceUrlController.dispose();
    _infectionControlUrlController.dispose();
    _manualHandlingUrlController.dispose();
    _safeguardingUrlController.dispose();
    _sortCodeController.dispose();
    _accountNumberController.dispose();
    _photoUrlController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(String field) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      setState(() {
        switch (field) {
          case 'dbs':
            _dbsExpiryDate = picked;
            break;
          case 'proofOfId':
            _proofOfIdExpiry = picked;
            break;
          case 'proofOfResidence':
            _proofOfResidenceExpiry = picked;
            break;
          case 'infectionControl':
            _infectionControlExpiry = picked;
            break;
          case 'manualHandling':
            _manualHandlingExpiry = picked;
            break;
          case 'safeguarding':
            _safeguardingExpiry = picked;
            break;
          case 'fitnessToWork':
            _fitnessToWorkExpiry = picked;
            break;
        }
      });
    }
  }

  String? _validateSortCode(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Sort code must be 6 digits';
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length != 8 || !RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'Account number must be 8 digits';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      return 'Please enter a valid URL (starting with http:// or https://)';
    }
    return null;
  }

  Future<void> _saveCarer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      try {
        final carer = Carer(
          id: widget.carer?.id ?? '', // Empty for new carers - Supabase generates UUID
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          employeeNumber: _employeeNumberController.text.trim(),
          dbsNumber: _dbsNumberController.text.trim(),
          dbsExpiryDate: _dbsExpiryDate,
          dbsCertificateUrl: _dbsCertificateUrlController.text.trim(),
          idDocumentUrl: _proofOfIdUrlController.text.trim(),
          idExpiryDate: _proofOfIdExpiry,
          proofOfResidenceUrl: _proofOfResidenceUrlController.text.trim(),
          proofOfResidenceExpiry: _proofOfResidenceExpiry,
          infectionControlUrl: _infectionControlUrlController.text.trim(),
          infectionControlExpiry: _infectionControlExpiry,
          manualHandlingUrl: _manualHandlingUrlController.text.trim(),
          manualHandlingExpiry: _manualHandlingExpiry,
          safeguardingUrl: _safeguardingUrlController.text.trim(),
          safeguardingExpiry: _safeguardingExpiry,
          fitnessToWorkExpiry: _fitnessToWorkExpiry,
          dateOfBirth: _dateOfBirth,
          address: _addressController.text.trim(),
          sortCode: _sortCodeController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          photoUrl: _photoUrlController.text.trim(),
          rightToWorkExpiry: null, // Not in the requirements
          trainingRecords: null, // Not in the requirements
          isActive: true,
          createdAt: widget.carer?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          jobRole: _staffRole,
          staffType: _staffRole,
        );

        String carerId = widget.carer?.id ?? '';
        if (widget.carer != null) {
          await databaseService.updateCarer(carer);
        } else {
          carerId = await databaseService.addCarer(carer);
        }

        // Create / reset the staff-app login (auth user + profile) when requested
        final password = _passwordController.text.trim();
        if (_createLogin && password.isNotEmpty) {
          final authService =
              Provider.of<SupabaseAuthService>(context, listen: false);
          final organisationId = authService.organisationId;
          final invitedBy = authService.currentUser?.id;

          if (organisationId == null || organisationId.isEmpty) {
            throw Exception('No organisation found for this admin');
          }
          if (invitedBy == null) {
            throw Exception('Not authenticated');
          }

          final inviteService = CarerInviteService(Supabase.instance.client);
          await inviteService.upsertCarerAuth(
            carerId: carerId,
            email: _emailController.text.trim(),
            fullName: _nameController.text.trim(),
            password: password,
            role: _staffRole,
            organisationId: organisationId,
            invitedBy: invitedBy,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.carer != null
                  ? _createLogin
                      ? 'Carer updated & login password set'
                      : 'Carer updated successfully'
                  : 'Carer created & staff login ready',
            ),
          ),
        );

        Navigator.pop(context);
    } catch (e) {
      // Print full error to console
      print('===== FULL ERROR =====');
      print(e);
      print('===== END ERROR =====');
      
      // Also show on screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().substring(0, math.min(200, e.toString().length))}'),
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: 'DETAILS',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Error Details'),
                  content: SingleChildScrollView(
                    child: Text(e.toString()),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(_),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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
        title: Text(widget.carer != null ? 'Edit Carer' : 'Add Carer'),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Basic Information Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter carer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              }
                              return null;
                            },
                          ),
                          
                          // Date of Birth
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _dateOfBirth = date;
                                });
                              }
                            },
                            child: IgnorePointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: _dateOfBirth != null 
                                    ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                                    : 'Date of Birth',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                ),
                              ),
                            ),
                          ),
                          
                          // Address
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Employment Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Employment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _employeeNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Employee Number',
                              prefixIcon: Icon(Icons.badge),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter employee number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Documents Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Documents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // DBS Section
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dbsNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'DBS Number',
                                    prefixIcon: Icon(Icons.document_scanner),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: _dbsExpiryDate != null 
                                      ? '${_dbsExpiryDate!.day}/${_dbsExpiryDate!.month}/${_dbsExpiryDate!.year}'
                                      : 'DBS Expiry Date',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate('dbs'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          TextFormField(
                            controller: _dbsCertificateUrlController,
                            decoration: const InputDecoration(
                              labelText: 'DBS Certificate URL',
                              prefixIcon: Icon(Icons.link),
                            ),
                            validator: _validateUrl,
                          ),
                          const SizedBox(height: 12),

                          // Proof of ID Section
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _proofOfIdUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Proof of ID URL',
                                    prefixIcon: Icon(Icons.document_scanner),
                                  ),
                                  validator: _validateUrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: _proofOfIdExpiry != null 
                                      ? '${_proofOfIdExpiry!.day}/${_proofOfIdExpiry!.month}/${_proofOfIdExpiry!.year}'
                                      : 'Proof of ID Expiry',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate('proofOfId'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Proof of Residence Section
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _proofOfResidenceUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Proof of Residence URL',
                                    prefixIcon: Icon(Icons.home),
                                  ),
                                  validator: _validateUrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: _proofOfResidenceExpiry != null 
                                      ? '${_proofOfResidenceExpiry!.day}/${_proofOfResidenceExpiry!.month}/${_proofOfResidenceExpiry!.year}'
                                      : 'Proof of Residence Expiry',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate('proofOfResidence'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Training Certificates Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Training Certificates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Infection Control Section
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _infectionControlUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Infection Control URL',
                                    prefixIcon: Icon(Icons.health_and_safety),
                                  ),
                                  validator: _validateUrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: _infectionControlExpiry != null 
                                      ? '${_infectionControlExpiry!.day}/${_infectionControlExpiry!.month}/${_infectionControlExpiry!.year}'
                                      : 'Infection Control Expiry',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate('infectionControl'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Manual Handling Section
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _manualHandlingUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Manual Handling URL',
                                    prefixIcon: Icon(Icons.directions_walk),
                                  ),
                                  validator: _validateUrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: _manualHandlingExpiry != null 
                                      ? '${_manualHandlingExpiry!.day}/${_manualHandlingExpiry!.month}/${_manualHandlingExpiry!.year}'
                                      : 'Manual Handling Expiry',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate('manualHandling'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Safeguarding Section
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _safeguardingUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Safeguarding URL',
                                    prefixIcon: Icon(Icons.shield),
                                  ),
                                  validator: _validateUrl,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: _safeguardingExpiry != null 
                                      ? '${_safeguardingExpiry!.day}/${_safeguardingExpiry!.month}/${_safeguardingExpiry!.year}'
                                      : 'Safeguarding Expiry',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate('safeguarding'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Employment Details Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Employment Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: _fitnessToWorkExpiry != null 
                                ? '${_fitnessToWorkExpiry!.day}/${_fitnessToWorkExpiry!.month}/${_fitnessToWorkExpiry!.year}'
                                : 'Fitness to Work Expiry',
                              prefixIcon: const Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate('fitnessToWork'),
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _sortCodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Sort Code (6 digits)',
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: _validateSortCode,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _accountNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Account Number (8 digits)',
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: _validateAccountNumber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          TextFormField(
                            controller: _photoUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Photo URL',
                              prefixIcon: Icon(Icons.photo),
                            ),
                            validator: _validateUrl,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Staff Login Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Staff App Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Set a password so this staff member can log in to the staff app.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _staffRole,
                            decoration: const InputDecoration(
                              labelText: 'Staff Role',
                              prefixIcon: Icon(Icons.badge),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'carer', child: Text('Carer')),
                              DropdownMenuItem(value: 'senior_carer', child: Text('Senior Carer')),
                              DropdownMenuItem(value: 'team_leader', child: Text('Team Leader')),
                              DropdownMenuItem(value: 'manager', child: Text('Manager')),
                              DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            ],
                            onChanged: (v) => setState(() => _staffRole = v ?? 'carer'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password (min 6 characters)',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (_createLogin &&
                                  value != _passwordController.text.trim()) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              widget.carer != null
                                  ? 'Set / reset this staff login password'
                                  : 'Create this staff login',
                            ),
                            value: _createLogin,
                            onChanged: (v) =>
                                setState(() => _createLogin = v ?? false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveCarer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: Text(widget.carer != null ? 'Update Carer' : 'Create Carer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}