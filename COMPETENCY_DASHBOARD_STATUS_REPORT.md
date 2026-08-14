# Competency Dashboard - Status Report

**Date:** 22/07/2026  
**Purpose:** Analysis of current competency assessment system for developer discussion

---

## Executive Summary

The competency dashboard system is **partially implemented** with core infrastructure in place but **missing critical assessment and update workflows**. While the database schema, models, and basic UI screens exist, there are **no active forms or workflows** for assessing and updating employee competencies in the current codebase.

---

## Current File Structure

### Database Layer
```
supabase/migrations/
├── 096_training_courses.sql          # Training courses table
├── 097_seed_training_courses.sql     # Initial training data
└── 099_create_disciplinary_cases.sql # Disciplinary cases (related)
```

### Models Layer
```
admin-app/lib/models/
├── training_course.dart              # Training course model
├── carer_training_record.dart        # Individual training records
└── carer_training_history.dart       # Training history tracking
```

### Service Layer
```
admin-app/lib/services/
└── training_service.dart             # Training CRUD operations
```

### UI Layer
```
admin-app/lib/ui/
├── staff/
│   ├── training_matrix_screen.dart   # Main training/compliance dashboard
│   └── disciplinary_screen.dart      # Disciplinary cases screen
└── training/
    └── training_matrix_screen.dart   # Alternative training view
```

---

## Current Competency Assessment Flow

### How Competencies Are Currently Tracked

**1. Training Matrix Screen (`training_matrix_screen.dart`)**
- Displays staff training compliance status
- Shows mandatory training completion rates
- Color-coded indicators (green = compliant, red = non-compliant)
- Filterable by staff member, department, training type

**2. Training Records (`carer_training_record.dart`)**
```dart
class CarerTrainingRecord {
  final String id;
  final String carerId;
  final String carerName;
  final String trainingCourseId;
  final String trainingCourseName;
  final DateTime? completionDate;
  final DateTime? expiryDate;
  final String? certificateUrl;
  final String status; // 'not_started', 'in_progress', 'completed', 'expired'
  final int? score;
  final String? assessorNotes;
  // ...
}
```

**3. Training Courses (`training_course.dart`)**
```dart
class TrainingCourse {
  final String id;
  final String courseName;
  final String courseCode;
  final String category; // 'mandatory', 'optional', 'specialist'
  final int durationHours;
  final DateTime? validUntil;
  final bool requiresAssessment;
  final int? passingScore;
  final List<String> competencies; // ['medication_admin', 'wound_care', ...]
  // ...
}
```

---

## Current Assessment Process

### What EXISTS:
1. **Training Course Catalog** - Pre-defined courses with competencies
2. **Training Records** - Track completion status per staff member
3. **Expiry Tracking** - Automatic flagging of expired training
4. **Compliance Dashboard** - Overview of training compliance rates

### What is MISSING:

#### 1. **Competency Assessment Form** ❌
**Status:** NOT IMPLEMENTED

**What's needed:**
- Form to assess staff against competency framework
- Rating scale (e.g., 1-5 or Beginner/Intermediate/Advanced)
- Evidence collection (documents, observations)
- Assessor signature/approval workflow
- Development plan generation

**Example structure needed:**
```dart
class CompetencyAssessmentForm {
  // Staff being assessed
  String staffId;
  String staffName;
  
  // Assessment period
  DateTime assessmentDate;
  String assessmentType; // 'annual', 'probation', 'return_to_work'
  
  // Competency areas (example)
  Map<String, CompetencyRating> competencies; {
    'medication_administration': CompetencyRating(
      level: 4,
      evidence: 'Observed 5 times, all correct',
      assessor: 'John Smith',
      date: DateTime(2026, 7, 22)
    ),
    'wound_care': CompetencyRating(...),
    'manual_handling': CompetencyRating(...),
    'communication_skills': CompetencyRating(...),
    'risk_assessment': CompetencyRating(...),
    // ... more competencies
  }
  
  // Overall rating
  String overallRating;
  bool isCompetent;
  
  // Development needs
  List<String> developmentAreas;
  String actionPlan;
  
  // Sign-off
  String assessorId;
  String assessorSignature;
  DateTime? staffAcknowledgmentDate;
}
```

#### 2. **Competency Framework Definition** ❌
**Status:** NOT IMPLEMENTED

**What's needed:**
- Define competency categories (Clinical, Administrative, Interpersonal)
- Define specific competencies per role (Care Worker, Senior Carer, Manager)
- Proficiency levels definition
- Required competencies per role

**Example structure:**
```sql
CREATE TABLE competency_framework (
  id UUID PRIMARY KEY,
  category TEXT, -- 'Clinical Skills', 'Communication', 'Professionalism'
  competency_name TEXT, -- 'Medication Administration'
  competency_code TEXT, -- 'MED-ADMIN-001'
  description TEXT,
  role_levels TEXT[], -- ['care_worker', 'senior_carer', 'manager']
  assessment_criteria TEXT,
  evidence_requirements TEXT
);
```

