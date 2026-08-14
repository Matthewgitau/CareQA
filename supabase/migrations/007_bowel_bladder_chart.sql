-- Create bowel_bladder_charts table
CREATE TABLE bowel_bladder_charts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  chart_date DATE NOT NULL,
  entries JSONB NOT NULL,
  days_since_last_bowel INTEGER,
  warning_triggered BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bowel_bladder_audit_logs table for tracking edits
CREATE TABLE bowel_bladder_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chart_id UUID REFERENCES bowel_bladder_charts(id) ON DELETE CASCADE,
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

CREATE TRIGGER update_bowel_bladder_charts_updated_at 
    BEFORE UPDATE ON bowel_bladder_charts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_bowel_bladder_charts_service_user ON bowel_bladder_charts(service_user_id);
CREATE INDEX idx_bowel_bladder_charts_date ON bowel_bladder_charts(chart_date);
CREATE INDEX idx_bowel_bladder_charts_warning ON bowel_bladder_charts(warning_triggered) WHERE warning_triggered = true;