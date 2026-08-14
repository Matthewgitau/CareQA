-- Create fire_hazard_risk_assessments table
CREATE TABLE fire_hazard_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id),
    assessment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    assessor_name TEXT,
    
    -- Section 1: Fire Detection & Warning (6 fields)
    smoke_detectors_present TEXT CHECK (smoke_detectors_present IN ('yes', 'no', 'partial')),
    smoke_detector_test_date DATE,
    heat_detectors_in_kitchens BOOLEAN,
    fire_alarm_system_type TEXT CHECK (fire_alarm_system_type IN ('manual', 'automatic', 'none')),
    fire_alarm_test_date DATE,
    fire_alarm_weekly_test_recorded BOOLEAN,
    
    -- Section 2: Fire Fighting Equipment (8 fields)
    fire_extinguisher_types TEXT[], -- Array of: water, CO2, foam, powder, wet_chemical
    fire_extinguisher_locations_documented BOOLEAN,
    fire_extinguisher_service_date DATE,
    fire_extinguisher_next_service_due DATE,
    fire_blanket_in_kitchen BOOLEAN,
    fire_blanket_service_date DATE,
    fire_hose_reel_present BOOLEAN,
    equipment_inspected_monthly BOOLEAN,
    
    -- Section 3: Means of Escape (8 fields)
    emergency_exits_clearly_marked BOOLEAN,
    exit_doors_open_easily BOOLEAN,
    exit_routes_unobstructed BOOLEAN,
    emergency_lighting_working BOOLEAN,
    emergency_lighting_test_date DATE,
    fire_exit_signs_illuminated BOOLEAN,
    final_exits_open_outward BOOLEAN,
    escape_routes_suitable_for_mobility_aids BOOLEAN,
    
    -- Section 4: Fire Doors & Compartmentation (6 fields)
    fire_doors_self_closing BOOLEAN,
    fire_door_gaps_less_than_4mm BOOLEAN,
    fire_door_seals_intact BOOLEAN,
    fire_door_inspection_date DATE,
    compartment_walls_intact BOOLEAN,
    ceiling_floor_penetrations_sealed BOOLEAN,
    
    -- Section 5: PEEPs & Evacuation (8 fields)
    peeps_in_place_for_all_service_users TEXT CHECK (peeps_in_place_for_all_service_users IN ('yes', 'no', 'partial')),
    peeps_reviewed_annually BOOLEAN,
    staff_know_peeps_for_assigned_service_users BOOLEAN,
    evacuation_plan_displayed BOOLEAN,
    evacuation_plan_rehearsed BOOLEAN,
    visitors_signed_in_out BOOLEAN,
    night_staff_numbers_adequate BOOLEAN,
    disabled_refuge_points_identified BOOLEAN,
    
    -- Section 6: Training & Drills (6 fields)
    staff_fire_training_completed BOOLEAN,
    staff_training_date DATE,
    staff_training_next_due DATE,
    fire_drill_conducted BOOLEAN,
    fire_drill_date DATE,
    fire_drill_frequency TEXT CHECK (fire_drill_frequency IN ('monthly', 'quarterly', 'annually')),
    
    -- Section 7: Management & Records (6 fields)
    fire_log_book_maintained BOOLEAN,
    fire_risk_assessment_review_date DATE,
    fire_warden_appointed BOOLEAN,
    fire_warden_name TEXT,
    weekly_checks_recorded BOOLEAN,
    monthly_checks_recorded BOOLEAN,
    
    -- Section 8: Kitchen & High Risk Areas (4 fields)
    kitchen_extractor_hood_cleaned BOOLEAN,
    extractor_cleaning_date DATE,
    cooker_isolator_switch_accessible BOOLEAN,
    laundry_dryer_lint_filter_cleaned BOOLEAN,
    
    -- Section 9: Electrical Fire Risks (4 fields)
    pat_testing_up_to_date BOOLEAN,
    pat_test_expiry_date DATE,
    electrical_equipment_not_overloaded BOOLEAN,
    charging_devices_on_non_flammable_surface BOOLEAN,
    
    -- Section 10: Arson Prevention (4 fields)
    external_waste_bins_away_from_building BOOLEAN,
    bin_stores_locked BOOLEAN,
    external_lighting_working BOOLEAN,
    intruder_alarm_working BOOLEAN,
    
    -- Calculated fields
    total_score INTEGER DEFAULT 0,
    risk_level TEXT CHECK (risk_level IN ('high', 'medium', 'low', 'excellent')),
    action_required TEXT,
    
    -- Action plan
    action_items JSONB DEFAULT '[]', -- Array of action items
    responsible_person TEXT,
    completion_deadline DATE,
    review_date DATE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id),
    updated_by UUID REFERENCES profiles(id)
);

