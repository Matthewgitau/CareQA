import 'package:flutter/material.dart';
import 'package:staff_app/models/financial_assessment.dart';
import 'package:staff_app/services/financial_service.dart';
import 'package:supabase/supabase.dart';

class FinancialRiskForm extends StatefulWidget {
  final FinancialAssessment? assessment;
  final String? serviceUserId;

  const FinancialRiskForm({
    Key? key,
    this.assessment,
    this.serviceUserId,
  }) : super(key: key);

  @override
  State<FinancialRiskForm> createState() => _FinancialRiskFormState();
}

class _FinancialRiskFormState extends State<FinancialRiskForm> {
  late final FinancialService _financialService;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  late DateTime _assessmentDate;
  late String _financialCapacity;
  late DateTime? _mentalCapacityAssessmentDate;
  late bool _appointeeDeputyAppointed;
  late String? _appointeeName;
  late String? _appointeeContact;
  late String _managingOwnFinances;
  late List<String> _benefitsClaimed;
  late double? _savingsAndAssets;
  late String _debtManagement;
  late String _billsPaid;
  late String _financialDecisionMaking;
  late bool _signsOfFinancialAbuse;
  late bool _unusualTransactions;
  late bool _missingMoney;
  late bool _pressureFromOthers;
  late bool _gamblingConcerns;
  late bool _scamsTargeted;
  late bool _financialSupportWorkerInvolved;
  late bool _safeguardingReferralMade;
  late String? _actionPlan;
  late DateTime? _reviewDate;
  late String _assessorName;
  late String? _assessorSignature;

  // Available options
  final List<String> _financialCapacities = ['full', 'partial', 'none'];
  final List<String> _managingOwnFinancesOptions = ['yes', 'no', 'partial'];
  final List<String> _debtManagements = ['none', 'manageable', 'struggling'];
  final List<String> _billsPaids = ['on_time', 'late', 'unsure'];
  final List<String> _financialDecisionMakings = ['independent', 'supported', 'unable'];
  final List<String> _benefitsOptions = ['PIP', 'AA', 'UC', 'State Pension'];
  
