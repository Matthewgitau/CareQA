# Nutrition Risk Assessment (MUST) Implementation Summary

## Overview
The Nutrition Risk Assessment (MUST) system has been successfully implemented as part of the CareQA platform. This assessment tool helps identify individuals at risk of malnutrition using the Malnutrition Universal Screening Tool (MUST) criteria.

## Database Schema

### Table: `nutrition_risk_assessments`
- **Primary Key**: `id` (UUID)
- **Foreign Key**: `service_user_id` (references service_users)
- **Core Fields**:
  - Physical measurements: `height_cm`, `current_weight_kg`, `weight_3_6_months_ago_kg`
  - Calculated values: `bmi`, `weight_loss_percentage`, `must_total_score`
  - Risk assessment: `bmi_score`, `weight_loss_score`, `acute_disease_effect_score`, `risk_category`
  - Clinical information: `dietary_requirements`, `food_preferences_allergies`, `swallowing_difficulties`
  - Interventions: `referred_to_dietitian`, `supplementation_required`, `action_plan`
  - Follow-up: `review_date`, `next_weight_check_date`
  - Metadata: `assessor_name`, `assessor_signature`, timestamps

### Key Features
- **Auto-calculation**: BMI, weight loss percentage, MUST scores, and risk categories are automatically calculated
- **Triggers**: Database triggers ensure data consistency and automatic score calculation
- **RLS Policies**: Row-level security ensures proper access control
- **Indexes**: Optimized for common queries by service user, date, and risk category

## Application Components

### Admin App
- **Model**: `admin-app/lib/models/nutrition_assessment.dart`
  - Complete data model with validation and calculation methods
  - Helper methods for risk categorization and status display
  - Proper serialization/deserialization for Supabase integration

- **Service**: `admin-app/lib/services/nutrition_service.dart`
  - Comprehensive CRUD operations
  - Advanced querying capabilities (by risk category, MUST score, assessor, etc.)
  - Specialized methods for review tracking and statistics
  - Error handling and validation

- **UI Screen**: `admin-app/lib/ui/risk/nutrition_risk_screen.dart`
  - List view with detailed assessment cards
  - Visual risk indicators and status chips
  - Quick access to dietary information and action plans
  - Refresh functionality and error handling

### Staff App
- **Form**: `staff-app/lib/ui/risk/nutrition_risk_form.dart`
  - Comprehensive form with real-time calculations
  - Physical measurements input with validation
  - MUST score calculation and risk category display
  - Dietary requirements and intervention tracking
  - Review and follow-up date management

## MUST Assessment Criteria

### BMI Scoring
- **Score 0**: BMI > 20 kg/m²
- **Score 1**: BMI 18.5-20 kg/m²
- **Score 2**: BMI < 18.5 kg/m²

### Weight Loss Scoring
- **Score 0**: < 5% weight loss
- **Score 1**: 5-10% weight loss
- **Score 2**: > 10% weight loss

### Acute Disease Effect
- **Score 0**: No acute disease effect
- **Score 2**: Acute disease effect (e.g., requiring >5 days of reduced intake)

### Risk Categories
- **Low Risk**: MUST Score = 0
- **Medium Risk**: MUST Score = 1
- **High Risk**: MUST Score ≥ 2

## Key Features

### Automatic Calculations
- BMI calculation from height and weight
- Weight loss percentage from current and historical weight
- MUST total score from individual components
- Risk category determination

### Clinical Decision Support
- Visual indicators for risk levels
- Status chips for key measurements
- Dietary requirement tracking
- Swallowing difficulty identification
- Referral and supplementation tracking

### Follow-up Management
- Review date tracking
- Weight check scheduling
- Due date notifications
- Action plan documentation

### Data Validation
- Physical measurement ranges (height: 0-250cm, weight: 0-300kg)
- Logical consistency checks
- Required field validation
- Date validation

## Integration Points

### Service User Association
- Each assessment is linked to a specific service user
- Access controlled through service user relationships
- Historical tracking for individual monitoring

### Care Team Collaboration
- Assessor name and signature tracking
- Multi-disciplinary team coordination
- Referral management to dietitians
- Supplementation coordination

### Care Plan Integration
- Dietary requirements feed into care plans
- Action plans for nutrition interventions
- Risk category informs care planning
- Follow-up scheduling integration

## Usage Scenarios

### Initial Assessment
1. Staff completes physical measurements
2. System calculates MUST scores automatically
3. Risk category is determined
4. Dietary requirements and interventions are documented
5. Follow-up dates are scheduled

### Ongoing Monitoring
1. Regular weight checks track progress
2. Review dates ensure timely reassessment
3. Risk category changes trigger interventions
4. Action plans are updated as needed

### Team Coordination
1. High-risk cases trigger dietitian referrals
2. Swallowing difficulties prompt speech therapy
3. Supplementation needs are coordinated
4. Dietary requirements inform meal planning

## Benefits

### For Care Staff
- Standardized assessment process
- Automatic calculations reduce errors
- Clear risk categorization
- Comprehensive documentation

### For Service Users
- Early identification of malnutrition risk
- Personalized dietary interventions
- Regular monitoring and follow-up
- Coordinated care team approach

### For Care Homes
- Compliance with nutrition standards
- Risk mitigation through early detection
- Improved nutritional outcomes
- Better care coordination

## Future Enhancements

### Potential Additions
- Integration with meal planning systems
- Automated weight tracking from scales
- Nutritional intake monitoring
- Trend analysis over time
- Mobile app support for bedside assessments
- Integration with electronic health records

### Reporting Capabilities
- Malnutrition prevalence tracking
- Intervention effectiveness analysis
- Weight trend monitoring
- Referral pattern analysis
- Compliance reporting

This implementation provides a comprehensive foundation for nutrition risk assessment and management within the CareQA platform, supporting both individual care and organizational quality improvement initiatives.