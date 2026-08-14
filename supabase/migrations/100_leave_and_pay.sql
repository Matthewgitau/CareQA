-- ============================================
-- LEAVE & PAY SYSTEM
-- ============================================

-- 1. Leave Requests Table
CREATE TABLE IF NOT EXISTS leave_requests (
  id UUID PRIMARY DEFAULT uuid_generate_v4(),
  staff_id UUID NOT NULL,
  staff_name TEXT NOT NULL,
  employee_number TEXT,

  -- Leave Details
  leave_type TEXT NOT NULL CHECK (leave_type IN (
    'annual_holiday',
    'sick_leave',
    'compassionate_leave',
    'bereavement_leave',
    'maternity_leave',
    'paternity_leave',
    'adoption_leave',
    'parental_leave',
    'carers_leave',
    'study_leave',
    'emergency_leave',
    'unpaid_leave',
    'other'
  )),

  -- Date Range
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_days NUMERIC(5,1) GENERATED ALWAYS AS (
    (end_date - start_date) + 1
  ) STORED,

  -- Pay Calculation
  pay_rate_type TEXT DEFAULT 'statutory' CHECK (pay_rate_type IN ('statutory', 'enhanced', 'unpaid', 'full_pay')),
  pay_percentage INTEGER DEFAULT 100 CHECK (pay_percentage BETWEEN 0 AND 100),
  hourly_rate NUMERIC(10,2),
  daily_rate NUMERIC(10,2),

  -- Approval Workflow
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled', 'withdrawn')),
  requested_by UUID REFERENCES profiles(id),
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejected_reason TEXT,

  -- Payroll
  payroll_processed BOOLEAN DEFAULT FALSE,
  payroll_processed_at TIMESTAMP WITH TIME ZONE,
  payroll_notes TEXT,

  -- Metadata
  notes TEXT,
  attachment_url TEXT,
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Holiday Allowance Table (per staff member, per year)
CREATE TABLE IF NOT EXISTS holiday_allowance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  year INTEGER NOT NULL,
  total_allowance_days NUMERIC(5,1) DEFAULT 28.0,
  taken_days NUMERIC(5,1) DEFAULT 0.0,
  remaining_days NUMERIC(5,1) GENERATED ALWAYS AS (total_allowance_days - taken_days) STORED,
  carried_over_days NUMERIC(5,1) DEFAULT 0.0,
  notes TEXT,
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(staff_id, year)
);

-- 3. Payroll History Table
CREATE TABLE IF NOT EXISTS payroll_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  staff_name TEXT NOT NULL,
  employee_number TEXT,

  -- Period
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  period_label TEXT GENERATED ALWAYS AS (
    TO_CHAR(period_start, 'Mon YYYY')
  ) STORED,

  -- Hours
  regular_hours NUMERIC(8,2) DEFAULT 0,
  overtime_hours NUMERIC(8,2) DEFAULT 0,
  total_hours NUMERIC(8,2) GENERATED ALWAYS AS (regular_hours + overtime_hours) STORED,

  -- Rates
  hourly_rate NUMERIC(10,2),
  overtime_rate NUMERIC(10,2),

  -- Pay
  regular_pay NUMERIC(10,2),
  overtime_pay NUMERIC(10,2),
  holiday_pay NUMERIC(10,2) DEFAULT 0,
  sick_pay NUMERIC(10,2) DEFAULT 0,
  bonus_pay NUMERIC(10,2) DEFAULT 0,
  deductions NUMERIC(10,2) DEFAULT 0,

  -- Tax & NI
  tax_deducted NUMERIC(10,2) DEFAULT 0,
  ni_deducted NUMERIC(10,2) DEFAULT 0,

  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'processed', 'paid', 'approved')),
  processed_at TIMESTAMP WITH TIME ZONE,
  paid_at TIMESTAMP WITH TIME ZONE,

  -- Metadata
  notes TEXT,
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Leave Policy Settings (per organisation)
CREATE TABLE IF NOT EXISTS leave_policy_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID REFERENCES organisations(id) UNIQUE,

  -- Holiday Settings
  statutory_holiday_days NUMERIC(5,1) DEFAULT 28.0,
  enhanced_holiday_days NUMERIC(5,1),
  holiday_year_start_month INTEGER DEFAULT 1,

  -- Pay Settings
  holiday_pay_rate_type TEXT DEFAULT 'statutory' CHECK (holiday_pay_rate_type IN ('statutory', 'enhanced', 'average_earnings')),
  sick_pay_type TEXT DEFAULT 'statutory' CHECK (sick_pay_type IN ('statutory', 'enhanced', 'full_pay')),

  -- Notification Settings
  reminder_days_before_leave INTEGER DEFAULT 7,
  require_approval BOOLEAN DEFAULT TRUE,
  max_consecutive_days INTEGER DEFAULT 20,

  -- Custom
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE holiday_allowance ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_policy_settings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================
DROP POLICY IF EXISTS "tenant_isolation_leave_requests" ON leave_requests;
CREATE POLICY "tenant_isolation_leave_requests" ON leave_requests
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_holiday_allowance" ON holiday_allowance;
CREATE POLICY "tenant_isolation_holiday_allowance" ON holiday_allowance
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_payroll_history" ON payroll_history;
CREATE POLICY "tenant_isolation_payroll_history" ON payroll_history
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_leave_policy" ON leave_policy_settings;
CREATE POLICY "tenant_isolation_leave_policy" ON leave_policy_settings
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_leave_requests_staff ON leave_requests(staff_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_dates ON leave_requests(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_holiday_allowance_staff_year ON holiday_allowance(staff_id, year);
CREATE INDEX IF NOT EXISTS idx_payroll_history_staff ON payroll_history(staff_id);
CREATE INDEX IF NOT EXISTS idx_payroll_history_period ON payroll_history(period_start, period_end);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Calculate holiday allowance for a staff member
CREATE OR REPLACE FUNCTION calculate_holiday_allowance(p_staff_id UUID, p_year INTEGER)
RETURNS NUMERIC AS $$
DECLARE
  v_allowance NUMERIC;
BEGIN
  SELECT statutory_holiday_days INTO v_allowance
  FROM leave_policy_settings
  WHERE organisation_id = (SELECT organisation_id FROM profiles WHERE id = p_staff_id);

  IF v_allowance IS NULL THEN
    v_allowance := 28.0;
  END IF;

  RETURN v_allowance;
END;
$$ LANGUAGE plpgsql;

-- Auto-create holiday allowance for new staff
CREATE OR REPLACE FUNCTION auto_create_holiday_allowance()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO holiday_allowance (staff_id, year, total_allowance_days)
  VALUES (
    NEW.id,
    EXTRACT(YEAR FROM CURRENT_DATE),
    calculate_holiday_allowance(NEW.id, EXTRACT(YEAR FROM CURRENT_DATE))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;