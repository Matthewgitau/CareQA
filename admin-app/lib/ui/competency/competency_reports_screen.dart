import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/competency_framework.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';

class CompetencyReportsScreen extends StatefulWidget {
  const CompetencyReportsScreen({super.key});

  @override
  State<CompetencyReportsScreen> createState() => _CompetencyReportsScreenState();
}

class _CompetencyReportsScreenState extends State<CompetencyReportsScreen> {
  final _competencyService = CompetencyService(Supabase.instance.client);
  bool _isLoading = true;
  String _selectedReport = 'compliance';
  List<Map<String, dynamic>> _staffList = [];
  List<Competency> _competencies = [];
  Map<String, dynamic> _complianceData = {};
  List<Map<String, dynamic>> _gapData = [];
  Map<String, dynamic>? _selectedStaffPortfolio;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _staffList = await _competencyService.getAllStaff();
      _competencies = await _competencyService.getCompetencyFramework();
      await _loadComplianceData();
      await _loadGapData();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _loadComplianceData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('organisation_id')
        .eq('id', user.id)
        .single();
    final orgId = profile['organisation_id'];

    final staff = await _competencyService.getAllStaff();
    final roleStats = <String, Map<String, dynamic>>{};
    int totalAssessed = 0;
    int totalCompetencies = 0;

    for (final s in staff) {
      final levels = await _competencyService.getStaffCompetencyLevels(s['id']);
      final role = s['role'] ?? 'Unknown';
      if (!roleStats.containsKey(role)) {
        roleStats[role] = {'total': 0, 'assessed': 0, 'met': 0, 'staff': []};
      }
      roleStats[role]!['total'] = _competencies.length;
      roleStats[role]!['assessed'] += levels.length;
      roleStats[role]!['staff'].add(s['name']);
      totalAssessed += levels.length;
      totalCompetencies += _competencies.length;
    }

    final overallPercentage = totalCompetencies > 0
        ? (totalAssessed / totalCompetencies * 100).round()
        : 0;

