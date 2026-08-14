import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SupplierLogScreen extends StatefulWidget {
  const SupplierLogScreen({super.key});

  @override
  State<SupplierLogScreen> createState() => _SupplierLogScreenState();
}

class _SupplierLogScreenState extends State<SupplierLogScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _suppliersFuture;
  String _selectedCategory = 'all';

  final List<String> _categories = ['all', 'medical_supplies', 'catering', 'cleaning', 'maintenance', 'office', 'other'];
  final Map<String, String> _categoryLabels = {
    'medical_supplies': 'Medical Supplies',
    'catering': 'Catering',
    'cleaning': 'Cleaning',
    'maintenance': 'Maintenance',
    'office': 'Office',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _suppliersFuture = _loadSuppliers();
  }

  Future<List<Map<String, dynamic>>> _loadSuppliers() async {
    var query = _supabase.from('suppliers').select('*').order('supplier_name', ascending: true);

    final response = await query;
    var suppliers = List<Map<String, dynamic>>.from(response);

    if (_selectedCategory != 'all') {
      suppliers = suppliers.where((s) => s['category'] == _selectedCategory).toList();
    }

    return suppliers;
  }

  Color _getRatingColor(int? rating) {
    if (rating == null) return Colors.grey;
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  Future<void> _showSupplierForm({Map<String, dynamic>? supplier}) async {
    await showDialog(
      context: context,
      builder: (context) => _SupplierFormDialog(supplier: supplier),
    );
    setState(() {
      _suppliersFuture = _loadSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Register'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
                _suppliersFuture = _loadSuppliers();
              });
            },
            itemBuilder: (context) => _categories.map((c) {
              String display = c == 'all' ? 'All Categories' : (_categoryLabels[c] ?? c);
              return PopupMenuItem(value: c, child: Text(display));
            }).toList(),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _suppliersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No suppliers found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final suppliers = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () => _loadSuppliers(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                final isActive = supplier['is_active'] != false;
                final insuranceExpiry = supplier['insurance_expiry'] != null ? DateTime.parse(supplier['insurance_expiry']) : null;
                final isInsuranceExpired = insuranceExpiry != null && insuranceExpiry.isBefore(DateTime.now());

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isActive ? null : Colors.grey.shade100,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier['supplier_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isActive ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Inactive', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (supplier['contact_name'] != null) Text('Contact: ${supplier['contact_name']}'),
                        if (supplier['phone'] != null) Text('Phone: ${supplier['phone']}'),
                        if (supplier['email'] != null) Text('Email: ${supplier['email']}'),
                        if (supplier['category'] != null)
                          Text('Category: ${_categoryLabels[supplier['category']] ?? supplier['category']}'),
                        if (insuranceExpiry != null)
                          Text(
                            'Insurance: ${DateFormat('dd/MM/yyyy').format(insuranceExpiry)}',
                            style: isInsuranceExpired ? const TextStyle(color: Colors.red, fontWeight: FontWeight.bold) : null,
                          ),
                        if (isInsuranceExpired)
                          const Text('INSURANCE EXPIRED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                        if (supplier['performance_rating'] != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) {
                              return Icon(
                                i < supplier['performance_rating'] ? Icons.star : Icons.star_border,
                                size: 16,
                                color: _getRatingColor(supplier['performance_rating']),
                              );
                            }),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSupplierForm(supplier: supplier),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierForm(),
        tooltip: 'Add Supplier',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SupplierFormDialog extends StatefulWidget {
  final Map<String, dynamic>? supplier;

  const _SupplierFormDialog({this.supplier});

  @override
  State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _category;
  DateTime? _insuranceExpiry;
  int? _rating;
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _categories = ['medical_supplies', 'catering', 'cleaning', 'maintenance', 'office', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!['supplier_name'] ?? '';
      _contactController.text = widget.supplier!['contact_name'] ?? '';
      _phoneController.text = widget.supplier!['phone'] ?? '';
      _emailController.text = widget.supplier!['email'] ?? '';
      _addressController.text = widget.supplier!['address'] ?? '';
      _paymentTermsController.text = widget.supplier!['payment_terms'] ?? '';
      _notesController.text = widget.supplier!['notes'] ?? '';
      _category = widget.supplier!['category'];
      _rating = widget.supplier!['performance_rating'];
      _isActive = widget.supplier!['is_active'] ?? true;
      if (widget.supplier!['insurance_expiry'] != null) {
        _insuranceExpiry = DateTime.parse(widget.supplier!['insurance_expiry']);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _insuranceExpiry = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'supplier_name': _nameController.text,
        'contact_name': _contactController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'category': _category,
        'payment_terms': _paymentTermsController.text,
        'insurance_expiry': _insuranceExpiry?.toIso8601String().split('T')[0],
        'performance_rating': _rating,
        'is_active': _isActive,
        'notes': _notesController.text,
      };

      if (widget.supplier != null) {
        await Supabase.instance.client.from('suppliers').update(data).eq('id', widget.supplier!['id']);
      } else {
        await Supabase.instance.client.from('suppliers').insert(data);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.supplier != null ? 'Edit Supplier' : 'Add Supplier'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Supplier Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) {
                  String display = c.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                  return DropdownMenuItem(value: c, child: Text(display));
                }).toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentTermsController,
                decoration: const InputDecoration(labelText: 'Payment Terms', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Insurance Expiry',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                    errorText: _insuranceExpiry != null && _insuranceExpiry!.isBefore(DateTime.now()) ? 'EXPIRED' : null,
                  ),
                  child: Text(_insuranceExpiry != null ? DateFormat('dd/MM/yyyy').format(_insuranceExpiry!) : 'Select date'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Performance Rating', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final rating = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = rating),
                    child: Icon(
                      rating <= (_rating ?? 0) ? Icons.star : Icons.star_border,
                      size: 32,
                      color: rating <= (_rating ?? 0) ? Colors.amber : Colors.grey,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active Supplier'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}