# Admin Dashboard Navigation Map

This document tracks all navigation links in the CareQA Admin Dashboard to ensure nothing gets lost during development.

## PEOPLE Section
- Carers → `CarerListScreen`
- Service Users → `ServiceUserListScreen`
- Add New User → `SignUpScreen`
- Care Home Details → `CarehomeDetailsScreen`

## SCHEDULING Section
- Shifts → `ShiftListScreen`
- Shift Rota → `ShiftRotaScreen`
- Visits → `VisitListScreen`
- Drivers → `DriversScreen`

## ASSESSMENTS Section
- Accidents & Incidents → `AccidentsIncidentsScreen`
- Choking Risk → `ChokingRiskScreen`
- Falls Risk → `FallsRiskScreen`
- Medication Risk → `MedicationRiskScreen`
- MCA → `McaScreen`
- Risk Assessment → `RiskAssessmentScreen`
- Waterlow → `WaterlowScreen`
- ReSPECT Form → `RespectFormScreen`
- Grab Sheet → `GrabsheetScreen`

## RISK ASSESSMENTS Section
- Fire Hazard → `FireHazardScreen`
- COSHH → `CoshhRiskScreen` (with service user picker)
- Catheter Care Risk → `CatheterCareRiskScreen` (with service user picker)
- Epilepsy → `EpilepsyRiskScreen` (with service user picker)
- Diabetes → `DiabetesRiskScreen` (with service user picker)
- Self Harm → `SelfHarmRiskScreen`
- Activity Risk → `ActivityRiskScreen`
- Bed Railing → `BedRailingScreen`
- Challenging Behaviour → `ChallengingBehaviourScreen`
- Environmental Risk → `EnvironmentalRiskScreen`
- Nutrition Risk → `NutritionRiskScreen`
- Incontinence Risk → `IncontinenceRiskScreen`

## DAILY MONITORING Section
- Food & Fluid Log → `IntakeLogScreen`
- Stool Log → `StoolLogScreen`
- Temperature Log → `TemperatureLogScreen`
- Daily Notes → `DailyNotesScreen`

## AUDITS Section
- MAR Audit → `MarAuditScreen`
- MAR Chart → `MarChartViewScreen` (with service user picker)
- Care Log Audit → `CarelogAuditScreen`
- Care Plan Audit → `CarePlanAuditScreen`
- Spot Check → `SpotCheckScreen`
- Compliance → `ComplianceDashboard`

## SAFEGUARDING & INCIDENTS Section
- Safeguarding → `SafeguardingScreen`
- Accidents Log → `SafeguardingAccidentsScreen`
- Complaints → `ComplaintsScreen`
- Compliments → `ComplimentsScreen`
- Whistleblower → `WhistleblowerScreen`
- Medication Incidents → `MedicationIncidentScreen`
- Medication Errors → `MedicationErrorsScreen`
- Missing Persons → `MissingPersonsScreen`
- Missing Items → `MissingItemsScreen`
- Serious Incidents → `SeriousIncidentsScreen`

## STAFF & HR Section
- Supervision Matrix → `SupervisionMatrixScreen`
- Appraisals → `AppraisalsScreen`
- Training Matrix → `TrainingMatrixScreen`
- Disciplinary → `DisciplinaryScreen`
- Leave & Pay → `LeaveScreen`
- Employee Welfare → `EmployeeWelfareScreen`
- Employee Satisfaction → `EmployeeSatisfactionScreen`
- Employee Incentives → `EmployeeIncentivesScreen`
- Meetings Log → `MeetingsLogScreen`
- Emergency Contacts → `EmergencyContactsScreen`

## COMPETENCY Section
- Competency Dashboard → `CompetencyDashboardScreen`
- Medication Competency → `MedicationCompetencyScreen`
- Manual Handling → `ManualHandlingCompetencyScreen`
- Catheter Care → `CatheterCareCompetencyScreen`
- Spot Check → `SpotCheckCompetencyScreen`
- Pressure Prevention → `PressurePreventionCompetencyScreen`
- Infection Control → `InfectionControlCompetencyScreen`
- Fire Safety → `FireSafetyCompetencyScreen`
- First Aid → `FirstAidCompetencyScreen`
- Moving & Handling → `MovingHandlingCompetencyScreen`
- Safeguarding → `SafeguardingCompetencyScreen`
- Dignity & Respect → `DignityRespectCompetencyScreen`
- Communication → `CommunicationCompetencyScreen`

## MATRIX Section
- Matrix Dashboard → `MatrixDashboardScreen`
  - Training Matrix → `TrainingMatrixScreen`
  - Supervision Matrix → `SupervisionMatrixScreen`
  - Appraisal Matrix → `AppraisalMatrixScreen`
  - Equipment Matrix → `EquipmentMatrixScreen`

## ADMIN Section
- Meetings Log → `MeetingsLogScreen`
- Analysis → `AnalysisScreen`

## FINANCE & ADMIN Section
- Supplier Register → `SupplierLogScreen`
- Receipt Entry → `ReceiptEntryScreen`
- Profit Calculator → `ProfitCalculatorScreen`
- Profit & Loss → `ProfitLossScreen`
- Invoice Generation → `InvoiceScreen`
- Action Plans → `ActionPlansScreen`
- Lessons Learnt → `LessonsLearntScreen`
- Policy Library → `PoliciesScreen`
- Analysis → `AnalysisScreen`
- Generate Report → `GenerateReportScreen`

## COMMUNICATIONS Section
- Notification Hub → `NotificationsScreen`
- Carer Inbox → `CarerInboxScreen`
- Recordings → `RecordingsScreen`

## Quick Access Tiles (Dashboard Home)
- Carers → `CarerListScreen`
- Service Users → `ServiceUserListScreen`
- Shifts → `ShiftListScreen`
- Safeguarding → `SafeguardingScreen`
- MAR Audit → `MarAuditScreen`
- Compliance → `ComplianceDashboard`

---

## Notes

### Duplicate Entries
Some screens appear in multiple sections:
- `MeetingsLogScreen` appears in both STAFF & HR and ADMIN sections
- `AnalysisScreen` appears in both ADMIN and FINANCE & ADMIN sections
- `SupplierLogScreen` appears twice in FINANCE & ADMIN section

### Service User Pickers
The following screens use the `_showRiskAssessmentPicker` pattern to select a service user first:
- COSHH
- Catheter Care Risk
- Epilepsy
- Diabetes
- MAR Chart

### File Location
This document should be updated whenever new navigation items are added to `admin-app/lib/ui/dashboard/admin_dashboard.dart`.