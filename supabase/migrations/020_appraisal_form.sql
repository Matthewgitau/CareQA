-- Create appraisal_forms table
CREATE TABLE IF NOT EXISTS appraisal_forms (
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
CREATE INDEX IF NOT EXISTS idx_appraisal_forms_service_user_id ON appraisal_forms(service_user_id);
CREATE INDEX IF NOT EXISTS idx_appraisal_forms_assessment_date ON appraisal_forms(assessment_date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_appraisal_forms_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only create if it doesn't exist)
DROP TRIGGER IF EXISTS appraisal_forms_updated_at ON appraisal_forms;
CREATE TRIGGER appraisal_forms_updated_at
    BEFORE UPDATE ON appraisal_forms
    FOR EACH ROW
    EXECUTE FUNCTION update_appraisal_forms_updated_at();

-- RLS Policies
ALTER TABLE appraisal_forms ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own forms
DROP POLICY IF EXISTS "Users can view appraisal forms" ON appraisal_forms;
CREATE POLICY "Users can view appraisal forms" ON appraisal_forms
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert forms
DROP POLICY IF EXISTS "Users can insert appraisal forms" ON appraisal_forms;
CREATE POLICY "Users can insert appraisal forms" ON appraisal_forms
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own forms
DROP POLICY IF EXISTS "Users can update appraisal forms" ON appraisal_forms;
CREATE POLICY "Users can update appraisal forms" ON appraisal_forms
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own forms
DROP POLICY IF EXISTS "Users can delete appraisal forms" ON appraisal_forms;
CREATE POLICY "Users can delete appraisal forms" ON appraisal_forms
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON appraisal_forms TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;