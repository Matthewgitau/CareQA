-- Catheter Care Risk Assessments table
CREATE TABLE catheter_care_risk_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  assessor_id UUID REFERENCES profiles(id),
  assessment_date DATE NOT NULL,
  
  -- Catheter Information
  catheter_type TEXT CHECK (catheter_type IN ('indwelling', 'suprapubic', 'intermittent')),
  insertion_date DATE,
  next_change_date DATE,
  catheter_size INTEGER,
  balloon_volume INTEGER,
  
  -- Urine Monitoring
  urine_output_ml INTEGER,
  urine_appearance TEXT CHECK (urine_appearance IN ('clear', 'cloudy', 'blood_stained', 'dark')),
  urine_odour TEXT CHECK (urine_odour IN ('normal', 'foul', 'sweet')),
  
  -- Infection Signs
  fever_celsius NUMERIC,
  pain_level INTEGER CHECK (pain_level BETWEEN 0 AND 10),
  pain_location TEXT,
  
  -- Skin Condition
  skin_condition TEXT CHECK (skin_condition IN ('intact', 'redness', 'rash', 'broken', 'infected')),
  skin_condition_notes TEXT,
  
  -- Drainage System
  drainage_bag_position TEXT CHECK (drainage_bag_position IN ('below_bladder', 'above_bladder', 'floor')),
  drainage_bag_secure BOOLEAN,
  
  -- Risk Assessment
  infection_risk TEXT CHECK (infection_risk IN ('low', 'medium', 'high')),
  blockage_risk TEXT CHECK (blockage_risk IN ('low', 'medium', 'high')),
  dislodgement_risk TEXT CHECK (dislodgement_risk IN ('low', 'medium', 'high')),
  overall_risk_level TEXT CHECK (overall_risk_level IN ('low', 'medium', 'high', 'critical')),
  
  -- Patient Comfort
  comfort_level INTEGER CHECK (comfort_level BETWEEN 1 AND 5),
  patient_concerns TEXT,
  
  -- Staff & Review
  staff_competency_verified BOOLEAN,
  review_date DATE,
  action_plan TEXT,
  
  -- Metadata
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE catheter_care_risk_assessments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their organization's catheter care assessments"
  ON catheter_care_risk_assessments FOR SELECT
  USING (
    service_user_id IN (
      SELECT id FROM service_users 
      WHERE organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    )
  );

CREATE POLICY "Users can insert catheter care assessments"
  ON catheter_care_risk_assessments FOR INSERT
  WITH CHECK (
    service_user_id IN (
      SELECT id FROM service_users 
      WHERE organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    )
  );

CREATE POLICY "Users can update their organization's catheter care assessments"
  ON catheter_care_risk_assessments FOR UPDATE
  USING (
    service_user_id IN (
      SELECT id FROM service_users 
      WHERE organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    )
  );

CREATE POLICY "Users can delete their organization's catheter care assessments"
  ON catheter_care_risk_assessments FOR DELETE
  USING (
    service_user_id IN (
      SELECT id FROM service_users 
      WHERE organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    )
  );

-- Indexes
CREATE INDEX idx_catheter_care_assessments_service_user ON catheter_care_risk_assessments(service_user_id);
CREATE INDEX idx_catheter_care_assessments_date ON catheter_care_risk_assessments(assessment_date);
CREATE INDEX idx_catheter_care_assessments_risk ON catheter_care_risk_assessments(overall_risk_level);