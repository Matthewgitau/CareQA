import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/incontinence_assessment.dart';
import 'package:admin_app/services/incontinence_service.dart';

class IncontinenceRiskForm extends StatefulWidget {
  final IncontinenceAssessment? assessment;
  final String? serviceUserId;

  const IncontinenceRiskForm({
    Key? key,
    this.assessment,
    this.serviceUserId,
  }) : super(key: key);

  @override
  State<IncontinenceRiskForm> createState() => _IncontinenceRiskFormState();
}

class _IncontinenceRiskFormState extends State<IncontinenceRiskForm> {
  final _formKey = GlobalKey<FormState>();
  late final IncontinenceService _incontinenceService;

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  // Form fields
  DateTime _assessmentDate = DateTime.now();
  String _assessorName = '';
  BladderContinenceStatus _bladderContinenceStatus = BladderContinenceStatus.continent;
  BowelContinenceStatus _bowelContinenceStatus = BowelContinenceStatus.continent;
  Frequency _frequency = Frequency.daily;
  List<String> _triggers = [];
  int? _fluidIntakeMl;
  bool _caffeineIntake = false;
  bool _alcoholIntake = false;
  String? _medications;
  bool _mobilityAffectingAccess = false;
  bool _cognitiveAwareness = true;
  ToiletAccessibility _toiletAccessibility = ToiletAccessibility.withinReach;
  List<String> _incontinenceProducts = [];
  SkinCondition _skinCondition = SkinCondition.intact;
  DateTime? _previousAssessmentDate;
  bool _referredToContinenceService = false;
  bool _bladderDiaryCompleted = false;
  bool _bowelDiaryCompleted = false;
  String? _actionPlan;
  DateTime? _reviewDate;

  bool _isLoading = false;

