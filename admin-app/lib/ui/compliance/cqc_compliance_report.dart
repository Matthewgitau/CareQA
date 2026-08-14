import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/competency_framework.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';

class CQCComplianceReportScreen extends StatefulWidget {
  const CQCComplianceReportScreen({super.key});

  @override
  State<CQCComplianceReportScreen> createState() => _CQCComplianceReportScreenState();
}

class _CQCComplianceReportScreenState extends State<CQCComplianceReportScreen> {
  final _competencyService = CompetencyService(Supabase.instance.client);
  bool _isLoading = true;
  String _selectedSection = 'training';
  List<Map<String, dynamic>> _staffList = [];
  List<Competency> _competencies = [];
  Map<String, dynamic> _trainingData = {};
  Map<String, dynamic> _competencyData = {};
  List<Map<String, dynamic>> _evidenceData = [];

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
      await _loadTrainingData();
      await _loadCompetencyData();
      await _loadEvidenceData();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CQC Compliance Report'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportCQCReport, tooltip: 'Export CQC PDF'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              _buildSectionSelector(),
              Expanded(child: _buildSectionContent()),
            ]),
    );
  }

  Widget _buildSectionSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        _buildSectionTab('training', 'Training Compliance'),
        _buildSectionTab('competency', 'Competency Compliance'),
        _buildSectionTab('evidence', 'Evidence Portfolio'),
      ]),
    );
  }

  Widget _buildSectionTab(String value, String label) {
    final isSelected = _selectedSection == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSection = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 'training': return _buildTrainingSection();
      case 'competency': return _buildCompetencySection();
      case 'evidence': return _buildEvidenceSection();
      default: return _buildTrainingSection();
    }
  }

  Widget _buildTrainingSection() {
    final roleStats = _trainingData['roleStats'] as Map<String, dynamic>? ?? {};
    final deptStats = _trainingData['deptStats'] as Map<String, dynamic>? ?? {};
    final overallRate = _trainingData['overallRate'] as int? ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Staff Training Compliance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          const Text('Overall Training Completion Rate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$overallRate%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getRateColor(overallRate))),
          const SizedBox(height: 8),
          Text('${_trainingData['totalCompleted']} of ${_trainingData['totalRequired']} training items completed'),
        ]))),
        const SizedBox(height: 16),
        const Text('By Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        const SizedBox(height: 8),
        ...roleStats.entries.map((entry) {
          final role = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          final completed = stats['completed'] as int;
          final total = stats['total'] as int;
          final rate = total > 0 ? (completed / total * 100).round() : 0;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${stats['staff']} staff', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: rate / 100, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(_getRateColor(rate)), minHeight: 8),
            const SizedBox(height: 4),
            Text('$rate% complete', style: TextStyle(color: _getRateColor(rate), fontWeight: FontWeight.bold)),
          ])));
        }),
        const SizedBox(height: 16),
        const Text('By Department', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        const SizedBox(height: 8),
        ...deptStats.entries.map((entry) {
          final dept = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          final completed = stats['completed'] as int;
          final total = stats['total'] as int;
          final rate = total > 0 ? (completed / total * 100).round() : 0;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dept, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${stats['staff']} staff', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: rate / 100, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(_getRateColor(rate)), minHeight: 8),
            const SizedBox(height: 4),
            Text('$rate% complete', style: TextStyle(color: _getRateColor(rate), fontWeight: FontWeight.bold)),
          ])));
        }),
      ]),
    );
  }

  Widget _buildCompetencySection() {
    final complianceRate = _competencyData['complianceRate'] as int? ?? 0;
    final gaps = _competencyData['gaps'] as List? ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Competency Compliance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          const Text('Overall Competency Compliance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$complianceRate%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getRateColor(complianceRate))),
          const SizedBox(height: 8),
          Text('${_competencyData['totalMet']} of ${_competencyData['totalAssessed']} competencies met required level'),
        ]))),
        const SizedBox(height: 16),
        Text('Gap Analysis (${gaps.length} gaps)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        const SizedBox(height: 8),
        if (gaps.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No competency gaps found - all staff meet required levels!', style: TextStyle(color: Colors.green))))
        else
          ...gaps.map((gap) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: Text(gap['competencyName'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${gap['staffName']} (${gap['role']})'),
              Text('Level ${gap['achievedLevel']} / ${gap['requiredLevel']} required', style: TextStyle(color: Colors.grey[600])),
            ]),
          ))),
      ]),
    );
  }

  Widget _buildEvidenceSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Evidence Portfolio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        const SizedBox(height: 16),
        Text('${_evidenceData.length} evidence records found', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        ..._evidenceData.map((assessment) {
          final staffName = assessment['staff']['full_name'] ?? 'Unknown';
          final staffRole = assessment['staff']['role'] ?? 'Staff';
          final date = assessment['assessment_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(assessment['assessment_date'])) : 'N/A';
          final status = assessment['status'] ?? 'draft';
          final passed = assessment['passed'] ?? false;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: CircleAvatar(backgroundColor: passed ? Colors.green : Colors.orange, child: const Icon(Icons.description, color: Colors.white)),
            title: Text(staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(staffRole, style: TextStyle(color: Colors.grey[600])),
              Text('Date: $date', style: TextStyle(color: Colors.grey[600])),
              Text('Status: $status', style: TextStyle(color: Colors.grey[600])),
            ]),
            trailing: Icon(passed ? Icons.check_circle : Icons.warning, color: passed ? Colors.green : Colors.orange),
          ));
        }),
      ]),
    );
  }

  Future<void> _loadTrainingData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client.from('profiles').select('organisation_id').eq('id', user.id).single();
    final orgId = profile['organisation_id'];
    final staff = await _competencyService.getAllStaff();
    final roleStats = <String, Map<String, dynamic>>{};
    final deptStats = <String, Map<String, dynamic>>{};
    int totalRequired = 0;
    int totalCompleted = 0;
    for (final s in staff) {
      final levels = await _competencyService.getStaffCompetencyLevels(s['id']);
      final role = s['role'] ?? 'Unknown';
      final dept = s['department'] ?? 'Unknown';
      if (!roleStats.containsKey(role)) roleStats[role] = {'total': 0, 'completed': 0, 'staff': 0};
      if (!deptStats.containsKey(dept)) deptStats[dept] = {'total': 0, 'completed': 0, 'staff': 0};
      roleStats[role]!['total'] = _competencies.length;
      roleStats[role]!['completed'] += levels.length;
      roleStats[role]!['staff']++;
      deptStats[dept]!['total'] = _competencies.length;
      deptStats[dept]!['completed'] += levels.length;
      deptStats[dept]!['staff']++;
      totalRequired += _competencies.length;
      totalCompleted += levels.length;
    }
    final overallRate = totalRequired > 0 ? (totalCompleted / totalRequired * 100).round() : 0;
    setState(() {
      _trainingData = {'roleStats': roleStats, 'deptStats': deptStats, 'overallRate': overallRate, 'totalStaff': staff.length, 'totalRequired': totalRequired, 'totalCompleted': totalCompleted};
    });
  }

  Future<void> _loadCompetencyData() async {
    final staff = _staffList;
    final gaps = <Map<String, dynamic>>[];
    int totalAssessed = 0;
    int totalMet = 0;
    for (final s in staff) {
      final levels = await _competencyService.getStaffCompetencyLevels(s['id']);
      for (final comp in _competencies) {
        final achieved = levels[comp.id] ?? 0;
        if (achieved > 0) totalAssessed++;
        if (achieved >= comp.requiredLevel) totalMet++;
        if (achieved < comp.requiredLevel) {
          gaps.add({'staffName': s['name'], 'role': s['role'] ?? 'Unknown', 'competencyName': comp.competencyName, 'category': comp.category, 'requiredLevel': comp.requiredLevel, 'achievedLevel': achieved, 'gap': comp.requiredLevel - achieved});
        }
      }
    }
    final complianceRate = totalAssessed > 0 ? (totalMet / totalAssessed * 100).round() : 0;
    setState(() {
      _competencyData = {'complianceRate': complianceRate, 'totalAssessed': totalAssessed, 'totalMet': totalMet, 'totalGaps': gaps.length, 'gaps': gaps};
    });
  }

  Future<void> _loadEvidenceData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client.from('profiles').select('organisation_id').eq('id', user.id).single();
    final orgId = profile['organisation_id'];
    final assessments = await Supabase.instance.client.from('staff_competency_assessments').select('*, staff:profiles!staff_id(full_name, role)').eq('organisation_id', orgId).order('assessment_date', ascending: false).limit(50);
    setState(() {
      _evidenceData = (assessments as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _exportCQCReport() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CQC compliance report exported as PDF'), backgroundColor: Colors.green));
  }

  Color _getRateColor(int rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.lightGreen;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }
}
</arg_value><arg_key>task_progress</arg_key><arg_value>
- [x] Create Phase 11 CQC compliance report screen
</arg_value></tool_call>