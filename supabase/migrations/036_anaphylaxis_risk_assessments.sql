-- Create anaphylaxis risk assessments table
CREATE TABLE IF NOT EXISTS anaphylaxis_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID NOT NULL REFERENCES service_users(id) ON DELETE CASCADE,
    assessor_id UUID NOT NULL REFERENCES carers(id) ON DELETE RESTRICT,
    
    -- Allergy identification
    allergens TEXT[] NOT NULL, -- Array of allergens (e.g., nuts, shellfish, latex)
    allergen_details TEXT, -- Additional details about specific allergens
    
    -- Reaction history
    previous_reaction_severity TEXT CHECK (previous_reaction_severity IN ('mild', 'moderate', 'severe', 'anaphylactic')),
    previous_reaction_date DATE,
    previous_reaction_details TEXT,
    
    -- Auto-injector management
    autoinjector_prescribed BOOLEAN NOT NULL DEFAULT false,
    autoinjector_type TEXT, -- EpiPen, Jext, Emerade, etc.
    autoinjector_location TEXT, -- Where auto-injector is stored
    autoinjector_expiry_date DATE,
    autoinjector_in_date BOOLEAN DEFAULT true, -- Whether expiry is current
    autoinjector_check_date DATE,
    
    -- Emergency preparedness
    emergency_action_plan BOOLEAN NOT NULL DEFAULT false,
    action_plan_location TEXT, -- Where action plan is stored
    action_plan_review_date DATE,
    
    -- Staff training and awareness
    staff_trained_autoinjector BOOLEAN NOT NULL DEFAULT false,
    staff_training_date DATE,
    staff_training_expiry_date DATE,
    service_user_self_administer BOOLEAN DEFAULT false,
    
    -- Allergy awareness
    allergy_alert_visible BOOLEAN NOT NULL DEFAULT false,
    allergy_alert_location TEXT, -- Where allergy alert is displayed
    medical_id_jewellery BOOLEAN DEFAULT false,
    medical_id_details TEXT,
    
    -- Specialist care
    allergy_specialist_referral BOOLEAN DEFAULT false,
    specialist_name TEXT,
    last_appointment_date DATE,
    next_appointment_date DATE,
    
    -- Risk management
    cross_reactivity_risks TEXT[], -- Array of cross-reactivity risks
    cross_reactivity_details TEXT,
    dietary_restrictions TEXT[], -- Array of dietary restrictions
    dietary_details TEXT,
    
    -- Assessment metadata
    risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high', 'extreme')) DEFAULT 'medium',
    status TEXT CHECK (status IN ('draft', 'completed', 'reviewed', 'escalated')) DEFAULT 'draft',
    review_required BOOLEAN DEFAULT false,
    next_review_date DATE,
    
    -- Documentation
    assessment_notes TEXT,
    signature_data TEXT, -- Digital signature data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES carers(id)
);

-- Create indexes for performance
CREATE INDEX idx_anaphylaxis_assessments_service_user ON anaphylaxis_risk_assessments(service_user_id);
CREATE INDEX idx_anaphylaxis_assessments_assessor ON anaphylaxis_risk_assessments(assessor_id);
CREATE INDEX idx_anaphylaxis_assessments_risk_level ON anaphylaxis_risk_assessments(risk_level);
CREATE INDEX idx_anaphylaxis_assessments_status ON anaphylaxis_risk_assessments(status);
CREATE INDEX idx_anaphylaxis_assessments_expiry_date ON anaphylaxis_risk_assessments(autoinjector_expiry_date);
CREATE INDEX idx_anaphylaxis_assessments_review_date ON anaphylaxis_risk_assessments(next_review_date);

-- Enable Row Level Security
ALTER TABLE anaphylaxis_risk_assessments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view assessments for their service users
CREATE POLICY "Users can view assessments for their service users" ON anaphylaxis_risk_assessments
FOR ALL USING (
    service_user_id IN (
        SELECT service_user_id FROM carer_service_users 
        WHERE carer_id = auth.uid()
    )
);

