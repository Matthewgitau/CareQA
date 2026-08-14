-- Appraisals
CREATE TABLE appraisals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id),
  appraisal_date DATE NOT NULL,
  reviewer_id UUID REFERENCES profiles(id),
  performance_rating INTEGER CHECK (performance_rating BETWEEN 1 AND 5),
  objectives JSONB,
  training_needs TEXT,
  overall_rating INTEGER CHECK (overall_rating BETWEEN 1 AND 5),
  staff_comments TEXT,
  reviewer_comments TEXT,
  next_appraisal_date DATE,
  staff_signature TEXT,
  reviewer_signature TEXT,
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Disciplinary
CREATE TABLE disciplinary_cases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id),
  incident_date DATE NOT NULL,
  case_type TEXT,
  description TEXT,
  investigation_notes TEXT,
  action_taken TEXT,
  outcome TEXT,
  follow_up_date DATE,
  status TEXT DEFAULT 'open',
  reported_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Leave Requests
CREATE TABLE leave_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  leave_type TEXT CHECK (leave_type IN ('annual', 'sick', 'bereavement', 'compassionate', 'unpaid', 'other')),
  reason TEXT,
  status TEXT DEFAULT 'pending',
  approved_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Holiday Allowance
CREATE TABLE holiday_allowance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id) UNIQUE,
  total_days INTEGER DEFAULT 28,
  taken_days INTEGER DEFAULT 0,
  remaining_days INTEGER GENERATED ALWAYS AS (total_days - taken_days) STORED,
  year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)
);

-- Satisfaction Surveys
CREATE TABLE satisfaction_surveys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id),
  survey_date DATE NOT NULL,
  overall_satisfaction INTEGER CHECK (overall_satisfaction BETWEEN 1 AND 5),
  work_environment INTEGER CHECK (work_environment BETWEEN 1 AND 5),
  management_support INTEGER CHECK (management_support BETWEEN 1 AND 5),
  training_satisfaction INTEGER CHECK (training_satisfaction BETWEEN 1 AND 5),
  comments TEXT,
  is_anonymous BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Incentives
CREATE TABLE incentives (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id),
  incentive_type TEXT,
  award_date DATE NOT NULL,
  points INTEGER,
  reward TEXT,
  reason TEXT,
  nominated_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Welfare Checks
CREATE TABLE welfare_checks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id),
  check_date DATE NOT NULL,
  wellbeing_score INTEGER CHECK (wellbeing_score BETWEEN 1 AND 10),
  concerns TEXT,
  support_provided TEXT,
  follow_up_required BOOLEAN DEFAULT FALSE,
  follow_up_date DATE,
  conducted_by UUID REFERENCES profiles(id),
  is_anonymous BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for all tables
ALTER TABLE appraisals ENABLE ROW LEVEL SECURITY;
ALTER TABLE disciplinary_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE holiday_allowance ENABLE ROW LEVEL SECURITY;
ALTER TABLE satisfaction_surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE incentives ENABLE ROW LEVEL SECURITY;
ALTER TABLE welfare_checks ENABLE ROW LEVEL SECURITY;

-- RLS Policies for appraisals
CREATE POLICY "Users can view their own appraisals"
  ON appraisals FOR SELECT
  USING (staff_id = auth.uid() OR reviewer_id = auth.uid());

CREATE POLICY "Managers can insert appraisals"
  ON appraisals FOR INSERT
  WITH CHECK (reviewer_id = auth.uid());

CREATE POLICY "Users can update their own appraisals"
  ON appraisals FOR UPDATE
  USING (staff_id = auth.uid() OR reviewer_id = auth.uid());

-- RLS Policies for disciplinary_cases
CREATE POLICY "Users can view their own disciplinary cases"
  ON disciplinary_cases FOR SELECT
  USING (staff_id = auth.uid() OR reported_by = auth.uid());

CREATE POLICY "Managers can insert disciplinary cases"
  ON disciplinary_cases FOR INSERT
  WITH CHECK (reported_by = auth.uid());

CREATE POLICY "Managers can update disciplinary cases"
  ON disciplinary_cases FOR UPDATE
  USING (reported_by = auth.uid());

-- RLS Policies for leave_requests
CREATE POLICY "Users can view their own leave requests"
  ON leave_requests FOR SELECT
  USING (staff_id = auth.uid() OR approved_by = auth.uid());

CREATE POLICY "Users can insert their own leave requests"
  ON leave_requests FOR INSERT
  WITH CHECK (staff_id = auth.uid());

CREATE POLICY "Managers can update leave requests"
  ON leave_requests FOR UPDATE
  USING (approved_by = auth.uid());

-- RLS Policies for holiday_allowance
CREATE POLICY "Users can view their own holiday allowance"
  ON holiday_allowance FOR SELECT
  USING (staff_id = auth.uid());

CREATE POLICY "Managers can manage holiday allowance"
  ON holiday_allowance FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));

-- RLS Policies for satisfaction_surveys
CREATE POLICY "Users can view their own surveys (if not anonymous)"
  ON satisfaction_surveys FOR SELECT
  USING (staff_id = auth.uid() OR is_anonymous = FALSE);

CREATE POLICY "Users can insert their own surveys"
  ON satisfaction_surveys FOR INSERT
  WITH CHECK (staff_id = auth.uid());

-- RLS Policies for incentives
CREATE POLICY "Users can view their own incentives"
  ON incentives FOR SELECT
  USING (staff_id = auth.uid() OR nominated_by = auth.uid());

CREATE POLICY "Managers can insert incentives"
  ON incentives FOR INSERT
  WITH CHECK (nominated_by = auth.uid());

-- RLS Policies for welfare_checks
CREATE POLICY "Users can view their own welfare checks"
  ON welfare_checks FOR SELECT
  USING (staff_id = auth.uid() OR conducted_by = auth.uid());

CREATE POLICY "Managers can insert welfare checks"
  ON welfare_checks FOR INSERT
  WITH CHECK (conducted_by = auth.uid());

CREATE POLICY "Managers can update welfare checks"
  ON welfare_checks FOR UPDATE
  USING (conducted_by = auth.uid());

-- Indexes
CREATE INDEX idx_appraisals_staff ON appraisals(staff_id);
CREATE INDEX idx_appraisals_date ON appraisals(appraisal_date);

CREATE INDEX idx_disciplinary_cases_staff ON disciplinary_cases(staff_id);
CREATE INDEX idx_disciplinary_cases_status ON disciplinary_cases(status);

CREATE INDEX idx_leave_requests_staff ON leave_requests(staff_id);
CREATE INDEX idx_leave_requests_status ON leave_requests(status);

CREATE INDEX idx_holiday_allowance_staff ON holiday_allowance(staff_id);

CREATE INDEX idx_satisfaction_surveys_staff ON satisfaction_surveys(staff_id);
CREATE INDEX idx_satisfaction_surveys_date ON satisfaction_surveys(survey_date);

CREATE INDEX idx_incentives_staff ON incentives(staff_id);
CREATE INDEX idx_incentives_date ON incentives(award_date);

CREATE INDEX idx_welfare_checks_staff ON welfare_checks(staff_id);
CREATE INDEX idx_welfare_checks_date ON welfare_checks(check_date);