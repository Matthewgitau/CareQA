-- Create infection_control_audits table
CREATE TABLE IF NOT EXISTS infection_control_audits (
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
CREATE INDEX IF NOT EXISTS idx_infection_control_audits_service_user_id ON infection_control_audits(service_user_id);
CREATE INDEX IF NOT EXISTS idx_infection_control_audits_assessment_date ON infection_control_audits(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_infection_control_audits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS infection_control_audits_updated_at ON infection_control_audits;
CREATE TRIGGER infection_control_audits_updated_at
    BEFORE UPDATE ON infection_control_audits
    FOR EACH ROW
    EXECUTE FUNCTION update_infection_control_audits_updated_at();

-- RLS Policies
ALTER TABLE infection_control_audits ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own audits
DROP POLICY IF EXISTS "Users can view infection control audits" ON infection_control_audits;
CREATE POLICY "Users can view infection control audits" ON infection_control_audits
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert audits
DROP POLICY IF EXISTS "Users can insert infection control audits" ON infection_control_audits;
CREATE POLICY "Users can insert infection control audits" ON infection_control_audits
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own audits
DROP POLICY IF EXISTS "Users can update infection control audits" ON infection_control_audits;
CREATE POLICY "Users can update infection control audits" ON infection_control_audits
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own audits
DROP POLICY IF EXISTS "Users can delete infection control audits" ON infection_control_audits;
CREATE POLICY "Users can delete infection control audits" ON infection_control_audits
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON infection_control_audits TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;