-- Users can view their own assessments
CREATE POLICY "Users can view their own assessments" ON anaphylaxis_risk_assessments
FOR ALL USING (assessor_id = auth.uid());

-- Care home staff can view assessments in their care home
CREATE POLICY "Care home staff can view assessments" ON anaphylaxis_risk_assessments
FOR ALL USING (
    service_user_id IN (
        SELECT su.id FROM service_users su
        JOIN carehomes ch ON su.carehome_id = ch.id
        WHERE ch.id IN (
            SELECT carehome_id FROM carer_carehomes 
            WHERE carer_id = auth.uid()
        )
    )
);

-- Users can insert assessments for their service users
CREATE POLICY "Users can insert assessments" ON anaphylaxis_risk_assessments
FOR INSERT WITH CHECK (
    service_user_id IN (
        SELECT service_user_id FROM carer_service_users 
        WHERE carer_id = auth.uid()
    )
);

-- Users can update their own assessments
CREATE POLICY "Users can update their own assessments" ON anaphylaxis_risk_assessments
FOR UPDATE USING (assessor_id = auth.uid());

-- Enable realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE anaphylaxis_risk_assessments;

-- Create function to calculate risk level
CREATE OR REPLACE FUNCTION calculate_anaphylaxis_risk_level(
    p_previous_severity TEXT,
    p_autoinjector_prescribed BOOLEAN,
    p_autoinjector_in_date BOOLEAN,
    p_emergency_plan BOOLEAN,
    p_staff_trained BOOLEAN,
    p_allergy_alert_visible BOOLEAN
) RETURNS TEXT AS $$
DECLARE
    risk_score INTEGER := 0;
    risk_level TEXT := 'low';
BEGIN
    -- Base risk from previous reaction severity
    CASE p_previous_severity
        WHEN 'anaphylactic' THEN risk_score := risk_score + 4;
        WHEN 'severe' THEN risk_score := risk_score + 3;
        WHEN 'moderate' THEN risk_score := risk_score + 2;
        WHEN 'mild' THEN risk_score := risk_score + 1;
        ELSE risk_score := risk_score + 1;
    END CASE;
    
    -- Risk reduction factors
    IF p_autoinjector_prescribed AND p_autoinjector_in_date THEN
        risk_score := risk_score - 1;
    END IF;
    
    IF p_emergency_plan THEN
        risk_score := risk_score - 1;
    END IF;
    
    IF p_staff_trained THEN
        risk_score := risk_score - 1;
    END IF;
    
    IF p_allergy_alert_visible THEN
        risk_score := risk_score - 1;
    END IF;
    
    -- Determine risk level
    IF risk_score >= 4 THEN
        risk_level := 'extreme';
    ELSIF risk_score >= 3 THEN
        risk_level := 'high';
    ELSIF risk_score >= 2 THEN
        risk_level := 'medium';
    ELSE
        risk_level := 'low';
    END IF;
    
    RETURN risk_level;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to check auto-injector expiry
CREATE OR REPLACE FUNCTION check_autoinjector_expiry() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.autoinjector_expiry_date IS NOT NULL THEN
        NEW.autoinjector_in_date := NEW.autoinjector_expiry_date > CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-injector expiry check
CREATE TRIGGER trigger_check_autoinjector_expiry
    BEFORE INSERT OR UPDATE ON anaphylaxis_risk_assessments
    FOR EACH ROW EXECUTE FUNCTION check_autoinjector_expiry();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_anaphylaxis_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_anaphylaxis_updated_at
    BEFORE UPDATE ON anaphylaxis_risk_assessments
    FOR EACH ROW EXECUTE FUNCTION update_anaphylaxis_updated_at_column();

