# Admin-App Schema & Function Documentation

## Overview

The **admin-app** is a Flutter-based administrative dashboard for the CareQA care home management system. It provides a comprehensive interface for managing residents (service users), staff (carers), compliance, finances, risk assessments, competencies, communications, and analytics.

The app connects to a Supabase backend (PostgreSQL) with Row-Level Security (RLS) enabled on all tables. Data is accessed through Dart service classes that wrap Supabase client queries, and UI screens that render the data in Flutter widgets.

---

## Architecture Overview

```
admin-app/
├── lib/
│   ├── models/          # Data models (DTOs) for each entity
│   ├── services/        # Supabase service classes (CRUD + queries)
│   ├── ui/              # Flutter screens organized by feature domain
│   │   ├── dashboard/   # AdminDashboard - main navigation hub
│   │   ├── competency/  # Competency assessment forms
│   │   ├── communication/  # Carer inbox, messages
│   │   ├── finance/     # Invoices, receipts, suppliers
│   │   ├── assessments/ # Risk assessments
│   │   ├── risk/        # Risk assessment screens
│   │   ├── monitoring/  # Daily monitoring logs
│   │   ├── audits/      # Audit screens
│   │   ├── compliance/  # Compliance dashboard
│   │   ├── safeguarding/  # Safeguarding hub
│   │   ├── staff/       # HR management
│   │   ├── actions/     # Action plans
│   │   ├── lessons/     # Lessons learnt
│   │   ├── policies/    # Policy library
│   │   ├── analysis/    # Analysis dashboard
│   │   ├── notifications/  # Notification hub
│   │   └── widgets/     # Reusable widgets
│   └── supabase_config.dart  # Supabase initialization
```

### Data Flow

1. **UI Screen** calls a **Service class** method
2. **Service class** uses `Supabase.instance.client` to query the database
3. **Database** returns data (with RLS filtering applied)
4. **Service class** parses the response into **Model objects**
5. **UI Screen** renders the models in Flutter widgets

---

## Database Schemas & Their Usage

### Core Identity & People

#### `profiles` (Migration 001)
**Stores:** Staff/admin user accounts (extends Supabase Auth)
- **Fields:** id, email, full_name, role, organisation_id, phone, created_at, updated_at
- **Called by:** 
  - `AnalysisService.getStaff()` - Staff tab in Analysis Dashboard
  - `AnalysisService._getStaffByRole()` - Staff by Role chart
  - `AnalysisService._getTrainingCompliance()` - Training compliance count
  - `AnalysisService._getStaffTrainingCompletion()` - Training completion rate
  - `AnalysisService._getOrganisationId()` - Gets org from current user
  - `SupabaseAuthService` - Authentication
- **Not called by but should be:** Staff management screens (staff_list_screen.dart, appraisals, disciplinary, leave)

#### `carers` (Migration 001, extended by 069, 070)
**Stores:** Care workers/carers (residential care staff)
- **Fields:** id, profile_id, first_name, last_name, email, phone, dob, address, is_active, qualification, created_at, updated_at
- **Called by:**
  - `AnalysisService.getCarers()` - Carers section (newly added)
  - `CarerListScreen` - via CarerService
- **Not called by but should be:** Competency assessment forms (should pull carer names from here for dropdowns)

#### `service_users` (Migration 001)
**Stores:** Residents/service users (people receiving care)
- **Fields:** id, name, email, phone, address, date_of_birth, admission_date, is_active, created_at, updated_at
- **Called by:**
  - `AnalysisService.getServiceUsers()` - Service Users tab (newly added)
  - `AnalysisService._getRiskAssessmentCompliance()` - Compliance count
  - `AnalysisService.getServiceUserMetrics()` - Service user count
  - `ServiceUserListScreen` - via ServiceUserService
  - Risk assessment screens (COSHH, Catheter Care, Epilepsy, Diabetes)
- **Not called by but should be:** More risk assessment screens that still use text input for names

### Scheduling & Visits

