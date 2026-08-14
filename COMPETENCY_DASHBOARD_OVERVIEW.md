# Competency Dashboard and Form Overview

## 1. Database Migrations

### Migration 100: `competency_framework.sql` — Core Schema
Creates the foundational tables for the competency management system:

- **competency_framework** — Defines all competencies (id, code, name, category, description, required_level 1-5, assessment_method, evidence_requirements, regulatory_reference)
- **role_competency_requirements** — Maps competencies to roles (care_worker, senior_carer, team_leader, manager, nurse, admin) with required levels
- **staff_competency_assessments** — Records actual assessments (staff, assessor, date, achieved_level, evidence, status, expiry_date)
- **staff_development_plans** — Stores development plans with goals in JSONB format
- RLS policies enforce tenant isolation per organisation
- Indexes on competency_code, category, role_type, staff_id, status, expiry_date

### Migration 101: `seed_competency_framework.sql` — Seed Data
Inserts 28 CQC-aligned competencies across 6 categories:

| Category | Code Prefix | Competencies |
|----------|------------|--------------|
| Clinical | CLIN-001–010 | Medication Admin, Catheter Care, Wound Care, Diabetes, Epilepsy, MCA, DoLS, End of Life, Infection Control, Nutrition |
| Communication | COMM-001–004 | Person-Centred, Dementia, Conflict Resolution, Cultural Sensitivity |
| Safety | SAFE-001–005 | Manual Handling, Fire Safety, Health & Safety, Lone Working, First Aid |
| Professional | PROF-001–005 | Dignity & Respect, Duty of Candour, GDPR, Whistleblowing, EDI |
| Management | MGT-001–003 | Supervision & Appraisal, Rota Management, Incident Management |
| Digital | DIG-001–002 | Digital Care Records, Video Consultation |

Also seeds role-level requirements: care_workers get clinical/communication/safety/professional; managers get management; nurses get advanced clinical.

### Migration 102: `competency_notifications.sql` — Notification System
- Creates the **notifications** table with user_id, title, body, notification_type, expiry_date, is_read
- Trigger `check_competency_expiry()` — Fires on INSERT/UPDATE of staff_competency_assessments
  - Sends expiry reminders when next_review_date is within 30 days
  - Sends gap alerts when overall_rating = 'not_competent'
  - Also notifies managers of competency gaps
- Trigger `check_development_plan_reminders()` — Fires on INSERT/UPDATE of staff_development_plans
  - Notifies when development plan is created
  - Sends reminders when review_date is within 14 days
- `cleanup_old_notifications()` — Purges read notifications older than 90 days

---

## 2. Service Layer

### `competency_service.dart`
Core service class connecting forms to the Supabase backend:

| Method | Purpose |
|--------|---------|
| `getCompetencyFramework()` | All active competencies |
| `getCompetenciesByCategory(category)` | Filtered by category |
| `getRoleRequirements(roleType)` | Role-specific requirements |
| `getAllRoleRequirements()` | All role mappings |
| `getStaffCompetencies(staffId)` | Current assessments for a staff member |
| `getStaffCompetencyLevels(staffId)` | Map of competency_id → achieved_level |
| `createAssessment(assessment)` | Creates new competency assessment |
| `updateAssessment(id, data)` | Updates existing assessment |
| `approveAssessment(id)` | Sets status to 'approved' |
| `rejectAssessment(id, reason)` | Sets status to 'rejected' with notes |
| `getDevelopmentPlan(staffId)` | Current active development plan |
| `createDevelopmentPlan(plan)` | Creates a new development plan |
| `updateDevelopmentPlan(id, data)` | Updates a development plan |
| `calculateGap(staffId, roleType)` | Returns missing/below_level/met competencies |
| `getRecommendedTraining(staffId, roleType)` | Lists training needed |
| `getCompetencyStats(staffId)` | Statistics for a staff member |
| `getCompetencySummary()` | Organisation-wide summary stats |
| `getExpiredCompetencies()` | Competencies past expiry date |
| `getExpiringCompetencies(days)` | Competencies expiring within N days |
| `getRecordsByType(type)` | Records filtered by assessment type |
| `getAllRecords()` | All records for the organisation |
| `getAllStaff()` | Combined profiles + carers |

