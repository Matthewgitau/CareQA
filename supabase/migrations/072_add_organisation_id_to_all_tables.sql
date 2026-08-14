-- Add organisation_id to ALL tables
DO $$
DECLARE
  tables TEXT[] := ARRAY[
    'carers', 'service_users', 'shifts', 'visits', 'documents',
    'notifications', 'risk_assessments', 'choking_risk_assessments',
    'falls_risk_assessments', 'medication_risk_assessments',
    'mental_capacity_assessments', 'waterlow_assessments',
    'mar_audits', 'spot_checks', 'careplan_audits',
    'food_fluid_charts', 'bowel_bladder_charts', 'repositioning_charts',
    'sleep_charts', 'infection_control_audits', 'health_safety_audits',
    'fire_safety_audits', 'equipment_audits', 'supervision_records',
    'appraisal_forms', 'training_records', 'competency_assessments',
    'dols_assessments', 'moving_handling_assessments',
    'skin_integrity_assessments', 'oral_health_assessments',
    'drivers', 'vehicles', 'vehicle_assignments', 'messages',
    'action_plans', 'lessons_learnt', 'policies', 'complaints',
    'compliments', 'whistleblower_reports', 'medication_incidents',
    'missing_items', 'meetings_log', 'invoices', 'expenses', 'suppliers'
  ];
  table_name TEXT;
BEGIN
  FOREACH table_name IN ARRAY tables
  LOOP
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS organisation_id UUID REFERENCES organisations(id);', table_name);
  END LOOP;
END $$;

-- Create indexes on organisation_id for key tables
DO $$
DECLARE
  tables TEXT[] := ARRAY[
    'carers', 'service_users', 'shifts', 'visits'
  ];
  table_name TEXT;
BEGIN
  FOREACH table_name IN ARRAY tables
  LOOP
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%I_organisation_id ON %I (organisation_id);', table_name, table_name);
  END LOOP;
END $$;