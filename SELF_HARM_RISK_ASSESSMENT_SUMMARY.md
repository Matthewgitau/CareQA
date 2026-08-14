# Self-Harm/Suicide Risk Assessment Implementation Summary

## Overview
The Self-Harm/Suicide Risk Assessment feature has been successfully implemented based on the CC157-Prevention and Management of Self-harm and Suicide guidelines. This feature provides comprehensive mental health safeguarding with 15 critical assessment points and immediate escalation capabilities.

## Database Schema

### Table: `self_harm_risk_assessments`
- **Primary Key**: `id` (UUID)
- **Foreign Keys**: `service_user_id`, `assessor_id`
- **Critical Fields**: 15 assessment points as specified in CC157 guidelines
- **Risk Levels**: low, medium, high, immediate
- **Status Tracking**: draft, completed, reviewed, escalated

### Key Features:
- **Immediate escalation** for high-risk responses (current ideation = "constant")
- **Safeguarding alerts** for method planning and giving away possessions
- **Follow-up action plan** generation
- **Crisis contact information** display
- **Digital signature** support with automatic escalation checks

## Files Created

### 1. Database Migration
- **File**: `supabase/migrations/035_self_harm_risk_assessments.sql`
- **Purpose**: Creates the main assessment table with all required fields, indexes, RLS policies, and database functions
- **Key Functions**:
  - `calculate_self_harm_risk_level()` - Automated risk calculation
  - `submit_self_harm_assessment()` - Submission with escalation checks
  - `flag_high_risk_self_harm_assessments()` - High-risk monitoring
  - `get_self_harm_assessment_summary()` - Service user summary

### 2. Admin App Model
- **File**: `admin-app/lib/models/self_harm_assessment.dart`
- **Purpose**: Data model with business logic, validation, and helper methods
- **Key Features**:
  - 15 assessment fields as per CC157 guidelines
  - Risk calculation methods
  - Escalation check methods
  - Helper methods for display formatting
  - Factory methods for creating new assessments

### 3. Admin App Service
- **File**: `admin-app/lib/services/self_harm_service.dart`
- **Purpose**: Business logic layer for database operations
- **Key Methods**:
  - CRUD operations for assessments
  - High-risk assessment retrieval
  - Assessment validation
  - Risk level calculation
  - Escalation management

### 4. Staff App Model
- **File**: `staff-app/lib/models/self_harm_assessment.dart`
- **Purpose**: Identical model for staff app with same business logic
- **Note**: Mirrors admin app model for consistency

### 5. Staff App Service
- **File**: `staff-app/lib/services/self_harm_service.dart`
- **Purpose**: Service layer for staff app operations
- **Note**: Mirrors admin app service for consistency

### 6. Staff App Form
- **File**: `staff-app/lib/ui/risk/self_harm_risk_form.dart`
- **Purpose**: Interactive assessment form for staff to complete
- **Key Features**:
  - 15 assessment fields with proper validation
  - Real-time risk level calculation
  - Immediate escalation warnings
  - Digital signature capture
  - Action plan generation
  - Crisis contact management

### 7. Admin App Screen
- **File**: `admin-app/lib/ui/risk/self_harm_risk_screen.dart`
- **Purpose**: Management interface for administrators
- **Key Features**:
  - Assessment listing with filtering
  - High-risk alert display
  - Search functionality
  - Assessment creation/editing
  - Bulk management capabilities

## Key Assessment Fields (15 Critical Points)

1. **Current suicidal ideation** (never/sometimes/frequently/constant) - CRITICAL
2. **Previous self-harm attempts** - Count and details
3. **Method of self-harm** - Specific method and planning
4. **Frequency of thoughts** - Never/rarely/sometimes/often/constant
5. **Triggers** - Relationship, financial, health, other
6. **Protective factors** - Family, friend support, routine
7. **Access to means** - What means are accessible
8. **Mental health diagnosis** - Current diagnoses
9. **Current treatment** - Medication, therapy, both, none
10. **Recent life events** - Stressors and changes
11. **Substance use** - None/occasional/regular/problematic
12. **Sleep disturbances** - Yes/No
13. **Withdrawal from activities** - Yes/No
14. **Giving away possessions** - Yes/No - SAFEGUARDING ALERT
15. **Making plans/arrangements** - Yes/No

