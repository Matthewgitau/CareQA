import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/spot_check.dart';
import 'package:admin_app/services/spot_check_service.dart';

class SpotCheckScreen extends StatefulWidget {
  const SpotCheckScreen({super.key});
  @override
  State<SpotCheckScreen> createState() => _SpotCheckScreenState();
}

class _SpotCheckScreenState extends State<SpotCheckScreen> {
  final _service = SpotCheckService(Supabase.instance.client);

  List<Map<String, dynamic>> _serviceUsers = [];
  List<Map<String, dynamic>> _carers = [];
  String? _filterServiceUserId;
  String? _filterCarerId;
  String _filterRating = 'all';
  String _filterStatus = 'all';

  List<SpotCheck> _spotChecks = [];
  bool _isLoading = true;

  final _ratingOptions = ['all', 'exceeds_expectations', 'meets_expectations', 'requires_improvement', 'unsatisfactory', 'immediate_action'];
  final _statusOptions = ['all', 'draft', 'completed', 'carer_acknowledged', 'action_required', 'closed'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCarers();
    _loadData();
  }

  Future<void> _loadUsers() async {
    try { final u = await _service.getServiceUsers(); setState(() => _serviceUsers = u); } catch (_) {}
  }

  Future<void> _loadCarers() async {
    try { final c = await _service.getCarers(); setState(() => _carers = c); } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getSpotChecks(
        serviceUserId: _filterServiceUserId, carerId: _filterCarerId,
        competencyRating: _filterRating, status: _filterStatus,
      );
      setState(() { _spotChecks = data; _isLoading = false; });
    } catch (_) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spot Checks'), backgroundColor: const Color(0xFF1976D2)),
      body: Column(children: [_buildFilter(), const Divider(height: 1), Expanded(child: _buildList())]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilter() {
    return Container(padding: const EdgeInsets.all(8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      SizedBox(width: 160, child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Service User', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), isDense: true),
        items: [const DropdownMenuItem(value: null, child: Text('All')), ..._serviceUsers.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String, overflow: TextOverflow.ellipsis)))],
        onChanged: (v) { setState(() => _filterServiceUserId = v); _loadData(); },
      )),
      const SizedBox(width: 8),
      SizedBox(width: 160, child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Carer', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), isDense: true),
        items: [const DropdownMenuItem(value: null, child: Text('All')), ..._carers.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String, overflow: TextOverflow.ellipsis)))],
        onChanged: (v) { setState(() => _filterCarerId = v); _loadData(); },
      )),
      const SizedBox(width: 8),
      SizedBox(width: 130, child: DropdownButtonFormField<String>(
        value: _filterRating, decoration: const InputDecoration(labelText: 'Rating', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), isDense: true),
        items: _ratingOptions.map((r) => DropdownMenuItem(value: r, child: Text(r == 'all' ? 'All' : SpotCheckHelper.getRatingBadge(r)))).toList(),
        onChanged: (v) { setState(() => _filterRating = v!); _loadData(); },
      )),
      const SizedBox(width: 8),
      SizedBox(width: 130, child: DropdownButtonFormField<String>(
        value: _filterStatus, decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), isDense: true),
        items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s == 'all' ? 'All' : s.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')))).toList(),
        onChanged: (v) { setState(() => _filterStatus = v!); _loadData(); },
      )),
    ])));
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_spotChecks.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search, size: 64, color: Colors.grey), SizedBox(height: 16),
      Text('No spot checks found', style: TextStyle(color: Colors.grey, fontSize: 16)),
    ]));
    return RefreshIndicator(onRefresh: _loadData, child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: _spotChecks.length, itemBuilder: (_, i) => _buildCard(_spotChecks[i])));
  }

  Widget _buildCard(SpotCheck sc) {
    final rc = SpotCheckHelper.getRatingColor(sc.competencyRating);
    final pct = sc.overallPercentage ?? 0;
    return Card(margin: const EdgeInsets.symmetric(vertical: 4), child: InkWell(
      onTap: () => _navigateToForm(spotCheck: sc),
      child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: rc.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: rc, width: 2)),
          child: Center(child: Text('${pct.round()}%', style: TextStyle(color: rc, fontWeight: FontWeight.bold, fontSize: 13)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(sc.serviceUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(width: 8),
            Text(sc.spotCheckNumber ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 11))]),
          Text('${sc.carerName} • ${DateFormat('dd MMM').format(sc.spotCheckDate)} ${sc.spotCheckTime}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: rc.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(SpotCheckHelper.getRatingIcon(sc.competencyRating), size: 12, color: rc), const SizedBox(width: 2),
                Text(SpotCheckHelper.getRatingBadge(sc.competencyRating), style: TextStyle(color: rc, fontSize: 10, fontWeight: FontWeight.bold)),
              ])),
          ]),
        ])),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ])),
    ));
  }

  Future<void> _navigateToForm({SpotCheck? spotCheck}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SpotCheckFormView(spotCheck: spotCheck)),
    );
    _loadData();
  }
}

