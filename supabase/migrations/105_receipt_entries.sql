-- Receipt Entries Table
CREATE TABLE receipt_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Receipt Data
  merchant_name TEXT NOT NULL,
  merchant_address TEXT,
  merchant_phone TEXT,
  merchant_tax_id TEXT,
  
  -- Transaction Details
  receipt_date DATE NOT NULL,
  receipt_time TIME,
  subtotal DECIMAL(10,2),
  tax_rate DECIMAL(5,2),
  tax_amount DECIMAL(10,2),
  total_amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'GBP',
  payment_method TEXT CHECK (payment_method IN ('cash', 'card', 'bank_transfer', 'cheque', 'other')),
  card_last_four TEXT,
  
  -- Items
  items JSONB DEFAULT '[]', -- [{description, quantity, unit_price, total}]
  
  -- OCR Data
  ocr_raw_text TEXT,
  ocr_confidence INTEGER,
  ocr_provider TEXT, -- 'budgetlens', 'tesseract', 'manual'
  
  -- Photos (for reference)
  original_photo_url TEXT,
  
  -- Category & Tags
  category TEXT CHECK (category IN (
    'fuel', 'ppe', 'uniforms', 'training', 'vehicle', 'insurance',
    'rent', 'utilities', 'marketing', 'office_supplies', 'food',
    'equipment', 'maintenance', 'cleaning', 'staff', 'other'
  )),
  tags TEXT[],
  
  -- Expense Details
  is_billable BOOLEAN DEFAULT FALSE,
  billable_to UUID REFERENCES service_users(id),
  expense_notes TEXT,
  
  -- Approval
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'audited')),
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Receipt Data (for regeneration)
  receipt_data JSONB, -- Full structured receipt data for reconstruction
  
  -- Metadata
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id)
);

-- Enable RLS
ALTER TABLE receipt_entries ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY tenant_isolation_receipts ON receipt_entries
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_receipts_date ON receipt_entries(receipt_date);
CREATE INDEX idx_receipts_merchant ON receipt_entries(merchant_name);
CREATE INDEX idx_receipts_category ON receipt_entries(category);
CREATE INDEX idx_receipts_status ON receipt_entries(status);

-- Auto-update updated_at trigger
CREATE TRIGGER update_receipt_entries_updated_at
  BEFORE UPDATE ON receipt_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();