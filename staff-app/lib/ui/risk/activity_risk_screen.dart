import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/activity_risk_assessment.dart';
import 'package:staff_app/services/activity_risk_service.dart';
import 'package:staff_app/ui/common/custom_app_bar.dart';
import 'package:staff_app/ui/common/custom_button.dart';
import 'package:staff_app/ui/common/custom_card.dart';
import 'package:staff_app/ui/common/custom_search_field.dart';
import 'package:staff_app/ui/common/section_header.dart';
import 'package:staff_app/utils/constants.dart';
import 'package:staff_app/utils/date_utils.dart';
import 'package:staff_app/utils/dialog_utils.dart';
import 'package:staff_app/utils/snackbar_utils.dart';

class ActivityRiskScreen extends StatefulWidget {
  final String? serviceUserId;

  const ActivityRiskScreen({
    Key? key,
    this.serviceUserId,
  }) : super(key: key);

  @override
  _ActivityRiskScreenState createState() => _ActivityRiskScreenState();
}

class _ActivityRiskScreenState extends State<ActivityRiskScreen> {
  final _activityRiskService = ActivityRiskService(Supabase.instance.client);
  final _searchController = TextEditingController();

  List<ActivityRiskAssessment> _assessments = [];
  List<ActivityRiskAssessment> _filteredAssessments = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterRiskLevel = 'all';
  String _filterActivityType = 'all';

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      List<ActivityRiskAssessment> assessments;
      
      if (widget.serviceUserId != null) {
        assessments = await _activityRiskService.getAssessmentsByServiceUser(widget.serviceUserId!);
      } else {
        assessments = await _activityRiskService.getAllAssessments();
      }

      setState(() {
        _assessments = assessments;
        _filteredAssessments = assessments;
      });
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to load assessments: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterAssessments() {
    setState(() {
      _filteredAssessments = _assessments.where((assessment) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final activityType = assessment.getActivityTypeDisplay().toLowerCase();
          final assessorName = assessment.assessorId.toLowerCase();
          
          if (!activityType.contains(searchLower) && !assessorName.contains(searchLower)) {
            return false;
          }
        }

        // Status filter
        if (_filterStatus != 'all' && assessment.status != _filterStatus) {
          return false;
        }

        // Risk level filter
        if (_filterRiskLevel != 'all' && assessment.riskLevel != _filterRiskLevel) {
          return false;
        }

        // Activity type filter
        if (_filterActivityType != 'all' && 
            _activityTypeToString(assessment.activityType) != _filterActivityType) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterAssessments();
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _filterStatus = value ?? 'all';
    });
    _filterAssessments();
  }

  void _onRiskLevelFilterChanged(String? value) {
    setState(() {
      _filterRiskLevel = value ?? 'all';
    });
    _filterAssessments();
  }

  void _onActivityTypeFilterChanged(String? value) {
    setState(() {
      _filterActivityType = value ?? 'all';
    });
    _filterAssessments();
  }

