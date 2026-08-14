-- Compliance Rules Engine Function
-- This function implements the main compliance checking logic

CREATE OR REPLACE FUNCTION check_compliance_rules()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
  carer_record RECORD;
  visit_record RECORD;
  teaching_content TEXT;
  rule_config JSONB;
  severity_level TEXT;
  threshold_diff INTEGER;
  meds_due INTEGER;
  meds_given INTEGER;
  flags_count INTEGER;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record FROM settings WHERE id = 1;
  
  -- Get carer info
  SELECT * INTO carer_record FROM carers WHERE id = NEW.carer_id;
  
  -- Build visit record with all context
  SELECT 
    v.*,
    s.service_user_id,
    s.scheduled_date,
    s.start_time,
    s.end_time,
    su.name as service_user_name,
    su.care_plan
  INTO visit_record
  FROM visits v
  JOIN shifts s ON v.shift_id = s.id
  JOIN service_users su ON s.service_user_id = su.id
  WHERE v.id = NEW.id;
  
  -- RULE 1: Duration Compliance
  -- Check if duration compliance rule is enabled
  SELECT rule_config INTO rule_config 
  FROM compliance_rules 
  WHERE rule_id = 'DURATION_COMPLIANCE' AND enabled = true;
  
  IF rule_config IS NOT NULL AND NEW.compliance_percentage < (rule_config->>'min_percentage')::INTEGER THEN
    -- Calculate severity based on how bad it is
    threshold_diff := (rule_config->>'min_percentage')::INTEGER - NEW.compliance_percentage;
    
    severity_level := CASE 
      WHEN threshold_diff > (rule_config->>'critical_threshold')::INTEGER THEN 'CRITICAL'
      WHEN threshold_diff > (rule_config->>'warning_threshold')::INTEGER THEN 'WARNING'
      ELSE 'INFO'
    END;
    
    -- Check if flag already exists for this visit and rule
    IF NOT EXISTS (
      SELECT 1 FROM compliance_flags 
      WHERE visit_id = NEW.id 
      AND rule_id LIKE 'DURATION_%'
    ) THEN
      INSERT INTO compliance_flags (
        visit_id, carer_id, shift_id, rule_id, rule_name,
        severity, message, regulation_reference, suggested_action
      ) VALUES (
        NEW.id, NEW.carer_id, NEW.shift_id,
        'DURATION_' || threshold_diff,
        'Visit Duration Compliance',
        severity_level,
        format('Visit was only %s%% of scheduled %s minutes (requires %s%%)',
               NEW.compliance_percentage,
               EXTRACT(EPOCH FROM (visit_record.end_time - visit_record.start_time))/60,
               rule_config->>'min_percentage'),
        'CQC Regulation 12 - Safe Care and Treatment',
        'Review visit schedule and discuss with carer. Consider if service user needs increased support.'
      );
      
      -- Create teaching moment
      teaching_content := format(
        'Your visit to %s was shorter than planned. This is important because:
        
        1. The care plan requires %s minutes to deliver all necessary support
        2. Short visits can lead to missed medications or care tasks
        3. Service users may feel rushed or unsupported
        4. CQC requires evidence of sufficient time for care delivery
        
        Tips for next time:
        • Review the care plan before arriving
        • Prioritize essential tasks first
        • If running short, notify the office immediately
        • Document any reasons for shortened visits',
        visit_record.service_user_name,
        EXTRACT(EPOCH FROM (visit_record.end_time - visit_record.start_time))/60
      );
      
      INSERT INTO teaching_moments (
        user_id, trigger_rule_id, title, content, policy_url
      ) VALUES (
        NEW.carer_id,
        'DURATION_' || threshold_diff,
        'Understanding Visit Duration Requirements',
        teaching_content,
        'https://yourplatform.com/policies/visit-durations'
      );
    END IF;
  END IF;
  
  -- RULE 2: Medication Compliance
  -- Check if medication compliance rule is enabled
  SELECT rule_config INTO rule_config 
  FROM compliance_rules 
  WHERE rule_id = 'MEDICATION_COMPLIANCE' AND enabled = true;
  
  IF rule_config IS NOT NULL AND 
     (visit_record.care_plan->>'medications' IS NOT NULL AND 
      jsonb_array_length(visit_record.care_plan->'medications') > 0) THEN
    
    meds_due := jsonb_array_length(visit_record.care_plan->'medications');
    meds_given := 0;
    
    -- Count medications given from structured_notes
    IF NEW.structured_notes ? 'medications_given' THEN
      meds_given := jsonb_array_length(NEW.structured_notes->'medications_given');
    END IF;
    
    IF meds_given < meds_due THEN
      -- Check if flag already exists for this visit and rule
      IF NOT EXISTS (
        SELECT 1 FROM compliance_flags 
        WHERE visit_id = NEW.id 
        AND rule_id LIKE 'MEDS_MISSED_%'
      ) THEN
        INSERT INTO compliance_flags (
          visit_id, carer_id, shift_id, rule_id, rule_name,
          severity, message, regulation_reference, suggested_action
        ) VALUES (
          NEW.id, NEW.carer_id, NEW.shift_id,
          'MEDS_MISSED_' || (meds_due - meds_given),
          'Medication Administration',
          CASE WHEN (meds_due - meds_given) > 2 THEN 'CRITICAL' ELSE 'WARNING' END,
          format('%s of %s medications were not recorded as given',
                 meds_due - meds_given, meds_due),
          'CQC Regulation 13 - Safeguarding Service Users from Abuse',
          'Review medication administration records and retrain on MAR chart completion'
        );
        
        -- Check pattern (3+ missed meds in 7 days)
        SELECT COUNT(*) INTO flags_count FROM compliance_flags 
        WHERE carer_id = NEW.carer_id 
        AND rule_id LIKE 'MEDS_MISSED_%'
        AND created_at > NOW() - INTERVAL '7 days';
        
        IF flags_count >= 3 THEN
          INSERT INTO notifications (user_id, type, title, body, data)
          VALUES (
            (SELECT manager_id FROM carers WHERE id = NEW.carer_id),
            'escalation',
            '⚠️ Medication Compliance Alert',
            format('Carer has missed %s medications in the past 7 days. Review required.',
                   flags_count),
            jsonb_build_object('carer_id', NEW.carer_id, 'severity', 'high')
          );
        END IF;
      END IF;
    END IF;
  END IF;
  
  -- RULE 3: Incident Reporting Compliance
  -- Check if incident reporting rule is enabled
  SELECT rule_config INTO rule_config 
  FROM compliance_rules 
  WHERE rule_id = 'INCIDENT_REPORTING' AND enabled = true;
  
  IF rule_config IS NOT NULL AND 
     NEW.structured_notes->>'incident_occurred' = 'true' AND 
     (NEW.structured_notes->>'incident_type' IS NULL OR 
      NEW.structured_notes->>'incident_type' = '') THEN
    
    -- Check if flag already exists for this visit and rule
    IF NOT EXISTS (
      SELECT 1 FROM compliance_flags 
      WHERE visit_id = NEW.id 
      AND rule_id = 'INCIDENT_INCOMPLETE'
    ) THEN
      INSERT INTO compliance_flags (
        visit_id, carer_id, shift_id, rule_id, rule_name,
        severity, message, regulation_reference, suggested_action
      ) VALUES (
        NEW.id, NEW.carer_id, NEW.shift_id,
        'INCIDENT_INCOMPLETE',
        'Incident Reporting',
        'WARNING',
        'Incident reported but no incident type recorded',
        'CQC Regulation 18 - Notification of Incidents',
        'Complete incident report immediately including type, severity, and actions taken'
      );
    END IF;
  END IF;
  
  -- RULE 4: Family Communication Compliance
  -- Check if family communication rule is enabled
  SELECT rule_config INTO rule_config 
  FROM compliance_rules 
  WHERE rule_id = 'FAMILY_COMMUNICATION' AND enabled = true;
  
  IF rule_config IS NOT NULL AND 
     (visit_record.care_plan->>'family_updates_required')::boolean = true AND
     NEW.structured_notes->>'family_updated' = 'false' THEN
    
    -- Check if flag already exists for this visit and rule
    IF NOT EXISTS (
      SELECT 1 FROM compliance_flags 
      WHERE visit_id = NEW.id 
      AND rule_id = 'FAMILY_COMMS'
    ) THEN
      INSERT INTO compliance_flags (
        visit_id, carer_id, shift_id, rule_id, rule_name,
        severity, message, regulation_reference, suggested_action
      ) VALUES (
        NEW.id, NEW.carer_id, NEW.shift_id,
        'FAMILY_COMMS',
        'Family Communication',
        'INFO',
        'Family update was required but not marked as completed',
        'CQC Regulation 9 - Person-centred Care',
        'Consider if family should be notified of today''s visit'
      );
    END IF;
  END IF;
  
  -- RULE 5: Document Expiry Check (runs on login/shift start, not visit completion)
  -- This is handled by a separate scheduled job
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach to visits table
CREATE TRIGGER compliance_check_trigger
  AFTER INSERT OR UPDATE ON visits
  FOR EACH ROW
  EXECUTE FUNCTION check_compliance_rules();

