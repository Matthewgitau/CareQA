import 'package:flutter/material.dart';
import 'package:admin_app/models/epilepsy_assessment.dart';
import 'package:admin_app/services/epilepsy_service.dart';
import 'package:admin_app/ui/risk/epilepsy_risk_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EpilepsyRiskScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const EpilepsyRiskScreen({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
  }) : super(key: key);

  @override
  _EpilepsyRiskScreenState createState() => _EpilepsyRiskScreenState();
}

class _EpilepsyRiskScreenState extends State<EpilepsyRiskScreen> {
  final _epilepsyService = EpilepsyService(Supabase.instance.client);
  List<EpilepsyAssessment> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    try {
      setState(() => _isLoading = true);
      _assessments = await _epilepsyService.getAssessmentsByServiceUser(widget.serviceUserId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load assessments: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewAssessment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EpilepsyRiskForm(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          onSaved: _loadAssessments,
        ),
      ),
    );
    
    if (result == true) {
      _loadAssessments();
    }
  }

  Future<void> _editAssessment(EpilepsyAssessment assessment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EpilepsyRiskForm(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          assessmentId: assessment.id,
          onSaved: _loadAssessments,
        ),
      ),
    );
    
    if (result == true) {
      _loadAssessments();
    }
  }

  Future<void> _deleteAssessment(String assessmentId) async {
    try {
      await _epilepsyService.deleteAssessment(assessmentId);
      _loadAssessments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessment deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete assessment: $e')),
      );
    }
  }

  Future<void> _viewAssessmentDetails(EpilepsyAssessment assessment) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AssessmentDetailsScreen(assessment: assessment),
      ),
    );
  }

  Future<void> _submitAssessment(EpilepsyAssessment assessment) async {
    try {
      await _epilepsyService.submitAssessment(assessment.id!, 'Digital Signature');
      _loadAssessments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessment submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit assessment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Epilepsy Risk Assessments - ${widget.serviceUserName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAssessmentList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAssessment,
        tooltip: 'Add New Assessment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAssessmentList() {
    if (_assessments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No epilepsy risk assessments found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to create a new assessment',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssessments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assessments.length,
        itemBuilder: (context, index) {
          final assessment = _assessments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
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
                                assessment.getSeizureTypeDisplay(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                assessment.getSeizureFrequencyDisplay(),
                                style: TextStyle(
                                  color: _getFrequencyColor(assessment.seizureFrequency),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRiskLevelColor(assessment.overallRiskLevel),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                assessment.overallRiskLevel?.toUpperCase() ?? 'UNKNOWN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              assessment.createdAt.toLocal().toIso8601String().split('T').first,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assessment.getSummary(),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(assessment.status),
                        const SizedBox(width: 8),
                        _buildComplianceChip(assessment.medicationCompliance),
                        if (assessment.safeguardingConcerns) ...[
                          const SizedBox(width: 8),
                          _buildSafeguardingChip(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (assessment.hasRescueMedication())
                          _buildRescueMedicationChip(assessment),
                        if (assessment.needsReview())
                          _buildReviewRequiredChip(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _editAssessment(assessment),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        if (assessment.status != 'completed')
                          TextButton.icon(
                            onPressed: () => _submitAssessment(assessment),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Submit'),
                          ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _deleteAssessment(assessment.id!),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
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

  Color _getFrequencyColor(String frequency) {
    switch (frequency) {
      case 'daily':
        return Colors.red;
      case 'weekly':
        return Colors.orange;
      case 'monthly':
        return Colors.yellow[700]!;
      case 'rarely':
        return Colors.green;
      case 'none':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'draft':
        color = Colors.grey;
        label = 'Draft';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'reviewed':
        color = Colors.blue;
        label = 'Reviewed';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildComplianceChip(bool compliance) {
    return Chip(
      label: Text(
        compliance ? 'Compliant' : 'Non-Compliant',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: compliance ? Colors.green : Colors.red,
    );
  }

  Widget _buildSafeguardingChip() {
    return Chip(
      label: const Text('Safeguarding', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.red,
    );
  }

  Widget _buildRescueMedicationChip(EpilepsyAssessment assessment) {
    return Chip(
      label: Text(
        'Rescue: ${assessment.getRescueMedicationInfo()}',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.blue,
    );
  }

  Widget _buildReviewRequiredChip() {
    return Chip(
      label: const Text('Review Required', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.orange,
    );
  }
}

class _AssessmentDetailsScreen extends StatelessWidget {
  final EpilepsyAssessment assessment;

  const _AssessmentDetailsScreen({Key? key, required this.assessment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Information
          _buildSection('Basic Information', [
            _buildDetailRow('Seizure Type', assessment.getSeizureTypeDisplay()),
            _buildDetailRow('Seizure Frequency', assessment.getSeizureFrequencyDisplay()),
            _buildDetailRow('Last Seizure', assessment.getDaysSinceLastSeizure()),
            _buildDetailRow('Risk Level', assessment.overallRiskLevel?.toUpperCase() ?? 'Unknown'),
            _buildDetailRow('Status', assessment.status),
          ]),

          // Medication Information
          _buildSection('Medication Information', [
            _buildDetailRow('Medication Name', assessment.medicationName ?? 'Not specified'),
            _buildDetailRow('Medication Dose', assessment.medicationDose ?? 'Not specified'),
            _buildDetailRow('Medication Times', assessment.medicationTimes?.join(', ') ?? 'Not specified'),
            _buildDetailRow('Medication Compliance', assessment.medicationCompliance ? 'Good' : 'Poor'),
          ]),

          // Seizure Characteristics
          _buildSection('Seizure Characteristics', [
            _buildDetailRow('Typical Duration', assessment.getTypicalDurationDisplay()),
            _buildDetailRow('Warning Signs', assessment.warningSigns ?? 'None reported'),
            _buildDetailRow('Recovery Time', assessment.getRecoveryTimeDisplay()),
            _buildDetailRow('Post-Seizure Behaviour', assessment.postSeizureBehaviour ?? 'Not specified'),
          ]),

          // Risk Factors
          _buildSection('Risk Factors', [
            _buildDetailRow('Safeguarding Concerns', assessment.safeguardingConcerns ? 'Yes' : 'No'),
            _buildDetailRow('Injury Risk Factors', assessment.injuryRiskFactors?.join(', ') ?? 'None'),
            _buildDetailRow('Unwitnessed Locations', assessment.unwitnessedSeizureLocations?.join(', ') ?? 'None'),
            _buildDetailRow('Seizure Triggers', assessment.seizureTriggers?.join(', ') ?? 'None'),
          ]),

          // Emergency Protocol
          _buildSection('Emergency Protocol', [
            _buildDetailRow('When to Call Ambulance', assessment.emergencyProtocol),
            _buildDetailRow('Rescue Medication', assessment.hasRescueMedication() 
                ? assessment.getRescueMedicationInfo() 
                : 'None'),
            _buildDetailRow('Rescue Administered', assessment.rescueMedicationAdministered ? 'Yes' : 'No'),
            _buildDetailRow('Response to Rescue', assessment.rescueMedicationResponse ?? 'Not specified'),
          ]),

          // Monitoring and Review
          _buildSection('Monitoring & Review', [
            _buildDetailRow('Monitoring Requirements', assessment.getMonitoringRequirements()),
            _buildDetailRow('Next Review Date', assessment.nextReviewDate?.toLocal().toIso8601String().split('T').first ?? 'Not set'),
            _buildDetailRow('Review Required', assessment.needsReview() ? 'Yes' : 'No'),
          ]),

          // Additional Information
          if (assessment.seizureFrequencyDetails != null && assessment.seizureFrequencyDetails!.isNotEmpty)
            _buildSection('Additional Details', [
              _buildDetailRow('Frequency Details', assessment.seizureFrequencyDetails!),
            ]),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'Not specified' || value == 'None' || value == 'No' 
                    ? Colors.grey 
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}