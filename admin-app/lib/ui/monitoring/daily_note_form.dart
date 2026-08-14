import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/daily_note.dart';
import 'package:admin_app/services/daily_note_service.dart';
import 'package:admin_app/ui/monitoring/stool_log_form.dart';

class DailyNoteForm extends StatefulWidget {
  final DailyNote? note;
  final String? serviceUserId;

  const DailyNoteForm({super.key, this.note, this.serviceUserId});

  @override
  State<DailyNoteForm> createState() => _DailyNoteFormState();
}

class _DailyNoteFormState extends State<DailyNoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = DailyNoteService(Supabase.instance.client);

  // Service user
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;
  String? _selectedServiceUserId;

  // Basic info
  DateTime _visitDate = DateTime.now();
  TimeOfDay _visitTime = TimeOfDay.now();
  String _carerName = '';

  // Visit type
  String? _visitType;

  // Care acceptance
  String? _careAccepted;
  final _refusalReasonController = TextEditingController();

  // Emotional state
  List<String> _selectedEmotions = [];

  // Pad check
  bool _padChanged = false;
  bool _padUrinePresent = false;
  String? _padUrineAmount;
  bool _padFaecesPresent = false;
  String? _padFaecesAmount;

  // Food
  bool _foodOffered = false;
  double _foodEatenSlider = 50;
  final _foodDetailsController = TextEditingController();

  // Fluid
  bool _fluidOffered = false;
  int _fluidMl = 150;
  final _fluidDetailsController = TextEditingController();

  // Medication
  bool _medicationObserved = false;
  bool? _medicationTaken;
  bool _medicationRefused = false;
  final _medicationNotesController = TextEditingController();

  // Observations
  String? _skinCondition;
  final _skinNotesController = TextEditingController();
  final _mobilityNotesController = TextEditingController();
  final _communicationNotesController = TextEditingController();

  // Incidents
  bool _incidentOccurred = false;
  final _incidentDescriptionController = TextEditingController();
  final _incidentReportedToController = TextEditingController();

  // Manual notes
  bool _useManualNotes = false;
  final _manualNotesController = TextEditingController();

  // Signature
  bool _signatureConfirmed = false;
  final _signatureController = TextEditingController();

  bool _isSubmitting = false;

  final List<String> _visitTypes = ['morning', 'lunch', 'tea', 'evening'];
  final List<String> _skinOptions = ['Normal', 'Redness', 'Rash', 'Dry', 'Broken', 'Infected'];
  final List<int> _fluidPresets = [50, 100, 150, 200, 250, 500];

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    _initialize();
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
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  void _initialize() {
    _carerName = Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Current User';
    if (widget.note != null) {
      final n = widget.note!;
      _selectedServiceUserId = n.serviceUserId;
      _visitDate = n.visitDate;
      _visitTime = TimeOfDay(
        hour: int.tryParse(n.visitTime.split(':').first) ?? 0,
        minute: (int.tryParse(n.visitTime.split(':').length > 1 ? n.visitTime.split(':')[1] : '0')) ?? 0,
      );
      _carerName = n.carerName ?? _carerName;
      _visitType = n.visitType;
      _careAccepted = n.careAccepted;
      _refusalReasonController.text = n.refusalReason ?? '';
      _selectedEmotions = n.emotionalState ?? [];
      _padChanged = n.padChanged;
      _padUrinePresent = n.padUrinePresent;
      _padUrineAmount = n.padUrineAmount;
      _padFaecesPresent = n.padFaecesPresent;
      _padFaecesAmount = n.padFaecesAmount;
      _foodOffered = n.foodOffered;
      _foodEatenSlider = (n.foodEatenPercentage ?? 50).toDouble();
      _foodDetailsController.text = n.foodDetails ?? '';
      _fluidOffered = n.fluidOffered;
      _fluidMl = n.fluidMl ?? 150;
      _fluidDetailsController.text = n.fluidDetails ?? '';
      _medicationObserved = n.medicationObserved;
      if (n.medicationTaken) _medicationTaken = true;
      _medicationRefused = n.medicationRefused;
      _medicationNotesController.text = n.medicationNotes ?? '';
      _skinCondition = n.skinCondition;
      _skinNotesController.text = n.skinNotes ?? '';
      _mobilityNotesController.text = n.mobilityNotes ?? '';
      _communicationNotesController.text = n.communicationNotes ?? '';
      _incidentOccurred = n.incidentOccurred;
      _incidentDescriptionController.text = n.incidentDescription ?? '';
      _incidentReportedToController.text = n.incidentReportedTo ?? '';
      _useManualNotes = n.useManualNotes;
      _manualNotesController.text = n.manualNotes ?? '';
    }
  }

  @override
  void dispose() {
    _refusalReasonController.dispose();
    _foodDetailsController.dispose();
    _fluidDetailsController.dispose();
    _medicationNotesController.dispose();
    _skinNotesController.dispose();
    _mobilityNotesController.dispose();
    _communicationNotesController.dispose();
    _incidentDescriptionController.dispose();
    _incidentReportedToController.dispose();
    _manualNotesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    switch (preset) {
      case 'good':
        setState(() {
          _selectedEmotions = ['happy', 'calm'];
          _careAccepted = 'accepted';
          _foodOffered = true;
          _foodEatenSlider = 100;
          _skinCondition = 'Normal';
          _mobilityNotesController.text = 'Mobilised as normal';
        });
        break;
      case 'difficult':
        setState(() {
          _selectedEmotions = ['agitated', 'frustrated'];
          _careAccepted = 'partial';
          _refusalReasonController.text = 'Service user was unsettled';
        });
        break;
      case 'refused_all':
        setState(() {
          _careAccepted = 'refused';
          _refusalReasonController.text = 'Service user refused all care offered';
          _foodOffered = false;
          _fluidOffered = false;
          _medicationObserved = false;
          _selectedEmotions = ['frustrated', 'withdrawn'];
        });
        break;
    }
  }

  Future<void> _save({required bool completed}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service user')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userName = _serviceUsers.firstWhere((u) => u['id'] == _selectedServiceUserId)['name'] as String;
      final timeStr = '${_visitTime.hour.toString().padLeft(2, '0')}:${_visitTime.minute.toString().padLeft(2, '0')}:00';

      final note = DailyNote(
        id: widget.note?.id,
        serviceUserId: _selectedServiceUserId,
        serviceUserName: userName,
        carerName: _carerName,
        visitDate: _visitDate,
        visitTime: timeStr,
        visitType: _visitType!,
        careAccepted: _careAccepted!,
        refusalReason: _refusalReasonController.text.isNotEmpty ? _refusalReasonController.text : null,
        emotionalState: _selectedEmotions.isNotEmpty ? _selectedEmotions : null,
        padChanged: _padChanged,
        padUrinePresent: _padUrinePresent,
        padUrineAmount: _padUrineAmount,
        padFaecesPresent: _padFaecesPresent,
        padFaecesAmount: _padFaecesAmount,
        foodOffered: _foodOffered,
        foodEatenPercentage: _foodOffered ? _foodEatenSlider.round() : null,
        foodDetails: _foodDetailsController.text.isNotEmpty ? _foodDetailsController.text : null,
        fluidOffered: _fluidOffered,
        fluidMl: _fluidOffered ? _fluidMl : null,
        fluidDetails: _fluidDetailsController.text.isNotEmpty ? _fluidDetailsController.text : null,
        medicationObserved: _medicationObserved,
        medicationTaken: _medicationTaken ?? false,
        medicationRefused: _medicationRefused,
        medicationNotes: _medicationNotesController.text.isNotEmpty ? _medicationNotesController.text : null,
        skinCondition: _skinCondition,
        skinNotes: _skinNotesController.text.isNotEmpty ? _skinNotesController.text : null,
        mobilityNotes: _mobilityNotesController.text.isNotEmpty ? _mobilityNotesController.text : null,
        communicationNotes: _communicationNotesController.text.isNotEmpty ? _communicationNotesController.text : null,
        incidentOccurred: _incidentOccurred,
        incidentDescription: _incidentDescriptionController.text.isNotEmpty ? _incidentDescriptionController.text : null,
        incidentReportedTo: _incidentReportedToController.text.isNotEmpty ? _incidentReportedToController.text : null,
        useManualNotes: _useManualNotes,
        manualNotes: _useManualNotes && _manualNotesController.text.isNotEmpty ? _manualNotesController.text : null,
        carerSignature: _signatureConfirmed ? _signatureController.text.trim() : null,
        status: completed ? 'completed' : 'draft',
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.note?.id != null) {
        await _service.updateNote(widget.note!.id!, note);
      } else {
        await _service.createNote(note);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(completed ? 'Daily note submitted successfully' : 'Draft saved'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
    );
  }

  Widget _buildYesNoToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        ChoiceChip(label: const Text('No'), selected: !value, onSelected: (_) => onChanged(false)),
        const SizedBox(width: 8),
        ChoiceChip(label: const Text('Yes'), selected: value, onSelected: (_) => onChanged(true)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Notes'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service user
            if (_loadingUsers)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedServiceUserId,
                decoration: const InputDecoration(labelText: 'Service User *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                items: _serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String))).toList(),
                onChanged: (v) => setState(() => _selectedServiceUserId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            const SizedBox(height: 12),

            // Basic info row
            Row(children: [
              Expanded(child: InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _visitDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) setState(() => _visitDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                  child: Text('${_visitDate.day}/${_visitDate.month}/${_visitDate.year}'),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(child: InkWell(
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: _visitTime);
                  if (t != null) setState(() => _visitTime = t);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Time', prefixIcon: Icon(Icons.access_time), border: OutlineInputBorder()),
                  child: Text('${_visitTime.hour.toString().padLeft(2, '0')}:${_visitTime.minute.toString().padLeft(2, '0')}'),
                ),
              )),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Carer Name', border: OutlineInputBorder()),
              initialValue: _carerName,
              onChanged: (v) => _carerName = v,
            ),
            const SizedBox(height: 16),

            // Presets
            const Text('Quick Fill', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(avatar: const Icon(Icons.thumb_up, size: 16), label: const Text('Good visit'), onPressed: () => _applyPreset('good')),
                ActionChip(avatar: const Icon(Icons.warning, size: 16), label: const Text('Difficult visit'), onPressed: () => _applyPreset('difficult')),
                ActionChip(avatar: const Icon(Icons.block, size: 16), label: const Text('Refused all'), onPressed: () => _applyPreset('refused_all')),
              ],
            ),
            const SizedBox(height: 16),

            // Visit Type
            _buildSectionTitle('1. Visit Type'),
            Wrap(
              spacing: 8,
              children: _visitTypes.map((t) {
                final emoji = t == 'morning' ? '🌅' : t == 'lunch' ? '🍽️' : t == 'tea' ? '☕' : '🌙';
                final isSelected = _visitType == t;
                return ChoiceChip(
                  avatar: Text(emoji, style: const TextStyle(fontSize: 18)),
                  label: Text(t[0].toUpperCase() + t.substring(1)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _visitType = t),
                  selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
                );
              }).toList(),
            ),
            if (_visitType == null) const Text('Please select a visit type', style: TextStyle(color: Colors.red, fontSize: 12)),

            // Care Acceptance
            _buildSectionTitle('2. Care Acceptance'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(avatar: const Text('✅', style: TextStyle(fontSize: 16)), label: const Text('Accepted'), selected: _careAccepted == 'accepted', onSelected: (_) => setState(() => _careAccepted = 'accepted')),
                ChoiceChip(avatar: const Text('⚠️', style: TextStyle(fontSize: 16)), label: const Text('Partial'), selected: _careAccepted == 'partial', onSelected: (_) => setState(() => _careAccepted = 'partial')),
                ChoiceChip(avatar: const Text('❌', style: TextStyle(fontSize: 16)), label: const Text('Refused'), selected: _careAccepted == 'refused', onSelected: (_) => setState(() => _careAccepted = 'refused')),
              ],
            ),
            if (_careAccepted == 'partial' || _careAccepted == 'refused') ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _refusalReasonController,
                decoration: const InputDecoration(labelText: 'Reason for refusal', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
            if (_careAccepted == null) const Text('Please select care acceptance', style: TextStyle(color: Colors.red, fontSize: 12)),

            // Emotional State
            _buildSectionTitle('3. Emotional State'),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: EmotionalStateHelper.emojis.entries.map((e) {
                final isSelected = _selectedEmotions.contains(e.key);
                return FilterChip(
                  avatar: Text(e.value, style: const TextStyle(fontSize: 18)),
                  label: Text(EmotionalStateHelper.labels[e.key]!, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (v) {
                    setState(() {
                      if (v) { _selectedEmotions.add(e.key); } else { _selectedEmotions.remove(e.key); }
                    });
                  },
                );
              }).toList(),
            ),

            // Pad Check
            _buildSectionTitle('4. Pad / Continence Check'),
            _buildYesNoToggle('Was the pad checked/changed?', _padChanged, (v) => setState(() => _padChanged = v)),
            if (_padChanged) ...[
              const SizedBox(height: 8),
              _buildYesNoToggle('Urine present?', _padUrinePresent, (v) => setState(() { _padUrinePresent = v; if (!v) _padUrineAmount = null; })),
              if (_padUrinePresent) ...[
                Row(children: [
                  const Text('Amount: '),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Small'), selected: _padUrineAmount == 'small', onSelected: (_) => setState(() => _padUrineAmount = 'small')),
                  const SizedBox(width: 4),
                  ChoiceChip(label: const Text('Medium'), selected: _padUrineAmount == 'medium', onSelected: (_) => setState(() => _padUrineAmount = 'medium')),
                  const SizedBox(width: 4),
                  ChoiceChip(label: const Text('Large'), selected: _padUrineAmount == 'large', onSelected: (_) => setState(() => _padUrineAmount = 'large')),
                ]),
              ],
              const SizedBox(height: 8),
              _buildYesNoToggle('Faeces present?', _padFaecesPresent, (v) => setState(() { _padFaecesPresent = v; if (!v) _padFaecesAmount = null; })),
              if (_padFaecesPresent) ...[
                Row(children: [
                  const Text('Amount: '),
                  ChoiceChip(label: const Text('Small'), selected: _padFaecesAmount == 'small', onSelected: (_) => setState(() => _padFaecesAmount = 'small')),
                  const SizedBox(width: 4),
                  ChoiceChip(label: const Text('Medium'), selected: _padFaecesAmount == 'medium', onSelected: (_) => setState(() => _padFaecesAmount = 'medium')),
                  const SizedBox(width: 4),
                  ChoiceChip(label: const Text('Large'), selected: _padFaecesAmount == 'large', onSelected: (_) => setState(() => _padFaecesAmount = 'large')),
                ]),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StoolLogForm(serviceUserId: _selectedServiceUserId))).then((_) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stool logged')));
                    });
                  },
                  icon: const Icon(Icons.assignment),
                  label: const Text('Log Stool Details'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.brown),
                ),
              ],
            ],

            // Food & Fluid
            if (!_useManualNotes) ...[
              _buildSectionTitle('5. Food & Fluid'),
              _buildYesNoToggle('Food offered?', _foodOffered, (v) => setState(() => _foodOffered = v)),
              if (_foodOffered) ...[
                const SizedBox(height: 8),
                const Text('How much was eaten?'),
                Slider(
                  value: _foodEatenSlider,
                  min: 0, max: 100, divisions: 20,
                  label: '${_foodEatenSlider.round()}%',
                  onChanged: (v) => setState(() => _foodEatenSlider = v),
                ),
                Text('${_foodEatenSlider.round()}% eaten', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _foodDetailsController,
                  decoration: const InputDecoration(labelText: 'Food details', hintText: 'e.g. Toast and tea', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 12),
              _buildYesNoToggle('Fluid offered?', _fluidOffered, (v) => setState(() => _fluidOffered = v)),
              if (_fluidOffered) ...[
                const SizedBox(height: 8),
                const Text('Amount (ml):'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _fluidPresets.map((m) => ChoiceChip(
                    label: Text('${m}ml'),
                    selected: _fluidMl == m,
                    onSelected: (_) => setState(() => _fluidMl = m),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fluidDetailsController,
                  decoration: const InputDecoration(labelText: 'Fluid details', hintText: 'e.g. Water with juice', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],

              // Medication
              _buildSectionTitle('6. Medication Observed'),
              _buildYesNoToggle('Medication observed?', _medicationObserved, (v) => setState(() => _medicationObserved = v)),
              if (_medicationObserved) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('Taken'), selected: _medicationTaken == true, onSelected: (_) => setState(() { _medicationTaken = true; _medicationRefused = false; })),
                    ChoiceChip(label: const Text('Partial'), selected: _medicationTaken == null, onSelected: (_) => setState(() { _medicationTaken = null; _medicationRefused = false; })),
                    ChoiceChip(label: const Text('Refused'), selected: _medicationRefused, onSelected: (_) => setState(() { _medicationRefused = true; _medicationTaken = false; })),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _medicationNotesController,
                  decoration: const InputDecoration(labelText: 'Medication notes', hintText: 'Which medication, any reactions', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],

              // Observations
              _buildSectionTitle('7. General Observations'),
              DropdownButtonFormField<String>(
                value: _skinCondition,
                decoration: const InputDecoration(labelText: 'Skin condition', border: OutlineInputBorder()),
                items: _skinOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _skinCondition = v),
                style: const TextStyle(color: Colors.black),
                dropdownColor: Colors.white,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _skinNotesController, decoration: const InputDecoration(labelText: 'Skin notes', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 8),
              TextFormField(controller: _mobilityNotesController, decoration: const InputDecoration(labelText: 'Mobility notes', hintText: 'e.g. Walked with frame', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 8),
              TextFormField(controller: _communicationNotesController, decoration: const InputDecoration(labelText: 'Communication notes', hintText: 'e.g. Spoke clearly', border: OutlineInputBorder()), maxLines: 2),

              // Incidents
              _buildSectionTitle('8. Incidents & Concerns'),
              _buildYesNoToggle('Did any incident occur?', _incidentOccurred, (v) => setState(() => _incidentOccurred = v)),
              if (_incidentOccurred) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _incidentDescriptionController,
                  decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
                  maxLines: 3,
                  validator: _incidentOccurred ? (v) => v!.isEmpty ? 'Required' : null : null,
                ),
                const SizedBox(height: 8),
                TextFormField(controller: _incidentReportedToController, decoration: const InputDecoration(labelText: 'Reported to', border: OutlineInputBorder())),
              ],
            ],

            // Manual notes toggle
            _buildSectionTitle('9. Manual Notes'),
            SwitchListTile(
              title: const Text('Write manual notes instead'),
              subtitle: const Text('Hides structured sections above'),
              value: _useManualNotes,
              onChanged: (v) => setState(() => _useManualNotes = v),
            ),
            if (_useManualNotes) ...[
              TextFormField(
                controller: _manualNotesController,
                decoration: const InputDecoration(labelText: 'Daily notes', border: OutlineInputBorder()),
                maxLines: 10,
              ),
            ],

            // Signature
            _buildSectionTitle('10. Signature & Submit'),
            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('I confirm these notes are accurate to the best of my knowledge'),
                    value: _signatureConfirmed,
                    activeColor: const Color(0xFF1976D2),
                    onChanged: (v) => setState(() => _signatureConfirmed = v ?? false),
                  ),
                  if (_signatureConfirmed) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _signatureController,
                        decoration: const InputDecoration(labelText: 'Signature (type your name)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit_note)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _save(completed: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _save(completed: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}