  @override
  void initState() {
    super.initState();
    _financialService = FinancialService(SupabaseClient('https://your-project.supabase.co', 'your-anon-key'));
    
    // Initialize with existing assessment or defaults
    if (widget.assessment != null) {
      final assessment = widget.assessment!;
      _assessmentDate = assessment.assessmentDate;
      _financialCapacity = assessment.financialCapacity;
      _mentalCapacityAssessmentDate = assessment.mentalCapacityAssessmentDate;
      _appointeeDeputyAppointed = assessment.appointeeDeputyAppointed;
      _appointeeName = assessment.appointeeName;
      _appointeeContact = assessment.appointeeContact;
      _managingOwnFinances = assessment.managingOwnFinances;
      _benefitsClaimed = assessment.benefitsClaimed;
      _savingsAndAssets = assessment.savingsAndAssets;
      _debtManagement = assessment.debtManagement;
      _billsPaid = assessment.billsPaid;
      _financialDecisionMaking = assessment.financialDecisionMaking;
      _signsOfFinancialAbuse = assessment.signsOfFinancialAbuse;
      _unusualTransactions = assessment.unusualTransactions;
      _missingMoney = assessment.missingMoney;
      _pressureFromOthers = assessment.pressureFromOthers;
      _gamblingConcerns = assessment.gamblingConcerns;
      _scamsTargeted = assessment.scamsTargeted;
      _financialSupportWorkerInvolved = assessment.financialSupportWorkerInvolved;
      _safeguardingReferralMade = assessment.safeguardingReferralMade;
      _actionPlan = assessment.actionPlan;
      _reviewDate = assessment.reviewDate;
      _assessorName = assessment.assessorName;
      _assessorSignature = assessment.assessorSignature;
    } else {
      _assessmentDate = DateTime.now();
      _financialCapacity = 'full';
      _mentalCapacityAssessmentDate = null;
      _appointeeDeputyAppointed = false;
      _appointeeName = null;
      _appointeeContact = null;
      _managingOwnFinances = 'yes';
      _benefitsClaimed = [];
      _savingsAndAssets = null;
      _debtManagement = 'none';
      _billsPaid = 'on_time';
      _financialDecisionMaking = 'independent';
      _signsOfFinancialAbuse = false;
      _unusualTransactions = false;
      _missingMoney = false;
      _pressureFromOthers = false;
      _gamblingConcerns = false;
      _scamsTargeted = false;
      _financialSupportWorkerInvolved = false;
      _safeguardingReferralMade = false;
      _actionPlan = null;
      _reviewDate = null;
      _assessorName = '';
      _assessorSignature = null;
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    try {
      final assessment = FinancialAssessment(
        id: widget.assessment?.id,
        serviceUserId: widget.serviceUserId,
        assessmentDate: _assessmentDate,
        financialCapacity: _financialCapacity,
        mentalCapacityAssessmentDate: _mentalCapacityAssessmentDate,
        appointeeDeputyAppointed: _appointeeDeputyAppointed,
        appointeeName: _appointeeName,
        appointeeContact: _appointeeContact,
        managingOwnFinances: _managingOwnFinances,
        benefitsClaimed: _benefitsClaimed,
        savingsAndAssets: _savingsAndAssets,
        debtManagement: _debtManagement,
        billsPaid: _billsPaid,
        financialDecisionMaking: _financialDecisionMaking,
        signsOfFinancialAbuse: _signsOfFinancialAbuse,
        unusualTransactions: _unusualTransactions,
        missingMoney: _missingMoney,
        pressureFromOthers: _pressureFromOthers,
        gamblingConcerns: _gamblingConcerns,
        scamsTargeted: _scamsTargeted,
        financialSupportWorkerInvolved: _financialSupportWorkerInvolved,
        safeguardingReferralMade: _safeguardingReferralMade,
        actionPlan: _actionPlan,
        reviewDate: _reviewDate,
        assessorName: _assessorName,
        assessorSignature: _assessorSignature,
        createdAt: widget.assessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.assessment != null) {
        await _financialService.updateAssessment(widget.assessment!.id!, assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Financial risk assessment updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _financialService.createAssessment(assessment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Financial risk assessment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isAssessmentDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isAssessmentDate ? _assessmentDate : (_reviewDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isAssessmentDate) {
          _assessmentDate = picked;
        } else {
          _reviewDate = picked;
        }
      });
    }
  }

  Future<void> _selectMentalCapacityDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _mentalCapacityAssessmentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _mentalCapacityAssessmentDate = picked;
      });
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

  String _getManagingOwnFinancesText(String option) {
    switch (option) {
      case 'yes': return 'Yes - Fully Independent';
      case 'no': return 'No - Requires Full Support';
      case 'partial': return 'Partial - Some Support Needed';
      default: return option;
    }
  }

  String _getDebtManagementText(String management) {
    switch (management) {
      case 'none': return 'No Debt';
      case 'manageable': return 'Manageable Debt';
      case 'struggling': return 'Struggling with Debt';
      default: return management;
    }
  }

  String _getBillsPaidText(String paid) {
    switch (paid) {
      case 'on_time': return 'On Time';
      case 'late': return 'Late';
      case 'unsure': return 'Unsure';
      default: return paid;
    }
  }

