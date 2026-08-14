-- Create staff appraisals table (separate from appraisal_forms which is for service users)
CREATE TABLE IF NOT EXISTS appraisals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
    appraisal_date DATE NOT NULL,
    previous_goals_achieved TEXT,
    areas_for_improvement TEXT,
    new_goals TEXT,
    overall_rating INTEGER CHECK (overall_rating >= 1 AND overall_rating <= 5),
    next_appraisal_date DATE NOT NULL,
    comments TEXT,
    status TEXT DEFAULT 'completed' CHECK (status IN ('draft', 'completed', 'signed_off')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_appraisals_employee_id ON appraisals(employee_id);
CREATE INDEX IF NOT EXISTS idx_appraisals_reviewer_id ON appraisals(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_appraisals_appraisal_date ON appraisals(appraisal_date);
CREATE INDEX IF NOT EXISTS idx_appraisals_next_appraisal_date ON appraisals(next_appraisal_date);
CREATE INDEX IF NOT EXISTS idx_appraisals_status ON appraisals(status);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_appraisals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS appraisals_updated_at ON appraisals;
CREATE TRIGGER appraisals_updated_at
    BEFORE UPDATE ON appraisals
    FOR EACH ROW
    EXECUTE FUNCTION update_appraisals_updated_at();

-- RLS
ALTER TABLE appraisals ENABLE ROW LEVEL SECURITY;

-- View: all authenticated users can view appraisals
DROP POLICY IF EXISTS "Users can view appraisals" ON appraisals;
CREATE POLICY "Users can view appraisals" ON appraisals
    FOR SELECT
    TO authenticated
    USING (true);

-- Insert: authenticated users can insert
DROP POLICY IF EXISTS "Users can insert appraisals" ON appraisals;
CREATE POLICY "Users can insert appraisals" ON appraisals
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Update: users can update if they are the reviewer or admin
DROP POLICY IF EXISTS "Users can update appraisals" ON appraisals;
CREATE POLICY "Users can update appraisals" ON appraisals
    FOR UPDATE
    TO authenticated
    USING (true);

-- Delete: only admins can delete
DROP POLICY IF EXISTS "Users can delete appraisals" ON appraisals;
CREATE POLICY "Users can delete appraisals" ON appraisals
    FOR DELETE
    TO authenticated
    USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Grant permissions
GRANT ALL ON appraisals TO authenticated;