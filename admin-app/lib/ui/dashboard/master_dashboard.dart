import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_app/services/auth_service.dart';
import 'package:admin_app/services/database_service.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/models/shift.dart';
import 'package:admin_app/models/visit.dart';

class MasterDashboard extends StatefulWidget {
  const MasterDashboard({super.key});

  @override
  State<MasterDashboard> createState() => _MasterDashboardState();
}

class _MasterDashboardState extends State<MasterDashboard> {
  late DatabaseService _databaseService;
  late AuthService _authService;
  
  // Dashboard data
  List<ServiceUser> _serviceUsers = [];
  List<Shift> _shifts = [];
  List<Visit> _visits = [];
  
  // Assessment counts
  int _totalAssessments = 0;
  int _upcomingReviews = 0;
  int _trainingExpirations = 0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load basic data
      _serviceUsers = await _databaseService.getServiceUsers().first;
      _shifts = await _databaseService.getShifts().first;
      _visits = await _databaseService.getVisits().first;
      
      // Calculate basic counts
      _totalAssessments = _serviceUsers.length * 2; // Estimate
      _upcomingReviews = 5; // Placeholder
      _trainingExpirations = 3; // Placeholder
      
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareQA Master Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          _buildWelcomeSection(),
          
          const SizedBox(height: 20),
          
          // Key metrics
          _buildMetricsSection(),
          
          const SizedBox(height: 20),
          
          // Recent activity
          _buildRecentActivitySection(),
          
          const SizedBox(height: 20),
          
          // Quick actions
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.dashboard, size: 40, color: Colors.blue),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to CareQA Master Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Overview of all assessments, compliance, and upcoming reviews',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildMetricCard(
              'Recent Assessments',
              _totalAssessments.toString(),
              Colors.green,
              Icons.assignment,
            ),
            const SizedBox(width: 10),
            _buildMetricCard(
              'Upcoming Reviews',
              _upcomingReviews.toString(),
              Colors.orange,
              Icons.calendar_today,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildMetricCard(
              'Training Expirations',
              _trainingExpirations.toString(),
              Colors.red,
              Icons.school,
            ),
            const SizedBox(width: 10),
            _buildMetricCard(
              'Active Service Users',
              _serviceUsers.length.toString(),
              Colors.blue,
              Icons.home,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        
        // Recent visits
        if (_visits.isNotEmpty)
          _buildRecentItemsCard(
            'Recent Visits',
            _visits.take(5).toList(),
            (visit) => visit.id ?? 'Unknown',
            (visit) => 'Visit completed',
          ),
        
        const SizedBox(height: 10),
        
        // Recent shifts
        if (_shifts.isNotEmpty)
          _buildRecentItemsCard(
            'Recent Shifts',
            _shifts.take(5).toList(),
            (shift) => shift.carerId ?? 'Unknown',
            (shift) => '${shift.startTime} - ${shift.endTime}',
          ),
      ],
    );
  }

  Widget _buildRecentItemsCard<T>(
    String title,
    List<T> items,
    String Function(T) primaryText,
    String Function(T) secondaryText,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryText(item),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              secondaryText(item),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildActionChip('Risk Assessments', Icons.assignment, () {
              // Navigate to risk assessments
            }),
            _buildActionChip('Daily Charts', Icons.insert_chart, () {
              // Navigate to daily charts
            }),
            _buildActionChip('Audits', Icons.checklist, () {
              // Navigate to audits
            }),
            _buildActionChip('Staff Records', Icons.person, () {
              // Navigate to staff records
            }),
            _buildActionChip('Compliance', Icons.shield, () {
              // Navigate to compliance
            }),
            _buildActionChip('Reports', Icons.analytics, () {
              // Navigate to reports
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      icon: Icon(icon),
      onPressed: onTap,
      backgroundColor: Colors.grey[100],
    );
  }
}