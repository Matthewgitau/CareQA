-- Whistleblower Reports (anonymous)
CREATE TABLE whistleblower_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reference_number TEXT UNIQUE,
  category TEXT NOT NULL,
  incident_date DATE,
  description TEXT NOT NULL,
  people_involved TEXT,
  evidence_urls TEXT[],
  status TEXT DEFAULT 'submitted',
  investigation_notes TEXT,
  escalated_to TEXT,
  escalated_at TIMESTAMP WITH TIME ZONE,
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Medication Incidents
CREATE TABLE medication_incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id),
  staff_id UUID REFERENCES profiles(id),
  incident_date TIMESTAMP WITH TIME ZONE NOT NULL,
  incident_type TEXT NOT NULL,
  medication_name TEXT NOT NULL,
  medication_dose TEXT,
  medication_route TEXT,
  scheduled_time TIME,
  actual_time TIME,
  severity TEXT DEFAULT 'medium',
  immediate_action TEXT,
  cqc_reportable BOOLEAN DEFAULT FALSE,
  investigation_notes TEXT,
  prevention_measures TEXT,
  status TEXT DEFAULT 'reported',
  reported_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Compliments
CREATE TABLE compliments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id),
  staff_id UUID REFERENCES profiles(id),
  compliment_date DATE NOT NULL,
  compliment_details TEXT NOT NULL,
  thank_you_sent BOOLEAN DEFAULT FALSE,
  thank_you_sent_date DATE,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Missing Items
CREATE TABLE missing_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  item_name TEXT NOT NULL,
  item_description TEXT,
  item_value NUMERIC,
  last_seen_date DATE,
  last_seen_location TEXT,
  reported_by UUID REFERENCES profiles(id),
  assigned_to UUID REFERENCES profiles(id),
  investigation_notes TEXT,
  status TEXT DEFAULT 'reported',
  found_date DATE,
  found_location TEXT,
  insurance_claimed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for all tables
ALTER TABLE whistleblower_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliments ENABLE ROW LEVEL SECURITY;
ALTER TABLE missing_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies for whistleblower_reports (anonymous)
CREATE POLICY "Anyone can submit whistleblower reports"
  ON whistleblower_reports FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Managers can view whistleblower reports"
  ON whistleblower_reports FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Managers can update whistleblower reports"
  ON whistleblower_reports FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));

-- RLS Policies for medication_incidents
CREATE POLICY "Users can view medication incidents"
  ON medication_incidents FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert medication incidents"
  ON medication_incidents FOR INSERT
  WITH CHECK (reported_by = auth.uid());

CREATE POLICY "Managers can update medication incidents"
  ON medication_incidents FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));

-- RLS Policies for compliments
CREATE POLICY "Users can view compliments"
  ON compliments FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert compliments"
  ON compliments FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Managers can update compliments"
  ON compliments FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));

-- RLS Policies for missing_items
CREATE POLICY "Users can view missing items"
  ON missing_items FOR SELECT
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert missing items"
  ON missing_items FOR INSERT
  WITH CHECK (reported_by = auth.uid());

CREATE POLICY "Managers can update missing items"
  ON missing_items FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_whistleblower_reports_status ON whistleblower_reports(status);
CREATE INDEX idx_whistleblower_reports_created ON whistleblower_reports(created_at);

CREATE INDEX idx_medication_incidents_service_user ON medication_incidents(service_user_id);
CREATE INDEX idx_medication_incidents_status ON medication_incidents(status);
CREATE INDEX idx_medication_incidents_date ON medication_incidents(incident_date);

CREATE INDEX idx_compliments_staff ON compliments(staff_id);
CREATE INDEX idx_compliments_date ON compliments(compliment_date);

CREATE INDEX idx_missing_items_status ON missing_items(status);
CREATE INDEX idx_missing_items_created ON missing_items(created_at);