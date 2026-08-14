import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/receipt_entry.dart';
import '../../services/receipt_service.dart';
import 'receipt_entry_screen.dart';

class ReceiptListScreen extends StatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  final ReceiptService _receiptService = ReceiptService(Supabase.instance.client);
  List<ReceiptEntry> _receipts = [];
  List<ReceiptEntry> _filteredReceipts = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    try {
      _receipts = await _receiptService.getReceipts();
      _filteredReceipts = _receipts;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading receipts: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterReceipts() {
    setState(() {
      _filteredReceipts = _receipts.where((receipt) {
        final matchesCategory = _selectedCategory == null || receipt.category == _selectedCategory;
        final matchesStatus = _selectedStatus == null || receipt.status == _selectedStatus;
        final matchesSearch = _searchController.text.isEmpty ||
            receipt.merchantName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (receipt.expenseNotes?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
        return matchesCategory && matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Future<void> _approveReceipt(ReceiptEntry receipt) async {
    try {
      await _receiptService.approveReceipt(receipt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt approved'), backgroundColor: Colors.green),
        );
        _loadReceipts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectReceipt(ReceiptEntry receipt) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context, reasonController.text);
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red),
              foregroundColor: MaterialStateProperty.all(Colors.white),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await _receiptService.rejectReceipt(receipt.id, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt rejected'), backgroundColor: Colors.orange),
          );
          _loadReceipts();
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

  Future<void> _deleteReceipt(ReceiptEntry receipt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt?'),
        content: Text('Are you sure you want to delete receipt from ${receipt.merchantName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _receiptService.deleteReceipt(receipt.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt deleted'), backgroundColor: Colors.green),
          );
          _loadReceipts();
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
        title: const Text('Receipts'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceipts,
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
                    labelText: 'Search receipts...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => _filterReceipts(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        value: _selectedCategory,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Categories')),
                          ..._receiptService.getReceiptCategories().map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.replaceAll('_', ' ').toUpperCase()),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                          _filterReceipts();
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
                          ..._receiptService.getStatusOptions().map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.toUpperCase()),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _filterReceipts();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Receipt List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReceipts.isEmpty
                    ? const Center(child: Text('No receipts found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredReceipts.length,
                        itemBuilder: (context, index) {
                          final receipt = _filteredReceipts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                receipt.merchantName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('dd/MM/yyyy').format(receipt.receiptDate)),
                                  if (receipt.category != null)
                                    Text(receipt.category!.replaceAll('_', ' ').toUpperCase()),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _StatusChip(status: receipt.status),
                                  const SizedBox(width: 8),
                                  Text(
                                    '£${receipt.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // TODO: Navigate to receipt detail view
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Receipt detail view - Coming soon')),
                                );
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
            MaterialPageRoute(builder: (context) => const ReceiptEntryScreen()),
          ).then((_) => _loadReceipts());
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
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'audited':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 10),
    );
  }
}