  void _createNewAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityRiskForm(
          serviceUserId: widget.serviceUserId,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadAssessments();
      }
    });
  }

  void _viewAssessment(ActivityRiskAssessment assessment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityRiskForm(
          assessmentId: assessment.id,
          serviceUserId: widget.serviceUserId,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadAssessments();
      }
    });
  }

  void _deleteAssessment(ActivityRiskAssessment assessment) async {
    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      'Delete Assessment',
      'Are you sure you want to delete this activity risk assessment?',
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _activityRiskService.deleteAssessment(assessment.id!);
        SnackbarUtils.showSuccessSnackbar(context, 'Assessment deleted successfully!');
        _loadAssessments();
      } catch (e) {
        SnackbarUtils.showSnackbar(context, 'Failed to delete assessment: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitAssessment(ActivityRiskAssessment assessment) async {
    setState(() => _isLoading = true);
    try {
      final updatedAssessment = await _activityRiskService.submitAssessment(
        assessment.id!,
        Supabase.instance.client.auth.currentSession?.user.id ?? '',
      );
      SnackbarUtils.showSuccessSnackbar(context, 'Assessment submitted successfully!');
      _loadAssessments();
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to submit assessment: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _escalateAssessment(ActivityRiskAssessment assessment) async {
    setState(() => _isLoading = true);
    try {
      final updatedAssessment = await _activityRiskService.escalateAssessment(
        assessment.id!,
        Supabase.instance.client.auth.currentSession?.user.id ?? '',
      );
      SnackbarUtils.showSuccessSnackbar(context, 'Assessment escalated successfully!');
      _loadAssessments();
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to escalate assessment: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _completeAssessment(ActivityRiskAssessment assessment) async {
    setState(() => _isLoading = true);
    try {
      final updatedAssessment = await _activityRiskService.completeAssessment(
        assessment.id!,
        Supabase.instance.client.auth.currentSession?.user.id ?? '',
      );
      SnackbarUtils.showSuccessSnackbar(context, 'Assessment completed successfully!');
      _loadAssessments();
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to complete assessment: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFilters() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Filters'),
          const SizedBox(height: 16),
          CustomSearchField(
            controller: _searchController,
            hintText: 'Search by activity type or assessor...',
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                    const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    const DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                    const DropdownMenuItem(value: 'escalated', child: Text('Escalated')),
                    const DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: _onStatusFilterChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterRiskLevel,
                  decoration: const InputDecoration(
                    labelText: 'Risk Level',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Risk Levels')),
                    const DropdownMenuItem(value: 'low', child: Text('Low')),
                    const DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    const DropdownMenuItem(value: 'high', child: Text('High')),
                    const DropdownMenuItem(value: 'extreme', child: Text('Extreme')),
                  ],
                  onChanged: _onRiskLevelFilterChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterActivityType,
                  decoration: const InputDecoration(
                    labelText: 'Activity Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Activity Types')),
                    const DropdownMenuItem(value: 'bathing', child: Text('Bathing')),
                    const DropdownMenuItem(value: 'dressing', child: Text('Dressing')),
                    const DropdownMenuItem(value: 'toileting', child: Text('Toileting')),
                    const DropdownMenuItem(value: 'mobility', child: Text('Mobility')),
                    const DropdownMenuItem(value: 'eating', child: Text('Eating')),
                    const DropdownMenuItem(value: 'drinking', child: Text('Drinking')),
                    const DropdownMenuItem(value: 'cooking', child: Text('Cooking')),
                    const DropdownMenuItem(value: 'cleaning', child: Text('Cleaning')),
                    const DropdownMenuItem(value: 'shopping', child: Text('Shopping')),
                    const DropdownMenuItem(value: 'appointments', child: Text('Appointments')),
                    const DropdownMenuItem(value: 'visits', child: Text('Visits')),
                    const DropdownMenuItem(value: 'outings', child: Text('Outings')),
                    const DropdownMenuItem(value: 'hobbies', child: Text('Hobbies')),
                    const DropdownMenuItem(value: 'exercise', child: Text('Exercise')),
                    const DropdownMenuItem(value: 'personal_care', child: Text('Personal Care')),
                  ],
                  onChanged: _onActivityTypeFilterChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _filterStatus = 'all';
                      _filterRiskLevel = 'all';
                      _filterActivityType = 'all';
                      _filteredAssessments = _assessments;
                    });
                  },
                  text: 'Clear Filters',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredAssessments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterStatus != 'all' || _filterRiskLevel != 'all' || _filterActivityType != 'all'
                ? 'No assessments found matching your filters'
                : 'No activity risk assessments found',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isNotEmpty || _filterStatus != 'all' || _filterRiskLevel != 'all' || _filterActivityType != 'all')
              CustomButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _filterStatus = 'all';
                    _filterRiskLevel = 'all';
                    _filterActivityType = 'all';
                    _filteredAssessments = _assessments;
                  });
                },
                text: 'Clear Filters',
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredAssessments.length,
      itemBuilder: (context, index) {
        final assessment = _filteredAssessments[index];
        return _buildAssessmentCard(assessment);
      },
    );
  }

  Widget _buildAssessmentCard(ActivityRiskAssessment assessment) {
    final summary = assessment.getSummary();
    final isHighRisk = assessment.riskLevel == 'high' || assessment.riskLevel == 'extreme';
    final isDueForReview = assessment.reviewDate.isBefore(DateTime.now());

    return CustomCard(
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
                      summary['activity_type'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Frequency: ${summary['frequency']} | Support: ${summary['support_level']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assessor: ${assessment.assessorId}',
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
                      color: _getRiskColor(assessment.riskLevel),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      assessment.riskLevel.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(assessment.reviewDate),
                    style: TextStyle(
                      color: isDueForReview ? Colors.red : Colors.grey,
                      fontWeight: isDueForReview ? FontWeight.bold : FontWeight.normal,
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
                child: Row(
                  children: [
                    _buildStatChip('Equipment', summary['equipment_count'] as int),
                    const SizedBox(width: 8),
                    _buildStatChip('Risks', summary['risk_count'] as int),
                    const SizedBox(width: 8),
                    _buildStatChip('Controls', summary['control_count'] as int),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  assessment.emergencyProcedures.isNotEmpty 
                      ? assessment.emergencyProcedures 
                      : 'No emergency procedures specified',
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CustomButton(
                onPressed: () => _viewAssessment(assessment),
                text: 'View/Edit',
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              if (assessment.status == 'pending')
                CustomButton(
                  onPressed: () => _submitAssessment(assessment),
                  text: 'Submit',
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.green,
                ),
              if (assessment.status == 'pending' && isHighRisk)
                CustomButton(
                  onPressed: () => _escalateAssessment(assessment),
                  text: 'Escalate',
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange,
                ),
              if (assessment.status == 'submitted' || assessment.status == 'escalated')
                CustomButton(
                  onPressed: () => _completeAssessment(assessment),
                  text: 'Complete',
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.purple,
                ),
              const SizedBox(width: 8),
              CustomButton(
                onPressed: () => _deleteAssessment(assessment),
                text: 'Delete',
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: Colors.grey[200],
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'low': return Colors.green;
      case 'medium': return Colors.yellow[700]!;
      case 'high': return Colors.orange;
      case 'extreme': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.bathing: return 'bathing';
      case ActivityType.dressing: return 'dressing';
      case ActivityType.toileting: return 'toileting';
      case ActivityType.mobility: return 'mobility';
      case ActivityType.eating: return 'eating';
      case ActivityType.drinking: return 'drinking';
      case ActivityType.cooking: return 'cooking';
      case ActivityType.cleaning: return 'cleaning';
      case ActivityType.shopping: return 'shopping';
      case ActivityType.appointments: return 'appointments';
      case ActivityType.visits: return 'visits';
      case ActivityType.outings: return 'outings';
      case ActivityType.hobbies: return 'hobbies';
      case ActivityType.exercise: return 'exercise';
      case ActivityType.personalCare: return 'personal_care';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.serviceUserId != null ? 'Activity Risk Assessments' : 'All Activity Risk Assessments',
        showBackButton: true,
        actions: [
          CustomButton(
            onPressed: _createNewAssessment,
            text: 'New Assessment',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildAssessmentList(),
            ),
          ],
        ),
      ),
    );
  }
}