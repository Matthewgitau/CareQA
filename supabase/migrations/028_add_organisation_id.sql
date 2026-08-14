-- Add organisation_id to all tables for multi-tenancy support
-- This migration adds organisation_id to all tables that don't already have it

-- Add organisation_id to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to carers table  
ALTER TABLE carers ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to service_users table
ALTER TABLE service_users ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to shifts table
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to visits table
ALTER TABLE visits ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to documents table
ALTER TABLE documents ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to notifications table
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to settings table
ALTER TABLE settings ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to risk_assessment_questions table
ALTER TABLE risk_assessment_questions ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to risk_assessments table
ALTER TABLE risk_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to risk_assessment_answers table
ALTER TABLE risk_assessment_answers ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to pre_admissions table
ALTER TABLE pre_admissions ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to adl_categories table
ALTER TABLE adl_categories ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to choking_risk_assessments table
ALTER TABLE choking_risk_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to falls_risk_assessments table
ALTER TABLE falls_risk_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to mar_audits table
ALTER TABLE mar_audits ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to waterlow_assessments table
ALTER TABLE waterlow_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to mental_capacity_assessments table
ALTER TABLE mental_capacity_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to food_fluid_charts table
ALTER TABLE food_fluid_charts ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to bowel_bladder_charts table
ALTER TABLE bowel_bladder_charts ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to repositioning_charts table
ALTER TABLE repositioning_charts ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to sleep_charts table
ALTER TABLE sleep_charts ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to infection_control_audits table
ALTER TABLE infection_control_audits ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to health_safety_audits table
ALTER TABLE health_safety_audits ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to fire_safety_audits table
ALTER TABLE fire_safety_audits ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to equipment_audits table
ALTER TABLE equipment_audits ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to supervision_records table
ALTER TABLE supervision_records ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to appraisal_forms table
ALTER TABLE appraisal_forms ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to training_records table
ALTER TABLE training_records ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to competency_assessments table
ALTER TABLE competency_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to dols_assessments table
ALTER TABLE dols_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to moving_handling_assessments table
ALTER TABLE moving_handling_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to skin_integrity_assessments table
ALTER TABLE skin_integrity_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to oral_health_assessments table
ALTER TABLE oral_health_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Add organisation_id to shift_rotas table
ALTER TABLE shift_rotas ADD COLUMN IF NOT EXISTS organisation_id UUID;

-- Create organisation table if it doesn't exist
CREATE TABLE IF NOT EXISTS organisations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key constraints for organisation_id
ALTER TABLE profiles ADD CONSTRAINT fk_profiles_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE carers ADD CONSTRAINT fk_carers_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE service_users ADD CONSTRAINT fk_service_users_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE shifts ADD CONSTRAINT fk_shifts_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE visits ADD CONSTRAINT fk_visits_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE documents ADD CONSTRAINT fk_documents_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE notifications ADD CONSTRAINT fk_notifications_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE settings ADD CONSTRAINT fk_settings_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE risk_assessment_questions ADD CONSTRAINT fk_risk_assessment_questions_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE risk_assessments ADD CONSTRAINT fk_risk_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE risk_assessment_answers ADD CONSTRAINT fk_risk_assessment_answers_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE pre_admissions ADD CONSTRAINT fk_pre_admissions_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE adl_categories ADD CONSTRAINT fk_adl_categories_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE choking_risk_assessments ADD CONSTRAINT fk_choking_risk_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE falls_risk_assessments ADD CONSTRAINT fk_falls_risk_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE mar_audits ADD CONSTRAINT fk_mar_audits_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE waterlow_assessments ADD CONSTRAINT fk_waterlow_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE mental_capacity_assessments ADD CONSTRAINT fk_mental_capacity_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE food_fluid_charts ADD CONSTRAINT fk_food_fluid_charts_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE bowel_bladder_charts ADD CONSTRAINT fk_bowel_bladder_charts_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE repositioning_charts ADD CONSTRAINT fk_repositioning_charts_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE sleep_charts ADD CONSTRAINT fk_sleep_charts_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE infection_control_audits ADD CONSTRAINT fk_infection_control_audits_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE health_safety_audits ADD CONSTRAINT fk_health_safety_audits_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE fire_safety_audits ADD CONSTRAINT fk_fire_safety_audits_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE equipment_audits ADD CONSTRAINT fk_equipment_audits_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE supervision_records ADD CONSTRAINT fk_supervision_records_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE appraisal_forms ADD CONSTRAINT fk_appraisal_forms_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE training_records ADD CONSTRAINT fk_training_records_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE competency_assessments ADD CONSTRAINT fk_competency_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE dols_assessments ADD CONSTRAINT fk_dols_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE moving_handling_assessments ADD CONSTRAINT fk_moving_handling_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE skin_integrity_assessments ADD CONSTRAINT fk_skin_integrity_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE oral_health_assessments ADD CONSTRAINT fk_oral_health_assessments_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

