-- Migration 084: Complete MAR Chart System
-- Creates mar_medications, mar_suggestions, and mar_administration_logs tables
-- with full RLS policies for admin-app

-- ============================================================
-- 1. mar_medications — Core medication records
-- ============================================================
CREATE TABLE IF NOT EXISTS mar_medications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID NOT NULL REFERENCES service_users(id) ON DELETE CASCADE,
  service_user_name TEXT NOT NULL,

  -- Medication details
  medication_name TEXT NOT NULL,
  dosage TEXT NOT NULL, -- e.g., "10mg", "5ml", "1 tablet"
  dosage_unit TEXT, -- mg, ml, tablet, patch, inhalation
  strength TEXT, -- e.g., "10mg/5ml"
  form TEXT, -- tablet, capsule, liquid, injection, cream, patch, inhaler

  -- Schedule
  frequency TEXT NOT NULL, -- 'once_daily', 'twice_daily', 'three_times_daily', 'four_times_daily', 'as_required'
  frequency_times TEXT[], -- e.g., ['08:00'], ['08:00', '20:00'], ['08:00', '14:00', '20:00']
  times_per_day INTEGER, -- calculated from frequency_times length
  days_of_week INTEGER[], -- 0=Sunday to 6=Saturday, NULL means daily

  -- Duration
  start_date DATE NOT NULL,
  end_date DATE,
  is_ongoing BOOLEAN DEFAULT true,

  -- Administration instructions
  special_instructions TEXT, -- e.g., "Take with food", "Avoid dairy"
  administration_route TEXT, -- oral, sublingual, topical, subcutaneous, intramuscular, intravenous, rectal, ophthalmic, otic, inhaled

  -- Prescriber info
  prescribed_by TEXT, -- doctor name
  prescribed_date DATE,

  -- Pharmacy info
  pharmacy_name TEXT,
  pharmacy_phone TEXT,

  -- Status
  is_active BOOLEAN DEFAULT true,
  is_prn BOOLEAN DEFAULT false, -- As required / when needed

  -- Stopping info
  stopped_date DATE,
  stopped_reason TEXT, -- 'course_completed', 'changed_medication', 'adverse_reaction', 'refused', 'other'

  -- Stock/Supply
  stock_quantity INTEGER, -- e.g., number of tablets remaining
  stock_unit TEXT, -- tablets, ml, patches
  reorder_level INTEGER, -- alert when stock reaches this level
  last_ordered_date DATE,
  next_refill_due DATE,

  -- Audit
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID,

  -- Soft delete
  deleted_at TIMESTAMPTZ,
  deleted_by UUID
);

-- ============================================================
-- 2. mar_suggestions — Staff change requests for admin review
-- ============================================================
CREATE TABLE IF NOT EXISTS mar_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  original_medication_id UUID REFERENCES mar_medications(id) ON DELETE CASCADE,
  service_user_id UUID NOT NULL,
  service_user_name TEXT NOT NULL,

  -- Suggested changes (if new medication, original_medication_id is NULL)
  suggestion_type TEXT NOT NULL, -- 'create', 'update', 'delete', 'stop'

  -- Suggested medication fields
  medication_name TEXT,
  dosage TEXT,
  dosage_unit TEXT,
  strength TEXT,
  form TEXT,
  frequency TEXT,
  frequency_times TEXT[],
  start_date DATE,
  end_date DATE,
  is_ongoing BOOLEAN,
  special_instructions TEXT,
  administration_route TEXT,

  -- Suggestion metadata
  suggested_by UUID NOT NULL,
  suggested_by_name TEXT NOT NULL,
  suggested_at TIMESTAMPTZ DEFAULT NOW(),
  suggestion_reason TEXT, -- why staff think this change is needed

  -- Status
  status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  reviewed_by UUID,
  reviewed_by_name TEXT,
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  approved_action_id UUID, -- if approved, the new/updated medication ID

  organisation_id UUID
);

-- ============================================================
-- 3. mar_administration_logs — Daily administration records
-- ============================================================
CREATE TABLE IF NOT EXISTS mar_administration_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medication_id UUID NOT NULL REFERENCES mar_medications(id) ON DELETE CASCADE,
  service_user_id UUID NOT NULL,
  scheduled_time TIMESTAMPTZ NOT NULL,
  administered_at TIMESTAMPTZ,
  administered_by UUID,
  administered_by_name TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'administered', 'missed', 'refused', 'held'
  refusal_reason TEXT,
  notes TEXT,
  witnessed_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  organisation_id UUID
);

-- ============================================================
-- 4. Indexes for performance
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_mar_medications_service_user ON mar_medications(service_user_id);
CREATE INDEX IF NOT EXISTS idx_mar_medications_active ON mar_medications(is_active);
CREATE INDEX IF NOT EXISTS idx_mar_medications_organisation ON mar_medications(organisation_id);
CREATE INDEX IF NOT EXISTS idx_mar_medications_deleted ON mar_medications(deleted_at);

CREATE INDEX IF NOT EXISTS idx_mar_suggestions_status ON mar_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_mar_suggestions_service_user ON mar_suggestions(service_user_id);
CREATE INDEX IF NOT EXISTS idx_mar_suggestions_organisation ON mar_suggestions(organisation_id);

CREATE INDEX IF NOT EXISTS idx_mar_admin_logs_medication ON mar_administration_logs(medication_id);
CREATE INDEX IF NOT EXISTS idx_mar_admin_logs_service_user ON mar_administration_logs(service_user_id);
CREATE INDEX IF NOT EXISTS idx_mar_admin_logs_scheduled ON mar_administration_logs(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_mar_admin_logs_status ON mar_administration_logs(status);

-- ============================================================
-- 5. Enable Row Level Security
-- ============================================================
ALTER TABLE mar_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE mar_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE mar_administration_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 6. RLS Policies for admin-app (full access for authenticated users)
-- ============================================================

-- mar_medications policies
DROP POLICY IF EXISTS "Admin full access mar_medications" ON mar_medications;
CREATE POLICY "Admin full access mar_medications" ON mar_medications
  FOR ALL USING (auth.role() = 'authenticated');

-- mar_suggestions policies
DROP POLICY IF EXISTS "Admin full access mar_suggestions" ON mar_suggestions;
CREATE POLICY "Admin full access mar_suggestions" ON mar_suggestions
  FOR ALL USING (auth.role() = 'authenticated');

-- mar_administration_logs policies
DROP POLICY IF EXISTS "Admin full access mar_administration_logs" ON mar_administration_logs;
CREATE POLICY "Admin full access mar_administration_logs" ON mar_administration_logs
  FOR ALL USING (auth.role() = 'authenticated');