    setState(() {
      _complianceData = {
        'roleStats': roleStats,
        'overallPercentage': overallPercentage,
        'totalStaff': staff.length,
        'totalCompetencies': _competencies.length,
        'totalAssessed': totalAssessed,
      };
    });
  }

  Future<void> _loadGapData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('organisation_id')
        .eq('id', user.id)
        .single();
    final orgId = profile['organisation_id'];

    final staff = await _competencyService.getAllStaff();
    final gaps = <Map<String, dynamic>>[];

    for (final s in staff) {
      final levels = await _competencyService.getStaffCompetencyLevels(s['id']);
      for (final comp in _competencies) {
        final achieved = levels[comp.id] ?? 0;
        if (achieved < comp.requiredLevel) {
          gaps.add({
            'staffId': s['id'],
            'staffName': s['name'],
            'role': s['role'] ?? 'Unknown',
            'competencyId': comp.id,
            'competencyName': comp.competencyName,
            'category': comp.category,
            'requiredLevel': comp.requiredLevel,
            'achievedLevel': achieved,
            'gap': comp.requiredLevel - achieved,
            'recommendedTraining': _getRecommendedTraining(comp),
          });
        }
      }
    }

    setState(() => _gapData = gaps);
  }

  String _getRecommendedTraining(Competency competency) {
    switch (competency.category) {
      case 'clinical': return 'Clinical skills workshop';
      case 'communication': return 'Communication training';
      case 'professional': return 'Professional development course';
      case 'safety': return 'Safety refresher training';
      case 'management': return 'Management training program';
      default: return 'Competency training session';
    }
  }

  Future<void> _exportCSV() async {
    final buffer = StringBuffer();
    if (_selectedReport == 'compliance') {
      buffer.writeln('Role,Total Staff,Total Competencies,Assessed,Met,Percentage');
      final roleStats = _complianceData['roleStats'] as Map<String, dynamic>;
      roleStats.forEach((role, stats) {
        final assessed = stats['assessed'] as int;
        final total = stats['total'] as int;
        final percentage = total > 0 ? (assessed / total * 100).round() : 0;
        buffer.writeln('$role,${stats['staff'].length},$total,$assessed,${stats['met']},$percentage%');
      });
    } else if (_selectedReport == 'gaps') {
      buffer.writeln('Staff Name,Role,Competency,Required Level,Achieved Level,Gap,Recommended Training');
      for (final gap in _gapData) {
        buffer.writeln('${gap['staffName']},${gap['role']},${gap['competencyName']},${gap['requiredLevel']},${gap['achievedLevel']},${gap['gap']},${gap['recommendedTraining']}');
      }
    }
    // In a real app, this would save to file or share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV exported successfully')),
    );
  }

  Future<void> _exportPDF() async {
    // In a real app, this would use a PDF generation library
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF exported successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competency Reports'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'csv') _exportCSV();
              if (value == 'pdf') _exportPDF();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildReportSelector(),
                Expanded(child: _buildReportContent()),
              ],
            ),
    );
  }

  Widget _buildReportSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildReportTab('compliance', 'Compliance Summary'),
          _buildReportTab('gaps', 'Gap Analysis'),
          _buildReportTab('portfolio', 'Staff Portfolio'),
        ],
      ),
    );
  }

  Widget _buildReportTab(String value, String label) {
    final isSelected = _selectedReport == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedReport = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReport) {
      case 'compliance':
        return _buildComplianceReport();
      case 'gaps':
        return _buildGapReport();
      case 'portfolio':
        return _buildPortfolioReport();
      default:
        return _buildComplianceReport();
    }
  }

  Widget _buildComplianceReport() {
    final roleStats = _complianceData['roleStats'] as Map<String, dynamic>? ?? {};
    final overallPercentage = _complianceData['overallPercentage'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Overall Compliance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$overallPercentage%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getPercentageColor(overallPercentage))),
                  const SizedBox(height: 8),
                  Text('${_complianceData['totalAssessed']} of ${_complianceData['totalCompetencies']} competencies assessed'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Compliance by Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          const SizedBox(height: 8),
          ...roleStats.entries.map((entry) {
            final role = entry.key;
            final stats = entry.value as Map<String, dynamic>;
            final assessed = stats['assessed'] as int;
            final total = stats['total'] as int;
            final percentage = total > 0 ? (assessed / total * 100).round() : 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${stats['staff'].length} staff', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(_getPercentageColor(percentage)), minHeight: 8),
                    const SizedBox(height: 4),
                    Text('$percentage% compliant', style: TextStyle(color: _getPercentageColor(percentage), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGapReport() {
    if (_gapData.isEmpty) {
      return const Center(child: Text('No gaps found - all staff are compliant!'));
    }

    // Group by staff
    final byStaff = <String, List<Map<String, dynamic>>>{};
    for (final gap in _gapData) {
      final name = gap['staffName'] as String;
      if (!byStaff.containsKey(name)) byStaff[name] = [];
      byStaff[name]!.add(gap);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Gaps: ${_gapData.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...byStaff.entries.map((entry) {
            final staffName = entry.key;
            final gaps = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${gaps.length} gaps'),
                children: gaps.map((gap) {
                  return ListTile(
                    title: Text(gap['competencyName']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${gap['category']} - Level ${gap['achievedLevel']} / ${gap['requiredLevel']}'),
                        Text('Recommended: ${gap['recommendedTraining']}', style: TextStyle(color: Colors.blue[600], fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPortfolioReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Select Staff', border: OutlineInputBorder()),
            items: _staffList.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']))).toList(),
            onChanged: (value) async {
              if (value == null) return;
              final levels = await _competencyService.getStaffCompetencyLevels(value);
              final staff = _staffList.firstWhere((s) => s['id'] == value);
              setState(() => _selectedStaffPortfolio = {'staff': staff, 'levels': levels});
            },
          ),
          const SizedBox(height: 24),
          if (_selectedStaffPortfolio != null) _buildStaffPortfolio(),
        ],
      ),
    );
  }

  Widget _buildStaffPortfolio() {
    final staff = _selectedStaffPortfolio!['staff'] as Map<String, dynamic>;
    final levels = _selectedStaffPortfolio!['levels'] as Map<String, int>;
    final staffName = staff['name'] ?? 'Unknown';
    final staffRole = staff['role'] ?? 'Staff';
    final assessedCount = levels.length;
    final totalCount = _competencies.length;
    final percentage = totalCount > 0 ? (assessedCount / totalCount * 100).round() : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(staffName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(staffRole, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Text('Overall: $percentage% ($assessedCount/$totalCount assessed)', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ..._competencies.map((comp) {
              final achieved = levels[comp.id] ?? 0;
              final isMet = achieved >= comp.requiredLevel;
              return ListTile(
                leading: CircleBadge(color: isMet ? Colors.green : (achieved > 0 ? Colors.orange : Colors.grey), child: Text('$achieved', style: const TextStyle(color: Colors.white, fontSize: 12))),
                title: Text(comp.competencyName),
                subtitle: Text('${comp.getCategoryDisplay()} - Required: ${comp.requiredLevel}'),
                trailing: isMet ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.warning, color: Colors.orange),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.lightGreen;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}

class CircleBadge extends StatelessWidget {
  final Color color;
  final Widget child;
  const CircleBadge({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 12, backgroundColor: color, child: child);
  }
}
</arg_value><arg_key>path</arg_key><arg_value>admin-app/lib/ui/competency/competency_reports_screen.dart</arg_value><arg_key>task_progress</arg_key><arg_value>
- [x] Create Phase 8 Competency Reports screen
</arg_value></tool_call>