-- Function to check document expiry compliance
CREATE OR REPLACE FUNCTION check_document_compliance()
RETURNS void AS $$
DECLARE
  carer_record RECORD;
  doc_record RECORD;
  settings_record RECORD;
  warning_days INTEGER;
BEGIN
  -- Get settings
  SELECT * INTO settings_record FROM settings WHERE id = 1;
  
  -- Get document expiry settings
  SELECT (compliance_settings->'documentation'->>'dbs_warning_days')::INTEGER INTO warning_days
  FROM settings WHERE id = 1;
  
  -- Check all active carers
  FOR carer_record IN 
    SELECT * FROM carers WHERE is_active = true
  LOOP
    -- Check DBS expiry
    IF carer_record.dbs_expiry_date IS NOT NULL THEN
      IF carer_record.dbs_expiry_date <= CURRENT_DATE + (warning_days || ' days')::INTERVAL THEN
        -- Check if flag already exists
        IF NOT EXISTS (
          SELECT 1 FROM compliance_flags 
          WHERE carer_id = carer_record.id 
          AND rule_id = 'DBS_EXPIRY'
          AND status = 'active'
        ) THEN
          INSERT INTO compliance_flags (
            carer_id, rule_id, rule_name, severity, message,
            regulation_reference, suggested_action
          ) VALUES (
            carer_record.id,
            'DBS_EXPIRY',
            'DBS Certificate Expiry',
            CASE WHEN carer_record.dbs_expiry_date <= CURRENT_DATE THEN 'CRITICAL' ELSE 'WARNING' END,
            format('DBS certificate expires on %s', carer_record.dbs_expiry_date),
            'CQC Regulation 11 - Fit and Proper Persons to Carry on the Service',
            'Renew DBS certificate immediately. Carer cannot work without valid DBS.'
          );
        END IF;
      END IF;
    END IF;
    
    -- Check ID document expiry
    IF carer_record.id_expiry_date IS NOT NULL THEN
      IF carer_record.id_expiry_date <= CURRENT_DATE + (warning_days || ' days')::INTERVAL THEN
        IF NOT EXISTS (
          SELECT 1 FROM compliance_flags 
          WHERE carer_id = carer_record.id 
          AND rule_id = 'ID_EXPIRY'
          AND status = 'active'
        ) THEN
          INSERT INTO compliance_flags (
            carer_id, rule_id, rule_name, severity, message,
            regulation_reference, suggested_action
          ) VALUES (
            carer_record.id,
            'ID_EXPIRY',
            'ID Document Expiry',
            CASE WHEN carer_record.id_expiry_date <= CURRENT_DATE THEN 'CRITICAL' ELSE 'WARNING' END,
            format('ID document expires on %s', carer_record.id_expiry_date),
            'CQC Regulation 11 - Fit and Proper Persons to Carry on the Service',
            'Update ID document. Carer cannot work without valid ID.'
          );
        END IF;
      END IF;
    END IF;
    
    -- Check right to work expiry
    IF carer_record.right_to_work_expiry IS NOT NULL THEN
      IF carer_record.right_to_work_expiry <= CURRENT_DATE + (warning_days || ' days')::INTERVAL THEN
        IF NOT EXISTS (
          SELECT 1 FROM compliance_flags 
          WHERE carer_id = carer_record.id 
          AND rule_id = 'RIGHT_TO_WORK_EXPIRY'
          AND status = 'active'
        ) THEN
          INSERT INTO compliance_flags (
            carer_id, rule_id, rule_name, severity, message,
            regulation_reference, suggested_action
          ) VALUES (
            carer_record.id,
            'RIGHT_TO_WORK_EXPIRY',
            'Right to Work Expiry',
            CASE WHEN carer_record.right_to_work_expiry <= CURRENT_DATE THEN 'CRITICAL' ELSE 'WARNING' END,
            format('Right to work expires on %s', carer_record.right_to_work_expiry),
            'UK Immigration Law',
            'Update right to work documentation immediately.'
          );
        END IF;
      END IF;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule document compliance check daily at 6 AM