  String _getFinancialDecisionMakingText(String making) {
    switch (making) {
      case 'independent': return 'Independent';
      case 'supported': return 'Supported';
      case 'unable': return 'Unable';
      default: return making;
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

  bool get _needsSafeguardingReferral {
    return _signsOfFinancialAbuse || 
           _unusualTransactions || 
           _missingMoney || 
           _pressureFromOthers || 
           _scamsTargeted;
  }

  bool get _needsAppointeeReferral {
    return (_financialCapacity == 'none' || _managingOwnFinances == 'no') && 
           !_appointeeDeputyAppointed;
  }

  bool get _needsFinancialSupportWorker {
    return (_financialCapacity != 'full' || _signsOfFinancialAbuse) && 
           !_financialSupportWorkerInvolved;
  }

  String get _riskLevel {
    int riskScore = 0;
    
    // Base risk based on financial capacity
    switch (_financialCapacity) {
      case 'none': riskScore += 3; break;
      case 'partial': riskScore += 2; break;
      case 'full': riskScore += 0; break;
    }
    
    // Risk factors
    if (_signsOfFinancialAbuse) riskScore += 4;
    if (_unusualTransactions) riskScore += 3;
    if (_missingMoney) riskScore += 3;
    if (_pressureFromOthers) riskScore += 2;
    if (_gamblingConcerns) riskScore += 3;
    if (_scamsTargeted) riskScore += 3;
    
    // Debt and bill management
    switch (_debtManagement) {
      case 'struggling': riskScore += 3; break;
      case 'manageable': riskScore += 1; break;
      case 'none': riskScore += 0; break;
    }
    
    switch (_billsPaid) {
      case 'late': riskScore += 2; break;
      case 'unsure': riskScore += 1; break;
      case 'on_time': riskScore += 0; break;
    }
    
    // Determine risk level
    if (riskScore >= 10) return 'high';
    if (riskScore >= 5) return 'medium';
    return 'low';
  }

  String get _reviewFrequencyRecommendation {
    if (_signsOfFinancialAbuse || _financialCapacity == 'none' || _debtManagement == 'struggling') {
      return 'Monthly review recommended';
    }
    if (_financialCapacity == 'partial' || _billsPaid == 'late') {
      return 'Quarterly review recommended';
    }
    return 'Annual review recommended';
  }

  String get _supportRecommendations {
    List<String> recommendations = [];
    
    if (_financialCapacity == 'none' && !_appointeeDeputyAppointed) {
      recommendations.add('Appointee/Deputy required');
    }
    
    if (_managingOwnFinances == 'no' && !_appointeeDeputyAppointed) {
      recommendations.add('Financial management support needed');
    }
    
    if (_signsOfFinancialAbuse) {
      recommendations.add('Enhanced monitoring and safeguarding measures required');
    }
    
    if (_needsFinancialSupportWorker) {
      recommendations.add('Financial support worker involvement recommended');
    }
    
    if (recommendations.isEmpty) {
      return 'Continue current monitoring approach';
    }
    
    return recommendations.join('. ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment != null ? 'Edit Financial Risk Assessment' : 'New Financial Risk Assessment'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assessment Information
              const Text('Assessment Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Assessment Date
              Row(
                children: [
                  Expanded(
                    child: Text('Assessment Date: ${_assessmentDate.toIso8601String().split('T').first}'),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context, true),
                    child: const Text('Change Date'),
                  ),
                ],
              ),
              
              // Financial Capacity
              DropdownButtonFormField<String>(
                value: _financialCapacity,
                items: _financialCapacities.map((capacity) {
                  return DropdownMenuItem(
                    value: capacity,
                    child: Text(_getFinancialCapacityText(capacity)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _financialCapacity = value!),
                decoration: const InputDecoration(
                  labelText: 'Financial Capacity',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Mental Capacity Assessment Date
              Row(
                children: [
                  Expanded(
                    child: _mentalCapacityAssessmentDate != null 
                        ? Text('Mental Capacity Assessment: ${_mentalCapacityAssessmentDate!.toIso8601String().split('T').first}')
                        : const Text('No mental capacity assessment date set'),
                  ),
                  TextButton(
                    onPressed: _selectMentalCapacityDate,
                    child: const Text('Set Assessment Date'),
                  ),
                ],
              ),
              
              // Managing Own Finances
              DropdownButtonFormField<String>(
                value: _managingOwnFinances,
                items: _managingOwnFinancesOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(_getManagingOwnFinancesText(option)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _managingOwnFinances = value!),
                decoration: const InputDecoration(
                  labelText: 'Managing Own Finances',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Financial Decision Making
              DropdownButtonFormField<String>(
                value: _financialDecisionMaking,
                items: _financialDecisionMakings.map((making) {
                  return DropdownMenuItem(
                    value: making,
                    child: Text(_getFinancialDecisionMakingText(making)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _financialDecisionMaking = value!),
                decoration: const InputDecoration(
                  labelText: 'Financial Decision Making',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Appointee/Deputy Information
              const Text('Appointee/Deputy Information', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Appointee/Deputy Appointed
              Row(
                children: [
                  Checkbox(
                    value: _appointeeDeputyAppointed,
                    onChanged: (value) => setState(() => _appointeeDeputyAppointed = value!),
                  ),
                  const Text('Appointee/Deputy appointed'),
                ],
              ),
              
              // Appointee Name
              TextFormField(
                initialValue: _appointeeName,
                decoration: const InputDecoration(
                  labelText: 'Appointee Name',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _appointeeName = value,
                enabled: _appointeeDeputyAppointed,
              ),
              
              const SizedBox(height: 16),
              
              // Appointee Contact
              TextFormField(
                initialValue: _appointeeContact,
                decoration: const InputDecoration(
                  labelText: 'Appointee Contact',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _appointeeContact = value,
                enabled: _appointeeDeputyAppointed,
              ),
              
              const SizedBox(height: 24),

              // Benefits and Finances
              const Text('Benefits and Finances', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Benefits Claimed
              const Text('Benefits Claimed', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _benefitsOptions.map((benefit) {
                  return FilterChip(
                    label: Text(benefit),
                    selected: _benefitsClaimed.contains(benefit),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _benefitsClaimed.add(benefit);
                        } else {
                          _benefitsClaimed.remove(benefit);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Savings and Assets
              TextFormField(
                initialValue: _savingsAndAssets?.toString(),
                decoration: const InputDecoration(
                  labelText: 'Savings and Assets (£)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount in pounds',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSaved: (value) => _savingsAndAssets = value != null && value.isNotEmpty ? double.tryParse(value) : null,
              ),
              
              const SizedBox(height: 16),
              
              // Debt Management
              DropdownButtonFormField<String>(
                value: _debtManagement,
                items: _debtManagements.map((management) {
                  return DropdownMenuItem(
                    value: management,
                    child: Text(_getDebtManagementText(management)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _debtManagement = value!),
                decoration: const InputDecoration(
                  labelText: 'Debt Management',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bills Paid
              DropdownButtonFormField<String>(
                value: _billsPaid,
                items: _billsPaids.map((paid) {
                  return DropdownMenuItem(
                    value: paid,
                    child: Text(_getBillsPaidText(paid)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _billsPaid = value!),
                decoration: const InputDecoration(
                  labelText: 'Bills Paid',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Financial Abuse Indicators
              const Text('Financial Abuse Indicators', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Signs of Financial Abuse
              Row(
                children: [
                  Checkbox(
                    value: _signsOfFinancialAbuse,
                    onChanged: (value) => setState(() => _signsOfFinancialAbuse = value!),
                  ),
                  const Text('Signs of financial abuse detected'),
                ],
              ),
              
              // Unusual Transactions
              Row(
                children: [
                  Checkbox(
                    value: _unusualTransactions,
                    onChanged: (value) => setState(() => _unusualTransactions = value!),
                  ),
                  const Text('Unusual financial transactions'),
                ],
              ),
              
              // Missing Money
              Row(
                children: [
                  Checkbox(
                    value: _missingMoney,
                    onChanged: (value) => setState(() => _missingMoney = value!),
                  ),
                  const Text('Missing money reported'),
                ],
              ),
              
              // Pressure from Others
              Row(
                children: [
                  Checkbox(
                    value: _pressureFromOthers,
                    onChanged: (value) => setState(() => _pressureFromOthers = value!),
                  ),
                  const Text('Pressure from others regarding finances'),
                ],
              ),
              
              // Gambling Concerns
              Row(
                children: [
                  Checkbox(
                    value: _gamblingConcerns,
                    onChanged: (value) => setState(() => _gamblingConcerns = value!),
                  ),
                  const Text('Gambling concerns identified'),
                ],
              ),
              
              // Scams Targeted
              Row(
                children: [
                  Checkbox(
                    value: _scamsTargeted,
                    onChanged: (value) => setState(() => _scamsTargeted = value!),
                  ),
                  const Text('Potential scam targeting'),
                ],
              ),
              
              const SizedBox(height: 24),

              // Risk Assessment (Calculated)
              const Text('Risk Assessment (Calculated)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Risk Level
              Card(
                color: _getRiskLevelColor(_riskLevel).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Text(
                        '${_getRiskLevelEmoji(_riskLevel)} Risk Level: ${_getRiskLevelText(_riskLevel)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRiskLevelColor(_riskLevel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Safeguarding Referral Required
              if (_needsSafeguardingReferral)
                Card(
                  color: Colors.red.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: const [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          '⚠️ SAFEGUARDING REFERRAL REQUIRED',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Appointee Referral Required
              if (_needsAppointeeReferral)
                Card(
                  color: Colors.orange.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: const [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          '⚠️ APPOINTEE/DEPUTY REFERRAL REQUIRED',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Financial Support Worker Required
              if (_needsFinancialSupportWorker)
                Card(
                  color: Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: const [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'ℹ️ FINANCIAL SUPPORT WORKER RECOMMENDED',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Review Frequency Recommendation
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Recommendation: $_reviewFrequencyRecommendation',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Support Recommendations
              Card(
                color: Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Support: $_supportRecommendations',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Support and Interventions
              const Text('Support and Interventions', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Financial Support Worker Involved
              Row(
                children: [
                  Checkbox(
                    value: _financialSupportWorkerInvolved,
                    onChanged: (value) => setState(() => _financialSupportWorkerInvolved = value!),
                  ),
                  const Text('Financial support worker involved'),
                ],
              ),
              
              // Safeguarding Referral Made
              Row(
                children: [
                  Checkbox(
                    value: _safeguardingReferralMade,
                    onChanged: (value) => setState(() => _safeguardingReferralMade = value!),
                  ),
                  const Text('Safeguarding referral made'),
                ],
              ),
              
              const SizedBox(height: 24),

              // Documentation
              const Text('Documentation', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Action Plan
              const Text('Action Plan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _actionPlan,
                decoration: const InputDecoration(
                  labelText: 'Action Plan',
                  border: OutlineInputBorder(),
                  hintText: 'Describe the action plan for financial safety',
                ),
                maxLines: 4,
                onSaved: (value) => _actionPlan = value,
              ),
              
              const SizedBox(height: 16),

              // Review Date
              Row(
                children: [
                  Expanded(
                    child: _reviewDate != null 
                        ? Text('Review Date: ${_reviewDate!.toIso8601String().split('T').first}')
                        : const Text('No review date set'),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context, false),
                    child: const Text('Set Review Date'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Assessor Name
              TextFormField(
                initialValue: _assessorName,
                decoration: const InputDecoration(
                  labelText: 'Assessor Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter assessor name';
                  }
                  return null;
                },
                onSaved: (value) => _assessorName = value!,
              ),
              
              const SizedBox(height: 16),
              
              // Assessor Signature
              TextFormField(
                initialValue: _assessorSignature,
                decoration: const InputDecoration(
                  labelText: 'Assessor Signature',
                  border: OutlineInputBorder(),
                  hintText: 'Digital signature or initials',
                ),
                onSaved: (value) => _assessorSignature = value,
              ),
              
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(widget.assessment != null ? 'Update Assessment' : 'Create Assessment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}