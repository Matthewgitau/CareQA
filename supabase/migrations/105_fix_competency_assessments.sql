-- ============================================
-- Fix: Ensure all required columns exist on staff_competency_assessments
-- ============================================

-- Ensure action_plan column exists (fixes PGRST204 error)
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS action_plan TEXT;

-- Ensure all other columns from 103_add_missing_columns exist
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS development_areas TEXT[];
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS next_review_date DATE;
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS overall_rating TEXT;
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS passed BOOLEAN DEFAULT FALSE;
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS assessment_type TEXT;
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS assessor_name TEXT;
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS staff_name TEXT;
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS organisation_id UUID REFERENCES organisations(id);
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS competency_ratings JSONB DEFAULT '[]'::jsonb;
ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS staff_sign_off_date DATE;

-- Refresh the schema cache to ensure PostgREST picks up the new columns
NOTIFY pgrst, 'reload schema';