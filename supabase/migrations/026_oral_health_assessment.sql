-- Create oral_health_assessments table
CREATE TABLE IF NOT EXISTS oral_health_assessments (
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
CREATE INDEX IF NOT EXISTS idx_oral_health_assessments_service_user_id ON oral_health_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_oral_health_assessments_assessment_date ON oral_health_assessments(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_oral_health_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS oral_health_assessments_updated_at ON oral_health_assessments;
CREATE TRIGGER oral_health_assessments_updated_at
    BEFORE UPDATE ON oral_health_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_oral_health_assessments_updated_at();

-- RLS Policies
ALTER TABLE oral_health_assessments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own assessments
DROP POLICY IF EXISTS "Users can view oral health assessments" ON oral_health_assessments;
CREATE POLICY "Users can view oral health assessments" ON oral_health_assessments
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert assessments
DROP POLICY IF EXISTS "Users can insert oral health assessments" ON oral_health_assessments;
CREATE POLICY "Users can insert oral health assessments" ON oral_health_assessments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own assessments
DROP POLICY IF EXISTS "Users can update oral health assessments" ON oral_health_assessments;
CREATE POLICY "Users can update oral health assessments" ON oral_health_assessments
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own assessments
DROP POLICY IF EXISTS "Users can delete oral health assessments" ON oral_health_assessments;
CREATE POLICY "Users can delete oral health assessments" ON oral_health_assessments
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON oral_health_assessments TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;