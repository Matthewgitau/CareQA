-- ========== STEP 1: CREATE VEHICLES TABLE ==========
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  registration TEXT UNIQUE NOT NULL,
  make_model TEXT NOT NULL,
  colour TEXT,
  vehicle_id_number TEXT,
  is_company_car BOOLEAN DEFAULT TRUE,
  status TEXT DEFAULT 'available',
  organisation_id UUID REFERENCES organisations(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========== STEP 2: ENABLE RLS ==========
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- ========== STEP 3: ADD RLS POLICIES ==========
DROP POLICY IF EXISTS "Allow all for authenticated users" ON vehicles;
CREATE POLICY "Allow all for authenticated users" ON vehicles
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ========== STEP 4: ADD INDEXES ==========
CREATE INDEX IF NOT EXISTS idx_vehicles_organisation ON vehicles(organisation_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_registration ON vehicles(registration);
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);

-- ========== STEP 5: VERIFY ==========
SELECT COUNT(*) FROM vehicles;

-- ========== STEP 6: VERIFY DRIVERS RLS ==========
-- Ensure drivers table has proper policies
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow insert for authenticated users" ON drivers;
CREATE POLICY "Allow insert for authenticated users" ON drivers
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Allow select for authenticated users" ON drivers;
CREATE POLICY "Allow select for authenticated users" ON drivers
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow update for authenticated users" ON drivers;
CREATE POLICY "Allow update for authenticated users" ON drivers
  FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow delete for authenticated users" ON drivers;
CREATE POLICY "Allow delete for authenticated users" ON drivers
  FOR DELETE TO authenticated USING (true);

-- ========== STEP 7: FINAL VERIFICATION ==========
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('drivers', 'vehicles')
ORDER BY tablename, cmd;