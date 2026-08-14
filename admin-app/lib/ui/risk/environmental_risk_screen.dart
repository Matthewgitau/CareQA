import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/environmental_assessment.dart';
import 'package:admin_app/services/environmental_service.dart';
import 'package:admin_app/ui/risk/environmental_risk_form.dart';

class EnvironmentalRiskScreen extends StatefulWidget {
  final String? serviceUserId;

  const EnvironmentalRiskScreen({Key? key, this.serviceUserId}) : super(key: key);

  @override
  State<EnvironmentalRiskScreen> createState() => _EnvironmentalRiskScreenState();
}

class _EnvironmentalRiskScreenState extends State<EnvironmentalRiskScreen> {
  late final EnvironmentalService _environmentalService;
  late Future<List<EnvironmentalAssessment>> _assessmentsFuture;
  Map<String, String> _serviceUserNames = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _environmentalService = EnvironmentalService(Supabase.instance.client);
    _loadServiceUsers();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final data = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      final users = List<Map<String, dynamic>>.from(data as List);
      _serviceUserNames = {
        for (final u in users) u['id'] as String: u['name'] as String,
      };
    } catch (_) {
      // ignore
    }
    setState(() {
      _assessmentsFuture = _fetchAssessments();
    });
  }

  Future<List<EnvironmentalAssessment>> _fetchAssessments() async {
    try {
      return await _environmentalService.getAssessments(
        serviceUserId: widget.serviceUserId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load assessments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  Future<void> _refreshAssessments() async {
    setState(() {
      _assessmentsFuture = _fetchAssessments();
    });
  }

  Future<void> _createAssessment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnvironmentalRiskForm(),
      ),
    );

    if (result == true) {
      _refreshAssessments();
    }
  }

  Future<void> _editAssessment(EnvironmentalAssessment assessment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnvironmentalRiskForm(assessment: assessment),
      ),
    );

    if (result == true) {
      _refreshAssessments();
    }
  }

  Future<void> _deleteAssessment(String id) async {
    try {
      await _environmentalService.deleteAssessment(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _refreshAssessments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete assessment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low: return Colors.green;
      case RiskLevel.medium: return Colors.orange;
      case RiskLevel.high: return Colors.red;
      case RiskLevel.critical: return Colors.purple;
    }
  }

  String _getServiceUserName(String? userId) {
    if (userId == null) return 'Unknown';
    return _serviceUserNames[userId] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Risk Assessments'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createAssessment,
            tooltip: 'Add Assessment',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAssessments,
        child: FutureBuilder<List<EnvironmentalAssessment>>(
          future: _assessmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Failed to load assessments', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString()),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshAssessments,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('No assessments found', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Create your first environmental risk assessment'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _createAssessment,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text('Create Assessment'),
                    ),
                  ],
                ),
              );
            } else {
              final assessments = snapshot.data!;
              
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: assessments.length,
                itemBuilder: (context, index) {
                  final assessment = assessments[index];
                  final riskColor = _getRiskColor(assessment.riskLevel);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: InkWell(
                      onTap: () => _editAssessment(assessment),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with service user name
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: riskColor.withOpacity(0.1),
                                  child: Icon(
                                    assessment.riskLevel == RiskLevel.critical ? Icons.gpp_bad :
                                    assessment.riskLevel == RiskLevel.high ? Icons.warning :
                                    assessment.riskLevel == RiskLevel.medium ? Icons.info :
                                    Icons.check_circle,
                                    color: riskColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getServiceUserName(assessment.serviceUserId),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Location: ${assessment.location}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: riskColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    assessment.riskLevel.name.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Assessment details
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date: ${assessment.assessmentDate.toIso8601String().split('T').first}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      if (assessment.reviewDate != null)
                                        Text(
                                          'Review: ${assessment.reviewDate!.toIso8601String().split('T').first}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Key findings
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: [
                                _buildStatusChip('Lighting', assessment.lightingAdequacy),
                                _buildStatusChip('Ventilation', assessment.ventilation),
                                _buildStatusChip('Flooring', assessment.flooringCondition),
                                _buildStatusChip('Fire Exits', assessment.fireExits),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Action plan preview
                            if (assessment.actionPlan != null && assessment.actionPlan!.isNotEmpty)
                              Text(
                                'Action Plan: ${assessment.actionPlan!}',
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, AssessmentStatus status) {
    Color getColor(AssessmentStatus status) {
      switch (status) {
        case AssessmentStatus.good:
        case AssessmentStatus.adequate:
        case AssessmentStatus.safe:
        case AssessmentStatus.clear:
        case AssessmentStatus.accessible:
        case AssessmentStatus.working:
        case AssessmentStatus.patTested:
        case AssessmentStatus.secure:
        case AssessmentStatus.appropriate:
          return Colors.green;
        case AssessmentStatus.poor:
        case AssessmentStatus.inadequate:
        case AssessmentStatus.tripHazard:
        case AssessmentStatus.uneven:
        case AssessmentStatus.obstructed:
        case AssessmentStatus.blocked:
        case AssessmentStatus.notTested:
        case AssessmentStatus.damaged:
        case AssessmentStatus.insecure:
        case AssessmentStatus.inappropriate:
        case AssessmentStatus.unsafe:
          return Colors.orange;
        case AssessmentStatus.requiresAttention:
        case AssessmentStatus.disposal:
          return Colors.red;
      }
    }

    return Chip(
      label: Text('$label: ${_getStatusText(status)}', style: const TextStyle(fontSize: 12)),
      backgroundColor: getColor(status).withOpacity(0.1),
      labelStyle: TextStyle(color: getColor(status)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: getColor(status), width: 1),
      ),
    );
  }

  String _getStatusText(AssessmentStatus status) {
    switch (status) {
      case AssessmentStatus.good: return 'Good';
      case AssessmentStatus.poor: return 'Poor';
      case AssessmentStatus.requiresAttention: return 'Needs Attention';
      case AssessmentStatus.adequate: return 'Adequate';
      case AssessmentStatus.inadequate: return 'Inadequate';
      case AssessmentStatus.safe: return 'Safe';
      case AssessmentStatus.tripHazard: return 'Trip Hazard';
      case AssessmentStatus.uneven: return 'Uneven';
      case AssessmentStatus.clear: return 'Clear';
      case AssessmentStatus.obstructed: return 'Obstructed';
      case AssessmentStatus.accessible: return 'Accessible';
      case AssessmentStatus.blocked: return 'Blocked';
      case AssessmentStatus.working: return 'Working';
      case AssessmentStatus.notTested: return 'Not Tested';
      case AssessmentStatus.patTested: return 'PAT Tested';
      case AssessmentStatus.damaged: return 'Damaged';
      case AssessmentStatus.secure: return 'Secure';
      case AssessmentStatus.insecure: return 'Insecure';
      case AssessmentStatus.appropriate: return 'Appropriate';
      case AssessmentStatus.inappropriate: return 'Inappropriate';
      case AssessmentStatus.disposal: return 'Disposal';
      case AssessmentStatus.unsafe: return 'Unsafe';
    }
  }
}