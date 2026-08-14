-- Phase 2B: Compliance Engine Migration
-- This migration adds the comprehensive compliance system

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create compliance_flags table
CREATE TABLE compliance_flags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visit_id UUID REFERENCES visits(id) ON DELETE CASCADE,
  carer_id UUID REFERENCES carers(id) ON DELETE CASCADE,
  shift_id UUID REFERENCES shifts(id) ON DELETE CASCADE,
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  rule_id TEXT NOT NULL,
  rule_name TEXT NOT NULL,
  severity TEXT CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'investigating')),
  message TEXT NOT NULL,
  regulation_reference TEXT, -- e.g., 'CQC Reg 12', 'Ofsted EYFS 3.4'
  suggested_action TEXT,
  acknowledged_by UUID REFERENCES profiles(id),
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES profiles(id),
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create compliance_scores table (trending)
CREATE TABLE compliance_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  carer_id UUID REFERENCES carers(id) ON DELETE CASCADE,
  care_home_id UUID, -- Add if you have multiple locations
  score_date DATE NOT NULL,
  overall_score DECIMAL(5,2),
  duration_compliance DECIMAL(5,2),
  documentation_compliance DECIMAL(5,2),
  medication_compliance DECIMAL(5,2),
  incident_reporting_compliance DECIMAL(5,2),
  flags_count INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(carer_id, score_date)
);

-- Create teaching_moments table (user guidance)
CREATE TABLE teaching_moments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  trigger_rule_id TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  video_url TEXT,
  policy_url TEXT,
  quiz_required BOOLEAN DEFAULT FALSE,
  quiz_passed BOOLEAN,
  viewed_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create regulatory_reports table
CREATE TABLE regulatory_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_type TEXT CHECK (report_type IN ('CQC', 'OFSTED', 'CIW', 'INTERNAL')),
  reporting_period_start DATE NOT NULL,
  reporting_period_end DATE NOT NULL,
  report_data JSONB NOT NULL,
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  generated_by UUID REFERENCES profiles(id),
  submitted BOOLEAN DEFAULT FALSE,
  submitted_at TIMESTAMP WITH TIME ZONE
);

-- Create compliance_rules table (configurable rules)
CREATE TABLE compliance_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rule_id TEXT UNIQUE NOT NULL,
  rule_name TEXT NOT NULL,
  description TEXT,
  severity TEXT CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL')) DEFAULT 'WARNING',
  enabled BOOLEAN DEFAULT TRUE,
  rule_config JSONB, -- Rule-specific configuration
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default compliance rules
INSERT INTO compliance_rules (rule_id, rule_name, description, severity, rule_config) VALUES
('DURATION_COMPLIANCE', 'Visit Duration Compliance', 'Ensures visits meet minimum duration requirements', 'WARNING', '{"min_percentage": 85, "warning_threshold": 10, "critical_threshold": 20}'),
('MEDICATION_COMPLIANCE', 'Medication Administration', 'Tracks medication administration compliance', 'CRITICAL', '{"require_confirmation": true, "max_missed_per_week": 2}'),
('DOCUMENT_EXPIRY', 'Document Expiry Tracking', 'Monitors document expiry dates', 'WARNING', '{"dbs_warning_days": 30, "id_warning_days": 30}'),
('INCIDENT_REPORTING', 'Incident Reporting', 'Ensures incidents are properly reported', 'CRITICAL', '{"require_type": true, "escalation_threshold_hours": 24}'),
('FAMILY_COMMUNICATION', 'Family Communication', 'Tracks required family updates', 'INFO', '{"require_updates": true, "default_frequency": "daily"}');

-- Create indexes for performance
CREATE INDEX idx_compliance_flags_carer_id ON compliance_flags(carer_id);
CREATE INDEX idx_compliance_flags_visit_id ON compliance_flags(visit_id);
CREATE INDEX idx_compliance_flags_severity ON compliance_flags(severity);
CREATE INDEX idx_compliance_flags_status ON compliance_flags(status);
CREATE INDEX idx_compliance_flags_created_at ON compliance_flags(created_at);

CREATE INDEX idx_compliance_scores_carer_date ON compliance_scores(carer_id, score_date);
CREATE INDEX idx_compliance_scores_overall_score ON compliance_scores(overall_score);

CREATE INDEX idx_teaching_moments_user_id ON teaching_moments(user_id);
CREATE INDEX idx_teaching_moments_status ON teaching_moments(quiz_passed);

CREATE INDEX idx_regulatory_reports_type_period ON regulatory_reports(report_type, reporting_period_start, reporting_period_end);

-- Enable Row Level Security
ALTER TABLE compliance_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE teaching_moments ENABLE ROW LEVEL SECURITY;
ALTER TABLE regulatory_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_rules ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies for compliance_flags
CREATE POLICY "Admins can view all compliance flags"
  ON compliance_flags FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Carers can view their own flags"
  ON compliance_flags FOR SELECT
  USING (carer_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  ));

CREATE POLICY "Admins can manage compliance flags"
  ON compliance_flags FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

-- Create RLS Policies for compliance_scores
CREATE POLICY "Admins can view all compliance scores"
  ON compliance_scores FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Carers can view their own scores"
  ON compliance_scores FOR SELECT
  USING (carer_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  ));

-- Create RLS Policies for teaching_moments
CREATE POLICY "Users can view their own teaching moments"
  ON teaching_moments FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their own teaching moments"
  ON teaching_moments FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all teaching moments"
  ON teaching_moments FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

-- Create RLS Policies for regulatory_reports
CREATE POLICY "Admins can view all regulatory reports"
  ON regulatory_reports FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Admins can manage regulatory reports"
  ON regulatory_reports FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

-- Create RLS Policies for compliance_rules
CREATE POLICY "Admins can view compliance rules"
  ON compliance_rules FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Admins can manage compliance rules"
  ON compliance_rules FOR ALL
  USING (EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'admin'
  ));

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_compliance_rules_updated_at BEFORE UPDATE ON compliance_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to update compliance_scores
CREATE OR REPLACE FUNCTION update_compliance_scores()
RETURNS TRIGGER AS $$
BEGIN
    -- Update carer's compliance score when a flag is created
    IF TG_OP = 'INSERT' THEN
        -- This will be handled by the daily scoring function
        RETURN NEW;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for compliance scoring
CREATE TRIGGER compliance_scoring_trigger
  AFTER INSERT ON compliance_flags
  FOR EACH ROW
  EXECUTE FUNCTION update_compliance_scores();