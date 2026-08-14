import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _policiesFuture;
  String _selectedCategory = 'all';
  late TabController _tabController;

  final List<String> _categories = [
    'all',
    'Health & Safety',
    'Safeguarding',
    'Medication',
    'Care Standards',
    'HR',
    'Infection Control',
    'Food & Nutrition',
    'Equipment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _policiesFuture = _loadPolicies();
  }

  Future<List<Map<String, dynamic>>> _loadPolicies() async {
    var query = _supabase.from('policies').select('''
      *,
      creator:created_by(name, email)
    ''').order('policy_name', ascending: true);

    final response = await query;
    var policies = List<Map<String, dynamic>>.from(response);

    // Filter by category
    if (_selectedCategory != 'all') {
      policies = policies.where((p) => p['category'] == _selectedCategory).toList();
    }

    // Filter by tab (active/archived)
    if (_tabController.index == 0) {
      policies = policies.where((p) => p['status'] == 'active' || p['status'] == 'draft').toList();
    } else {
      policies = policies.where((p) => p['status'] == 'archived').toList();
    }

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      policies = policies.where((p) =>
        (p['policy_name'] ?? '').toLowerCase().contains(search) ||
        (p['category'] ?? '').toLowerCase().contains(search) ||
        (p['version'] ?? '').toLowerCase().contains(search)
      ).toList();
    }

    return policies;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showPolicyForm({Map<String, dynamic>? policy}) async {
    await showDialog(
      context: context,
      builder: (context) => _PolicyFormDialog(policy: policy),
    );
    setState(() {
      _policiesFuture = _loadPolicies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Policy Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Archived'),
          ],
          onTap: (_) => setState(() {
            _policiesFuture = _loadPolicies();
          }),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
                _policiesFuture = _loadPolicies();
              });
            },
            itemBuilder: (context) => _categories.map((c) {
              String display = c == 'all' ? 'All Categories' : c;
              return PopupMenuItem(value: c, child: Text(display));
            }).toList(),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search policies',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {
                _policiesFuture = _loadPolicies();
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _policiesFuture,
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
                        const Icon(Icons.policy, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No policies found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text('Add your first policy document', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final policies = snapshot.data!;
                
                // Group by category
                Map<String, List<Map<String, dynamic>>> grouped = {};
                for (var policy in policies) {
                  final category = policy['category'] ?? 'Other';
                  if (!grouped.containsKey(category)) {
                    grouped[category] = [];
                  }
                  grouped[category]!.add(policy);
                }

                return RefreshIndicator(
                  onRefresh: () => _loadPolicies(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final category = grouped.keys.elementAt(index);
                      final categoryPolicies = grouped[category]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          ...categoryPolicies.map((policy) => _buildPolicyCard(policy)),
                        ],
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
        onPressed: () => _showPolicyForm(),
        tooltip: 'Add Policy',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPolicyCard(Map<String, dynamic> policy) {
    final effectiveDate = policy['effective_date'] != null ? DateTime.parse(policy['effective_date']) : null;
    final reviewDate = policy['review_date'] != null ? DateTime.parse(policy['review_date']) : null;
    final isOverdue = reviewDate != null && reviewDate.isBefore(DateTime.now()) && policy['status'] == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                policy['policy_name'] ?? 'Untitled',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(policy['status']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (policy['status'] ?? 'draft')[0].toUpperCase() + (policy['status'] ?? 'draft').substring(1),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (policy['version'] != null)
              Text('Version: ${policy['version']}', style: const TextStyle(fontSize: 12)),
            if (effectiveDate != null)
              Text('Effective: ${DateFormat('dd/MM/yyyy').format(effectiveDate)}', style: const TextStyle(fontSize: 12)),
            if (reviewDate != null)
              Text('Review: ${DateFormat('dd/MM/yyyy').format(reviewDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.grey,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  )),
            if (isOverdue)
              const Text('REVIEW OVERDUE', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _showPolicyForm(policy: policy),
        ),
      ),
    );
  }
}

class _PolicyFormDialog extends StatefulWidget {
  final Map<String, dynamic>? policy;

  const _PolicyFormDialog({this.policy});

  @override
  State<_PolicyFormDialog> createState() => _PolicyFormDialogState();
}

class _PolicyFormDialogState extends State<_PolicyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _versionController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedCategory;
  DateTime? _effectiveDate;
  DateTime? _reviewDate;
  String? _status = 'active';
  bool _isLoading = false;

  final List<String> _categories = [
    'Health & Safety',
    'Safeguarding',
    'Medication',
    'Care Standards',
    'HR',
    'Infection Control',
    'Food & Nutrition',
    'Equipment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.policy != null) {
      _nameController.text = widget.policy!['policy_name'] ?? '';
      _versionController.text = widget.policy!['version'] ?? '';
      _contentController.text = widget.policy!['content_text'] ?? '';
      _selectedCategory = widget.policy!['category'];
      _status = widget.policy!['status'];
      if (widget.policy!['effective_date'] != null) {
        _effectiveDate = DateTime.parse(widget.policy!['effective_date']);
      }
      if (widget.policy!['review_date'] != null) {
        _reviewDate = DateTime.parse(widget.policy!['review_date']);
      }
    }
  }

  Future<void> _pickDate(bool isEffective) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isEffective) {
          _effectiveDate = picked;
        } else {
          _reviewDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'policy_name': _nameController.text,
        'category': _selectedCategory,
        'version': _versionController.text,
        'content_text': _contentController.text,
        'effective_date': _effectiveDate?.toIso8601String().split('T')[0],
        'review_date': _reviewDate?.toIso8601String().split('T')[0],
        'status': _status,
      };

      if (widget.policy != null) {
        await Supabase.instance.client.from('policies').update(data).eq('id', widget.policy!['id']);
      } else {
        await Supabase.instance.client.from('policies').insert(data);
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
    _versionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.policy != null ? 'Edit Policy' : 'New Policy'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Policy Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _versionController,
                decoration: const InputDecoration(labelText: 'Version', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Effective Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_effectiveDate != null ? DateFormat('dd/MM/yyyy').format(_effectiveDate!) : 'Select'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Review Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_reviewDate != null ? DateFormat('dd/MM/yyyy').format(_reviewDate!) : 'Select'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ['active', 'draft', 'archived'].map((s) {
                  String display = s[0].toUpperCase() + s.substring(1);
                  return DropdownMenuItem(value: s, child: Text(display));
                }).toList(),
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Policy Content', border: OutlineInputBorder()),
                maxLines: 10,
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