## Critical Flags and Escalation

### Immediate Escalation Required:
- Current suicidal ideation = "constant"
- Method of self-harm is planned
- Giving away possessions

### Safeguarding Alerts:
- Method planned = true
- Giving away possessions = true
- Previous self-harm attempts > 0
- Access to means = true

### Risk Level Calculation:
- **Low**: No risk factors, protective factors present
- **Medium**: 1-2 risk factors, some protective factors
- **High**: Multiple risk factors, limited protective factors
- **Immediate**: Any immediate escalation criteria met

## Security and Compliance

### Row Level Security (RLS):
- Users can only access assessments for their service users
- Assessors can access their own assessments
- Care home staff can access assessments in their care home

### Data Validation:
- Required field validation
- Range validation for numerical fields
- Enum validation for dropdown fields
- Business rule validation for risk calculation

### Audit Trail:
- Created/updated timestamps
- Digital signature tracking
- Status change logging
- Reviewer tracking

## Integration Points

### With Other Systems:
- **Service User Management**: Links to service user records
- **Carer Management**: Links to assessor records
- **Safeguarding Module**: Escalation to safeguarding team
- **Notification System**: Alerts for high-risk cases

### API Endpoints:
- Assessment creation and updates
- High-risk assessment retrieval
- Assessment summaries
- Validation checks
- Escalation triggers

## Usage Workflow

### 1. Assessment Creation
1. Staff member selects service user
2. Form loads with default values
3. Staff completes 15 assessment fields
4. System calculates risk level in real-time
5. Immediate escalation warnings appear if needed

### 2. Assessment Submission
1. Staff reviews completed assessment
2. Digital signature captured
3. System automatically checks for escalation criteria
4. Assessment status updated to "completed" or "escalated"
5. Notifications sent to appropriate teams

### 3. Management and Monitoring
1. Administrators view assessment lists
2. Filter by risk level, status, date range
3. High-risk alerts displayed prominently
4. Escalated cases managed through safeguarding workflow
5. Regular review scheduling

## Testing and Validation

### Test Scenarios:
- [ ] Create new assessment with low risk
- [ ] Create assessment with immediate escalation criteria
- [ ] Edit existing assessment
- [ ] Validate risk level calculation
- [ ] Test escalation workflow
- [ ] Verify RLS permissions
- [ ] Test digital signature functionality

### Validation Rules:
- Required fields cannot be empty
- Risk level must be calculated correctly
- Escalation criteria must trigger automatically
- Status updates must be accurate
- Digital signatures must be captured

## Future Enhancements

### Potential Improvements:
1. **Mobile optimization** for tablet use during assessments
2. **Voice input** for faster data entry
3. **Integration with mental health EHR systems**
4. **Predictive analytics** for risk trends
5. **Family notification system** for emergency contacts
6. **Integration with crisis response teams**

### Reporting Features:
1. **Risk trend analysis** over time
2. **Care home risk profiles**
3. **Staff assessment patterns**
4. **Escalation effectiveness metrics**
5. **Compliance reporting**

## Compliance with CC157 Guidelines

This implementation fully complies with the CC157-Prevention and Management of Self-harm and Suicide guidelines by:

1. **Capturing all 15 critical assessment points**
2. **Providing immediate escalation for high-risk cases**
3. **Including safeguarding alert mechanisms**
4. **Generating follow-up action plans**
5. **Displaying crisis contact information**
6. **Maintaining comprehensive audit trails**
7. **Ensuring proper documentation and signatures**

The system provides a robust, secure, and user-friendly solution for managing self-harm and suicide risk assessments in care home environments while maintaining strict compliance with regulatory requirements.