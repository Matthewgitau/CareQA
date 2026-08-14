import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/appraisal_service.dart';
import '../staff/appraisal_form.dart';
import '../staff/appraisals_screen.dart';

class MatrixDashboardScreen extends StatefulWidget {
  const MatrixDashboardScreen({super.key});

  @override
  State<MatrixDashboardScreen> createState() => _MatrixDashboardScreenState();
}

class _MatrixDashboardScreenState extends State<MatrixDashboardScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _appraisalService = AppraisalService(Supabase.instance.client);
  late Future<List<Map<String, dynamic>>> _matrixRecordsFuture;
  late Future<List<Map<String, dynamic>>> _appraisalMatrixFuture;
  late TabController _tabController;
  String _selectedStatus = 'all';

  final List<String> _matrixTypes = ['training', 'supervision', 'appraisal_matrix', 'equipment'];
  final Map<String, IconData> _matrixIcons = {
    'training': Icons.school,
    'supervision': Icons.supervisor_account,
    'appraisal_matrix': Icons.star_rate,
    'equipment': Icons.business,
  };
  final Map<String, String> _matrixLabels = {
    'training': 'Training',
    'supervision': 'Supervision',
    'appraisal_matrix': 'Appraisals',
    'equipment': 'Equipment',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _matrixTypes.length, vsync: this);
    _matrixRecordsFuture = _loadMatrixRecords();
    _appraisalMatrixFuture = _appraisalService.getAppraisalMatrix();
  }

  Future<List<Map<String, dynamic>>> _loadMatrixRecords() async {
    var query = _supabase.from('matrix_records').select('''
      *,
      staff:staff_id(name, email),
      creator:created_by(name, email)
    ''').order('next_due_date', ascending: true);

    final response = await query;
    var records = List<Map<String, dynamic>>.from(response);

    // Filter by tab (matrix type)
    final currentType = _matrixTypes[_tabController.index];
    if (currentType != 'appraisal_matrix') {
      records = records.where((r) => r['matrix_type'] == currentType).toList();
    }

    // Filter by status
    if (_selectedStatus != 'all') {
      records = records.where((r) => r['status'] == _selectedStatus).toList();
    }

    return records;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String? status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'overdue':
        return 'Overdue';
      default:
        return status ?? 'Unknown';
    }
  }

  Future<void> _showMatrixRecordForm({Map<String, dynamic>? record}) async {
    await showDialog(
      context: context,
      builder: (context) => _MatrixRecordFormDialog(
        record: record,
        matrixType: _matrixTypes[_tabController.index],
      ),
    );
    setState(() {
      _matrixRecordsFuture = _loadMatrixRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAppraisalTab = _tabController.index == 2; // index 2 = appraisal_matrix
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _matrixTypes.map((type) => Tab(
            icon: Icon(_matrixIcons[type]),
            text: _matrixLabels[type],
          )).toList(),
          onTap: (_) => setState(() {
            _matrixRecordsFuture = _loadMatrixRecords();
          }),
        ),
        actions: isAppraisalTab ? null : [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedStatus = value;
                _matrixRecordsFuture = _loadMatrixRecords();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'overdue', child: Text('Overdue')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: isAppraisalTab
          ? _buildAppraisalMatrixView()
          : FutureBuilder<List<Map<String, dynamic>>>(
        future: _matrixRecordsFuture,
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
                  Icon(_matrixIcons[_matrixTypes[_tabController.index]], size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No ${_matrixLabels[_matrixTypes[_tabController.index]]?.toLowerCase() ?? 'matrix'} records found',
                      style: const TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final records = snapshot.data!;
          
          // Calculate summary stats
          final completed = records.where((r) => r['status'] == 'completed').length;
          final pending = records.where((r) => r['status'] == 'pending').length;
          final overdue = records.where((r) => r['status'] == 'overdue').length;

          return Column(
            children: [
              // Summary cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Completed', completed, Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSummaryCard('Pending', pending, Colors.orange)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSummaryCard('Overdue', overdue, Colors.red)),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadMatrixRecords(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final completionDate = record['completion_date'] != null ? DateTime.parse(record['completion_date']) : null;
                      final nextDueDate = record['next_due_date'] != null ? DateTime.parse(record['next_due_date']) : null;
                      final isOverdue = nextDueDate != null && nextDueDate.isBefore(DateTime.now()) && record['status'] != 'completed';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(isOverdue ? 'overdue' : record['status']),
                            child: Icon(Icons.check, color: Colors.white),
                          ),
                          title: Text(
                            record['staff']?['name'] ?? record['staff']?['email'] ?? 'Unknown Staff',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (completionDate != null)
                                Text('Completed: ${DateFormat('dd/MM/yyyy').format(completionDate)}'),
                              if (nextDueDate != null)
                                Text('Next Due: ${DateFormat('dd/MM/yyyy').format(nextDueDate)}'),
                              if (record['notes'] != null && record['notes'].toString().isNotEmpty)
                                Text(
                                  record['notes'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              if (isOverdue)
                                const Text('OVERDUE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(isOverdue ? 'overdue' : record['status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusDisplay(isOverdue ? 'overdue' : record['status']),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          onTap: () => _showMatrixRecordForm(record: record),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMatrixRecordForm(),
        tooltip: 'Add Record',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build the Appraisal Matrix view
  Widget _buildAppraisalMatrixView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _appraisalMatrixFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        }

        final data = snapshot.data ?? [];
        
        // Filter by status if not 'all'
        final filteredData = _selectedStatus == 'all'
            ? data
            : data.where((item) => item['matrixStatus'] == _selectedStatus).toList();

        // Summary stats
        final eligible = data.where((d) => d['matrixStatus'] == 'eligible').length;
        final completed = data.where((d) => d['matrixStatus'] == 'completed').length;
        final overdue = data.where((d) => d['matrixStatus'] == 'overdue' || d['matrixStatus'] == 'due_soon').length;
        final notEligible = data.where((d) => d['matrixStatus'] == 'not_eligible').length;

        return Column(
          children: [
            // Summary cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildSummaryCard('Completed', completed, Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard('Due Soon', overdue, Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard('Eligible', eligible, Colors.teal)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard('New', notEligible, Colors.grey)),
                ],
              ),
            ),
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Eligible', 'eligible'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', 'completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Overdue', 'overdue'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Due Soon', 'due_soon'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Not Eligible', 'not_eligible'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rate, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No appraisal data found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _appraisalMatrixFuture = _appraisalService.getAppraisalMatrix();
                        });
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          return _buildAppraisalMatrixRow(filteredData[index]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : 'all';
        });
      },
      selectedColor: const Color(0xFF1976D2),
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildAppraisalMatrixRow(Map<String, dynamic> item) {
    final matrixStatus = item['matrixStatus'] as String? ?? '';
    final lastAppraisalDate = item['lastAppraisalDate'] as DateTime?;
    final nextAppraisalDate = item['nextAppraisalDate'] as DateTime?;
    final overallRating = item['overallRating'] as int?;
    final daysSince = item['daysSinceLastAppraisal'] as int?;
    final daysUntil = item['daysUntilNextAppraisal'] as int?;

    Color statusColor;
    String statusLabel;
    switch (matrixStatus) {
      case 'completed':
        statusColor = Colors.green;
        statusLabel = 'Completed';
        break;
      case 'eligible':
        statusColor = Colors.teal;
        statusLabel = 'Eligible';
        break;
      case 'not_eligible':
        statusColor = Colors.grey;
        statusLabel = 'New Starter';
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusLabel = 'Overdue';
        break;
      case 'due_soon':
        statusColor = Colors.orange;
        statusLabel = 'Due Soon';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppraisalForm(
                preselectedEmployeeId: item['employeeId'] as String?,
                preselectedEmployeeName: item['employeeName'] as String?,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Employee info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['employeeName'] as String? ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    if (lastAppraisalDate != null)
                      Text(
                        'Last: ${DateFormat('dd MMM yyyy').format(lastAppraisalDate)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    if (nextAppraisalDate != null)
                      Text(
                        'Next: ${DateFormat('dd MMM yyyy').format(nextAppraisalDate)}',
                        style: TextStyle(
                          color: daysUntil != null && daysUntil <= 30 ? Colors.red : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    if (daysSince != null && matrixStatus == 'completed')
                      Text(
                        '$daysSince days since last appraisal',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                  ],
                ),
              ),
              // Rating
              if (overallRating != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(5, (i) {
                        return Icon(
                          i < overallRating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: i < overallRating ? Colors.amber : Colors.grey.shade300,
                        );
                      }),
                    ],
                  ),
                ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _MatrixRecordFormDialog extends StatefulWidget {
  final Map<String, dynamic>? record;
  final String matrixType;

  const _MatrixRecordFormDialog({this.record, required this.matrixType});

  @override
  State<_MatrixRecordFormDialog> createState() => _MatrixRecordFormDialogState();
}

class _MatrixRecordFormDialogState extends State<_MatrixRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _selectedStaffId;
  DateTime? _completionDate;
  DateTime? _nextDueDate;
  String _status = 'pending';
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    if (widget.record != null) {
      _selectedStaffId = widget.record!['staff_id'];
      _status = widget.record!['status'] ?? 'pending';
      _notesController.text = widget.record!['notes'] ?? '';
      if (widget.record!['completion_date'] != null) {
        _completionDate = DateTime.parse(widget.record!['completion_date']);
      }
      if (widget.record!['next_due_date'] != null) {
        _nextDueDate = DateTime.parse(widget.record!['next_due_date']);
      }
    }
  }

  Future<void> _loadStaff() async {
    final response = await Supabase.instance.client.from('profiles').select('id, name, email');
    setState(() {
      _staff = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _pickDate(bool isCompletion) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isCompletion) {
          _completionDate = picked;
        } else {
          _nextDueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'staff_id': _selectedStaffId,
        'matrix_type': widget.matrixType,
        'completion_date': _completionDate?.toIso8601String().split('T')[0],
        'next_due_date': _nextDueDate?.toIso8601String().split('T')[0],
        'status': _status,
        'notes': _notesController.text,
      };

      if (widget.record != null) {
        await Supabase.instance.client.from('matrix_records').update(data).eq('id', widget.record!['id']);
      } else {
        await Supabase.instance.client.from('matrix_records').insert(data);
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
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.record != null ? 'Edit ${widget.matrixType} Record' : 'New ${widget.matrixType} Record'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedStaffId,
                decoration: const InputDecoration(labelText: 'Staff Member', border: OutlineInputBorder()),
                items: _staff.map((s) => DropdownMenuItem<String>(
                  value: (s['id'] as String?) ?? '',
                  child: Text('${s['name'] ?? s['email']}'),
                )).toList(),
                onChanged: (v) => setState(() => _selectedStaffId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Completion Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_completionDate != null ? DateFormat('dd/MM/yyyy').format(_completionDate!) : 'Select'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Next Due Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_nextDueDate != null ? DateFormat('dd/MM/yyyy').format(_nextDueDate!) : 'Select'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: <String>['pending', 'completed', 'overdue'].map((String s) {
                  final String display = s[0].toUpperCase() + s.substring(1);
                  return DropdownMenuItem(value: s, child: Text(display));
                }).toList(),
                onChanged: (v) => setState(() => _status = v ?? 'pending'),
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