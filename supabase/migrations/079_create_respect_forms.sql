-- Create respect_forms table (RESPECT Framework)
CREATE TABLE IF NOT EXISTS respect_forms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  service_user_name TEXT NOT NULL,
  assessor_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  assessment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- RESPECT Framework sections (based on policy)
  what_matters_to_me TEXT,
  communication_needs TEXT,
  health_and_wellbeing TEXT,
  daily_living TEXT,
  relationships TEXT,
  spiritual_cultural TEXT,
  end_of_life_wishes TEXT,
  preferred_place_of_care TEXT,
  who_to_contact TEXT,
  
  -- Sign-off
  signature_data TEXT,
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID,
  updated_at TIMESTAMPTZ DEFAULT now(),
  organisation_id UUID
);

-- Enable RLS
ALTER TABLE respect_forms ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their org's respect forms" ON respect_forms;
DROP POLICY IF EXISTS "Users can insert respect forms" ON respect_forms;
DROP POLICY IF EXISTS "Users can update their org's respect forms" ON respect_forms;

-- Create policies
CREATE POLICY "Users can view their org's respect forms"
  ON respect_forms FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert respect forms"
  ON respect_forms FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update their org's respect forms"
  ON respect_forms FOR UPDATE
  USING (auth.uid() IS NOT NULL);