-- Create function to flag high-risk anaphylaxis assessments
CREATE OR REPLACE FUNCTION flag_high_risk_anaphylaxis_assessments()
RETURNS TABLE (
    assessment_id UUID,
    service_user_name TEXT,
    allergens TEXT,
    risk_level TEXT,
    autoinjector_status TEXT,
    emergency_plan_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        aa.id,
        su.full_name,
        array_to_string(aa.allergens, ', '),
        aa.risk_level,
        CASE 
            WHEN aa.autoinjector_prescribed AND aa.autoinjector_in_date THEN 'Current'
            WHEN aa.autoinjector_prescribed AND NOT aa.autoinjector_in_date THEN 'Expired'
            ELSE 'Not prescribed'
        END,
        CASE 
            WHEN aa.emergency_action_plan THEN 'In place'
            ELSE 'Not in place'
        END
    FROM anaphylaxis_risk_assessments aa
    JOIN service_users su ON aa.service_user_id = su.id
    WHERE aa.risk_level IN ('high', 'extreme')
    ORDER BY aa.risk_level DESC, aa.autoinjector_in_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get anaphylaxis assessment summary
CREATE OR REPLACE FUNCTION get_anaphylaxis_assessment_summary(p_service_user_id UUID)
RETURNS TABLE (
    total_assessments INTEGER,
    latest_assessment_date DATE,
    current_risk_level TEXT,
    autoinjector_status TEXT,
    emergency_plan_status TEXT,
    staff_training_status TEXT,
    allergy_alert_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER,
        MAX(aa.created_at)::DATE,
        MAX(aa.risk_level),
        CASE 
            WHEN MAX(aa.autoinjector_prescribed) AND MAX(aa.autoinjector_in_date) THEN 'Current'
            WHEN MAX(aa.autoinjector_prescribed) AND NOT MAX(aa.autoinjector_in_date) THEN 'Expired'
            WHEN MAX(aa.autoinjector_prescribed) THEN 'Prescribed'
            ELSE 'Not prescribed'
        END,
        CASE 
            WHEN MAX(aa.emergency_action_plan) THEN 'In place'
            ELSE 'Not in place'
        END,
        CASE 
            WHEN MAX(aa.staff_trained_autoinjector) THEN 'Trained'
            ELSE 'Not trained'
        END,
        CASE 
            WHEN MAX(aa.allergy_alert_visible) THEN 'Visible'
            ELSE 'Not visible'
        END
    FROM anaphylaxis_risk_assessments aa
    WHERE aa.service_user_id = p_service_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to validate anaphylaxis assessment completeness
CREATE OR REPLACE FUNCTION validate_anaphylaxis_assessment_completeness(p_assessment_id UUID)
RETURNS TABLE (
    is_complete BOOLEAN,
    missing_fields TEXT[],
    validation_errors TEXT[]
) AS $$
DECLARE
    assessment_record anaphylaxis_risk_assessments;
    missing_fields_array TEXT[] := '{}';
    validation_errors_array TEXT[] := '{}';
    is_complete_result BOOLEAN := true;
BEGIN
    SELECT * INTO assessment_record FROM anaphylaxis_risk_assessments WHERE id = p_assessment_id;
    
    -- Check required fields
    IF assessment_record.allergens IS NULL OR array_length(assessment_record.allergens, 1) = 0 THEN
        missing_fields_array := array_append(missing_fields_array, 'allergens');
        is_complete_result := false;
    END IF;
    
    IF assessment_record.previous_reaction_severity IS NULL THEN
        missing_fields_array := array_append(missing_fields_array, 'previous_reaction_severity');
        is_complete_result := false;
    END IF;
    
    IF assessment_record.autoinjector_prescribed IS NULL THEN
        missing_fields_array := array_append(missing_fields_array, 'autoinjector_prescribed');
        is_complete_result := false;
    END IF;
    
    -- Check logical consistency
    IF assessment_record.autoinjector_prescribed AND assessment_record.autoinjector_expiry_date IS NULL THEN
        validation_errors_array := array_append(validation_errors_array, 'Auto-injector expiry date required when prescribed');
        is_complete_result := false;
    END IF;
    
    IF assessment_record.emergency_action_plan AND assessment_record.action_plan_location IS NULL THEN
        validation_errors_array := array_append(validation_errors_array, 'Action plan location required when plan exists');
        is_complete_result := false;
    END IF;
    
    IF assessment_record.staff_trained_autoinjector AND assessment_record.staff_training_date IS NULL THEN
        validation_errors_array := array_append(validation_errors_array, 'Staff training date required when trained');
        is_complete_result := false;
    END IF;
    
    RETURN QUERY SELECT is_complete_result, missing_fields_array, validation_errors_array;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to submit anaphylaxis assessment with checks
CREATE OR REPLACE FUNCTION submit_anaphylaxis_assessment(
    p_assessment_id UUID,
    p_signature_data TEXT
) RETURNS VOID AS $$
DECLARE
    assessment_record anaphylaxis_risk_assessments;
    risk_level TEXT;
BEGIN
    -- Get assessment record
    SELECT * INTO assessment_record FROM anaphylaxis_risk_assessments WHERE id = p_assessment_id;
    
    -- Calculate risk level
    risk_level := calculate_anaphylaxis_risk_level(
        assessment_record.previous_reaction_severity,
        assessment_record.autoinjector_prescribed,
        assessment_record.autoinjector_in_date,
        assessment_record.emergency_action_plan,
        assessment_record.staff_trained_autoinjector,
        assessment_record.allergy_alert_visible
    );
    
    -- Update assessment
    UPDATE anaphylaxis_risk_assessments 
    SET 
        risk_level = risk_level,
        status = CASE 
            WHEN risk_level IN ('high', 'extreme') THEN 'escalated'
            ELSE 'completed'
        END,
        signature_data = p_signature_data,
        updated_at = NOW()
    WHERE id = p_assessment_id;
    
    -- Insert audit log for high-risk cases
    IF risk_level IN ('high', 'extreme') THEN
        INSERT INTO audit_logs (
            table_name, 
            record_id, 
            action, 
            details, 
            performed_by
        ) VALUES (
            'anaphylaxis_risk_assessments',
            p_assessment_id,
            'ESCALATED',
            format('High-risk anaphylaxis assessment submitted with risk level: %s', risk_level),
            assessment_record.assessor_id
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create view for anaphylaxis dashboard
CREATE VIEW anaphylaxis_dashboard_view AS
SELECT 
    aa.id,
    su.full_name as service_user_name,
    su.id as service_user_id,
    array_to_string(aa.allergens, ', ') as allergens,
    aa.previous_reaction_severity,
    aa.risk_level,
    aa.status,
    aa.autoinjector_prescribed,
    aa.autoinjector_in_date,
    aa.autoinjector_expiry_date,
    aa.emergency_action_plan,
    aa.staff_trained_autoinjector,
    aa.allergy_alert_visible,
    aa.created_at,
    aa.updated_at,
    aa.next_review_date,
    CASE 
        WHEN aa.autoinjector_expiry_date IS NOT NULL AND aa.autoinjector_expiry_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN aa.autoinjector_expiry_date IS NOT NULL AND aa.autoinjector_expiry_date <= CURRENT_DATE + INTERVAL '3 months' THEN 'EXPIRING_SOON'
        ELSE 'CURRENT'
    END as autoinjector_status,
    CASE 
        WHEN aa.next_review_date IS NOT NULL AND aa.next_review_date < CURRENT_DATE THEN 'OVERDUE'
        WHEN aa.next_review_date IS NOT NULL AND aa.next_review_date <= CURRENT_DATE + INTERVAL '1 month' THEN 'DUE_SOON'
        ELSE 'CURRENT'
    END as review_status
FROM anaphylaxis_risk_assessments aa
JOIN service_users su ON aa.service_user_id = su.id
ORDER BY aa.risk_level DESC, aa.updated_at DESC;