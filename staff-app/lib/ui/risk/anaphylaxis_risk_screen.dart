import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/anaphylaxis_assessment.dart';
import 'package:staff_app/services/anaphylaxis_service.dart';
import 'package:staff_app/ui/risk/anaphylaxis_risk_form.dart';

class AnaphylaxisRiskScreen extends StatefulWidget {
  final String? serviceUserId;
  final String? serviceUserName;

  const AnaphylaxisRiskScreen({
    Key? key,
    this.serviceUserId,
    this.serviceUserName,
  }) : super(key: key);

  @override
  _AnaphylaxisRiskScreenState createState() => _AnaphylaxisRiskScreenState();
}

class _AnaphylaxisRiskScreenState extends State<AnaphylaxisRiskScreen> {
  final _anaphylaxisService = AnaphylaxisService(Supabase.instance.client);

  late List<AnaphylaxisAssessment> _assessments = [];
  late List<AnaphylaxisAssessment> _filteredAssessments = [];
  late bool _isLoading = false;
  late String _searchQuery = '';
  late String _filterStatus = 'all';
  late String _filterRiskLevel = 'all';
  late DateTime? _filterStartDate;
  late DateTime? _filterEndDate;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoading = true);
    try {
      List<AnaphylaxisAssessment> assessments;
      
      if (widget.serviceUserId != null) {
        // Load assessments for specific service user
        assessments = await _anaphylaxisService.getAssessmentsByServiceUser(widget.serviceUserId!);
      } else {
        // Load all assessments
        assessments = await _anaphylaxisService.getAllAssessments();
      }
      
      setState(() {
        _assessments = assessments;
        _filteredAssessments = assessments;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load assessments: ${e.toString()}')),
      );
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
          final serviceUserMatch = assessment.serviceUserId.toLowerCase().contains(searchLower);
          final assessorMatch = assessment.assessorId.toLowerCase().contains(searchLower);
          final allergensMatch = assessment.allergens.any((allergen) => allergen.toLowerCase().contains(searchLower));
          if (!serviceUserMatch && !assessorMatch && !allergensMatch) {
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

        // Date range filter
        if (_filterStartDate != null && assessment.createdAt.isBefore(_filterStartDate!)) {
          return false;
        }
        if (_filterEndDate != null && assessment.createdAt.isAfter(_filterEndDate!)) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _createNewAssessment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnaphylaxisRiskForm(
          serviceUserId: widget.serviceUserId,
          assessorId: Supabase.instance.client.auth.currentSession?.user.id,
        ),
      ),
    );

    if (result == true) {
      await _loadAssessments();
    }
  }

  Future<void> _editAssessment(AnaphylaxisAssessment assessment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnaphylaxisRiskForm(
          assessmentId: assessment.id,
          serviceUserId: assessment.serviceUserId,
          assessorId: assessment.assessorId,
        ),
      ),
    );

    if (result == true) {
      await _loadAssessments();
    }
  }

  Future<void> _deleteAssessment(AnaphylaxisAssessment assessment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Assessment'),
        content: Text('Are you sure you want to delete this anaphylaxis assessment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _anaphylaxisService.deleteAssessment(assessment.id!);
        await _loadAssessments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anaphylaxis assessment deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete assessment: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAssessment(AnaphylaxisAssessment assessment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submit Assessment'),
        content: Text('Are you sure you want to submit this anaphylaxis assessment? This will calculate the risk level and may trigger escalation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Submit', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _anaphylaxisService.submitAssessment(assessment.id!, Supabase.instance.client.auth.currentSession?.user.id);
        await _loadAssessments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anaphylaxis assessment submitted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit assessment: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by service user, assessor, or allergens...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterAssessments();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status Filter',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'escalated', child: Text('Escalated')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                      _filterAssessments();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterRiskLevel,
                    decoration: const InputDecoration(
                      labelText: 'Risk Level Filter',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('All Risk Levels')),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'extreme', child: Text('Extreme')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterRiskLevel = value!;
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
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _filterStartDate != null 
                          ? DateFormat('dd/MM/yyyy').format(_filterStartDate!)
                          : 'Start Date'
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _filterStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _filterStartDate = date;
                        });
                        _filterAssessments();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _filterEndDate != null 
                          ? DateFormat('dd/MM/yyyy').format(_filterEndDate!)
                          : 'End Date'
                    ),
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _filterEndDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _filterEndDate = date;
                        });
                        _filterAssessments();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filterStatus = 'all';
                        _filterRiskLevel = 'all';
                        _filterStartDate = null;
                        _filterEndDate = null;
                        _searchController.clear();
                      });
                      _filterAssessments();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                    ),
                    child: Text('Clear Filters', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filterStatus = 'all';
                        _filterRiskLevel = 'all';
                        _filterStartDate = null;
                        _filterEndDate = null;
                        _searchController.clear();
                      });
                      _filterAssessments();
                    },
                    child: Text('Reset Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(AnaphylaxisAssessment assessment) {
    final riskLevel = assessment.calculateRiskLevel();
    final autoinjectorStatus = assessment.getAutoinjectorStatus();
    final needsEscalation = assessment.needsEscalation();

    Color getRiskColor(String risk) {
      switch (risk) {
        case 'extreme':
          return Colors.red;
        case 'high':
          return Colors.orange;
        case 'medium':
          return Colors.yellow[700]!;
        case 'low':
        default:
          return Colors.green;
      }
    }

    Color getAutoinjectorColor(String status) {
      switch (status) {
        case 'expired':
          return Colors.red;
        case 'expiring_soon':
          return Colors.orange;
        case 'current':
        default:
          return Colors.green;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Allergens: ${assessment.allergens.join(', ')}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getRiskColor(riskLevel),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    riskLevel.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Previous Reaction: ${assessment.getPreviousReactionSeverityDisplay()}'),
            const SizedBox(height: 4),
            Text('Auto-injector: ${autoinjectorStatus.toUpperCase()}'),
            const SizedBox(height: 4),
            Text('Emergency Plan: ${assessment.emergencyActionPlan ? 'YES' : 'NO'}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Created: ${DateFormat('dd/MM/yyyy').format(assessment.createdAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                if (assessment.status != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: assessment.status == 'escalated' ? Colors.red[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      assessment.status!.toUpperCase(),
                      style: TextStyle(
                        color: assessment.status == 'escalated' ? Colors.red[800] : Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _editAssessment(assessment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                    ),
                    child: Text('View/Edit', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                if (assessment.status != 'completed')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitAssessment(assessment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text('Submit', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _deleteAssessment(assessment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            if (needsEscalation)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ This assessment requires immediate escalation due to high risk level.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceUserName != null 
            ? 'Anaphylaxis Risk - $widget.serviceUserName'
            : 'Anaphylaxis Risk Assessments'),
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _createNewAssessment,
            tooltip: 'Create New Assessment',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue[600]))
          : RefreshIndicator(
              onRefresh: _loadAssessments,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilters(),
                  const SizedBox(height: 16),
                  Text(
                    'Total Assessments: ${_filteredAssessments.length}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (_filteredAssessments.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No anaphylaxis assessments found. Create a new assessment to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  if (_filteredAssessments.isNotEmpty)
                    for (final assessment in _filteredAssessments)
                      Column(
                        children: [
                          _buildAssessmentCard(assessment),
                          const SizedBox(height: 16),
                        ],
                      ),
                ],
              ),
            ),
    );
  }
}