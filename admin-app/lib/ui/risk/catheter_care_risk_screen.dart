import 'package:flutter/material.dart';
import 'package:admin_app/models/catheter_care_risk_assessment.dart';
import 'package:admin_app/services/catheter_care_risk_service.dart';
import 'package:admin_app/ui/risk/catheter_care_risk_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CatheterCareRiskScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const CatheterCareRiskScreen({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
  }) : super(key: key);

  @override
  _CatheterCareRiskScreenState createState() => _CatheterCareRiskScreenState();
}

class _CatheterCareRiskScreenState extends State<CatheterCareRiskScreen> {
  final _catheterCareService = CatheterCareRiskService(Supabase.instance.client);
  late Future<List<CatheterCareRiskAssessment>> _assessmentsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _assessmentsFuture = _loadAssessments();
  }

  Future<List<CatheterCareRiskAssessment>> _loadAssessments() async {
    try {
      return await _catheterCareService.getAssessmentsByServiceUser(widget.serviceUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load assessments: $e')),
      );
      return [];
    }
  }

  Future<void> _refreshAssessments() async {
    setState(() {
      _assessmentsFuture = _loadAssessments();
    });
  }

  Color _getRiskLevelColor(String? riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRiskLevelText(String? riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return 'Critical Risk';
      case 'high':
        return 'High Risk';
      case 'medium':
        return 'Medium Risk';
      case 'low':
        return 'Low Risk';
      default:
        return 'Unknown';
    }
  }

  Future<void> _createNewAssessment() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatheterCareRiskForm(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          onSaved: _refreshAssessments,
        ),
      ),
    );
  }

  Future<void> _editAssessment(CatheterCareRiskAssessment assessment) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatheterCareRiskForm(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          assessmentId: assessment.id,
          onSaved: _refreshAssessments,
        ),
      ),
    );
  }

  Future<void> _viewAssessmentDetails(CatheterCareRiskAssessment assessment) async {
    await showDialog(
      context: context,
      builder: (context) => _CatheterCareAssessmentDialog(assessment: assessment),
    );
  }

  Future<void> _deleteAssessment(CatheterCareRiskAssessment assessment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: const Text('Are you sure you want to delete this assessment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await _catheterCareService.deleteAssessment(assessment.id!);
        await _refreshAssessments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assessment deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete assessment: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catheter Care Risk Assessments - ${widget.serviceUserName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewAssessment,
            tooltip: 'Add New Assessment',
          ),
        ],
      ),
      body: FutureBuilder<List<CatheterCareRiskAssessment>>(
        future: _assessmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No catheter care risk assessments found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first assessment to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createNewAssessment,
                    child: const Text('Create New Assessment'),
                  ),
                ],
              ),
            );
          } else {
            final assessments = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refreshAssessments,
              child: ListView.builder(
                itemCount: assessments.length,
                itemBuilder: (context, index) {
                  final assessment = assessments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () => _viewAssessmentDetails(assessment),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assessment ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Date: ${DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      if (assessment.insertionDate != null)
                                        Text(
                                          'Catheter Type: ${assessment.getCatheterTypeDisplay()}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getRiskLevelColor(assessment.overallRiskLevel),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getRiskLevelText(assessment.overallRiskLevel),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
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
                                      if (assessment.urineAppearance != null)
                                        Text(
                                          'Urine: ${assessment.getUrineAppearanceDisplay()}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      if (assessment.skinCondition != null)
                                        Text(
                                          'Skin: ${assessment.getSkinConditionDisplay()}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      if (assessment.feverCelsius != null && assessment.feverCelsius! > 37.5)
                                        Text(
                                          'Temperature: ${assessment.feverCelsius}°C (Elevated)',
                                          style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _editAssessment(assessment);
                                        break;
                                      case 'delete':
                                        _deleteAssessment(assessment);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 16),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 16, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: const Icon(Icons.more_vert),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewAssessment,
        tooltip: 'Add New Assessment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CatheterCareAssessmentDialog extends StatelessWidget {
  final CatheterCareRiskAssessment assessment;

  const _CatheterCareAssessmentDialog({Key? key, required this.assessment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.water_drop),
          const SizedBox(width: 8),
          const Text('Catheter Care Risk Assessment'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Assessment Date', DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)),
            _buildDetailRow('Catheter Type', assessment.getCatheterTypeDisplay()),
            if (assessment.insertionDate != null)
              _buildDetailRow('Insertion Date', DateFormat('dd/MM/yyyy').format(assessment.insertionDate!)),
            if (assessment.nextChangeDate != null)
              _buildDetailRow('Next Change Date', DateFormat('dd/MM/yyyy').format(assessment.nextChangeDate!)),
            if (assessment.catheterSize != null)
              _buildDetailRow('Catheter Size', '${assessment.catheterSize} Fr'),
            if (assessment.balloonVolume != null)
              _buildDetailRow('Balloon Volume', '${assessment.balloonVolume} ml'),
            
            const Divider(),
            const Text('Urine Monitoring:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (assessment.urineOutputMl != null)
              _buildDetailRow('Urine Output', '${assessment.urineOutputMl} ml/24h'),
            _buildDetailRow('Urine Appearance', assessment.getUrineAppearanceDisplay()),
            _buildDetailRow('Urine Odour', assessment.getUrineOdourDisplay()),
            
            const Divider(),
            const Text('Infection Signs:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (assessment.feverCelsius != null)
              _buildDetailRow('Temperature', '${assessment.feverCelsius}°C'),
            if (assessment.painLevel != null)
              _buildDetailRow('Pain Level', '${assessment.painLevel}/10'),
            if (assessment.painLocation != null && assessment.painLocation!.isNotEmpty)
              _buildDetailRow('Pain Location', assessment.painLocation!),
            
            const Divider(),
            const Text('Skin Condition:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildDetailRow('Skin Condition', assessment.getSkinConditionDisplay()),
            if (assessment.skinConditionNotes != null && assessment.skinConditionNotes!.isNotEmpty)
              _buildDetailRow('Notes', assessment.skinConditionNotes!),
            
            const Divider(),
            const Text('Drainage System:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildDetailRow('Bag Position', assessment.getDrainageBagPositionDisplay()),
            _buildDetailRow('Bag Secure', assessment.drainageBagSecure == true ? 'Yes' : 'No'),
            
            const Divider(),
            const Text('Risk Assessment:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildRiskRow('Infection Risk', assessment.infectionRisk),
            _buildRiskRow('Blockage Risk', assessment.blockageRisk),
            _buildRiskRow('Dislodgement Risk', assessment.dislodgementRisk),
            _buildDetailRow('Overall Risk', _getRiskLevelText(assessment.overallRiskLevel)),
            
            const Divider(),
            const Text('Patient Comfort:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (assessment.comfortLevel != null)
              _buildDetailRow('Comfort Level', assessment.getComfortLevelDisplay()),
            if (assessment.patientConcerns != null && assessment.patientConcerns!.isNotEmpty)
              _buildDetailRow('Concerns', assessment.patientConcerns!),
            
            const Divider(),
            const Text('Staff & Review:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildDetailRow('Competency Verified', assessment.staffCompetencyVerified == true ? 'Yes' : 'No'),
            if (assessment.reviewDate != null)
              _buildDetailRow('Review Date', DateFormat('dd/MM/yyyy').format(assessment.reviewDate!)),
            if (assessment.actionPlan != null && assessment.actionPlan!.isNotEmpty)
              _buildDetailRow('Action Plan', assessment.actionPlan!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskRow(String label, String? risk) {
    Color color;
    switch (risk) {
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.amber;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              risk ?? 'Not assessed',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getRiskLevelText(String? riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return 'Critical Risk';
      case 'high':
        return 'High Risk';
      case 'medium':
        return 'Medium Risk';
      case 'low':
        return 'Low Risk';
      default:
        return 'Unknown';
    }
  }
}