SELECT cron.schedule(
  'daily-document-compliance',
  '0 6 * * *',
  'SELECT check_document_compliance();'
);

-- Function to calculate daily compliance scores
CREATE OR REPLACE FUNCTION calculate_daily_compliance_scores()
RETURNS void AS $$
DECLARE
  carer_record RECORD;
  yesterday DATE := CURRENT_DATE - 1;
BEGIN
  FOR carer_record IN SELECT id FROM carers WHERE is_active = true
  LOOP
    -- Calculate compliance scores for yesterday
    INSERT INTO compliance_scores (
      carer_id,
      score_date,
      overall_score,
      duration_compliance,
      documentation_compliance,
      medication_compliance,
      incident_reporting_compliance,
      flags_count
    )
    SELECT
      carer_record.id,
      yesterday,
      -- Calculate overall score (weighted average)
      (
        COALESCE(AVG(CASE WHEN v.flagged = false THEN 100 ELSE 0 END), 0) * 0.4 +
        COALESCE(AVG(CASE WHEN d.expiry_date > CURRENT_DATE THEN 100 ELSE 0 END), 0) * 0.3 +
        COALESCE(AVG(CASE WHEN (v.structured_notes->>'medication_given')::boolean = true THEN 100 ELSE 0 END), 0) * 0.3
      ),
      -- Individual components
      COALESCE(AVG(CASE WHEN v.flagged = false THEN 100 ELSE 0 END), 0),
      COALESCE(AVG(CASE WHEN d.expiry_date > CURRENT_DATE THEN 100 ELSE 0 END), 0),
      COALESCE(AVG(CASE WHEN (v.structured_notes->>'medication_given')::boolean = true THEN 100 ELSE 0 END), 0),
      COALESCE(AVG(CASE WHEN v.structured_notes->>'incident_occurred' = 'true' THEN 100 ELSE 0 END), 0),
      COUNT(cf.id)
    FROM visits v
    LEFT JOIN shifts s ON v.shift_id = s.id
    LEFT JOIN documents d ON d.carer_id = carer_record.id
    LEFT JOIN compliance_flags cf ON cf.carer_id = carer_record.id 
      AND DATE(cf.created_at) = yesterday
    WHERE s.carer_id = carer_record.id
      AND DATE(s.scheduled_date) = yesterday
    GROUP BY carer_record.id
    ON CONFLICT (carer_id, score_date) 
    DO UPDATE SET
      overall_score = EXCLUDED.overall_score,
      duration_compliance = EXCLUDED.duration_compliance,
      documentation_compliance = EXCLUDED.documentation_compliance,
      medication_compliance = EXCLUDED.medication_compliance,
      incident_reporting_compliance = EXCLUDED.incident_reporting_compliance,
      flags_count = EXCLUDED.flags_count;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule daily compliance scoring at 2 AM