#### `shifts` (Migration 001)
**Stores:** Staff shift schedules
- **Fields:** id, carer_id, scheduled_date, start_time, end_time, status, assigned_staff_id, created_at, updated_at
- **Called by:**
  - `AnalysisService._getShiftCoverage()` - Shift coverage rate
  - `ShiftListScreen` - via ShiftService
- **Not called by but should be:** More scheduling features

#### `visits` (Migration 001)
**Stores:** Care visit records
- **Fields:** id, shift_id, carer_id, service_user_id, visit_date, status, billing_amount, created_at, updated_at
- **Called by:**
  - `AnalysisService._getVisitCompletion()` - Visit completion rate
  - `AnalysisService._getRouteProfitability()` - Route revenue
  - `VisitListScreen` - via VisitService
- **Not called by but should be:** More visit tracking features

### Risk Assessments

#### Risk Assessment Tables (Migrations 031-046, 075-082)
Multiple tables for different risk assessment types:
- `choking_risk_assessments` (031, 075, 076)
- `catheter_care_risk_assessments` (032, 047)
- `epilepsy_risk_assessments` (033)
- `diabetes_risk_assessments` (034)
- `self_harm_risk_assessments` (035)
- `anaphylaxis_risk_assessments` (036)
- `activity_risk_assessments` (037)
- `sepsis_risk_assessments` (038)
- `environmental_risk_assessments` (039)
- `incontinence_risk_assessments` (040)
- `nutrition_risk_assessments` (041, 082)
- `challenging_behaviour_risk_assessments` (042)
- `bed_railing_risk_assessments` (043)
- `financial_risk_assessments` (044)
- `equipment_register_risk_assessments` (045)
- `fire_hazard_risk_assessments` (046, 080)
- `coshh_assessments` (082)

**Called by:**
- `AnalysisService._getRiskAssessmentCompliance()` - Uses `risk_assessments` table
- Individual risk assessment screens (ChokingRiskScreen, FallsRiskScreen, etc.)
- `RiskAssessmentHubScreen`

**Not called by but should be:** The `risk_assessments` table referenced in analysis_service.dart may not exist as a unified table

### Compliance & Competency

#### `compliance_flags` (Migration 002)
**Stores:** Compliance violation flags
- **Fields:** id, carer_id, visit_id, severity, status, description, created_at
- **Called by:** `ComplianceDashboard`

#### `compliance_scores` (Migration 002)
**Stores:** Trending compliance scores
- **Fields:** id, carer_id, score_date, overall_score, created_at
- **Called by:** `ComplianceDashboard`

#### `compliance_rules` (Migration 002)
**Stores:** Configurable compliance rules
- **Fields:** id, rule_name, rule_type, threshold, is_active, created_at
- **Called by:** `ComplianceDashboard`

#### `compliance_scores` (Migration 002)
**Stores:** Compliance score trends
- **Called by:** `ComplianceDashboard`

#### `staff_competency_assessments` (Migration 022, 052, 100, 102, 103, 105)
**Stores:** Competency assessment records
- **Fields:** id, carer_id, competency_type, assessment_date, score, status, action_plan, notes, created_by, created_at
- **Called by:** Competency form screens (catheter_care, fire_safety, first_aid, etc.)
- **Not called by but should be:** The `action_plan` column is referenced but may not exist in schema (causing PGRST204 error)

#### `competency_frameworks` (Migration 100)
**Stores:** Competency framework definitions
- **Called by:** `CompetencyDashboardScreen`

#### `training_records` (Migration 021, 094, 096)
**Stores:** Staff training records
- **Fields:** id, staff_id, course_id, completion_date, expiry_date, score, status
- **Called by:**
  - `AnalysisService._getTrainingCompliance()` - Training completion
  - `AnalysisService._getStaffTrainingCompletion()` - Training completion rate
  - `TrainingMatrixScreen`
  - `AppraisalsScreen`

#### `training_courses` (Migration 096, 097)
**Stores:** Training course definitions
- **Called by:** `TrainingMatrixScreen`

### Finance

