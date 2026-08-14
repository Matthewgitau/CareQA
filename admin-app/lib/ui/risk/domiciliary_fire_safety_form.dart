import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/domiciliary_fire_safety_assessment.dart';
import '../../services/domiciliary_fire_safety_service.dart';

class DomiciliaryFireSafetyForm extends StatefulWidget {
  final DomiciliaryFireSafetyAssessment? assessment;
  final String? serviceUserId;

  const DomiciliaryFireSafetyForm({
    Key? key,
    this.assessment,
    this.serviceUserId,
  }) : super(key: key);

  @override
  State<DomiciliaryFireSafetyForm> createState() => _DomiciliaryFireSafetyFormState();
}

class _DomiciliaryFireSafetyFormState extends State<DomiciliaryFireSafetyForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = DomiciliaryFireSafetyService(Supabase.instance.client);
  final _supabase = Supabase.instance.client;

  late DomiciliaryFireSafetyAssessment _assessment;
  bool _saving = false;
  bool _loadingUsers = true;
  String? _selectedServiceUserId;
  List<Map<String, dynamic>> _serviceUsers = [];
  final _assessorNameController = TextEditingController();
  final _actionsController = TextEditingController();
  final _signatureController = TextEditingController();
  DateTime _assessmentDate = DateTime.now();
  bool _signatureConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    _initialize();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final response = await _supabase.from('service_users').select('id, name').order('name');
      setState(() {
        _serviceUsers = List<Map<String, dynamic>>.from(response as List);
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  void _initialize() {
    if (widget.assessment != null) {
      _assessment = widget.assessment!;
    } else {
      _assessment = DomiciliaryFireSafetyAssessment(
        assessmentDate: DateTime.now(),
        status: 'draft',
      );
    }
    _selectedServiceUserId = _assessment.serviceUserId;
    _assessmentDate = _assessment.assessmentDate ?? DateTime.now();
    _assessorNameController.text = _assessment.assessorName ?? '';
    _actionsController.text = _assessment.recommendedActions ?? '';

    final user = _supabase.auth.currentUser;
    if (user != null && _assessment.assessorName == null) {
      _assessorNameController.text = user.email?.split('@').first ?? user.id ?? '';
    }
  }

  @override
  void dispose() {
    _assessorNameController.dispose();
    _actionsController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  String get _riskLevel => _assessment.calculatedRiskLevel;

  Color get _riskColor {
    switch (_riskLevel) {
      case 'high': return const Color(0xFFF44336);
      case 'medium': return const Color(0xFFFF9800);
      default: return const Color(0xFF4CAF50);
    }
  }

  int get _noCount => _assessment.noCount;
  bool get _hasDangerousCondition => _assessment.hasDangerousCondition;

  void _updateField(String field, String value) {
    setState(() {
      switch (field) {
        case 'hasElectricalEquipment': _assessment = _assessment.copyWith(hasElectricalEquipment: DomiciliaryFireSafetyAssessment.stringToBool(value)); break;
        case 'patTestVisible': _assessment = _assessment.copyWith(patTestVisible: DomiciliaryFireSafetyAssessment.stringToBool(value)); break;
        case 'operatesEquipmentSelf': _assessment = _assessment.copyWith(operatesEquipmentSelf: value); break;
        case 'visibleDamage': _assessment = _assessment.copyWith(visibleDamage: DomiciliaryFireSafetyAssessment.stringToBool(value)); break;
        case 'workingSmokeAlarms': _assessment = _assessment.copyWith(workingSmokeAlarms: DomiciliaryFireSafetyAssessment.stringToBool(value)); break;
        case 'smokes': _assessment = _assessment.copyWith(smokes: DomiciliaryFireSafetyAssessment.stringToBool(value)); break;
        case 'escapeRoutesClear': _assessment = _assessment.copyWith(escapeRoutesClear: value); break;
        case 'hasFireBlanketOrExtinguisher': _assessment = _assessment.copyWith(hasFireBlanketOrExtinguisher: DomiciliaryFireSafetyAssessment.stringToBool(value)); break;
        case 'canExitIndependently': _assessment = _assessment.copyWith(canExitIndependently: value); break;
        case 'hasCapacityToUnderstand': _assessment = _assessment.copyWith(hasCapacityToUnderstand: value); break;
        case 'nameAddressVisible': _assessment = _assessment.copyWith(nameAddressVisible: DomiciliaryFireSafetyAssessment.stringToBool(value)); break;
      }
    });
  }

  Widget _buildQuestion(String question, String field, List<String> options) {
    final value = switch (field) {
      'hasElectricalEquipment' => DomiciliaryFireSafetyAssessment.boolToString(_assessment.hasElectricalEquipment),
      'patTestVisible' => DomiciliaryFireSafetyAssessment.boolToString(_assessment.patTestVisible),
      'operatesEquipmentSelf' => _assessment.operatesEquipmentSelf,
      'visibleDamage' => DomiciliaryFireSafetyAssessment.boolToString(_assessment.visibleDamage),
      'workingSmokeAlarms' => DomiciliaryFireSafetyAssessment.boolToString(_assessment.workingSmokeAlarms),
      'smokes' => DomiciliaryFireSafetyAssessment.boolToString(_assessment.smokes),
      'escapeRoutesClear' => _assessment.escapeRoutesClear,
      'hasFireBlanketOrExtinguisher' => DomiciliaryFireSafetyAssessment.boolToString(_assessment.hasFireBlanketOrExtinguisher),
      'canExitIndependently' => _assessment.canExitIndependently,
      'hasCapacityToUnderstand' => _assessment.hasCapacityToUnderstand,
      'nameAddressVisible' => DomiciliaryFireSafetyAssessment.boolToString(_assessment.nameAddressVisible),
      _ => null,
    };
    final isDanger = field == 'visibleDamage' || field == 'workingSmokeAlarms';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isDanger)
                  Icon(Icons.warning_amber_rounded, size: 16, color: value == 'no' || value == 'yes' ? const Color(0xFFF44336) : Colors.grey[400]),
                if (isDanger) const SizedBox(width: 6),
                Expanded(
                  child: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: options.map((opt) => ChoiceChip(
                label: Text(opt, style: const TextStyle(fontSize: 12)),
                selected: value == opt.toLowerCase(),
                selectedColor: opt == 'No' ? const Color(0xFFF44336).withOpacity(0.2) : const Color(0xFF1565C0).withOpacity(0.15),
                onSelected: (_) => _updateField(field, opt.toLowerCase()),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service user')));
      return;
    }
    if (_assessorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the assessor name')));
      return;
    }

    setState(() => _saving = true);
    try {
      _assessment = _assessment.copyWith(
        serviceUserId: _selectedServiceUserId,
        assessorName: _assessorNameController.text.trim(),
        assessmentDate: _assessmentDate,
        recommendedActions: _actionsController.text.trim().isEmpty ? null : _actionsController.text.trim(),
        riskLevel: _riskLevel,
        signature: _signatureConfirmed ? _signatureController.text.trim() : null,
        status: _signatureConfirmed ? 'completed' : 'draft',
      );

      if (widget.assessment?.id != null) {
        await _service.updateAssessment(widget.assessment!.id!, _assessment);
      } else {
        await _service.createAssessment(_assessment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fire safety assessment saved')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domiciliary Fire Safety'),
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Risk header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_riskColor.withOpacity(0.1), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border(bottom: BorderSide(color: _riskColor.withOpacity(0.4), width: 2)),
            ),
            child: Row(
              children: [
                Icon(_riskLevel == 'high' ? Icons.error : _riskLevel == 'medium' ? Icons.warning : Icons.check_circle, color: _riskColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fire Safety Risk', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(_riskLevel.toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _riskColor)),
                          const SizedBox(width: 8),
                          if (_noCount > 0 || _hasDangerousCondition)
                            Text('$_noCount issues found', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Service user + assessor row
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                if (_loadingUsers)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String>(
                    value: _selectedServiceUserId,
                    decoration: const InputDecoration(labelText: 'Service User', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: _serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedServiceUserId = v),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _assessorNameController,
                        decoration: const InputDecoration(labelText: 'Assessor', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: _assessmentDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (picked != null) setState(() => _assessmentDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          child: Text('${_assessmentDate.day}/${_assessmentDate.month}/${_assessmentDate.year}', style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Questions
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Container(width: 4, height: 16, color: const Color(0xFF1976D2)),
                      const SizedBox(width: 8),
                      const Text('Electrical Safety', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _buildQuestion('1. Does the service user have any electrical equipment in the home?', 'hasElectricalEquipment', ['Yes', 'No']),
                _buildQuestion('2. Has a PAT test sticker been seen on equipment within the last 12 months?', 'patTestVisible', ['Yes', 'No', 'Unknown']),
                _buildQuestion('3. Does the service user operate electrical equipment themselves?', 'operatesEquipmentSelf', ['Yes', 'No', 'With Support']),
                _buildQuestion('4. Are there any visible signs of electrical damage?', 'visibleDamage', ['Yes', 'No']),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      Container(width: 4, height: 16, color: const Color(0xFFFF6F00)),
                      const SizedBox(width: 8),
                      const Text('Fire Prevention', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _buildQuestion('5. Are there working smoke alarms?', 'workingSmokeAlarms', ['Yes', 'No', 'Unknown']),
                _buildQuestion('6. Does the service user smoke?', 'smokes', ['Yes', 'No']),
                _buildQuestion('7. Are escape routes kept clear?', 'escapeRoutesClear', ['Yes', 'No', 'Partial']),
                _buildQuestion('8. Is there a fire blanket or extinguisher in the kitchen?', 'hasFireBlanketOrExtinguisher', ['Yes', 'No', 'Unknown']),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      Container(width: 4, height: 16, color: const Color(0xFFE91E63)),
                      const SizedBox(width: 8),
                      const Text('Emergency Response', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _buildQuestion('9. In case of fire, can the service user exit independently?', 'canExitIndependently', ['Yes', 'No', 'With Assistance']),
                _buildQuestion('10. Does the service user understand fire safety instructions?', 'hasCapacityToUnderstand', ['Yes', 'No', 'Partial']),
                _buildQuestion('11. Is the service user\'s name and address clearly visible near the main entrance?', 'nameAddressVisible', ['Yes', 'No']),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _actionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '12. Recommended Actions',
                      hintText: 'Optional actions to improve fire safety...',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('I confirm that I have completed this assessment', style: TextStyle(fontSize: 13)),
                          value: _signatureConfirmed,
                          activeColor: const Color(0xFFF44336),
                          onChanged: (v) => setState(() => _signatureConfirmed = v ?? false),
                        ),
                        if (_signatureConfirmed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: TextField(
                              controller: _signatureController,
                              decoration: const InputDecoration(labelText: 'Assessor Signature', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit_note)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save Assessment'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336), foregroundColor: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}