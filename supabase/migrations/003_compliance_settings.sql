-- Update settings table with comprehensive compliance configuration

-- Add compliance_settings column to settings table if it doesn't exist
ALTER TABLE settings ADD COLUMN IF NOT EXISTS compliance_settings JSONB DEFAULT '{
  "duration": {
    "min_percentage": 85,
    "warning_threshold": 10,
    "critical_threshold": 20,
    "escalation_days": 7,
    "escalation_count": 3
  },
  "medication": {
    "require_confirmation": true,
    "require_witness_for_controlled": true,
    "max_missed_per_week": 2,
    "escalation_threshold": 3
  },
  "documentation": {
    "dbs_warning_days": 30,
    "id_warning_days": 30,
    "training_warning_days": 30,
    "right_to_work_warning_days": 30
  },
  "incident_reporting": {
    "require_type": true,
    "require_severity": true,
    "require_action": true,
    "escalation_threshold_hours": 24
  },
  "family_communication": {
    "require_updates": true,
    "update_methods": ["app", "email", "sms"],
    "default_frequency": "daily"
  },
  "regulatory_bodies": {
    "cqc": {
      "notification_threshold_hours": 24,
      "serious_incident_threshold": "high"
    },
    "ofsted": {
      "notification_threshold_hours": 24,
      "serious_incident_threshold": "critical"
    }
  },
  "scoring_weights": {
    "duration": 0.4,
    "documentation": 0.3,
    "medication": 0.3
  },
  "teaching_moments": {
    "auto_create": true,
    "require_acknowledgment": true,
    "max_pending": 5
  },
  "escalation_rules": {
    "medication_errors": {
      "threshold": 3,
      "period_days": 7,
      "escalate_to": "manager"
    },
    "duration_issues": {
      "threshold": 5,
      "period_days": 7,
      "escalate_to": "supervisor"
    },
    "document_expiry": {
      "escalate_to": "admin"
    }
  }
}';

-- Update existing settings record with compliance configuration
UPDATE settings SET compliance_settings = '{
  "duration": {
    "min_percentage": 85,
    "warning_threshold": 10,
    "critical_threshold": 20,
    "escalation_days": 7,
    "escalation_count": 3
  },
  "medication": {
    "require_confirmation": true,
    "require_witness_for_controlled": true,
    "max_missed_per_week": 2,
    "escalation_threshold": 3
  },
  "documentation": {
    "dbs_warning_days": 30,
    "id_warning_days": 30,
    "training_warning_days": 30,
    "right_to_work_warning_days": 30
  },
  "incident_reporting": {
    "require_type": true,
    "require_severity": true,
    "require_action": true,
    "escalation_threshold_hours": 24
  },
  "family_communication": {
    "require_updates": true,
    "update_methods": ["app", "email", "sms"],
    "default_frequency": "daily"
  },
  "regulatory_bodies": {
    "cqc": {
      "notification_threshold_hours": 24,
      "serious_incident_threshold": "high"
    },
    "ofsted": {
      "notification_threshold_hours": 24,
      "serious_incident_threshold": "critical"
    }
  },
  "scoring_weights": {
    "duration": 0.4,
    "documentation": 0.3,
    "medication": 0.3
  },
  "teaching_moments": {
    "auto_create": true,
    "require_acknowledgment": true,
    "max_pending": 5
  },
  "escalation_rules": {
    "medication_errors": {
      "threshold": 3,
      "period_days": 7,
      "escalate_to": "manager"
    },
    "duration_issues": {
      "threshold": 5,
      "period_days": 7,
      "escalate_to": "supervisor"
    },
    "document_expiry": {
      "escalate_to": "admin"
    }
  }
}' WHERE id = 1;

-- Create function to get compliance settings with defaults
CREATE OR REPLACE FUNCTION get_compliance_settings()
RETURNS JSONB AS $$
DECLARE
  settings_record RECORD;
  default_settings JSONB := '{
    "duration": {
      "min_percentage": 85,
      "warning_threshold": 10,
      "critical_threshold": 20,
      "escalation_days": 7,
      "escalation_count": 3
    },
    "medication": {
      "require_confirmation": true,
      "require_witness_for_controlled": true,
      "max_missed_per_week": 2,
      "escalation_threshold": 3
    },
    "documentation": {
      "dbs_warning_days": 30,
      "id_warning_days": 30,
      "training_warning_days": 30,
      "right_to_work_warning_days": 30
    },
    "incident_reporting": {
      "require_type": true,
      "require_severity": true,
      "require_action": true,
      "escalation_threshold_hours": 24
    },
    "family_communication": {
      "require_updates": true,
      "update_methods": ["app", "email", "sms"],
      "default_frequency": "daily"
    },
    "regulatory_bodies": {
      "cqc": {
        "notification_threshold_hours": 24,
        "serious_incident_threshold": "high"
      },
      "ofsted": {
        "notification_threshold_hours": 24,
        "serious_incident_threshold": "critical"
      }
    },
    "scoring_weights": {
      "duration": 0.4,
      "documentation": 0.3,
      "medication": 0.3
    },
    "teaching_moments": {
      "auto_create": true,
      "require_acknowledgment": true,
      "max_pending": 5
    },
    "escalation_rules": {
      "medication_errors": {
        "threshold": 3,
        "period_days": 7,
        "escalate_to": "manager"
      },
      "duration_issues": {
        "threshold": 5,
        "period_days": 7,
        "escalate_to": "supervisor"
      },
      "document_expiry": {
        "escalate_to": "admin"
      }
    }
  }';
