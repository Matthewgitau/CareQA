-- Create nutrition_risk_assessments table (MUST)
CREATE TABLE IF NOT EXISTS nutrition_risk_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID NOT NULL,
  service_user_name TEXT,
  assessor_id UUID,
  assessor_name TEXT,
  assessment_date DATE DEFAULT CURRENT_DATE,

  -- MUST Score components
  height_cm DOUBLE PRECISION,
  current_weight_kg DOUBLE PRECISION,
  bmi DOUBLE PRECISION,
  bmi_score INTEGER, -- 0, 1, or 2
  weight_3_6_months_ago_kg DOUBLE PRECISION,
  weight_loss_percentage DOUBLE PRECISION,
  weight_loss_score INTEGER, -- 0, 1, or 2
  acute_disease_effect_score INTEGER, -- 0 or 2

  -- MUST total score
  must_total_score INTEGER,
  risk_category TEXT, -- 'low', 'medium', 'high'

  -- Additional assessment fields
  appetite TEXT, -- 'good', 'reduced', 'poor', 'none'
  eating_difficulties TEXT[], -- e.g., ['swallowing', 'chewing', 'nausea', 'vomiting', 'diarrhoea']
  dietary_requirements TEXT,
  food_preferences_allergies TEXT,
  swallowing_difficulties BOOLEAN DEFAULT false,

  -- Food intake monitoring trigger
  requires_food_monitoring BOOLEAN DEFAULT false,
  monitoring_frequency TEXT, -- 'daily', 'weekly', 'fortnightly', 'monthly'
  next_monitoring_date DATE,

  -- Care plan actions
  referred_to_dietitian BOOLEAN DEFAULT false,
  gp_referral BOOLEAN DEFAULT false,
  supplementation_required BOOLEAN DEFAULT false,
  supplements_details TEXT,
  action_plan TEXT,

  -- Review
  review_date DATE,
  next_weight_check_date DATE,
  reassessment_frequency TEXT, -- '1 week', '2 weeks', '1 month', '3 months'

  -- Sign-off
  assessor_signature TEXT,
  status TEXT DEFAULT 'draft',

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- Enable RLS
ALTER TABLE nutrition_risk_assessments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'nutrition_risk_assessments' AND policyname = 'Allow all authenticated'
  ) THEN
    CREATE POLICY "Allow all authenticated" ON nutrition_risk_assessments
      FOR ALL USING (auth.role() = 'authenticated');
  END IF;
END $$;