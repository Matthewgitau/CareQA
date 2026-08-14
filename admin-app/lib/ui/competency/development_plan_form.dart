import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/competency_framework.dart';
import '../../models/competency_assessment.dart';
import '../../services/competency_service.dart';

class DevelopmentPlanForm extends StatefulWidget {
  final String? planId;

  const DevelopmentPlanForm({super.key, this.planId});

  @override
  State<DevelopmentPlanForm> createState() => _DevelopmentPlanFormState();
}

class _DevelopmentPlanFormState extends State<DevelopmentPlanForm> {
  final _service = CompetencyService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoading = true;

  // Form fields
  String? _selectedStaffId;
  String _notes = '';
  DateTime? _reviewDate;
  List<DevelopmentGoal> _goals = [];

  // Data
  List<Map<String, dynamic>> _staffList = [];
  List<Competency> _competencies = [];
  DevelopmentPlan? _existingPlan;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load staff list
      _staffList = await _service.getAllStaff();
      
      // Load competencies
      _competencies = await _service.getCompetencyFramework();

      // Load existing plan if editing
      if (widget.planId != null) {
        // TODO: Load existing plan by ID
        // For now, we'll just create a new plan
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get organisation_id
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('organisation_id')
          .eq('id', user.id)
          .single();

      final plan = DevelopmentPlan(
        id: widget.planId ?? '',
        staffId: _selectedStaffId!,
        createdById: user.id,
        createdDate: DateTime.now(),
        reviewDate: _reviewDate,
        goals: _goals,
        notes: _notes,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _service.createDevelopmentPlan(plan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Development plan created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating development plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addGoal() {
    setState(() {
      _goals.add(DevelopmentGoal(
        competencyId: '',
        competencyName: '',
        targetLevel: 3,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        status: 'not_started',
      ));
    });
  }

  void _removeGoal(int index) {
    setState(() {
      _goals.removeAt(index);
    });
  }

  void _updateGoal(int index, DevelopmentGoal goal) {
    setState(() {
      _goals[index] = goal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planId != null ? 'Edit Development Plan' : 'New Development Plan'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Staff Selection
                  _buildSectionHeader('Staff Member'),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Staff *',
                      border: OutlineInputBorder(),
                    ),
                    items: _staffList.map((staff) {
                      return DropdownMenuItem<String>(
                        value: staff['id'],
                        child: Text(staff['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStaffId = value);
                    },
                    validator: (v) => v == null ? 'Please select a staff member' : null,
                  ),
                  const SizedBox(height: 24),

                  // Goals
                  _buildSectionHeader('Development Goals'),
                  ..._goals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final goal = entry.value;
                    return _buildGoalCard(index, goal);
                  }),
                  ElevatedButton.icon(
                    onPressed: _addGoal,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Goal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Review Date
                  _buildSectionHeader('Review Date'),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _reviewDate ?? DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _reviewDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Review Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _reviewDate != null
                            ? DateFormat('dd/MM/yyyy').format(_reviewDate!)
                            : 'Select date',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  _buildSectionHeader('Notes'),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes and Resources',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    onChanged: (v) => _notes = v,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(widget.planId != null ? 'Update Plan' : 'Create Plan',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }

  Widget _buildGoalCard(int index, DevelopmentGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goal ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeGoal(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Competency selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Competency *',
                border: OutlineInputBorder(),
              ),
              items: _competencies.map((comp) {
                return DropdownMenuItem<String>(
                  value: comp.id,
                  child: Text(comp.competencyName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final competency = _competencies.firstWhere((c) => c.id == value);
                  _updateGoal(index, DevelopmentGoal(
                    competencyId: value,
                    competencyName: competency.competencyName,
                    targetLevel: goal.targetLevel,
                    targetDate: goal.targetDate,
                    status: goal.status,
                    actionPlan: goal.actionPlan,
                    notes: goal.notes,
                  ));
                }
              },
              validator: (v) => v == null ? 'Please select a competency' : null,
            ),
            const SizedBox(height: 12),
            // Target Level
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Target Level *',
                border: OutlineInputBorder(),
              ),
              items: List.generate(5, (i) => i + 1).map((level) {
                return DropdownMenuItem<int>(
                  value: level,
                  child: Text('Level $level'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateGoal(index, DevelopmentGoal(
                    competencyId: goal.competencyId,
                    competencyName: goal.competencyName,
                    targetLevel: value,
                    targetDate: goal.targetDate,
                    status: goal.status,
                    actionPlan: goal.actionPlan,
                    notes: goal.notes,
                  ));
                }
              },
            ),
            const SizedBox(height: 12),
            // Target Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: goal.targetDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  _updateGoal(index, DevelopmentGoal(
                    competencyId: goal.competencyId,
                    competencyName: goal.competencyName,
                    targetLevel: goal.targetLevel,
                    targetDate: picked,
                    status: goal.status,
                    actionPlan: goal.actionPlan,
                    notes: goal.notes,
                  ));
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Target Date *',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(goal.targetDate)),
              ),
            ),
            const SizedBox(height: 12),
            // Status
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              value: goal.status,
              items: const [
                DropdownMenuItem(value: 'not_started', child: Text('Not Started')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _updateGoal(index, DevelopmentGoal(
                    competencyId: goal.competencyId,
                    competencyName: goal.competencyName,
                    targetLevel: goal.targetLevel,
                    targetDate: goal.targetDate,
                    status: value,
                    actionPlan: goal.actionPlan,
                    notes: goal.notes,
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}