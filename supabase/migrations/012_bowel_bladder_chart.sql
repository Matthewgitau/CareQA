-- Create bowel_bladder_charts table
CREATE TABLE IF NOT EXISTS bowel_bladder_charts (
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
CREATE INDEX IF NOT EXISTS idx_bowel_bladder_charts_service_user_id ON bowel_bladder_charts(service_user_id);
CREATE INDEX IF NOT EXISTS idx_bowel_bladder_charts_assessment_date ON bowel_bladder_charts(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_bowel_bladder_charts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS bowel_bladder_charts_updated_at ON bowel_bladder_charts;
CREATE TRIGGER bowel_bladder_charts_updated_at
    BEFORE UPDATE ON bowel_bladder_charts
    FOR EACH ROW
    EXECUTE FUNCTION update_bowel_bladder_charts_updated_at();

-- RLS Policies
ALTER TABLE bowel_bladder_charts ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own charts
DROP POLICY IF EXISTS "Users can view bowel/bladder charts" ON bowel_bladder_charts;
CREATE POLICY "Users can view bowel/bladder charts" ON bowel_bladder_charts
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert charts
DROP POLICY IF EXISTS "Users can insert bowel/bladder charts" ON bowel_bladder_charts;
CREATE POLICY "Users can insert bowel/bladder charts" ON bowel_bladder_charts
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own charts
DROP POLICY IF EXISTS "Users can update bowel/bladder charts" ON bowel_bladder_charts;
CREATE POLICY "Users can update bowel/bladder charts" ON bowel_bladder_charts
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own charts
DROP POLICY IF EXISTS "Users can delete bowel/bladder charts" ON bowel_bladder_charts;
CREATE POLICY "Users can delete bowel/bladder charts" ON bowel_bladder_charts
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON bowel_bladder_charts TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;