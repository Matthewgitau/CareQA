-- Phase 10: Add missing columns to staff_competency_assessments
-- Required for competency assessment forms

ALTER TABLE staff_competency_assessments ADD COLUMN IF NOT EXISTS action_plan TEXT;
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