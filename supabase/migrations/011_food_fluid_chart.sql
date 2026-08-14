-- Create food_fluid_charts table
CREATE TABLE IF NOT EXISTS food_fluid_charts (
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
CREATE INDEX IF NOT EXISTS idx_food_fluid_charts_service_user_id ON food_fluid_charts(service_user_id);
CREATE INDEX IF NOT EXISTS idx_food_fluid_charts_assessment_date ON food_fluid_charts(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_food_fluid_charts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS food_fluid_charts_updated_at ON food_fluid_charts;
CREATE TRIGGER food_fluid_charts_updated_at
    BEFORE UPDATE ON food_fluid_charts
    FOR EACH ROW
    EXECUTE FUNCTION update_food_fluid_charts_updated_at();

-- RLS Policies
ALTER TABLE food_fluid_charts ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own charts
DROP POLICY IF EXISTS "Users can view food/fluid charts" ON food_fluid_charts;
CREATE POLICY "Users can view food/fluid charts" ON food_fluid_charts
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert charts
DROP POLICY IF EXISTS "Users can insert food/fluid charts" ON food_fluid_charts;
CREATE POLICY "Users can insert food/fluid charts" ON food_fluid_charts
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own charts
DROP POLICY IF EXISTS "Users can update food/fluid charts" ON food_fluid_charts;
CREATE POLICY "Users can update food/fluid charts" ON food_fluid_charts
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own charts
DROP POLICY IF EXISTS "Users can delete food/fluid charts" ON food_fluid_charts;
CREATE POLICY "Users can delete food/fluid charts" ON food_fluid_charts
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON food_fluid_charts TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;