#### 3. **Competency Update Workflow** ❌
**Status:** NOT IMPLEMENTED

**Current gap:** 
- No form to update individual competency ratings
- No workflow for assessors to submit assessments
- No approval process
- No notification system for expired competencies

**What happens now:**
```
Staff completes training → Training record created → Status = 'completed'
                              ↓
                    [GAP] No competency rating update
                              ↓
                    [GAP] No skill verification
                              ↓
                    [GAP] No development plan created
```

**What should happen:**
```
Staff completes training → Training record created → Status = 'completed'
                              ↓
                    Assessor observes staff → Fills competency assessment form
                              ↓
                    Competency rating updated → Evidence attached
                              ↓
                    Overall competency score calculated → Development plan created
                              ↓
                    Manager approves → Staff notified → Next review date set
```

#### 4. **Competency Gap Analysis** ❌
**Status:** NOT IMPLEMENTED

**Missing functionality:**
- Compare current competencies vs. required competencies per role
- Identify gaps
- Suggest training courses to fill gaps
- Track gap closure progress

---

## Current Data Flow

### What Currently Works:
```
Training Course Created
    ↓
Staff Assigned Training
    ↓
Staff Completes Training
    ↓
Training Record Created (status = 'completed')
    ↓
Training Matrix Shows Compliance
```

### What's Broken/Missing:
```
[NO ASSESSMENT] → Competencies not verified
[NO RATING] → No skill level recorded
[NO EVIDENCE] → No proof of competency
[NO GAP ANALYSIS] → Can't identify weaknesses
[NO DEVELOPMENT PLAN] → No structured improvement path
```

---

## Database Schema Analysis

### Existing Tables:
1. **training_courses** - Course catalog ✅
2. **carer_training_records** - Training completion tracking ✅
3. **carer_training_history** - Historical training data ✅

### Missing Tables:
1. **competency_framework** - Competency definitions ❌
2. **competency_assessments** - Assessment records ❌
3. **competency_evidence** - Evidence attachments ❌
4. **competency_development_plans** - Improvement plans ❌
5. **competency_gaps** - Gap analysis results ❌

---

## UI Screens Analysis

### Existing Screens:
1. **Training Matrix Screen** (`training_matrix_screen.dart`)
   - Shows training compliance
   - Lists staff and their training status
   - Color-coded compliance indicators
   - **Missing:** Competency ratings, assessment forms, gap analysis

### Missing Screens:
1. **Competency Assessment Form** ❌
   - Assessor fills out ratings
   - Adds evidence
   - Creates development plan
   
2. **Competency Dashboard** ❌
   - Overall competency scores per staff
   - Competency heat maps
   - Gap analysis visualization
   
3. **Competency Development Plan** ❌
   - Action items
   - Training recommendations
   - Progress tracking

---

## Code Examples: Current vs. Needed

### Current: Training Record (What Exists)
```dart
// admin-app/lib/models/carer_training_record.dart
class CarerTrainingRecord {
  final String id;
  final String carerId;
  final String trainingCourseId;
  final DateTime? completionDate;
  final String status; // 'completed'
  final String? certificateUrl;
  
  // This tracks TRAINING COMPLETION only
  // It does NOT track COMPETENCY LEVEL
}
```

### Needed: Competency Assessment (What's Missing)
```dart
// NEW FILE: admin-app/lib/models/competency_assessment.dart
class CompetencyAssessment {
  final String id;
  final String staffId;
  final String staffName;
  final String assessorId;
  final String assessorName;
  final DateTime assessmentDate;
  final String assessmentType; // 'annual', 'probation', 'spot'
  
  // Competency ratings
  final Map<String, CompetencyRating> competencyRatings;
  
  // Overall assessment
  final String overallRating; // 'competent', 'development_needed', 'not_competent'
  final bool passed;
  
  // Development
  final List<String> developmentAreas;
  final String actionPlan;
  final DateTime? nextReviewDate;
  
  // Sign-off
  final String status; // 'draft', 'submitted', 'approved', 'acknowledged'
  final DateTime? staffSignOffDate;
}

class CompetencyRating {
  final String competencyId;
  final String competencyName;
  final int level; // 1-5 scale
  final String evidence;
  final String? certificateUrl;
  final String assessorNotes;
  final DateTime assessedDate;
}
```

---

## Integration Points

### What Needs to Connect:

