-- Create sepsis_risk_assessments table
CREATE TABLE IF NOT EXISTS sepsis_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
    assessor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    -- Assessment timing
    assessment_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    assessment_time TIME NOT NULL,
    
    -- NEWS2 vital signs
    temperature NUMERIC(4,1) NOT NULL, -- °C
    heart_rate INTEGER NOT NULL, -- bpm
    respiratory_rate INTEGER NOT NULL, -- breaths/min
    oxygen_saturation NUMERIC(4,1) NOT NULL, -- %
    systolic_bp INTEGER NOT NULL, -- mmHg
    consciousness_level VARCHAR(20) NOT NULL, -- alert/voice/pain/unresponsive
    
    -- NEWS2 score calculation
    news2_score INTEGER NOT NULL DEFAULT 0,
    
    -- Sepsis indicators
    new_confusion BOOLEAN NOT NULL DEFAULT FALSE,
    signs_of_infection VARCHAR(50)[] NOT NULL DEFAULT '{}', -- fever/shivering/cold
    infection_source VARCHAR(200),
    patient_unwell BOOLEAN NOT NULL DEFAULT FALSE,
    family_concerned BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Risk assessment
    sepsis_risk_level VARCHAR(20) NOT NULL DEFAULT 'low', -- low/medium/high/critical
    action_taken VARCHAR(50) NOT NULL DEFAULT 'monitor', -- monitor/escalate/999
    
    -- Sepsis Six protocol
    sepsis_six_completed BOOLEAN[] NOT NULL DEFAULT '{}', -- oxygen/fluids/bloods/antibiotics/urine/output
    sepsis_six_details JSONB,
    
    -- Escalation and outcomes
    referral_to_hospital BOOLEAN DEFAULT FALSE,
    referral_time TIMESTAMP WITH TIME ZONE,
    hospital_outcome VARCHAR(100),
    assessor_signature VARCHAR(100),
    
    -- Monitoring
    review_time TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_consciousness_level CHECK (consciousness_level IN ('alert', 'voice', 'pain', 'unresponsive')),
    CONSTRAINT valid_sepsis_risk_level CHECK (sepsis_risk_level IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT valid_action_taken CHECK (action_taken IN ('monitor', 'escalate', '999')),
    CONSTRAINT valid_temperature CHECK (temperature >= 34.0 AND temperature <= 42.0),
    CONSTRAINT valid_heart_rate CHECK (heart_rate >= 20 AND heart_rate <= 220),
    CONSTRAINT valid_respiratory_rate CHECK (respiratory_rate >= 4 AND respiratory_rate <= 50),
    CONSTRAINT valid_oxygen_saturation CHECK (oxygen_saturation >= 70.0 AND oxygen_saturation <= 100.0),
    CONSTRAINT valid_systolic_bp CHECK (systolic_bp >= 50 AND systolic_bp <= 250),
    CONSTRAINT valid_news2_score CHECK (news2_score >= 0 AND news2_score <= 20)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_sepsis_assessments_service_user ON sepsis_risk_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_sepsis_assessments_assessor ON sepsis_risk_assessments(assessor_id);
CREATE INDEX IF NOT EXISTS idx_sepsis_assessments_date ON sepsis_risk_assessments(assessment_date);
CREATE INDEX IF NOT EXISTS idx_sepsis_assessments_risk_level ON sepsis_risk_assessments(sepsis_risk_level);
CREATE INDEX IF NOT EXISTS idx_sepsis_assessments_news2_score ON sepsis_risk_assessments(news2_score);

-- Create function to calculate NEWS2 score
CREATE OR REPLACE FUNCTION calculate_news2_score(
    p_temperature NUMERIC,
    p_heart_rate INTEGER,
    p_respiratory_rate INTEGER,
    p_oxygen_saturation NUMERIC,
    p_systolic_bp INTEGER,
    p_consciousness VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    news2_total INTEGER := 0;
    temp_score INTEGER := 0;
    hr_score INTEGER := 0;
    rr_score INTEGER := 0;
    os_score INTEGER := 0;
    bp_score INTEGER := 0;
    cs_score INTEGER := 0;
BEGIN
    -- Temperature score
    IF p_temperature >= 36.1 AND p_temperature <= 38.0 THEN
        temp_score := 0;
    ELSIF p_temperature >= 38.1 AND p_temperature <= 39.0 THEN
        temp_score := 1;
    ELSIF p_temperature > 39.0 OR p_temperature < 36.1 THEN
        temp_score := 2;
    END IF;
    
    -- Heart rate score
    IF p_heart_rate >= 51 AND p_heart_rate <= 90 THEN
        hr_score := 0;
    ELSIF (p_heart_rate >= 41 AND p_heart_rate <= 50) OR (p_heart_rate >= 91 AND p_heart_rate <= 110) THEN
        hr_score := 1;
    ELSIF (p_heart_rate >= 111 AND p_heart_rate <= 130) OR p_heart_rate <= 40 THEN
        hr_score := 2;
    ELSIF p_heart_rate > 130 THEN
        hr_score := 3;
    END IF;
    
    -- Respiratory rate score
    IF p_respiratory_rate >= 12 AND p_respiratory_rate <= 20 THEN
        rr_score := 0;
    ELSIF (p_respiratory_rate >= 21 AND p_respiratory_rate <= 24) OR p_respiratory_rate <= 11 THEN
        rr_score := 1;
    ELSIF p_respiratory_rate >= 25 THEN
        rr_score := 2;
    END IF;
    
    -- Oxygen saturation score
    IF p_oxygen_saturation >= 96 THEN
        os_score := 0;
    ELSIF p_oxygen_saturation >= 94 AND p_oxygen_saturation <= 95 THEN
        os_score := 1;
    ELSIF p_oxygen_saturation >= 92 AND p_oxygen_saturation <= 93 THEN
        os_score := 2;
    ELSIF p_oxygen_saturation < 92 THEN
        os_score := 3;
    END IF;
    
    -- Systolic BP score
    IF p_systolic_bp >= 111 AND p_systolic_bp <= 219 THEN
        bp_score := 0;
    ELSIF (p_systolic_bp >= 101 AND p_systolic_bp <= 110) OR (p_systolic_bp >= 220 AND p_systolic_bp <= 239) THEN
        bp_score := 1;
    ELSIF (p_systolic_bp >= 91 AND p_systolic_bp <= 100) OR (p_systolic_bp >= 240 AND p_systolic_bp <= 250) THEN
        bp_score := 2;
    ELSIF p_systolic_bp <= 90 OR p_systolic_bp > 250 THEN
        bp_score := 3;
    END IF;
    
    -- Consciousness score
    IF p_consciousness = 'alert' THEN
        cs_score := 0;
    ELSE
        cs_score := 3;
    END IF;
    
    news2_total := temp_score + hr_score + rr_score + os_score + bp_score + cs_score;
    
    RETURN news2_total;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to determine sepsis risk level
CREATE OR REPLACE FUNCTION determine_sepsis_risk_level(
    p_news2_score INTEGER,
    p_new_confusion BOOLEAN,
    p_signs_of_infection VARCHAR[],
    p_patient_unwell BOOLEAN
) RETURNS VARCHAR AS $$
DECLARE
    risk_level VARCHAR := 'low';
BEGIN
    -- Critical risk: NEWS2 >= 7
    IF p_news2_score >= 7 THEN
        risk_level := 'critical';
    -- High risk: NEWS2 >= 5 OR (new confusion + signs of infection)
    ELSIF p_news2_score >= 5 OR (p_new_confusion = TRUE AND array_length(p_signs_of_infection, 1) > 0) THEN
        risk_level := 'high';
    -- Medium risk: NEWS2 = 3-4 OR patient looks unwell
    ELSIF p_news2_score >= 3 OR p_patient_unwell = TRUE THEN
        risk_level := 'medium';
    ELSE
        risk_level := 'low';
    END IF;
    
    RETURN risk_level;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create trigger function to auto-calculate scores and risk levels
CREATE OR REPLACE FUNCTION update_sepsis_assessment_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate NEWS2 score
    NEW.news2_score := calculate_news2_score(
        NEW.temperature,
        NEW.heart_rate,
        NEW.respiratory_rate,
        NEW.oxygen_saturation,
        NEW.systolic_bp,
        NEW.consciousness_level
    );
    
    -- Determine sepsis risk level
    NEW.sepsis_risk_level := determine_sepsis_risk_level(
        NEW.news2_score,
        NEW.new_confusion,
        NEW.signs_of_infection,
        NEW.patient_unwell
    );
    
    -- Set default action based on risk level
    IF NEW.sepsis_risk_level = 'critical' THEN
        NEW.action_taken := '999';
    ELSIF NEW.sepsis_risk_level = 'high' THEN
        NEW.action_taken := 'escalate';
    ELSE
        NEW.action_taken := 'monitor';
    END IF;
    
    -- Update timestamp
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_sepsis_assessment ON sepsis_risk_assessments;
CREATE TRIGGER trigger_update_sepsis_assessment
    BEFORE INSERT OR UPDATE ON sepsis_risk_assessments
    FOR EACH ROW EXECUTE FUNCTION update_sepsis_assessment_trigger();

-- Create function to get sepsis stats
CREATE OR REPLACE FUNCTION get_sepsis_risk_stats()
RETURNS TABLE (
    risk_level VARCHAR,
    count INTEGER,
    percentage NUMERIC
) AS $$
DECLARE
    total_count INTEGER;
BEGIN
    -- Get total count
    SELECT COUNT(*) INTO total_count FROM sepsis_risk_assessments;
    
    -- Return stats
    RETURN QUERY
    SELECT 
        sra.sepsis_risk_level,
        COUNT(*) as count,
        ROUND((COUNT(*) * 100.0 / NULLIF(total_count, 0)), 1) as percentage
    FROM sepsis_risk_assessments sra
    GROUP BY sra.sepsis_risk_level
    ORDER BY count DESC;
END;
$$ LANGUAGE plpgsql;

-- Create function to get urgent assessments
CREATE OR REPLACE FUNCTION get_urgent_sepsis_assessments()
RETURNS TABLE (
    id UUID,
    service_user_name VARCHAR,
    news2_score INTEGER,
    sepsis_risk_level VARCHAR,
    assessment_date TIMESTAMP WITH TIME ZONE,
    action_taken VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sra.id,
        su.full_name as service_user_name,
        sra.news2_score,
        sra.sepsis_risk_level,
        sra.assessment_date,
        sra.action_taken
    FROM sepsis_risk_assessments sra
    JOIN service_users su ON sra.service_user_id = su.id
    WHERE sra.news2_score >= 5
    ORDER BY sra.news2_score DESC, sra.assessment_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Row Level Security policies
ALTER TABLE sepsis_risk_assessments ENABLE ROW LEVEL SECURITY;

-- Allow read access for authenticated users
CREATE POLICY "Users can view sepsis assessments" ON sepsis_risk_assessments
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        (
            -- Staff can view their own assessments and assessments for their service users
            assessor_id = auth.uid() OR
            service_user_id IN (
                SELECT service_user_id FROM staff_service_users 
                WHERE staff_id = auth.uid()
            ) OR
            -- Admins can view all
            auth.uid() IN (
                SELECT id FROM profiles WHERE role = 'admin'
            )
        )
    );

-- Allow insert for authenticated users
CREATE POLICY "Users can create sepsis assessments" ON sepsis_risk_assessments
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow update for authenticated users (only their own assessments)
CREATE POLICY "Users can update their own sepsis assessments" ON sepsis_risk_assessments
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND assessor_id = auth.uid()
    );

-- Allow delete for authenticated users (only their own assessments)
CREATE POLICY "Users can delete their own sepsis assessments" ON sepsis_risk_assessments
    FOR DELETE USING (
        auth.role() = 'authenticated' AND assessor_id = auth.uid()
    );

-- Insert sample data for testing
INSERT INTO sepsis_risk_assessments (
    service_user_id,
    assessor_id,
    assessment_time,
    temperature,
    heart_rate,
    respiratory_rate,
    oxygen_saturation,
    systolic_bp,
    consciousness_level,
    new_confusion,
    signs_of_infection,
    infection_source,
    patient_unwell,
    family_concerned,
    sepsis_six_completed,
    sepsis_six_details,
    referral_to_hospital,
    referral_time,
    hospital_outcome,
    assessor_signature,
    review_time
) VALUES 
(
    (SELECT id FROM service_users LIMIT 1),
    (SELECT id FROM profiles WHERE role = 'staff' LIMIT 1),
    '10:30:00',
    38.5,
    115,
    22,
    94.0,
    95,
    'alert',
    true,
    ARRAY['fever'],
    'urinary tract',
    true,
    false,
    ARRAY[true, true, true, false, true, false],
    '{"oxygen": "2L via nasal specs", "fluids": "500ml IV", "bloods": "FBC, CRP, LFTs", "antibiotics": null, "urine": "C&U sent", "output": "Catheter inserted"}',
    true,
    NOW() + INTERVAL '30 minutes',
    'Admitted to hospital',
    'Staff Member 1',
    NOW() + INTERVAL '1 hour'
),
(
    (SELECT id FROM service_users LIMIT 1),
    (SELECT id FROM profiles WHERE role = 'staff' LIMIT 1),
    '14:15:00',
    36.8,
    85,
    16,
    98.0,
    120,
    'alert',
    false,
    ARRAY[''],
    null,
    false,
    false,
    ARRAY[false, false, false, false, false, false],
    '{}',
    false,
    null,
    null,
    'Staff Member 1',
    NOW() + INTERVAL '4 hours'
);