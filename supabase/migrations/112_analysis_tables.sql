-- Create analysis_views table to store saved report configurations
CREATE TABLE analysis_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- View Details
  name TEXT NOT NULL,
  description TEXT,
  
  -- Configuration
  view_type TEXT CHECK (view_type IN (
    'financial',
    'compliance',
    'operational',
    'staff',
    'service_user',
    'custom'
  )),
  
  -- Filters Configuration
  filters JSONB DEFAULT '{}',
  
  -- Display Configuration
  display_options JSONB DEFAULT '{}',
  
  -- Access
  is_public BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES profiles(id),
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id)
);

-- Enable RLS
ALTER TABLE analysis_views ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY tenant_isolation_analysis_views ON analysis_views
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_analysis_views_type ON analysis_views(view_type);
CREATE INDEX idx_analysis_views_created ON analysis_views(created_at);