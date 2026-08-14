import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';
import 'competency_list_screen.dart';
import 'moving_assisting_competency_form.dart';
import 'spot_check_competency_form.dart';
import 'fire_safety_competency_form.dart';
import 'communication_competency_form.dart';
import 'safeguarding_competency_form.dart';
import 'catheter_care_competency_form.dart';
import 'infection_control_competency_form.dart';
import 'dignity_respect_competency_form.dart';
import 'mental_capacity_competency_form.dart';
import 'first_aid_competency_form.dart';
import 'pressure_prevention_competency_form.dart';

/// Dashboard screen displaying competency assessment summaries.
class CompetencyDashboardScreen extends StatefulWidget {
  const CompetencyDashboardScreen({super.key});

  @override
  State<CompetencyDashboardScreen> createState() =>
      _CompetencyDashboardScreenState();
}

class _CompetencyDashboardScreenState extends State<CompetencyDashboardScreen> {
  final _competencyService = CompetencyService(Supabase.instance.client);
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _expiredRecords = [];
  List<Map<String, dynamic>> _expiringRecords = [];
  List<Map<String, dynamic>> _roleCompliance = [];
  List<Map<String, dynamic>> _gapAnalysis = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _competencyService.getCompetencySummary();
      final expired = await _competencyService.getExpiredCompetencies();
      final expiring = await _competencyService.getExpiringCompetencies(30);
      
      // Load role compliance and gap analysis
      final roleCompliance = await _loadRoleCompliance();
      final gapAnalysis = await _loadGapAnalysis();

