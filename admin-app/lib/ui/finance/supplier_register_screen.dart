import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supplier.dart';
import '../../services/supplier_service.dart';
import 'supplier_form.dart';

class SupplierRegisterScreen extends StatefulWidget {
  const SupplierRegisterScreen({super.key});

  @override
  State<SupplierRegisterScreen> createState() => _SupplierRegisterScreenState();
}

class _SupplierRegisterScreenState extends State<SupplierRegisterScreen> {
  final SupplierService _supplierService = SupplierService(Supabase.instance.client);
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedRisk;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      _suppliers = await _supplierService.getSuppliers();
      _filteredSuppliers = _suppliers;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suppliers: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSuppliers() {
    setState(() {
      _filteredSuppliers = _suppliers.where((supplier) {
        final matchesType = _selectedType == null || supplier.supplierType == _selectedType;
        final matchesStatus = _selectedStatus == null || supplier.supplierStatus == _selectedStatus;
        final matchesRisk = _selectedRisk == null || supplier.riskRating == _selectedRisk;
        final matchesSearch = _searchController.text.isEmpty ||
            supplier.supplierName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (supplier.companyRegistrationNumber?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
        return matchesType && matchesStatus && matchesRisk && matchesSearch;
      }).toList();
    });
  }

  Future<void> _markAsInactive(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Inactive?'),
        content: Text('Are you sure you want to mark ${supplier.supplierName} as inactive?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark Inactive')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supplierService.deleteSupplier(supplier.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplier marked as inactive'), backgroundColor: Colors.green),
          );
          _loadSuppliers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Register'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuppliers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search suppliers...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => _filterSuppliers(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        value: _selectedType,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Types')),
                          ..._supplierService.getSupplierTypes().map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.replaceAll('_', ' ').toUpperCase()),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedType = value);
                          _filterSuppliers();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                        value: _selectedStatus,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Statuses')),
                          ..._supplierService.getSupplierStatuses().map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.replaceAll('_', ' ').toUpperCase()),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _filterSuppliers();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Risk', border: OutlineInputBorder()),
                        value: _selectedRisk,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Risks')),
                          ..._supplierService.getRiskRatings().map((risk) => DropdownMenuItem(
                            value: risk,
                            child: Text(risk.toUpperCase()),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedRisk = value);
                          _filterSuppliers();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Supplier List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSuppliers.isEmpty
                    ? const Center(child: Text('No suppliers found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = _filteredSuppliers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                supplier.supplierName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(supplier.supplierType?.replaceAll('_', ' ').toUpperCase() ?? 'N/A'),
                                  if (supplier.contactEmail != null) Text(supplier.contactEmail!),
                                  if (supplier.contractEndDate != null)
                                    Text('Contract ends: ${DateFormat('dd/MM/yyyy').format(supplier.contractEndDate!)}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _StatusChip(status: supplier.supplierStatus),
                                  const SizedBox(width: 8),
                                  _RiskChip(risk: supplier.riskRating ?? 'low'),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SupplierFormScreen(supplier: supplier),
                                  ),
                                ).then((_) => _loadSuppliers());
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupplierFormScreen()),
          ).then((_) => _loadSuppliers());
        },
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'inactive':
        color = Colors.grey;
        break;
      case 'suspended':
        color = Colors.red;
        break;
      case 'pending_approval':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 10),
    );
  }
}

class _RiskChip extends StatelessWidget {
  final String risk;
  const _RiskChip({required this.risk});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (risk) {
      case 'low':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'high':
        color = Colors.deepOrange;
        break;
      case 'critical':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(risk.toUpperCase(), style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 10),
    );
  }
}