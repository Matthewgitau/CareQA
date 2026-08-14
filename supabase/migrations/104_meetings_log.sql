-- ============================================
-- MEETINGS LOG SYSTEM
-- ============================================

-- 1. Meetings Table
CREATE TABLE IF NOT EXISTS meetings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Meeting Details
  meeting_title TEXT NOT NULL,
  meeting_type TEXT CHECK (meeting_type IN (
    'team_meeting', 'handover', 'supervision', 'training_session',
    'emergency_meeting', 'management_meeting', 'care_plan_review',
    'service_user_review', 'incident_review', 'audit_review',
    'staff_meeting', 'other'
  )),
  
  meeting_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  duration_minutes INTEGER GENERATED ALWAYS AS (
    EXTRACT(EPOCH FROM (end_time - start_time)) / 60
  ) STORED,
  
  location TEXT,
  is_online BOOLEAN DEFAULT FALSE,
  meeting_link TEXT,
  
  -- Agenda
  agenda TEXT,
  
  -- Chair & Organiser
  chair_person UUID REFERENCES profiles(id),
  chair_person_name TEXT,
  organiser UUID REFERENCES profiles(id),
  organiser_name TEXT,
  minute_taker UUID REFERENCES profiles(id),
  minute_taker_name TEXT,
  
  -- Attendees
  attendees JSONB DEFAULT '[]',
  attendees_count INTEGER GENERATED ALWAYS AS (
    jsonb_array_length(attendees)
  ) STORED,
  
  -- Apologies
  apologies JSONB DEFAULT '[]',
  apologies_count INTEGER GENERATED ALWAYS AS (
    jsonb_array_length(apologies)
  ) STORED,
  
  -- Minutes
  minutes TEXT,
  decisions JSONB DEFAULT '[]',
  key_discussion_points TEXT,
  
  -- Action Items
  action_items JSONB DEFAULT '[]',
  
  -- Next Meeting
  next_meeting_date DATE,
  next_meeting_time TIME,
  next_meeting_notes TEXT,
  
  -- Status
  status TEXT DEFAULT 'scheduled' CHECK (status IN (
    'scheduled', 'in_progress', 'completed', 'cancelled', 'postponed'
  )),
  
  -- Compliance & Quality
  minuted_approved BOOLEAN DEFAULT FALSE,
  minuted_approved_at TIMESTAMP WITH TIME ZONE,
  minuted_approved_by UUID REFERENCES profiles(id),
  
  cqc_compliance_checked BOOLEAN DEFAULT FALSE,
  cqc_compliance_notes TEXT,
  
  -- Attachments
  attachments JSONB DEFAULT '[]',
  
  -- Confidentiality
  is_confidential BOOLEAN DEFAULT FALSE,
  
  -- Feedback
  meeting_effectiveness_score INTEGER CHECK (meeting_effectiveness_score BETWEEN 1 AND 5),
  feedback_notes TEXT,
  
  -- Metadata
  notes TEXT,
  organisation_id UUID REFERENCES organisations(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Meeting Types Reference Table
CREATE TABLE IF NOT EXISTS meeting_type_reference (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  type_code TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  description TEXT,
  default_duration_minutes INTEGER,
  requires_agenda BOOLEAN DEFAULT TRUE,
  requires_minutes BOOLEAN DEFAULT TRUE,
  requires_attendance_tracking BOOLEAN DEFAULT TRUE,
  cqc_relevant BOOLEAN DEFAULT FALSE,
  
  is_active BOOLEAN DEFAULT TRUE,
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default meeting types (ignore duplicates)
INSERT INTO meeting_type_reference (type_code, display_name, description, default_duration_minutes, requires_agenda, requires_minutes, requires_attendance_tracking, cqc_relevant) VALUES
('team_meeting', 'Team Meeting', 'Regular team meeting for updates and coordination', 60, true, true, true, false),
('handover', 'Shift Handover', 'Handover between shifts', 30, false, false, true, false),
('supervision', 'Supervision Meeting', 'One-on-one staff supervision', 45, true, true, true, false),
('training_session', 'Training Session', 'Staff training and development', 120, true, true, true, false),
('emergency_meeting', 'Emergency Meeting', 'Urgent unplanned meeting', 30, false, true, true, false),
('management_meeting', 'Management Meeting', 'Management team meeting', 60, true, true, false, false),
('care_plan_review', 'Care Plan Review', 'Service user care plan review', 45, true, true, true, true),
('service_user_review', 'Service User Review', 'Comprehensive service user review', 60, true, true, true, true),
('incident_review', 'Incident Review', 'Post-incident review meeting', 60, true, true, true, true),
('audit_review', 'Audit Review', 'Audit findings review', 45, true, true, true, true)
ON CONFLICT (type_code) DO NOTHING;

-- 3. Meeting Templates Table
CREATE TABLE IF NOT EXISTS meeting_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  template_name TEXT NOT NULL,
  meeting_type TEXT CHECK (meeting_type IN (
    'team_meeting', 'handover', 'supervision', 'training_session',
    'emergency_meeting', 'management_meeting', 'care_plan_review',
    'service_user_review', 'incident_review', 'audit_review',
    'staff_meeting', 'other'
  )),
  
  default_agenda TEXT,
  default_attendees TEXT[],
  default_location TEXT,
  is_online BOOLEAN DEFAULT FALSE,
  meeting_link_template TEXT,
  
  is_active BOOLEAN DEFAULT TRUE,
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_type_reference ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_templates ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================
CREATE POLICY "tenant_isolation_meetings" ON meetings
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "tenant_isolation_meeting_types" ON meeting_type_reference
  FOR ALL USING (organisation_id IS NULL OR organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "tenant_isolation_meeting_templates" ON meeting_templates
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_meetings_date ON meetings(meeting_date);
CREATE INDEX idx_meetings_type ON meetings(meeting_type);
CREATE INDEX idx_meetings_status ON meetings(status);
CREATE INDEX idx_meetings_chair ON meetings(chair_person);
CREATE INDEX idx_meetings_cqc_compliance ON meetings(cqc_compliance_checked) WHERE cqc_compliance_checked = true;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Generate meeting summary for dashboard
CREATE OR REPLACE FUNCTION get_meeting_summary(
  p_org_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  total_meetings INTEGER,
  average_attendance NUMERIC,
  completion_rate NUMERIC,
  compliance_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::INTEGER,
    AVG(attendees_count)::NUMERIC,
    (COUNT(*) FILTER (WHERE status = 'completed')::NUMERIC / COUNT(*)::NUMERIC * 100),
    (COUNT(*) FILTER (WHERE cqc_compliance_checked = true)::NUMERIC / COUNT(*)::NUMERIC * 100)
  FROM meetings
  WHERE organisation_id = p_org_id
    AND meeting_date BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql;

-- Auto-update meeting status based on date/time
CREATE OR REPLACE FUNCTION update_meeting_status()
RETURNS void AS $$
BEGIN
  -- Update completed meetings
  UPDATE meetings
  SET status = 'completed'
  WHERE status NOT IN ('cancelled', 'completed')
    AND (meeting_date < CURRENT_DATE OR (meeting_date = CURRENT_DATE AND end_time < CURRENT_TIME));
  
  -- Update in-progress meetings
  UPDATE meetings
  SET status = 'in_progress'
  WHERE status = 'scheduled'
    AND meeting_date = CURRENT_DATE
    AND start_time <= CURRENT_TIME
    AND end_time > CURRENT_TIME;
END;
$$ LANGUAGE plpgsql;