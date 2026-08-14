-- Supplier Register Table - Compliant with CQC, HSE, and Financial Regulations
CREATE TABLE supplier_register (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Supplier Details
  supplier_name TEXT NOT NULL,
  trading_name TEXT,
  supplier_type TEXT CHECK (supplier_type IN (
    'medical_supplies',
    'catering',
    'cleaning',
    'maintenance',
    'equipment',
    'ppe',
    'medication',
    'laundry',
    'training',
    'consultancy',
    'utilities',
    'software',
    'telecare',
    'transport',
    'other'
  )),
  supplier_status TEXT DEFAULT 'active' CHECK (supplier_status IN ('active', 'inactive', 'suspended', 'pending_approval')),
  
  -- Contact Information
  contact_name TEXT,
  contact_title TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  contact_mobile TEXT,
  address_line_1 TEXT,
  address_line_2 TEXT,
  city TEXT,
  county TEXT,
  postcode TEXT,
  country TEXT DEFAULT 'United Kingdom',
  website_url TEXT,
  
  -- Registration & Compliance Numbers
  company_registration_number TEXT,
  vat_number TEXT,
  cqc_registration_number TEXT,
  nhs_supplier_code TEXT,
  iso_certifications TEXT[],
  
  -- Insurance
  insurance_provider TEXT,
  insurance_policy_number TEXT,
  public_liability_expiry DATE,
  employers_liability_expiry DATE,
  professional_indemnity_expiry DATE,
  
  -- Compliance Documents
  contract_url TEXT,
  data_sharing_agreement_url TEXT,
  dbs_policy_url TEXT,
  health_safety_policy_url TEXT,
  quality_policy_url TEXT,
  equal_opportunities_policy_url TEXT,
  environmental_policy_url TEXT,
  safeguarding_policy_url TEXT,
  whistleblowing_policy_url TEXT,
  
  -- Financial Details
  payment_terms TEXT DEFAULT '30_days' CHECK (payment_terms IN ('7_days', '14_days', '30_days', '60_days', 'prepaid', 'other')),
  bank_name TEXT,
  bank_account_name TEXT,
  bank_sort_code TEXT,
  bank_account_number TEXT,
  invoicing_notes TEXT,
  
  -- Performance & Risk Rating
  performance_rating INTEGER CHECK (performance_rating BETWEEN 1 AND 5),
  risk_rating TEXT CHECK (risk_rating IN ('low', 'medium', 'high', 'critical')),
  last_performance_review_date DATE,
  next_performance_review_date DATE,
  quality_rating INTEGER CHECK (quality_rating BETWEEN 1 AND 5),
  value_rating INTEGER CHECK (value_rating BETWEEN 1 AND 5),
  
  -- Compliance Checks
  last_compliance_check_date DATE,
  next_compliance_check_date DATE,
  compliance_status TEXT DEFAULT 'pending' CHECK (compliance_status IN ('compliant', 'non_compliant', 'pending', 'needs_review')),
  compliance_notes TEXT,
  
  -- Contract Details
  contract_start_date DATE,
  contract_end_date DATE,
  contract_value DECIMAL(10,2),
  contract_renewal_terms TEXT,
  notice_period_weeks INTEGER DEFAULT 4,
  
  -- Service Details
  services_provided TEXT[],
  special_requirements TEXT,
  hours_of_operation TEXT,
  emergency_contact_procedure TEXT,
  
  -- Incident History
  incident_history JSONB DEFAULT '[]',
  complaint_history JSONB DEFAULT '[]',
  
  -- Notes & Metadata
  notes TEXT,
  internal_notes TEXT,
  
  -- Audit Trail
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id),
  
  -- Unique Constraint
  UNIQUE(organisation_id, company_registration_number)
);

-- Enable RLS
ALTER TABLE supplier_register ENABLE ROW LEVEL SECURITY;

-- RLS Policy - Tenant Isolation
CREATE POLICY tenant_isolation_supplier_register ON supplier_register
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_supplier_register_name ON supplier_register(supplier_name);
CREATE INDEX idx_supplier_register_type ON supplier_register(supplier_type);
CREATE INDEX idx_supplier_register_status ON supplier_register(supplier_status);
CREATE INDEX idx_supplier_register_risk ON supplier_register(risk_rating);
CREATE INDEX idx_supplier_register_contract_end ON supplier_register(contract_end_date);
CREATE INDEX idx_supplier_register_compliance_status ON supplier_register(compliance_status);
CREATE INDEX idx_supplier_register_insurance_expiry ON supplier_register(public_liability_expiry);

-- Auto-update updated_at trigger
CREATE TRIGGER update_supplier_register_updated_at
  BEFORE UPDATE ON supplier_register
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to check compliance status
CREATE OR REPLACE FUNCTION check_supplier_compliance()
RETURNS TRIGGER AS $$
BEGIN
  -- If any compliance document is missing, mark as non_compliant
  IF NEW.data_sharing_agreement_url IS NULL OR
     NEW.health_safety_policy_url IS NULL THEN
    NEW.compliance_status := 'non_compliant';
  END IF;
  
  -- If insurance is expired, mark as non_compliant
  IF NEW.public_liability_expiry < CURRENT_DATE OR
     NEW.employers_liability_expiry < CURRENT_DATE THEN
    NEW.compliance_status := 'non_compliant';
  END IF;
  
  -- If contract has ended, mark for review
  IF NEW.contract_end_date < CURRENT_DATE THEN
    NEW.supplier_status := 'suspended';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-check compliance on insert/update
CREATE TRIGGER supplier_compliance_check
  BEFORE INSERT OR UPDATE ON supplier_register
  FOR EACH ROW
  EXECUTE FUNCTION check_supplier_compliance();