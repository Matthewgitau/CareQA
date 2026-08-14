import 'package:flutter/material.dart';
import 'package:admin_app/models/coshh_risk_assessment.dart';
import 'package:admin_app/services/coshh_risk_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'coshh_risk_form.dart';

class CoshhRiskScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const CoshhRiskScreen({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
  }) : super(key: key);

  @override
  _CoshhRiskScreenState createState() => _CoshhRiskScreenState();
}

class _CoshhRiskScreenState extends State<CoshhRiskScreen> {
  final _coshhService = CoshhRiskService(Supabase.instance.client);
  late Future<List<CoshhRiskAssessment>> _assessmentsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _assessmentsFuture = _loadAssessments();
  }

  Future<List<CoshhRiskAssessment>> _loadAssessments() async {
    try {
      return await _coshhService.getAssessmentsByServiceUser(widget.serviceUserId);
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

  Future<void> _createNewAssessment() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoshhRiskForm(
          serviceUserId: widget.serviceUserId,
          onSaved: _refreshAssessments,
        ),
      ),
    );
  }

  Future<void> _editAssessment(CoshhRiskAssessment assessment) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoshhRiskForm(
          serviceUserId: widget.serviceUserId,
          assessmentId: assessment.id,
          onSaved: _refreshAssessments,
        ),
      ),
    );
  }

  Future<void> _deleteAssessment(CoshhRiskAssessment assessment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: const Text('Are you sure you want to delete this COSHH assessment?'),
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
        await _coshhService.deleteAssessment(assessment.id!);
        await _refreshAssessments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('COSHH assessment deleted successfully')),
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

  Future<void> _viewAssessmentDetails(CoshhRiskAssessment assessment) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('COSHH Assessment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Substance Name', assessment.substanceName),
              _buildDetailRow('Type of Harm', assessment.typeOfHarm),
              _buildDetailRow('Description', assessment.description),
              _buildDetailRow('How it Causes Harm', assessment.howCausesHarm),
              _buildDetailRow('Who is Exposed', assessment.whoExposed.join(', ')),
              _buildDetailRow('Frequency of Use', assessment.frequencyOfUse),
              _buildDetailRow('Purpose/Activity', assessment.purposeActivity),
              _buildDetailRow('Can be Eliminated', assessment.canBeEliminated ? 'Yes' : 'No'),
              if (assessment.eliminationReason != null)
                _buildDetailRow('Elimination Reason', assessment.eliminationReason!),
              _buildDetailRow('Staff Aware', assessment.staffAware ? 'Yes' : 'No'),
              _buildDetailRow('Training Required', assessment.trainingRequired ? 'Yes' : 'No'),
              if (assessment.trainingDetails != null && assessment.trainingDetails!.isNotEmpty)
                _buildDetailRow('Training Details', assessment.trainingDetails!),
              _buildDetailRow('Risk Acceptable', assessment.riskAcceptable ? 'Yes' : 'No'),
              _buildDetailRow('Risk Level', assessment.riskLevel ?? 'Not calculated'),
              if (assessment.reconsiderControls != null && assessment.reconsiderControls!.isNotEmpty)
                _buildDetailRow('Reconsider Controls', assessment.reconsiderControls!),
              _buildDetailRow('Assessment Date', assessment.assessmentDate.toLocal().toIso8601String()),
              _buildDetailRow('Status', assessment.status),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('COSHH Risk Assessments - ${widget.serviceUserName}'),
      ),
      body: FutureBuilder<List<CoshhRiskAssessment>>(
        future: _assessmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load assessments'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => setState(() => _assessmentsFuture = _loadAssessments()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No COSHH assessments found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first assessment to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
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
                    child: ListTile(
                      title: Text(
                        assessment.substanceName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${assessment.typeOfHarm}'),
                          Text('Risk Level: ${assessment.riskLevel ?? 'Not calculated'}'),
                          Text('Status: ${assessment.status}'),
                          Text('Date: ${assessment.assessmentDate.toLocal().toIso8601String()}'),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (assessment.riskLevel == 'High')
                            const Icon(Icons.warning, color: Colors.red),
                          if (assessment.trainingRequired)
                            const Icon(Icons.school, color: Colors.orange),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () => _viewAssessmentDetails(assessment),
                      onLongPress: () => _editAssessment(assessment),
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
        tooltip: 'New Assessment',
        child: const Icon(Icons.add),
      ),
    );
  }
}