  final List<String> _triggerOptions = [
    'Coughing', 'Sneezing', 'Laughing', 'Urgency',
    'Activity', 'Lifting', 'Standing up', 'Walking',
  ];
  final List<String> _productOptions = [
    'Pads', 'Sheaths', 'Catheters', 'Urinals', 'Bedpans', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _incontinenceService = IncontinenceService(Supabase.instance.client);
    _loadServiceUsers();
    _initializeFromAssessment();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('service_users')
          .select('id, name')
          .order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
    }
  }

  void _initializeFromAssessment() {
    if (widget.assessment == null) {
      _assessorName = Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Current User';
      return;
    }
    final a = widget.assessment!;
    _selectedServiceUserId = a.serviceUserId;
    _assessmentDate = a.assessmentDate;
    _assessorName = a.assessorName;
    _bladderContinenceStatus = a.bladderContinenceStatus;
    _bowelContinenceStatus = a.bowelContinenceStatus;
    _frequency = a.frequency;
    _triggers = a.triggers;
    _fluidIntakeMl = a.fluidIntakeMl;
    _caffeineIntake = a.caffeineIntake;
    _alcoholIntake = a.alcoholIntake;
    _medications = a.medications;
    _mobilityAffectingAccess = a.mobilityAffectingAccess;
    _cognitiveAwareness = a.cognitiveAwareness;
    _toiletAccessibility = a.toiletAccessibility;
    _incontinenceProducts = a.incontinenceProducts;
    _skinCondition = a.skinCondition;
    _previousAssessmentDate = a.previousAssessmentDate;
    _referredToContinenceService = a.referredToContinenceService;
    _bladderDiaryCompleted = a.bladderDiaryCompleted;
    _bowelDiaryCompleted = a.bowelDiaryCompleted;
    _actionPlan = a.actionPlan;
    _reviewDate = a.reviewDate;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service user')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final assessment = IncontinenceAssessment(
        id: widget.assessment?.id,
        serviceUserId: _selectedServiceUserId,
        assessmentDate: _assessmentDate,
        assessorName: _assessorName,
        bladderContinenceStatus: _bladderContinenceStatus,
        bowelContinenceStatus: _bowelContinenceStatus,
        frequency: _frequency,
        triggers: _triggers,
        fluidIntakeMl: _fluidIntakeMl,
        caffeineIntake: _caffeineIntake,
        alcoholIntake: _alcoholIntake,
        medications: _medications,
        mobilityAffectingAccess: _mobilityAffectingAccess,
        cognitiveAwareness: _cognitiveAwareness,
        toiletAccessibility: _toiletAccessibility,
        incontinenceProducts: _incontinenceProducts,
        skinCondition: _skinCondition,
        previousAssessmentDate: _previousAssessmentDate,
        referredToContinenceService: _referredToContinenceService,
        bladderDiaryCompleted: _bladderDiaryCompleted,
        bowelDiaryCompleted: _bowelDiaryCompleted,
        actionPlan: _actionPlan,
        reviewDate: _reviewDate,
        createdAt: widget.assessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.assessment != null) {
        await _incontinenceService.updateAssessment(widget.assessment!.id!, assessment);
      } else {
        await _incontinenceService.createAssessment(assessment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assessment saved successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFilterChips(List<String> options, List<String> selectedOptions) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: options.map((option) {
        return FilterChip(
          label: Text(option),
          selected: selectedOptions.contains(option),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                selectedOptions.add(option);
              } else {
                selectedOptions.remove(option);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment != null ? 'Edit Incontinence Assessment' : 'New Incontinence Assessment'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service user selector
              if (_loadingUsers)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: _selectedServiceUserId,
                  decoration: const InputDecoration(
                    labelText: 'Service User *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: _serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String))).toList(),
                  onChanged: (v) => setState(() => _selectedServiceUserId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              const SizedBox(height: 16),

              const Text('Assessment Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text('Assessment Date: ${_assessmentDate.toIso8601String().split('T').first}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context, initialDate: _assessmentDate,
                        firstDate: DateTime(2020), lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _assessmentDate = picked);
                    },
                    child: const Text('Change Date'),
                  ),
                ],
              ),

              TextFormField(
                initialValue: _assessorName,
                decoration: const InputDecoration(labelText: 'Assessor Name', border: OutlineInputBorder()),
                onChanged: (v) => _assessorName = v,
                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              const Text('Bladder Continence Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<BladderContinenceStatus>(
                value: _bladderContinenceStatus,
                items: BladderContinenceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _bladderContinenceStatus = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              const Text('Bowel Continence Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<BowelContinenceStatus>(
                value: _bowelContinenceStatus,
                items: BowelContinenceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _bowelContinenceStatus = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              const Text('Frequency of Incontinence Episodes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Frequency>(
                value: _frequency,
                items: Frequency.values.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                onChanged: (v) => setState(() => _frequency = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              const Text('Triggers', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFilterChips(_triggerOptions, _triggers),
              const SizedBox(height: 24),

              TextFormField(
                initialValue: _fluidIntakeMl?.toString(),
                decoration: const InputDecoration(labelText: 'Fluid Intake (ml per day)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => _fluidIntakeMl = v.isEmpty ? null : int.tryParse(v),
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _caffeineIntake,
                onChanged: (v) => setState(() => _caffeineIntake = v!),
                title: const Text('Caffeine Intake'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _alcoholIntake,
                onChanged: (v) => setState(() => _alcoholIntake = v!),
                title: const Text('Alcohol Intake'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _medications,
                decoration: const InputDecoration(
                  labelText: 'Medications Affecting Continence',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (v) => _medications = v,
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _mobilityAffectingAccess,
                onChanged: (v) => setState(() => _mobilityAffectingAccess = v!),
                title: const Text('Mobility Affecting Access to Toilet'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _cognitiveAwareness,
                onChanged: (v) => setState(() => _cognitiveAwareness = v!),
                title: const Text('Cognitive Awareness of Need'),
              ),
              const SizedBox(height: 16),

              const Text('Toilet Accessibility', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ToiletAccessibility>(
                value: _toiletAccessibility,
                items: ToiletAccessibility.values.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                onChanged: (v) => setState(() => _toiletAccessibility = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              const Text('Incontinence Products Used', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFilterChips(_productOptions, _incontinenceProducts),
              const SizedBox(height: 24),

              const Text('Skin Condition', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<SkinCondition>(
                value: _skinCondition,
                items: SkinCondition.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _skinCondition = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _previousAssessmentDate != null
                        ? Text('Previous Assessment: ${_previousAssessmentDate!.toIso8601String().split('T').first}')
                        : const Text('No previous assessment'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _previousAssessmentDate ?? DateTime.now(),
                        firstDate: DateTime(2020), lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _previousAssessmentDate = picked);
                    },
                    child: const Text('Set Previous Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _referredToContinenceService,
                onChanged: (v) => setState(() => _referredToContinenceService = v!),
                title: const Text('Referred to Continence Service'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _bladderDiaryCompleted,
                onChanged: (v) => setState(() => _bladderDiaryCompleted = v!),
                title: const Text('Bladder Diary Completed'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _bowelDiaryCompleted,
                onChanged: (v) => setState(() => _bowelDiaryCompleted = v!),
                title: const Text('Bowel Diary Completed'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _actionPlan,
                decoration: const InputDecoration(
                  labelText: 'Action Plan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onChanged: (v) => _actionPlan = v,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _reviewDate != null
                        ? Text('Review Date: ${_reviewDate!.toIso8601String().split('T').first}')
                        : const Text('No review date set'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _reviewDate ?? DateTime.now(),
                        firstDate: DateTime(2020), lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _reviewDate = picked);
                    },
                    child: const Text('Set Review Date'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.assessment != null ? 'Update Assessment' : 'Create Assessment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}