-- ============================================================
-- PROFIT TRACKING SYSTEM - Consolidated Migration
-- Run this in Supabase SQL Editor instead of 106 and 107
-- ============================================================

-- 1. Add missing columns to receipt_entries
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS expense_category TEXT;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS expense_subcategory TEXT;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS route_id UUID;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS route_name TEXT;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS is_agency_expense BOOLEAN DEFAULT FALSE;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS agency_shift_id UUID;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS is_revenue BOOLEAN DEFAULT FALSE;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS revenue_source TEXT;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS approved_for_route BOOLEAN DEFAULT FALSE;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS approved_for_agency BOOLEAN DEFAULT FALSE;

-- 2. Create dom_care_routes table if not exists
CREATE TABLE IF NOT EXISTS dom_care_routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  organisation_id UUID REFERENCES organisations(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 3. Add route_id to visits for revenue tracking
ALTER TABLE visits ADD COLUMN IF NOT EXISTS route_id UUID REFERENCES dom_care_routes(id);
ALTER TABLE visits ADD COLUMN IF NOT EXISTS billing_amount DECIMAL(10,2);

-- 4. Link agency shifts to agency revenue
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS agency_client_id UUID;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS agency_billing_rate DECIMAL(10,2);

-- 5. Indexes for profit queries
CREATE INDEX IF NOT EXISTS idx_receipts_expense_category ON receipt_entries(expense_category);
CREATE INDEX IF NOT EXISTS idx_receipts_route_id ON receipt_entries(route_id);
CREATE INDEX IF NOT EXISTS idx_receipts_is_revenue ON receipt_entries(is_revenue);
CREATE INDEX IF NOT EXISTS idx_receipts_revenue_source ON receipt_entries(revenue_source);

-- 6. Profit snapshots table
CREATE TABLE IF NOT EXISTS profit_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  calculation_date DATE NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  calculation_type TEXT CHECK (calculation_type IN ('overall', 'route', 'agency')),
  
  -- Overall numbers
  total_revenue DECIMAL(12,2) DEFAULT 0,
  total_expenses DECIMAL(12,2) DEFAULT 0,
  total_profit DECIMAL(12,2) DEFAULT 0,
  profit_margin DECIMAL(5,2) DEFAULT 0,
  
  -- Breakdowns (JSONB for flexibility)
  revenue_by_source JSONB DEFAULT '{}',
  expenses_by_category JSONB DEFAULT '{}',
  expenses_by_route JSONB DEFAULT '{}',
  
  -- Route-specific
  route_id UUID REFERENCES dom_care_routes(id),
  route_name TEXT,
  route_revenue DECIMAL(12,2) DEFAULT 0,
  route_expenses DECIMAL(12,2) DEFAULT 0,
  route_profit DECIMAL(12,2) DEFAULT 0,
  route_margin DECIMAL(5,2) DEFAULT 0,
  route_visit_count INTEGER DEFAULT 0,
  route_revenue_per_visit DECIMAL(10,2) DEFAULT 0,
  route_profit_per_visit DECIMAL(10,2) DEFAULT 0,
  
  -- Agency-specific
  agency_revenue DECIMAL(12,2) DEFAULT 0,
  agency_expenses DECIMAL(12,2) DEFAULT 0,
  agency_profit DECIMAL(12,2) DEFAULT 0,
  agency_margin DECIMAL(5,2) DEFAULT 0,
  agency_placement_count INTEGER DEFAULT 0,
  
  -- Metadata
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id)
);

-- Enable RLS (using DROP + CREATE since IF NOT EXISTS not supported for policies in all PG versions)
ALTER TABLE profit_snapshots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_profit_snapshots ON profit_snapshots;
CREATE POLICY tenant_isolation_profit_snapshots ON profit_snapshots
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes on profit_snapshots
CREATE INDEX IF NOT EXISTS idx_profit_snapshots_date ON profit_snapshots(calculation_date);
CREATE INDEX IF NOT EXISTS idx_profit_snapshots_period ON profit_snapshots(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_profit_snapshots_type ON profit_snapshots(calculation_type);
CREATE INDEX IF NOT EXISTS idx_profit_snapshots_route ON profit_snapshots(route_id);