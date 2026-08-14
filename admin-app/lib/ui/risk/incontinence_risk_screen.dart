import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/incontinence_assessment.dart';
import 'package:admin_app/services/incontinence_service.dart';
import 'package:admin_app/ui/risk/incontinence_risk_form.dart';

class IncontinenceRiskScreen extends StatefulWidget {
  final String? serviceUserId;

  const IncontinenceRiskScreen({Key? key, this.serviceUserId}) : super(key: key);

  @override
  State<IncontinenceRiskScreen> createState() => _IncontinenceRiskScreenState();
}

class _IncontinenceRiskScreenState extends State<IncontinenceRiskScreen> {
  late final IncontinenceService _incontinenceService;
  late Future<List<IncontinenceAssessment>> _assessmentsFuture;
  Map<String, String> _serviceUserNames = {};

  @override
  void initState() {
    super.initState();
    _incontinenceService = IncontinenceService(Supabase.instance.client);
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
    } catch (_) {}
    setState(() {
      _assessmentsFuture = _fetchAssessments();
    });
  }

  Future<List<IncontinenceAssessment>> _fetchAssessments() async {
    try {
      return await _incontinenceService.getAssessments(
        serviceUserId: widget.serviceUserId,
      );
    } catch (e) {
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
        builder: (context) => const IncontinenceRiskForm(),
      ),
    );

    if (result == true) {
      _refreshAssessments();
    }
  }

  Future<void> _editAssessment(IncontinenceAssessment assessment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncontinenceRiskForm(assessment: assessment),
      ),
    );

    if (result == true) {
      _refreshAssessments();
    }
  }

  Future<void> _deleteAssessment(String id) async {
    try {
      await _incontinenceService.deleteAssessment(id);
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

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incontinence Risk Assessments'),
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
        child: FutureBuilder<List<IncontinenceAssessment>>(
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
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
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
                    const Text('Create your first incontinence risk assessment'),
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
                  final userName = assessment.serviceUserId != null
                      ? _serviceUserNames[assessment.serviceUserId] ?? 'Unknown'
                      : 'Unknown';
                  final riskColor = _getRiskLevelColor(assessment.riskLevel);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: InkWell(
                      onTap: () => _editAssessment(assessment),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: riskColor.withOpacity(0.1),
                                  child: Icon(
                                    riskColor == Colors.red ? Icons.warning : Icons.info,
                                    color: riskColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Bladder: ${assessment.bladderContinenceStatusText} | Bowel: ${assessment.bowelContinenceStatusText}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                                    assessment.riskLevel.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
                                  ),
                                ),
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
                                        'Date: ${assessment.assessmentDate.toIso8601String().split('T').first}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      if (assessment.reviewDate != null)
                                        Text(
                                          'Review: ${assessment.reviewDate!.toIso8601String().split('T').first}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      Text(
                                        'Frequency: ${assessment.frequencyText}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                if (assessment.actionPlan != null && assessment.actionPlan!.isNotEmpty)
                                  const Icon(Icons.description, color: Colors.blueAccent),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: [
                                _buildStatusChip('Skin', assessment.skinConditionText),
                                _buildStatusChip('Mobility', assessment.mobilityAffectingAccess ? 'Limited' : 'Good'),
                                _buildStatusChip('Cognitive', assessment.cognitiveAwareness ? 'Aware' : 'Impaired'),
                              ],
                            ),

                            const SizedBox(height: 8),

                            if (assessment.actionPlan != null && assessment.actionPlan!.isNotEmpty)
                              Text(
                                'Action Plan: ${assessment.actionPlan!}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.blueGrey,
                                ),
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

  Widget _buildStatusChip(String label, String value) {
    Color getColor(String value) {
      if (value.toLowerCase().contains('yes') || value.toLowerCase().contains('good') || value.toLowerCase().contains('aware') || value.toLowerCase().contains('intact')) {
        return Colors.green;
      } else if (value.toLowerCase().contains('no') || value.toLowerCase().contains('limited') || value.toLowerCase().contains('impaired') || value.toLowerCase().contains('rash') || value.toLowerCase().contains('broken')) {
        return Colors.orange;
      } else {
        return Colors.blue;
      }
    }

    return Chip(
      label: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: getColor(value).withOpacity(0.1),
      labelStyle: TextStyle(color: getColor(value)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: getColor(value), width: 1),
      ),
    );
  }
}