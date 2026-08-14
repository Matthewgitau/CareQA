import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';

class MyCompetenciesScreen extends StatefulWidget {
  const MyCompetenciesScreen({super.key});

  @override
  State<MyCompetenciesScreen> createState() => _MyCompetenciesScreenState();
}

class _MyCompetenciesScreenState extends State<MyCompetenciesScreen> {
  final _competencyService = CompetencyService(Supabase.instance.client);
  bool _isLoading = true;
  Map<String, dynamic> _profile = {};
  List<Competency> _competencies = [];
  List<CompetencyAssessment> _myAssessments = [];
  List<Map<String, dynamic>> _developmentPlan = [];
  Map<String, int> _myLevels = {};
  String? _staffId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _staffId = user.id;

      // Load profile
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      // Load all competencies
      final competencies = await _competencyService.getCompetencyFramework();

      // Load my assessments
      final assessments = await _competencyService.getStaffCompetencies(user.id);

      // Load my competency levels
      final levels = await _competencyService.getStaffCompetencyLevels(user.id);

      // Load development plan
      final devPlan = await _competencyService.getDevelopmentPlan(user.id);

      setState(() {
        _profile = profile;
        _competencies = competencies;
        _myAssessments = assessments;
        _myLevels = levels;
        _developmentPlan = devPlan != null ? [devPlan.toJson()] : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load competencies: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Competencies'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Summary
                    _buildProfileSummary(),
                    const SizedBox(height: 24),

                    // Overall Status
                    _buildOverallStatus(),
                    const SizedBox(height: 24),

                    // Competency Cards
                    _buildCompetencySection(),
                    const SizedBox(height: 24),

                    // Development Plan
                    if (_developmentPlan.isNotEmpty) _buildDevelopmentPlanSection(),
                    const SizedBox(height: 24),

                    // Request Assessment Button
                    _buildRequestAssessmentButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF1565C0),
                  child: Text(
                    _profile['full_name']?.toString().substring(0, 2).toUpperCase() ?? 'ST',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile['full_name'] ?? 'Staff Member',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile['role'] ?? 'Staff',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_profile['department'] != null)
                        Text(
                          _profile['department'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatus() {
    final totalCompetencies = _competencies.length;
    final assessedCount = _myLevels.length;
    final metCount = _myLevels.entries.where((e) {
      final competency = _competencies.firstWhere(
        (c) => c.id == e.key,
        orElse: () => Competency(
          id: '',
          competencyCode: '',
          competencyName: '',
          category: '',
          description: '',
          requiredLevel: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return e.value >= competency.requiredLevel;
    }).length;

    final compliancePercentage = totalCompetencies > 0
        ? (assessedCount / totalCompetencies * 100).round()
        : 0;

    return Card(
      elevation: 2,
      color: _getComplianceColor(compliancePercentage),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Competency Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getComplianceColor(compliancePercentage).computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$assessedCount of $totalCompetencies competencies assessed',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getComplianceColor(compliancePercentage).computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$compliancePercentage%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getComplianceColor(compliancePercentage).computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                Text(
                  'Compliance',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getComplianceColor(compliancePercentage).computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Competencies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 12),
        if (_competencies.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.workspace_premium, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No competencies assigned',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _competencies.length,
            itemBuilder: (context, index) {
              final competency = _competencies[index];
              final achievedLevel = _myLevels[competency.id] ?? 0;
              final status = _getCompetencyStatus(competency, achievedLevel);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: status['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(competency.category),
                      color: status['color'],
                      size: 24,
                    ),
                  ),
                  title: Text(
                    competency.competencyName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(competency.getCategoryDisplay()),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Level: $achievedLevel / ${competency.requiredLevel}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: status['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: status['color'].withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              status['label'],
                              style: TextStyle(
                                color: status['color'],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: achievedLevel > 0
                      ? Icon(Icons.check_circle, color: status['color'])
                      : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDevelopmentPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Development Plan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Development Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        'In Progress',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._developmentPlan.map((plan) {
                  final goals = plan['goals'] as List? ?? [];
                  final completedGoals = goals.where((g) => g['status'] == 'completed').length;
                  final totalGoals = goals.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: $completedGoals / $totalGoals goals completed',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: totalGoals > 0 ? completedGoals / totalGoals : 0,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 16),
                      if (plan['notes'] != null && plan['notes'].isNotEmpty)
                        Text(
                          'Notes: ${plan['notes']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestAssessmentButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assessment request sent to your manager'),
              backgroundColor: Colors.green,
            ),
          );
        },
        icon: const Icon(Icons.assignment),
        label: const Text('Request Assessment'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Map<String, dynamic> _getCompetencyStatus(Competency competency, int achievedLevel) {
    if (achievedLevel == 0) {
      return {'label': 'Not Assessed', 'color': Colors.grey};
    } else if (achievedLevel >= competency.requiredLevel) {
      return {'label': 'Met', 'color': Colors.green};
    } else {
      return {'label': 'Gap', 'color': Colors.red};
    }
  }

  Color _getComplianceColor(int percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.lightGreen;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'clinical': return Icons.medical_services;
      case 'communication': return Icons.chat;
      case 'professional': return Icons.badge;
      case 'safety': return Icons.security;
      case 'management': return Icons.manage_accounts;
      case 'digital': return Icons.computer;
      default: return Icons.workspace_premium;
    }
  }
}