#### `invoices` (Migration 108)
**Stores:** Client invoices
- **Fields:** id, invoice_number, client_id, client_type, period_start, period_end, total_amount, status, created_by, created_at
- **Called by:**
  - `AnalysisService._getRevenue()` - Revenue calculation
  - `AnalysisService._getRevenueBySource()` - Revenue by client type
  - `InvoiceScreen`, `InvoiceListScreen`
- **Not called by but should be:** More finance screens

#### `receipt_entries` (Migration 105, 106)
**Stores:** Expense receipts
- **Fields:** id, receipt_number, expense_category, total_amount, receipt_date, status, vendor_name, route_id, created_by, created_at
- **Called by:**
  - `AnalysisService._getExpenses()` - Expense calculation
  - `AnalysisService._getExpensesByCategory()` - Expenses by category
  - `AnalysisService._getRouteProfitability()` - Route expenses
  - `ReceiptEntryScreen`, `ReceiptListScreen`
- **Not called by but should be:** More finance screens

#### `organisation_profiles` (Migration 108)
**Stores:** Organisation profile details
- **Called by:** `OrganisationProfileScreen`

#### `suppliers` (Migration 104)
**Stores:** Supplier information
- **Called by:** `SupplierRegisterScreen`

### Communications

#### `messages` (Migration 114)
**Stores:** Carer-to-admin messages
- **Fields:** id, sender_id, recipient_id, subject, content, priority, message_type, is_read, is_urgent, action_required, action_deadline, action_completed, thread_id, attachment_url, created_at, updated_at, folder
- **Called by:**
  - `MessageService.getMessages()` - Inbox screen
  - `MessageService.getUnreadCount()` - Notification badge
  - `MessageService.markAsRead()` - Mark messages read
  - `MessageService.deleteMessage()` - Delete messages
  - `MessageService.sendMessage()` - Send messages
- **Not called by but should be:** Staff app messaging

### Notifications

#### `notifications` (Migration 001, 113)
**Stores:** System notifications
- **Fields:** id, user_id, title, message, type, priority, read, action_url, created_at
- **Called by:**
  - `NotificationService` - All notification operations
  - `NotificationHubScreen`, `NotificationBadge`
- **Not called by but should be:** More notification integration

### Action Plans & Lessons

#### `action_plans` (Migration 109)
**Stores:** Action plan records
- **Fields:** id, reference_number, title, description, priority, status, source_type, source_id, assigned_to, target_completion_date, actual_completion_date, created_by, created_at
- **Called by:**
  - `ActionPlanService` - CRUD operations
  - `ActionPlanListScreen`, `ActionPlanForm`, `ActionPlanDetailScreen`
- **Not called by but should be:** More action plan integration

#### `lessons_learnt` (Migration 110)
**Stores:** Lessons learnt records
- **Fields:** id, reference_number, title, description, severity, category, root_cause, corrective_action, status, implemented, source_type, source_id, created_by, created_at
- **Called by:**
  - `LessonLearntService` - CRUD operations
  - `LessonListScreen`, `LessonForm`, `LessonDetailScreen`
- **Not called by but should be:** More lessons learnt integration

### Policy Library

#### `policy_library` (Migration 111)
**Stores:** Policy documents
- **Fields:** id, policy_reference, title, category, status, content, next_review_date, owner_id, created_by, created_at
- **Called by:**
  - `PolicyService` - CRUD operations
  - `PolicyListScreen`, `PolicyForm`, `PolicyDetailScreen`
- **Not called by but should be:** More policy integration

### Analysis

#### `analysis_views` (Migration 112)
**Stores:** Saved report configurations
- **Fields:** id, view_name, view_type, configuration, created_by, created_at, updated_at
- **Called by:**
  - `AnalysisService.getAnalysisViews()` - Load saved views
  - `AnalysisService.createAnalysisView()` - Save new views
- **Not called by but should be:** Analysis dashboard UI integration

### Documents

#### `documents` (Migration 001)
**Stores:** Document records
- **Fields:** id, title, file_url, document_type, expiry_date, verified, created_by, created_at
- **Called by:** `DocumentManagementScreen`
- **Not called by but should be:** More document management

