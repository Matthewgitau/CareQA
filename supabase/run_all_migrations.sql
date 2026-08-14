-- Run all CareQA migrations in order
-- This script executes migrations 001 through 026

-- Migration 001: Initial Schema
\i 001_initial_schema.sql

-- Migration 002: Compliance Engine
\i 002_compliance_engine.sql

-- Migration 003: Compliance Settings
\i 003_compliance_settings.sql

-- Migration 004: Medication Risk Assessment
\i 004_medication_risk_assessment.sql

-- Migration 005: Pre-Admission Assessment
\i 005_pre_admission_assessment.sql

-- Migration 006: Choking Risk Assessment
\i 006_choking_risk_assessment.sql

-- Migration 007: Falls Risk Assessment
\i 007_falls_risk_assessment.sql

-- Migration 008: MAR Audit
\i 008_mar_audit.sql

-- Migration 009: Waterlow Assessment
\i 009_waterlow_assessment.sql

-- Migration 010: Mental Capacity Assessment
\i 010_mental_capacity_assessment.sql

-- Migration 011: Food & Fluid Chart
\i 011_food_fluid_chart.sql

-- Migration 012: Bowel & Bladder Chart
\i 012_bowel_bladder_chart.sql

-- Migration 013: Repositioning Chart
\i 013_repositioning_chart.sql

-- Migration 014: Sleep Chart
\i 014_sleep_chart.sql

-- Migration 015: Infection Control Audit
\i 015_infection_control_audit.sql

-- Migration 016: Health & Safety Audit
\i 016_health_safety_audit.sql

-- Migration 017: Fire Safety Audit
\i 017_fire_safety_audit.sql

-- Migration 018: Equipment Audit
\i 018_equipment_audit.sql

-- Migration 019: Supervision Record
\i 019_supervision_record.sql

-- Migration 020: Appraisal Form
\i 020_appraisal_form.sql

-- Migration 021: Training Record
\i 021_training_record.sql

-- Migration 022: Competency Assessment
\i 022_competency_assessment.sql

-- Migration 023: DoLS Assessment
\i 023_dols_assessment.sql

-- Migration 024: Moving & Handling Assessment
\i 024_moving_handling_assessment.sql

-- Migration 025: Skin Integrity Assessment
\i 025_skin_integrity_assessment.sql

-- Migration 026: Oral Health Assessment
\i 026_oral_health_assessment.sql

-- Verify all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'service_users', 'carers', 'shifts', 'visits',
  'medication_risk_assessments', 'pre_admission_assessments',
  'choking_risk_assessments', 'falls_risk_assessments',
  'mar_audits', 'waterlow_assessments', 'mental_capacity_assessments',
  'food_fluid_charts', 'bowel_bladder_charts', 'repositioning_charts',
  'sleep_charts', 'infection_control_audits', 'health_safety_audits',
  'fire_safety_audits', 'equipment_audits', 'supervision_records',
  'appraisal_forms', 'training_records', 'competency_assessments',
  'dols_assessments', 'moving_handling_assessments',
  'skin_integrity_assessments', 'oral_health_assessments'
)
ORDER BY table_name;

-- Verify RLS policies are enabled
SELECT schemaname, tablename, rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN (
  'service_users', 'carers', 'shifts', 'visits',
  'medication_risk_assessments', 'pre_admission_assessments',
  'choking_risk_assessments', 'falls_risk_assessments',
  'mar_audits', 'waterlow_assessments', 'mental_capacity_assessments',
  'food_fluid_charts', 'bowel_bladder_charts', 'repositioning_charts',
  'sleep_charts', 'infection_control_audits', 'health_safety_audits',
  'fire_safety_audits', 'equipment_audits', 'supervision_records',
  'appraisal_forms', 'training_records', 'competency_assessments',
  'dols_assessments', 'moving_handling_assessments',
  'skin_integrity_assessments', 'oral_health_assessments'
)
AND rowsecurity = true
ORDER BY tablename;

-- Show table row counts
SELECT 
  'service_users' as table_name, COUNT(*) as row_count FROM service_users
UNION ALL
SELECT 'carers', COUNT(*) FROM carers
UNION ALL
SELECT 'shifts', COUNT(*) FROM shifts
UNION ALL
SELECT 'visits', COUNT(*) FROM visits
UNION ALL
SELECT 'medication_risk_assessments', COUNT(*) FROM medication_risk_assessments
UNION ALL
SELECT 'pre_admission_assessments', COUNT(*) FROM pre_admission_assessments
UNION ALL
SELECT 'choking_risk_assessments', COUNT(*) FROM choking_risk_assessments
UNION ALL
SELECT 'falls_risk_assessments', COUNT(*) FROM falls_risk_assessments
UNION ALL
SELECT 'mar_audits', COUNT(*) FROM mar_audits
UNION ALL
SELECT 'waterlow_assessments', COUNT(*) FROM waterlow_assessments
UNION ALL
SELECT 'mental_capacity_assessments', COUNT(*) FROM mental_capacity_assessments
UNION ALL
SELECT 'food_fluid_charts', COUNT(*) FROM food_fluid_charts
UNION ALL
SELECT 'bowel_bladder_charts', COUNT(*) FROM bowel_bladder_charts
UNION ALL
SELECT 'repositioning_charts', COUNT(*) FROM repositioning_charts
UNION ALL
SELECT 'sleep_charts', COUNT(*) FROM sleep_charts
UNION ALL
SELECT 'infection_control_audits', COUNT(*) FROM infection_control_audits
UNION ALL
SELECT 'health_safety_audits', COUNT(*) FROM health_safety_audits
UNION ALL
SELECT 'fire_safety_audits', COUNT(*) FROM fire_safety_audits
UNION ALL
SELECT 'equipment_audits', COUNT(*) FROM equipment_audits
UNION ALL
SELECT 'supervision_records', COUNT(*) FROM supervision_records
UNION ALL
SELECT 'appraisal_forms', COUNT(*) FROM appraisal_forms
UNION ALL
SELECT 'training_records', COUNT(*) FROM training_records
UNION ALL
SELECT 'competency_assessments', COUNT(*) FROM competency_assessments
UNION ALL
SELECT 'dols_assessments', COUNT(*) FROM dols_assessments
UNION ALL
SELECT 'moving_handling_assessments', COUNT(*) FROM moving_handling_assessments
UNION ALL
SELECT 'skin_integrity_assessments', COUNT(*) FROM skin_integrity_assessments
UNION ALL
SELECT 'oral_health_assessments', COUNT(*) FROM oral_health_assessments
ORDER BY table_name;

-- Show compliance rules
SELECT rule_name, rule_type, description, severity 
FROM compliance_rules 
ORDER BY rule_type, rule_name;

-- Show compliance settings
SELECT setting_name, setting_value, description 
FROM compliance_settings 
ORDER BY setting_name;