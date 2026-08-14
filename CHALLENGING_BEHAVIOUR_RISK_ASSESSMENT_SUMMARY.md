# Challenging Behaviour Risk Assessment (PBS) Implementation Summary

## Overview
The Challenging Behaviour Risk Assessment system has been successfully implemented as part of the CareQA platform. This assessment tool follows the Positive Behaviour Support (PBS) framework to identify, assess, and manage challenging behaviours in care settings.

## Database Schema

### Table: `challenging_behaviour_risk_assessments`
- **Primary Key**: `id` (UUID)
- **Foreign Key**: `service_user_id` (references service_users)
- **Core Fields**:
  - Assessment metadata: `assessment_date`, `behaviour_type`, `behaviour_frequency`, `behaviour_duration_minutes`
  - Risk assessment: `intensity`, `triggers`, `warning_signs`, `de_escalation_strategies`
  - Clinical information: `medication_used`, `injuries_caused`, `injuries_to_self`, `injuries_to_others`, `property_damage`
  - Support and interventions: `staff_trained_de_escalation`, `pbs_plan_in_place`, `environmental_modifications_needed`, `support_needs`
  - Risk management: `risk_level`, `action_plan`, `review_date`, `next_behaviour_monitoring_date`
  - Metadata: `assessor_name`, `assessor_signature`, timestamps

### Key Features
- **Auto-calculation**: Risk level automatically calculated based on critical rules and high-risk factors
- **Critical rules**: Specific triggers for urgent/escalation scenarios
- **Triggers**: Database triggers ensure data consistency and automatic risk calculation
- **RLS Policies**: Row-level security ensures proper access control
- **Indexes**: Optimized for common queries by service user, date, behaviour type, and risk level

## Application Components

### Admin App
- **Model**: `admin-app/lib/models/challenging_behaviour_assessment.dart`
  - Complete data model with validation and helper methods
  - Risk calculation methods and status display helpers
  - Comprehensive property accessors for display formatting
  - Proper serialization/deserialization for Supabase integration

- **Service**: `admin-app/lib/services/challenging_behaviour_service.dart`
  - Comprehensive CRUD operations
  - Advanced querying capabilities (by risk level, behaviour type, assessor, etc.)
  - Specialized methods for urgent assessments and monitoring
  - Statistics and reporting capabilities
  - Error handling and validation

- **UI Screen**: `admin-app/lib/ui/risk/challenging_behaviour_screen.dart`
  - List view with detailed assessment cards
  - Visual risk indicators and status chips
  - Critical alert highlighting for urgent cases
  - Comprehensive assessment information display
  - Refresh functionality and error handling

### Staff App
- **Form**: `staff-app/lib/ui/risk/challenging_behaviour_form.dart`
  - Comprehensive form with multi-select options for triggers, warning signs, and strategies
  - Real-time risk level calculation and display
  - Critical rule highlighting (urgent, escalation, review)
  - Physical measurements and behavioural data input
  - PBS plan and intervention tracking
  - Review and monitoring date management

## Positive Behaviour Support Framework

### Assessment Components
1. **Behaviour Identification**: Type, frequency, duration, intensity
2. **Trigger Analysis**: Communication, pain, environment, activity, other factors
3. **Warning Signs**: Body language, verbal cues, physiological indicators
4. **De-escalation Strategies**: Calm voice, personal space, distraction, etc.
5. **Risk Assessment**: Injuries, property damage, support needs
6. **Interventions**: Medication, PBS plans, environmental modifications

### Critical Rules Implementation
- **URGENT**: Injuries to others + Severe intensity
- **ESCALATION**: Self-harm + High frequency (hourly/daily)
- **REVIEW**: Property damage + Aggression

### Risk Level Calculation
- **Low Risk**: 0-1 high-risk factors
- **Medium Risk**: 2-3 high-risk factors
- **High Risk**: 4+ high-risk factors
- **Critical Risk**: Automatic trigger from critical rules

## Key Features

### Automatic Risk Calculation
- High-risk factor counting (intensity, frequency, injuries, property damage)
- Critical rule evaluation for immediate alerts
- Real-time risk level updates in forms

### Clinical Decision Support
- Visual risk indicators with emoji and color coding
- Critical alert highlighting for immediate attention
- Status chips for key behavioural factors
- Trigger and strategy tracking

### PBS Integration
- Positive Behaviour Support plan tracking
- Environmental modification documentation
- Staff training status monitoring
- Multi-disciplinary team coordination

### Follow-up Management
- Review date tracking with due date notifications
- Behaviour monitoring date scheduling
- Action plan documentation and tracking
- Progress monitoring over time

### Data Validation
- Behaviour type validation (aggression, self-harm, wandering, etc.)
- Frequency validation (hourly, daily, weekly, monthly)
- Intensity validation (mild, moderate, severe)
- Duration validation (0-1440 minutes)
- Support needs validation (none, 1:1, 2:1, specialist)

## Integration Points

### Service User Association
- Each assessment linked to specific service user
- Access controlled through service user relationships
- Historical tracking for individual behaviour patterns

### Care Team Collaboration
- Assessor name and signature tracking
- Multi-disciplinary team input coordination
- PBS plan coordination across team members
- Training status tracking for de-escalation techniques

### Care Plan Integration
- Behaviour triggers feed into care plans
- Environmental modifications inform care planning
- Support needs inform staffing decisions
- Risk level informs care approach

## Usage Scenarios

### Initial Assessment
1. Staff completes comprehensive behavioural assessment
2. System calculates risk level automatically
3. Critical rules trigger immediate alerts if applicable
4. PBS plan components are documented
5. Follow-up dates are scheduled

### Ongoing Monitoring
1. Regular behaviour monitoring tracks progress
2. Review dates ensure timely reassessment
3. Risk level changes trigger intervention reviews
4. PBS plan effectiveness is evaluated

### Team Coordination
1. High-risk cases trigger team meetings
2. PBS plans are shared across team members
3. Environmental modifications are implemented
4. Staff training needs are identified

## Benefits

### For Care Staff
- Standardized PBS assessment process
- Clear risk categorization and alerts
- Comprehensive trigger and strategy documentation
- Coordinated team approach to behaviour management

### For Service Users
- Individualized behaviour support plans
- Reduced use of restrictive interventions
- Improved understanding of triggers and needs
- Enhanced safety and dignity

### For Care Homes
- Compliance with PBS standards
- Reduced incidents and injuries
- Improved staff confidence in behaviour management
- Better outcomes through proactive support

## Future Enhancements

### Potential Additions
- Behaviour tracking charts and trend analysis
- PBS plan effectiveness monitoring
- Staff training module integration
- Family/carer input coordination
- Mobile app support for real-time documentation

### Reporting Capabilities
- Behaviour incident frequency tracking
- PBS intervention effectiveness analysis
- Staff training impact measurement
- Environmental modification outcomes
- Compliance reporting for regulatory requirements

This implementation provides a comprehensive foundation for challenging behaviour assessment and management within the CareQA platform, supporting both individual care and organizational quality improvement initiatives through the Positive Behaviour Support framework.