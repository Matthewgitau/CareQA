-- Create challenging behaviour risk assessments table
CREATE TABLE challenging_behaviour_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
    assessment_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    behaviour_type TEXT NOT NULL CHECK (behaviour_type IN ('aggression', 'self_harm', 'wandering', 'sexual', 'inappropriate', 'vocal', 'withdrawal')),
    behaviour_frequency TEXT NOT NULL CHECK (behaviour_frequency IN ('hourly', 'daily', 'weekly', 'monthly')),
    behaviour_duration_minutes INTEGER CHECK (behaviour_duration_minutes >= 0 AND behaviour_duration_minutes <= 1440),
    intensity TEXT NOT NULL CHECK (intensity IN ('mild', 'moderate', 'severe')),
    triggers TEXT[] CHECK (array_length(triggers, 1) <= 5),
    warning_signs TEXT[] CHECK (array_length(warning_signs, 1) <= 10),
    de_escalation_strategies TEXT[] CHECK (array_length(de_escalation_strategies, 1) <= 10),
    medication_used TEXT CHECK (medication_used IN ('none', 'prn', 'regular')),
    injuries_caused TEXT NOT NULL DEFAULT 'none' CHECK (injuries_caused IN ('none', 'minor', 'moderate', 'severe')),
    injuries_to_self BOOLEAN NOT NULL DEFAULT false,
    injuries_to_others BOOLEAN NOT NULL DEFAULT false,
    property_damage BOOLEAN NOT NULL DEFAULT false,
    staff_trained_de_escalation BOOLEAN NOT NULL DEFAULT false,
    pbs_plan_in_place BOOLEAN NOT NULL DEFAULT false,
    environmental_modifications_needed TEXT,
    support_needs TEXT CHECK (support_needs IN ('none', '1:1', '2:1', 'specialist')),
    risk_level TEXT NOT NULL DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    action_plan TEXT,
    review_date DATE,
    next_behaviour_monitoring_date DATE,
    assessor_name TEXT NOT NULL,
    assessor_signature TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_challenging_behaviour_assessments_service_user_id ON challenging_behaviour_risk_assessments(service_user_id);
CREATE INDEX idx_challenging_behaviour_assessments_assessment_date ON challenging_behaviour_risk_assessments(assessment_date);
CREATE INDEX idx_challenging_behaviour_assessments_behaviour_type ON challenging_behaviour_risk_assessments(behaviour_type);
CREATE INDEX idx_challenging_behaviour_assessments_risk_level ON challenging_behaviour_risk_assessments(risk_level);
CREATE INDEX idx_challenging_behaviour_assessments_intensity ON challenging_behaviour_risk_assessments(intensity);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_challenging_behaviour_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_challenging_behaviour_assessments_updated_at 
    BEFORE UPDATE ON challenging_behaviour_risk_assessments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_challenging_behaviour_assessments_updated_at();

-- Create trigger to auto-calculate risk level based on critical rules
CREATE OR REPLACE FUNCTION calculate_challenging_behaviour_risk_level()
RETURNS TRIGGER AS $$
BEGIN
    -- Critical rules check
    IF NEW.injuries_to_others = true AND NEW.intensity = 'severe' THEN
        NEW.risk_level = 'critical';
    ELSIF NEW.injuries_to_self = true AND NEW.behaviour_frequency IN ('hourly', 'daily') THEN
        NEW.risk_level = 'high';
    ELSIF NEW.property_damage = true AND NEW.behaviour_type = 'aggression' THEN
        NEW.risk_level = 'high';
    -- Standard risk calculation based on multiple factors
    ELSE
        -- Count high-risk factors
        DECLARE high_risk_factors INTEGER := 0;
        BEGIN
            IF NEW.intensity = 'severe' THEN high_risk_factors := high_risk_factors + 2; END IF;
            IF NEW.intensity = 'moderate' THEN high_risk_factors := high_risk_factors + 1; END IF;
            IF NEW.behaviour_frequency IN ('hourly', 'daily') THEN high_risk_factors := high_risk_factors + 1; END IF;
            IF NEW.injuries_to_others = true THEN high_risk_factors := high_risk_factors + 2; END IF;
            IF NEW.injuries_to_self = true THEN high_risk_factors := high_risk_factors + 1; END IF;
            IF NEW.property_damage = true THEN high_risk_factors := high_risk_factors + 1; END IF;
            
            -- Determine risk level
            IF high_risk_factors >= 4 THEN
                NEW.risk_level = 'high';
            ELSIF high_risk_factors >= 2 THEN
                NEW.risk_level = 'medium';
            ELSE
                NEW.risk_level = 'low';
            END IF;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER calculate_challenging_behaviour_risk_level 
    BEFORE INSERT OR UPDATE ON challenging_behaviour_risk_assessments 
    FOR EACH ROW 
    EXECUTE FUNCTION calculate_challenging_behaviour_risk_level();

-- Add RLS policies
ALTER TABLE challenging_behaviour_risk_assessments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own service user's assessments
CREATE POLICY "Users can view challenging behaviour assessments" ON challenging_behaviour_risk_assessments
    FOR SELECT USING (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = challenging_behaviour_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM service_users 
            WHERE service_users.id = challenging_behaviour_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = challenging_behaviour_risk_assessments.service_user_id
            )
        )
    );

-- Allow authenticated users to insert assessments for their service users
CREATE POLICY "Users can insert challenging behaviour assessments" ON challenging_behaviour_risk_assessments
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = challenging_behaviour_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM service_users 
            WHERE service_users.id = challenging_behaviour_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = challenging_behaviour_risk_assessments.service_user_id
            )
        )
    );

-- Allow authenticated users to update their own assessments
CREATE POLICY "Users can update challenging behaviour assessments" ON challenging_behaviour_risk_assessments
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = challenging_behaviour_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM service_users 
            WHERE service_users.id = challenging_behaviour_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = challenging_behaviour_risk_assessments.service_user_id
            )
        )
    );

-- Allow authenticated users to delete their own assessments
CREATE POLICY "Users can delete challenging behaviour assessments" ON challenging_behaviour_risk_assessments
    FOR DELETE USING (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = challenging_behaviour_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM service_users 
            WHERE service_users.id = challenging_behaviour_risk_assessments.service_user_id
        )
        OR auth.uid() IN (
            SELECT created_by FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = challenging_behaviour_risk_assessments.service_user_id
            )
        )
    );

-- Grant permissions
GRANT ALL ON challenging_behaviour_risk_assessments TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;