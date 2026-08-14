-- Create bed railing risk assessments table
CREATE TABLE bed_railing_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
    
    -- Assessment metadata
    assessment_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Bed and rail information
    bed_type TEXT NOT NULL CHECK (bed_type IN ('standard', 'profiling', 'hospital', 'other')),
    bed_rails_type TEXT NOT NULL CHECK (bed_rails_type IN ('full', 'half', 'mobile', 'other')),
    rail_condition TEXT NOT NULL CHECK (rail_condition IN ('good', 'worn', 'damaged')),
    manufacturer_instructions_available BOOLEAN NOT NULL DEFAULT false,
    rail_height_and_fit TEXT NOT NULL CHECK (rail_height_and_fit IN ('correct', 'incorrect')),
    
    -- Risk assessment
    entrapment_risk_assessed BOOLEAN NOT NULL DEFAULT false,
    patient_mobility TEXT NOT NULL CHECK (patient_mobility IN ('independent', 'assisted', 'bedbound')),
    cognitive_impairment BOOLEAN NOT NULL DEFAULT false,
    agitation_restlessness BOOLEAN NOT NULL DEFAULT false,
    risk_of_falling_out_of_bed TEXT NOT NULL CHECK (risk_of_falling_out_of_bed IN ('high', 'medium', 'low')),
    risk_of_entrapment TEXT NOT NULL CHECK (risk_of_entrapment IN ('high', 'medium', 'low')),
    
    -- Safety measures
    alternative_measures_considered BOOLEAN NOT NULL DEFAULT false,
    family_consent_obtained BOOLEAN NOT NULL DEFAULT false,
    staff_trained_in_bed_rail_use BOOLEAN NOT NULL DEFAULT false,
    rail_regularly_checked BOOLEAN NOT NULL DEFAULT false,
    last_check_date DATE,
    next_check_date DATE,
    
    -- Documentation
    action_plan TEXT,
    review_date DATE,
    
    -- Metadata
    assessor_name TEXT NOT NULL,
    assessor_signature TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_bed_railing_assessments_service_user ON bed_railing_risk_assessments(service_user_id);
CREATE INDEX idx_bed_railing_assessments_date ON bed_railing_risk_assessments(assessment_date);
CREATE INDEX idx_bed_railing_assessments_bed_type ON bed_railing_risk_assessments(bed_type);
CREATE INDEX idx_bed_railing_assessments_risk_level ON bed_railing_risk_assessments(risk_of_falling_out_of_bed, risk_of_entrapment);
CREATE INDEX idx_bed_railing_assessments_next_check ON bed_railing_risk_assessments(next_check_date);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_bed_railing_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_bed_railing_risk_assessments_updated_at 
    BEFORE UPDATE ON bed_railing_risk_assessments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_bed_railing_updated_at();

-- Create function to calculate entrapment risk
CREATE OR REPLACE FUNCTION calculate_entrapment_risk(
    p_rail_condition TEXT,
    p_rail_height_and_fit TEXT,
    p_patient_mobility TEXT,
    p_cognitive_impairment BOOLEAN,
    p_agitation_restlessness BOOLEAN
) RETURNS TEXT AS $$
DECLARE
    risk_score INTEGER := 0;
    risk_level TEXT := 'low';
BEGIN
    -- Base risk from rail condition
    CASE p_rail_condition
        WHEN 'damaged' THEN risk_score := risk_score + 3;
        WHEN 'worn' THEN risk_score := risk_score + 2;
        WHEN 'good' THEN risk_score := risk_score + 0;
    END CASE;
    
    -- Risk from fit
    IF p_rail_height_and_fit = 'incorrect' THEN
        risk_score := risk_score + 2;
    END IF;
    
    -- Risk from patient factors
    IF p_patient_mobility = 'independent' THEN
        risk_score := risk_score + 1;
    END IF;
    
    IF p_cognitive_impairment THEN
        risk_score := risk_score + 2;
    END IF;
    
    IF p_agitation_restlessness THEN
        risk_score := risk_score + 2;
    END IF;
    
    -- Determine risk level
    IF risk_score >= 6 THEN
        risk_level := 'high';
    ELSIF risk_score >= 3 THEN
        risk_level := 'medium';
    ELSE
        risk_level := 'low';
    END IF;
    
    RETURN risk_level;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to calculate fall risk
CREATE OR REPLACE FUNCTION calculate_fall_risk(
    p_patient_mobility TEXT,
    p_cognitive_impairment BOOLEAN,
    p_agitation_restlessness BOOLEAN,
    p_rail_condition TEXT
) RETURNS TEXT AS $$
DECLARE
    risk_score INTEGER := 0;
    risk_level TEXT := 'low';
