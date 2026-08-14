-- Create drivers table (extends carers)
CREATE TABLE drivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
  is_exclusive_driver BOOLEAN DEFAULT FALSE,
  staff_name TEXT NOT NULL,
  employee_id TEXT,
  job_role TEXT,
  contact_phone TEXT,
  date_of_birth DATE,
  license_number TEXT,
  license_expiry DATE,
  license_categories TEXT,
  license_issue_date DATE,
  license_checked BOOLEAN DEFAULT FALSE,
  has_endorsements BOOLEAN DEFAULT FALSE,
  endorsement_details TEXT,
  license_copy_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create vehicles table
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  registration TEXT UNIQUE NOT NULL,
  make_model TEXT NOT NULL,
  colour TEXT,
  vehicle_id_number TEXT,
  is_company_car BOOLEAN DEFAULT TRUE,
  status TEXT DEFAULT 'available',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create vehicle_assignments table (sign-out/return records)
CREATE TABLE vehicle_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID REFERENCES drivers(id),
  vehicle_id UUID REFERENCES vehicles(id),
  
  -- Sign-Out Details
  sign_out_date DATE NOT NULL,
  sign_out_time TIME NOT NULL,
  start_mileage INTEGER,
  fuel_level_start TEXT,
  existing_damage TEXT,
  purpose TEXT,
  expected_return_date DATE,
  
  -- Driver Details (snapshot at time of sign-out)
  driver_name TEXT,
  employee_id TEXT,
  job_role TEXT,
  contact_phone TEXT,
  
  -- Licence Details (snapshot)
  license_number TEXT,
  license_expiry DATE,
  license_categories TEXT,
  license_checked BOOLEAN,
  has_endorsements BOOLEAN,
  endorsement_details TEXT,
  license_confirmed BOOLEAN,
  
  -- Vehicle Details (snapshot)
  vehicle_registration TEXT,
  vehicle_make_model TEXT,
  vehicle_colour TEXT,
  
  -- Liability
  liability_accepted BOOLEAN DEFAULT FALSE,
  read_policy BOOLEAN DEFAULT FALSE,
  insurance_confirmed BOOLEAN DEFAULT FALSE,
  phone_policy_accepted BOOLEAN DEFAULT FALSE,
  smoking_policy_accepted BOOLEAN DEFAULT FALSE,
  special_instructions TEXT,
  
  -- Signatures
  signed_out_by TEXT,
  signed_out_to TEXT,
  
  -- Return Details
  return_date DATE,
  return_time TIME,
  end_mileage INTEGER,
  fuel_level_end TEXT,
  new_damage TEXT,
  keys_returned BOOLEAN,
  accessories_returned BOOLEAN,
  signed_back_in_by TEXT,
  signed_by_driver TEXT,
  
  -- Status
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_assignments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view drivers" ON drivers FOR SELECT USING (true);
CREATE POLICY "Users can insert drivers" ON drivers FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update drivers" ON drivers FOR UPDATE USING (true);

CREATE POLICY "Users can view vehicles" ON vehicles FOR SELECT USING (true);
CREATE POLICY "Users can insert vehicles" ON vehicles FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update vehicles" ON vehicles FOR UPDATE USING (true);

CREATE POLICY "Users can view assignments" ON vehicle_assignments FOR SELECT USING (true);
CREATE POLICY "Users can insert assignments" ON vehicle_assignments FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update assignments" ON vehicle_assignments FOR UPDATE USING (true);

-- Indexes
CREATE INDEX idx_drivers_carer ON drivers(carer_id);
CREATE INDEX idx_drivers_active ON drivers(is_active);
CREATE INDEX idx_vehicles_registration ON vehicles(registration);
CREATE INDEX idx_assignments_driver ON vehicle_assignments(driver_id);
CREATE INDEX idx_assignments_vehicle ON vehicle_assignments(vehicle_id);
CREATE INDEX idx_assignments_status ON vehicle_assignments(status);