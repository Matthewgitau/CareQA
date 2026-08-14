-- Store profit calculation snapshots
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
  
  -- Breakdowns
  revenue_by_source JSONB, -- {dom_care: X, agency: X, other: X}
  expenses_by_category JSONB, -- {wages: X, fuel: X, ppe: X, ...}
  expenses_by_route JSONB, -- {route_id_1: X, route_id_2: X}
  
  -- Route-specific
  route_id UUID REFERENCES dom_care_routes(id),
  route_revenue DECIMAL(12,2),
  route_expenses DECIMAL(12,2),
  route_profit DECIMAL(12,2),
  
  -- Agency-specific
  agency_revenue DECIMAL(12,2),
  agency_expenses DECIMAL(12,2),
  agency_profit DECIMAL(12,2),
  
  -- Metadata
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id)
);

-- Enable RLS
ALTER TABLE profit_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS tenant_isolation_profit_snapshots ON profit_snapshots
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_profit_snapshots_date ON profit_snapshots(calculation_date);
CREATE INDEX IF NOT EXISTS idx_profit_snapshots_period ON profit_snapshots(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_profit_snapshots_type ON profit_snapshots(calculation_type);