### Settings

#### `settings` (Migration 001)
**Stores:** System settings
- **Called by:** `SettingsScreen`

### Meetings

#### `meetings_log` (Migration 054, 104)
**Stores:** Meeting records
- **Called by:** `MeetingsLogScreen`

### Disciplinary

#### `disciplinary_cases` (Migration 099)
**Stores:** Disciplinary case records
- **Called by:** `DisciplinaryScreen`

### Leave & Pay

#### `leave_requests` (Migration 100)
**Stores:** Leave request records
- **Called by:** `LeaveScreen`

### Employee Welfare

#### `employee_welfare` (Migration 101)
**Stores:** Employee welfare records
- **Called by:** `EmployeeWelfareScreen`

### Employee Satisfaction

#### `employee_satisfaction` (Migration 102)
**Stores:** Employee satisfaction survey responses
- **Called by:** `EmployeeSatisfactionScreen`

### Employee Incentives

#### `employee_incentives` (Migration 103)
**Stores:** Employee incentive records
- **Called by:** `EmployeeIncentivesScreen`

### Drivers & Vehicles

#### `drivers` (Migration 068)
**Stores:** Driver records
- **Called by:** `DriversScreen`

#### `vehicles` (Migration 068)
**Stores:** Vehicle records
- **Called by:** `DriversScreen`

### Daily Monitoring

#### `food_fluid_charts` (Migration 006, 011)
**Stores:** Food and fluid intake logs
- **Called by:** `IntakeLogScreen`

#### `bowel_bladder_charts` (Migration 007, 012)
**Stores:** Bowel and bladder charts
- **Called by:** `StoolLogScreen`

#### `temperature_logs` (Migration 009, 014)
**Stores:** Temperature monitoring logs
- **Called by:** `TemperatureLogScreen`

#### `daily_notes` (Migration 083)
**Stores:** Daily care notes
- **Called by:** `DailyNotesScreen`

### Audits

#### `mar_audits` (Migration 008)
**Stores:** MAR (Medication Administration Record) audit data
- **Called by:** `MarAuditScreen`

#### `care_log_audits` (Migration 085)
**Stores:** Care log audit data
- **Called by:** `CareLogAuditScreen`

#### `care_plan_audits` (Migration 086)
**Stores:** Care plan audit data
- **Called by:** `CarePlanAuditScreen`

#### `spot_checks` (Migration 087, 088)
**Stores:** Spot check audit data
- **Called by:** `SpotCheckScreen`

### Safeguard

#### `safeguarding_records` (Migration 050, 093)
**Stores:** Safeguarding incident records
- **Called by:** `SafeguardingScreen`

### Supervision

#### `supervision_records` (Migration 019)
**Stores:** Staff supervision records
- **Called by:** `SupervisionMatrixScreen`

### Appraisals

#### `appraisal_forms` (Migration 020, 094)
**Stores:** Staff appraisal forms
- **Called by:** `AppraisalsScreen`

### Organisations

#### `organisations` (Migration 071)
**Stores:** Organisation records
- **Called by:** `OrganisationProfileScreen`

### Incidents

#### `incidents` (Referenced in AnalysisService)
**Stores:** Incident records
- **Called by:** `AnalysisService._getIncidentTrends()` - Incident trends
- **Not called by but should be:** Incidents screen (may not exist)

### Domain Care Routes

#### `dom_care_routes` (Referenced in AnalysisService)
**Stores:** Domestic care route definitions
- **Called by:** `AnalysisService._getRouteProfitability()` - Route profitability
- **Not called by but should be:** Route management screen

### Regulatory Reports

#### `regulatory_reports` (Migration 002)
**Stores:** Generated regulatory reports
- **Called by:** `ComplianceDashboard`

### Teaching Moments

#### `teaching_moments` (Migration 002)
**Stores:** User guidance/teaching moments
- **Called by:** `ComplianceDashboard`

---

## Service Classes & Their Database Connections

