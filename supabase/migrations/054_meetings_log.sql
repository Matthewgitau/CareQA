-- Meetings Log table for tracking staff meetings
CREATE TABLE meetings_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  meeting_date DATE NOT NULL,
  meeting_time TIME,
  location TEXT,
  attendees TEXT[],
  agenda TEXT,
  minutes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE meetings_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view meetings"
  ON meetings_log FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert meetings"
  ON meetings_log FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update meetings"
  ON meetings_log FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by);

CREATE POLICY "Users can delete meetings"
  ON meetings_log FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- Indexes
CREATE INDEX idx_meetings_log_date ON meetings_log(meeting_date);
CREATE INDEX idx_meetings_log_created_by ON meetings_log(created_by);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_meetings_log_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS meetings_log_updated_at ON meetings_log;
CREATE TRIGGER meetings_log_updated_at
  BEFORE UPDATE ON meetings_log
  FOR EACH ROW
  EXECUTE FUNCTION update_meetings_log_updated_at();

-- Grant permissions
GRANT ALL ON meetings_log TO authenticated;