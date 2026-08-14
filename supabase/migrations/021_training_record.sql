-- Create training_records table
CREATE TABLE IF NOT EXISTS training_records (
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
CREATE INDEX IF NOT EXISTS idx_training_records_service_user_id ON training_records(service_user_id);
CREATE INDEX IF NOT EXISTS idx_training_records_assessment_date ON training_records(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_training_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS training_records_updated_at ON training_records;
CREATE TRIGGER training_records_updated_at
    BEFORE UPDATE ON training_records
    FOR EACH ROW
    EXECUTE FUNCTION update_training_records_updated_at();

-- RLS Policies
ALTER TABLE training_records ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own records
DROP POLICY IF EXISTS "Users can view training records" ON training_records;
CREATE POLICY "Users can view training records" ON training_records
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert records
DROP POLICY IF EXISTS "Users can insert training records" ON training_records;
CREATE POLICY "Users can insert training records" ON training_records
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own records
DROP POLICY IF EXISTS "Users can update training records" ON training_records;
CREATE POLICY "Users can update training records" ON training_records
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own records
DROP POLICY IF EXISTS "Users can delete training records" ON training_records;
CREATE POLICY "Users can delete training records" ON training_records
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON training_records TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;