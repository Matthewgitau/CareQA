-- Create domiciliary_fire_safety_assessments table
CREATE TABLE IF NOT EXISTS domiciliary_fire_safety_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID,
  service_user_name TEXT,
  assessor_name TEXT,
  assessment_date DATE,
  risk_level TEXT,
  
  -- Section 1: Electrical Safety
  has_electrical_equipment TEXT,
  pat_test_sticker_seen TEXT,
  operates_equipment_self TEXT,
  visible_electrical_damage TEXT,
  
  -- Section 2: Fire Prevention
  working_smoke_alarms TEXT,
  service_user_smokes TEXT,
  escape_routes_clear TEXT,
  has_fire_blanket_extinguisher TEXT,
  
  -- Section 3: Emergency Response
  can_exit_independently TEXT,
  understands_fire_safety TEXT,
  name_visible_at_entrance TEXT,
  
  -- Action Plan
  recommended_actions TEXT,
  
  -- Sign-off
  signature_data TEXT,
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID,
  updated_at TIMESTAMPTZ DEFAULT now(),
  organisation_id UUID
);

-- Enable RLS
ALTER TABLE domiciliary_fire_safety_assessments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'domiciliary_fire_safety_assessments' AND policyname = 'Allow all for authenticated users'
  ) THEN
    CREATE POLICY "Allow all for authenticated users" ON domiciliary_fire_safety_assessments
      FOR ALL USING (auth.role() = 'authenticated');
  END IF;
END $$;
