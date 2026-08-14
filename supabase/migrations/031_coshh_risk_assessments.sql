-- COSHH Risk Assessment System
-- Based on CR502-COSHH Risk Management.pdf requirements

-- COSHH Risk Assessments table
CREATE TABLE IF NOT EXISTS coshh_risk_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  assessor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  assessment_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  -- Core substance information
  substance_name TEXT NOT NULL,
  type_of_harm TEXT NOT NULL,
  description TEXT NOT NULL, -- liquid/solid/vapour/gas + colour
  how_causes_harm TEXT NOT NULL, -- inhalation/ingestion/absorption
  who_exposed TEXT[] NOT NULL, -- staff/service users/visitors
  frequency_of_use TEXT NOT NULL,
  purpose_activity TEXT NOT NULL,
  
  -- Risk assessment decisions
  can_be_eliminated BOOLEAN NOT NULL,
  elimination_reason TEXT, -- if yes, why/what alternative
  
  -- Control measures
  control_measures JSONB NOT NULL DEFAULT '{}', -- engineering/PPE/procedures
  emergency_procedures JSONB NOT NULL DEFAULT '{}', -- spill/exposure
  
  -- Staff awareness and training
  staff_aware BOOLEAN NOT NULL,
  training_required BOOLEAN DEFAULT false,
  training_details TEXT,
  
  -- Final risk assessment
  risk_acceptable BOOLEAN NOT NULL,
  risk_level TEXT, -- Low/Medium/High
  reconsider_controls TEXT, -- if risk not acceptable
  
  -- Assessment metadata
  signature TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'signed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_coshh_assessments_service_user_id ON coshh_risk_assessments(service_user_id);
CREATE INDEX IF NOT EXISTS idx_coshh_assessments_assessor_id ON coshh_risk_assessments(assessor_id);
CREATE INDEX IF NOT EXISTS idx_coshh_assessments_date ON coshh_risk_assessments(assessment_date);
CREATE INDEX IF NOT EXISTS idx_coshh_assessments_substance_name ON coshh_risk_assessments(substance_name);
CREATE INDEX IF NOT EXISTS idx_coshh_assessments_can_be_eliminated ON coshh_risk_assessments(can_be_eliminated);
CREATE INDEX IF NOT EXISTS idx_coshh_assessments_risk_acceptable ON coshh_risk_assessments(risk_acceptable);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_coshh_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger
DROP TRIGGER IF EXISTS coshh_assessments_updated_at ON coshh_risk_assessments;
CREATE TRIGGER coshh_assessments_updated_at
    BEFORE UPDATE ON coshh_risk_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_coshh_assessments_updated_at();

-- RLS Policies
ALTER TABLE coshh_risk_assessments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own assessments
DROP POLICY IF EXISTS "Users can view COSHH assessments" ON coshh_risk_assessments;
CREATE POLICY "Users can view COSHH assessments" ON coshh_risk_assessments
    FOR SELECT
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to insert assessments
DROP POLICY IF EXISTS "Users can insert COSHH assessments" ON coshh_risk_assessments;
CREATE POLICY "Users can insert COSHH assessments" ON coshh_risk_assessments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'carer'))
    );

-- Allow authenticated users to update their own assessments
DROP POLICY IF EXISTS "Users can update COSHH assessments" ON coshh_risk_assessments;
CREATE POLICY "Users can update COSHH assessments" ON coshh_risk_assessments
    FOR UPDATE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow authenticated users to delete their own assessments