class SpotCheckFormView extends StatefulWidget {
  final SpotCheck? spotCheck;
  const SpotCheckFormView({super.key, this.spotCheck});
  @override
  State<SpotCheckFormView> createState() => _SpotCheckFormViewState();
}

class _SpotCheckFormViewState extends State<SpotCheckFormView> {
  final _formKey = GlobalKey<FormState>();
  final _service = SpotCheckService(Supabase.instance.client);

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _carers = [];
  List<Map<String, dynamic>> _adminStaff = [];
  bool _loading = true;
  bool _isEditing = false;

  String? _serviceUserId; String? _serviceUserName; DateTime? _serviceUserDob;
  String? _carerId; String? _carerName; String? _carerRole;
  String _carerEmploymentType = 'Permanent';
  DateTime _date = DateTime.now(); TimeOfDay _time = TimeOfDay.now();
  int? _duration; String _type = 'unannounced'; String? _reason;
  String? _otherReason;
  String _conductedByName = Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Auditor';
  String _conductedByRole = 'QA Officer';
  bool _witnessPresent = false; String? _witnessName; String? _witnessRole;

  // All 0-5 ratings
  int _p1=0,_p2=0,_p3=0,_p4=0,_p5=0,_p6=0;
  int _i1=0,_i2=0,_i3=0,_i4=0,_i5=0,_i6=0;
  int _sg1=0,_sg2=0,_sg3=0,_sg4=0,_sg5=0,_sg6=0,_sg7=0,_sg8=0,_sg9=0;
  int _c1=0,_c2=0,_c3=0,_c4=0,_c5=0,_c6=0,_c7=0;
  int _s1=0,_s2=0,_s3=0,_s4=0,_s5=0,_s6=0;
  int _cm1=0,_cm2=0,_cm3=0,_cm4=0,_cm5=0;
  int _pf1=0,_pf2=0,_pf3=0,_pf4=0,_pf5=0,_pf6=0;

  bool _f1=false,_f2=false,_f3=false,_f4=false,_f5=false,_f6=false,_f7=false,_f8=false,_f9=false;

