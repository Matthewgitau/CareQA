import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ActionPlansScreen extends StatefulWidget {
  const ActionPlansScreen({super.key});

  @override
  State<ActionPlansScreen> createState() => _ActionPlansScreenState();
}

class _ActionPlansScreenState extends State<ActionPlansScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _actionPlansFuture;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _actionPlansFuture = _loadActionPlans();
  }

  Future<List<Map<String, dynamic>>> _loadActionPlans() async {
    var query = _supabase.from('action_plans').select('''
      *,
      assigned_staff:assigned_to(name, email),
      service_user:service_user_id(name)
    ''').order('due_date', ascending: true);

    List<Map<String, dynamic>> response;
    if (_selectedFilter != 'all') {
      response = await query.then((data) => data.where((p) => p['status'] == _selectedFilter).toList());
    } else {
      response = await query;
    }
    return response;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'overdue':
        return 'Overdue';
      default:
        return status;
    }
  }

  Future<void> _showActionPlanForm({Map<String, dynamic>? actionPlan}) async {
    await showDialog(
      context: context,
      builder: (context) => _ActionPlanFormDialog(actionPlan: actionPlan),
    );
    setState(() {
      _actionPlansFuture = _loadActionPlans();
    });
  }

  Future<void> _markAsComplete(String id) async {
    try {
      await _supabase.from('action_plans').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action plan marked as complete')),
      );
      setState(() {
        _actionPlansFuture = _loadActionPlans();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Plans'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
                _actionPlansFuture = _loadActionPlans();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'overdue', child: Text('Overdue')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _actionPlansFuture,
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
                  const Icon(Icons.playlist_add_check, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No action plans found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Create your first action plan', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final actionPlans = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () => _loadActionPlans(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: actionPlans.length,
              itemBuilder: (context, index) {
                final plan = actionPlans[index];
                final dueDate = plan['due_date'] != null ? DateTime.parse(plan['due_date']) : null;
                final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && plan['status'] != 'completed';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      plan['title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (plan['service_user'] != null)
                          Text('Service User: ${plan['service_user']['name'] ?? 'Unknown'}'),
                        if (plan['assigned_staff'] != null)
                          Text('Assigned: ${plan['assigned_staff']['name'] ?? plan['assigned_staff']['email'] ?? 'Unassigned'}'),
                        if (dueDate != null)
                          Text('Due: ${DateFormat('dd/MM/yyyy').format(dueDate)}'),
                        if (isOverdue)
                          const Text('OVERDUE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(isOverdue ? 'overdue' : plan['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusDisplay(isOverdue ? 'overdue' : plan['status']),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        if (plan['status'] != 'completed')
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => _markAsComplete(plan['id']),
                            tooltip: 'Mark as complete',
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => _showActionPlanForm(actionPlan: plan),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionPlanForm(),
        tooltip: 'Add Action Plan',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ActionPlanFormDialog extends StatefulWidget {
  final Map<String, dynamic>? actionPlan;

  const _ActionPlanFormDialog({this.actionPlan});

  @override
  State<_ActionPlanFormDialog> createState() => _ActionPlanFormDialogState();
}

class _ActionPlanFormDialogState extends State<_ActionPlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedStaffId;
  String? _selectedServiceUserId;
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.actionPlan != null) {
      _titleController.text = widget.actionPlan!['title'] ?? '';
      _descriptionController.text = widget.actionPlan!['description'] ?? '';
      if (widget.actionPlan!['due_date'] != null) {
        _dueDate = DateTime.parse(widget.actionPlan!['due_date']);
      }
      _selectedStaffId = widget.actionPlan!['assigned_to'];
      _selectedServiceUserId = widget.actionPlan!['service_user_id'];
    }
  }

  Future<void> _loadData() async {
    final staffResponse = await Supabase.instance.client.from('profiles').select('id, name, email');
    final serviceUsersResponse = await Supabase.instance.client.from('service_users').select('id, name');
    
    setState(() {
      _staff = List<Map<String, dynamic>>.from(staffResponse);
      _serviceUsers = List<Map<String, dynamic>>.from(serviceUsersResponse);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'assigned_to': _selectedStaffId,
        'due_date': _dueDate?.toIso8601String().split('T')[0],
        'service_user_id': _selectedServiceUserId,
      };

      if (widget.actionPlan != null) {
        await Supabase.instance.client.from('action_plans').update(data).eq('id', widget.actionPlan!['id']);
      } else {
        await Supabase.instance.client.from('action_plans').insert(data);
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.actionPlan != null ? 'Edit Action Plan' : 'New Action Plan'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedStaffId,
                decoration: const InputDecoration(labelText: 'Assigned Staff', border: OutlineInputBorder()),
                items: _staff.map((s) => DropdownMenuItem<String?>(
                  value: s['id'] as String?,
                  child: Text('${s['name'] ?? s['email']}'),
                )).toList(),
                onChanged: (v) => setState(() => _selectedStaffId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedServiceUserId,
                decoration: const InputDecoration(labelText: 'Related Service User (Optional)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('None')),
                  ..._serviceUsers.map((su) => DropdownMenuItem<String?>(
                    value: su['id'] as String?,
                    child: Text(su['name'] ?? 'Unknown'),
                  )),
                ],
                onChanged: (v) => setState(() => _selectedServiceUserId = v),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : 'Select date'),
                ),
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