1. **Training Completion → Competency Update**
   ```dart
   // When training is marked complete, prompt for competency assessment
   Future<void> onTrainingCompleted(String trainingCourseId) async {
     // Check if this training requires competency assessment
     final course = await _trainingService.getCourse(trainingCourseId);
     if (course.requiresAssessment) {
       // Navigate to competency assessment form
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (context) => CompetencyAssessmentForm(
             staffId: staffId,
             trainingCourseId: trainingCourseId,
             competencies: course.competencies, // ['medication_admin', ...]
           ),
         ),
       );
     }
   }
   ```

2. **Competency Gaps → Training Recommendations**
   ```dart
   Future<List<TrainingCourse>> getRecommendedTraining(String staffId) async {
     // Get current competencies
     final current = await _competencyService.getCurrentCompetencies(staffId);
     
     // Get required competencies for role
     final required = await _competencyService.getRequiredCompetencies(staffId);
     
     // Find gaps
     final gaps = required.where((comp) => 
       !current.containsKey(comp) || current[comp]!.level < 3
     ).toList();
     
     // Recommend courses
     return _trainingService.getCoursesForCompetencies(gaps);
   }
   ```

---

## Missing Forms Checklist

### Critical (Blocking):
- [ ] **Competency Assessment Form** - Core assessment workflow
- [ ] **Competency Framework Setup** - Define what to assess
- [ ] **Development Plan Form** - Create improvement plans

### Important (High Priority):
- [ ] **Competency Gap Analysis Report** - Identify weaknesses
- [ ] **Training Recommendation Form** - Suggest courses based on gaps
- [ ] **Assessor Feedback Form** - Detailed feedback collection

### Nice to Have:
- [ ] **Self-Assessment Form** - Staff self-evaluation
- [ ] **360-Degree Feedback** - Peer review component
- [ ] **Portfolio Builder** - Evidence collection interface

---

## Recommendations for Discussion

### Immediate Actions Needed:

1. **Define Competency Framework**
   - What competencies are required per role?
   - What are the proficiency levels?
   - Who defines this? (Clinical lead, Manager, HR)

2. **Choose Assessment Method**
   - Direct observation?
   - Portfolio of evidence?
   - Multiple choice test?
   - Practical assessment?
   - Combination?

3. **Design Assessment Workflow**
   - Who assesses? (Line manager, Clinical lead, External assessor)
   - How often? (Annual, probation, after training)
   - Approval process?
   - What happens if not competent?

4. **Integration Points**
   - Link training completion to competency assessment
   - Auto-expire competencies based on CPD requirements
   - Alert managers when competencies expiring

### Technical Debt:
- Current training records don't link to competency ratings
- No audit trail for competency changes
- No versioning of competency frameworks
- No historical tracking of competency progression

---

## Example: Ideal Competency Assessment Flow

```dart
// Step 1: Staff completes training
await _trainingService.completeTraining(staffId, courseId);

// Step 2: System checks if assessment required
final course = await _trainingService.getCourse(courseId);
if (course.requiresAssessment) {
  
  // Step 3: Create assessment form
  final assessment = CompetencyAssessment(
    staffId: staffId,
    assessorId: currentUser.id,
    assessmentDate: DateTime.now(),
    assessmentType: 'post_training',
    competencies: course.competencies.map((comp) {
      return CompetencyRating(
        competencyId: comp,
        level: 0, // To be filled
        evidence: '',
        assessorNotes: '',
        assessedDate: DateTime.now(),
      );
    }).toList(),
  );
  
  // Step 4: Assessor fills out form
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CompetencyAssessmentForm(assessment: assessment),
    ),
  );
}

// Step 5: Assessment submitted
// - Updates competency ratings
// - Creates development plan if needed
// - Sets next review date
// - Notifies manager

// Step 6: Dashboard updates
// - Shows competency scores
// - Highlights gaps
// - Recommends training
```

---

## Questions for Developer Discussion

1. **Scope:** Should we build a full competency management system or just add basic ratings to existing training records?

2. **Framework:** Do we have a defined competency framework, or do we need to create one?

3. **Assessment:** Who will be the assessors? What's the approval workflow?

4. **Integration:** How should this integrate with existing training, disciplinary, and performance systems?

5. **Compliance:** Are there specific CQC or regulatory requirements for competency assessment?

6. **Timeline:** What's the priority - basic competency tracking or full assessment workflow?

---

## Summary

**Current State:** Training completion tracking exists, but **no competency assessment or rating system** is implemented.

**Gap:** Missing forms, workflows, and database tables for assessing and updating employee competencies.

**Impact:** Cannot verify if staff are actually competent, only if they've completed training.

**Effort to Complete:** 
- Database: 3-4 new tables (1-2 days)
- Models: 3-4 new models (1 day)
- Service: Competency service with CRUD + gap analysis (2-3 days)
- UI: 3-4 new screens (3-4 days)
- **Total: ~1-2 weeks** for basic implementation

**Recommendation:** Prioritize defining the competency framework first, then build the assessment workflow around it.