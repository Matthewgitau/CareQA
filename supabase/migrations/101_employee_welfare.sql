-- ============================================
-- EMPLOYEE WELFARE & WELLBEING SYSTEM
-- ============================================

-- 1. Welfare Checks Table
CREATE TABLE IF NOT EXISTS welfare_checks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Staff Member
  staff_id UUID NOT NULL,
  staff_name TEXT NOT NULL,
  employee_number TEXT,
  job_role TEXT,
  department TEXT,
  
  -- Check Details
  check_date DATE NOT NULL DEFAULT CURRENT_DATE,
  check_time TIME NOT NULL DEFAULT NOW(),
  check_type TEXT CHECK (check_type IN (
    'annual_wellbeing',
    'return_to_work',
    'stress_risk_assessment',
    'health_questionnaire',
    'ergonomic_assessment',
    'mental_health_check',
    'general_welfare',
    'exit_interview',
    'other'
  )),
  
  -- Wellbeing Scores (1-10 scale)
  wellbeing_score INTEGER CHECK (wellbeing_score BETWEEN 1 AND 10),
  stress_score INTEGER CHECK (stress_score BETWEEN 1 AND 10),
  job_satisfaction_score INTEGER CHECK (job_satisfaction_score BETWEEN 1 AND 10),
  workload_score INTEGER CHECK (workload_score BETWEEN 1 AND 10),
  
  -- Physical Health
  physical_health_issues TEXT,
  recent_illness TEXT,
  medication_impact BOOLEAN DEFAULT FALSE,
  medication_impact_notes TEXT,
  
  -- Mental Health
  anxiety_level TEXT CHECK (anxiety_level IN ('none', 'mild', 'moderate', 'severe')),
  depression_symptoms TEXT CHECK (depression_symptoms IN ('none', 'mild', 'moderate', 'severe')),
  burnout_symptoms TEXT CHECK (burnout_symptoms IN ('none', 'early_warning', 'developing', 'full_burnout')),
  sleeping_issues TEXT CHECK (sleeping_issues IN ('none', 'occasional', 'regular', 'chronic')),
  
  -- Work Environment
  workload_manageable BOOLEAN,
  support_available BOOLEAN,
  team_relationships TEXT CHECK (team_relationships IN ('excellent', 'good', 'fair', 'poor', 'toxic')),
  manager_support TEXT CHECK (manager_support IN ('excellent', 'good', 'fair', 'poor', 'none')),
  
  -- Home Life Impact
  work_life_balance TEXT CHECK (work_life_balance IN ('excellent', 'good', 'fair', 'poor', 'very_poor')),
  caring_responsibilities BOOLEAN DEFAULT FALSE,
  caring_responsibilities_notes TEXT,
  
  -- Stress Factors
  identified_stressors TEXT[],
  stress_level_trend TEXT CHECK (stress_level_trend IN ('improving', 'stable', 'worsening', 'fluctuating')),
  
  -- Support Provided
  support_provided TEXT,
  referral_made BOOLEAN DEFAULT FALSE,
  referral_type TEXT,
  referral_date DATE,
  follow_up_required BOOLEAN DEFAULT FALSE,
  follow_up_date DATE,
  
  -- Action Plan
  action_plan TEXT,
  action_plan_completed BOOLEAN DEFAULT FALSE,
  action_plan_completion_date DATE,
  
  -- Sign-off
  checked_by UUID REFERENCES profiles(id),
  checked_by_name TEXT,
  staff_signature_url TEXT,
  manager_signature_url TEXT,
  
  -- Confidentiality
  is_confidential BOOLEAN DEFAULT TRUE,
  share_with_manager BOOLEAN DEFAULT TRUE,
  
  -- Metadata
  notes TEXT,
  organisation_id UUID REFERENCES organisations(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Welfare Referrals Table
CREATE TABLE IF NOT EXISTS welfare_referrals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  welfare_check_id UUID REFERENCES welfare_checks(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL,
  
  referral_type TEXT NOT NULL CHECK (referral_type IN (
    'occupational_health',
    'counselling',
    'mental_health_support',
    'physiotherapy',
    'stress_management',
    'employee_assistance_programme',
    'gp',
    'other'
  )),
  
  referral_date DATE NOT NULL,
  referral_details TEXT,
  referral_contact TEXT,
  appointment_date DATE,
  appointment_attended BOOLEAN DEFAULT FALSE,
  outcome TEXT,
  follow_up_date DATE,
  
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Stress Risk Assessments (HSE Management Standards)
CREATE TABLE IF NOT EXISTS stress_risk_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID NOT NULL,
  staff_name TEXT NOT NULL,
  
  assessment_date DATE NOT NULL,
  review_date DATE,
  
  -- HSE Six Management Standards
  demands_score INTEGER CHECK (demands_score BETWEEN 1 AND 5),
  demands_notes TEXT,
  control_score INTEGER CHECK (control_score BETWEEN 1 AND 5),
  control_notes TEXT,
  support_score INTEGER CHECK (support_score BETWEEN 1 AND 5),
  support_notes TEXT,
  relationships_score INTEGER CHECK (relationships_score BETWEEN 1 AND 5),
  relationships_notes TEXT,
  role_score INTEGER CHECK (role_score BETWEEN 1 AND 5),
  role_notes TEXT,
  change_score INTEGER CHECK (change_score BETWEEN 1 AND 5),
  change_notes TEXT,
  
  -- Overall Risk Level
  overall_risk_level TEXT CHECK (overall_risk_level IN ('low', 'medium', 'high', 'critical')),
  risk_assessment_notes TEXT,
  
  -- Action Plan
  action_plan TEXT,
  action_deadline DATE,
  action_owner TEXT,
  
  -- Metadata
  organisation_id UUID REFERENCES organisations(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE welfare_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE welfare_referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE stress_risk_assessments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================
DROP POLICY IF EXISTS "tenant_isolation_welfare_checks" ON welfare_checks;
CREATE POLICY "tenant_isolation_welfare_checks" ON welfare_checks
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_welfare_referrals" ON welfare_referrals;
CREATE POLICY "tenant_isolation_welfare_referrals" ON welfare_referrals
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_stress_assessments" ON stress_risk_assessments;
CREATE POLICY "tenant_isolation_stress_assessments" ON stress_risk_assessments
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_welfare_checks_staff ON welfare_checks(staff_id);
CREATE INDEX IF NOT EXISTS idx_welfare_checks_date ON welfare_checks(check_date);
CREATE INDEX IF NOT EXISTS idx_welfare_checks_score ON welfare_checks(wellbeing_score);
CREATE INDEX IF NOT EXISTS idx_welfare_referrals_staff ON welfare_referrals(staff_id);
CREATE INDEX IF NOT EXISTS idx_stress_assessments_staff ON stress_risk_assessments(staff_id);
CREATE INDEX IF NOT EXISTS idx_stress_assessments_risk ON stress_risk_assessments(overall_risk_level);