BEGIN
    -- Base risk from mobility
    CASE p_patient_mobility
        WHEN 'independent' THEN risk_score := risk_score + 1;
        WHEN 'assisted' THEN risk_score := risk_score + 2;
        WHEN 'bedbound' THEN risk_score := risk_score + 0;
    END CASE;
    
    -- Risk from cognitive impairment
    IF p_cognitive_impairment THEN
        risk_score := risk_score + 2;
    END IF;
    
    -- Risk from agitation
    IF p_agitation_restlessness THEN
        risk_score := risk_score + 2;
    END IF;
    
    -- Risk from rail condition
    IF p_rail_condition = 'damaged' THEN
        risk_score := risk_score + 2;
    ELSIF p_rail_condition = 'worn' THEN
        risk_score := risk_score + 1;
    END IF;
    
    -- Determine risk level
    IF risk_score >= 5 THEN
        risk_level := 'high';
    ELSIF risk_score >= 3 THEN
        risk_level := 'medium';
    ELSE
        risk_level := 'low';
    END IF;
    
    RETURN risk_level;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create trigger to auto-calculate risks
CREATE OR REPLACE FUNCTION auto_calculate_bed_rail_risks()
RETURNS TRIGGER AS $$
BEGIN
    -- Only calculate if not manually set
    IF NEW.risk_of_entrapment IS NULL OR NEW.risk_of_entrapment = '' THEN
        NEW.risk_of_entrapment := calculate_entrapment_risk(
            NEW.rail_condition,
            NEW.rail_height_and_fit,
            NEW.patient_mobility,
            NEW.cognitive_impairment,
            NEW.agitation_restlessness
        );
    END IF;
    
    IF NEW.risk_of_falling_out_of_bed IS NULL OR NEW.risk_of_falling_out_of_bed = '' THEN
        NEW.risk_of_falling_out_of_bed := calculate_fall_risk(
            NEW.patient_mobility,
            NEW.cognitive_impairment,
            NEW.agitation_restlessness,
            NEW.rail_condition
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_calculate_bed_rail_risks_trigger
    BEFORE INSERT OR UPDATE ON bed_railing_risk_assessments
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_bed_rail_risks();

-- Create view for LOLER compliance tracking
CREATE VIEW bed_rail_loler_compliance AS
SELECT 
    id,
    service_user_id,
    assessment_date,
    bed_type,
    bed_rails_type,
    rail_condition,
    manufacturer_instructions_available,
    rail_height_and_fit,
    entrapment_risk_assessed,
    patient_mobility,
    cognitive_impairment,
    agitation_restlessness,
    risk_of_falling_out_of_bed,
    risk_of_entrapment,
    alternative_measures_considered,
    family_consent_obtained,
    staff_trained_in_bed_rail_use,
    rail_regularly_checked,
    last_check_date,
    next_check_date,
    action_plan,
    review_date,
    assessor_name,
    assessor_signature,
    created_at,
    updated_at,
    
    -- LOLER compliance indicators
    CASE 
        WHEN manufacturer_instructions_available = true 
             AND rail_condition = 'good' 
             AND rail_height_and_fit = 'correct'
             AND entrapment_risk_assessed = true
             AND staff_trained_in_bed_rail_use = true
             AND rail_regularly_checked = true
        THEN true 
        ELSE false 
    END AS lol_compliant,
    
    -- High-risk indicators
    CASE 
        WHEN risk_of_entrapment = 'high' OR risk_of_falling_out_of_bed = 'high' 
        THEN true 
        ELSE false 
    END AS high_risk,
    
    -- Due for check
    CASE 
        WHEN next_check_date IS NOT NULL AND next_check_date <= CURRENT_DATE 
        THEN true 
        ELSE false 
    END AS due_for_check
    
FROM bed_railing_risk_assessments;

-- Set up Row Level Security (RLS)
ALTER TABLE bed_railing_risk_assessments ENABLE ROW LEVEL SECURITY;

-- Policies for bed railing risk assessments
CREATE POLICY "Users can view their own service user bed rail assessments" ON bed_railing_risk_assessments
    FOR SELECT USING (
        service_user_id IN (
            SELECT service_user_id FROM carer_service_users 
            WHERE carer_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert bed rail assessments for their service users" ON bed_railing_risk_assessments
    FOR INSERT WITH CHECK (
        service_user_id IN (
            SELECT service_user_id FROM carer_service_users 
            WHERE carer_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own bed rail assessments" ON bed_railing_risk_assessments
    FOR UPDATE USING (
        service_user_id IN (
            SELECT service_user_id FROM carer_service_users 
            WHERE carer_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own bed rail assessments" ON bed_railing_risk_assessments
    FOR DELETE USING (
        service_user_id IN (
            SELECT service_user_id FROM carer_service_users 
            WHERE carer_id = auth.uid()
        )
    );

-- Grant permissions
GRANT ALL ON bed_railing_risk_assessments TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;