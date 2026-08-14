-- Create nutrition risk assessments table
CREATE TABLE nutrition_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
    assessment_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    height_cm DECIMAL(5,2) NOT NULL CHECK (height_cm > 0 AND height_cm <= 250),
    current_weight_kg DECIMAL(5,2) NOT NULL CHECK (current_weight_kg > 0 AND current_weight_kg <= 300),
    weight_3_6_months_ago_kg DECIMAL(5,2) CHECK (weight_3_6_months_ago_kg > 0 AND weight_3_6_months_ago_kg <= 300),
    bmi DECIMAL(4,1) GENERATED ALWAYS AS (current_weight_kg / POWER(height_cm / 100, 2)) STORED,
    bmi_score INTEGER NOT NULL DEFAULT 0 CHECK (bmi_score IN (0, 1, 2)),
    weight_loss_percentage DECIMAL(4,1) GENERATED ALWAYS AS (
        CASE 
            WHEN weight_3_6_months_ago_kg IS NULL THEN NULL
            WHEN weight_3_6_months_ago_kg <= 0 THEN NULL
            ELSE ((weight_3_6_months_ago_kg - current_weight_kg) / weight_3_6_months_ago_kg) * 100
        END
    ) STORED,
    weight_loss_score INTEGER NOT NULL DEFAULT 0 CHECK (weight_loss_score IN (0, 1, 2)),
    acute_disease_effect_score INTEGER NOT NULL DEFAULT 0 CHECK (acute_disease_effect_score IN (0, 2)),
    must_total_score INTEGER NOT NULL DEFAULT 0 CHECK (must_total_score >= 0 AND must_total_score <= 6),
    risk_category TEXT NOT NULL DEFAULT 'low' CHECK (risk_category IN ('low', 'medium', 'high')),
    dietary_requirements TEXT,
    food_preferences_allergies TEXT,
    swallowing_difficulties BOOLEAN NOT NULL DEFAULT false,
    referred_to_dietitian BOOLEAN NOT NULL DEFAULT false,
    supplementation_required BOOLEAN NOT NULL DEFAULT false,
    action_plan TEXT,
    review_date DATE,
    next_weight_check_date DATE,
    assessor_name TEXT NOT NULL,
    assessor_signature TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_nutrition_risk_assessments_service_user_id ON nutrition_risk_assessments(service_user_id);
CREATE INDEX idx_nutrition_risk_assessments_assessment_date ON nutrition_risk_assessments(assessment_date);
CREATE INDEX idx_nutrition_risk_assessments_risk_category ON nutrition_risk_assessments(risk_category);
CREATE INDEX idx_nutrition_risk_assessments_must_score ON nutrition_risk_assessments(must_total_score);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_nutrition_risk_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_nutrition_risk_assessments_updated_at 
    BEFORE UPDATE ON nutrition_risk_assessments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_nutrition_risk_assessments_updated_at();

-- Create trigger to auto-calculate MUST scores
CREATE OR REPLACE FUNCTION calculate_must_scores()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate BMI score
    IF NEW.bmi IS NOT NULL THEN
        IF NEW.bmi > 20 THEN
            NEW.bmi_score = 0;
        ELSIF NEW.bmi >= 18.5 THEN
            NEW.bmi_score = 1;
        ELSE
            NEW.bmi_score = 2;
        END IF;
    END IF;
    
    -- Calculate weight loss score
    IF NEW.weight_loss_percentage IS NOT NULL THEN
        IF NEW.weight_loss_percentage < 5 THEN
            NEW.weight_loss_score = 0;
        ELSIF NEW.weight_loss_percentage <= 10 THEN
            NEW.weight_loss_score = 1;
        ELSE
            NEW.weight_loss_score = 2;
        END IF;
    END IF;
    
    -- Calculate total MUST score
    NEW.must_total_score = COALESCE(NEW.bmi_score, 0) + COALESCE(NEW.weight_loss_score, 0) + COALESCE(NEW.acute_disease_effect_score, 0);
    
    -- Determine risk category
    IF NEW.must_total_score = 0 THEN
        NEW.risk_category = 'low';
    ELSIF NEW.must_total_score = 1 THEN
        NEW.risk_category = 'medium';
    ELSE
        NEW.risk_category = 'high';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER calculate_must_scores 
    BEFORE INSERT OR UPDATE ON nutrition_risk_assessments 
    FOR EACH ROW 
    EXECUTE FUNCTION calculate_must_scores();

-- Add RLS policies
ALTER TABLE nutrition_risk_assessments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own service user's assessments
CREATE POLICY "Users can view nutrition risk assessments" ON nutrition_risk_assessments
    FOR SELECT USING (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = nutrition_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM service_users 
            WHERE service_users.id = nutrition_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = nutrition_risk_assessments.service_user_id
            )
        )
    );

-- Allow authenticated users to insert assessments for their service users
CREATE POLICY "Users can insert nutrition risk assessments" ON nutrition_risk_assessments
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = nutrition_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM service_users 
            WHERE service_users.id = nutrition_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = nutrition_risk_assessments.service_user_id
            )
        )
    );

-- Allow authenticated users to update their own assessments
CREATE POLICY "Users can update nutrition risk assessments" ON nutrition_risk_assessments
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = nutrition_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM service_users 
            WHERE service_users.id = nutrition_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = nutrition_risk_assessments.service_user_id
            )
        )
    );

-- Allow authenticated users to delete their own assessments
CREATE POLICY "Users can delete nutrition risk assessments" ON nutrition_risk_assessments
    FOR DELETE USING (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = nutrition_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM service_users 
            WHERE service_users.id = nutrition_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = nutrition_risk_assessments.service_user_id
            )
        )
    );

-- Grant permissions
GRANT ALL ON nutrition_risk_assessments TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;