SELECT cron.schedule(
  'daily-compliance-scores',
  '0 2 * * *',
  'SELECT calculate_daily_compliance_scores();'
);

-- Function to generate regulatory reports
CREATE OR REPLACE FUNCTION generate_regulatory_report(
  report_type_param TEXT,
  period_start DATE,
  period_end DATE,
  generated_by_param UUID
)
RETURNS UUID AS $$
DECLARE
  report_id UUID;
  report_data JSONB;
BEGIN
  -- Calculate report data
  SELECT jsonb_build_object(
    'period_start', period_start,
    'period_end', period_end,
    'total_visits', COUNT(v.id),
    'flagged_visits', COUNT(cf.id),
    'compliance_rate', 
      CASE WHEN COUNT(v.id) > 0 
           THEN ROUND((COUNT(v.id) - COUNT(cf.id)) * 100.0 / COUNT(v.id), 2)
           ELSE 0 
      END,
    'average_duration_compliance', AVG(v.compliance_percentage),
    'medication_errors', COUNT(CASE WHEN cf.rule_id LIKE 'MEDS_%' THEN 1 END),
    'duration_issues', COUNT(CASE WHEN cf.rule_id LIKE 'DURATION_%' THEN 1 END),
    'incident_reporting_issues', COUNT(CASE WHEN cf.rule_id = 'INCIDENT_INCOMPLETE' THEN 1 END),
    'carer_performance', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'carer_id', c.id,
          'name', p.full_name,
          'total_visits', COUNT(v.id),
          'flags', COUNT(cf.id),
          'score', AVG(cs.overall_score)
        )
      )
      FROM carers c
      JOIN profiles p ON c.id = p.id
      LEFT JOIN visits v ON v.carer_id = c.id AND DATE(v.created_at) BETWEEN period_start AND period_end
      LEFT JOIN compliance_flags cf ON cf.carer_id = c.id AND DATE(cf.created_at) BETWEEN period_start AND period_end
      LEFT JOIN compliance_scores cs ON cs.carer_id = c.id AND cs.score_date BETWEEN period_start AND period_end
      GROUP BY c.id, p.full_name
    ),
    'regulation_compliance', jsonb_build_object(
      'cqc_reg_12', 
        CASE WHEN COUNT(CASE WHEN cf.regulation_reference = 'CQC Regulation 12 - Safe Care and Treatment' THEN 1 END) = 0 
             THEN true ELSE false END,
      'cqc_reg_13',
        CASE WHEN COUNT(CASE WHEN cf.regulation_reference = 'CQC Regulation 13 - Safeguarding Service Users from Abuse' THEN 1 END) = 0 
             THEN true ELSE false END,
      'cqc_reg_18',
        CASE WHEN COUNT(CASE WHEN cf.regulation_reference = 'CQC Regulation 18 - Notification of Incidents' THEN 1 END) = 0 
             THEN true ELSE false END
    )
  ) INTO report_data
  FROM visits v
  LEFT JOIN compliance_flags cf ON cf.visit_id = v.id AND DATE(cf.created_at) BETWEEN period_start AND period_end
  WHERE DATE(v.created_at) BETWEEN period_start AND period_end;
  
  -- Insert report
  INSERT INTO regulatory_reports (
    report_type, reporting_period_start, reporting_period_end, 
    report_data, generated_by
  ) VALUES (
    report_type_param, period_start, period_end, report_data, generated_by_param
  ) RETURNING id INTO report_id;
  
  RETURN report_id;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA cron TO postgres;
GRANT SELECT ON cron.job TO postgres;
GRANT INSERT, UPDATE, DELETE ON cron.job TO postgres;
GRANT EXECUTE ON FUNCTION cron.schedule(text, text, text) TO postgres;
GRANT EXECUTE ON FUNCTION cron.unschedule(text) TO postgres;