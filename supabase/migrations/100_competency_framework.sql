-- ============================================
-- COMPETENCY FRAMEWORK - PHASE 1
-- CQC-Compliant Competency Management System
-- ============================================

-- 1. Competency Framework (defines what competencies exist)
CREATE TABLE IF NOT EXISTS competency_framework (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  competency_code TEXT UNIQUE NOT NULL,
  competency_name TEXT NOT NULL,
  category TEXT CHECK (category IN ('clinical', 'communication', 'professional', 'safety', 'management', 'digital')),
  description TEXT NOT NULL,
  required_level INTEGER DEFAULT 3 CHECK (required_level BETWEEN 1 AND 5),
  assessment_method TEXT[] DEFAULT '{"observation"}',
  evidence_requirements TEXT[],
  regulatory_reference TEXT, -- e.g., 'CQC Regulation 18', 'Care Certificate Standard 4'
  is_active BOOLEAN DEFAULT TRUE,
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Role Competency Mapping (what competencies each role needs)
CREATE TABLE IF NOT EXISTS role_competency_requirements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_type TEXT NOT NULL CHECK (role_type IN ('care_worker', 'senior_carer', 'team_leader', 'manager', 'nurse', 'admin')),
  competency_id UUID REFERENCES competency_framework(id) ON DELETE CASCADE,
  required_level INTEGER DEFAULT 3 CHECK (required_level BETWEEN 1 AND 5),
  is_mandatory BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 3. Staff Competency Assessments (actual assessments)
CREATE TABLE IF NOT EXISTS staff_competency_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  competency_id UUID REFERENCES competency_framework(id) ON DELETE CASCADE,
  assessor_id UUID REFERENCES profiles(id),
  assessment_date DATE NOT NULL,
  achieved_level INTEGER CHECK (achieved_level BETWEEN 1 AND 5),
  evidence TEXT,
  evidence_urls TEXT[],
  assessor_notes TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'requires_reassessment')),
  expiry_date DATE,
  is_current BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Staff Development Plans
CREATE TABLE IF NOT EXISTS staff_development_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_by UUID REFERENCES profiles(id),
  created_date DATE NOT NULL,
  review_date DATE,
  goals JSONB, -- array of {competency_id, target_level, target_date, status}
  notes TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE competency_framework ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_competency_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_competency_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_development_plans ENABLE ROW LEVEL SECURITY;

-- RLS Policies (tenant isolation)
CREATE POLICY tenant_isolation_framework ON competency_framework
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY tenant_isolation_role_requirements ON role_competency_requirements
  FOR ALL USING (EXISTS (
    SELECT 1 FROM competency_framework cf 
    WHERE cf.id = role_competency_requirements.competency_id 
    AND cf.organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid())
  ));

CREATE POLICY tenant_isolation_assessments ON staff_competency_assessments
  FOR ALL USING (staff_id IN (SELECT id FROM profiles WHERE organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid())));

CREATE POLICY tenant_isolation_development_plans ON staff_development_plans
  FOR ALL USING (staff_id IN (SELECT id FROM profiles WHERE organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid())));

-- Indexes
CREATE INDEX idx_competency_framework_code ON competency_framework(competency_code);
CREATE INDEX idx_competency_framework_category ON competency_framework(category);
CREATE INDEX idx_role_requirements_role ON role_competency_requirements(role_type);
CREATE INDEX idx_role_requirements_competency ON role_competency_requirements(competency_id);
CREATE INDEX idx_competency_assessments_staff ON staff_competency_assessments(staff_id);
CREATE INDEX idx_competency_assessments_competency ON staff_competency_assessments(competency_id);
CREATE INDEX idx_competency_assessments_status ON staff_competency_assessments(status);
CREATE INDEX idx_competency_assessments_expiry ON staff_competency_assessments(expiry_date);
CREATE INDEX idx_development_plans_staff ON staff_development_plans(staff_id);
CREATE INDEX idx_development_plans_status ON staff_development_plans(status);