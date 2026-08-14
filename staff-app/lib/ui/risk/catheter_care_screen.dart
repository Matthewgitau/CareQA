import 'package:flutter/material.dart';
import 'package:staff_app/models/catheter_care_assessment.dart';
import 'package:staff_app/services/catheter_care_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'catheter_care_form.dart';

class CatheterCareScreen extends StatefulWidget {
  final String serviceUserId;
  final String serviceUserName;

  const CatheterCareScreen({
    Key? key,
    required this.serviceUserId,
    required this.serviceUserName,
  }) : super(key: key);

  @override
  _CatheterCareScreenState createState() => _CatheterCareScreenState();
}

class _CatheterCareScreenState extends State<CatheterCareScreen> {
  final _catheterService = CatheterCareService(Supabase.instance.client);
  late Future<List<CatheterCareAssessment>> _assessmentsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _assessmentsFuture = _loadAssessments();
  }

  Future<List<CatheterCareAssessment>> _loadAssessments() async {
    try {
      return await _catheterService.getAssessmentsByServiceUser(widget.serviceUserId);
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
        builder: (context) => CatheterCareForm(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          onSaved: _refreshAssessments,
        ),
      ),
    );
  }

  Future<void> _editAssessment(CatheterCareAssessment assessment) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatheterCareForm(
          serviceUserId: widget.serviceUserId,
          serviceUserName: widget.serviceUserName,
          assessmentId: assessment.id,
          onSaved: _refreshAssessments,
        ),
      ),
    );
  }

  Future<void> _deleteAssessment(String assessmentId) async {
    try {
      setState(() => _isLoading = true);
      await _catheterService.deleteAssessment(assessmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessment deleted successfully')),
      );
      _refreshAssessments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete assessment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAssessmentDetails(CatheterCareAssessment assessment) async {
    await showDialog(
      context: context,
      builder: (context) => _AssessmentDetailsDialog(assessment: assessment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catheter Care - ${widget.serviceUserName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewAssessment,
            tooltip: 'Add New Assessment',
          ),
        ],
      ),
      body: FutureBuilder<List<CatheterCareAssessment>>(
        future: _assessmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshAssessments,
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
                  const Icon(Icons.assignment, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Catheter Care Assessments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Create your first assessment to get started.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createNewAssessment,
                    child: const Text('Create Assessment'),
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
                  return _buildAssessmentCard(assessment);
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

  Widget _buildAssessmentCard(CatheterCareAssessment assessment) {
    final riskLevel = assessment.getRiskLevel();
    final riskColor = _getRiskColor(riskLevel);
    final warnings = assessment.getWarnings();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showAssessmentDetails(assessment),
        onLongPress: () => _editAssessment(assessment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catheter Care Assessment',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${assessment.catheterType}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          riskLevel.toUpperCase(),
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${assessment.status}',
                        style: TextStyle(
                          color: assessment.status == 'completed' ? Colors.green : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Summary
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assessment.getSummary(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: warnings.map((warning) => Chip(
                    label: Text(warning, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    avatar: const Icon(Icons.warning, color: Colors.red, size: 14),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Next Change: ${assessment.getDaysUntilChange()}',
                      style: TextStyle(
                        color: assessment.isCatheterChangeUrgent() ? Colors.red : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editAssessment(assessment),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(assessment),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  void _showDeleteConfirmation(CatheterCareAssessment assessment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: const Text('Are you sure you want to delete this assessment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAssessment(assessment.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AssessmentDetailsDialog extends StatelessWidget {
  final CatheterCareAssessment assessment;

  const _AssessmentDetailsDialog({Key? key, required this.assessment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.assignment),
          const SizedBox(width: 8),
          Text('Catheter Care Assessment Details'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Basic Information
            _buildSection('Basic Information', [
              _buildDetail('Date', DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)),
              _buildDetail('Catheter Type', assessment.catheterType),
              _buildDetail('Catheter Size', assessment.catheterSize ?? 'Not specified'),
              _buildDetail('Balloon Volume', assessment.balloonVolume ?? 'Not specified'),
              _buildDetail('Insertion Date', assessment.insertionDate != null 
                ? DateFormat('dd/MM/yyyy').format(assessment.insertionDate!) 
                : 'Not specified'),
              _buildDetail('Next Change Date', assessment.nextChangeDate != null 
                ? DateFormat('dd/MM/yyyy').format(assessment.nextChangeDate!) 
                : 'Not specified'),
            ]),

            const SizedBox(height: 16),

            // Urine Monitoring
            _buildSection('Urine Monitoring', [
              _buildDetail('Morning Output', '${assessment.urineOutputMorning ?? 0} ml'),
              _buildDetail('Afternoon Output', '${assessment.urineOutputAfternoon ?? 0} ml'),
              _buildDetail('Night Output', '${assessment.urineOutputNight ?? 0} ml'),
              _buildDetail('Total Output', '${assessment.getUrineOutputTotal()} ml'),
              _buildDetail('Urine Appearance', assessment.urineAppearance ?? 'Not specified'),
              if (assessment.urineAppearanceNotes != null)
                _buildDetail('Appearance Notes', assessment.urineAppearanceNotes!),
            ]),

            const SizedBox(height: 16),

            // Infection Monitoring
            _buildSection('Infection Monitoring', [
              _buildDetail('Fever Present', assessment.feverPresent ? 'Yes' : 'No'),
              _buildDetail('Pain Present', assessment.painPresent ? 'Yes' : 'No'),
              _buildDetail('Urine Odour Present', assessment.urineOdourPresent ? 'Yes' : 'No'),
              if (assessment.infectionNotes != null)
                _buildDetail('Infection Notes', assessment.infectionNotes!),
            ]),

            const SizedBox(height: 16),

            // Skin Condition
            _buildSection('Skin Condition', [
              _buildDetail('Skin Condition', assessment.skinCondition ?? 'Not specified'),
              if (assessment.skinConditionNotes != null)
                _buildDetail('Skin Notes', assessment.skinConditionNotes!),
            ]),

            const SizedBox(height: 16),

            // Drainage System
            _buildSection('Drainage System', [
              _buildDetail('Bag Position Correct', assessment.bagPositionCorrect ? 'Yes' : 'No'),
              _buildDetail('Bag Secure', assessment.bagSecure ? 'Yes' : 'No'),
              _buildDetail('Tubing Secure', assessment.tubingSecure ? 'Yes' : 'No'),
              if (assessment.drainageNotes != null)
                _buildDetail('Drainage Notes', assessment.drainageNotes!),
            ]),

            const SizedBox(height: 16),

            // Patient Comfort
            _buildSection('Patient Comfort', [
              _buildDetail('Pain Level', '${assessment.painLevel ?? 'Not specified'}/10'),
              _buildDetail('Comfort Level', '${assessment.comfortLevel ?? 'Not specified'}/5'),
              if (assessment.patientComplaints != null)
                _buildDetail('Patient Complaints', assessment.patientComplaints!),
            ]),

            const SizedBox(height: 16),

            // Risk Assessment
            _buildSection('Risk Assessment', [
              _buildDetail('Infection Risk', assessment.infectionRisk ? 'Yes' : 'No'),
              _buildDetail('Blockage Risk', assessment.blockageRisk ? 'Yes' : 'No'),
              _buildDetail('Dislodgement Risk', assessment.dislodgementRisk ? 'Yes' : 'No'),
              _buildDetail('Skin Breakdown Risk', assessment.skinBreakdownRisk ? 'Yes' : 'No'),
              _buildDetail('Overall Risk Level', assessment.overallRiskLevel ?? 'Not specified'),
            ]),

            const SizedBox(height: 16),

            // Actions and Monitoring
            _buildSection('Actions and Monitoring', [
              _buildDetail('Actions Required', assessment.actionsRequired ? 'Yes' : 'No'),
              if (assessment.actionsDetails != null)
                _buildDetail('Actions Details', assessment.actionsDetails!),
              _buildDetail('Monitoring Frequency', assessment.monitoringFrequency ?? 'Not specified'),
              if (assessment.nextReviewDate != null)
                _buildDetail('Next Review Date', DateFormat('dd/MM/yyyy').format(assessment.nextReviewDate!)),
            ]),

            const SizedBox(height: 16),

            // Risk Factors
            if (assessment.getRiskFactors().isNotEmpty)
              _buildSection('Risk Factors', [
                ...assessment.getRiskFactors().map((factor) => _buildDetail('', factor)).toList(),
              ]),

            const SizedBox(height: 16),

            // Warnings
            if (assessment.getWarnings().isNotEmpty)
              _buildSection('Warnings', [
                ...assessment.getWarnings().map((warning) => _buildDetail('', warning)).toList(),
              ]),

            const SizedBox(height: 16),

            // Summary
            _buildSection('Summary', [
              _buildDetail('Risk Level', assessment.getRiskLevel().toUpperCase()),
              _buildDetail('Catheter Change', assessment.getDaysUntilChange()),
              _buildDetail('Monitoring Frequency', assessment.getMonitoringFrequency()),
            ]),
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}