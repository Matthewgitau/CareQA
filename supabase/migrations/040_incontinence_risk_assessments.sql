-- Create incontinence risk assessments table
CREATE TABLE IF NOT EXISTS incontinence_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
    assessment_date DATE NOT NULL,
    assessor_name VARCHAR(255) NOT NULL,
    bladder_continence_status VARCHAR(50) NOT NULL CHECK (bladder_continence_status IN ('continent', 'stress', 'urge', 'overflow', 'functional')),
    bowel_continence_status VARCHAR(50) NOT NULL CHECK (bowel_continence_status IN ('continent', 'constipation', 'diarrhoea', 'fecal_incontinence')),
    frequency VARCHAR(50) NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly')),
    triggers TEXT[], -- Array of triggers: coughing, sneezing, laughing, urgency, activity
    fluid_intake_ml INTEGER,
    caffeine_intake BOOLEAN NOT NULL DEFAULT false,
    alcohol_intake BOOLEAN NOT NULL DEFAULT false,
    medications TEXT, -- List of medications affecting continence
    mobility_affecting_access BOOLEAN NOT NULL DEFAULT false,
    cognitive_awareness BOOLEAN NOT NULL DEFAULT true,
    toilet_accessibility VARCHAR(50) NOT NULL CHECK (toilet_accessibility IN ('within_reach', 'requires_assistance')),
    incontinence_products TEXT[], -- Array of products: pads, sheaths, catheters, other
    skin_condition VARCHAR(50) NOT NULL CHECK (skin_condition IN ('intact', 'rash', 'broken')),
    previous_assessment_date DATE,
    referred_to_continence_service BOOLEAN NOT NULL DEFAULT false,
    bladder_diary_completed BOOLEAN NOT NULL DEFAULT false,
    bowel_diary_completed BOOLEAN NOT NULL DEFAULT false,
    action_plan TEXT,
    review_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_incontinence_assessments_service_user ON incontinence_risk_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_incontinence_assessments_date ON incontinence_risk_assessments(assessment_date);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_incontinence_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_incontinence_assessments_updated_at ON incontinence_risk_assessments;
CREATE TRIGGER update_incontinence_assessments_updated_at
    BEFORE UPDATE ON incontinence_risk_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_incontinence_assessments_updated_at();

-- Enable Row Level Security
ALTER TABLE incontinence_risk_assessments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own service user's incontinence assessments" ON incontinence_risk_assessments
    FOR SELECT
    USING (
        service_user_id IN (
            SELECT service_user_id 
            FROM carer_service_users 
            WHERE carer_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert incontinence assessments for their service users" ON incontinence_risk_assessments
    FOR INSERT
    WITH CHECK (
        service_user_id IN (
            SELECT service_user_id 
            FROM carer_service_users 
            WHERE carer_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own service user's incontinence assessments" ON incontinence_risk_assessments
    FOR UPDATE
    USING (
        service_user_id IN (
            SELECT service_user_id 
            FROM carer_service_users 
            WHERE carer_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own service user's incontinence assessments" ON incontinence_risk_assessments
    FOR DELETE
    USING (
        service_user_id IN (
            SELECT service_user_id 
            FROM carer_service_users 
            WHERE carer_id = auth.uid()
        )
    );