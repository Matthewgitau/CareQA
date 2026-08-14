-- AI Training Data View
-- This view provides structured data for machine learning analysis

CREATE VIEW ai_training_data AS
SELECT
  v.id as visit_id,
  v.duration_minutes,
  v.compliance_percentage,
  v.flagged,
  v.flag_reason,
  v.structured_notes,
  s.scheduled_date,
  EXTRACT(DOW FROM s.scheduled_date) as day_of_week,
  EXTRACT(HOUR FROM s.start_time) as hour_of_day,
  EXTRACT(EPOCH FROM (s.end_time - s.start_time))/60 as scheduled_duration_minutes,
  c.id as carer_id,
  c.dbs_expiry_date,
  c.is_active as carer_active,
  su.id as service_user_id,
  su.care_plan,
  su.dependency_level,
  su.medication_complexity,
  (SELECT jsonb_agg(f) FROM compliance_flags f WHERE f.visit_id = v.id) as flags,
  cs.overall_score as carer_compliance_score,
  cs.duration_compliance,
  cs.documentation_compliance,
  cs.medication_compliance,
  cs.incident_reporting_compliance,
  cs.flags_count,
  -- Derived features for ML
  CASE 
    WHEN EXTRACT(DOW FROM s.scheduled_date) IN (0,6) THEN true 
    ELSE false 
  END as is_weekend,
  CASE 
    WHEN EXTRACT(HOUR FROM s.start_time) BETWEEN 6 AND 12 THEN 'morning'
    WHEN EXTRACT(HOUR FROM s.start_time) BETWEEN 13 AND 17 THEN 'afternoon'
    WHEN EXTRACT(HOUR FROM s.start_time) BETWEEN 18 AND 22 THEN 'evening'
    ELSE 'night'
  END as time_of_day,
  -- Risk factors
  CASE 
    WHEN su.dependency_level = 'high' THEN 1
    WHEN su.dependency_level = 'medium' THEN 0.5
    ELSE 0
  END as dependency_risk_score,
  CASE 
    WHEN su.medication_complexity = 'high' THEN 1
    WHEN su.medication_complexity = 'medium' THEN 0.5
    ELSE 0
  END as medication_risk_score,
  -- Carer experience proxy (based on compliance score)
  CASE 
    WHEN cs.overall_score >= 90 THEN 'experienced'
    WHEN cs.overall_score >= 70 THEN 'intermediate'
    ELSE 'needs_support'
  END as carer_experience_level
FROM visits v
JOIN shifts s ON v.shift_id = s.id
JOIN carers c ON v.carer_id = c.id
JOIN service_users su ON s.service_user_id = su.id
LEFT JOIN compliance_scores cs ON cs.carer_id = c.id 
  AND cs.score_date = s.scheduled_date
WHERE v.created_at > NOW() - INTERVAL '90 days'
  AND c.is_active = true;

-- Grant access to AI service user
-- Note: This assumes you have created an AI service user
-- GRANT SELECT ON ai_training_data TO ai_service_user;

-- Create view for compliance trends
CREATE VIEW compliance_trends AS
SELECT
  carer_id,
  DATE(score_date) as date,
  AVG(overall_score) as avg_score,
  AVG(duration_compliance) as avg_duration_score,
  AVG(documentation_compliance) as avg_documentation_score,
  AVG(medication_compliance) as avg_medication_score,
  AVG(incident_reporting_compliance) as avg_incident_score,
  SUM(flags_count) as total_flags,
  -- Trend calculation (7-day moving average)
  AVG(overall_score) OVER (
    PARTITION BY carer_id 
    ORDER BY score_date 
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) as moving_avg_score
FROM compliance_scores
WHERE score_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY carer_id, DATE(score_date)
ORDER BY carer_id, date;

-- Create view for regulatory compliance summary
CREATE VIEW regulatory_compliance_summary AS
SELECT
  DATE(created_at) as date,
  COUNT(*) as total_flags,
  COUNT(CASE WHEN severity = 'CRITICAL' THEN 1 END) as critical_flags,
  COUNT(CASE WHEN severity = 'WARNING' THEN 1 END) as warning_flags,
  COUNT(CASE WHEN severity = 'INFO' THEN 1 END) as info_flags,
  COUNT(CASE WHEN regulation_reference LIKE '%CQC%' THEN 1 END) as cqc_flags,
  COUNT(CASE WHEN rule_id LIKE 'DURATION_%' THEN 1 END) as duration_flags,
  COUNT(CASE WHEN rule_id LIKE 'MEDS_%' THEN 1 END) as medication_flags,
  COUNT(CASE WHEN rule_id = 'INCIDENT_INCOMPLETE' THEN 1 END) as incident_flags,
  COUNT(CASE WHEN rule_id = 'FAMILY_COMMS' THEN 1 END) as family_flags,
  -- Compliance rate calculation
  ROUND(
    (1 - (COUNT(*)::decimal / (SELECT COUNT(*) FROM visits WHERE DATE(created_at) = DATE(compliance_flags.created_at)))) * 100, 
    2
  ) as compliance_rate