### AnalysisService
**File:** `admin-app/lib/services/analysis_service.dart`
**Database Tables Used:**
- `profiles` - Staff counts, roles, training compliance
- `service_users` - Service user counts, risk assessment compliance
- `invoices` - Revenue, revenue by source
- `receipt_entries` - Expenses, expenses by category, route profitability
- `shifts` - Shift coverage
- `visits` - Visit completion, route profitability
- `training_records` - Training compliance
- `audits` - Audit compliance (referenced but table may not exist)
- `incidents` - Incident trends (referenced but table may not exist)
- `dom_care_routes` - Route profitability (referenced but table may not exist)
- `carers` - Carer list (newly added)
- `service_users` - Service user list (newly added)
- `profiles` - Staff list (newly added)
- `analysis_views` - Saved analysis views

### MessageService
**File:** `admin-app/lib/services/message_service.dart`
**Database Tables Used:**
- `messages` - All message operations

### NotificationService
**File:** `admin-app/lib/services/notification_service.dart`
**Database Tables Used:**
- `notifications` - All notification operations

### ActionPlanService
**File:** `admin-app/lib/services/action_plan_service.dart`
**Database Tables Used:**
- `action_plans` - All action plan operations

### LessonLearntService
**File:** `admin-app/lib/services/lesson_learnt_service.dart`
**Database Tables Used:**
- `lessons_learnt` - All lessons learnt operations

### PolicyService
**File:** `admin-app/lib/services/policy_service.dart`
**Database Tables Used:**
- `policy_library` - All policy operations

### CarerService
**File:** `admin-app/lib/services/carer_service.dart`
**Database Tables Used:**
- `carers` - All carer operations

### ServiceUserService
**File:** `admin-app/lib/services/service_user_service.dart`
**Database Tables Used:**
- `service_users` - All service user operations

### ShiftService
**File:** `admin-app/lib/services/shift_service.dart`
**Database Tables Used:**
- `shifts` - All shift operations

### VisitService
**File:** `admin-app/lib/services/visit_service.dart`
**Database Tables Used:**
- `visits` - All visit operations

### InvoiceService
**File:** `admin-app/lib/services/invoice_service.dart`
**Database Tables Used:**
- `invoices` - All invoice operations

### ReceiptService
**File:** `admin-app/lib/services/receipt_service.dart`
**Database Tables Used:**
- `receipt_entries` - All receipt operations

### SupplierService
**File:** `admin-app/lib/services/supplier_service.dart`
**Database Tables Used:**
- `suppliers` - All supplier operations

### ComplianceService
**File:** `admin-app/lib/services/compliance_service.dart`
**Database Tables Used:**
- `compliance_flags` - Flag operations
- `compliance_scores` - Score operations
- `compliance_rules` - Rule operations
- `regulatory_reports` - Report operations
- `teaching_moments` - Teaching moment operations

---

## UI Screens & Their Data Sources

### Dashboard
- **AdminDashboard** (`ui/dashboard/admin_dashboard.dart`) - Main navigation hub
  - Pulls: Service users (for risk assessment picker), all navigation targets

### Analysis
- **AnalysisDashboardScreen** (`ui/analysis/analysis_dashboard_screen.dart`)
  - Financial tab: `AnalysisService.getFinancialSummary()` → `invoices`, `receipt_entries`, `dom_care_routes`
  - Compliance tab: `AnalysisService.getComplianceSummary()` → `profiles`, `service_users`, `training_records`, `audits`
  - Operational tab: `AnalysisService.getOperationalSummary()` → `shifts`, `visits`, `incidents`
  - Staff tab: `AnalysisService.getStaffMetrics()` → `profiles`; `AnalysisService.getStaff()` → `profiles`
  - Service Users tab: `AnalysisService.getServiceUserMetrics()` → `service_users`; `AnalysisService.getServiceUsers()` → `service_users`

### Communication
- **CarerInboxScreen** (`ui/communication/carer_inbox_screen.dart`)
  - `MessageService.getMessages()` → `messages`
  - `MessageService.getUnreadCount()` → `messages`
