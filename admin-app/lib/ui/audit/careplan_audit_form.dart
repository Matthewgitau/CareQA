import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/care_plan_audit.dart';
import 'package:admin_app/services/care_plan_audit_service.dart';

class CarePlanAuditFormView extends StatefulWidget {
  final CarePlanAudit? audit;
  const CarePlanAuditFormView({super.key, this.audit});

  @override
  State<CarePlanAuditFormView> createState() => _CarePlanAuditFormViewState();
}

class _CarePlanAuditFormViewState extends State<CarePlanAuditFormView> {
  final _formKey = GlobalKey<FormState>();
  final _service = CarePlanAuditService(Supabase.instance.client);

  List<Map<String, dynamic>> _serviceUsers = [];
  List<Map<String, dynamic>> _staffUsers = [];
  bool _loading = true;
  bool _isEditing = false;

  // Service user
  String? _serviceUserId;
  String? _serviceUserName;

  // Auditor
  String _auditorName = Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Auditor';
  DateTime _auditDate = DateTime.now();

  // ========== SECTION 1: Person-Centred Care ==========
  int _pc1 = 0, _pc2 = 0, _pc3 = 0, _pc4 = 0, _pc5 = 0, _pc6 = 0;

  // ========== SECTION 2: Risk Integration ==========
  int _r1 = 0, _r2 = 0, _r3 = 0, _r4 = 0, _r5 = 0, _r6 = 0, _r7 = 0, _r8 = 0, _r9 = 0, _r10 = 0;

  // ========== SECTION 3: Care Delivery ==========
  int _d1 = 0, _d2 = 0, _d3 = 0, _d4 = 0, _d5 = 0, _d6 = 0, _d7 = 0;

  // ========== SECTION 4: Legal & Ethical ==========
  int _l1 = 0, _l2 = 0, _l3 = 0, _l4 = 0, _l5 = 0, _l6 = 0;

  // ========== SECTION 5: Review & Monitoring ==========
  int _rev1 = 0, _rev2 = 0, _rev3 = 0, _rev4 = 0, _rev5 = 0, _rev6 = 0;

  // ========== SECTION 6: Multi-Disciplinary ==========
  int _md1 = 0, _md2 = 0, _md3 = 0, _md4 = 0, _md5 = 0, _md6 = 0, _md7 = 0, _md8 = 0, _md9 = 0, _md10 = 0;

  // ========== SECTION 7: End of Life ==========
  bool _eolApplicable = false;
  int _eol1 = 0, _eol2 = 0, _eol3 = 0, _eol4 = 0, _eol5 = 0;

  // ========== SECTION 8: Format & Accessibility ==========
  int _f1 = 0, _f2 = 0, _f3 = 0, _f4 = 0, _f5 = 0;

  // ========== SECTION 9: Critical Flags ==========
  bool _cf1 = false, _cf2 = false, _cf3 = false, _cf4 = false, _cf5 = false, _cf6 = false, _cf7 = false, _cf8 = false, _cf9 = false;

  // ========== Action Plan ==========
  final _actionRequiredCtrl = TextEditingController();
  String? _actionAssignedTo;
  DateTime? _actionDeadline;
  final _actionNotesCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();

