import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/care_log_audit.dart';
import 'package:admin_app/services/care_log_audit_service.dart';

class CareLogAuditForm extends StatefulWidget {
  final CareLogAudit? audit;

  const CareLogAuditForm({super.key, this.audit});

  @override
  State<CareLogAuditForm> createState() => _CareLogAuditFormState();
}

class _CareLogAuditFormState extends State<CareLogAuditForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = CareLogAuditService(Supabase.instance.client);

  // Service users
  List<Map<String, dynamic>> _serviceUsers = [];
  bool _loadingUsers = true;

  // Selected daily note for audit
  List<Map<String, dynamic>> _dailyNotes = [];
  String? _selectedDailyNoteId;
  Map<String, dynamic>? _selectedDailyNote;
  bool _loadingDailyNotes = false;

  // Auditor info
  String _auditorName = Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Auditor';
  DateTime _auditDate = DateTime.now();

  // ============================================================
  // SECTION 1: Completeness scores (0-2 each)
  // ============================================================
  int _compBasicInfo = 0;
  int _compVisitType = 0;
  int _compCareAcceptance = 0;
  int _compEmotionalState = 0;
  int _compPadCheck = 0;
  int _compFoodFluid = 0;
  int _compMedication = 0;
  int _compObservations = 0;
  int _compIncidents = 0;
  int _compSignature = 0;

  // ============================================================
  // SECTION 2: Accuracy (booleans)
  // ============================================================
  bool _accEmotionalMatch = false;
  bool _accFoodFluidAmounts = false;
  bool _accMedicationDetails = false;
  bool _accSkinCondition = false;
  bool _accIncidentDetails = false;

  // ============================================================
  // SECTION 3: Compliance (booleans)
  // ============================================================
  bool _compCareAct2014 = false;
  bool _compMca2005 = false;
  bool _compDols = false;
  bool _compConfidentiality = false;
  bool _compTimeliness = false;

  // ============================================================
  // SECTION 4: Quality (booleans)
  // ============================================================
  bool _qualProfessionalLanguage = false;
  bool _qualObjectiveObservations = false;
  bool _qualLegibility = false;
  bool _qualActionableInfo = false;
  bool _qualContinuity = false;

  // ============================================================
  // SECTION 5: Clinical Safety (booleans - any true = critical)
  // ============================================================
  bool _csMedicationErrors = false;
  bool _csSafeguarding = false;
  bool _csHealthDeterioration = false;
  bool _csFallsRisk = false;
  bool _csNutritionHydration = false;
  final _csNotesController = TextEditingController();

  // ============================================================
  // SECTION 7: Action Plan
  // ============================================================
  final _actionRequiredController = TextEditingController();
  List<Map<String, dynamic>> _staffUsers = [];
  String? _actionAssignedTo;
  DateTime? _actionDeadline;
  final _actionNotesController = TextEditingController();

  // ============================================================
  // SECTION 9: Sign-off
  // ============================================================
  final _auditorSignatureController = TextEditingController();
  bool _managerReviewed = false;
  final _managerSignatureController = TextEditingController();
  final _managerNotesController = TextEditingController();

  // State
  bool _isSubmitting = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadServiceUsers();
    _loadStaffUsers();
    _isEditing = widget.audit != null;
    if (_isEditing) {
      _populateFromAudit(widget.audit!);
    }
  }

  void _populateFromAudit(CareLogAudit audit) {
    _selectedDailyNoteId = audit.dailyNoteId;
    _auditorName = audit.auditorName;
    _auditDate = audit.auditDate;

    _compBasicInfo = audit.completenessBasicInfo ?? 0;
    _compVisitType = audit.completenessVisitType ?? 0;
    _compCareAcceptance = audit.completenessCareAcceptance ?? 0;
    _compEmotionalState = audit.completenessEmotionalState ?? 0;
    _compPadCheck = audit.completenessPadCheck ?? 0;
    _compFoodFluid = audit.completenessFoodFluid ?? 0;
    _compMedication = audit.completenessMedication ?? 0;
    _compObservations = audit.completenessObservations ?? 0;
    _compIncidents = audit.completenessIncidents ?? 0;
    _compSignature = audit.completenessSignature ?? 0;

    _accEmotionalMatch = audit.accuracyEmotionalStateMatch ?? false;
    _accFoodFluidAmounts = audit.accuracyFoodFluidAmounts ?? false;
    _accMedicationDetails = audit.accuracyMedicationDetails ?? false;
    _accSkinCondition = audit.accuracySkinCondition ?? false;
    _accIncidentDetails = audit.accuracyIncidentDetails ?? false;

    _compCareAct2014 = audit.complianceCareAct2014 ?? false;
    _compMca2005 = audit.complianceMca2005 ?? false;
    _compDols = audit.complianceDols ?? false;
    _compConfidentiality = audit.complianceConfidentiality ?? false;
    _compTimeliness = audit.complianceTimeliness ?? false;

    _qualProfessionalLanguage = audit.qualityProfessionalLanguage ?? false;
    _qualObjectiveObservations = audit.qualityObjectiveObservations ?? false;
    _qualLegibility = audit.qualityLegibilityReadability ?? false;
    _qualActionableInfo = audit.qualityActionableInformation ?? false;
    _qualContinuity = audit.qualityContinuityOfCare ?? false;

    _csMedicationErrors = audit.clinicalSafetyMedicationErrors;
    _csSafeguarding = audit.clinicalSafetySafeguarding;
    _csHealthDeterioration = audit.clinicalSafetyHealthDeterioration;
    _csFallsRisk = audit.clinicalSafetyFallsRisk;
    _csNutritionHydration = audit.clinicalSafetyNutritionHydration;
    _csNotesController.text = audit.clinicalSafetyNotes ?? '';

    _actionRequiredController.text = audit.actionRequired ?? '';
    _actionAssignedTo = audit.actionAssignedTo;
    _actionDeadline = audit.actionDeadline;
    _actionNotesController.text = audit.actionNotes ?? '';

    _auditorSignatureController.text = audit.auditorSignature ?? '';
    _managerReviewed = audit.managerReviewed;
    _managerNotesController.text = audit.managerNotes ?? '';

    if (audit.dailyNoteId.isNotEmpty) {
      _loadDailyNoteDetails(audit.dailyNoteId);
    }
  }

  @override
  void dispose() {
    _csNotesController.dispose();
    _actionRequiredController.dispose();
    _actionNotesController.dispose();
    _auditorSignatureController.dispose();
    _managerSignatureController.dispose();
    _managerNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceUsers() async {
    try {
      final users = await _service.getServiceUsers();
      setState(() {
        _serviceUsers = users;
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadStaffUsers() async {
    try {
      final staff = await _service.getStaffUsers();
      setState(() => _staffUsers = staff);
    } catch (_) {}
  }

  Future<void> _loadDailyNotes(String? serviceUserId) async {
    setState(() => _loadingDailyNotes = true);
    try {
      final notes = await _service.getDailyNotesForAudit(serviceUserId: serviceUserId);
      setState(() {
        _dailyNotes = notes;
        _loadingDailyNotes = false;
      });
    } catch (_) {
      setState(() => _loadingDailyNotes = false);
    }
  }

  Future<void> _loadDailyNoteDetails(String dailyNoteId) async {
    final note = await _service.getDailyNoteDetails(dailyNoteId);
    if (note != null && mounted) {
      setState(() {
        _selectedDailyNote = note;
        _autoCompleteScores(note);
      });
    }
  }

  void _autoCompleteScores(Map<String, dynamic> note) {
    // Pre-fill completeness scores based on actual data
    _compBasicInfo = (note['service_user_id'] != null && note['visit_date'] != null && note['visit_time'] != null) ? 2 : 0;
    _compVisitType = note['visit_type'] != null ? 2 : 0;
    _compCareAcceptance = note['care_accepted'] != null ? (note['refusal_reason'] != null && note['care_accepted'] != 'accepted' ? 2 : 1) : 0;
    _compEmotionalState = note['emotional_state'] != null ? ((note['emotional_state'] as List?)?.length ?? 0) >= 3 ? 2 : 1 : 0;
    _compPadCheck = note['pad_changed'] == true ? (note['pad_urine_present'] != null ? 2 : 1) : 0;
    _compFoodFluid = note['food_offered'] == true || note['fluid_offered'] == true ? (note['food_eaten_percentage'] != null || note['fluid_ml'] != null ? 2 : 1) : 0;
    _compMedication = note['medication_observed'] == true ? (note['medication_taken'] != null ? 2 : 1) : 0;
    _compObservations = note['mobility_notes'] != null || note['communication_notes'] != null ? 2 : 1;
    _compIncidents = note['incident_occurred'] == true ? (note['incident_description'] != null ? 2 : 1) : 1;
    _compSignature = note['carer_signature'] != null ? 2 : 0;

    // Pre-fill accuracy
    _accEmotionalMatch = true;
    _accFoodFluidAmounts = true;
    _accMedicationDetails = true;
    _accSkinCondition = note['skin_condition'] != null;
    _accIncidentDetails = note['incident_occurred'] != true || note['incident_description'] != null;

    // Pre-fill compliance
    _compCareAct2014 = true;
    _compMca2005 = true;
    _compDols = true;
    _compConfidentiality = true;
    _compTimeliness = true;

    // Pre-fill quality
    _qualProfessionalLanguage = true;
    _qualObjectiveObservations = true;
    _qualLegibility = true;
    _qualActionableInfo = true;
    _qualContinuity = true;
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================

  int _getCompletenessTotal() {
    return _compBasicInfo + _compVisitType + _compCareAcceptance + _compEmotionalState +
        _compPadCheck + _compFoodFluid + _compMedication + _compObservations + _compIncidents + _compSignature;
  }

  int _getAccuracyTotal() {
    int score = 0;
    if (_accEmotionalMatch) score += 2;
    if (_accFoodFluidAmounts) score += 2;
    if (_accMedicationDetails) score += 2;
    if (_accSkinCondition) score += 2;
    if (_accIncidentDetails) score += 2;
    return score;
  }

  int _getComplianceTotal() {
    int score = 0;
    if (_compCareAct2014) score += 2;
    if (_compMca2005) score += 2;
    if (_compDols) score += 2;
    if (_compConfidentiality) score += 2;
    if (_compTimeliness) score += 2;
    return score;
  }

  int _getQualityTotal() {
    int score = 0;
    if (_qualProfessionalLanguage) score += 2;
    if (_qualObjectiveObservations) score += 2;
    if (_qualLegibility) score += 2;
    if (_qualActionableInfo) score += 2;
    if (_qualContinuity) score += 2;
    return score;
  }

  int _getOverallScore() {
    return _getCompletenessTotal() + _getAccuracyTotal() + _getComplianceTotal() + _getQualityTotal();
  }

  double _getOverallPercentage() {
    return (_getOverallScore() / 50.0) * 100;
  }

  bool _hasClinicalSafetyFlag() {
    return _csMedicationErrors || _csSafeguarding || _csHealthDeterioration || _csFallsRisk || _csNutritionHydration;
  }

  bool _requiresAction() {
    return _hasClinicalSafetyFlag() || _getOverallPercentage() < 75;
  }

  @override
  Widget build(BuildContext context) {
    final totalScore = _getOverallScore();
    final percentage = _getOverallPercentage();
    final hasSafetyFlag = _hasClinicalSafetyFlag();
    final riskLevel = AuditRiskHelper.calculateRiskLevel(percentage, hasSafetyFlag);
    final riskColor = AuditRiskHelper.getRiskColor(riskLevel);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Audit' : 'New Audit'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Live score summary at top
            _buildScoreSummary(percentage, riskLevel, riskColor, hasSafetyFlag),
            const SizedBox(height: 16),

            // Section 1: Select Daily Note
            _buildSectionTitle('1. Select Daily Note to Audit'),
            _buildDailyNoteSelector(),
            if (_selectedDailyNote != null) _buildDailyNotePreview(),
            const SizedBox(height: 16),

            // Section 2: Completeness
            _buildSectionTitle('2. Completeness (0=Missing, 1=Partial, 2=Complete)'),
            _buildCompletenessSection(),
            const SizedBox(height: 16),

            // Section 3: Accuracy
            _buildSectionTitle('3. Accuracy'),
            _buildAccuracySection(),
            const SizedBox(height: 16),

            // Section 4: Compliance
            _buildSectionTitle('4. Compliance'),
            _buildComplianceSection(),
            const SizedBox(height: 16),

            // Section 5: Quality
            _buildSectionTitle('5. Quality'),
            _buildQualitySection(),
            const SizedBox(height: 16),

            // Section 6: Clinical Safety
            _buildSectionTitle('6. Clinical Safety (Critical)'),
            _buildClinicalSafetySection(),
            const SizedBox(height: 16),

            // Section 7: Action Plan
            if (_requiresAction()) ...[
              _buildSectionTitle('7. Action Plan'),
              _buildActionPlanSection(),
              const SizedBox(height: 16),
            ],

            // Section 8: Sign-off
            _buildSectionTitle('8. Sign-off'),
            _buildSignOffSection(),
            const SizedBox(height: 16),

            // Summary card
            _buildSummaryCard(totalScore, percentage, riskLevel, riskColor, hasSafetyFlag),
            const SizedBox(height: 24),

            // Submit buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _save(status: 'draft'),
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
                    onPressed: _isSubmitting ? null : () => _save(status: 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Audit', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildScoreSummary(double percentage, String riskLevel, Color riskColor, bool hasSafetyFlag) {
    return Card(
      color: riskColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  ),
                  Text('${percentage.round()}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: riskColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AuditRiskHelper.getRiskIcon(riskLevel), size: 16, color: riskColor),
                      const SizedBox(width: 4),
                      Text(AuditRiskHelper.getRiskLabel(riskLevel),
                        style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  if (hasSafetyFlag)
                    const Text('⚠️ Clinical safety flag detected', style: TextStyle(color: Colors.red, fontSize: 11)),
                ],
              ),
            ),
            if (_requiresAction())
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('Action Needed', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DAILY NOTE SELECTOR
  // ============================================================

  Widget _buildDailyNoteSelector() {
    return Column(
      children: [
        // Service user filter for daily notes
        if (_loadingUsers)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Service User', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
            items: _serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String))).toList(),
            onChanged: (v) {
              _selectedDailyNoteId = null;
              _selectedDailyNote = null;
              _loadDailyNotes(v);
            },
          ),
        const SizedBox(height: 8),

        // Daily note selector
        if (_loadingDailyNotes)
          const Center(child: CircularProgressIndicator())
        else if (_dailyNotes.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedDailyNoteId,
            decoration: const InputDecoration(labelText: 'Daily Note *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note)),
            items: _dailyNotes.map((n) => DropdownMenuItem(
              value: n['id'] as String,
              child: Text(
                '${DateFormat('dd MMM').format(DateTime.parse(n['visit_date']))} - '
                '${(n['visit_type'] as String?)?.capitalize() ?? ''} ${n['status'] == 'draft' ? '(draft)' : ''}',
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: (v) {
              setState(() => _selectedDailyNoteId = v);
              if (v != null) _loadDailyNoteDetails(v);
            },
            validator: (v) => v == null ? 'Required' : null,
          ),
      ],
    );
  }

  Widget _buildDailyNotePreview() {
    if (_selectedDailyNote == null) return const SizedBox.shrink();
    final n = _selectedDailyNote!;
    final emotions = n['emotional_state'] as List?;
    final skin = n['skin_condition'] as String?;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋 ${n['service_user_name'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Visit: ${n['visit_type']} | ${n['care_accepted']}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            if (emotions != null && emotions.isNotEmpty)
              Text('Emotions: ${emotions.join(', ')}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            if (skin != null) Text('Skin: $skin', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPLETENESS
  // ============================================================

  Widget _buildCompletenessSection() {
    return Column(
      children: [
        _buildScoreRow('Basic Info (user, date, time, carer)', _compBasicInfo, (v) => _compBasicInfo = v),
        _buildScoreRow('Visit Type', _compVisitType, (v) => _compVisitType = v),
        _buildScoreRow('Care Acceptance', _compCareAcceptance, (v) => _compCareAcceptance = v),
        _buildScoreRow('Emotional State', _compEmotionalState, (v) => _compEmotionalState = v),
        _buildScoreRow('Pad Check', _compPadCheck, (v) => _compPadCheck = v),
        _buildScoreRow('Food & Fluid', _compFoodFluid, (v) => _compFoodFluid = v),
        _buildScoreRow('Medication', _compMedication, (v) => _compMedication = v),
        _buildScoreRow('Observations', _compObservations, (v) => _compObservations = v),
        _buildScoreRow('Incidents', _compIncidents, (v) => _compIncidents = v),
        _buildScoreRow('Signature', _compSignature, (v) => _compSignature = v),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Total: ${_getCompletenessTotal()}/20',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildScoreRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          SizedBox(
            width: 120,
            child: Row(
              children: [0, 1, 2].map((s) {
                final colors = [Colors.red, Colors.orange, Colors.green];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => onChanged(s)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: value == s ? colors[s].withOpacity(0.2) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: value == s ? colors[s] : Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text('$s', style: TextStyle(
                          fontSize: 12,
                          fontWeight: value == s ? FontWeight.bold : FontWeight.normal,
                          color: value == s ? colors[s] : Colors.grey,
                        )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCURACY
  // ============================================================

  Widget _buildAccuracySection() {
    return Column(
      children: [
        _buildBoolRow('Emotional state matches narrative?', _accEmotionalMatch, (v) => _accEmotionalMatch = v),
        _buildBoolRow('Food/fluid amounts realistic?', _accFoodFluidAmounts, (v) => _accFoodFluidAmounts = v),
        _buildBoolRow('Medication details match MAR?', _accMedicationDetails, (v) => _accMedicationDetails = v),
        _buildBoolRow('Skin condition documented correctly?', _accSkinCondition, (v) => _accSkinCondition = v),
        _buildBoolRow('Incident details complete?', _accIncidentDetails, (v) => _accIncidentDetails = v),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Total: ${_getAccuracyTotal()}/10',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  // ============================================================
  // COMPLIANCE
  // ============================================================

  Widget _buildComplianceSection() {
    return Column(
      children: [
        _buildBoolRow('Care Act 2014 (person-centred)?', _compCareAct2014, (v) => _compCareAct2014 = v),
        _buildBoolRow('MCA 2005 considerations?', _compMca2005, (v) => _compMca2005 = v),
        _buildBoolRow('DoLS considerations?', _compDols, (v) => _compDols = v),
        _buildBoolRow('No breach of confidentiality?', _compConfidentiality, (v) => _compConfidentiality = v),
        _buildBoolRow('Completed within 24 hours?', _compTimeliness, (v) => _compTimeliness = v),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Total: ${_getComplianceTotal()}/10',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  // ============================================================
  // QUALITY
  // ============================================================

  Widget _buildQualitySection() {
    return Column(
      children: [
        _buildBoolRow('Professional language?', _qualProfessionalLanguage, (v) => _qualProfessionalLanguage = v),
        _buildBoolRow('Objective observations?', _qualObjectiveObservations, (v) => _qualObjectiveObservations = v),
        _buildBoolRow('Legible and readable?', _qualLegibility, (v) => _qualLegibility = v),
        _buildBoolRow('Actionable info for next carer?', _qualActionableInfo, (v) => _qualActionableInfo = v),
        _buildBoolRow('Continuity of care references?', _qualContinuity, (v) => _qualContinuity = v),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Total: ${_getQualityTotal()}/10',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildBoolRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          ChoiceChip(
            label: const Text('No', style: TextStyle(fontSize: 11)),
            selected: !value,
            onSelected: (_) => setState(() => onChanged(false)),
          ),
          const SizedBox(width: 4),
          ChoiceChip(
            label: const Text('Yes', style: TextStyle(fontSize: 11)),
            selected: value,
            onSelected: (_) => setState(() => onChanged(true)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CLINICAL SAFETY
  // ============================================================

  Widget _buildClinicalSafetySection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Any issues flagged here will set risk level to CRITICAL',
                style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSafetyCheck('Medication discrepancies found', _csMedicationErrors, (v) => _csMedicationErrors = v),
            _buildSafetyCheck('Missing safeguarding concerns', _csSafeguarding, (v) => _csSafeguarding = v),
            _buildSafetyCheck('Missed health deterioration signs', _csHealthDeterioration, (v) => _csHealthDeterioration = v),
            _buildSafetyCheck('Falls risk not documented', _csFallsRisk, (v) => _csFallsRisk = v),
            _buildSafetyCheck('Nutrition/hydration concerns missed', _csNutritionHydration, (v) => _csNutritionHydration = v),
            const SizedBox(height: 8),
            TextFormField(
              controller: _csNotesController,
              decoration: const InputDecoration(labelText: 'Clinical safety notes', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCheck(String label, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 12)),
      value: value,
      dense: true,
      activeColor: Colors.red,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.trailing,
      onChanged: (v) => setState(() => onChanged(v ?? false)),
    );
  }

  // ============================================================
  // ACTION PLAN
  // ============================================================

  Widget _buildActionPlanSection() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Action required due to risk level',
                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _actionRequiredController,
              decoration: const InputDecoration(labelText: 'Action Required *', border: OutlineInputBorder()),
              maxLines: 2,
              validator: _requiresAction() ? (v) => v!.isEmpty ? 'Required' : null : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _actionAssignedTo,
              decoration: const InputDecoration(labelText: 'Assign To *', border: OutlineInputBorder()),
              items: _staffUsers.map((s) => DropdownMenuItem(
                value: s['id'] as String,
                child: Text(s['full_name'] as String? ?? s['email'] as String? ?? ''),
              )).toList(),
              onChanged: (v) => setState(() => _actionAssignedTo = v),
              validator: _requiresAction() ? (v) => v == null ? 'Required' : null : null,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _actionDeadline ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _actionDeadline = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Deadline *', border: OutlineInputBorder()),
                child: Text(_actionDeadline != null
                    ? DateFormat('dd MMM yyyy').format(_actionDeadline!)
                    : 'Select date'),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _actionNotesController,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIGN-OFF
  // ============================================================

  Widget _buildSignOffSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _auditorSignatureController,
          decoration: const InputDecoration(labelText: 'Auditor Name / Signature *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit_note)),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Manager reviewed', style: TextStyle(fontSize: 13)),
          value: _managerReviewed,
          activeColor: const Color(0xFF1976D2),
          contentPadding: EdgeInsets.zero,
          onChanged: _isEditing
              ? (v) => setState(() => _managerReviewed = v ?? false)
              : null,
        ),
        if (_managerReviewed) ...[
          const SizedBox(height: 4),
          TextFormField(
            controller: _managerSignatureController,
            decoration: const InputDecoration(labelText: 'Manager Signature', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _managerNotesController,
            decoration: const InputDecoration(labelText: 'Manager Notes', border: OutlineInputBorder()),
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard(int totalScore, double percentage, String riskLevel, Color riskColor, bool hasSafetyFlag) {
    return Card(
      color: riskColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audit Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(),
            _summaryRow('Completeness', '${_getCompletenessTotal()}/20', null),
            _summaryRow('Accuracy', '${_getAccuracyTotal()}/10', null),
            _summaryRow('Compliance', '${_getComplianceTotal()}/10', null),
            _summaryRow('Quality', '${_getQualityTotal()}/10', null),
            _summaryRow('Total Score', '$totalScore/50', riskColor),
            _summaryRow('Percentage', '${percentage.toStringAsFixed(1)}%', riskColor),
            _summaryRow('Risk Level', AuditRiskHelper.getRiskLabel(riskLevel), riskColor),
            if (hasSafetyFlag) ...[
              const Divider(),
              const Text('⚠️ Clinical Safety Flags Present', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              if (_csMedicationErrors) const Text('  • Medication discrepancies', style: TextStyle(color: Colors.red, fontSize: 11)),
              if (_csSafeguarding) const Text('  • Missing safeguarding concerns', style: TextStyle(color: Colors.red, fontSize: 11)),
              if (_csHealthDeterioration) const Text('  • Missed health deterioration', style: TextStyle(color: Colors.red, fontSize: 11)),
              if (_csFallsRisk) const Text('  • Falls risk not documented', style: TextStyle(color: Colors.red, fontSize: 11)),
              if (_csNutritionHydration) const Text('  • Nutrition/hydration concerns', style: TextStyle(color: Colors.red, fontSize: 11)),
            ],
            if (_requiresAction()) ...[
              const Divider(),
              const Text('⚠️ Action Required', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save({required String status}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDailyNoteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a daily note')));
      return;
    }

    if (_auditorSignatureController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auditor signature required')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final percentage = _getOverallPercentage();
      final hasSafetyFlag = _hasClinicalSafetyFlag();
      final riskLevel = AuditRiskHelper.calculateRiskLevel(percentage, hasSafetyFlag);
      final requiresAction = _requiresAction();

      // Get user info from daily note
      final dailyNote = _dailyNotes.firstWhere((n) => n['id'] == _selectedDailyNoteId);
      final serviceUserId = dailyNote['service_user_id'] as String;
      final serviceUserName = dailyNote['service_user_name'] as String;

      final audit = CareLogAudit(
        id: widget.audit?.id,
        dailyNoteId: _selectedDailyNoteId!,
        serviceUserId: serviceUserId,
        serviceUserName: serviceUserName,
        auditDate: _auditDate,
        auditorName: _auditorName,
        auditorId: Supabase.instance.client.auth.currentUser?.id,
        completenessBasicInfo: _compBasicInfo,
        completenessVisitType: _compVisitType,
        completenessCareAcceptance: _compCareAcceptance,
        completenessEmotionalState: _compEmotionalState,
        completenessPadCheck: _compPadCheck,
        completenessFoodFluid: _compFoodFluid,
        completenessMedication: _compMedication,
        completenessObservations: _compObservations,
        completenessIncidents: _compIncidents,
        completenessSignature: _compSignature,
        accuracyEmotionalStateMatch: _accEmotionalMatch,
        accuracyFoodFluidAmounts: _accFoodFluidAmounts,
        accuracyMedicationDetails: _accMedicationDetails,
        accuracySkinCondition: _accSkinCondition,
        accuracyIncidentDetails: _accIncidentDetails,
        complianceCareAct2014: _compCareAct2014,
        complianceMca2005: _compMca2005,
        complianceDols: _compDols,
        complianceConfidentiality: _compConfidentiality,
        complianceTimeliness: _compTimeliness,
        qualityProfessionalLanguage: _qualProfessionalLanguage,
        qualityObjectiveObservations: _qualObjectiveObservations,
        qualityLegibilityReadability: _qualLegibility,
        qualityActionableInformation: _qualActionableInfo,
        qualityContinuityOfCare: _qualContinuity,
        clinicalSafetyMedicationErrors: _csMedicationErrors,
        clinicalSafetySafeguarding: _csSafeguarding,
        clinicalSafetyHealthDeterioration: _csHealthDeterioration,
        clinicalSafetyFallsRisk: _csFallsRisk,
        clinicalSafetyNutritionHydration: _csNutritionHydration,
        totalCompletenessScore: _getCompletenessTotal(),
        totalAccuracyScore: _getAccuracyTotal(),
        totalComplianceScore: _getComplianceTotal(),
        totalQualityScore: _getQualityTotal(),
        overallScore: _getOverallScore(),
        overallPercentage: percentage,
        riskLevel: riskLevel,
        clinicalSafetyAlert: hasSafetyFlag,
        clinicalSafetyNotes: _csNotesController.text.isNotEmpty ? _csNotesController.text : null,
        requiresAction: requiresAction,
        actionRequired: requiresAction ? _actionRequiredController.text : null,
        actionAssignedTo: requiresAction ? _actionAssignedTo : null,
        actionDeadline: requiresAction ? _actionDeadline : null,
        actionNotes: _actionNotesController.text.isNotEmpty ? _actionNotesController.text : null,
        auditorSignature: _auditorSignatureController.text.trim(),
        managerReviewed: _managerReviewed,
        managerReviewedBy: null,
        managerReviewedAt: null,
        managerNotes: _managerNotesController.text.isNotEmpty ? _managerNotesController.text : null,
        status: requiresAction && status == 'completed' ? 'action_required' : status,
        createdAt: widget.audit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.audit?.id != null) {
        await _service.updateAudit(widget.audit!.id!, audit);
      } else {
        await _service.createAudit(audit);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'completed' ? 'Audit submitted' : 'Draft saved'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}