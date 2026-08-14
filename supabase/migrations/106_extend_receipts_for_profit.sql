-- Add expense segmentation fields
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS expense_category TEXT CHECK (expense_category IN (
  'wages', 'fuel', 'ppe', 'uniforms', 'training', 'vehicle_maintenance',
  'insurance', 'rent', 'utilities', 'marketing', 'office_supplies',
  'equipment', 'cleaning', 'food', 'staff', 'administration', 'other'
));

ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS expense_subcategory TEXT;

-- Add route attribution for Dom Care expenses
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS route_id UUID REFERENCES dom_care_routes(id);
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS route_name TEXT;

-- Add agency side fields
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS agency_shift_id UUID REFERENCES shifts(id);
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS is_agency_expense BOOLEAN DEFAULT FALSE;

-- Add profit tracking fields
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS is_revenue BOOLEAN DEFAULT FALSE;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS revenue_source TEXT CHECK (revenue_source IN ('dom_care_visit', 'agency_placement', 'other'));

-- Add approval tracking
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS approved_for_route BOOLEAN DEFAULT FALSE;
ALTER TABLE receipt_entries ADD COLUMN IF NOT EXISTS approved_for_agency BOOLEAN DEFAULT FALSE;

-- Indexes for profit queries
CREATE INDEX IF NOT EXISTS idx_receipts_expense_category ON receipt_entries(expense_category);
CREATE INDEX IF NOT EXISTS idx_receipts_route_id ON receipt_entries(route_id);
CREATE INDEX IF NOT EXISTS idx_receipts_is_revenue ON receipt_entries(is_revenue);
CREATE INDEX IF NOT EXISTS idx_receipts_revenue_source ON receipt_entries(revenue_source);