---

## 3. Dashboard Screen

### `competency_dashboard_screen.dart`
The central hub for competency management.

**Sections:**
1. **Quick Actions** — Direct buttons to all competency forms
2. **Competency Overview** — Summary cards showing total assessed, compliance %, competent, needs development, not competent, average score, expired, expiring soon
3. **Attention Required** — Alerts for expired and expiring competencies
4. **Role Compliance** — Progress bars per role (care_worker, senior_carer, team_leader, manager, nurse)
5. **Priority Gaps** — Top competency gaps requiring attention
6. **Competency Categories Grid** — Clickable category cards navigatin to filtered list screens

---

## 4. Competency Forms — Questions & Structure

### A. Moving & Assisting (`moving_assisting_competency_form.dart`)
**Sections:**
- Staff Information (name, care home, assessment date, assessor)
- **Before Moving and Assisting** (Yes/No/N/A):
  - Care plan and risk assessment checked for changes
  - Effective communication and consent gained
  - Correct number of staff ready
  - All equipment checked
- **Throughout Moving and Assisting** (Yes/No/N/A):
  - Resident's independence promoted
  - Resident comfortable and reassured
  - Communication maintained
  - Privacy and dignity respected
- **After Moving and Assisting** (Yes/No/N/A):
  - Equipment stored safely
  - Resident comfortable with everything within reach
  - Call bell placed within reach
- **Manoeuvre Observations** (Observed? / Performed Correctly? / Notes):
  - Rolling in bed, Moving up the bed, Moving forward in chair, Laying to sitting, Sit to laying, Full hoist transfer, Standing hoist transfer, Sit to stand, Stand to sit, Standing transfer, Mobilising, Full hoist from floor (managers)
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### B. Spot Check (`spot_check_competency_form.dart`)
**Sections:**
- Staff Information (name, care home, spot check date/time, assessor)
- **Punctuality & Attendance** (Yes/No/N/A):
  - Arrived on time, Break times appropriate, Notification given if late, Overtime agreed, Absence communicated
- **Communication & Consent** (Yes/No/N/A):
  - Greeted politely, Introduced self, Consent obtained, Communication clear
- **Care Delivery & Documentation** (Yes/No/N/A):
  - Care plan followed, Tasks completed, Documentation accurate, Documentation timely, Handover completed, Concerns reported
- **Health & Safety** (Yes/No/N/A):
  - PPE used, Equipment safe, Hazard identified, Emergency procedure known
- **Medication Observations** (if applicable): Observed, Performed correctly, Notes
- **Spot Check Observation Notes**: Open text
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### C. Fire Safety (`fire_safety_competency_form.dart`)
**Sections:**
- Staff Information (name, care home, assessment date, assessor)
- **Fire Prevention** (Yes/No/N/A):
  - Fire hazards identified, Electrical safety checked, Fire doors checked, Smoking policy known, Kitchen safety maintained
- **Fire Detection & Equipment** (Yes/No/N/A):
  - Alarm sound recognised, Alarm panel location, Extinguisher types known, Extinguisher locations known, Emergency lighting known
- **Evacuation Procedures** (Yes/No/N/A):
  - Emergency exits known, Evacuation routes, Assembly point location, Resident evacuation (PEEPs), Fire warden duties (managers)
- **Communication & Emergency Response** (Yes/No/N/A):
  - Emergency dialled, Information given to operator, Residents/staff accounted for, Fire log updated
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### D. Communication (`communication_competency_form.dart`)
**Sections:**
- Staff Information (name, department, assessment date, assessor)
- **Verbal Communication** (Yes/No/N/A):
  - Clear speech and tone, Appropriate language, Active listening, Questions encouraged, Adjusts communication style
