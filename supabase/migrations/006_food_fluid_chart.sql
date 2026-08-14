-- Create food_fluid_charts table with audit fields
CREATE TABLE food_fluid_charts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  chart_date DATE NOT NULL,
  entries JSONB NOT NULL,
  total_fluid_ml INTEGER,
  fluid_target_met BOOLEAN,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create food_fluid_audit_logs table for tracking edits
CREATE TABLE food_fluid_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chart_id UUID REFERENCES food_fluid_charts(id) ON DELETE CASCADE,
  edited_by UUID REFERENCES profiles(id),
  previous_data JSONB,
  new_data JSONB,
  edited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_food_fluid_charts_updated_at 
    BEFORE UPDATE ON food_fluid_charts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_food_fluid_charts_service_user ON food_fluid_charts(service_user_id);
CREATE INDEX idx_food_fluid_charts_date ON food_fluid_charts(chart_date);
CREATE INDEX idx_food_fluid_charts_created_by ON food_fluid_charts(created_by);
CREATE INDEX idx_food_fluid_audit_logs_chart ON food_fluid_audit_logs(chart_id);
CREATE INDEX idx_food_fluid_audit_logs_edited_by ON food_fluid_audit_logs(edited_by);
CREATE INDEX idx_food_fluid_audit_logs_edited_at ON food_fluid_audit_logs(edited_at);