import 'package:flutter/material.dart';
import 'package:staff_app/models/financial_assessment.dart';
import 'package:staff_app/services/financial_service.dart';
import 'package:staff_app/ui/risk/financial_risk_form.dart';
import 'package:supabase/supabase.dart';

class FinancialRiskScreen extends StatefulWidget {
  final String? serviceUserId;

  const FinancialRiskScreen({
    Key? key,
    this.serviceUserId,
  }) : super(key: key);

  @override
  State<FinancialRiskScreen> createState() => _FinancialRiskScreenState();
}

class _FinancialRiskScreenState extends State<FinancialRiskScreen> {
  late final FinancialService _financialService;
  late Future<List<FinancialAssessment>> _assessmentsFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _financialService = FinancialService(SupabaseClient('https://your-project.supabase.co', 'your-anon-key'));
    _refreshAssessments();
  }

  Future<void> _refreshAssessments() async {
    setState(() {
      _isLoading = true;
    });
    
    _assessmentsFuture = _financialService.getAssessments(
      serviceUserId: widget.serviceUserId,
    );
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createNewAssessment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinancialRiskForm(serviceUserId: widget.serviceUserId),
      ),
    );

    if (result == true) {
      _refreshAssessments();
    }
  }

  Future<void> _editAssessment(FinancialAssessment assessment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinancialRiskForm(
          assessment: assessment,
          serviceUserId: widget.serviceUserId,
        ),
      ),
    );

    if (result == true) {
      _refreshAssessments();
    }
  }

  Future<void> _deleteAssessment(String id) async {
    try {
      await _financialService.deleteAssessment(id);
      _refreshAssessments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getFinancialCapacityText(String capacity) {
    switch (capacity) {
      case 'full': return 'Full Capacity';
      case 'partial': return 'Partial Capacity';
      case 'none': return 'No Capacity';
      default: return capacity;
    }
  }

  String _getRiskLevelText(String riskLevel) {
    switch (riskLevel) {
      case 'high': return 'High Risk';
      case 'medium': return 'Medium Risk';
      case 'low': return 'Low Risk';
      default: return riskLevel;
    }
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getRiskLevelEmoji(String riskLevel) {
    switch (riskLevel) {
      case 'high': return '🔴';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  String _getRiskLevel(FinancialAssessment assessment) {
    int riskScore = 0;
    
    // Base risk based on financial capacity
    switch (assessment.financialCapacity) {
      case 'none': riskScore += 3; break;
      case 'partial': riskScore += 2; break;
      case 'full': riskScore += 0; break;
    }
    
    // Risk factors
    if (assessment.signsOfFinancialAbuse) riskScore += 4;
    if (assessment.unusualTransactions) riskScore += 3;
    if (assessment.missingMoney) riskScore += 3;
    if (assessment.pressureFromOthers) riskScore += 2;
    if (assessment.gamblingConcerns) riskScore += 3;
    if (assessment.scamsTargeted) riskScore += 3;
    
    // Debt and bill management
    switch (assessment.debtManagement) {
      case 'struggling': riskScore += 3; break;
      case 'manageable': riskScore += 1; break;
      case 'none': riskScore += 0; break;
    }
    
    switch (assessment.billsPaid) {
      case 'late': riskScore += 2; break;
      case 'unsure': riskScore += 1; break;
      case 'on_time': riskScore += 0; break;
    }
    
    // Determine risk level
    if (riskScore >= 10) return 'high';
    if (riskScore >= 5) return 'medium';
    return 'low';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Risk Assessments'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewAssessment,
            tooltip: 'Add New Assessment',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<FinancialAssessment>>(
              future: _assessmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading assessments: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
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
                        const Icon(Icons.assignment, color: Colors.grey, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'No financial risk assessments found',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _createNewAssessment,
                          child: const Text('Create First Assessment'),
                        ),
                      ],
                    ),
                  );
                } else {
                  final assessments = snapshot.data!;
                  
                  return RefreshIndicator(
                    onRefresh: _refreshAssessments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: assessments.length,
                      itemBuilder: (context, index) {
                        final assessment = assessments[index];
                        final riskLevel = _getRiskLevel(assessment);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () => _editAssessment(assessment),
                            borderRadius: BorderRadius.circular(8),
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
                                              'Assessment Date: ${assessment.assessmentDate.toIso8601String().split('T').first}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getFinancialCapacityText(assessment.financialCapacity),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Risk Level Indicator
                                      Column(
                                        children: [
                                          Text(
                                            '${_getRiskLevelEmoji(riskLevel)} ${_getRiskLevelText(riskLevel)}',
                                            style: TextStyle(
                                              color: _getRiskLevelColor(riskLevel),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),

                                  // Key Information
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Managing Finances: ${assessment.managingOwnFinances}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Debt Management: ${assessment.debtManagement}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Bills Paid: ${assessment.billsPaid}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Decision Making: ${assessment.financialDecisionMaking}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Financial Abuse Indicators
                                  if (assessment.signsOfFinancialAbuse ||
                                      assessment.unusualTransactions ||
                                      assessment.missingMoney ||
                                      assessment.pressureFromOthers ||
                                      assessment.gamblingConcerns ||
                                      assessment.scamsTargeted)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '⚠️ Financial Abuse Indicators Detected',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (assessment.signsOfFinancialAbuse)
                                              Chip(
                                                label: const Text('Signs of Abuse'),
                                                backgroundColor: Colors.red.withOpacity(0.1),
                                                labelStyle: const TextStyle(color: Colors.red),
                                              ),
                                            if (assessment.unusualTransactions)
                                              Chip(
                                                label: const Text('Unusual Transactions'),
                                                backgroundColor: Colors.orange.withOpacity(0.1),
                                                labelStyle: const TextStyle(color: Colors.orange),
                                              ),
                                            if (assessment.missingMoney)
                                              Chip(
                                                label: const Text('Missing Money'),
                                                backgroundColor: Colors.red.withOpacity(0.1),
                                                labelStyle: const TextStyle(color: Colors.red),
                                              ),
                                            if (assessment.pressureFromOthers)
                                              Chip(
                                                label: const Text('Pressure from Others'),
                                                backgroundColor: Colors.orange.withOpacity(0.1),
                                                labelStyle: const TextStyle(color: Colors.orange),
                                              ),
                                            if (assessment.gamblingConcerns)
                                              Chip(
                                                label: const Text('Gambling Concerns'),
                                                backgroundColor: Colors.red.withOpacity(0.1),
                                                labelStyle: const TextStyle(color: Colors.red),
                                              ),
                                            if (assessment.scamsTargeted)
                                              Chip(
                                                label: const Text('Scam Targeting'),
                                                backgroundColor: Colors.red.withOpacity(0.1),
                                                labelStyle: const TextStyle(color: Colors.red),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),

                                  // Appointee/Deputy Status
                                  if (assessment.appointeeDeputyAppointed)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Appointee/Deputy: ${assessment.appointeeName ?? 'Not specified'}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 8),

                                  // Actions
                                  Row(
                                    children: [
                                      if (!assessment.safeguardingReferralMade &&
                                          (assessment.signsOfFinancialAbuse ||
                                           assessment.unusualTransactions ||
                                           assessment.missingMoney ||
                                           assessment.pressureFromOthers ||
                                           assessment.scamsTargeted))
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _financialService.markSafeguardingReferral(assessment.id!);
                                              _refreshAssessments();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            child: const Text(
                                              'Mark Safeguarding Referral',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      
                                      const SizedBox(width: 8),

                                      if (!assessment.appointeeDeputyAppointed &&
                                          (assessment.financialCapacity == 'none' || 
                                           assessment.managingOwnFinances == 'no'))
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _financialService.markAppointeeAppointed(assessment.id!);
                                              _refreshAssessments();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            child: const Text(
                                              'Mark Appointee Appointed',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),

                                      const SizedBox(width: 8),

                                      if (!assessment.financialSupportWorkerInvolved &&
                                          (assessment.financialCapacity != 'full' || 
                                           assessment.signsOfFinancialAbuse))
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _financialService.markFinancialSupportWorkerInvolved(assessment.id!);
                                              _refreshAssessments();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            child: const Text(
                                              'Mark Support Worker Involved',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Footer
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Assessor: ${assessment.assessorName}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      if (assessment.reviewDate != null)
                                        Text(
                                          'Review: ${assessment.reviewDate!.toIso8601String().split('T').first}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
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
    );
  }
}