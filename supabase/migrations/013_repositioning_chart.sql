-- Create repositioning_charts table
CREATE TABLE IF NOT EXISTS repositioning_charts (
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
CREATE INDEX IF NOT EXISTS idx_repositioning_charts_service_user_id ON repositioning_charts(service_user_id);
CREATE INDEX IF NOT EXISTS idx_repositioning_charts_assessment_date ON repositioning_charts(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_repositioning_charts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS repositioning_charts_updated_at ON repositioning_charts;
CREATE TRIGGER repositioning_charts_updated_at
    BEFORE UPDATE ON repositioning_charts
    FOR EACH ROW
    EXECUTE FUNCTION update_repositioning_charts_updated_at();

-- RLS Policies
ALTER TABLE repositioning_charts ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own charts
DROP POLICY IF EXISTS "Users can view repositioning charts" ON repositioning_charts;
CREATE POLICY "Users can view repositioning charts" ON repositioning_charts
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert charts
DROP POLICY IF EXISTS "Users can insert repositioning charts" ON repositioning_charts;
CREATE POLICY "Users can insert repositioning charts" ON repositioning_charts
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own charts
DROP POLICY IF EXISTS "Users can update repositioning charts" ON repositioning_charts;
CREATE POLICY "Users can update repositioning charts" ON repositioning_charts
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own charts
DROP POLICY IF EXISTS "Users can delete repositioning charts" ON repositioning_charts;
CREATE POLICY "Users can delete repositioning charts" ON repositioning_charts
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON repositioning_charts TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;