- **MessageComposeScreen** (`ui/communication/message_compose_screen.dart`)
  - `MessageService.sendMessage()` → `messages`
  - `MessageService.getCarers()` → `carers` (for recipient dropdown)
- **MessageDetailScreen** (`ui/communication/message_detail_screen.dart`)
  - `MessageService.getMessage()` → `messages`
- **WhistleblowerInboxScreen** (`ui/communication/whistleblower_inbox_screen.dart`)
  - `MessageService.getMessages()` → `messages` (filtered for whistleblower type)

### Finance
- **InvoiceScreen** (`ui/finance/invoice_screen.dart`) → `InvoiceService` → `invoices`
- **InvoiceListScreen** (`ui/finance/invoice_list_screen.dart`) → `InvoiceService` → `invoices`
- **ReceiptEntryScreen** (`ui/finance/receipt_entry_screen.dart`) → `ReceiptService` → `receipt_entries`
- **ReceiptListScreen** (`ui/finance/receipt_list_screen.dart`) → `ReceiptService` → `receipt_entries`
- **ProfitCalculatorScreen** (`ui/finance/profit_calculator_screen.dart`) → `AnalysisService` → `invoices`, `receipt_entries`
- **ProfitLossScreen** (`ui/finance/profit_loss_screen.dart`) → `AnalysisService` → `invoices`, `receipt_entries`
- **SupplierRegisterScreen** (`ui/finance/supplier_register_screen.dart`) → `SupplierService` → `suppliers`
- **OrganisationProfileScreen** (`ui/finance/organisation_profile_screen.dart`) → `OrganisationProfileService` → `organisation_profiles`

### Competency
- **CompetencyDashboardScreen** → `competency_frameworks`, `staff_competency_assessments`
- **All competency form screens** (catheter_care, fire_safety, first_aid, etc.) → `staff_competency_assessments`
  - **Issue:** These forms use text input for carer names instead of dropdowns from `carers` table
  - **Should use:** `AnalysisService.getCarers()` or a dedicated CarerService to populate dropdowns

### Risk Assessments
- **RiskAssessmentHubScreen** → Multiple risk assessment tables
- **CoshhRiskScreen** → `coshh_assessments`
- **CatheterCareRiskScreen** → `catheter_care_risk_assessments`
- **EpilepsyRiskScreen** → `epilepsy_risk_assessments`
- **DiabetesRiskScreen** → `diabetes_risk_assessments`
- **FireHazardScreen** → `fire_hazard_risk_assessments`
- **FallsRiskScreen** → `falls_risk_assessments`
- **ChokingRiskScreen** → `choking_risk_assessments`
- **MedicationRiskScreen** → `medication_risk_assessments`
- **WaterlowScreen** → `waterlow_assessments`
- **RespectFormScreen** → `respect_forms`
- **GrabsheetScreen** → `grabsheets`

### Monitoring
- **IntakeLogScreen** → `food_fluid_charts`
- **StoolLogScreen** → `bowel_bladder_charts`
- **TemperatureLogScreen** → `temperature_logs`
- **DailyNotesScreen** → `daily_notes`

### Audits
- **MarAuditScreen** → `mar_audits`
- **MarChartScreen** → `mar_chart`
- **CareLogAuditScreen** → `care_log_audits`
- **CarePlanAuditScreen** → `care_plan_audits`
- **SpotCheckScreen** → `spot_checks`

### Compliance
- **ComplianceDashboard** → `compliance_flags`, `compliance_scores`, `compliance_rules`, `regulatory_reports`, `teaching_moments`

### Safeguarding
- **SafeguardingScreen** → `safeguarding_records`

