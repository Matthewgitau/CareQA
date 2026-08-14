-- Self-Harm/Suicide Risk Assessment Table
-- Based on CC157-Prevention and Management of Self-harm and Suicide guidelines

-- Create the main table
CREATE TABLE self_harm_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID NOT NULL REFERENCES service_users(id) ON DELETE CASCADE,
    assessor_id UUID REFERENCES carers(id),
    
    -- Current suicidal ideation (critical field)
    current_suicidal_ideation VARCHAR(20) NOT NULL CHECK (current_suicidal_ideation IN ('never', 'sometimes', 'frequently', 'constant')),
    current_suicidal_ideation_details TEXT,
    
    -- Previous self-harm attempts
    previous_self_harm_attempts INTEGER DEFAULT 0,
    previous_self_harm_details TEXT,
    
    -- Method of self-harm
    self_harm_method VARCHAR(50),
    self_harm_method_other TEXT,
    method_planned BOOLEAN DEFAULT false,
    
    -- Frequency of thoughts
    frequency_of_thoughts VARCHAR(20) CHECK (frequency_of_thoughts IN ('never', 'rarely', 'sometimes', 'often', 'constant')),
    
    -- Triggers
    relationship_triggers BOOLEAN DEFAULT false,
    financial_triggers BOOLEAN DEFAULT false,
    health_triggers BOOLEAN DEFAULT false,
    other_triggers BOOLEAN DEFAULT false,
    trigger_details TEXT,
    
    -- Protective factors
    family_support BOOLEAN DEFAULT false,
    friend_support BOOLEAN DEFAULT false,
    routine_structure BOOLEAN DEFAULT false,
    other_protective_factors BOOLEAN DEFAULT false,
    protective_factors_details TEXT,
    
    -- Risk factors
    access_to_means BOOLEAN DEFAULT false,
    access_to_means_details TEXT,
    mental_health_diagnosis VARCHAR(100),
    current_treatment VARCHAR(20) CHECK (current_treatment IN ('none', 'medication', 'therapy', 'both')),
    treatment_details TEXT,
    
    -- Recent life events
    recent_life_events TEXT,
    substance_use VARCHAR(20) CHECK (substance_use IN ('none', 'occasional', 'regular', 'problematic')),
    substance_details TEXT,
    
    -- Behavioral indicators
    sleep_disturbances BOOLEAN DEFAULT false,
    withdrawal_from_activities BOOLEAN DEFAULT false,
    giving_away_possessions BOOLEAN DEFAULT false,
    making_plans_arrangements BOOLEAN DEFAULT false,
    
    -- Risk assessment
    overall_risk_level VARCHAR(10) CHECK (overall_risk_level IN ('low', 'medium', 'high', 'immediate')),
    risk_factors_identified TEXT[],
    protective_factors_identified TEXT[],
    
    -- Action plan
    immediate_actions_required BOOLEAN DEFAULT false,
    immediate_actions TEXT,
    follow_up_actions TEXT,
    crisis_contacts TEXT,
    next_review_date DATE,
    
    -- Status and compliance
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'reviewed', 'escalated')),
    signature TEXT,
    reviewed_by UUID REFERENCES carers(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_self_harm_assessments_service_user ON self_harm_risk_assessments(service_user_id);
CREATE INDEX idx_self_harm_assessments_assessor ON self_harm_risk_assessments(assessor_id);
CREATE INDEX idx_self_harm_assessments_ideation ON self_harm_risk_assessments(current_suicidal_ideation);
CREATE INDEX idx_self_harm_assessments_risk_level ON self_harm_risk_assessments(overall_risk_level);
CREATE INDEX idx_self_harm_assessments_status ON self_harm_risk_assessments(status);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_self_harm_assessment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_self_harm_assessment_updated_at  
    BEFORE UPDATE ON self_harm_risk_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_self_harm_assessment_updated_at();

-- Create RLS policies
ALTER TABLE self_harm_risk_assessments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own assessments and those in their care home
CREATE POLICY "Users can view own and care home assessments" ON self_harm_risk_assessments
    FOR SELECT
    USING (
        service_user_id IN (
            SELECT service_user_id FROM service_user_carer_links WHERE carer_id = auth.uid()
        )
        OR assessor_id = auth.uid()
        OR auth.uid() IN (
            SELECT carer_id FROM care_home_carers 
            WHERE care_home_id IN (
                SELECT care_home_id FROM service_users WHERE id = service_user_id
            )
        )
    );

-- Allow carers to insert assessments for their service users
CREATE POLICY "Carers can insert assessments" ON self_harm_risk_assessments
    FOR INSERT
    WITH CHECK (
        service_user_id IN (
            SELECT service_user_id FROM service_user_carer_links WHERE carer_id = auth.uid()
        )
        OR auth.uid() IN (
            SELECT carer_id FROM care_home_carers 
            WHERE care_home_id IN (
                SELECT care_home_id FROM service_users WHERE id = service_user_id
            )
        )
    );

-- Allow carers to update their own assessments
CREATE POLICY "Carers can update own assessments" ON self_harm_risk_assessments
    FOR UPDATE
    USING (
        assessor_id = auth.uid()
        OR auth.uid() IN (
            SELECT carer_id FROM care_home_carers 
            WHERE care_home_id IN (
                SELECT care_home_id FROM service_users WHERE id = service_user_id
            )
        )
    );

-- Allow carers to delete their own assessments
CREATE POLICY "Carers can delete own assessments" ON self_harm_risk_assessments
    FOR DELETE
    USING (
        assessor_id = auth.uid()
        OR auth.uid() IN (
            SELECT carer_id FROM care_home_carers 
            WHERE care_home_id IN (
                SELECT care_home_id FROM service_users WHERE id = service_user_id
            )
        )
    );

-- Create function to get assessments by care home
CREATE OR REPLACE FUNCTION get_self_harm_assessments_by_carehome(p_carehome_id UUID)
RETURNS SETOF self_harm_risk_assessments AS $$
BEGIN
    RETURN QUERY
    SELECT sha.*
    FROM self_harm_risk_assessments sha
    JOIN service_users su ON sha.service_user_id = su.id
    WHERE su.care_home_id = p_carehome_id
    ORDER BY sha.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to flag high-risk assessments
CREATE OR REPLACE FUNCTION flag_high_risk_self_harm_assessments()
RETURNS TABLE (
    assessment_id UUID,
    service_user_name TEXT,
    current_ideation VARCHAR,
    method_planned BOOLEAN,
    giving_away_possessions BOOLEAN,
    risk_level VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sha.id,
        CONCAT(su.first_name, ' ', su.last_name) as service_user_name,
        sha.current_suicidal_ideation,
        sha.method_planned,
        sha.giving_away_possessions,
        sha.overall_risk_level
    FROM self_harm_risk_assessments sha
    JOIN service_users su ON sha.service_user_id = su.id
    WHERE sha.current_suicidal_ideation = 'constant'
       OR sha.method_planned = true
       OR sha.giving_away_possessions = true
    ORDER BY sha.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get assessment summary
CREATE OR REPLACE FUNCTION get_self_harm_assessment_summary(p_service_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_assessments', COUNT(*),
        'latest_assessment', (
            SELECT json_build_object(
                'id', id,
                'current_ideation', current_suicidal_ideation,
                'overall_risk_level', overall_risk_level,
                'created_at', created_at,
                'status', status
            ) FROM self_harm_risk_assessments 
            WHERE service_user_id = p_service_user_id 
            ORDER BY created_at DESC 
            LIMIT 1
        ),
        'high_risk_count', COUNT(*) FILTER (WHERE overall_risk_level IN ('high', 'immediate')),
        'escalated_count', COUNT(*) FILTER (WHERE status = 'escalated'),
        'average_ideation_frequency', AVG(
            CASE current_suicidal_ideation
                WHEN 'never' THEN 0
                WHEN 'sometimes' THEN 1
                WHEN 'frequently' THEN 2
                WHEN 'constant' THEN 3
                ELSE 0
            END
        )
    ) INTO result
    FROM self_harm_risk_assessments 
    WHERE service_user_id = p_service_user_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to validate assessment completeness
CREATE OR REPLACE FUNCTION validate_self_harm_assessment_completeness(p_assessment_id UUID)
RETURNS JSON AS $$
DECLARE
    assessment_record self_harm_risk_assessments;
    is_complete BOOLEAN;
    missing_fields TEXT[] := '{}';
BEGIN
    SELECT * INTO assessment_record FROM self_harm_risk_assessments WHERE id = p_assessment_id;
    
    -- Check required fields
    is_complete := true;
    
    IF assessment_record.current_suicidal_ideation IS NULL THEN
        is_complete := false;
        missing_fields := array_append(missing_fields, 'current_suicidal_ideation');
    END IF;
    
    IF assessment_record.frequency_of_thoughts IS NULL THEN
        is_complete := false;
        missing_fields := array_append(missing_fields, 'frequency_of_thoughts');
    END IF;
    
    IF assessment_record.overall_risk_level IS NULL THEN
        is_complete := false;
        missing_fields := array_append(missing_fields, 'overall_risk_level');
    END IF;
    
    IF assessment_record.next_review_date IS NULL THEN
        is_complete := false;
        missing_fields := array_append(missing_fields, 'next_review_date');
    END IF;
    
    RETURN json_build_object(
        'assessment_id', p_assessment_id,
        'is_complete', is_complete,
        'missing_fields', missing_fields,
        'completion_percentage', 
            CASE 
                WHEN is_complete THEN 100
                ELSE ROUND(
                    (1.0 - (array_length(missing_fields, 1)::NUMERIC / 5.0)) * 100, 
                    1
                )
            END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to calculate risk level
CREATE OR REPLACE FUNCTION calculate_self_harm_risk_level(
    p_current_ideation VARCHAR,
    p_method_planned BOOLEAN,
    p_giving_away_possessions BOOLEAN,
    p_previous_attempts INTEGER,
    p_access_to_means BOOLEAN
)
RETURNS VARCHAR AS $$
DECLARE
    risk_score INTEGER := 0;
    risk_level VARCHAR := 'low';
BEGIN
    -- Base risk scoring
    CASE p_current_ideation
        WHEN 'constant' THEN risk_score := risk_score + 4;
        WHEN 'frequently' THEN risk_score := risk_score + 3;
        WHEN 'sometimes' THEN risk_score := risk_score + 2;
        WHEN 'never' THEN risk_score := risk_score + 0;
    END CASE;
    
    -- Additional risk factors
    IF p_method_planned THEN risk_score := risk_score + 3; END IF;
    IF p_giving_away_possessions THEN risk_score := risk_score + 3; END IF;
    IF p_previous_attempts > 0 THEN risk_score := risk_score + p_previous_attempts; END IF;
    IF p_access_to_means THEN risk_score := risk_score + 2; END IF;
    
    -- Determine risk level
    IF p_current_ideation = 'constant' THEN
        risk_level := 'immediate';
    ELSIF risk_score >= 8 THEN
        risk_level := 'high';
    ELSIF risk_score >= 4 THEN
        risk_level := 'medium';
    ELSE
        risk_level := 'low';
    END IF;
    
    RETURN risk_level;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to submit assessment with digital signature
CREATE OR REPLACE FUNCTION submit_self_harm_assessment(
    p_assessment_id UUID,
    p_signature_data TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE self_harm_risk_assessments 
    SET 
        status = 'completed',
        signature = p_signature_data,
        updated_at = NOW()
    WHERE id = p_assessment_id;
    
    -- Check for immediate escalation
    IF EXISTS (
        SELECT 1 FROM self_harm_risk_assessments 
        WHERE id = p_assessment_id 
        AND (
            current_suicidal_ideation = 'constant'
            OR method_planned = true
            OR giving_away_possessions = true
        )
    ) THEN
        UPDATE self_harm_risk_assessments 
        SET status = 'escalated' 
        WHERE id = p_assessment_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create view for care home assessments
CREATE VIEW self_harm_assessments_by_carehome_view AS
SELECT 
    sha.*,
    CONCAT(su.first_name, ' ', su.last_name) as service_user_name,
    su.care_home_id,
    ch.name as care_home_name,
    CONCAT(c.first_name, ' ', c.last_name) as assessor_name
FROM self_harm_risk_assessments sha
JOIN service_users su ON sha.service_user_id = su.id
JOIN care_homes ch ON su.care_home_id = ch.id
LEFT JOIN carers c ON sha.assessor_id = c.id;

-- Grant permissions
GRANT ALL ON self_harm_risk_assessments TO authenticated;
GRANT EXECUTE ON FUNCTION get_self_harm_assessments_by_carehome(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION flag_high_risk_self_harm_assessments() TO authenticated;
GRANT EXECUTE ON FUNCTION get_self_harm_assessment_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_self_harm_assessment_completeness(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_self_harm_risk_level(VARCHAR, BOOLEAN, BOOLEAN, INTEGER, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION submit_self_harm_assessment(UUID, TEXT) TO authenticated;
GRANT SELECT ON self_harm_assessments_by_carehome_view TO authenticated;