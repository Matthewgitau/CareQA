import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';

class DevelopmentPlansScreen extends StatefulWidget {
  const DevelopmentPlansScreen({super.key});

  @override
  State<DevelopmentPlansScreen> createState() => _DevelopmentPlansScreenState();
}

class _DevelopmentPlansScreenState extends State<DevelopmentPlansScreen> {
  final _competencyService = CompetencyService(Supabase.instance.client);
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPlans = [];
  List<Map<String, dynamic>> _filteredPlans = [];
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('organisation_id')
          .eq('id', user.id)
          .single();

      final orgId = profile['organisation_id'];

      // Load all development plans for the organisation
      final response = await Supabase.instance.client
          .from('staff_development_plans')
          .select('*, staff:profiles!staff_id(full_name, role), creator:profiles!created_by(full_name)')
          .eq('organisation_id', orgId)
          .order('created_date', ascending: false);

      setState(() {
        _allPlans = (response as List).cast<Map<String, dynamic>>();
        _filterPlans();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load development plans: $e')),
        );
      }
    }
  }

  void _filterPlans() {
    setState(() {
      _filteredPlans = _allPlans.where((plan) {
        // Status filter
        if (_statusFilter != 'all' && plan['status'] != _statusFilter) {
          return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final staffName = plan['staff']['full_name']?.toString().toLowerCase() ?? '';
          return staffName.contains(_searchQuery.toLowerCase());
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Development Plans'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Filter
                _buildSearchAndFilter(),
                // Plans List
                Expanded(
                  child: _filteredPlans.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPlans.length,
                          itemBuilder: (context, index) {
                            final plan = _filteredPlans[index];
                            return _buildPlanCard(plan);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DevelopmentPlanForm(),
            ),
          ).then((_) => _loadPlans());
        },
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search by staff name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _filterPlans();
            },
          ),
          const SizedBox(height: 12),
          // Status Filter
          Row(
            children: [
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', 'completed'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cancelled', 'cancelled'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
          _filterPlans();
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No development plans found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a development plan to help staff improve their competencies',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final staffName = plan['staff']['full_name'] ?? 'Unknown';
    final staffRole = plan['staff']['role'] ?? 'Staff';
    final status = plan['status'] ?? 'active';
    final createdDate = plan['created_date'] != null 
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(plan['created_date']))
        : 'N/A';
    final reviewDate = plan['review_date'] != null 
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(plan['review_date']))
        : null;
    final goals = plan['goals'] as List? ?? [];
    final completedGoals = goals.where((g) => g['status'] == 'completed').length;
    final totalGoals = goals.length;
    final progress = totalGoals > 0 ? completedGoals / totalGoals : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DevelopmentPlanForm(planId: plan['id']),
            ),
          ).then((_) => _loadPlans());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staffName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          staffRole,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusDisplay(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Created: $createdDate',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (reviewDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.event, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Review: $reviewDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress: $completedGoals / $totalGoals goals',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress == 1.0 ? Colors.green : Colors.blue,
                          ),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (plan['notes'] != null && plan['notes'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  plan['notes'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'active': return 'Active';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}