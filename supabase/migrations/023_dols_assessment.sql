-- Create dols_assessments table
CREATE TABLE IF NOT EXISTS dols_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
    assessor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    assessment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    responses JSONB NOT NULL DEFAULT '{}',
    action_plan JSONB NOT NULL DEFAULT '[]',
    signature TEXT,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'signed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries (only create if they don't exist)
CREATE INDEX IF NOT EXISTS idx_dols_assessments_service_user_id ON dols_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_dols_assessments_assessment_date ON dols_assessments(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_dols_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS dols_assessments_updated_at ON dols_assessments;
CREATE TRIGGER dols_assessments_updated_at
    BEFORE UPDATE ON dols_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_dols_assessments_updated_at();

-- RLS Policies
ALTER TABLE dols_assessments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own assessments
DROP POLICY IF EXISTS "Users can view DOLS assessments" ON dols_assessments;
CREATE POLICY "Users can view DOLS assessments" ON dols_assessments
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert assessments
DROP POLICY IF EXISTS "Users can insert DOLS assessments" ON dols_assessments;
CREATE POLICY "Users can insert DOLS assessments" ON dols_assessments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own assessments
DROP POLICY IF EXISTS "Users can update DOLS assessments" ON dols_assessments;
CREATE POLICY "Users can update DOLS assessments" ON dols_assessments
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own assessments
DROP POLICY IF EXISTS "Users can delete DOLS assessments" ON dols_assessments;
CREATE POLICY "Users can delete DOLS assessments" ON dols_assessments
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON dols_assessments TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;