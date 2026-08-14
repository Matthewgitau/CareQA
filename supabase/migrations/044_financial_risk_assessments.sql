-- Create financial_risk_assessments table
CREATE TABLE financial_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
    
    -- Assessment metadata
    assessment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    financial_capacity VARCHAR(20) NOT NULL CHECK (financial_capacity IN ('full', 'partial', 'none')),
    mental_capacity_assessment_date DATE,
    
    -- Appointee/Deputy information
    appointee_deputy_appointed BOOLEAN NOT NULL DEFAULT false,
    appointee_name VARCHAR(255),
    appointee_contact VARCHAR(255),
    
    -- Financial management
    managing_own_finances VARCHAR(20) NOT NULL CHECK (managing_own_finances IN ('yes', 'no', 'partial')),
    
    -- Benefits and income
    benefits_claimed TEXT[], -- Array of benefits: PIP, AA, UC, State Pension, etc.
    savings_and_assets DECIMAL(15,2),
    
    -- Financial management status
    debt_management VARCHAR(20) NOT NULL CHECK (debt_management IN ('none', 'manageable', 'struggling')),
    bills_paid VARCHAR(20) NOT NULL CHECK (bills_paid IN ('on_time', 'late', 'unsure')),
    financial_decision_making VARCHAR(20) NOT NULL CHECK (financial_decision_making IN ('independent', 'supported', 'unable')),
    
    -- Financial abuse indicators
    signs_of_financial_abuse BOOLEAN NOT NULL DEFAULT false,
    unusual_transactions BOOLEAN NOT NULL DEFAULT false,
    missing_money BOOLEAN NOT NULL DEFAULT false,
    pressure_from_others BOOLEAN NOT NULL DEFAULT false,
    gambling_concerns BOOLEAN NOT NULL DEFAULT false,
    scams_targeted BOOLEAN NOT NULL DEFAULT false,
    
    -- Support and interventions
    financial_support_worker_involved BOOLEAN NOT NULL DEFAULT false,
    safeguarding_referral_made BOOLEAN NOT NULL DEFAULT false,
    
    -- Documentation
    action_plan TEXT,
    review_date DATE,
    
    -- Metadata
    assessor_name VARCHAR(255) NOT NULL,
    assessor_signature VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_financial_risk_assessments_service_user_id ON financial_risk_assessments(service_user_id);
CREATE INDEX idx_financial_risk_assessments_assessment_date ON financial_risk_assessments(assessment_date);
CREATE INDEX idx_financial_risk_assessments_financial_capacity ON financial_risk_assessments(financial_capacity);
CREATE INDEX idx_financial_risk_assessments_signs_of_financial_abuse ON financial_risk_assessments(signs_of_financial_abuse);
CREATE INDEX idx_financial_risk_assessments_appointee_deputy_appointed ON financial_risk_assessments(appointee_deputy_appointed);
CREATE INDEX idx_financial_risk_assessments_safeguarding_referral_made ON financial_risk_assessments(safeguarding_referral_made);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_financial_risk_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_financial_risk_assessments_updated_at 
    BEFORE UPDATE ON financial_risk_assessments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_financial_risk_assessments_updated_at();

-- Create function to check if review is due
CREATE OR REPLACE FUNCTION is_financial_risk_review_due(
    p_review_date DATE,
    p_assessment_date DATE
) RETURNS BOOLEAN AS $$
BEGIN
    -- Review is due if review_date is set and is today or in the past
    -- OR if no review_date is set but assessment is older than 6 months
    RETURN (
        (p_review_date IS NOT NULL AND p_review_date <= CURRENT_DATE)
        OR 
        (p_review_date IS NULL AND p_assessment_date <= CURRENT_DATE - INTERVAL '6 months')
    );
END;
$$ LANGUAGE plpgsql;

-- Create function to calculate financial risk level
CREATE OR REPLACE FUNCTION calculate_financial_risk_level(
    p_financial_capacity VARCHAR(20),
    p_signs_of_financial_abuse BOOLEAN,
    p_unusual_transactions BOOLEAN,
    p_missing_money BOOLEAN,
    p_pressure_from_others BOOLEAN,
    p_gambling_concerns BOOLEAN,
    p_scams_targeted BOOLEAN,
    p_debt_management VARCHAR(20),
    p_bills_paid VARCHAR(20)
) RETURNS VARCHAR(20) AS $$
DECLARE
    risk_score INTEGER := 0;
BEGIN
    -- Base risk based on financial capacity
    CASE p_financial_capacity
        WHEN 'none' THEN risk_score := risk_score + 3;
        WHEN 'partial' THEN risk_score := risk_score + 2;
        WHEN 'full' THEN risk_score := risk_score + 0;
    END CASE;
    
    -- Risk factors
    IF p_signs_of_financial_abuse THEN risk_score := risk_score + 4; END IF;
    IF p_unusual_transactions THEN risk_score := risk_score + 3; END IF;
    IF p_missing_money THEN risk_score := risk_score + 3; END IF;
    IF p_pressure_from_others THEN risk_score := risk_score + 2; END IF;
    IF p_gambling_concerns THEN risk_score := risk_score + 3; END IF;
    IF p_scams_targeted THEN risk_score := risk_score + 3; END IF;
    
    -- Debt and bill management
    CASE p_debt_management
        WHEN 'struggling' THEN risk_score := risk_score + 3;
        WHEN 'manageable' THEN risk_score := risk_score + 1;
        WHEN 'none' THEN risk_score := risk_score + 0;
    END CASE;
    
    CASE p_bills_paid
        WHEN 'late' THEN risk_score := risk_score + 2;
        WHEN 'unsure' THEN risk_score := risk_score + 1;
        WHEN 'on_time' THEN risk_score := risk_score + 0;
    END CASE;
    
    -- Determine risk level
    IF risk_score >= 10 THEN
        RETURN 'high';
    ELSIF risk_score >= 5 THEN
        RETURN 'medium';
    ELSE
        RETURN 'low';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create function to check if appointee referral needed
