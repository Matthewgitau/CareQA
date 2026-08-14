-- Create organisations profile table
CREATE TABLE organisation_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID REFERENCES organisations(id) UNIQUE,
  
  -- Business Details
  legal_name TEXT NOT NULL,
  trading_name TEXT,
  registration_number TEXT,
  vat_number TEXT,
  cqc_registration_number TEXT,
  
  -- Contact Details
  address_line_1 TEXT,
  address_line_2 TEXT,
  city TEXT,
  county TEXT,
  postcode TEXT,
  country TEXT DEFAULT 'United Kingdom',
  phone TEXT,
  email TEXT,
  website TEXT,
  
  -- Invoice Settings
  invoice_prefix TEXT DEFAULT 'INV-',
  invoice_terms TEXT DEFAULT '30 days',
  bank_name TEXT,
  bank_account_name TEXT,
  bank_sort_code TEXT,
  bank_account_number TEXT,
  tax_rate DECIMAL(5,2) DEFAULT 20.0,
  
  -- Branding
  logo_url TEXT,
  primary_color TEXT DEFAULT '#1565C0',
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create invoices table
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_number TEXT UNIQUE NOT NULL,
  
  -- Client Information
  client_type TEXT CHECK (client_type IN ('service_user', 'care_home', 'council', 'other')),
  client_id UUID,
  client_name TEXT NOT NULL,
  client_address TEXT,
  client_email TEXT,
  client_reference TEXT,
  
  -- Period
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  invoice_date DATE NOT NULL,
  due_date DATE NOT NULL,
  
  -- Line Items
  line_items JSONB DEFAULT '[]',
  
  -- Totals
  subtotal DECIMAL(12,2) DEFAULT 0,
  tax_rate DECIMAL(5,2) DEFAULT 20.0,
  tax_amount DECIMAL(12,2) DEFAULT 0,
  total_amount DECIMAL(12,2) DEFAULT 0,
  
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
  
  -- Payments
  payment_method TEXT,
  payment_reference TEXT,
  paid_date DATE,
  
  -- Metadata
  notes TEXT,
  terms TEXT,
  
  -- PDF
  pdf_url TEXT,
  
  -- Audit
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id)
);

-- Enable RLS
ALTER TABLE organisation_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY tenant_isolation_org_profiles ON organisation_profiles
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY tenant_isolation_invoices ON invoices
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_invoices_client ON invoices(client_id);
CREATE INDEX idx_invoices_period ON invoices(period_start, period_end);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_number ON invoices(invoice_number);

-- Auto-update timestamp
CREATE TRIGGER update_invoices_updated_at
  BEFORE UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Generate invoice number function
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
DECLARE
  prefix TEXT;
  year TEXT;
  seq TEXT;
BEGIN
  SELECT invoice_prefix INTO prefix FROM organisation_profiles WHERE organisation_id = NEW.organisation_id;
  IF prefix IS NULL THEN prefix := 'INV-'; END IF;
  
  year := TO_CHAR(NEW.invoice_date, 'YYYY');
  
  SELECT LPAD((COUNT(*) + 1)::TEXT, 6, '0') INTO seq
  FROM invoices 
  WHERE organisation_id = NEW.organisation_id 
  AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NEW.created_at);
  
  IF seq IS NULL THEN seq := '000001'; END IF;
  
  NEW.invoice_number := prefix || year || '-' || seq;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for invoice number
CREATE TRIGGER set_invoice_number
  BEFORE INSERT ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION generate_invoice_number();