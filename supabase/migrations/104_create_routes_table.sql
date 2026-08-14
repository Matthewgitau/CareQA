-- Routes table for daily care schedules
-- Each route represents a day's worth of calls/visits for a service user

CREATE TABLE IF NOT EXISTS public.routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_organisation_id UUID NOT NULL REFERENCES client_organisations(id) ON DELETE CASCADE,
  service_user_id UUID NOT NULL REFERENCES service_users(id) ON DELETE CASCADE,
  route_date DATE NOT NULL,
  call_number INTEGER NOT NULL,
  proposed_start_time TIME,
  proposed_end_time TIME,
  actual_start_time TIME,
  actual_end_time TIME,
  is_respite BOOLEAN DEFAULT FALSE,
  carer_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(client_organisation_id, service_user_id, route_date, call_number)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_routes_client_org ON routes(client_organisation_id);
CREATE INDEX IF NOT EXISTS idx_routes_service_user ON routes(service_user_id);
CREATE INDEX IF NOT EXISTS idx_routes_date ON routes(route_date);
CREATE INDEX IF NOT EXISTS idx_routes_carer ON routes(carer_id);

-- RLS
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

-- Clients can view their own routes
DROP POLICY IF EXISTS "clients_select_routes" ON routes;
CREATE POLICY "clients_select_routes" ON routes
  FOR SELECT TO authenticated
  USING (
    client_organisation_id IN (
      SELECT client_organisation_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Clients can insert their own routes
DROP POLICY IF EXISTS "clients_insert_routes" ON routes;
CREATE POLICY "clients_insert_routes" ON routes
  FOR INSERT TO authenticated
  WITH CHECK (
    client_organisation_id IN (
      SELECT client_organisation_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Clients can update their own routes
DROP POLICY IF EXISTS "clients_update_routes" ON routes;
CREATE POLICY "clients_update_routes" ON routes
  FOR UPDATE TO authenticated
  USING (
    client_organisation_id IN (
      SELECT client_organisation_id FROM profiles WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    client_organisation_id IN (
      SELECT client_organisation_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Clients can delete their own routes
DROP POLICY IF EXISTS "clients_delete_routes" ON routes;
CREATE POLICY "clients_delete_routes" ON routes
  FOR DELETE TO authenticated
  USING (
    client_organisation_id IN (
      SELECT client_organisation_id FROM profiles WHERE id = auth.uid()
    )
  );