- **Non-Verbal Communication** (Yes/No/N/A):
  - Positive body language, Eye contact appropriate, Facial expressions, Personal space respected
- **Written Communication** (Yes/No/N/A):
  - Records legible, Records accurate, Records timely, Records completed, Confidentiality maintained
- **Communication with Specific Groups** (Yes/No/N/A):
  - Dementia communication, Hearing/vision loss adjustments, Learning disabilities, Non-English speakers
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### E. Safeguarding (`safeguarding_competency_form.dart`)
**Sections:**
- Staff Information (name, care home, assessment date, assessor)
- **Safeguarding Knowledge** (Yes/No/N/A):
  - Types of abuse known, Signs of abuse recognised, Reporting procedure known, Whistleblowing aware, Prevent duty known
- **Reporting & Recording** (Yes/No/N/A):
  - Incident reported promptly, Recorded accurately, Evidence preserved, Confidentiality maintained, Duty of candour
- **Vulnerable Groups** (Yes/No/N/A):
  - Children safeguarding, Adults safeguarding, Mental capacity considered, Advocacy offered
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### F. Catheter Care (`catheter_care_competency_form.dart`)
**Sections:**
- Staff Information (name, care home, assessment date, assessor)
- **Catheter Care Criteria** (Yes/No/N/A):
  - Hand hygiene performed, PPE worn appropriately, Catheter patency checked, Catheter site clean and dry, Drainage bag below bladder, Bag emptied correctly, Catheter secured, Patient comfort ensured, Fluid intake monitored, Documentation completed
- **Infection Prevention** (Yes/No/N/A):
  - Aseptic technique maintained, Catheter site cleaned, Drainage bag changed, Specimen collected correctly, Signs of infection monitored
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### G. Infection Control (`infection_control_competency_form.dart`)
**Sections:**
- Staff Information (name, department, assessment date, assessor)
- **Hand Hygiene** (Yes/No/N/A):
  - Hand washing technique, Hand washing frequency, Alcohol gel used, Gloves changed, Skin condition checked
- **PPE Use** (Yes/No/N/A):
  - Gloves worn correctly, Aprons worn correctly, Masks worn correctly, Eye protection used, PPE removed correctly, PPE disposed correctly
- **Waste Management** (Yes/No/N/A):
  - Clinical waste segregated, Sharps disposed correctly, Waste bins used, Waste storage area clean
- **Environment & Equipment** (Yes/No/N/A):
  - Equipment cleaned after use, Commodes cleaned, Bed spaces clean, Spillages managed, Isolation precautions followed
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### H. Dignity & Respect (`dignity_respect_competency_form.dart`)
**Sections:**
- Staff Information (name, department, assessment date, assessor)
- **Privacy & Confidentiality** (Yes/No/N/A):
  - Privacy maintained during care, Doors closed/curtains drawn, Confidential information protected, Personal data handled correctly
- **Choice & Autonomy** (Yes/No/N/A):
  - Choices offered and respected, Independence promoted, Informed consent obtained, Decisions respected
- **Communication & Interaction** (Yes/No/N/A):
  - Addresses resident by preference, Respectful tone and manner, Listening without interruption, Empathy compassion shown
- **Personal Care & Appearance** (Yes/No/N/A):
  - Personal grooming preferences respected, Clothing preferences respected, Cultural/religious needs respected, Personal possessions respected
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### I. Mental Capacity (`mental_capacity_competency_form.dart`)
**Sections:**
- Staff Information (name, department, assessment date, assessor)
- **MCA Principles Knowledge** (Yes/No/N/A):
  - Presumption of capacity, Right to make unwise decisions, Best interests decision-making, Least restrictive option
- **Capacity Assessment Process** (Yes/No/N/A):
  - Assessed at time of decision, Functional test applied, Support provided before assessment, Diagnosed correctly, Assessment documented
