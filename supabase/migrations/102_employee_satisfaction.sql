-- ============================================
-- EMPLOYEE SATISFACTION & ENGAGEMENT SYSTEM
-- ============================================

-- 1. Satisfaction Surveys Table
CREATE TABLE IF NOT EXISTS satisfaction_surveys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Staff Member
  staff_id UUID NOT NULL,
  staff_name TEXT,
  employee_number TEXT,
  department TEXT,
  job_role TEXT,
  
  -- Survey Details
  survey_date DATE NOT NULL DEFAULT CURRENT_DATE,
  survey_type TEXT DEFAULT 'standard' CHECK (survey_type IN (
    'standard', 'quarterly', 'annual', 'pulse', 'exit', 'onboarding', 'project_feedback'
  )),
  
  -- Engagement & Satisfaction Scores (1-10)
  overall_satisfaction INTEGER CHECK (overall_satisfaction BETWEEN 1 AND 10),
  engagement_score INTEGER CHECK (engagement_score BETWEEN 1 AND 10),
  motivation_score INTEGER CHECK (motivation_score BETWEEN 1 AND 10),
  
  -- Work Environment
  work_environment_score INTEGER CHECK (work_environment_score BETWEEN 1 AND 10),
  team_collaboration_score INTEGER CHECK (team_collaboration_score BETWEEN 1 AND 10),
  resources_available_score INTEGER CHECK (resources_available_score BETWEEN 1 AND 10),
  
  -- Management & Leadership
  management_support_score INTEGER CHECK (management_support_score BETWEEN 1 AND 10),
  leadership_trust_score INTEGER CHECK (leadership_trust_score BETWEEN 1 AND 10),
  communication_score INTEGER CHECK (communication_score BETWEEN 1 AND 10),
  feedback_effectiveness_score INTEGER CHECK (feedback_effectiveness_score BETWEEN 1 AND 10),
  
  -- Career Development
  career_development_score INTEGER CHECK (career_development_score BETWEEN 1 AND 10),
  training_opportunities_score INTEGER CHECK (training_opportunities_score BETWEEN 1 AND 10),
  recognition_score INTEGER CHECK (recognition_score BETWEEN 1 AND 10),
  
  -- Work-Life Balance
  work_life_balance_score INTEGER CHECK (work_life_balance_score BETWEEN 1 AND 10),
  flexibility_score INTEGER CHECK (flexibility_score BETWEEN 1 AND 10),
  
  -- Open Questions
  what_do_you_enjoy TEXT,
  what_could_improve TEXT,
  suggestions_for_improvement TEXT,
  additional_comments TEXT,
  
  -- Key Drivers
  top_driver TEXT,
  top_concern TEXT,
  
  -- Engagement Factors (Yes/No)
  feel_valued BOOLEAN,
  feel_heard BOOLEAN,
  feel_supported BOOLEAN,
  feel_developed BOOLEAN,
  feel_recognized BOOLEAN,
  
  -- Anonymous Option
  is_anonymous BOOLEAN DEFAULT FALSE,
  
  -- Response Metadata
  response_time_seconds INTEGER,
  completion_status TEXT DEFAULT 'completed' CHECK (completion_status IN ('started', 'completed', 'abandoned')),
  
  -- HR Use
  hr_reviewed BOOLEAN DEFAULT FALSE,
  hr_review_date DATE,
  hr_notes TEXT,
  
  -- Action Plan
  action_plan TEXT,
  action_deadline DATE,
  action_owner TEXT,
  action_completed BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  organisation_id UUID REFERENCES organisations(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Satisfaction Trends Table (for aggregated data)
CREATE TABLE IF NOT EXISTS satisfaction_trends (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID REFERENCES organisations(id),
  
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  period_label TEXT,
  
  -- Aggregated Scores
  avg_overall_satisfaction NUMERIC(5,2),
  avg_engagement_score NUMERIC(5,2),
  avg_management_support NUMERIC(5,2),
  avg_work_environment NUMERIC(5,2),
  avg_career_development NUMERIC(5,2),
  
  -- Response Rates
  total_surveys_sent INTEGER,
  total_surveys_completed INTEGER,
  response_rate NUMERIC(5,2),
  
  -- Key Themes
  top_strengths TEXT[],
  top_areas_for_improvement TEXT[],
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Recognition & Awards Table
CREATE TABLE IF NOT EXISTS staff_recognition (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  staff_id UUID NOT NULL,
  staff_name TEXT NOT NULL,
  
  recognition_type TEXT CHECK (recognition_type IN (
    'employee_of_month', 'employee_of_quarter', 'employee_of_year',
    'spot_award', 'team_award', 'long_service', 'exceptional_care',
    'innovation', 'leadership', 'other'
  )),
  
  recognition_date DATE NOT NULL,
  reason TEXT NOT NULL,
  nominated_by UUID REFERENCES profiles(id),
  nominated_by_name TEXT,
  
  award_details TEXT,
  certificate_url TEXT,
  
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE satisfaction_surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE satisfaction_trends ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_recognition ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================
DROP POLICY IF EXISTS "tenant_isolation_satisfaction" ON satisfaction_surveys;
CREATE POLICY "tenant_isolation_satisfaction" ON satisfaction_surveys
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_satisfaction_trends" ON satisfaction_trends;
CREATE POLICY "tenant_isolation_satisfaction_trends" ON satisfaction_trends
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_recognition" ON staff_recognition;
CREATE POLICY "tenant_isolation_recognition" ON staff_recognition
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Staff can view their own surveys
CREATE POLICY "staff_view_own_surveys" ON satisfaction_surveys
  FOR SELECT USING (staff_id = auth.uid());

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_satisfaction_staff ON satisfaction_surveys(staff_id);
CREATE INDEX IF NOT EXISTS idx_satisfaction_date ON satisfaction_surveys(survey_date);
CREATE INDEX IF NOT EXISTS idx_satisfaction_overall ON satisfaction_surveys(overall_satisfaction);
CREATE INDEX IF NOT EXISTS idx_satisfaction_anonymous ON satisfaction_surveys(is_anonymous);
CREATE INDEX IF NOT EXISTS idx_recognition_staff ON staff_recognition(staff_id);
CREATE INDEX IF NOT EXISTS idx_recognition_date ON staff_recognition(recognition_date);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Calculate engagement score (composite)
CREATE OR REPLACE FUNCTION calculate_engagement_score(
  p_staff_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS NUMERIC AS $$
DECLARE
  v_avg_engagement NUMERIC;
BEGIN
  SELECT AVG(engagement_score) INTO v_avg_engagement
  FROM satisfaction_surveys
  WHERE staff_id = p_staff_id
    AND survey_date BETWEEN p_start_date AND p_end_date
    AND engagement_score IS NOT NULL;
  
  RETURN COALESCE(v_avg_engagement, 0);
END;
$$ LANGUAGE plpgsql;