-- Create index for better query performance
CREATE INDEX idx_fire_hazard_assessments_service_user ON fire_hazard_risk_assessments(service_user_id);
CREATE INDEX idx_fire_hazard_assessments_date ON fire_hazard_risk_assessments(assessment_date);
CREATE INDEX idx_fire_hazard_assessments_risk_level ON fire_hazard_risk_assessments(risk_level);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_fire_hazard_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_fire_hazard_risk_assessments_updated_at
    BEFORE UPDATE ON fire_hazard_risk_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_fire_hazard_updated_at();

-- Create function to calculate fire hazard risk score and level
CREATE OR REPLACE FUNCTION calculate_fire_hazard_risk()
RETURNS TRIGGER AS $$
DECLARE
    score INTEGER := 0;
    action_text TEXT := '';
BEGIN
    -- Section 1: Fire Detection & Warning (6 fields)
    IF NEW.smoke_detectors_present = 'yes' THEN score := score + 1; END IF;
    IF NEW.smoke_detector_test_date >= CURRENT_DATE - INTERVAL '6 months' THEN score := score + 1; END IF;
    IF NEW.heat_detectors_in_kitchens THEN score := score + 1; END IF;
    IF NEW.fire_alarm_system_type IN ('manual', 'automatic') THEN score := score + 1; END IF;
    IF NEW.fire_alarm_test_date >= CURRENT_DATE - INTERVAL '1 week' THEN score := score + 1; END IF;
    IF NEW.fire_alarm_weekly_test_recorded THEN score := score + 1; END IF;
    
    -- Section 2: Fire Fighting Equipment (8 fields)
    IF array_length(NEW.fire_extinguisher_types, 1) > 0 THEN score := score + 1; END IF;
    IF NEW.fire_extinguisher_locations_documented THEN score := score + 1; END IF;
    IF NEW.fire_extinguisher_service_date >= CURRENT_DATE - INTERVAL '1 year' THEN score := score + 1; END IF;
    IF NEW.fire_extinguisher_next_service_due > CURRENT_DATE THEN score := score + 1; END IF;
    IF NEW.fire_blanket_in_kitchen THEN score := score + 1; END IF;
    IF NEW.fire_blanket_service_date >= CURRENT_DATE - INTERVAL '1 year' THEN score := score + 1; END IF;
    IF NEW.fire_hose_reel_present THEN score := score + 1; END IF;
    IF NEW.equipment_inspected_monthly THEN score := score + 1; END IF;
    
    -- Section 3: Means of Escape (8 fields)
    IF NEW.emergency_exits_clearly_marked THEN score := score + 1; END IF;
    IF NEW.exit_doors_open_easily THEN score := score + 1; END IF;
    IF NEW.exit_routes_unobstructed THEN score := score + 1; END IF;
    IF NEW.emergency_lighting_working THEN score := score + 1; END IF;
    IF NEW.emergency_lighting_test_date >= CURRENT_DATE - INTERVAL '1 month' THEN score := score + 1; END IF;
    IF NEW.fire_exit_signs_illuminated THEN score := score + 1; END IF;
    IF NEW.final_exits_open_outward THEN score := score + 1; END IF;
    IF NEW.escape_routes_suitable_for_mobility_aids THEN score := score + 1; END IF;
    
    -- Section 4: Fire Doors & Compartmentation (6 fields)
    IF NEW.fire_doors_self_closing THEN score := score + 1; END IF;
    IF NEW.fire_door_gaps_less_than_4mm THEN score := score + 1; END IF;
    IF NEW.fire_door_seals_intact THEN score := score + 1; END IF;
    IF NEW.fire_door_inspection_date >= CURRENT_DATE - INTERVAL '6 months' THEN score := score + 1; END IF;
    IF NEW.compartment_walls_intact THEN score := score + 1; END IF;
    IF NEW.ceiling_floor_penetrations_sealed THEN score := score + 1; END IF;
    
    -- Section 5: PEEPs & Evacuation (8 fields)
    IF NEW.peeps_in_place_for_all_service_users = 'yes' THEN score := score + 1; END IF;
    IF NEW.peeps_reviewed_annually THEN score := score + 1; END IF;
    IF NEW.staff_know_peeps_for_assigned_service_users THEN score := score + 1; END IF;
    IF NEW.evacuation_plan_displayed THEN score := score + 1; END IF;
    IF NEW.evacuation_plan_rehearsed THEN score := score + 1; END IF;
    IF NEW.visitors_signed_in_out THEN score := score + 1; END IF;
    IF NEW.night_staff_numbers_adequate THEN score := score + 1; END IF;
    IF NEW.disabled_refuge_points_identified THEN score := score + 1; END IF;
    
    -- Section 6: Training & Drills (6 fields)
    IF NEW.staff_fire_training_completed THEN score := score + 1; END IF;
    IF NEW.staff_training_date >= CURRENT_DATE - INTERVAL '1 year' THEN score := score + 1; END IF;
    IF NEW.staff_training_next_due > CURRENT_DATE THEN score := score + 1; END IF;
    IF NEW.fire_drill_conducted THEN score := score + 1; END IF;
    IF NEW.fire_drill_date >= CURRENT_DATE - INTERVAL '3 months' THEN score := score + 1; END IF;
    IF NEW.fire_drill_frequency IN ('monthly', 'quarterly') THEN score := score + 1; END IF;
    
    -- Section 7: Management & Records (6 fields)
    IF NEW.fire_log_book_maintained THEN score := score + 1; END IF;
    IF NEW.fire_risk_assessment_review_date >= CURRENT_DATE - INTERVAL '1 year' THEN score := score + 1; END IF;
    IF NEW.fire_warden_appointed THEN score := score + 1; END IF;
    IF NEW.fire_warden_name IS NOT NULL THEN score := score + 1; END IF;
    IF NEW.weekly_checks_recorded THEN score := score + 1; END IF;
    IF NEW.monthly_checks_recorded THEN score := score + 1; END IF;
    
    -- Section 8: Kitchen & High Risk Areas (4 fields)
    IF NEW.kitchen_extractor_hood_cleaned THEN score := score + 1; END IF;
    IF NEW.extractor_cleaning_date >= CURRENT_DATE - INTERVAL '3 months' THEN score := score + 1; END IF;
    IF NEW.cooker_isolator_switch_accessible THEN score := score + 1; END IF;
    IF NEW.laundry_dryer_lint_filter_cleaned THEN score := score + 1; END IF;
    
    -- Section 9: Electrical Fire Risks (4 fields)
    IF NEW.pat_testing_up_to_date THEN score := score + 1; END IF;
    IF NEW.pat_test_expiry_date > CURRENT_DATE THEN score := score + 1; END IF;
    IF NEW.electrical_equipment_not_overloaded THEN score := score + 1; END IF;
    IF NEW.charging_devices_on_non_flammable_surface THEN score := score + 1; END IF;
    
    -- Section 10: Arson Prevention (4 fields)
    IF NEW.external_waste_bins_away_from_building THEN score := score + 1; END IF;
    IF NEW.bin_stores_locked THEN score := score + 1; END IF;
    IF NEW.external_lighting_working THEN score := score + 1; END IF;
    IF NEW.intruder_alarm_working THEN score := score + 1; END IF;
    
    -- Set calculated fields
    NEW.total_score := score;
    
    -- Determine risk level
    IF score <= 30 THEN
        NEW.risk_level := 'high';
        action_text := 'IMMEDIATE ACTION REQUIRED: High fire risk identified. Review and address all non-compliant items immediately.';
    ELSIF score <= 45 THEN
        NEW.risk_level := 'medium';
        action_text := 'IMPROVEMENTS NEEDED: Medium fire risk identified. Address non-compliant items within 30 days.';
    ELSIF score <= 55 THEN
        NEW.risk_level := 'low';
        action_text := 'MONITOR: Low fire risk identified. Continue monitoring and maintain current standards.';
    ELSE
        NEW.risk_level := 'excellent';
        action_text := 'EXCELLENT: Fire safety standards are excellent. Maintain current practices.';
    END IF;
    
    NEW.action_required := action_text;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to calculate fire hazard risk
