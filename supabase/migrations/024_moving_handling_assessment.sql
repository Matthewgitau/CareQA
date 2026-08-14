-- Create moving_handling_assessments table
CREATE TABLE IF NOT EXISTS moving_handling_assessments (
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
CREATE INDEX IF NOT EXISTS idx_moving_handling_assessments_service_user_id ON moving_handling_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_moving_handling_assessments_assessment_date ON moving_handling_assessments(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_moving_handling_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS moving_handling_assessments_updated_at ON moving_handling_assessments;
CREATE TRIGGER moving_handling_assessments_updated_at
    BEFORE UPDATE ON moving_handling_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_moving_handling_assessments_updated_at();

-- RLS Policies
ALTER TABLE moving_handling_assessments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own assessments
DROP POLICY IF EXISTS "Users can view moving handling assessments" ON moving_handling_assessments;
CREATE POLICY "Users can view moving handling assessments" ON moving_handling_assessments
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert assessments
DROP POLICY IF EXISTS "Users can insert moving handling assessments" ON moving_handling_assessments;
CREATE POLICY "Users can insert moving handling assessments" ON moving_handling_assessments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own assessments
DROP POLICY IF EXISTS "Users can update moving handling assessments" ON moving_handling_assessments;
CREATE POLICY "Users can update moving handling assessments" ON moving_handling_assessments
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own assessments
DROP POLICY IF EXISTS "Users can delete moving handling assessments" ON moving_handling_assessments;
CREATE POLICY "Users can delete moving handling assessments" ON moving_handling_assessments
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON moving_handling_assessments TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;