- **Best Interests Decision-Making** (Yes/No/N/A):
  - Person included in process, Past wishes considered, Others consulted, Least restrictive option chosen, Decision documented
- **DoLS Application** (Yes/No/N/A):
  - Deprivation of liberty recognised, DoLS authorised, Urgent authorisations documented, Standard authorisations applied, Liberty Protection Safeguards known
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### J. First Aid (`first_aid_competency_form.dart`)
**Sections:**
- Staff Information (name, department, assessment date, assessor)
- **Emergency Response** (Yes/No/N/A):
  - Danger assessed, Response checked, Help called, Airway opened, Breathing checked, CPR initiated, AED used correctly
- **Injury Management** (Yes/No/N/A):
  - Bleeding controlled, Burns managed, Fractures immobilised, Spinal injuries managed, Choking response correct
- **Medical Emergencies** (Yes/No/N/A):
  - Heart attack recognised, Stroke recognised (FAST), Seizure management, Diabetic emergency, Allergic reaction (anaphylaxis)
- **Recovery & Handover** (Yes/No/N/A):
  - Recovery position used, Incident recorded, Handover given to emergency services, First aid kit restocked
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

### K. Pressure Prevention (`pressure_prevention_competency_form.dart`)
**Sections:**
- Staff Information (name, department, assessment date, assessor)
- **Risk Assessment** (Yes/No/N/A):
  - Waterlow score completed correctly, Risk assessment updated, Risk level identified, Contributing factors identified
- **Skin Inspection** (Yes/No/N/A):
  - Skin inspected regularly, Pressure areas checked, Skin condition documented, Changes reported promptly
- **Preventive Measures** (Yes/No/N/A):
  - Repositioning schedule followed, Pressure-relieving equipment used, Nutrition and hydration monitored, Moisture managed, Incontinence managed
- **Documentation & Communication** (Yes/No/N/A):
  - Care plan reflects current needs, Repositioning chart completed, Skin map updated, Escalation protocol followed
- **Overall Decision**: Competent / Not Competent
- **Assessor Sign-off**: Date

---

## 5. Data Model

### `competency_assessment.dart` — Model Classes
| Class | Fields |
|-------|--------|
| **CompetencyAssessment** | id, staffId, staffName, assessorId, assessorName, assessmentDate, assessmentType, competencyRatings[], overallRating, passed, developmentAreas[], actionPlan, nextReviewDate, status, staffSignOffDate, createdAt, updatedAt |
| **CompetencyRating** | competencyId, competencyName, achievedLevel (1-5), evidence, assessorNotes, assessedDate |
| **DevelopmentPlan** | id, staffId, createdBy, createdDate, reviewDate, goals, notes, status, createdAt, updatedAt |
| **DevelopmentGoal** | competencyId, targetLevel, targetDate, status |

### `competency_framework.dart` — Model Classes
| Class | Fields |
|-------|--------|
| **Competency** | id, competencyCode, competencyName, category, description, requiredLevel, assessmentMethod[], evidenceRequirements[], regulatoryReference, isActive, organisationId |
| **RoleRequirement** | id, roleType, competencyId, requiredLevel, isMandatory |

---

## 6. System Architecture

```
User → CompetencyDashboardScreen
         ├── Quick Action Buttons → Direct form navigation
         │     ├── moving_assisting_competency_form.dart
         │     ├── spot_check_competency_form.dart
         │     ├── fire_safety_competency_form.dart
         │     ├── communication_competency_form.dart
         │     ├── safeguarding_competency_form.dart
         │     ├── catheter_care_competency_form.dart
         │     ├── infection_control_competency_form.dart
         │     ├── dignity_respect_competency_form.dart
         │     ├── mental_capacity_competency_form.dart
         │     ├── first_aid_competency_form.dart
         │     └── pressure_prevention_competency_form.dart
         │
         ├── Summary Cards → competency_service.getCompetencySummary()
         ├── Alerts Section → getExpiredCompetencies(), getExpiringCompetencies(30)
         │     └── Tap → CompetencyListScreen with filter
         ├── Role Compliance → calculateGap('', role) for each role
         └── Categories Grid → CompetencyListScreen filtered by category
                 └── Tap → CompetencyListScreen

Each form → CompetencyService
               └── createAssessment() / updateAssessment()
                     └── Supabase (competency_framework, staff_competency_assessments, etc.)
                           └── PostgreSQL triggers (notifications)
```