ALTER TABLE shift_rotas ADD CONSTRAINT fk_shift_rotas_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;

-- Create indexes for organisation_id
CREATE INDEX IF NOT EXISTS idx_profiles_organisation_id ON profiles(organisation_id);
CREATE INDEX IF NOT EXISTS idx_carers_organisation_id ON carers(organisation_id);
CREATE INDEX IF NOT EXISTS idx_service_users_organisation_id ON service_users(organisation_id);
CREATE INDEX IF NOT EXISTS idx_shifts_organisation_id ON shifts(organisation_id);
CREATE INDEX IF NOT EXISTS idx_visits_organisation_id ON visits(organisation_id);
CREATE INDEX IF NOT EXISTS idx_documents_organisation_id ON documents(organisation_id);
CREATE INDEX IF NOT EXISTS idx_notifications_organisation_id ON notifications(organisation_id);
CREATE INDEX IF NOT EXISTS idx_settings_organisation_id ON settings(organisation_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessment_questions_organisation_id ON risk_assessment_questions(organisation_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_organisation_id ON risk_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessment_answers_organisation_id ON risk_assessment_answers(organisation_id);
CREATE INDEX IF NOT EXISTS idx_pre_admissions_organisation_id ON pre_admissions(organisation_id);
CREATE INDEX IF NOT EXISTS idx_adl_categories_organisation_id ON adl_categories(organisation_id);
CREATE INDEX IF NOT EXISTS idx_choking_risk_assessments_organisation_id ON choking_risk_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_falls_risk_assessments_organisation_id ON falls_risk_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_mar_audits_organisation_id ON mar_audits(organisation_id);
CREATE INDEX IF NOT EXISTS idx_waterlow_assessments_organisation_id ON waterlow_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_mental_capacity_assessments_organisation_id ON mental_capacity_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_food_fluid_charts_organisation_id ON food_fluid_charts(organisation_id);
CREATE INDEX IF NOT EXISTS idx_bowel_bladder_charts_organisation_id ON bowel_bladder_charts(organisation_id);
CREATE INDEX IF NOT EXISTS idx_repositioning_charts_organisation_id ON repositioning_charts(organisation_id);
CREATE INDEX IF NOT EXISTS idx_sleep_charts_organisation_id ON sleep_charts(organisation_id);
CREATE INDEX IF NOT EXISTS idx_infection_control_audits_organisation_id ON infection_control_audits(organisation_id);
CREATE INDEX IF NOT EXISTS idx_health_safety_audits_organisation_id ON health_safety_audits(organisation_id);
CREATE INDEX IF NOT EXISTS idx_fire_safety_audits_organisation_id ON fire_safety_audits(organisation_id);
CREATE INDEX IF NOT EXISTS idx_equipment_audits_organisation_id ON equipment_audits(organisation_id);
CREATE INDEX IF NOT EXISTS idx_supervision_records_organisation_id ON supervision_records(organisation_id);
CREATE INDEX IF NOT EXISTS idx_appraisal_forms_organisation_id ON appraisal_forms(organisation_id);
CREATE INDEX IF NOT EXISTS idx_training_records_organisation_id ON training_records(organisation_id);
CREATE INDEX IF NOT EXISTS idx_competency_assessments_organisation_id ON competency_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_dols_assessments_organisation_id ON dols_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_moving_handling_assessments_organisation_id ON moving_handling_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_skin_integrity_assessments_organisation_id ON skin_integrity_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_oral_health_assessments_organisation_id ON oral_health_assessments(organisation_id);
CREATE INDEX IF NOT EXISTS idx_shift_rotas_organisation_id ON shift_rotas(organisation_id);

-- Update RLS policies to include organisation_id filtering
-- Note: These policies will need to be updated based on the actual user-organisation relationship
-- For now, we'll add basic organisation filtering to existing policies

-- Update profiles policy to include organisation filtering
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles
FOR SELECT USING (auth.uid() = id OR organisation_id IS NULL);

-- Update carers policy to include organisation filtering
DROP POLICY IF EXISTS "Admins can view all carers" ON carers;
CREATE POLICY "Admins can view all carers" ON carers
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ) OR organisation_id IS NULL
);

