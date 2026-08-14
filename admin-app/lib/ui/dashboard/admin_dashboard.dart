import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/supabase_auth_service.dart';
import 'package:admin_app/ui/carer/carer_list_screen.dart';
import 'package:admin_app/ui/service_user/service_user_list_screen.dart';
import 'package:admin_app/ui/shift/shift_list_screen.dart';
import 'package:admin_app/ui/shift_rota/shift_rota_screen.dart';
import 'package:admin_app/ui/visit/visit_list_screen.dart';
import 'package:admin_app/ui/assessments/accidents_incidents_screen.dart';
import 'package:admin_app/ui/assessments/choking_risk_screen.dart';
import 'package:admin_app/ui/assessments/falls_risk_screen.dart';
import 'package:admin_app/ui/assessments/medication_risk_screen.dart';
import 'package:admin_app/ui/assessments/mca_screen.dart';
import 'package:admin_app/ui/assessments/respect_form_screen.dart';
import 'package:admin_app/ui/assessments/grabsheet_screen.dart';
import 'package:admin_app/ui/risk_assessment/risk_assessment_screen.dart';
import 'package:admin_app/ui/waterlow_assessment/waterlow_screen.dart';
import 'package:admin_app/ui/monitoring/intake_log_screen.dart';
import 'package:admin_app/ui/monitoring/stool_log_screen.dart';
import 'package:admin_app/ui/monitoring/temperature_log_screen.dart';
import 'package:admin_app/ui/monitoring/daily_notes_screen.dart';
import 'package:admin_app/ui/audits/mar_audit_screen.dart';
import 'package:admin_app/ui/audit/care_log_audit_screen.dart';
import 'package:admin_app/ui/audits/careplan_audit_screen.dart';
import 'package:admin_app/ui/audits/spot_check_screen.dart';
import 'package:admin_app/ui/compliance/compliance_dashboard.dart';
import 'package:admin_app/ui/safeguarding/safeguarding_screen.dart';
import 'package:admin_app/ui/staff/supervision_matrix_screen.dart';
import 'package:admin_app/ui/staff/appraisals_screen.dart';
import 'package:admin_app/ui/staff/training_matrix_screen.dart';
import 'package:admin_app/ui/staff/disciplinary_screen.dart';
import 'package:admin_app/ui/staff/leave_screen.dart';
import 'package:admin_app/ui/staff/employee_welfare_screen.dart';
import 'package:admin_app/ui/staff/employee_satisfaction_screen.dart';
import 'package:admin_app/ui/staff/employee_incentives_screen.dart';
import 'package:admin_app/ui/competency/competency_dashboard_screen.dart';
import 'package:admin_app/ui/competency/manual_handling_competency_screen.dart';
import 'package:admin_app/ui/competency/medication_competency_screen.dart';
import 'package:admin_app/ui/competency/catheter_care_competency_screen.dart';
import 'package:admin_app/ui/competency/spot_check_competency_screen.dart';
import 'package:admin_app/ui/competency/pressure_prevention_competency_screen.dart';
import 'package:admin_app/ui/competency/infection_control_competency_screen.dart';
import 'package:admin_app/ui/competency/fire_safety_competency_screen.dart';
import 'package:admin_app/ui/competency/first_aid_competency_screen.dart';
import 'package:admin_app/ui/competency/moving_handling_competency_screen.dart';
import 'package:admin_app/ui/competency/safeguarding_competency_screen.dart';
import 'package:admin_app/ui/competency/dignity_respect_competency_screen.dart';
import 'package:admin_app/ui/competency/communication_competency_screen.dart';
import 'package:admin_app/ui/admin/meetings_log_screen.dart';
import 'package:admin_app/ui/admin/analysis_screen.dart';
import 'package:admin_app/ui/finance/supplier_log_screen.dart';
import 'package:admin_app/ui/finance/receipt_entry_screen.dart';
import 'package:admin_app/ui/finance/receipt_list_screen.dart';
import 'package:admin_app/ui/finance/profit_calculator_screen.dart';
import 'package:admin_app/ui/finance/invoice_screen.dart';
import 'package:admin_app/ui/finance/supplier_register_screen.dart';
import 'package:admin_app/ui/admin/action_plans_screen.dart';
import 'package:admin_app/ui/admin/lessons_learnt_screen.dart';
import 'package:admin_app/ui/admin/policies_screen.dart';
import 'package:admin_app/ui/admin/analysis_screen.dart';
import 'package:admin_app/ui/admin/notifications_screen.dart';
import 'package:admin_app/ui/communication/carer_inbox_screen.dart' as comm_carer_inbox;
import 'package:admin_app/ui/admin/recordings_screen.dart';
import 'package:admin_app/ui/admin/matrix_dashboard_screen.dart';
import 'package:admin_app/ui/admin/emergency_contacts_screen.dart';
import 'package:admin_app/ui/admin/carehome_details_screen.dart';
import 'package:admin_app/ui/admin/drivers_screen.dart';
import 'package:admin_app/ui/admin/sign_up_screen.dart';
import 'package:admin_app/ui/admin/generate_report_screen.dart';
import 'package:admin_app/ui/finance/profit_loss_screen.dart';
import 'package:admin_app/ui/finance/invoice_screen.dart';
import 'package:admin_app/ui/finance/invoice_list_screen.dart';
import 'package:admin_app/ui/finance/organisation_profile_screen.dart';
import 'package:admin_app/ui/actions/action_plan_list_screen.dart';
import 'package:admin_app/ui/actions/action_plan_widget.dart';
import 'package:admin_app/ui/actions/action_plan_reports_screen.dart';
import 'package:admin_app/ui/lessons/lesson_list_screen.dart';
import 'package:admin_app/ui/lessons/lesson_dashboard_widget.dart';
import 'package:admin_app/ui/lessons/lesson_reports_screen.dart';
import 'package:admin_app/ui/lessons/root_cause_analysis_screen.dart';
import 'package:admin_app/ui/policies/policy_list_screen.dart';
import 'package:admin_app/ui/policies/policy_dashboard_widget.dart';
import 'package:admin_app/ui/policies/policy_reports_screen.dart';
import 'package:admin_app/ui/policies/policy_acknowledgment_screen.dart';
import 'package:admin_app/ui/analysis/analysis_dashboard_screen.dart';
import 'package:admin_app/ui/notifications/notification_hub_screen.dart';
import 'package:admin_app/ui/notifications/notification_settings_screen.dart';
import 'package:admin_app/ui/communication/carer_inbox_screen.dart';
import 'package:admin_app/ui/communication/whistleblower_inbox_screen.dart';
import 'package:admin_app/ui/medication/mar_chart_screen.dart';
import 'package:admin_app/ui/risk/activity_risk_screen.dart';
import 'package:admin_app/ui/risk/bed_railing_screen.dart';
import 'package:admin_app/ui/risk/challenging_behaviour_screen.dart';
import 'package:admin_app/ui/risk/coshh_risk_screen.dart';
import 'package:admin_app/ui/risk/diabetes_risk_screen.dart';
import 'package:admin_app/ui/risk/environmental_risk_screen.dart';
import 'package:admin_app/ui/risk/epilepsy_risk_screen.dart';
import 'package:admin_app/ui/risk/fire_hazard_screen.dart';
import 'package:admin_app/ui/risk/incontinence_risk_screen.dart';
import 'package:admin_app/ui/risk/nutrition_risk_screen.dart';
import 'package:admin_app/ui/risk/self_harm_risk_screen.dart';
import 'package:admin_app/ui/risk/catheter_care_risk_screen.dart';
import 'package:admin_app/ui/admin/import_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  void _go(BuildContext context, Widget screen) {
    if (Navigator.canPop(context)) Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<List<Map<String, dynamic>>> _getServiceUsers() async {
    final response = await Supabase.instance.client
        .from('service_users')
        .select('id, name')
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  void _showRiskAssessmentPicker(
    BuildContext context,
    String title,
    IconData icon,
    Widget Function(String, String) screenBuilder,
  ) {
    Navigator.pop(context); // Close drawer first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Service User'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getServiceUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No service users found'));
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final user = snapshot.data![index];
                  return ListTile(
                    title: Text(user['name']?.toString() ?? 'Unknown'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => screenBuilder(
                            user['id'].toString(),
                            user['name']?.toString() ?? 'Unknown',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SupabaseAuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareQA Admin'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await auth.signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1565C0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text('CareQA Admin',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(auth.currentUser?.email ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            _h('PEOPLE'),
            _i(context, Icons.people, 'Carers', const CarerListScreen()),
            _i(context, Icons.home, 'Service Users', const ServiceUserListScreen()),
            _i(context, Icons.person_add, 'Add New User', const SignUpScreen()),
            _i(context, Icons.business, 'Care Home Details', const CarehomeDetailsScreen()),
            _h('SCHEDULING'),
            _i(context, Icons.schedule, 'Shifts', const ShiftListScreen()),
            _i(context, Icons.calendar_month, 'Shift Rota', const ShiftRotaScreen()),
            _i(context, Icons.check_circle, 'Visits', const VisitListScreen()),
            _i(context, Icons.directions_car, 'Drivers', const DriversScreen()),
            _h('ASSESSMENTS'),
            _i(context, Icons.warning_amber, 'Accidents & Incidents', const AccidentsIncidentsScreen()),
            _i(context, Icons.restaurant, 'Choking Risk', const ChokingRiskScreen()),
            _i(context, Icons.elderly, 'Falls Risk', const FallsRiskScreen()),
            _i(context, Icons.medication, 'Medication Risk', const MedicationRiskScreen()),
            _i(context, Icons.psychology, 'MCA', const McaScreen()),
            _i(context, Icons.assignment, 'Risk Assessment', RiskAssessmentHubScreen()),
            _i(context, Icons.medical_information, 'Waterlow', const WaterlowScreen()),
            _i(context, Icons.healing, 'ReSPECT Form', const RespectFormScreen()),
            _i(context, Icons.person_search, 'Grab Sheet', const GrabsheetScreen()),
            _h('RISK ASSESSMENTS'),
            _i(context, Icons.local_fire_department, 'Fire Hazard', const FireHazardScreen()),
            ListTile(
              leading: const Icon(Icons.science, color: Color(0xFF1565C0), size: 22),
              title: const Text('COSHH', style: TextStyle(fontWeight: FontWeight.w500)),
              dense: true,
              onTap: () => _showRiskAssessmentPicker(
                context,
                'COSHH',
                Icons.science,
                (userId, userName) => CoshhRiskScreen(serviceUserId: userId, serviceUserName: userName),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.water_drop, color: Color(0xFF1565C0), size: 22),
              title: const Text('Catheter Care Risk', style: TextStyle(fontWeight: FontWeight.w500)),
              dense: true,
              onTap: () => _showRiskAssessmentPicker(
                context,
                'Catheter Care Risk',
                Icons.water_drop,
                (userId, userName) => CatheterCareRiskScreen(serviceUserId: userId, serviceUserName: userName),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bolt, color: Color(0xFF1565C0), size: 22),
              title: const Text('Epilepsy', style: TextStyle(fontWeight: FontWeight.w500)),
              dense: true,
              onTap: () => _showRiskAssessmentPicker(
                context,
                'Epilepsy',
                Icons.bolt,
                (userId, userName) => EpilepsyRiskScreen(serviceUserId: userId, serviceUserName: userName),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bloodtype, color: Color(0xFF1565C0), size: 22),
              title: const Text('Diabetes', style: TextStyle(fontWeight: FontWeight.w500)),
              dense: true,
              onTap: () => _showRiskAssessmentPicker(
                context,
                'Diabetes',
                Icons.bloodtype,
                (userId, userName) => DiabetesRiskScreen(serviceUserId: userId, serviceUserName: userName),
              ),
            ),
            _i(context, Icons.self_improvement, 'Self Harm', const SelfHarmRiskScreen()),
            _i(context, Icons.bug_report, 'Activity Risk', const ActivityRiskScreen()),
            _i(context, Icons.bed, 'Bed Railing', const BedRailingScreen()),
            _i(context, Icons.psychology_alt, 'Challenging Behaviour', const ChallengingBehaviourScreen()),
            _i(context, Icons.eco, 'Environmental Risk', const EnvironmentalRiskScreen()),
            _i(context, Icons.restaurant_menu, 'Nutrition Risk', const NutritionRiskScreen()),
            _i(context, Icons.wb_sunny, 'Incontinence Risk', const IncontinenceRiskScreen()),
            _h('DAILY MONITORING'),
            _i(context, Icons.local_drink, 'Food & Fluid Log', const IntakeLogScreen()),
            _i(context, Icons.monitor_heart, 'Stool Log', const StoolLogScreen()),
            _i(context, Icons.thermostat, 'Temperature Log', const TemperatureLogScreen()),
            _i(context, Icons.note_alt, 'Daily Notes', const DailyNotesScreen()),
            _h('AUDITS'),
            _i(context, Icons.fact_check, 'MAR Audit', const MarAuditScreen()),
            _i(context, Icons.receipt_long, 'MAR Chart', const MarChartScreen()),
            _i(context, Icons.book, 'Care Log Audit', const CareLogAuditScreen()),
            _i(context, Icons.assignment_turned_in, 'Care Plan Audit', const CarePlanAuditScreen()),
            _i(context, Icons.search, 'Spot Check', const SpotCheckScreen()),
            _i(context, Icons.verified_user, 'Compliance', ComplianceDashboard()),
            _h('SAFEGUARDING & INCIDENTS'),
            _i(context, Icons.shield, 'Safeguarding Hub', const SafeguardingScreen()),
            _h('STAFF & HR'),
            _i(context, Icons.supervisor_account, 'Supervision Matrix', const SupervisionMatrixScreen()),
            _i(context, Icons.star_rate, 'Appraisals', const AppraisalsScreen()),
            _i(context, Icons.school, 'Training Matrix', const TrainingMatrixScreen()),
            _i(context, Icons.gavel, 'Disciplinary', const DisciplinaryScreen()),
            _i(context, Icons.beach_access, 'Leave & Pay', const LeaveScreen()),
            _i(context, Icons.favorite, 'Employee Welfare', const EmployeeWelfareScreen()),
            _i(context, Icons.sentiment_satisfied, 'Employee Satisfaction', const EmployeeSatisfactionScreen()),
            _i(context, Icons.emoji_events, 'Employee Incentives', const EmployeeIncentivesScreen()),
            _i(context, Icons.groups, 'Meetings Log', const MeetingsLogScreen()),
            _i(context, Icons.contacts, 'Emergency Contacts', const EmergencyContactsScreen()),
            _h('COMPETENCY'),
            _i(context, Icons.workspace_premium, 'Competency Dashboard', const CompetencyDashboardScreen()),
            _i(context, Icons.medication, 'Medication Competency', const MedicationCompetencyScreen()),
            _i(context, Icons.fitness_center, 'Manual Handling', const ManualHandlingCompetencyScreen()),
            _i(context, Icons.water_drop, 'Catheter Care', const CatheterCareCompetencyScreen()),
            _i(context, Icons.search, 'Spot Check', const SpotCheckCompetencyScreen()),
            _i(context, Icons.accessibility_new, 'Pressure Prevention', const PressurePreventionCompetencyScreen()),
            _i(context, Icons.sanitizer, 'Infection Control', const InfectionControlCompetencyScreen()),
            _i(context, Icons.local_fire_department, 'Fire Safety', const FireSafetyCompetencyScreen()),
            _i(context, Icons.medical_services, 'First Aid', const FirstAidCompetencyScreen()),
            _i(context, Icons.accessibility, 'Moving & Handling', const MovingHandlingCompetencyScreen()),
            _i(context, Icons.shield, 'Safeguarding', const SafeguardingCompetencyScreen()),
            _i(context, Icons.favorite, 'Dignity & Respect', const DignityRespectCompetencyScreen()),
            _i(context, Icons.chat, 'Communication', const CommunicationCompetencyScreen()),
            _h('MATRIX'),
            _i(context, Icons.grid_view, 'Matrix Dashboard', const MatrixDashboardScreen()),
            _h('ADMIN'),
            _i(context, Icons.calendar_today, 'Meetings Log', const MeetingsLogScreen()),
            _i(context, Icons.analytics, 'Analysis', const AnalysisScreen()),
            _i(context, Icons.assignment, 'Action Plans', const ActionPlanListScreen()),
            _i(context, Icons.analytics, 'Action Plan Reports', const ActionPlanReportsScreen()),
            _i(context, Icons.school, 'Lessons Learnt', const LessonListScreen()),
            _i(context, Icons.analytics, 'Lesson Reports', const LessonReportsScreen()),
            _i(context, Icons.find_in_page, 'Root Cause Analysis', const RootCauseAnalysisScreen()),
            _i(context, Icons.folder, 'Policy Library', const PolicyListScreen()),
            _i(context, Icons.analytics, 'Policy Reports', const PolicyReportsScreen()),
            _i(context, Icons.verified_user, 'Policy Acknowledgment', const PolicyAcknowledgmentScreen()),
            _i(context, Icons.analytics, 'Analysis', const AnalysisDashboardScreen()),
            _h('FINANCE & ADMIN'),
            _i(context, Icons.download, 'Onboarding Import', const ImportScreen()),
            _i(context, Icons.store, 'Supplier Register', const SupplierRegisterScreen()),
            _i(context, Icons.receipt, 'Receipts', const ReceiptListScreen()),
            _i(context, Icons.calculate, 'Profit Calculator', const ProfitCalculatorScreen()),
            _i(context, Icons.show_chart, 'Profit & Loss', const ProfitLossScreen()),
            _i(context, Icons.receipt_long, 'Invoice Generator', const InvoiceScreen()),
            _i(context, Icons.list, 'Invoice List', const InvoiceListScreen()),
            _i(context, Icons.business, 'Organisation Profile', const OrganisationProfileScreen()),
            _i(context, Icons.task_alt, 'Action Plans', const ActionPlansScreen()),
            _i(context, Icons.lightbulb, 'Lessons Learnt', const LessonsLearntScreen()),
            _i(context, Icons.policy, 'Policy Library', const PoliciesScreen()),
            _i(context, Icons.analytics, 'Analysis', const AnalysisScreen()),
            _i(context, Icons.summarize, 'Generate Report', const GenerateReportScreen()),
            _h('COMMUNICATIONS'),
            _i(context, Icons.notifications, 'Notification Hub', const NotificationHubScreen()),
            _i(context, Icons.settings, 'Notification Settings', const NotificationSettingsScreen()),
            _i(context, Icons.inbox, 'Carer Inbox', const comm_carer_inbox.CarerInboxScreen()),
            _i(context, Icons.visibility_off, 'Whistleblower Inbox', const WhistleblowerInboxScreen()),
            _i(context, Icons.videocam, 'Recordings', const RecordingsScreen()),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async => await auth.signOut(),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('CareQA Admin Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Tap ☰ to navigate', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              Wrap(
                spacing: 16, runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _q(context, 'Carers', Icons.people, Colors.blue, const CarerListScreen()),
                  _q(context, 'Service Users', Icons.home, Colors.green, const ServiceUserListScreen()),
                  _q(context, 'Shifts', Icons.schedule, Colors.orange, const ShiftListScreen()),
                  _q(context, 'Safeguarding', Icons.shield, Colors.red, const SafeguardingScreen()),
                  _q(context, 'MAR Audit', Icons.fact_check, Colors.teal, const MarAuditScreen()),
                  _q(context, 'Compliance', Icons.verified_user, Colors.indigo, ComplianceDashboard()),
                  _q(context, 'Action Plans', Icons.assignment, Colors.purple, const ActionPlanListScreen()),
                  _q(context, 'Lessons Learnt', Icons.school, Colors.indigo, const LessonListScreen()),
                  _q(context, 'Policy Library', Icons.folder, Colors.brown, const PolicyListScreen()),
                  _q(context, 'Analysis', Icons.analytics, Colors.teal, const AnalysisDashboardScreen()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _h(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
  );

  Widget _i(BuildContext context, IconData icon, String title, Widget screen) =>
    ListTile(
      leading: Icon(icon, color: const Color(0xFF1565C0), size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      dense: true,
      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => screen)); },
    );

  Widget _q(BuildContext context, String title, IconData icon, Color color, Widget screen) =>
    GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        width: 140, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 36, color: Colors.white),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
}


class ServiceUserPickerScreen extends StatelessWidget {
  final String destination;

  const ServiceUserPickerScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(destination == 'risk' ? 'Risk Assessment' : 'Waterlow Assessment')),
      body: const Center(child: Text('Service User Picker - Coming Soon')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