BEGIN
  SELECT compliance_settings INTO settings_record FROM settings WHERE id = 1;
  
  IF settings_record.compliance_settings IS NOT NULL THEN
    RETURN settings_record.compliance_settings;
  ELSE
    RETURN default_settings;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create function to update compliance settings
CREATE OR REPLACE FUNCTION update_compliance_settings(new_settings JSONB)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE settings SET 
    compliance_settings = new_settings,
    updated_at = NOW()
  WHERE id = 1;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Create function to validate compliance settings
CREATE OR REPLACE FUNCTION validate_compliance_settings(settings JSONB)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check required fields exist
  IF settings IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Validate duration settings
  IF (settings->'duration'->>'min_percentage')::INTEGER < 50 OR 
     (settings->'duration'->>'min_percentage')::INTEGER > 100 THEN
    RETURN FALSE;
  END IF;
  
  -- Validate medication settings
  IF (settings->'medication'->>'max_missed_per_week')::INTEGER < 0 THEN
    RETURN FALSE;
  END IF;
  
  -- Validate documentation settings
  IF (settings->'documentation'->>'dbs_warning_days')::INTEGER < 0 THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create function to get compliance summary for dashboard
CREATE OR REPLACE FUNCTION get_compliance_summary()
RETURNS JSONB AS $$
DECLARE
  summary JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_flags_today', COUNT(CASE WHEN DATE(created_at) = CURRENT_DATE THEN 1 END),
    'critical_flags_today', COUNT(CASE WHEN DATE(created_at) = CURRENT_DATE AND severity = 'CRITICAL' THEN 1 END),
    'active_teaching_moments', COUNT(DISTINCT tm.user_id),
    'carers_needing_attention', COUNT(DISTINCT CASE WHEN cs.overall_score < 70 THEN cs.carer_id END),
    'upcoming_document_expiry', COUNT(DISTINCT CASE WHEN d.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days' THEN d.carer_id END),
    'compliance_rate_30_days', 
      ROUND(
        (1 - (COUNT(CASE WHEN cf.created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END)::decimal / 
         NULLIF((SELECT COUNT(*) FROM visits WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'), 0))) * 100, 
        2
      ),
    'top_issues', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'rule_name', rule_name,
          'count', count,
          'percentage', ROUND(count * 100.0 / NULLIF(SUM(count) OVER(), 0), 2)
        )
      )
      FROM (
        SELECT rule_name, COUNT(*) as count
        FROM compliance_flags 
        WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY rule_name
        ORDER BY count DESC
        LIMIT 5
      ) as issue_summary
    )
  ) INTO summary
  FROM compliance_flags cf
  FULL OUTER JOIN teaching_moments tm ON tm.quiz_passed = false
  FULL OUTER JOIN compliance_scores cs ON cs.score_date = CURRENT_DATE AND cs.overall_score < 70
  FULL OUTER JOIN documents d ON d.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days';
  
  RETURN summary;
END;
$$ LANGUAGE plpgsql;

-- Create function to escalate compliance issues
CREATE OR REPLACE FUNCTION escalate_compliance_issue(
  flag_id UUID,
  escalated_by UUID,
  escalation_notes TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  flag_record RECORD;
  escalation_target UUID;
BEGIN
  -- Get flag details
  SELECT * INTO flag_record FROM compliance_flags WHERE id = flag_id;
  
  IF flag_record IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Determine escalation target based on rule and severity
  CASE flag_record.rule_id
    WHEN 'MEDS_%' THEN
      SELECT manager_id INTO escalation_target FROM carers WHERE id = flag_record.carer_id;
    WHEN 'DURATION_%' THEN
      SELECT supervisor_id INTO escalation_target FROM carers WHERE id = flag_record.carer_id;
    ELSE
      SELECT id INTO escalation_target FROM profiles WHERE role = 'admin' LIMIT 1;
  END CASE;
  
  -- Update flag status
  UPDATE compliance_flags 
  SET 
    status = 'investigating',
    acknowledged_by = escalated_by,
    acknowledged_at = NOW()
  WHERE id = flag_id;
  
  -- Create escalation notification
  INSERT INTO notifications (
    user_id, type, title, body, data
  ) VALUES (
    escalation_target,
    'escalation',
    format('⚠️ Compliance Issue Escalated: %s', flag_record.rule_name),
    format('Flag "%s" has been escalated by %s. %s', 
           flag_record.message, 
           (SELECT full_name FROM profiles WHERE id = escalated_by),
           escalation_notes),
    jsonb_build_object(
      'flag_id', flag_id,
      'carer_id', flag_record.carer_id,
      'severity', flag_record.severity,
      'escalated_by', escalated_by
    )
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create function to resolve compliance flags
CREATE OR REPLACE FUNCTION resolve_compliance_flag(
  flag_id UUID,
  resolved_by UUID,
  resolution_notes TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Update flag status
  UPDATE compliance_flags 
  SET 
    status = 'resolved',
    resolved_by = resolved_by,
    resolved_at = NOW()
  WHERE id = flag_id;
  
  -- Create notification to carer
  INSERT INTO notifications (
    user_id, type, title, body, data
  ) VALUES (
    (SELECT carer_id FROM compliance_flags WHERE id = flag_id),
    'resolution',
    '✅ Compliance Issue Resolved',
    format('Your compliance issue "%s" has been resolved. %s', 
           (SELECT rule_name FROM compliance_flags WHERE id = flag_id),
           resolution_notes),
    jsonb_build_object(
      'flag_id', flag_id,
      'resolved_by', resolved_by,
      'resolution_notes', resolution_notes
    )
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create function to generate compliance insights
CREATE OR REPLACE FUNCTION generate_compliance_insights()
RETURNS JSONB AS $$
DECLARE
  insights JSONB;
BEGIN
  SELECT jsonb_build_object(
    'trends', (
      SELECT jsonb_build_object(
        'improving_carers', COUNT(CASE WHEN moving_avg_score > overall_score THEN 1 END),
        'declining_carers', COUNT(CASE WHEN moving_avg_score < overall_score THEN 1 END),
        'stable_carers', COUNT(CASE WHEN ABS(moving_avg_score - overall_score) < 5 THEN 1 END)
      )
      FROM compliance_trends ct
      JOIN compliance_scores cs ON cs.carer_id = ct.carer_id AND cs.score_date = CURRENT_DATE
    ),
    'patterns', (
      SELECT jsonb_build_object(
        'peak_flag_times', (
          SELECT jsonb_agg(
            jsonb_build_object('hour', hour_of_day, 'count', count)
          )
          FROM (
            SELECT EXTRACT(HOUR FROM created_at) as hour_of_day, COUNT(*) as count
            FROM compliance_flags
            WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
            GROUP BY EXTRACT(HOUR FROM created_at)
            ORDER BY count DESC
            LIMIT 3
          ) as peak_hours
        ),
        'common_issues', (
          SELECT jsonb_agg(
            jsonb_build_object('rule', rule_name, 'percentage', percentage)
          )
          FROM (
            SELECT rule_name, 
                   ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
            FROM compliance_flags
            WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY rule_name
            ORDER BY COUNT(*) DESC
            LIMIT 5
          ) as common_issues
        ),
        'risk_factors', (
          SELECT jsonb_build_object(
            'high_dependency_issues', COUNT(CASE WHEN su.dependency_level = 'high' THEN 1 END),
            'medication_complexity_issues', COUNT(CASE WHEN su.medication_complexity = 'high' THEN 1 END),
            'weekend_issues', COUNT(CASE WHEN EXTRACT(DOW FROM cf.created_at) IN (0,6) THEN 1 END)
          )
          FROM compliance_flags cf
          JOIN visits v ON cf.visit_id = v.id
          JOIN shifts s ON v.shift_id = s.id
          JOIN service_users su ON s.service_user_id = su.id
          WHERE cf.created_at >= CURRENT_DATE - INTERVAL '30 days'
        )
      )
    ),
    'recommendations', (
      SELECT jsonb_agg(recommendation)
      FROM (
        SELECT 'Review carers with compliance scores below 70%' as recommendation
        WHERE EXISTS (SELECT 1 FROM compliance_scores WHERE overall_score < 70)
        
        UNION ALL
        
        SELECT 'Schedule additional training for medication administration'
        WHERE EXISTS (SELECT 1 FROM compliance_flags WHERE rule_id LIKE 'MEDS_%')
        
        UNION ALL
        
        SELECT 'Review weekend staffing levels'
        WHERE (
          SELECT COUNT(*) FROM compliance_flags 
          WHERE EXTRACT(DOW FROM created_at) IN (0,6) AND created_at >= CURRENT_DATE - INTERVAL '30 days'
        ) > (
          SELECT COUNT(*) FROM compliance_flags 
          WHERE EXTRACT(DOW FROM created_at) NOT IN (0,6) AND created_at >= CURRENT_DATE - INTERVAL '30 days'
        ) * 0.5
      ) as recommendations
    )
  ) INTO insights;
  
  RETURN insights;
END;
$$ LANGUAGE plpgsql;