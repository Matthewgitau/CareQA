-- Create sleep_charts table
CREATE TABLE sleep_charts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  chart_date DATE NOT NULL,
  bedtime_time TIME,
  bedtime_routine TEXT,
  overnight_entries JSONB NOT NULL,
  sleep_quality TEXT CHECK (sleep_quality IN ('Good', 'Fair', 'Poor', 'Very Poor', 'Unsettled throughout')),
  morning_notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sleep_audit_logs table for tracking edits
CREATE TABLE sleep_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chart_id UUID REFERENCES sleep_charts(id) ON DELETE CASCADE,
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

CREATE TRIGGER update_sleep_charts_updated_at 
    BEFORE UPDATE ON sleep_charts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_sleep_charts_service_user ON sleep_charts(service_user_id);
CREATE INDEX idx_sleep_charts_date ON sleep_charts(chart_date);