      setState(() {
        _summary = summary;
        _expiredRecords = expired;
        _expiringRecords = expiring;
        _roleCompliance = roleCompliance;
        _gapAnalysis = gapAnalysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load competency data: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadRoleCompliance() async {
    try {
      final roles = ['care_worker', 'senior_carer', 'team_leader', 'manager', 'nurse'];
      final compliance = <Map<String, dynamic>>[];

      for (final role in roles) {
        final gap = await _competencyService.calculateGap('', role);
        final totalRequired = gap['total_required'] ?? 0;
        final totalMet = gap['total_met'] ?? 0;
        final percentage = totalRequired > 0 ? (totalMet / totalRequired * 100).round() : 0;

        compliance.add({
          'role': role,
          'total_required': totalRequired,
          'total_met': totalMet,
          'percentage': percentage,
        });
      }

      return compliance;
    } catch (e) {
      print('Error loading role compliance: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadGapAnalysis() async {
    try {
      final roles = ['care_worker', 'senior_carer', 'team_leader', 'manager', 'nurse'];
      final allGaps = <Map<String, dynamic>>[];

      for (final role in roles) {
        final gap = await _competencyService.calculateGap('', role);
        final missing = gap['missing'] as List<String>? ?? [];
        final belowLevel = gap['below_level'] as Map<String, int>? ?? {};

        for (final competencyId in missing) {
          allGaps.add({
            'role': role,
            'competency_id': competencyId,
            'gap_type': 'missing',
            'gap_size': 1,
          });
        }

        for (final entry in belowLevel.entries) {
          allGaps.add({
            'role': role,
            'competency_id': entry.key,
            'gap_type': 'below_level',
            'gap_size': entry.value,
          });
        }
      }

      // Sort by gap size (critical first)
      allGaps.sort((a, b) => (b['gap_size'] as int).compareTo(a['gap_size'] as int));

      return allGaps.take(20).toList(); // Top 20 gaps
    } catch (e) {
      print('Error loading gap analysis: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competency Dashboard'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Alerts Section
                    if (_expiredRecords.isNotEmpty || _expiringRecords.isNotEmpty)
                      _buildAlertsSection(),
                    const SizedBox(height: 24),

                    // Role Compliance
                    _buildRoleComplianceSection(),
                    const SizedBox(height: 24),

                    // Gap Analysis
                    if (_gapAnalysis.isNotEmpty) _buildGapAnalysisSection(),
                    const SizedBox(height: 24),

                    // Competency Categories Grid
                    _buildCompetencyGrid(),
                  ],
                ),
              ),
            ),
    );
  }

   Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MovingAssistingCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Moving & Assisting'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SpotCheckCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Spot Check'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FireSafetyCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fire_extinguisher),
                    label: const Text('Fire Safety'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunicationCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Communication'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SafeguardingCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Safeguarding'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CatheterCareCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Catheter Care'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InfectionControlCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.health_and_safety),
                    label: const Text('Infection Control'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DignityRespectCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.handshake),
                    label: const Text('Dignity & Respect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MentalCapacityCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_tree),
                    label: const Text('Mental Capacity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FirstAidCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_hospital),
                    label: const Text('First Aid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PressurePreventionCompetencyForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bed),
                    label: const Text('Pressure Prevention'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Placeholder for other forms
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('More forms coming soon')),
                      );
                    },
                    icon: const Icon(Icons.more),
                    label: const Text('More Forms'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalAssessments = _summary['total_assessments'] ?? 0;
    final competent = _summary['competent'] ?? 0;
    final developmentNeeded = _summary['development_needed'] ?? 0;
    final notCompetent = _summary['not_competent'] ?? 0;
    final averageScore = _summary['average_score'] ?? 0.0;
    final compliancePercentage = totalAssessments > 0 
        ? ((competent + developmentNeeded) / totalAssessments * 100).round() 
        : 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Competency Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'Total Assessed',
                  totalAssessments.toString(),
                  Icons.assessment,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Compliance %',
                  '$compliancePercentage%',
                  Icons.check_circle,
                  _getComplianceColor(compliancePercentage),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Competent',
                  competent.toString(),
                  Icons.thumb_up,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Needs Development',
                  developmentNeeded.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  'Not Competent',
                  notCompetent.toString(),
                  Icons.thumb_down,
                  Colors.red,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Average Score',
                  averageScore.toStringAsFixed(1),
                  Icons.star,
                  Colors.purple,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Expired',
                  _expiredRecords.length.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Expiring Soon',
                  _expiringRecords.length.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getComplianceColor(int percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.lightGreen;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Attention Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_expiredRecords.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: Text('${_expiredRecords.length} Expired Competencies'),
                subtitle: const Text('These need immediate renewal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompetencyListScreen(
                        competencyType: null,
                        competencyName: 'Expired Competencies',
                        filterStatus: 'expired',
                      ),
                    ),
                  );
                },
              ),
            if (_expiringRecords.isNotEmpty)
              ListTile(
                leading: Icon(Icons.warning, color: Colors.orange),
                title: Text('${_expiringRecords.length} Expiring Soon'),
                subtitle: const Text('Expiring within 30 days'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompetencyListScreen(
                        competencyType: null,
                        competencyName: 'Expiring Competencies',
                        filterStatus: 'expiring',
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleComplianceSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role Compliance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            ..._roleCompliance.map((role) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getRoleDisplayName(role['role']),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${role['total_met']}/${role['total_required']} (${role['percentage']}%)',
                        style: TextStyle(
                          color: _getComplianceColor(role['percentage']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (role['percentage'] as int) / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getComplianceColor(role['percentage']),
                    ),
                    minHeight: 8,
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'care_worker': return 'Care Worker';
      case 'senior_carer': return 'Senior Carer';
      case 'team_leader': return 'Team Leader';
      case 'manager': return 'Manager';
      case 'nurse': return 'Nurse';
      default: return role;
    }
  }

  Widget _buildGapAnalysisSection() {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Priority Gaps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Top ${_gapAnalysis.length} competencies requiring attention',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ..._gapAnalysis.take(10).map((gap) => ListTile(
              leading: CircleAvatar(
                backgroundColor: gap['gap_type'] == 'missing' ? Colors.red : Colors.orange,
                child: Icon(
                  gap['gap_type'] == 'missing' ? Icons.error : Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                '${_getRoleDisplayName(gap['role'])}: ${gap['competency_id']}',
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                gap['gap_type'] == 'missing' 
                    ? 'Not assessed' 
                    : '${gap['gap_size']} levels below required',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Icon(
                gap['gap_type'] == 'missing' ? Icons.priority_high : Icons.arrow_downward,
                color: Colors.red,
                size: 20,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetencyGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Competency Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: CompetencyCategory.values.length,
          itemBuilder: (context, index) {
            final category = CompetencyCategory.values[index];
            return _buildCompetencyCard(
              name: category.displayName,
              icon: category.icon,
              category: category,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompetencyCard({
    required String name,
    required IconData icon,
    required CompetencyCategory category,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompetencyListScreen(
                competencyType: category.name,
                competencyName: name,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: const Color(0xFF1565C0), size: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Expanded(
                child: Text(
                  category.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Competency categories enum
enum CompetencyCategory {
  clinical('Clinical Skills', Icons.medical_services, 'Medical and nursing competencies'),
  communication('Communication', Icons.chat, 'Interpersonal and communication skills'),
  professional('Professional', Icons.badge, 'Professional standards and ethics'),
  safety('Safety', Icons.security, 'Health and safety competencies'),
  management('Management', Icons.manage_accounts, 'Leadership and management skills'),
  digital('Digital', Icons.computer, 'Digital literacy and systems');

  final String displayName;
  final IconData icon;
  final String description;

  const CompetencyCategory(this.displayName, this.icon, this.description);
}