FROM compliance_flags
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Create view for carer performance dashboard
CREATE VIEW carer_performance_dashboard AS
SELECT
  c.id as carer_id,
  p.full_name as carer_name,
  p.email as carer_email,
  COUNT(v.id) as total_visits,
  COUNT(CASE WHEN v.flagged = true THEN 1 END) as flagged_visits,
  ROUND(
    (1 - (COUNT(CASE WHEN v.flagged = true THEN 1 END)::decimal / COUNT(v.id))) * 100, 
    2
  ) as compliance_rate,
  AVG(v.compliance_percentage) as avg_duration_compliance,
  COUNT(cf.id) as total_flags,
  COUNT(CASE WHEN cf.severity = 'CRITICAL' THEN 1 END) as critical_flags,
  COUNT(CASE WHEN cf.severity = 'WARNING' THEN 1 END) as warning_flags,
  COUNT(CASE WHEN cf.rule_id LIKE 'DURATION_%' THEN 1 END) as duration_issues,
  COUNT(CASE WHEN cf.rule_id LIKE 'MEDS_%' THEN 1 END) as medication_issues,
  COUNT(CASE WHEN cf.rule_id = 'INCIDENT_INCOMPLETE' THEN 1 END) as incident_issues,
  -- Recent performance (last 30 days)
  COUNT(CASE WHEN v.created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_visits,
  COUNT(CASE WHEN v.created_at >= CURRENT_DATE - INTERVAL '30 days' AND v.flagged = true THEN 1 END) as recent_flags,
  -- Risk assessment
  CASE 
    WHEN COUNT(CASE WHEN cf.severity = 'CRITICAL' THEN 1 END) > 5 THEN 'HIGH_RISK'
    WHEN COUNT(CASE WHEN cf.severity = 'WARNING' THEN 1 END) > 10 THEN 'MEDIUM_RISK'
    WHEN COUNT(cf.id) > 20 THEN 'NEEDS_ATTENTION'
    ELSE 'PERFORMING_WELL'
  END as risk_level,
  -- Last compliance score
  cs.overall_score as current_compliance_score,
  cs.duration_compliance,
  cs.documentation_compliance,
  cs.medication_compliance,
  cs.incident_reporting_compliance
FROM carers c
JOIN profiles p ON c.id = p.id
LEFT JOIN visits v ON v.carer_id = c.id
LEFT JOIN compliance_flags cf ON cf.carer_id = c.id
LEFT JOIN compliance_scores cs ON cs.carer_id = c.id AND cs.score_date = CURRENT_DATE
WHERE c.is_active = true
GROUP BY c.id, p.full_name, p.email, cs.overall_score, 
         cs.duration_compliance, cs.documentation_compliance, 
         cs.medication_compliance, cs.incident_reporting_compliance
ORDER BY compliance_rate ASC, total_visits DESC;

-- Create view for service user risk assessment
CREATE VIEW service_user_risk_assessment AS
SELECT
  su.id as service_user_id,
  su.name as service_user_name,
  su.dependency_level,
  su.medication_complexity,
  COUNT(v.id) as total_visits,
  COUNT(CASE WHEN v.flagged = true THEN 1 END) as flagged_visits,
  ROUND(
    (1 - (COUNT(CASE WHEN v.flagged = true THEN 1 END)::decimal / COUNT(v.id))) * 100, 
    2
  ) as compliance_rate,
  AVG(v.compliance_percentage) as avg_duration_compliance,
  COUNT(cf.id) as total_flags,
  COUNT(CASE WHEN cf.severity = 'CRITICAL' THEN 1 END) as critical_flags,
  COUNT(CASE WHEN cf.rule_id LIKE 'MEDS_%' THEN 1 END) as medication_flags,
  -- Risk factors
  CASE 
    WHEN su.dependency_level = 'high' AND su.medication_complexity = 'high' THEN 'HIGH_RISK'
    WHEN su.dependency_level = 'high' OR su.medication_complexity = 'high' THEN 'MEDIUM_RISK'
    ELSE 'LOW_RISK'
  END as overall_risk_level,
  -- Care plan complexity
  jsonb_array_length(su.care_plan->'medications') as medication_count,
  jsonb_array_length(su.care_plan->'tasks') as task_count,
  (su.care_plan->>'family_updates_required')::boolean as family_updates_required
FROM service_users su
LEFT JOIN shifts s ON s.service_user_id = su.id
LEFT JOIN visits v ON v.shift_id = s.id
LEFT JOIN compliance_flags cf ON cf.visit_id = v.id
WHERE su.is_active = true
GROUP BY su.id, su.name, su.dependency_level, su.medication_complexity, su.care_plan
ORDER BY overall_risk_level DESC, compliance_rate ASC;