CREATE OR REPLACE FUNCTION needs_appointee_referral(
    p_financial_capacity VARCHAR(20),
    p_managing_own_finances VARCHAR(20),
    p_appointee_deputy_appointed BOOLEAN
) RETURNS BOOLEAN AS $$
BEGIN
    -- Need appointee referral if unable to manage finances and no appointee/deputy
    RETURN (
        (p_financial_capacity = 'none' OR p_managing_own_finances = 'no')
        AND NOT p_appointee_deputy_appointed
    );
END;
$$ LANGUAGE plpgsql;

-- Create function to check if safeguarding referral needed
CREATE OR REPLACE FUNCTION needs_safeguarding_referral(
    p_signs_of_financial_abuse BOOLEAN,
    p_unusual_transactions BOOLEAN,
    p_missing_money BOOLEAN,
    p_pressure_from_others BOOLEAN,
    p_scams_targeted BOOLEAN
) RETURNS BOOLEAN AS $$
BEGIN
    -- Need safeguarding referral if any signs of financial abuse or scams
    RETURN (
        p_signs_of_financial_abuse 
        OR p_unusual_transactions 
        OR p_missing_money 
        OR p_pressure_from_others 
        OR p_scams_targeted
    );
END;
$$ LANGUAGE plpgsql;

-- Create function to get recommended review frequency
CREATE OR REPLACE FUNCTION get_financial_risk_review_frequency(
    p_financial_capacity VARCHAR(20),
    p_signs_of_financial_abuse BOOLEAN,
    p_debt_management VARCHAR(20),
    p_bills_paid VARCHAR(20)
) RETURNS VARCHAR(50) AS $$
BEGIN
    -- High frequency if high risk factors
    IF p_signs_of_financial_abuse OR p_financial_capacity = 'none' OR p_debt_management = 'struggling' THEN
        RETURN 'Monthly review recommended';
    -- Medium frequency for moderate risk
    ELSIF p_financial_capacity = 'partial' OR p_bills_paid = 'late' THEN
        RETURN 'Quarterly review recommended';
    -- Low frequency for low risk
    ELSE
        RETURN 'Annual review recommended';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create function to get financial support recommendations
CREATE OR REPLACE FUNCTION get_financial_support_recommendations(
    p_financial_capacity VARCHAR(20),
    p_managing_own_finances VARCHAR(20),
    p_appointee_deputy_appointed BOOLEAN,
    p_financial_support_worker_involved BOOLEAN,
    p_signs_of_financial_abuse BOOLEAN
) RETURNS TEXT AS $$
DECLARE
    recommendations TEXT := '';
BEGIN
    -- Capacity and management recommendations
    IF p_financial_capacity = 'none' AND NOT p_appointee_deputy_appointed THEN
        recommendations := recommendations || 'Appointee/Deputy required. ';
    END IF;
    
    IF p_managing_own_finances = 'no' AND NOT p_appointee_deputy_appointed THEN
        recommendations := recommendations || 'Financial management support needed. ';
    END IF;
    
    -- Abuse prevention recommendations
    IF p_signs_of_financial_abuse THEN
        recommendations := recommendations || 'Enhanced monitoring and safeguarding measures required. ';
    END IF;
    
    IF NOT p_financial_support_worker_involved AND (p_financial_capacity != 'full' OR p_signs_of_financial_abuse) THEN
        recommendations := recommendations || 'Financial support worker involvement recommended. ';
    END IF;
    
    -- Default recommendation
    IF recommendations = '' THEN
        recommendations := 'Continue current monitoring approach.';
    END IF;
    
    RETURN recommendations;
END;
$$ LANGUAGE plpgsql;

-- Set up Row Level Security (RLS)
ALTER TABLE financial_risk_assessments ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own financial risk assessments" ON financial_risk_assessments
    FOR SELECT USING (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = financial_risk_assessments.service_user_id
        )
        OR
        auth.uid() IN (
            SELECT carer_id FROM service_users 
            WHERE service_users.id = financial_risk_assessments.service_user_id
        )
        OR
        EXISTS (
            SELECT 1 FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = financial_risk_assessments.service_user_id
            )
            AND carehomes.admin_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own financial risk assessments" ON financial_risk_assessments
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = financial_risk_assessments.service_user_id
        )
        OR
        EXISTS (
            SELECT 1 FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = financial_risk_assessments.service_user_id
            )
            AND carehomes.admin_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own financial risk assessments" ON financial_risk_assessments
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = financial_risk_assessments.service_user_id
        )
        OR
        EXISTS (
            SELECT 1 FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = financial_risk_assessments.service_user_id
            )
            AND carehomes.admin_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own financial risk assessments" ON financial_risk_assessments
    FOR DELETE USING (
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = financial_risk_assessments.service_user_id
        )
        OR
        EXISTS (
            SELECT 1 FROM carehomes 
            WHERE carehomes.id = (
                SELECT carehome_id FROM service_users 
                WHERE service_users.id = financial_risk_assessments.service_user_id
            )
            AND carehomes.admin_id = auth.uid()
        )
    );

-- Grant permissions
GRANT ALL ON financial_risk_assessments TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;