DROP POLICY IF EXISTS "Users can delete COSHH assessments" ON coshh_risk_assessments;
CREATE POLICY "Users can delete COSHH assessments" ON coshh_risk_assessments
    FOR DELETE
    TO authenticated
    USING (
        assessor_id = auth.uid() 
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant permissions
GRANT ALL ON coshh_risk_assessments TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Function to calculate risk level based on assessment criteria
CREATE OR REPLACE FUNCTION calculate_coshh_risk_level(
    p_substance_name TEXT,
    p_how_causes_harm TEXT,
    p_frequency_of_use TEXT,
    p_can_be_eliminated BOOLEAN,
    p_risk_acceptable BOOLEAN
)
RETURNS TEXT AS $$
DECLARE
    risk_score INTEGER := 0;
    risk_level TEXT;
BEGIN
    -- Base risk score based on substance type and harm mechanism
    CASE 
        WHEN p_how_causes_harm ILIKE '%inhalation%' THEN risk_score := risk_score + 3;
        WHEN p_how_causes_harm ILIKE '%ingestion%' THEN risk_score := risk_score + 2;
        WHEN p_how_causes_harm ILIKE '%absorption%' THEN risk_score := risk_score + 2;
    END CASE;
    
    -- Frequency impact
    CASE 
        WHEN p_frequency_of_use ILIKE '%daily%' THEN risk_score := risk_score + 3;
        WHEN p_frequency_of_use ILIKE '%weekly%' THEN risk_score := risk_score + 2;
        WHEN p_frequency_of_use ILIKE '%monthly%' THEN risk_score := risk_score + 1;
    END CASE;
    
    -- Elimination factor
    IF p_can_be_eliminated THEN
        risk_score := risk_score - 2;
    END IF;
    
    -- Final risk assessment
    IF p_risk_acceptable THEN
        risk_score := risk_score - 1;
    END IF;
    
    -- Determine risk level
    IF risk_score <= 2 THEN
        risk_level := 'Low';
    ELSIF risk_score <= 4 THEN
        risk_level := 'Medium';
    ELSE
        risk_level := 'High';
    END IF;
    
    RETURN risk_level;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to trigger training requirement check
CREATE OR REPLACE FUNCTION check_coshh_training_required()
RETURNS TRIGGER AS $$
BEGIN
    -- If staff are not aware, training is required
    IF NEW.staff_aware = false THEN
        NEW.training_required := true;
    ELSE
        NEW.training_required := false;
    END IF;
    
    -- Calculate risk level
    NEW.risk_level := calculate_coshh_risk_level(
        NEW.substance_name,
        NEW.how_causes_harm,
        NEW.frequency_of_use,
        NEW.can_be_eliminated,
        NEW.risk_acceptable
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic calculations
DROP TRIGGER IF EXISTS coshh_assessments_training_check ON coshh_risk_assessments;
CREATE TRIGGER coshh_assessments_training_check
    BEFORE INSERT OR UPDATE ON coshh_risk_assessments
    FOR EACH ROW
    EXECUTE FUNCTION check_coshh_training_required();

-- Function to get COSHH assessment summary
CREATE OR REPLACE FUNCTION get_coshh_assessment_summary(service_user_id_param UUID)
RETURNS TABLE (
    total_assessments INTEGER,
    substances_count INTEGER,
    high_risk_count INTEGER,
    medium_risk_count INTEGER,
    low_risk_count INTEGER,
    training_required_count INTEGER,
    elimination_possible_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_assessments,
        COUNT(DISTINCT substance_name)::INTEGER as substances_count,
        COUNT(CASE WHEN risk_level = 'High' THEN 1 END)::INTEGER as high_risk_count,
        COUNT(CASE WHEN risk_level = 'Medium' THEN 1 END)::INTEGER as medium_risk_count,
        COUNT(CASE WHEN risk_level = 'Low' THEN 1 END)::INTEGER as low_risk_count,
        COUNT(CASE WHEN training_required = true THEN 1 END)::INTEGER as training_required_count,
        COUNT(CASE WHEN can_be_eliminated = true THEN 1 END)::INTEGER as elimination_possible_count
    FROM coshh_risk_assessments
    WHERE service_user_id = service_user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate COSHH assessment completeness
CREATE OR REPLACE FUNCTION validate_coshh_assessment_completeness(assessment_id UUID)
RETURNS TABLE (
    is_complete BOOLEAN,
    missing_fields TEXT[],
    warnings TEXT[]
) AS $$
DECLARE
    missing_fields_array TEXT[] := '{}';
    warnings_array TEXT[] := '{}';
    assessment_record coshh_risk_assessments%ROWTYPE;
BEGIN
    SELECT * INTO assessment_record FROM coshh_risk_assessments WHERE id = assessment_id;
    
    -- Check required fields
    IF assessment_record.substance_name IS NULL OR assessment_record.substance_name = '' THEN
        missing_fields_array := array_append(missing_fields_array, 'Substance Name');
    END IF;
    
    IF assessment_record.type_of_harm IS NULL OR assessment_record.type_of_harm = '' THEN
        missing_fields_array := array_append(missing_fields_array, 'Type of Harm');
    END IF;
    
    IF assessment_record.description IS NULL OR assessment_record.description = '' THEN
        missing_fields_array := array_append(missing_fields_array, 'Description');
    END IF;
    
    IF assessment_record.how_causes_harm IS NULL OR assessment_record.how_causes_harm = '' THEN
        missing_fields_array := array_append(missing_fields_array, 'How it Causes Harm');
    END IF;
    
    IF assessment_record.frequency_of_use IS NULL OR assessment_record.frequency_of_use = '' THEN
        missing_fields_array := array_append(missing_fields_array, 'Frequency of Use');
    END IF;
    
    IF assessment_record.purpose_activity IS NULL OR assessment_record.purpose_activity = '' THEN
        missing_fields_array := array_append(missing_fields_array, 'Purpose/Activity');
    END IF;
    
    IF assessment_record.can_be_eliminated IS NULL THEN
        missing_fields_array := array_append(missing_fields_array, 'Can it be Eliminated?');
    END IF;
    
    IF assessment_record.staff_aware IS NULL THEN
        missing_fields_array := array_append(missing_fields_array, 'Staff Aware?');
    END IF;
    
    IF assessment_record.risk_acceptable IS NULL THEN
        missing_fields_array := array_append(missing_fields_array, 'Risk Acceptable?');
    END IF;
    
    -- Check for warnings
    IF assessment_record.can_be_eliminated = false AND assessment_record.risk_level = 'High' THEN
        warnings_array := array_append(warnings_array, 'High risk substance that cannot be eliminated - consider alternative substances');
    END IF;
    
    IF assessment_record.training_required = true THEN
        warnings_array := array_append(warnings_array, 'Training required for staff');
    END IF;
    
    IF assessment_record.risk_acceptable = false THEN
        warnings_array := array_append(warnings_array, 'Risk not acceptable - reconsider control measures');
    END IF;
    
    RETURN QUERY SELECT 
        (array_length(missing_fields_array, 1) IS NULL)::BOOLEAN as is_complete,
        missing_fields_array as missing_fields,
        warnings_array as warnings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to submit COSHH assessment
CREATE OR REPLACE FUNCTION submit_coshh_assessment(assessment_id UUID, signature_data TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    validation_result RECORD;
BEGIN
    -- Validate completeness
    SELECT * INTO validation_result FROM validate_coshh_assessment_completeness(assessment_id);
    
    IF NOT validation_result.is_complete THEN
        RAISE EXCEPTION 'Cannot submit incomplete assessment. Missing fields: %', validation_result.missing_fields;
    END IF;
    
    -- Update status and signature
    UPDATE coshh_risk_assessments 
    SET 
        status = 'completed',
        signature = signature_data,
        updated_at = NOW()
    WHERE id = assessment_id;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get assessment with all data
CREATE OR REPLACE FUNCTION get_coshh_assessment_with_data(assessment_id UUID)
RETURNS TABLE (
    assessment_data JSONB,
    control_measures_data JSONB,
    emergency_procedures_data JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(cra) as assessment_data,
        cra.control_measures as control_measures_data,
        cra.emergency_procedures as emergency_procedures_data
    FROM coshh_risk_assessments cra
    WHERE cra.id = assessment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert sample data for testing
INSERT INTO coshh_risk_assessments (
    service_user_id,
    assessor_id,
    substance_name,
    type_of_harm,
    description,
    how_causes_harm,
    who_exposed,
    frequency_of_use,
    purpose_activity,
    can_be_eliminated,
    elimination_reason,
    control_measures,
    emergency_procedures,
    staff_aware,
    training_required,
    training_details,
    risk_acceptable,
    risk_level,
    reconsider_controls,
    signature,
    status
) VALUES 
(
    (SELECT id FROM service_users LIMIT 1),
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
    'Bleach Solution',
    'Respiratory irritation, skin burns',
    'Clear liquid, strong chlorine smell',
    'inhalation, absorption',
    ARRAY['staff'],
    'daily',
    'Surface disinfection',
    false,
    'Required for infection control',
    '{"engineering": ["Ventilation"], "PPE": ["Gloves", "Mask"], "procedures": ["Dilution instructions"]}',
    '{"spill": ["Evacuate area", "Ventilate", "Use absorbent material"], "exposure": ["Rinse with water", "Seek medical attention"]}',
    true,
    false,
    'Annual COSHH training completed',
    true,
    'Medium',
    null,
    null,
    'completed'
),
(
    (SELECT id FROM service_users OFFSET 1 LIMIT 1),
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
    'Hand Sanitiser',
    'Skin irritation',
    'Clear gel, alcohol-based',
    'absorption',
    ARRAY['staff', 'service users'],
    'multiple times daily',
    'Hand hygiene',
    true,
    'Can use soap and water instead',
    '{"engineering": [], "PPE": ["None required"], "procedures": ["Use sparingly", "Allow to dry"]}',
    '{"spill": ["Wipe up immediately", "Ventilate area"], "exposure": ["Rinse with water", "Monitor for irritation"]}',
    false,
    true,
    'Training required on proper use',
    true,
    'Low',
    null,
    null,
    'draft'
)
ON CONFLICT DO NOTHING;