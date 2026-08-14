-- Create supervision_records table
CREATE TABLE IF NOT EXISTS supervision_records (
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
CREATE INDEX IF NOT EXISTS idx_supervision_records_service_user_id ON supervision_records(service_user_id);
CREATE INDEX IF NOT EXISTS idx_supervision_records_assessment_date ON supervision_records(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_supervision_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS supervision_records_updated_at ON supervision_records;
CREATE TRIGGER supervision_records_updated_at
    BEFORE UPDATE ON supervision_records
    FOR EACH ROW
    EXECUTE FUNCTION update_supervision_records_updated_at();

-- RLS Policies
ALTER TABLE supervision_records ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own records
DROP POLICY IF EXISTS "Users can view supervision records" ON supervision_records;
CREATE POLICY "Users can view supervision records" ON supervision_records
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert records
DROP POLICY IF EXISTS "Users can insert supervision records" ON supervision_records;
CREATE POLICY "Users can insert supervision records" ON supervision_records
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own records
DROP POLICY IF EXISTS "Users can update supervision records" ON supervision_records;
CREATE POLICY "Users can update supervision records" ON supervision_records
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own records
DROP POLICY IF EXISTS "Users can delete supervision records" ON supervision_records;
CREATE POLICY "Users can delete supervision records" ON supervision_records
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON supervision_records TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;