  final _strengthsCtrl = TextEditingController();
  final _afiCtrl = TextEditingController();
  final _concernsCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _actionReqCtrl = TextEditingController();
  final _actionNotesCtrl = TextEditingController();
  String? _actionAssignedTo; DateTime? _actionDeadline;
  bool _followUpReq = false; DateTime? _followUpDate; String _followUpType = 're_observation';
  final _auditorSigCtrl = TextEditingController();
  bool _carerAcknowledged = false; final _carerCommentsCtrl = TextEditingController();
  bool _managerReviewed = false; final _managerNotesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.spotCheck != null;
    _loadDropdowns();
    if (_isEditing) _populate();
  }

  void _populate() {
    final s = widget.spotCheck!;
    _serviceUserId = s.serviceUserId; _serviceUserName = s.serviceUserName; _serviceUserDob = s.serviceUserDob;
    _carerId = s.carerId; _carerName = s.carerName; _carerRole = s.carerRole; _carerEmploymentType = s.carerEmploymentType ?? 'Permanent';
    _date = s.spotCheckDate; _time = TimeOfDay(hour: int.tryParse(s.spotCheckTime.split(':').first) ?? 0, minute: int.tryParse(s.spotCheckTime.split(':').last) ?? 0);
    _duration = s.spotCheckDurationMinutes; _type = s.spotCheckType; _reason = s.spotCheckReason;
    _conductedByName = s.conductedByName; _conductedByRole = s.conductedByRole ?? 'QA Officer';
    _witnessPresent = s.witnessPresent; _witnessName = s.witnessName; _witnessRole = s.witnessRole;
    _p1=s.prepHandoverReviewed??0;_p2=s.prepMedicationChecked??0;_p3=s.prepEquipmentReady??0;_p4=s.arrivalPunctuality??0;_p5=s.arrivalPresentation??0;_p6=s.arrivalCommunication??0;
    _i1=s.icHandHygiene??0;_i2=s.icPpeWorn??0;_i3=s.icPpeChanged??0;_i4=s.icEquipmentCleanliness??0;_i5=s.icEnvironmentHygiene??0;_i6=s.icWasteDisposal??0;
    _sg1=s.interactionGreeting??0;_sg2=s.interactionConsent??0;_sg3=s.interactionDignity??0;_sg4=s.interactionPrivacy??0;_sg5=s.interactionCommunication??0;
    _sg6=s.interactionHearingListening??0;_sg7=s.interactionChoicePromoted??0;_sg8=s.interactionCapacityConsidered??0;_sg9=s.interactionEmotionalSupport??0;
    _c1=s.careFollowsCarePlan??0;_c2=s.carePersonalCareQuality??0;_c3=s.careMobilityAssistance??0;_c4=s.careMedicationAdministration??0;_c5=s.careNutritionHydration??0;_c6=s.careDocumentation??0;_c7=s.careHandoverCommunication??0;
    _s1=s.safetyRiskAssessment??0;_s2=s.safetyEnvironmentCheck??0;_s3=s.safetyMovingHandling??0;_s4=s.safetyEmergencyKnowledge??0;_s5=s.safetyMedicationSecurity??0;_s6=s.safetyChallengingBehaviour??0;
    _cm1=s.commDailyNoteQuality??0;_cm2=s.commIncidentReporting??0;_cm3=s.commFamilyCommunication??0;_cm4=s.commOtherProfessionals??0;_cm5=s.commEscalationAwareness??0;
    _pf1=s.profCodeOfConduct??0;_pf2=s.profMedicationKnowledge??0;_pf3=s.profSafeguardingKnowledge??0;_pf4=s.profDataProtection??0;_pf5=s.profTeamWorking??0;_pf6=s.profFeedbackReceptiveness??0;
    _f1=s.flagMedicationError;_f2=s.flagInfectionBreach;_f3=s.flagDignityBreach;_f4=s.flagSafeguardingConcern;_f5=s.flagUnauthorizedAbsence;_f6=s.flagUntrainedTask;_f7=s.flagFalsifiedRecords;_f8=s.flagRefusedCare;_f9=s.flagAggressiveBehaviour;
    _strengthsCtrl.text=s.strengths??'';_afiCtrl.text=s.areasForImprovement??'';_concernsCtrl.text=s.immediateConcerns??'';_observationsCtrl.text=s.additionalObservations??'';
    _actionReqCtrl.text=s.actionRequired??'';_actionAssignedTo=s.actionAssignedTo;_actionDeadline=s.actionDeadline;_actionNotesCtrl.text=s.actionNotes??'';
    _followUpReq=s.followUpRequired;_followUpDate=s.followUpDate;_followUpType=s.followUpType??'re_observation';
    _auditorSigCtrl.text=s.auditorSignature;_carerAcknowledged=s.carerAcknowledged;_carerCommentsCtrl.text=s.carerComments??'';
    _managerReviewed=s.managerReviewed;_managerNotesCtrl.text=s.managerNotes??'';
  }

  @override
  void dispose() {
    _strengthsCtrl.dispose();_afiCtrl.dispose();_concernsCtrl.dispose();_observationsCtrl.dispose();
    _actionReqCtrl.dispose();_actionNotesCtrl.dispose();_auditorSigCtrl.dispose();_carerCommentsCtrl.dispose();_managerNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final u = await _service.getServiceUsers();
      final c = await _service.getCarers();
      final a = await _service.getAdminStaff();
      setState(() { _users = u; _carers = c; _adminStaff = a; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  int _totalScore() => [
    _p1,_p2,_p3,_p4,_p5,_p6,_i1,_i2,_i3,_i4,_i5,_i6,
    _sg1,_sg2,_sg3,_sg4,_sg5,_sg6,_sg7,_sg8,_sg9,
    _c1,_c2,_c3,_c4,_c5,_c6,_c7,
    _s1,_s2,_s3,_s4,_s5,_s6,
    _cm1,_cm2,_cm3,_cm4,_cm5,
    _pf1,_pf2,_pf3,_pf4,_pf5,_pf6,
  ].fold(0, (a, b) => a + b);

  double _pct() => (_totalScore() / 240.0) * 100;
  bool _hasFlags() => _f1||_f2||_f3||_f4||_f5||_f6||_f7||_f8||_f9;
  bool _reqAction() => _hasFlags() || _pct() < 70;

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Loading...')), body: const Center(child: CircularProgressIndicator()));

    final pct = _pct(); final hf = _hasFlags(); final rl = SpotCheckHelper.calcRating(pct, hf); final rc = SpotCheckHelper.getRatingColor(rl);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Spot Check' : 'New Spot Check'), backgroundColor: const Color(0xFF1976D2)),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
        _scoreBanner(pct, rl, rc, hf), const SizedBox(height: 12),
        _section('Basic Information'),
        if (!_isEditing) ...[
          DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Service User *', border: OutlineInputBorder()),
            items: _users.map((u) => DropdownMenuItem(value: u['id'] as String, child: Text(u['name'] as String))).toList(),
            onChanged: (v) { final u = _users.firstWhere((x) => x['id'] == v); setState(() { _serviceUserId = v; _serviceUserName = u['name']; }); },
            validator: (v) => v == null ? 'Required' : null),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Carer *', border: OutlineInputBorder()),
            items: _carers.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
            onChanged: (v) { final c = _carers.firstWhere((x) => x['id'] == v); setState(() { _carerId = v; _carerName = c['name']; _carerRole = c['role']; }); },
            validator: (v) => v == null ? 'Required' : null),
          const SizedBox(height: 8),
        ] else Text('${_serviceUserName ?? ''} → ${_carerName ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),

        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder(), isDense: true),
            items: ['announced','unannounced','follow_up'].map((t) => DropdownMenuItem(value: t, child: Text(t.split('_').map((w) => w[0].toUpperCase()+w.substring(1)).join(' ')))).toList(),
            onChanged: (v) => setState(() => _type = v!))),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder(), isDense: true),
            value: _reason, items: ['routine','concern_follow_up','new_staff','complaint','other'].map((r) => DropdownMenuItem(value: r, child: Text(r.split('_').map((w) => w[0].toUpperCase()+w.substring(1)).join(' ')))).toList(),
            onChanged: (v) => setState(() => _reason = v))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => _date = d); },
            child: InputDecorator(decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()), child: Text(DateFormat('dd MMM yyyy').format(_date))))),
          const SizedBox(width: 8),
          Expanded(child: InkWell(onTap: () async { final t = await showTimePicker(context: context, initialTime: _time); if (t != null) setState(() => _time = t); },
            child: InputDecorator(decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()), child: Text('${_time.hour.toString().padLeft(2,'0')}:${_time.minute.toString().padLeft(2,'0')}')))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Duration (min)', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number,
            initialValue: _duration?.toString(), onChanged: (v) => _duration = int.tryParse(v))),
        ]),
        const SizedBox(height: 16),

        // Rating sections
        _section('1. Preparation & Arrival'),
        _scoreItem('Handover/care plan reviewed', _p1,(v)=>_p1=v),
        _scoreItem('MAR chart/medication checked', _p2,(v)=>_p2=v),
        _scoreItem('Equipment ready', _p3,(v)=>_p3=v),
        _scoreItem('Punctuality', _p4,(v)=>_p4=v),
        _scoreItem('Professional appearance', _p5,(v)=>_p5=v),
        _scoreItem('Greeting & introduction', _p6,(v)=>_p6=v),
        Text('Total: ${_p1+_p2+_p3+_p4+_p5+_p6}/30', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),

        _section('2. Infection Control & PPE'),
        _scoreItem('Hand hygiene', _i1,(v)=>_i1=v),_scoreItem('PPE worn', _i2,(v)=>_i2=v),_scoreItem('PPE changed between tasks', _i3,(v)=>_i3=v),
        _scoreItem('Equipment cleanliness', _i4,(v)=>_i4=v),_scoreItem('Work area hygiene', _i5,(v)=>_i5=v),_scoreItem('Waste disposal', _i6,(v)=>_i6=v),
        Text('Total: ${_i1+_i2+_i3+_i4+_i5+_i6}/30', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),

        _section('3. Service User Interaction'),
        _scoreItem('Respectful greeting',_sg1,(v)=>_sg1=v),_scoreItem('Obtained consent',_sg2,(v)=>_sg2=v),
        _scoreItem('Maintained dignity',_sg3,(v)=>_sg3=v),_scoreItem('Privacy respected',_sg4,(v)=>_sg4=v),
        _scoreItem('Communication (tone/pacing)',_sg5,(v)=>_sg5=v),_scoreItem('Active listening',_sg6,(v)=>_sg6=v),
        _scoreItem('Choice promoted',_sg7,(v)=>_sg7=v),_scoreItem('MCA principles',_sg8,(v)=>_sg8=v),
        _scoreItem('Empathy & reassurance',_sg9,(v)=>_sg9=v),
        Text('Total: ${_sg1+_sg2+_sg3+_sg4+_sg5+_sg6+_sg7+_sg8+_sg9}/45', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),

        _section('4. Care Delivery'),
        _scoreItem('Follows care plan',_c1,(v)=>_c1=v),_scoreItem('Personal care quality',_c2,(v)=>_c2=v),
        _scoreItem('Mobility assistance',_c3,(v)=>_c3=v),_scoreItem('Medication administration',_c4,(v)=>_c4=v),
        _scoreItem('Nutrition/hydration support',_c5,(v)=>_c5=v),_scoreItem('Documentation',_c6,(v)=>_c6=v),
        _scoreItem('Handover communication',_c7,(v)=>_c7=v),
        Text('Total: ${_c1+_c2+_c3+_c4+_c5+_c6+_c7}/35', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),

        _section('5. Safety & Risk Management'),
        _scoreItem('Risk assessments followed',_s1,(v)=>_s1=v),_scoreItem('Environmental hazards',_s2,(v)=>_s2=v),
        _scoreItem('Moving & handling',_s3,(v)=>_s3=v),_scoreItem('Emergency procedures',_s4,(v)=>_s4=v),
        _scoreItem('Medication security',_s5,(v)=>_s5=v),_scoreItem('Challenging behaviour',_s6,(v)=>_s6=v),
        Text('Total: ${_s1+_s2+_s3+_s4+_s5+_s6}/30', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),

        _section('6. Communication & Recording'),
        _scoreItem('Daily note quality',_cm1,(v)=>_cm1=v),_scoreItem('Incident reporting',_cm2,(v)=>_cm2=v),
        _scoreItem('Family communication',_cm3,(v)=>_cm3=v),_scoreItem('Professional communication',_cm4,(v)=>_cm4=v),
        _scoreItem('Escalation awareness',_cm5,(v)=>_cm5=v),
        Text('Total: ${_cm1+_cm2+_cm3+_cm4+_cm5}/25', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),

        _section('7. Compliance & Professionalism'),
        _scoreItem('Code of conduct',_pf1,(v)=>_pf1=v),_scoreItem('Medication knowledge',_pf2,(v)=>_pf2=v),
        _scoreItem('Safeguarding knowledge',_pf3,(v)=>_pf3=v),_scoreItem('Data protection',_pf4,(v)=>_pf4=v),
        _scoreItem('Team working',_pf5,(v)=>_pf5=v),_scoreItem('Feedback receptiveness',_pf6,(v)=>_pf6=v),
        Text('Total: ${_pf1+_pf2+_pf3+_pf4+_pf5+_pf6}/30', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),

        // Critical flags
        _section('8. Critical Safety Flags'),
        Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
          const Text('Any flag checked → Immediate Action Required', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          _flagItem('Medication error observed',_f1,(v)=>_f1=v),_flagItem('Infection control breach',_f2,(v)=>_f2=v),
          _flagItem('Dignity/respect breach',_f3,(v)=>_f3=v),_flagItem('Safeguarding concern',_f4,(v)=>_f4=v),
          _flagItem('Unauthorised absence',_f5,(v)=>_f5=v),_flagItem('Untrained task performed',_f6,(v)=>_f6=v),
          _flagItem('False/misleading documentation',_f7,(v)=>_f7=v),_flagItem('Refused care task',_f8,(v)=>_f8=v),
          _flagItem('Aggressive behaviour',_f9,(v)=>_f9=v),
        ]))),

        // Findings
        _section('9. Findings & Observations'),
        TextFormField(controller:_strengthsCtrl, decoration: const InputDecoration(labelText:'Strengths (what went well)', border: OutlineInputBorder()), maxLines: 2),
        const SizedBox(height: 8),
        TextFormField(controller:_afiCtrl, decoration: const InputDecoration(labelText:'Areas for improvement', border: OutlineInputBorder()), maxLines: 2),
        const SizedBox(height: 8),
        TextFormField(controller:_concernsCtrl, decoration: const InputDecoration(labelText:'Immediate concerns', border: OutlineInputBorder()), maxLines: 2),
        const SizedBox(height: 8),
        TextFormField(controller:_observationsCtrl, decoration: const InputDecoration(labelText:'Additional observations', border: OutlineInputBorder()), maxLines: 2),

        // Action plan
        if (_reqAction()) ...[
          _section('10. Action Plan'),
          Card(color: Colors.orange.shade50, child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
            TextFormField(controller:_actionReqCtrl, decoration: const InputDecoration(labelText:'Action Required *', border: OutlineInputBorder()), maxLines: 2, validator:(v)=>v!.isEmpty?'Required':null),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value:_actionAssignedTo, decoration: const InputDecoration(labelText:'Assign To *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.admin_panel_settings)),
              items: _adminStaff.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name']?.toString() ?? s['email']?.toString() ?? 'Unknown'))).toList(),
              onChanged:(v)=>setState(()=>_actionAssignedTo=v), validator:(v)=>v==null?'Required':null),
            const SizedBox(height: 8),
            InkWell(onTap:()async{final p=await showDatePicker(context:context,initialDate:_actionDeadline??DateTime.now().add(const Duration(days:7)),firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:365)));if(p!=null)setState(()=>_actionDeadline=p);},
              child:InputDecorator(decoration:const InputDecoration(labelText:'Deadline *', border:OutlineInputBorder()),child:Text(_actionDeadline!=null?DateFormat('dd MMM yyyy').format(_actionDeadline!):'Select date'))),
            const SizedBox(height: 8),
            TextFormField(controller:_actionNotesCtrl, decoration: const InputDecoration(labelText:'Notes', border: OutlineInputBorder()), maxLines: 2),
          ]))),
        ],

        // Follow-up
        _section('11. Follow-up'),
        SwitchListTile(title: const Text('Follow-up required?', style: TextStyle(fontSize: 13)), value: _followUpReq, onChanged: (v) => setState(() => _followUpReq = v)),
        if (_followUpReq) ...[
          InkWell(onTap:()async{final p=await showDatePicker(context:context,initialDate:_followUpDate??DateTime.now().add(const Duration(days:14)),firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:365)));if(p!=null)setState(()=>_followUpDate=p);},
            child:InputDecorator(decoration:const InputDecoration(labelText:'Follow-up Date', border:OutlineInputBorder()),child:Text(_followUpDate!=null?DateFormat('dd MMM yyyy').format(_followUpDate!):'Select date'))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: _followUpType, decoration: const InputDecoration(labelText:'Type', border:OutlineInputBorder()),
            items:['re_observation','supervision','training','disciplinary'].map((t)=>DropdownMenuItem(value:t,child:Text(t.split('_').map((w)=>w[0].toUpperCase()+w.substring(1)).join(' ')))).toList(),
            onChanged:(v)=>setState(()=>_followUpType=v!)),
        ],

        // Sign-off
        _section('12. Sign-off'),
        TextFormField(controller:_auditorSigCtrl, decoration: const InputDecoration(labelText:'Auditor Signature *', border:OutlineInputBorder()), validator:(v)=>v!.isEmpty?'Required':null),
        const SizedBox(height: 8),
        CheckboxListTile(title: const Text('Carer has acknowledged findings', style: TextStyle(fontSize: 13)), value: _carerAcknowledged, activeColor: const Color(0xFF1976D2), contentPadding: EdgeInsets.zero,
          onChanged: _isEditing ? (v) => setState(() => _carerAcknowledged = v ?? false) : null),
        if (_carerAcknowledged) TextFormField(controller:_carerCommentsCtrl, decoration: const InputDecoration(labelText:'Carer comments', border:OutlineInputBorder()), maxLines: 2),
        const SizedBox(height: 8),
        CheckboxListTile(title: const Text('Manager reviewed', style: TextStyle(fontSize: 13)), value: _managerReviewed, activeColor: const Color(0xFF1976D2), contentPadding: EdgeInsets.zero,
          onChanged: _isEditing ? (v) => setState(() => _managerReviewed = v ?? false) : null),
        if (_managerReviewed) TextFormField(controller:_managerNotesCtrl, decoration: const InputDecoration(labelText:'Manager notes', border:OutlineInputBorder()), maxLines: 2),

        // Summary
        _summaryCard(pct, rl, rc, hf),
        const SizedBox(height: 24),

        Row(children: [
          Expanded(child: ElevatedButton(onPressed: _isSubmitting ? null : () => _save('draft'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Save Draft'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: _isSubmitting ? null : () => _save('completed'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: _isSubmitting ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)))),
        ]),
        const SizedBox(height: 32),
      ])),
    );
  }

  Widget _scoreBanner(double pct, String rl, Color rc, bool hf) {
    return Card(color: rc.withOpacity(0.05), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      SizedBox(width:56,height:56,child:Stack(alignment:Alignment.center,children:[CircularProgressIndicator(value:pct/100,strokeWidth:4,backgroundColor:Colors.grey.shade200,valueColor:AlwaysStoppedAnimation<Color>(rc)),Text('${pct.round()}%',style:TextStyle(fontWeight:FontWeight.bold,fontSize:14,color:rc))])),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(SpotCheckHelper.getRatingIcon(rl),size:16,color:rc),const SizedBox(width:4),Text(SpotCheckHelper.getRatingLabel(rl),style:TextStyle(color:rc,fontWeight:FontWeight.bold,fontSize:14))]),
        if(hf) const Text('⚠️ Critical safety flags', style: TextStyle(color: Colors.red, fontSize: 11)),
      ])),
      if(_reqAction()) Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:Colors.red.withOpacity(0.1),borderRadius:BorderRadius.circular(4)),child:const Text('Action Needed',style:TextStyle(color:Colors.red,fontSize:10,fontWeight:FontWeight.bold))),
    ])));
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))));

  Widget _scoreItem(String label, int val, ValueChanged<int> onChange) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      SizedBox(width: 180, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(6, (i) {
        final c = SpotCheckHelper.ratingColors[i];
        return GestureDetector(onTap: () => setState(() => onChange(i)),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5), margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: val == i ? c.withOpacity(0.2) : Colors.grey.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: val == i ? c : Colors.grey.shade300)),
            child: Text('$i', style: TextStyle(fontSize: 11, fontWeight: val == i ? FontWeight.bold : FontWeight.normal, color: val == i ? c : Colors.grey))),
        );
      })))),
    ]));
  }

  Widget _flagItem(String label, bool val, ValueChanged<bool> onChange) {
    return CheckboxListTile(title: Text(label, style: const TextStyle(fontSize: 12)), value: val, dense: true, activeColor: Colors.red, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.trailing, onChanged: (v) => setState(() => onChange(v ?? false)));
  }

  Widget _summaryCard(double pct, String rl, Color rc, bool hf) {
    return Card(color: rc.withOpacity(0.05), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const Divider(),
      _sumRow('Total Score', '${_totalScore()}/240', rc), _sumRow('Percentage', '${pct.toStringAsFixed(1)}%', rc),
      _sumRow('Rating', SpotCheckHelper.getRatingBadge(rl), rc),
      if (hf) ...[const Divider(), const Text('⚠️ Critical Flags', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))],
      if (_reqAction()) ...[const Divider(), const Text('⚠️ Action Required', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12))],
    ])));
  }

  Widget _sumRow(String l, String v, Color? c) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [Expanded(child: Text(l, style: const TextStyle(fontSize: 12))), Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c))]));

  Future<void> _save(String status) async {
    if (!_formKey.currentState!.validate()) return;
    if (_serviceUserId == null || _carerId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service user and carer required'))); return; }
    if (_auditorSigCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auditor signature required'))); return; }

    setState(() => _isSubmitting = true);
    try {
      final pct = _pct(); final hf = _hasFlags(); final rl = SpotCheckHelper.calcRating(pct, hf); final ra = _reqAction();
      final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00';

      final sc = SpotCheck(
        id: widget.spotCheck?.id,
        serviceUserId: _serviceUserId!, serviceUserName: _serviceUserName ?? '',
        carerId: _carerId!, carerName: _carerName ?? '', carerRole: _carerRole, carerEmploymentType: _carerEmploymentType,
        spotCheckDate: _date, spotCheckTime: timeStr, spotCheckDurationMinutes: _duration,
        spotCheckType: _type, spotCheckReason: _reason == 'other' ? _otherReason : _reason,
        conductedById: Supabase.instance.client.auth.currentUser?.id ?? '', conductedByName: _conductedByName, conductedByRole: _conductedByRole,
        witnessPresent: _witnessPresent, witnessName: _witnessName, witnessRole: _witnessRole,
        prepHandoverReviewed: _p1, prepMedicationChecked: _p2, prepEquipmentReady: _p3,
        arrivalPunctuality: _p4, arrivalPresentation: _p5, arrivalCommunication: _p6,
        icHandHygiene: _i1, icPpeWorn: _i2, icPpeChanged: _i3,
        icEquipmentCleanliness: _i4, icEnvironmentHygiene: _i5, icWasteDisposal: _i6,
        interactionGreeting: _sg1, interactionConsent: _sg2, interactionDignity: _sg3,
        interactionPrivacy: _sg4, interactionCommunication: _sg5, interactionHearingListening: _sg6,
        interactionChoicePromoted: _sg7, interactionCapacityConsidered: _sg8, interactionEmotionalSupport: _sg9,
        careFollowsCarePlan: _c1, carePersonalCareQuality: _c2, careMobilityAssistance: _c3,
        careMedicationAdministration: _c4, careNutritionHydration: _c5, careDocumentation: _c6, careHandoverCommunication: _c7,
        safetyRiskAssessment: _s1, safetyEnvironmentCheck: _s2, safetyMovingHandling: _s3,
        safetyEmergencyKnowledge: _s4, safetyMedicationSecurity: _s5, safetyChallengingBehaviour: _s6,
        commDailyNoteQuality: _cm1, commIncidentReporting: _cm2, commFamilyCommunication: _cm3,
        commOtherProfessionals: _cm4, commEscalationAwareness: _cm5,
        profCodeOfConduct: _pf1, profMedicationKnowledge: _pf2, profSafeguardingKnowledge: _pf3,
        profDataProtection: _pf4, profTeamWorking: _pf5, profFeedbackReceptiveness: _pf6,
        flagMedicationError: _f1, flagInfectionBreach: _f2, flagDignityBreach: _f3,
        flagSafeguardingConcern: _f4, flagUnauthorizedAbsence: _f5, flagUntrainedTask: _f6,
        flagFalsifiedRecords: _f7, flagRefusedCare: _f8, flagAggressiveBehaviour: _f9,
        totalScore: _totalScore(), overallPercentage: pct, competencyRating: rl,
        strengths: _strengthsCtrl.text.isNotEmpty ? _strengthsCtrl.text : null,
        areasForImprovement: _afiCtrl.text.isNotEmpty ? _afiCtrl.text : null,
        immediateConcerns: _concernsCtrl.text.isNotEmpty ? _concernsCtrl.text : null,
        additionalObservations: _observationsCtrl.text.isNotEmpty ? _observationsCtrl.text : null,
        requiresAction: ra, actionRequired: ra ? _actionReqCtrl.text : null,
        actionAssignedTo: ra ? _actionAssignedTo : null, actionDeadline: ra ? _actionDeadline : null,
        actionNotes: _actionNotesCtrl.text.isNotEmpty ? _actionNotesCtrl.text : null,
        followUpRequired: _followUpReq, followUpDate: _followUpDate, followUpType: _followUpReq ? _followUpType : null,
        auditorSignature: _auditorSigCtrl.text.trim(),
        carerAcknowledged: _carerAcknowledged, carerComments: _carerCommentsCtrl.text.isNotEmpty ? _carerCommentsCtrl.text : null,
        managerReviewed: _managerReviewed, managerNotes: _managerNotesCtrl.text.isNotEmpty ? _managerNotesCtrl.text : null,
        status: ra && status == 'completed' ? 'action_required' : status,
        createdAt: widget.spotCheck?.createdAt ?? DateTime.now(), updatedAt: DateTime.now(),
      );

      if (widget.spotCheck?.id != null) await _service.updateSpotCheck(widget.spotCheck!.id!, sc);
      else await _service.createSpotCheck(sc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'completed' ? 'Spot check submitted' : 'Draft saved'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _isSubmitting = false); }
  }
}