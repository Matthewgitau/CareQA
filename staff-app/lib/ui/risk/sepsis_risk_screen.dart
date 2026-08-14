import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/sepsis_assessment.dart';
import 'package:staff_app/services/sepsis_service.dart';
import 'package:staff_app/ui/common/custom_app_bar.dart';
import 'package:staff_app/ui/common/custom_button.dart';
import 'package:staff_app/ui/common/custom_card.dart';
import 'package:staff_app/ui/common/custom_text_field.dart';
import 'package:staff_app/ui/common/section_header.dart';
import 'package:staff_app/utils/constants.dart';
import 'package:staff_app/utils/date_utils.dart';
import 'package:staff_app/utils/dialog_utils.dart';
import 'package:staff_app/utils/snackbar_utils.dart';

class SepsisRiskScreen extends StatefulWidget {
  final String serviceUserId;
  final String? assessorId;

  const SepsisRiskScreen({
    Key? key,
    required this.serviceUserId,
    this.assessorId,
  }) : super(key: key);

  @override
  _SepsisRiskScreenState createState() => _SepsisRiskScreenState();
}

class _SepsisRiskScreenState extends State<SepsisRiskScreen> {
  final _sepsisService = SepsisService(Supabase.instance.client);
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<SepsisAssessment> _assessments = [];
  List<SepsisAssessment> _filteredAssessments = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchText = '';
  DateTime? _selectedDate;
  SepsisRiskLevel? _selectedRiskLevel;
  ActionTaken? _selectedAction;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      _assessments = await _sepsisService.getAssessmentsByServiceUser(widget.serviceUserId);
      _filteredAssessments = _assessments;
    } catch (e) {
      SnackbarUtils.showSnackbar(context, 'Failed to load assessments: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterAssessments() {
    setState(() {
      _filteredAssessments = _assessments.where((assessment) {
        final matchesSearch = _searchText.isEmpty || 
            assessment.sepsisRiskLevel.toString().toLowerCase().contains(_searchText.toLowerCase()) ||
            assessment.actionTaken.toString().toLowerCase().contains(_searchText.toLowerCase()) ||
            assessment.infectionSource?.toLowerCase().contains(_searchText.toLowerCase()) == true;

        final matchesDate = _selectedDate == null || 
            DateUtils.isSameDay(assessment.assessmentDate, _selectedDate!);

        final matchesRiskLevel = _selectedRiskLevel == null || 
            assessment.sepsisRiskLevel == _selectedRiskLevel;

        final matchesAction = _selectedAction == null || 
            assessment.actionTaken == _selectedAction;

        return matchesSearch && matchesDate && matchesRiskLevel && matchesAction;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchText = '';
      _searchController.clear();
      _selectedDate = null;
      _selectedRiskLevel = null;
      _selectedAction = null;
      _filteredAssessments = _assessments;
    });
  }

  Future<void> _createNewAssessment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SepsisRiskForm(
          serviceUserId: widget.serviceUserId,
          assessorId: widget.assessorId,
        ),
      ),
    );

    if (result == true) {
      _loadAssessments();
    }
  }

  Future<void> _viewAssessment(SepsisAssessment assessment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SepsisRiskForm(
          assessmentId: assessment.id,
          serviceUserId: widget.serviceUserId,
          assessorId: widget.assessorId,
        ),
      ),
    );

    if (result == true) {
      _loadAssessments();
    }
  }

  Future<void> _deleteAssessment(SepsisAssessment assessment) async {
    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      'Delete Assessment',
      'Are you sure you want to delete this sepsis assessment?',
    );

    if (confirmed) {
      try {
        await _sepsisService.deleteAssessment(assessment.id!);
        SnackbarUtils.showSuccessSnackbar(context, 'Assessment deleted successfully!');
        _loadAssessments();
      } catch (e) {
        SnackbarUtils.showSnackbar(context, 'Failed to delete assessment: ${e.toString()}');
      }
    }
  }

  Widget _buildFilterSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Filter Assessments'),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _searchController,
            labelText: 'Search by risk level, action, or infection source',
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
              _filterAssessments();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  initialValue: _selectedDate != null 
                      ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                      : 'Select Date',
                  decoration: const InputDecoration(
                    labelText: 'Filter by Date',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 90)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                      _filterAssessments();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<SepsisRiskLevel>(
                  value: _selectedRiskLevel,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Risk Level',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Risk Levels')),
                    ...SepsisRiskLevel.values.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(_getRiskLevelDisplay(level)),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRiskLevel = value;
                    });
                    _filterAssessments();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ActionTaken>(
                  value: _selectedAction,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Action',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Actions')),
                    ...ActionTaken.values.map((action) {
                      return DropdownMenuItem(
                        value: action,
                        child: Text(_getActionDisplay(action)),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAction = value;
                    });
                    _filterAssessments();
                  },
                ),
              ),
              const SizedBox(width: 16),
              CustomButton(
                onPressed: _clearFilters,
                text: 'Clear Filters',
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            const Icon(Icons.medical_services, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchText.isNotEmpty || _selectedDate != null || _selectedRiskLevel != null || _selectedAction != null
                  ? 'No assessments found matching your filters'
                  : 'No sepsis assessments found',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_searchText.isNotEmpty || _selectedDate != null || _selectedRiskLevel != null || _selectedAction != null)
              CustomButton(
                onPressed: _clearFilters,
                text: 'Clear Filters',
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredAssessments.length,
      itemBuilder: (context, index) {
        final assessment = _filteredAssessments[index];
        return _buildAssessmentCard(assessment);
      },
    );
  }

  Widget _buildAssessmentCard(SepsisAssessment assessment) {
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
                      'Assessment Date: ${DateFormat('dd/MM/yyyy').format(assessment.assessmentDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Time: ${assessment.assessmentTime.format(context)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRiskLevelChip(assessment.sepsisRiskLevel),
                        const SizedBox(width: 8),
                        _buildActionChip(assessment.actionTaken),
                        const SizedBox(width: 8),
                        Text(
                          'NEWS2: ${assessment.news2Score}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getNews2Color(assessment.news2Score),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _viewAssessment(assessment),
                    tooltip: 'View Assessment',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteAssessment(assessment),
                    tooltip: 'Delete Assessment',
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (assessment.infectionSource != null && assessment.infectionSource!.isNotEmpty)
            Text(
              'Infection Source: ${assessment.infectionSource}',
              style: const TextStyle(color: Colors.blue),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vitals: T${assessment.temperature}°C, HR${assessment.heartRate}, RR${assessment.respiratoryRate}, SpO₂${assessment.oxygenSaturation}%, BP${assessment.systolicBp}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          if (assessment.signsOfInfection.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Signs of Infection: ${assessment.signsOfInfection.join(', ')}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
          if (assessment.referralToHospital)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Referral to Hospital: ${assessment.referralTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(assessment.referralTime!) : 'Time not recorded'}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
                if (assessment.hospitalOutcome != null)
                  Text(
                    'Hospital Outcome: ${assessment.hospitalOutcome}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRiskLevelChip(SepsisRiskLevel riskLevel) {
    Color color;
    String label;

    switch (riskLevel) {
      case SepsisRiskLevel.low:
        color = Colors.green;
        label = 'Low Risk';
        break;
      case SepsisRiskLevel.medium:
        color = Colors.yellow;
        label = 'Medium Risk';
        break;
      case SepsisRiskLevel.high:
        color = Colors.orange;
        label = 'High Risk';
        break;
      case SepsisRiskLevel.critical:
        color = Colors.red;
        label = 'Critical Risk';
        break;
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  Widget _buildActionChip(ActionTaken action) {
    Color color;
    String label;

    switch (action) {
      case ActionTaken.monitor:
        color = Colors.blue;
        label = 'Monitor';
        break;
      case ActionTaken.escalate:
        color = Colors.orange;
        label = 'Escalate';
        break;
      case ActionTaken.call999:
        color = Colors.red;
        label = 'Call 999';
        break;
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  Color _getNews2Color(int score) {
    if (score >= 7) return Colors.red;
    if (score >= 5) return Colors.orange;
    if (score >= 3) return Colors.yellow;
    return Colors.green;
  }

  String _getRiskLevelDisplay(SepsisRiskLevel level) {
    switch (level) {
      case SepsisRiskLevel.low: return 'Low Risk';
      case SepsisRiskLevel.medium: return 'Medium Risk';
      case SepsisRiskLevel.high: return 'High Risk';
      case SepsisRiskLevel.critical: return 'Critical Risk';
    }
  }

  String _getActionDisplay(ActionTaken action) {
    switch (action) {
      case ActionTaken.monitor: return 'Monitor';
      case ActionTaken.escalate: return 'Escalate';
      case ActionTaken.call999: return 'Call 999';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sepsis Risk Assessments',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewAssessment,
            tooltip: 'Create New Assessment',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildFilterSection(),
            const SizedBox(height: 16),
            _buildAssessmentList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}