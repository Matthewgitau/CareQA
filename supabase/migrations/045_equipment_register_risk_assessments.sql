-- Equipment Register Risk Assessments Table
-- Tracks equipment inventory, safety checks, and maintenance

-- Create the equipment_register_risk_assessments table
CREATE TABLE equipment_register_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    equipment_id VARCHAR(100) NOT NULL UNIQUE,
    equipment_name VARCHAR(200) NOT NULL,
    equipment_category VARCHAR(50) CHECK (equipment_category IN ('hoist', 'wheelchair', 'bed', 'chair', 'other')) NOT NULL,
    serial_number VARCHAR(100),
    manufacturer VARCHAR(150),
    supplier VARCHAR(150),
    purchase_date DATE,
    last_service_date DATE,
    next_service_due_date DATE,
    service_provider VARCHAR(150),
    pat_test_date DATE,
    pat_test_expiry DATE,
    loler_test_date DATE,
    loler_test_expiry DATE,
    daily_checks_completed BOOLEAN DEFAULT false,
    weekly_checks_completed BOOLEAN DEFAULT false,
    monthly_checks_completed BOOLEAN DEFAULT false,
    equipment_condition VARCHAR(20) CHECK (equipment_condition IN ('good', 'worn', 'damaged', 'unsafe')) DEFAULT 'good',
    reported_faults VARCHAR(20) CHECK (reported_faults IN ('none', 'minor', 'major')) DEFAULT 'none',
    fault_reported_date DATE,
    fault_resolved_date DATE,
    staff_trained BOOLEAN DEFAULT false,
    training_record_available BOOLEAN DEFAULT false,
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high', 'critical')) DEFAULT 'low',
    action_required TEXT,
    review_date DATE,
    assessor_name VARCHAR(150),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_equipment_register_equipment_id ON equipment_register_risk_assessments(equipment_id);
CREATE INDEX idx_equipment_register_category ON equipment_register_risk_assessments(equipment_category);
CREATE INDEX idx_equipment_register_next_service ON equipment_register_risk_assessments(next_service_due_date);
CREATE INDEX idx_equipment_register_pat_expiry ON equipment_register_risk_assessments(pat_test_expiry);
CREATE INDEX idx_equipment_register_loler_expiry ON equipment_register_risk_assessments(loler_test_expiry);
CREATE INDEX idx_equipment_register_condition ON equipment_register_risk_assessments(equipment_condition);
CREATE INDEX idx_equipment_register_faults ON equipment_register_risk_assessments(reported_faults);
CREATE INDEX idx_equipment_register_risk_level ON equipment_register_risk_assessments(risk_level);

-- Create function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_equipment_register_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update the updated_at timestamp
CREATE TRIGGER update_equipment_register_risk_assessments_updated_at
    BEFORE UPDATE ON equipment_register_risk_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_equipment_register_updated_at();

-- Create RLS policies
ALTER TABLE equipment_register_risk_assessments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read equipment register assessments
CREATE POLICY "Users can view equipment register assessments" ON equipment_register_risk_assessments
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow authenticated users to insert equipment register assessments
CREATE POLICY "Users can create equipment register assessments" ON equipment_register_risk_assessments
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to update equipment register assessments
CREATE POLICY "Users can update equipment register assessments" ON equipment_register_risk_assessments
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Allow authenticated users to delete equipment register assessments
CREATE POLICY "Users can delete equipment register assessments" ON equipment_register_risk_assessments
    FOR DELETE USING (auth.role() = 'authenticated');

-- Create function to calculate risk level based on equipment status
CREATE OR REPLACE FUNCTION calculate_equipment_risk_level(
    p_loler_expired BOOLEAN,
    p_pat_expired BOOLEAN,
    p_major_fault BOOLEAN,
    p_equipment_condition VARCHAR(20),
    p_daily_checks BOOLEAN,
    p_weekly_checks BOOLEAN,
    p_monthly_checks BOOLEAN
) RETURNS VARCHAR(20) AS $$
BEGIN
    -- Critical risk conditions
    IF p_loler_expired OR p_equipment_condition = 'unsafe' OR p_major_fault THEN
        RETURN 'critical';
    END IF;
    
    -- High risk conditions
    IF p_pat_expired OR p_equipment_condition = 'damaged' THEN
        RETURN 'high';
    END IF;
    
    -- Medium risk conditions
    IF p_equipment_condition = 'worn' OR NOT p_daily_checks OR NOT p_weekly_checks OR NOT p_monthly_checks THEN
        RETURN 'medium';
    END IF;
    
    -- Low risk
    RETURN 'low';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to check if equipment is safe for use
CREATE OR REPLACE FUNCTION is_equipment_safe(
    p_loler_expired BOOLEAN,
    p_pat_expired BOOLEAN,
    p_major_fault BOOLEAN,
    p_equipment_condition VARCHAR(20)
) RETURNS BOOLEAN AS $$
BEGIN
    -- Equipment is unsafe if LOLER expired, has major fault, or condition is unsafe
    IF p_loler_expired OR p_major_fault OR p_equipment_condition = 'unsafe' THEN
        RETURN false;
    END IF;
    
    -- Equipment is safe if no critical issues
    RETURN true;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create view for equipment status dashboard
CREATE VIEW equipment_status_dashboard AS
SELECT 
    equipment_id,
    equipment_name,
    equipment_category,
    serial_number,
    manufacturer,
    supplier,
    purchase_date,
    last_service_date,
    next_service_due_date,
    service_provider,
    pat_test_date,
    pat_test_expiry,
    loler_test_date,
    loler_test_expiry,
    daily_checks_completed,
    weekly_checks_completed,
    monthly_checks_completed,
    equipment_condition,
    reported_faults,
    fault_reported_date,
    fault_resolved_date,
    staff_trained,
    training_record_available,
    risk_level,
    action_required,
    review_date,
    assessor_name,
    notes,
    created_at,
    updated_at,
    -- Calculate if tests are expired
    (loler_test_expiry < CURRENT_DATE AND loler_test_expiry IS NOT NULL) AS loler_expired,
    (pat_test_expiry < CURRENT_DATE AND pat_test_expiry IS NOT NULL) AS pat_expired,
    -- Calculate days until next service
    (next_service_due_date - CURRENT_DATE) AS days_until_service,
    -- Calculate if service is due
    (next_service_due_date <= CURRENT_DATE AND next_service_due_date IS NOT NULL) AS service_due,
    -- Calculate if review is due
    (review_date <= CURRENT_DATE AND review_date IS NOT NULL) AS review_due,
    -- Calculate overall equipment safety
    is_equipment_safe(
        (loler_test_expiry < CURRENT_DATE AND loler_test_expiry IS NOT NULL),
        (pat_test_expiry < CURRENT_DATE AND pat_test_expiry IS NOT NULL),
        (reported_faults = 'major'),
        equipment_condition
    ) AS is_safe_for_use
FROM equipment_register_risk_assessments
ORDER BY equipment_name, equipment_category;

-- Grant permissions on the view
GRANT SELECT ON equipment_status_dashboard TO authenticated;