CREATE TRIGGER calculate_fire_hazard_risk_trigger
    BEFORE INSERT OR UPDATE ON fire_hazard_risk_assessments
    FOR EACH ROW
    EXECUTE FUNCTION calculate_fire_hazard_risk();

-- Create view for fire hazard dashboard
CREATE VIEW fire_hazard_dashboard AS
SELECT 
    id,
    service_user_id,
    assessment_date,
    assessor_name,
    total_score,
    risk_level,
    action_required,
    
    -- Section 1: Fire Detection & Warning
    smoke_detectors_present,
    smoke_detector_test_date,
    heat_detectors_in_kitchens,
    fire_alarm_system_type,
    fire_alarm_test_date,
    fire_alarm_weekly_test_recorded,
    
    -- Section 2: Fire Fighting Equipment
    fire_extinguisher_types,
    fire_extinguisher_locations_documented,
    fire_extinguisher_service_date,
    fire_extinguisher_next_service_due,
    fire_blanket_in_kitchen,
    fire_blanket_service_date,
    fire_hose_reel_present,
    equipment_inspected_monthly,
    
    -- Section 3: Means of Escape
    emergency_exits_clearly_marked,
    exit_doors_open_easily,
    exit_routes_unobstructed,
    emergency_lighting_working,
    emergency_lighting_test_date,
    fire_exit_signs_illuminated,
    final_exits_open_outward,
    escape_routes_suitable_for_mobility_aids,
    
    -- Section 4: Fire Doors & Compartmentation
    fire_doors_self_closing,
    fire_door_gaps_less_than_4mm,
    fire_door_seals_intact,
    fire_door_inspection_date,
    compartment_walls_intact,
    ceiling_floor_penetrations_sealed,
    
    -- Section 5: PEEPs & Evacuation
    peeps_in_place_for_all_service_users,
    peeps_reviewed_annually,
    staff_know_peeps_for_assigned_service_users,
    evacuation_plan_displayed,
    evacuation_plan_rehearsed,
    visitors_signed_in_out,
    night_staff_numbers_adequate,
    disabled_refuge_points_identified,
    
    -- Section 6: Training & Drills
    staff_fire_training_completed,
    staff_training_date,
    staff_training_next_due,
    fire_drill_conducted,
    fire_drill_date,
    fire_drill_frequency,
    
    -- Section 7: Management & Records
    fire_log_book_maintained,
    fire_risk_assessment_review_date,
    fire_warden_appointed,
    fire_warden_name,
    weekly_checks_recorded,
    monthly_checks_recorded,
    
    -- Section 8: Kitchen & High Risk Areas
    kitchen_extractor_hood_cleaned,
    extractor_cleaning_date,
    cooker_isolator_switch_accessible,
    laundry_dryer_lint_filter_cleaned,
    
    -- Section 9: Electrical Fire Risks
    pat_testing_up_to_date,
    pat_test_expiry_date,
    electrical_equipment_not_overloaded,
    charging_devices_on_non_flammable_surface,
    
    -- Section 10: Arson Prevention
    external_waste_bins_away_from_building,
    bin_stores_locked,
    external_lighting_working,
    intruder_alarm_working,
    
    -- Expiry status indicators
    CASE WHEN fire_extinguisher_next_service_due <= CURRENT_DATE + INTERVAL '30 days' THEN true ELSE false END AS extinguisher_service_due_soon,
    CASE WHEN fire_blanket_service_date <= CURRENT_DATE + INTERVAL '30 days' THEN true ELSE false END AS blanket_service_due_soon,
    CASE WHEN staff_training_next_due <= CURRENT_DATE + INTERVAL '30 days' THEN true ELSE false END AS training_due_soon,
    CASE WHEN pat_test_expiry_date <= CURRENT_DATE + INTERVAL '30 days' THEN true ELSE false END AS pat_test_due_soon,
    CASE WHEN fire_alarm_test_date <= CURRENT_DATE - INTERVAL '1 week' THEN true ELSE false END AS alarm_test_overdue,
    CASE WHEN emergency_lighting_test_date <= CURRENT_DATE - INTERVAL '1 month' THEN true ELSE false END AS emergency_lighting_test_overdue,
    
    created_at,
    updated_at
FROM fire_hazard_risk_assessments;

-- Create policies for row-level security
ALTER TABLE fire_hazard_risk_assessments ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own assessments
CREATE POLICY "Users can view own fire hazard assessments" ON fire_hazard_risk_assessments
    FOR SELECT USING (
        auth.uid() = created_by OR
        auth.uid() IN (
            SELECT carer_id FROM service_user_carers 
            WHERE service_user_carers.service_user_id = fire_hazard_risk_assessments.service_user_id
        )
    );

-- Allow authenticated users to insert assessments
CREATE POLICY "Users can insert fire hazard assessments" ON fire_hazard_risk_assessments
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Allow authenticated users to update their own assessments
CREATE POLICY "Users can update own fire hazard assessments" ON fire_hazard_risk_assessments
    FOR UPDATE USING (auth.uid() = created_by);

-- Allow authenticated users to delete their own assessments
CREATE POLICY "Users can delete own fire hazard assessments" ON fire_hazard_risk_assessments
    FOR DELETE USING (auth.uid() = created_by);

-- Enable RLS on dashboard view
ALTER VIEW fire_hazard_dashboard SET (security_barrier = true);