### Staff & HR
- **CarerListScreen** → `carers`
- **ServiceUserListScreen** → `service_users`
- **ShiftListScreen** → `shifts`
- **ShiftRotaScreen** → `shifts`
- **VisitListScreen** → `visits`
- **SupervisionMatrixScreen** → `supervision_records`
- **AppraisalsScreen** → `appraisal_forms`
- **TrainingMatrixScreen** → `training_records`, `training_courses`
- **DisciplinaryScreen** → `disciplinary_cases`
- **LeaveScreen** → `leave_requests`
- **EmployeeWelfareScreen** → `employee_welfare`
- **EmployeeSatisfactionScreen** → `employee_satisfaction`
- **EmployeeIncentivesScreen** → `employee_incentives`
- **MeetingsLogScreen** → `meetings_log`
- **EmergencyContactsScreen** → `emergency_contacts`
- **DriversScreen** → `drivers`, `vehicles`
- **SignUpScreen** → `profiles`

### Actions
- **ActionPlanListScreen** → `action_plans`
- **ActionPlanForm** → `action_plans`
- **ActionPlanDetailScreen** → `action_plans`
- **ActionPlanReportsScreen** → `action_plans`

### Lessons
- **LessonListScreen** → `lessons_learnt`
- **LessonForm** → `lessons_learnt`
- **LessonDetailScreen** → `lessons_learnt`
- **LessonReportsScreen** → `lessons_learnt`
- **RootCauseAnalysisScreen** → `lessons_learnt`

### Policies
- **PolicyListScreen** → `policy_library`
- **PolicyForm** → `policy_library`
- **PolicyDetailScreen** → `policy_library`
- **PolicyAcknowledgmentScreen** → `policy_library`
- **PolicyReportsScreen** → `policy_library`

### Notifications
- **NotificationHubScreen** → `notifications`
- **NotificationSettingsScreen** → `notifications`
- **NotificationBadge** → `notifications`

---

## Schemas Not Being Called (But Should Be)

### 1. `staff_competency_assessments` - `action_plan` column
- **Issue:** PGRST204 error - "Could not find the 'action_plan' column"
- **Migration:** 022, 052, 100, 102, 103, 105
- **Should be called by:** Competency assessment forms when saving action plans
- **Fix needed:** Add `action_plan` column via migration

### 2. `carers` - Used in competency forms
- **Issue:** Competency assessment forms use text input for carer names
- **Should be called by:** All competency form screens (catheter_care, fire_safety, first_aid, etc.)
- **Fix needed:** Replace text fields with dropdowns populated from `carers` table

### 3. `audits` table
- **Referenced by:** `AnalysisService._getAuditCompliance()`
- **Issue:** Table may not exist as a unified audits table
- **Should be called by:** Compliance dashboard audit section

### 4. `incidents` table
- **Referenced by:** `AnalysisService._getIncidentTrends()`
- **Issue:** Table may not exist
- **Should be called by:** Incident trends in operational dashboard

### 5. `dom_care_routes` table
- **Referenced by:** `AnalysisService._getRouteProfitability()`
- **Issue:** Table may not exist
- **Should be called by:** Route profitability in financial dashboard

### 6. `emergency_contacts` table
- **Referenced by:** `EmergencyContactsScreen`
- **Issue:** May not be properly connected
- **Should be called by:** Emergency contacts management

### 7. `grabsheets` table
- **Referenced by:** `GrabsheetScreen`
- **Issue:** May not be properly connected
- **Should be called by:** Grab sheet management

### 8. `waterlow_assessments` table
- **Referenced by:** `WaterlowScreen`
- **Issue:** May not be properly connected
- **Should be called by:** Waterlow assessment management

### 9. `medication_risk_assessments` table
- **Referenced by:** `MedicationRiskScreen`
- **Issue:** May not be properly connected
- **Should be called by:** Medication risk assessment management

### 10. `respect_forms` table
- **Referenced by:** `RespectFormScreen`
- **Issue:** May not be properly connected
- **Should be called by:** ReSPECT form management

### 11. `falls_risk_assessments` table
- **Referenced by:** `FallsRiskScreen`
- **Issue:** May not be properly connected
- **Should be called by:** Falls risk assessment management

### 12. `mar_chart` table
- **Referenced by:** `MarChartScreen`
- **Issue:** May not be properly connected
- **Should be called by:** MAR chart management

