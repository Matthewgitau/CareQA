import 'package:flutter/material.dart';
import 'package:admin_app/models/diabetes_assessment.dart';
import 'package:admin_app/services/diabetes_service.dart';
import 'package:admin_app/ui/risk/diabetes_risk_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DiabetesRiskScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const DiabetesRiskScreen({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
  }) : super(key: key);

  @override
  _DiabetesRiskScreenState createState() => _DiabetesRiskScreenState();
}

class _DiabetesRiskScreenState extends State<DiabetesRiskScreen> {
  final _diabetesService = DiabetesService(Supabase.instance.client);
  late Future<List<DiabetesAssessment>> _assessmentsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _assessmentsFuture = _loadAssessments();
  }

  Future<List<DiabetesAssessment>> _loadAssessments() async {
    try {
      return await _diabetesService.getAssessmentsByServiceUser(widget.serviceUserId);
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
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRiskLevelText(String? riskLevel) {
    switch (riskLevel) {
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

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'completed':
        return 'Completed';
      case 'reviewed':
        return 'Reviewed';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'reviewed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _createNewAssessment() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiabetesRiskForm(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          onSaved: _refreshAssessments,
        ),
      ),
    );
  }

  Future<void> _editAssessment(DiabetesAssessment assessment) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiabetesRiskForm(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          assessmentId: assessment.id,
          onSaved: _refreshAssessments,
        ),
      ),
    );
  }

  Future<void> _viewAssessmentDetails(DiabetesAssessment assessment) async {
    await showDialog(
      context: context,
      builder: (context) => _DiabetesAssessmentDialog(assessment: assessment),
    );
  }

  Future<void> _deleteAssessment(DiabetesAssessment assessment) async {
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
        await _diabetesService.deleteAssessment(assessment.id!);
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
        title: Text('Diabetes Risk Assessments - ${widget.serviceUserName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewAssessment,
            tooltip: 'Add New Assessment',
          ),
        ],
      ),
      body: FutureBuilder<List<DiabetesAssessment>>(
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
                  const Icon(Icons.medical_services, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No diabetes risk assessments found',
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
                                        'Created: ${DateFormat('dd/MM/yyyy').format(assessment.createdAt)}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      if (assessment.updatedAt != assessment.createdAt)
                                        Text(
                                          'Updated: ${DateFormat('dd/MM/yyyy').format(assessment.updatedAt)}',
                                          style: const TextStyle(color: Colors.grey),
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
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(assessment.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(assessment.status),
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
                                      Text(
                                        'Diabetes Type: ${assessment.getDiabetesTypeDisplay()}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Monitoring: ${assessment.getBgMonitoringFrequencyDisplay()}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      if (assessment.lastHba1cValue != null)
                                        Text(
                                          'HbA1c: ${assessment.lastHba1cValue} %',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: assessment.isHighRiskHba1c ? Colors.red : Colors.black,
                                            fontWeight: assessment.isHighRiskHba1c ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      Text(
                                        'Hypoglycaemia: ${assessment.getHypoglycaemiaFrequencyDisplay()}',
                                        style: const TextStyle(fontSize: 14),
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
                                          Icon(Icons.delete, size: 16),
                                          SizedBox(width: 8),
                                          Text('Delete'),
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

class _DiabetesAssessmentDialog extends StatelessWidget {
  final DiabetesAssessment assessment;

  const _DiabetesAssessmentDialog({Key? key, required this.assessment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.medical_services),
          const SizedBox(width: 8),
          Text('Diabetes Risk Assessment'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Diabetes Type', assessment.getDiabetesTypeDisplay()),
            _buildDetailRow('Monitoring Frequency', assessment.getBgMonitoringFrequencyDisplay()),
            if (assessment.lastHba1cValue != null)
              _buildDetailRow('Last HbA1c', '${assessment.lastHba1cValue} %'),
            if (assessment.hba1cTarget != null)
              _buildDetailRow('HbA1c Target', '${assessment.hba1cTarget} %'),
            _buildDetailRow('Hypoglycaemia Frequency', assessment.getHypoglycaemiaFrequencyDisplay()),
            _buildDetailRow('Overall Risk Level', _getRiskLevelText(assessment.overallRiskLevel)),
            _buildDetailRow('Status', _getStatusText(assessment.status)),
            _buildDetailRow('Created', DateFormat('dd/MM/yyyy').format(assessment.createdAt)),
            if (assessment.updatedAt != assessment.createdAt)
              _buildDetailRow('Updated', DateFormat('dd/MM/yyyy').format(assessment.updatedAt)),
            
            const SizedBox(height: 16),
            const Text('Key Risk Indicators:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (assessment.isHighRiskHba1c)
              _buildRiskIndicator('High HbA1c (>58%)', Colors.red),
            if (assessment.isFrequentHypoglycaemia)
              _buildRiskIndicator('Frequent Hypoglycaemia', Colors.orange),
            if (assessment.hasFootComplications)
              _buildRiskIndicator('Foot Complications', Colors.red),
            if (assessment.hasEyeComplications)
              _buildRiskIndicator('Eye Complications', Colors.red),
            if (assessment.hasFrequentHospitalAdmissions)
              _buildRiskIndicator('Frequent Hospital Admissions', Colors.red),
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.warning, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getRiskLevelText(String? riskLevel) {
    switch (riskLevel) {
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

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'completed':
        return 'Completed';
      case 'reviewed':
        return 'Reviewed';
      default:
        return status;
    }
  }
}