---

## 7. Workflow Summary

1. **Admin views dashboard** → sees overview stats, alerts, role compliance, gaps
2. **Admin selects a form** from Quick Actions or navigates via categories
3. **Form loads with assessment criteria** structured in Yes/No/N/A sections
4. **Admin completes assessment** with critical criteria checks and overall decision
5. **Assessment is saved** via CompetencyService → Supabase
6. **Notifications fire** if competency is expiring (30 days) or if staff member is not competent
7. **Dashboard updates** on next refresh to reflect new assessment data
8. **Development plans** can be created for staff needing improvement
9. **CQC compliance reports** can be generated from `cqc_compliance_report.dart`

---

## 8. File Index

| File | Path | Purpose |
|------|------|---------|
| Migration 100 | `supabase/migrations/100_competency_framework.sql` | Core schema |
| Migration 101 | `supabase/migrations/101_seed_competency_framework.sql` | Seed data |
| Migration 102 | `supabase/migrations/102_competency_notifications.sql` | Notification system |
| Model | `admin-app/lib/models/competency_framework.dart` | Competency/RoleRequirement models |
| Model | `admin-app/lib/models/competency_assessment.dart` | Assessment/DevelopmentPlan models |
| Service | `admin-app/lib/services/competency_service.dart` | Core service layer |
| Service | `admin-app/lib/services/notification_service.dart` | Notification service |
| Dashboard | `admin-app/lib/ui/competency/competency_dashboard_screen.dart` | Main dashboard |
| List | `admin-app/lib/ui/competency/competency_list_screen.dart` | Record listing |
| Reports | `admin-app/lib/ui/competency/competency_reports_screen.dart` | Reporting screen |
| CQC Report | `admin-app/lib/ui/compliance/cqc_compliance_report.dart` | CQC compliance report |
| Plans List | `admin-app/lib/ui/competency/development_plans_screen.dart` | Development plans list |
| Plan Form | `admin-app/lib/ui/competency/development_plan_form.dart` | Development plan form |
| Staff View | `staff-app/lib/ui/competency/my_competencies_screen.dart` | Staff: own competencies |
| Staff Service | `staff-app/lib/services/competency_service.dart` | Staff: competency service |
| Form | `admin-app/lib/ui/competency/moving_assisting_competency_form.dart` | Moving & Assisting |
| Form | `admin-app/lib/ui/competency/spot_check_competency_form.dart` | Spot Check |
| Form | `admin-app/lib/ui/competency/fire_safety_competency_form.dart` | Fire Safety |
| Form | `admin-app/lib/ui/competency/communication_competency_form.dart` | Communication |
| Form | `admin-app/lib/ui/competency/safeguarding_competency_form.dart` | Safeguarding |
| Form | `admin-app/lib/ui/competency/catheter_care_competency_form.dart` | Catheter Care |
| Form | `admin-app/lib/ui/competency/infection_control_competency_form.dart` | Infection Control |
| Form | `admin-app/lib/ui/competency/dignity_respect_competency_form.dart` | Dignity & Respect |
| Form | `admin-app/lib/ui/competency/mental_capacity_competency_form.dart` | Mental Capacity |
| Form | `admin-app/lib/ui/competency/first_aid_competency_form.dart` | First Aid |
| Form | `admin-app/lib/ui/competency/pressure_prevention_competency_form.dart` | Pressure Prevention |