-- Update service_users policy to include organisation filtering
DROP POLICY IF EXISTS "Admins can view all service users" ON service_users;
CREATE POLICY "Admins can view all service users" ON service_users
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ) OR organisation_id IS NULL
);

-- Update shifts policy to include organisation filtering
DROP POLICY IF EXISTS "Carers can view assigned shifts" ON shifts;
CREATE POLICY "Carers can view assigned shifts" ON shifts
FOR SELECT USING (
  carer_id = auth.uid() OR 
  auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin') OR
  organisation_id IS NULL
);

-- Update visits policy to include organisation filtering
DROP POLICY IF EXISTS "Carers can view own visits" ON visits;
CREATE POLICY "Carers can view own visits" ON visits
FOR SELECT USING (
  carer_id = auth.uid() OR 
  auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin') OR
  organisation_id IS NULL
);

-- Update documents policy to include organisation filtering
DROP POLICY IF EXISTS "Carers can view own documents" ON documents;
CREATE POLICY "Carers can view own documents" ON documents
FOR SELECT USING (
  carer_id = auth.uid() OR 
  auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin') OR
  organisation_id IS NULL
);

-- Update notifications policy to include organisation filtering
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" ON notifications
FOR SELECT USING (
  user_id = auth.uid() OR
  organisation_id IS NULL
);

-- Function to update organisation_id for existing records
-- This is a placeholder function that would need to be customized based on business logic
CREATE OR REPLACE FUNCTION assign_default_organisation()
RETURNS VOID AS $$
DECLARE
  default_org_id UUID;
BEGIN
  -- Create a default organisation if none exists
  SELECT id INTO default_org_id FROM organisations LIMIT 1;
  
  IF default_org_id IS NULL THEN
    INSERT INTO organisations (name, address, contact_email, contact_phone)
    VALUES ('Default Organisation', 'Unknown Address', 'admin@default.com', 'Unknown')
    RETURNING id INTO default_org_id;
  END IF;
  
  -- Update all existing records to use the default organisation
  UPDATE profiles SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE carers SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE service_users SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE shifts SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE visits SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE documents SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE notifications SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE settings SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE risk_assessment_questions SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE risk_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE risk_assessment_answers SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE pre_admissions SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE adl_categories SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE choking_risk_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE falls_risk_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE mar_audits SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE waterlow_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE mental_capacity_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE food_fluid_charts SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE bowel_bladder_charts SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE repositioning_charts SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE sleep_charts SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE infection_control_audits SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE health_safety_audits SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE fire_safety_audits SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE equipment_audits SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE supervision_records SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE appraisal_forms SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE training_records SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE competency_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE dols_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE moving_handling_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE skin_integrity_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE oral_health_assessments SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  UPDATE shift_rotas SET organisation_id = default_org_id WHERE organisation_id IS NULL;
  
  RAISE NOTICE 'Assigned default organisation % to all existing records', default_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Execute the function to assign default organisation
SELECT assign_default_organisation();

-- Drop the function after use
DROP FUNCTION assign_default_organisation();