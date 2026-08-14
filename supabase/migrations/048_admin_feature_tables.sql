-- Action Plans table
CREATE TABLE action_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES profiles(id),
  due_date DATE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue')),
  service_user_id UUID REFERENCES service_users(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Lessons Learnt table
CREATE TABLE lessons_learnt (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  incident_type TEXT,
  title TEXT NOT NULL,
  description TEXT,
  root_cause TEXT,
  action_taken TEXT,
  prevention_measures TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Policies table
CREATE TABLE policies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  policy_name TEXT NOT NULL,
  category TEXT,
  version TEXT,
  effective_date DATE,
  review_date DATE,
  file_url TEXT,
  content_text TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'draft', 'archived')),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID REFERENCES profiles(id),
  recipient_id UUID REFERENCES profiles(id),
  subject TEXT,
  content TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  type TEXT CHECK (type IN ('urgent', 'amber', 'routine', 'info')),
  title TEXT,
  body TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Matrix Records table
CREATE TABLE matrix_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES profiles(id),
  matrix_type TEXT CHECK (matrix_type IN ('training', 'supervision', 'appraisal', 'equipment')),
  completion_date DATE,
  next_due_date DATE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'overdue')),
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for all tables
ALTER TABLE action_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons_learnt ENABLE ROW LEVEL SECURITY;
ALTER TABLE policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE matrix_records ENABLE ROW LEVEL SECURITY;

-- RLS Policies for action_plans
CREATE POLICY "Users can view action plans from their organization"
  ON action_plans FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM service_users su
      JOIN profiles p ON p.organization_id = su.organization_id
      WHERE (su.id = action_plans.service_user_id OR action_plans.service_user_id IS NULL)
      AND p.id = auth.uid()
    )
  );

CREATE POLICY "Users can insert action plans"
  ON action_plans FOR INSERT
  WITH CHECK (
    service_user_id IS NULL OR EXISTS (
      SELECT 1 FROM service_users su
      JOIN profiles p ON p.organization_id = su.organization_id
      WHERE su.id = action_plans.service_user_id AND p.id = auth.uid()
    )
  );

CREATE POLICY "Users can update action plans"
  ON action_plans FOR UPDATE
  USING (
    service_user_id IS NULL OR EXISTS (
      SELECT 1 FROM service_users su
      JOIN profiles p ON p.organization_id = su.organization_id
      WHERE su.id = action_plans.service_user_id AND p.id = auth.uid()
    )
  );

-- RLS Policies for lessons_learnt
CREATE POLICY "Users can view lessons learnt from their organization"
  ON lessons_learnt FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid()
  ));

CREATE POLICY "Users can insert lessons learnt"
  ON lessons_learnt FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid()
  ));

-- RLS Policies for policies
CREATE POLICY "Users can view policies"
  ON policies FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid()
  ));

CREATE POLICY "Users can insert policies"
  ON policies FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid()
  ));

-- RLS Policies for messages
CREATE POLICY "Users can view their messages"
  ON messages FOR SELECT
  USING (sender_id = auth.uid() OR recipient_id = auth.uid());

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can update their received messages"
  ON messages FOR UPDATE
  USING (recipient_id = auth.uid());

-- RLS Policies for notifications
CREATE POLICY "Users can view their notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

-- RLS Policies for matrix_records
CREATE POLICY "Users can view matrix records from their organization"
  ON matrix_records FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
  ));

CREATE POLICY "Users can insert matrix records"
  ON matrix_records FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
  ));

-- Indexes
CREATE INDEX idx_action_plans_status ON action_plans(status);
CREATE INDEX idx_action_plans_due_date ON action_plans(due_date);
CREATE INDEX idx_action_plans_assigned_to ON action_plans(assigned_to);

CREATE INDEX idx_lessons_learnt_incident_type ON lessons_learnt(incident_type);
CREATE INDEX idx_lessons_learnt_created_at ON lessons_learnt(created_at);

CREATE INDEX idx_policies_category ON policies(category);
CREATE INDEX idx_policies_status ON policies(status);

CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_recipient ON messages(recipient_id);
CREATE INDEX idx_messages_read ON messages(read);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_type ON notifications(type);

CREATE INDEX idx_matrix_records_staff ON matrix_records(staff_id);
CREATE INDEX idx_matrix_records_type ON matrix_records(matrix_type);
CREATE INDEX idx_matrix_records_status ON matrix_records(status);