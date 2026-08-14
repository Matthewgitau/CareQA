-- Mental Capacity Assessment System
-- Based on comprehensive mental capacity assessment requirements

-- Mental capacity assessments
CREATE TABLE IF NOT EXISTS mental_capacity_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  assessor_id UUID REFERENCES profiles(id),
  assessment_date DATE NOT NULL,
  functional_test JSONB NOT NULL, -- 4-part functional test results
  two_stage_test JSONB NOT NULL, -- 2-stage test results
  best_interests JSONB, -- Best interests decision record
  imca_referral JSONB, -- IMCA referral information
  signature TEXT,
  status TEXT DEFAULT 'completed',
  capacity_level TEXT, -- Has Capacity, Lacks Capacity
  imca_details TEXT, -- IMCA involvement details
  pdf_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE mental_capacity_assessments ENABLE ROW LEVEL SECURITY;

-- Policies for mental capacity assessments
DROP POLICY IF EXISTS "Allow read access to own assessments" ON mental_capacity_assessments;
CREATE POLICY "Allow read access to own assessments" ON mental_capacity_assessments
FOR SELECT USING (
  assessor_id = auth.uid() OR 
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

DROP POLICY IF EXISTS "Allow insert for care staff" ON mental_capacity_assessments;
CREATE POLICY "Allow insert for care staff" ON mental_capacity_assessments
FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
);

DROP POLICY IF EXISTS "Allow update for care staff" ON mental_capacity_assessments;
CREATE POLICY "Allow update for care staff" ON mental_capacity_assessments
FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
);

-- Indexes for performance (only create if they don't exist)
CREATE INDEX IF NOT EXISTS idx_mental_capacity_assessments_service_user_id ON mental_capacity_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_mental_capacity_assessments_assessor_id ON mental_capacity_assessments(assessor_id);
CREATE INDEX IF NOT EXISTS idx_mental_capacity_assessments_date ON mental_capacity_assessments(assessment_date);
CREATE INDEX IF NOT EXISTS idx_mental_capacity_assessments_capacity_level ON mental_capacity_assessments(capacity_level);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_mental_capacity_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for updated_at (only create if it doesn't exist)
DROP TRIGGER IF EXISTS update_mental_capacity_assessments_timestamp ON mental_capacity_assessments;
CREATE TRIGGER update_mental_capacity_assessments_timestamp
  BEFORE UPDATE ON mental_capacity_assessments
  FOR EACH ROW EXECUTE FUNCTION update_mental_capacity_timestamp();

-- Function to generate PDF URL (placeholder for actual PDF generation)
CREATE OR REPLACE FUNCTION generate_mental_capacity_pdf_url(assessment_id UUID)
RETURNS TEXT AS $$
DECLARE
  pdf_url TEXT;
BEGIN
  -- In a real implementation, this would generate a PDF and return the URL
  -- For now, we'll return a placeholder URL
  pdf_url := 'https://careqa-documents.s3.amazonaws.com/mental_capacity/' || assessment_id::text || '.pdf';
  
  UPDATE mental_capacity_assessments 
  SET pdf_url = pdf_url 
  WHERE id = assessment_id;
  
  RETURN pdf_url;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get mental capacity summary
CREATE OR REPLACE FUNCTION get_mental_capacity_summary(service_user_id_param UUID)
RETURNS TABLE (
  total_assessments INTEGER,
  has_capacity_count INTEGER,
  lacks_capacity_count INTEGER,
  last_assessment_date DATE,
  imca_referrals_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_assessments,
    COUNT(CASE WHEN capacity_level = 'Has Capacity' THEN 1 END)::INTEGER as has_capacity_count,
    COUNT(CASE WHEN capacity_level = 'Lacks Capacity' THEN 1 END)::INTEGER as lacks_capacity_count,
    MAX(assessment_date) as last_assessment_date,
    COUNT(CASE WHEN imca_referral IS NOT NULL THEN 1 END)::INTEGER as imca_referrals_count
  FROM mental_capacity_assessments
  WHERE service_user_id = service_user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;