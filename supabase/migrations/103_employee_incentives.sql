-- ============================================
-- EMPLOYEE INCENTIVES & REWARDS SYSTEM
-- ============================================

-- 1. Incentive Programs Table
CREATE TABLE IF NOT EXISTS incentive_programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  program_name TEXT NOT NULL,
  program_type TEXT CHECK (program_type IN (
    'points_based', 'monetary_bonus', 'recognition_award', 'performance_bonus',
    'referral_bonus', 'retention_bonus', 'team_bonus', 'service_award', 'other'
  )),
  
  description TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  
  -- Budget
  total_budget NUMERIC(10,2),
  budget_spent NUMERIC(10,2) DEFAULT 0,
  
  -- Rules
  eligibility_criteria TEXT,
  rules TEXT,
  max_awards_per_employee INTEGER DEFAULT 1,
  
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Metadata
  organisation_id UUID REFERENCES organisations(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Employee Incentive Awards Table
CREATE TABLE IF NOT EXISTS employee_incentives (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Employee
  staff_id UUID NOT NULL,
  staff_name TEXT NOT NULL,
  employee_number TEXT,
  department TEXT,
  job_role TEXT,
  
  -- Incentive Details
  incentive_type TEXT CHECK (incentive_type IN (
    'employee_of_month', 'employee_of_quarter', 'employee_of_year',
    'spot_award', 'performance_bonus', 'referral_bonus', 'retention_bonus',
    'team_award', 'long_service_award', 'outstanding_care', 'innovation_award',
    'leadership_award', 'safety_hero', 'customer_service_excellence', 'other'
  )),
  
  incentive_program_id UUID REFERENCES incentive_programs(id),
  
  -- Points System
  points_awarded INTEGER DEFAULT 0,
  points_balance INTEGER DEFAULT 0,
  
  -- Monetary Value
  monetary_value NUMERIC(10,2) DEFAULT 0,
  currency TEXT DEFAULT 'GBP',
  
  -- Award Details
  award_date DATE NOT NULL,
  award_title TEXT NOT NULL,
  award_description TEXT,
  award_reason TEXT NOT NULL,
  
  -- Nominations
  nominated_by UUID REFERENCES profiles(id),
  nominated_by_name TEXT,
  nomination_notes TEXT,
  
  -- Approval
  approved_by UUID REFERENCES profiles(id),
  approved_by_name TEXT,
  approved_at TIMESTAMP WITH TIME ZONE,
  approval_notes TEXT,
  
  -- Recognition
  is_public BOOLEAN DEFAULT TRUE,
  certificate_url TEXT,
  photo_url TEXT,
  social_share_post TEXT,
  
  -- Redemption
  redeemed BOOLEAN DEFAULT FALSE,
  redeemed_at TIMESTAMP WITH TIME ZONE,
  redemption_details TEXT,
  
  -- Feedback
  employee_feedback TEXT,
  manager_feedback TEXT,
  
  -- Metadata
  organisation_id UUID REFERENCES organisations(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Employee Points Accounts Table
CREATE TABLE IF NOT EXISTS employee_points_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  staff_id UUID NOT NULL UNIQUE,
  staff_name TEXT NOT NULL,
  
  total_points_earned INTEGER DEFAULT 0,
  total_points_redeemed INTEGER DEFAULT 0,
  current_points_balance INTEGER GENERATED ALWAYS AS (
    total_points_earned - total_points_redeemed
  ) STORED,
  
  last_activity_at TIMESTAMP WITH TIME ZONE,
  
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Reward Catalogue Table
CREATE TABLE IF NOT EXISTS reward_catalogue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  reward_name TEXT NOT NULL,
  reward_type TEXT CHECK (reward_type IN (
    'gift_card', 'voucher', 'merchandise', 'experience', 'donation',
    'training_course', 'extra_holiday', 'flexible_hours', 'parking_spot', 'other'
  )),
  
  description TEXT,
  points_required INTEGER NOT NULL,
  monetary_value NUMERIC(10,2),
  
  image_url TEXT,
  supplier TEXT,
  
  -- Availability
  is_available BOOLEAN DEFAULT TRUE,
  stock_quantity INTEGER,
  
  -- Redemption Limits
  max_per_employee INTEGER DEFAULT 1,
  
  -- Metadata
  organisation_id UUID REFERENCES organisations(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Points Redemption Log
CREATE TABLE IF NOT EXISTS points_redemptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  staff_id UUID NOT NULL,
  staff_name TEXT NOT NULL,
  
  reward_id UUID REFERENCES reward_catalogue(id),
  reward_name TEXT NOT NULL,
  
  points_spent INTEGER NOT NULL,
  redemption_date DATE NOT NULL,
  
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'fulfilled', 'cancelled')),
  
  approval_notes TEXT,
  fulfilled_at TIMESTAMP WITH TIME ZONE,
  
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Performance Metrics Table
CREATE TABLE IF NOT EXISTS performance_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  staff_id UUID NOT NULL,
  staff_name TEXT NOT NULL,
  
  metric_type TEXT CHECK (metric_type IN (
    'visits_completed', 'on_time_rate', 'medication_accuracy',
    'client_complaints', 'compliments_received', 'overtime_hours', 'training_completed'
  )),
  
  metric_value NUMERIC(10,2),
  metric_period_start DATE,
  metric_period_end DATE,
  
  target_value NUMERIC(10,2),
  achievement_percentage NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN target_value > 0 THEN (metric_value / target_value) * 100
      ELSE 0
    END
  ) STORED,
  
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE incentive_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_incentives ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_points_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_catalogue ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================
DROP POLICY IF EXISTS "tenant_isolation_incentive_programs" ON incentive_programs;
CREATE POLICY "tenant_isolation_incentive_programs" ON incentive_programs
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_employee_incentives" ON employee_incentives;
CREATE POLICY "tenant_isolation_employee_incentives" ON employee_incentives
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_points_accounts" ON employee_points_accounts;
CREATE POLICY "tenant_isolation_points_accounts" ON employee_points_accounts
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_reward_catalogue" ON reward_catalogue;
CREATE POLICY "tenant_isolation_reward_catalogue" ON reward_catalogue
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "tenant_isolation_points_redemptions" ON points_redemptions;
CREATE POLICY "tenant_isolation_points_redemptions" ON points_redemptions
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_incentives_staff ON employee_incentives(staff_id);
CREATE INDEX IF NOT EXISTS idx_incentives_date ON employee_incentives(award_date);
CREATE INDEX IF NOT EXISTS idx_incentives_type ON employee_incentives(incentive_type);
CREATE INDEX IF NOT EXISTS idx_points_accounts_balance ON employee_points_accounts(current_points_balance);
CREATE INDEX IF NOT EXISTS idx_redemptions_staff ON points_redemptions(staff_id);
CREATE INDEX IF NOT EXISTS idx_rewards_available ON reward_catalogue(is_available);
CREATE INDEX IF NOT EXISTS idx_metrics_staff ON performance_metrics(staff_id);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Add points to employee account
CREATE OR REPLACE FUNCTION add_points_to_employee(
  p_staff_id UUID,
  p_points INTEGER,
  p_reason TEXT
)
RETURNS void AS $$
BEGIN
  UPDATE employee_points_accounts
  SET total_points_earned = total_points_earned + p_points,
      last_activity_at = NOW()
  WHERE staff_id = p_staff_id;
END;
$$ LANGUAGE plpgsql;

-- Auto-create points account for new staff
CREATE OR REPLACE FUNCTION auto_create_points_account()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO employee_points_accounts (staff_id, staff_name)
  VALUES (NEW.id, NEW.full_name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for new staff
CREATE TRIGGER create_points_account_on_staff_add
  AFTER INSERT ON profiles
  FOR EACH ROW
  WHEN (NEW.role IN ('carer', 'staff'))
  EXECUTE FUNCTION auto_create_points_account();