  // ========== Sign-off ==========
  final _auditorSigCtrl = TextEditingController();
  bool _clinicalLeadReviewed = false;
  final _clinicalLeadSigCtrl = TextEditingController();
  final _clinicalLeadNotesCtrl = TextEditingController();
  bool _managerReviewed = false;
  final _managerSigCtrl = TextEditingController();
  final _managerNotesCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.audit != null;
    _loadData();
    if (_isEditing) _populate();
  }

  void _populate() {
    final a = widget.audit!;
    _serviceUserId = a.serviceUserId;
    _serviceUserName = a.serviceUserName;
    _auditorName = a.auditorName;
    _auditDate = a.auditDate;
    _pc1 = a.pcWhatMattersToMe ?? 0; _pc2 = a.pcPersonalHistory ?? 0; _pc3 = a.pcCommunicationNeeds ?? 0;
    _pc4 = a.pcCulturalSpiritual ?? 0; _pc5 = a.pcSocialConnections ?? 0; _pc6 = a.pcGoalsAspirations ?? 0;
    _r1 = a.riskFalls ?? 0; _r2 = a.riskMedication ?? 0; _r3 = a.riskNutrition ?? 0;
    _r4 = a.riskPressureSores ?? 0; _r5 = a.riskContinence ?? 0; _r6 = a.riskMentalCapacity ?? 0;
    _r7 = a.riskChallengingBehaviour ?? 0; _r8 = a.riskSelfHarm ?? 0; _r9 = a.riskEpilepsy ?? 0; _r10 = a.riskDiabetes ?? 0;
    _d1 = a.deliveryDailyLiving ?? 0; _d2 = a.deliveryPersonalCare ?? 0; _d3 = a.deliveryMobility ?? 0;
    _d4 = a.deliveryMedicationSupport ?? 0; _d5 = a.deliveryMealtimes ?? 0; _d6 = a.deliverySocialActivities ?? 0; _d7 = a.deliveryNightTime ?? 0;
    _l1 = a.legalMca2005 ?? 0; _l2 = a.legalConsent ?? 0; _l3 = a.legalDols ?? 0;
    _l4 = a.legalAdvanceDecisions ?? 0; _l5 = a.legalEpr ?? 0; _l6 = a.legalDataProtection ?? 0;
    _rev1 = a.reviewFrequency ?? 0; _rev2 = a.reviewLastDate ?? 0; _rev3 = a.reviewNextDate ?? 0;
    _rev4 = a.reviewEffectiveness ?? 0; _rev5 = a.reviewChangesDocumented ?? 0; _rev6 = a.reviewIncidentIntegration ?? 0;
    _md1 = a.mdGpDetails ?? 0; _md2 = a.mdDistrictNurse ?? 0; _md3 = a.mdSpecialistNurse ?? 0;
    _md4 = a.mdPharmacist ?? 0; _md5 = a.mdOccupationalTherapist ?? 0; _md6 = a.mdPhysiotherapist ?? 0;
    _md7 = a.mdSpeechTherapy ?? 0; _md8 = a.mdDietitian ?? 0; _md9 = a.mdMentalHealth ?? 0; _md10 = a.mdFamilyCarers ?? 0;
    _eolApplicable = a.eolApplicable;
    _eol1 = a.eolPreferences ?? 0; _eol2 = a.eolCarePlan ?? 0; _eol3 = a.eolPreferredPlace ?? 0;
    _eol4 = a.eolAdvancedCarePlan ?? 0; _eol5 = a.eolDnacpr ?? 0;
    _f1 = a.formatAccessible ?? 0; _f2 = a.formatLanguage ?? 0; _f3 = a.formatLegible ?? 0;
    _f4 = a.formatSectioned ?? 0; _f5 = a.formatVersionControl ?? 0;
    _cf1 = a.criticalNoCarePlan; _cf2 = a.criticalNotReviewedAnnually; _cf3 = a.criticalMissingMca;
    _cf4 = a.criticalMissingConsent; _cf5 = a.criticalRiskNotManaged; _cf6 = a.criticalMedicationError;
    _cf7 = a.criticalSafeguardingMissing; _cf8 = a.criticalContradictoryInstructions; _cf9 = a.criticalOutdatedInformation;
    _actionRequiredCtrl.text = a.actionRequired ?? '';
    _actionAssignedTo = a.actionAssignedTo;
    _actionDeadline = a.actionDeadline;
    _actionNotesCtrl.text = a.actionNotes ?? '';
    _recommendationsCtrl.text = a.recommendations ?? '';
    _auditorSigCtrl.text = a.auditorSignature ?? '';
    _clinicalLeadReviewed = a.clinicalLeadReviewed;
    _clinicalLeadNotesCtrl.text = a.clinicalLeadNotes ?? '';
    _managerReviewed = a.registeredManagerReviewed;
    _managerNotesCtrl.text = a.registeredManagerNotes ?? '';
  }

  @override
  void dispose() {
    _actionRequiredCtrl.dispose(); _actionNotesCtrl.dispose(); _recommendationsCtrl.dispose();
    _auditorSigCtrl.dispose(); _clinicalLeadSigCtrl.dispose(); _clinicalLeadNotesCtrl.dispose();
    _managerSigCtrl.dispose(); _managerNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final users = await _service.getServiceUsers();
      final staff = await _service.getStaffUsers();
      setState(() { _serviceUsers = users; _staffUsers = staff; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  // ========== CALCULATIONS ==========

  int _pcTotal() => _pc1 + _pc2 + _pc3 + _pc4 + _pc5 + _pc6;
  int _riskTotal() => _r1 + _r2 + _r3 + _r4 + _r5 + _r6 + _r7 + _r8 + _r9 + _r10;
  int _delTotal() => _d1 + _d2 + _d3 + _d4 + _d5 + _d6 + _d7;
  int _legalTotal() => _l1 + _l2 + _l3 + _l4 + _l5 + _l6;
  int _revTotal() => _rev1 + _rev2 + _rev3 + _rev4 + _rev5 + _rev6;
  int _mdTotal() => _md1 + _md2 + _md3 + _md4 + _md5 + _md6 + _md7 + _md8 + _md9 + _md10;
  int _eolTotal() => _eolApplicable ? _eol1 + _eol2 + _eol3 + _eol4 + _eol5 : 0;
  int _fmtTotal() => _f1 + _f2 + _f3 + _f4 + _f5;

  int _totalScore() => _pcTotal() + _riskTotal() + _delTotal() + _legalTotal() + _revTotal() + _mdTotal() + _eolTotal() + _fmtTotal();
  int _maxPossible() => 12 + 18 + 14 + 12 + 12 + 20 + (_eolApplicable ? 10 : 0) + 10;
  double _percentage() => _maxPossible() > 0 ? (_totalScore() / _maxPossible()) * 100 : 0;

  bool _hasCriticalFlags() => _cf1 || _cf2 || _cf3 || _cf4 || _cf5 || _cf6 || _cf7 || _cf8 || _cf9;
  int _criticalCount() => [_cf1, _cf2, _cf3, _cf4, _cf5, _cf6, _cf7, _cf8, _cf9].where((b) => b).length;
  bool _reqAction() => _hasCriticalFlags() || _percentage() < 75;

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Loading...')), body: const Center(child: CircularProgressIndicator()));

    final pct = _percentage();
    final hasCF = _hasCriticalFlags();
    final rl = CarePlanAuditRiskHelper.calculateRiskLevel(pct, hasCF);
    final rc = CarePlanAuditRiskHelper.getRiskColor(rl);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Care Plan Audit' : 'New Care Plan Audit'), backgroundColor: const Color(0xFF1976D2)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _scoreBanner(pct, rl, rc, hasCF),
            const SizedBox(height: 12),

            // Service User
            _section('Service User'),
            if (!_isEditing) ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Service User *', border: OutlineInputBorder()),
                items: _serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String))).toList(),
                onChanged: (v) { setState(() { _serviceUserId = v; _serviceUserName = _serviceUsers.firstWhere((u) => u['id'] == v)['name']; }); },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 8),
            ] else
              Text(_serviceUserName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),

            // Section 1: Person-Centred Care
            _section('1. Person-Centred Care (CQC: Caring)'),
            _scoreItem('What matters to the person?', _pc1, (v) => _pc1 = v),
            _scoreItem('Personal history & preferences', _pc2, (v) => _pc2 = v),
            _scoreItem('Communication needs', _pc3, (v) => _pc3 = v),
            _scoreItem('Cultural/spiritual needs', _pc4, (v) => _pc4 = v),
            _scoreItem('Social connections', _pc5, (v) => _pc5 = v),
            _scoreItem('Goals & aspirations', _pc6, (v) => _pc6 = v),
            Text('Total: ${_pcTotal()}/12', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),

            // Section 2: Risk
            _section('2. Risk Assessment Integration (CQC: Safe)'),
            _scoreItem('Falls risk', _r1, (v) => _r1 = v),
            _scoreItem('Medication risk', _r2, (v) => _r2 = v),
            _scoreItem('Nutrition/MUST risk', _r3, (v) => _r3 = v),
            _scoreItem('Pressure sore/Waterlow risk', _r4, (v) => _r4 = v),
            _scoreItem('Continence risk', _r5, (v) => _r5 = v),
            _scoreItem('MCA assessment', _r6, (v) => _r6 = v),
            _scoreItem('Challenging behaviour/PBS', _r7, (v) => _r7 = v),
            _scoreItem('Self-harm risk', _r8, (v) => _r8 = v),
            _scoreItem('Epilepsy risk', _r9, (v) => _r9 = v),
            _scoreItem('Diabetes risk', _r10, (v) => _r10 = v),
            Text('Total: ${_riskTotal()}/18', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),

            // Section 3: Care Delivery
            _section('3. Care Delivery Instructions (CQC: Effective)'),
            _scoreItem('Daily living tasks', _d1, (v) => _d1 = v),
            _scoreItem('Personal care', _d2, (v) => _d2 = v),
            _scoreItem('Mobility assistance', _d3, (v) => _d3 = v),
            _scoreItem('Medication support', _d4, (v) => _d4 = v),
            _scoreItem('Mealtime support', _d5, (v) => _d5 = v),
            _scoreItem('Social/recreational activities', _d6, (v) => _d6 = v),
            _scoreItem('Night time care', _d7, (v) => _d7 = v),
            Text('Total: ${_delTotal()}/14', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),

            // Section 4: Legal & Ethical
            _section('4. Legal & Ethical Compliance'),
            _scoreItem('MCA 2005 principles', _l1, (v) => _l1 = v),
            _scoreItem('Consent documented', _l2, (v) => _l2 = v),
            _scoreItem('DoLS authorisation', _l3, (v) => _l3 = v),
            _scoreItem('Advance decisions', _l4, (v) => _l4 = v),
            _scoreItem('Emergency preparedness plan', _l5, (v) => _l5 = v),
            _scoreItem('Data protection/GDPR', _l6, (v) => _l6 = v),
            Text('Total: ${_legalTotal()}/12', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),

            // Section 5: Review & Monitoring
            _section('5. Review & Monitoring (CQC: Responsive)'),
            _scoreItem('Review frequency stated', _rev1, (v) => _rev1 = v),
            _scoreItem('Last review date recorded', _rev2, (v) => _rev2 = v),
            _scoreItem('Next review date scheduled', _rev3, (v) => _rev3 = v),
            _scoreItem('Effectiveness evaluated', _rev4, (v) => _rev4 = v),
            _scoreItem('Changes documented', _rev5, (v) => _rev5 = v),
            _scoreItem('Incidents reflected in updates', _rev6, (v) => _rev6 = v),
            Text('Total: ${_revTotal()}/12', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),

            // Section 6: Multi-Disciplinary
            _section('6. Multi-Disciplinary Working (CQC: Well-led)'),
            _scoreItem('GP details', _md1, (v) => _md1 = v),
            _scoreItem('District nurse involvement', _md2, (v) => _md2 = v),
            _scoreItem('Specialist nurses', _md3, (v) => _md3 = v),
            _scoreItem('Pharmacist review', _md4, (v) => _md4 = v),
            _scoreItem('Occupational therapist', _md5, (v) => _md5 = v),
            _scoreItem('Physiotherapist', _md6, (v) => _md6 = v),
            _scoreItem('Speech & language therapy', _md7, (v) => _md7 = v),
            _scoreItem('Dietitian', _md8, (v) => _md8 = v),
            _scoreItem('Mental health team', _md9, (v) => _md9 = v),
            _scoreItem('Family/carer involvement', _md10, (v) => _md10 = v),
            Text('Total: ${_mdTotal()}/20', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),

            // Section 7: End of Life
            _section('7. End of Life Care'),
            SwitchListTile(title: const Text('End of life care applicable?', style: TextStyle(fontSize: 13)), value: _eolApplicable, onChanged: (v) => setState(() => _eolApplicable = v)),
            if (_eolApplicable) ...[
              _scoreItem('EOL preferences documented', _eol1, (v) => _eol1 = v),
              _scoreItem('EOL care plan in place', _eol2, (v) => _eol2 = v),
              _scoreItem('Preferred place of death', _eol3, (v) => _eol3 = v),
              _scoreItem('Advanced Care Plan (ACP)', _eol4, (v) => _eol4 = v),
              _scoreItem('DNACPR decisions', _eol5, (v) => _eol5 = v),
              Text('Total: ${_eolTotal()}/10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
            const SizedBox(height: 12),

            // Section 8: Format & Accessibility
            _section('8. Format & Accessibility'),
            _scoreItem('Accessible format', _f1, (v) => _f1 = v),
            _scoreItem('Appropriate language', _f2, (v) => _f2 = v),
            _scoreItem('Legible and clear', _f3, (v) => _f3 = v),
            _scoreItem('Logically sectioned', _f4, (v) => _f4 = v),
            _scoreItem('Version control', _f5, (v) => _f5 = v),
            Text('Total: ${_fmtTotal()}/10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),

            // Section 9: Critical Compliance Flags
            _section('9. Critical Compliance Flags'),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Any flag checked sets risk to CRITICAL and requires action plan',
                      style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                  _cfItem('No care plan exists', _cf1, (v) => _cf1 = v),
                  _cfItem('Not reviewed in >12 months', _cf2, (v) => _cf2 = v),
                  _cfItem('MCA not considered where needed', _cf3, (v) => _cf3 = v),
                  _cfItem('Consent missing', _cf4, (v) => _cf4 = v),
                  _cfItem('Risk identified but no management plan', _cf5, (v) => _cf5 = v),
                  _cfItem('Medication instructions wrong/missing', _cf6, (v) => _cf6 = v),
                  _cfItem('Safeguarding concerns not addressed', _cf7, (v) => _cf7 = v),
                  _cfItem('Contradictory care instructions', _cf8, (v) => _cf8 = v),
                  _cfItem('Outdated/irrelevant information', _cf9, (v) => _cf9 = v),
                ]),
              ),
            ),
            if (_criticalCount() > 0) Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${_criticalCount()} critical flag(s) detected', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 12),

            // Section 10: Recommendations
            _section('10. Recommendations'),
            TextFormField(
              controller: _recommendationsCtrl,
              decoration: const InputDecoration(labelText: 'Summary of improvements needed', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Section 11: Action Plan
            if (_reqAction()) ...[
              _section('11. Action Plan'),
              Card(color: Colors.orange.shade50, child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                TextFormField(
                  controller: _actionRequiredCtrl,
                  decoration: const InputDecoration(labelText: 'Action Required *', border: OutlineInputBorder()),
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _actionAssignedTo,
                  decoration: const InputDecoration(labelText: 'Assign To *', border: OutlineInputBorder()),
                  items: _staffUsers.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['full_name'] as String? ?? s['email'] as String? ?? ''))).toList(),
                  onChanged: (v) => setState(() => _actionAssignedTo = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: context, initialDate: _actionDeadline ?? DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (p != null) setState(() => _actionDeadline = p);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Deadline *', border: OutlineInputBorder()),
                    child: Text(_actionDeadline != null ? DateFormat('dd MMM yyyy').format(_actionDeadline!) : 'Select date'),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(controller: _actionNotesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 2),
              ]))),
              const SizedBox(height: 12),
            ],

            // Section 12: Sign-off
            _section('12. Sign-off & Review'),
            TextFormField(
              controller: _auditorSigCtrl,
              decoration: const InputDecoration(labelText: 'Auditor Name / Signature *', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(title: const Text('Clinical Lead Reviewed', style: TextStyle(fontSize: 13)), value: _clinicalLeadReviewed, activeColor: const Color(0xFF1976D2), contentPadding: EdgeInsets.zero, onChanged: _isEditing ? (v) => setState(() => _clinicalLeadReviewed = v ?? false) : null),
            if (_clinicalLeadReviewed) ...[
              TextFormField(controller: _clinicalLeadSigCtrl, decoration: const InputDecoration(labelText: 'Clinical Lead Signature', border: OutlineInputBorder())),
              const SizedBox(height: 4),
              TextFormField(controller: _clinicalLeadNotesCtrl, decoration: const InputDecoration(labelText: 'Clinical Lead Notes', border: OutlineInputBorder()), maxLines: 2),
            ],
            const SizedBox(height: 8),
            CheckboxListTile(title: const Text('Registered Manager Reviewed', style: TextStyle(fontSize: 13)), value: _managerReviewed, activeColor: const Color(0xFF1976D2), contentPadding: EdgeInsets.zero, onChanged: _isEditing ? (v) => setState(() => _managerReviewed = v ?? false) : null),
            if (_managerReviewed) ...[
              TextFormField(controller: _managerSigCtrl, decoration: const InputDecoration(labelText: 'Manager Signature', border: OutlineInputBorder())),
              const SizedBox(height: 4),
              TextFormField(controller: _managerNotesCtrl, decoration: const InputDecoration(labelText: 'Manager Notes', border: OutlineInputBorder()), maxLines: 2),
            ],
            const SizedBox(height: 12),

            // Summary card
            _summaryCard(pct, rl, rc, hasCF),
            const SizedBox(height: 24),

            // Submit
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: _isSubmitting ? null : () => _save('draft'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Save Draft'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _isSubmitting ? null : () => _save('completed'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Audit', style: TextStyle(fontWeight: FontWeight.bold)))),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _scoreBanner(double pct, String rl, Color rc, bool hasCF) {
    return Card(color: rc.withOpacity(0.05), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      SizedBox(width: 56, height: 56, child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: pct / 100, strokeWidth: 4, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(rc)),
        Text('${pct.round()}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: rc)),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(CarePlanAuditRiskHelper.getRiskIcon(rl), size: 16, color: rc), const SizedBox(width: 4), Text(CarePlanAuditRiskHelper.getRiskLabel(rl), style: TextStyle(color: rc, fontWeight: FontWeight.bold, fontSize: 14))]),
        if (hasCF) const Text('⚠️ Critical compliance flags', style: TextStyle(color: Colors.red, fontSize: 11)),
      ])),
      if (_reqAction()) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('Action Needed', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))),
    ])));
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))));

  Widget _scoreItem(String label, int val, ValueChanged<int> onChange) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      SizedBox(width: 120, child: Row(children: [0, 1, 2].map((s) {
        final colors = [Colors.red, Colors.orange, Colors.green];
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => onChange(s)),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 6), margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: val == s ? colors[s].withOpacity(0.2) : Colors.grey.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: val == s ? colors[s] : Colors.grey.shade300)),
            child: Center(child: Text('$s', style: TextStyle(fontSize: 12, fontWeight: val == s ? FontWeight.bold : FontWeight.normal, color: val == s ? colors[s] : Colors.grey))),
          ),
        ));
      }).toList())),
    ]));
  }

  Widget _cfItem(String label, bool val, ValueChanged<bool> onChange) {
    return CheckboxListTile(title: Text(label, style: const TextStyle(fontSize: 12)), value: val, dense: true, activeColor: Colors.red, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.trailing, onChanged: (v) => setState(() => onChange(v ?? false)));
  }

  Widget _summaryCard(double pct, String rl, Color rc, bool hasCF) {
    return Card(color: rc.withOpacity(0.05), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Audit Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const Divider(),
      _sumRow('Person-Centred Care', '${_pcTotal()}/12', null),
      _sumRow('Risk Integration', '${_riskTotal()}/18', null),
      _sumRow('Care Delivery', '${_delTotal()}/14', null),
      _sumRow('Legal & Ethical', '${_legalTotal()}/12', null),
      _sumRow('Review & Monitoring', '${_revTotal()}/12', null),
      _sumRow('Multi-Disciplinary', '${_mdTotal()}/20', null),
      if (_eolApplicable) _sumRow('End of Life', '${_eolTotal()}/10', null),
      _sumRow('Format & Accessibility', '${_fmtTotal()}/10', null),
      const Divider(),
      _sumRow('Total Score', '${_totalScore()}/${_maxPossible()}', rc),
      _sumRow('Percentage', '${pct.toStringAsFixed(1)}%', rc),
      _sumRow('Risk Level', CarePlanAuditRiskHelper.getRiskBadge(rl), rc),
      if (hasCF) ...[
        const Divider(),
        const Text('⚠️ Critical Compliance Flags', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
        if (_cf1) const Text('  • No care plan exists', style: TextStyle(color: Colors.red, fontSize: 11)),
        if (_cf2) const Text('  • Not reviewed annually', style: TextStyle(color: Colors.red, fontSize: 11)),
        if (_cf3) const Text('  • MCA not considered', style: TextStyle(color: Colors.red, fontSize: 11)),
        if (_cf4) const Text('  • Consent missing', style: TextStyle(color: Colors.red, fontSize: 11)),
        if (_cf5) const Text('  • Risk not managed', style: TextStyle(color: Colors.red, fontSize: 11)),
        if (_cf6) const Text('  • Medication errors', style: TextStyle(color: Colors.red, fontSize: 11)),
        if (_cf7) const Text('  • Safeguarding missing', style: TextStyle(color: Colors.red, fontSize: 11)),
        if (_cf8) const Text('  • Contradictory instructions', style: TextStyle(color: Colors.red, fontSize: 11)),
        if (_cf9) const Text('  • Outdated information', style: TextStyle(color: Colors.red, fontSize: 11)),
      ],
      if (_reqAction()) ...[const Divider(), const Text('⚠️ Action Required', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12))],
    ])));
  }

  Widget _sumRow(String l, String v, Color? c) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [Expanded(child: Text(l, style: const TextStyle(fontSize: 12))), Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c))]));

  Future<void> _save(String status) async {
    if (!_formKey.currentState!.validate()) return;
    if (_serviceUserId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service user'))); return; }
    if (_auditorSigCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auditor signature required'))); return; }

    setState(() => _isSubmitting = true);
    try {
      final pct = _percentage();
      final hasCF = _hasCriticalFlags();
      final rl = CarePlanAuditRiskHelper.calculateRiskLevel(pct, hasCF);
      final reqAct = _reqAction();
      final cfCount = _criticalCount();
      final cfDetails = [
        if (_cf1) 'No care plan exists', if (_cf2) 'Not reviewed annually', if (_cf3) 'MCA not considered',
        if (_cf4) 'Consent missing', if (_cf5) 'Risk not managed', if (_cf6) 'Medication errors',
        if (_cf7) 'Safeguarding missing', if (_cf8) 'Contradictory instructions', if (_cf9) 'Outdated information',
      ].join('; ');

      final audit = CarePlanAudit(
        id: widget.audit?.id,
        serviceUserId: _serviceUserId!,
        serviceUserName: _serviceUserName ?? '',
        auditDate: _auditDate,
        auditorName: _auditorName,
        auditorId: Supabase.instance.client.auth.currentUser?.id,
        pcWhatMattersToMe: _pc1, pcPersonalHistory: _pc2, pcCommunicationNeeds: _pc3,
        pcCulturalSpiritual: _pc4, pcSocialConnections: _pc5, pcGoalsAspirations: _pc6,
        riskFalls: _r1, riskMedication: _r2, riskNutrition: _r3, riskPressureSores: _r4,
        riskContinence: _r5, riskMentalCapacity: _r6, riskChallengingBehaviour: _r7,
        riskSelfHarm: _r8, riskEpilepsy: _r9, riskDiabetes: _r10,
        deliveryDailyLiving: _d1, deliveryPersonalCare: _d2, deliveryMobility: _d3,
        deliveryMedicationSupport: _d4, deliveryMealtimes: _d5, deliverySocialActivities: _d6, deliveryNightTime: _d7,
        legalMca2005: _l1, legalConsent: _l2, legalDols: _l3, legalAdvanceDecisions: _l4, legalEpr: _l5, legalDataProtection: _l6,
        reviewFrequency: _rev1, reviewLastDate: _rev2, reviewNextDate: _rev3, reviewEffectiveness: _rev4,
        reviewChangesDocumented: _rev5, reviewIncidentIntegration: _rev6,
        mdGpDetails: _md1, mdDistrictNurse: _md2, mdSpecialistNurse: _md3, mdPharmacist: _md4,
        mdOccupationalTherapist: _md5, mdPhysiotherapist: _md6, mdSpeechTherapy: _md7, mdDietitian: _md8,
        mdMentalHealth: _md9, mdFamilyCarers: _md10,
        eolApplicable: _eolApplicable, eolPreferences: _eol1, eolCarePlan: _eol2, eolPreferredPlace: _eol3,
        eolAdvancedCarePlan: _eol4, eolDnacpr: _eol5,
        formatAccessible: _f1, formatLanguage: _f2, formatLegible: _f3, formatSectioned: _f4, formatVersionControl: _f5,
        criticalNoCarePlan: _cf1, criticalNotReviewedAnnually: _cf2, criticalMissingMca: _cf3,
        criticalMissingConsent: _cf4, criticalRiskNotManaged: _cf5, criticalMedicationError: _cf6,
        criticalSafeguardingMissing: _cf7, criticalContradictoryInstructions: _cf8, criticalOutdatedInformation: _cf9,
        pcTotalScore: _pcTotal(),
        riskMaxPossible: 18, deliveryTotalScore: _delTotal(), legalTotalScore: _legalTotal(),
        reviewTotalScore: _revTotal(), mdTotalScore: _mdTotal(), eolTotalScore: _eolTotal(), formatTotalScore: _fmtTotal(),
        totalScore: _totalScore(), maxPossibleScore: _maxPossible(), overallPercentage: pct, riskLevel: rl,
        criticalFlagsPresent: hasCF, criticalFlagsCount: cfCount, criticalFlagsDetails: cfDetails.isNotEmpty ? cfDetails : null,
        requiresAction: reqAct, actionRequired: reqAct ? _actionRequiredCtrl.text : null,
        actionAssignedTo: reqAct ? _actionAssignedTo : null, actionDeadline: reqAct ? _actionDeadline : null,
        actionNotes: _actionNotesCtrl.text.isNotEmpty ? _actionNotesCtrl.text : null,
        recommendations: _recommendationsCtrl.text.isNotEmpty ? _recommendationsCtrl.text : null,
        auditorSignature: _auditorSigCtrl.text.trim(),
        clinicalLeadReviewed: _clinicalLeadReviewed, clinicalLeadNotes: _clinicalLeadNotesCtrl.text.isNotEmpty ? _clinicalLeadNotesCtrl.text : null,
        registeredManagerReviewed: _managerReviewed, registeredManagerNotes: _managerNotesCtrl.text.isNotEmpty ? _managerNotesCtrl.text : null,
        status: reqAct && status == 'completed' ? 'action_required' : status,
        createdAt: widget.audit?.createdAt ?? DateTime.now(), updatedAt: DateTime.now(),
      );

      if (widget.audit?.id != null) await _service.updateAudit(widget.audit!.id!, audit);
      else await _service.createAudit(audit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'completed' ? 'Audit submitted' : 'Draft saved'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _isSubmitting = false); }
  }
}