### 13. `mar_audits` table
- **Referenced by:** `MarAuditScreen`
- **Issue:** May not be properly connected
- **Should be called by:** MAR audit management

---

## Key Issues Identified

### 1. Competency Assessment Forms - Carer Name Text Input
**Problem:** All competency assessment forms use `TextFormField` for entering carer names as free text.
**Solution:** Replace with `DropdownButtonFormField` populated from `carers` table via `AnalysisService.getCarers()` or `CarerService`.

### 2. Missing `action_plan` Column
**Problem:** `staff_competency_assessments` table lacks `action_plan` column, causing PGRST204 error.
**Solution:** Add migration to add `action_plan` column to `staff_competency_assessments` table.

### 3. Analysis Service Count Method
**Problem:** `AnalysisService` uses `.count()` method which returns `PostgrestList` without a `count` property in newer Supabase versions.
**Solution:** Use `.select('id', count: 'exact')` or cast response to access count.

### 4. Missing Import for PolicyListScreen and LessonListScreen
**Problem:** `policy_dashboard_widget.dart` and `lesson_dashboard_widget.dart` reference `PolicyListScreen` and `LessonListScreen` without importing them.
**Solution:** Add import statements for these screens.

### 5. Carer Inbox Navigation Conflict
**Problem:** `admin_dashboard.dart` imports `CarerInboxScreen` from both `admin/carer_inbox_screen.dart` and `communication/carer_inbox_screen.dart`.
**Solution:** Use prefix import for the communication version.

---

## Migration Summary

| Migration | Key Tables Created |
|-----------|-------------------|
| 001 | profiles, carers, service_users, shifts, visits, documents, notifications, settings |
| 002 | compliance_flags, compliance_scores, teaching_moments, regulatory_reports, compliance_rules |
| 005 | careplan_audit_items, pre_admission_assessments |
| 006 | choking_risk_assessments, food_fluid_charts |
| 007 | bowel_bladder_charts, falls_risk_assessments |
| 008 | mar_audits, repositioning_charts |
| 009 | sleep_charts, waterlow_assessments |
| 010 | mental_capacity_assessments |
| 015 | infection_control_audits |
| 016 | health_safety_audits |
| 017 | fire_safety_audits |
| 018 | equipment_audits |
| 019 | supervision_records |
| 020 | appraisal_forms |
| 021 | training_records |
| 022 | staff_competency_assessments |
| 027 | shift_rota |
| 029 | client_and_family_tables |
| 031-046 | Various risk assessment tables |
| 048 | admin_feature_tables |
| 049 | staff_management_tables |
| 050 | safeguarding_tables |
| 051 | finance_tables |
| 052 | staff_competency_records |
| 054 | meetings_log |
| 068 | drivers, vehicles |
| 071 | organisations |
| 075-082 | Enhanced risk assessment tables |
| 083 | daily_notes |
| 084 | mar_chart |
| 085-087 | care_log_audits, care_plan_audits, spot_checks |
| 092 | compliance_dashboard_enhancement |
| 093 | safeguarding_hub |
| 094 | staff_appraisals |
| 096 | training_courses |
| 099 | disciplinary_cases |
| 100 | competency_framework, leave_and_pay |
| 101 | employee_welfare, employee_satisfaction |
| 102 | competency_notifications, employee_incentives |
| 103 | missing_columns |
| 104 | supplier_register |
| 105 | receipt_entries |
| 106 | extend_receipts_for_profit |
| 107 | profit_calculations |
| 108 | invoice_system |
| 109 | action_plans |
| 110 | lessons_learnt |
| 111 | policy_library |
| 112 | analysis_tables |
| 113 | notifications |
| 114 | messages (carer_inbox) |
</arg_value>
<task_progress>
- [x] Analyze admin-app architecture and data flow
- [x] Document all database schemas and their purpose
- [x] Map service classes to database tables
- [x] Map UI screens to their data sources
- [x] Identify schemas not being called but should be
- [x] Document key issues and fixes needed
- [x] Create comprehensive markdown documentation file
</task_progress></tool_call>