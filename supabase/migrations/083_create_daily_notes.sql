-- Create daily_notes table
CREATE TABLE IF NOT EXISTS daily_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID NOT NULL,
  service_user_name TEXT,
  carer_id UUID,
  carer_name TEXT,
  visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
  visit_time TIME NOT NULL DEFAULT CURRENT_TIME,

  -- Visit type
  visit_type TEXT NOT NULL, -- 'morning', 'lunch', 'tea', 'evening'

  -- Care acceptance
  care_accepted TEXT NOT NULL, -- 'accepted', 'refused', 'partial'
  refusal_reason TEXT,

  -- Emotional state
  emotional_state TEXT[],

  -- Pad change
  pad_changed BOOLEAN DEFAULT false,
  pad_urine_present BOOLEAN DEFAULT false,
  pad_urine_amount TEXT,
  pad_faeces_present BOOLEAN DEFAULT false,
  pad_faeces_amount TEXT,
  stool_log_id UUID,

  -- Food and fluid
  food_offered BOOLEAN DEFAULT false,
  food_eaten_percentage INTEGER,
  food_details TEXT,
  fluid_offered BOOLEAN DEFAULT false,
  fluid_ml INTEGER,
  fluid_details TEXT,

  -- Medication
  medication_observed BOOLEAN DEFAULT false,
  medication_taken BOOLEAN DEFAULT false,
  medication_refused BOOLEAN DEFAULT false,
  medication_notes TEXT,

  -- Observations
  skin_condition TEXT,
  skin_notes TEXT,
  mobility_notes TEXT,
  communication_notes TEXT,

  -- Incidents
  incident_occurred BOOLEAN DEFAULT false,
  incident_description TEXT,
  incident_reported_to TEXT,

  -- Manual notes
  manual_notes TEXT,
  use_manual_notes BOOLEAN DEFAULT false,

  -- Signature
  carer_signature TEXT,
  status TEXT DEFAULT 'draft',

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

ALTER TABLE daily_notes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'daily_notes' AND policyname = 'Allow all authenticated'
  ) THEN
    CREATE POLICY "Allow all authenticated" ON daily_notes
      FOR ALL USING (auth.role() = 'authenticated');
  END IF;
END $$;