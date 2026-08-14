-- 092: Compliance Dashboard Enhancement
-- Adds category_scores JSONB to compliance_scores, plus dashboard helper functions

-- ============================================================
-- 1. Add category_scores column to compliance_scores table
-- ============================================================
ALTER TABLE compliance_scores
  ADD COLUMN IF NOT EXISTS category_scores JSONB DEFAULT '{}';

COMMENT ON COLUMN compliance_scores.category_scores IS
  'JSONB map of 16 category scores, e.g. {"mar_audit": 85, "care_log_audit": 92, ...}';

-- ============================================================
-- 2. calculate_carer_compliance_score()
--    Aggregates scores from 16 monitored data sources for a
--    given carer and date range, returning a single overall
--    score plus per-category breakdown.
-- ============================================================
CREATE OR REPLACE FUNCTION calculate_carer_compliance_score(
  p_carer_id UUID,
  p_start_date DATE DEFAULT (CURRENT_DATE - INTERVAL '30 days'),
  p_end_date   DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_mar            NUMERIC := 0;
  v_care_log       NUMERIC := 0;
  v_care_plan      NUMERIC := 0;
  v_spot_check     NUMERIC := 0;
  v_safeguarding   NUMERIC := 0;
  v_accidents      NUMERIC := 0;
  v_complaints     NUMERIC := 0;
  v_compliments    NUMERIC := 0;
  v_whistleblowers NUMERIC := 0;
  v_serious_inc    NUMERIC := 0;
  v_disciplinary   NUMERIC := 0;
  v_emp_welfare    NUMERIC := 0;
  v_training       NUMERIC := 0;
  v_appraisals     NUMERIC := 0;
  v_supervision    NUMERIC := 0;
  v_competency     NUMERIC := 0;
  v_total          NUMERIC;
  v_count          INTEGER := 0;
  v_sum            NUMERIC := 0;
BEGIN
  -- 1. MAR Audit
  SELECT COALESCE(
    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 100
      ELSE (COUNT(*) FILTER (WHERE total_accuracy_score IS NOT NULL AND total_accuracy_score >= 8)) * 100.0 / COUNT(*)
      END, 1), 100)
  INTO v_mar
  FROM mar_audits
  WHERE carer_id = p_carer_id
    AND audit_date BETWEEN p_start_date AND p_end_date;

  -- 2. Care Log Audit
  SELECT COALESCE(
    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 100
      ELSE (COUNT(*) FILTER (WHERE total_compliance_score IS NOT NULL AND total_compliance_score >= 7)) * 100.0 / COUNT(*)
      END, 1), 100)
  INTO v_care_log
  FROM care_log_audits
  WHERE carer_id = p_carer_id
    AND audit_date BETWEEN p_start_date AND p_end_date;

  -- 3. Care Plan Audit
  SELECT COALESCE(
    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 100
      ELSE (COUNT(*) FILTER (WHERE overall_score IS NOT NULL AND overall_score >= 7)) * 100.0 / COUNT(*)
      END, 1), 100)
  INTO v_care_plan
  FROM care_plan_audits
  WHERE carer_id = p_carer_id
    AND audit_date BETWEEN p_start_date AND p_end_date;

  -- 4. Spot Check
  SELECT COALESCE(
    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 100
      ELSE (COUNT(*) FILTER (WHERE overall_score IS NOT NULL AND overall_score >= 7)) * 100.0 / COUNT(*)
      END, 1), 100)
  INTO v_spot_check
  FROM spot_checks
  WHERE carer_id = p_carer_id
    AND check_date BETWEEN p_start_date AND p_end_date;

  -- 5. Safeguarding (fewer flags = better)
  SELECT COALESCE(
    ROUND(
      GREATEST(0, 100 - (COUNT(*) * 10.0)), 1), 100)
  INTO v_safeguarding
  FROM compliance_flags
  WHERE carer_id = p_carer_id
    AND rule_id ILIKE '%safeguarding%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 6. Accidents Log
  SELECT COALESCE(
    ROUND(
      GREATEST(0, 100 - (COUNT(*) * 5.0)), 1), 100)
  INTO v_accidents
  FROM compliance_flags
  WHERE carer_id = p_carer_id
    AND rule_id ILIKE '%accident%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 7. Complaints
  SELECT COALESCE(
    ROUND(
      GREATEST(0, 100 - (COUNT(*) * 10.0)), 1), 100)
  INTO v_complaints
  FROM compliance_flags
  WHERE carer_id = p_carer_id
    AND rule_id ILIKE '%complaint%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 8. Compliments (more = better, capped at 100)
  SELECT COALESCE(
    ROUND(
      LEAST(100, 70 + (COUNT(*) * 5.0)), 1), 85)
  INTO v_compliments
  FROM compliance_flags
  WHERE carer_id = p_carer_id
    AND rule_id ILIKE '%compliment%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 9. Whistleblowers
  SELECT COALESCE(
    ROUND(
      GREATEST(0, 100 - (COUNT(*) * 15.0)), 1), 100)
  INTO v_whistleblowers
  FROM compliance_flags
  WHERE carer_id = p_carer_id
    AND rule_id ILIKE '%whistle%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 10. Serious Incidents
  SELECT COALESCE(
    ROUND(
      GREATEST(0, 100 - (COUNT(*) * 20.0)), 1), 100)
  INTO v_serious_inc
  FROM compliance_flags
  WHERE carer_id = p_carer_id
    AND rule_id ILIKE '%serious%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 11. Disciplinary
  SELECT COALESCE(
    ROUND(
      GREATEST(0, 100 - (COUNT(*) * 15.0)), 1), 100)
  INTO v_disciplinary
  FROM compliance_flags
  WHERE carer_id = p_carer_id
    AND rule_id ILIKE '%disciplinary%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 12. Employee Welfare
  SELECT COALESCE(
    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 90
      ELSE (COUNT(*) FILTER (WHERE status = 'resolved')) * 100.0 / COUNT(*)
      END, 1), 90)
  INTO v_emp_welfare
  FROM compliance_flags
  WHERE carer_id = p_carer_id
    AND rule_id ILIKE '%welfare%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 13. Training Matrix
  SELECT COALESCE(
    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 100
      ELSE (COUNT(*) FILTER (WHERE completed_at IS NOT NULL)) * 100.0 / COUNT(*)
      END, 1), 100)
  INTO v_training
  FROM teaching_moments
  WHERE user_id = p_carer_id
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 14. Appraisals
  SELECT COALESCE(
    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 100
      ELSE (COUNT(*) FILTER (WHERE status = 'completed')) * 100.0 / COUNT(*)
      END, 1), 100)
  INTO v_appraisals
  FROM appraisal_forms
  WHERE carer_id = p_carer_id
    AND appraisal_date BETWEEN p_start_date AND p_end_date;

  -- 15. Supervision Matrix
  SELECT COALESCE(
    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 100
      ELSE (COUNT(*) FILTER (WHERE status = 'completed')) * 100.0 / COUNT(*)
      END, 1), 100)
  INTO v_supervision
  FROM supervision_records
  WHERE carer_id = p_carer_id
    AND supervision_date BETWEEN p_start_date AND p_end_date;

  -- 16. Competency Dashboard
  SELECT COALESCE(
    ROUND(
      CASE WHEN COUNT(*) = 0 THEN 100
      ELSE AVG(COALESCE(overall_score, 0))
      END, 1), 100)
  INTO v_competency
  FROM competency_assessments
  WHERE carer_id = p_carer_id
    AND assessment_date BETWEEN p_start_date AND p_end_date;

  -- Calculate weighted overall score
  v_sum := v_mar + v_care_log + v_care_plan + v_spot_check
         + v_safeguarding + v_accidents + v_complaints + v_compliments
         + v_whistleblowers + v_serious_inc + v_disciplinary + v_emp_welfare
         + v_training + v_appraisals + v_supervision + v_competency;
  v_total := ROUND(v_sum / 16.0, 1);

  v_result := jsonb_build_object(
    'overall_score', v_total,
    'category_scores', jsonb_build_object(
      'mar_audit',            v_mar,
      'care_log_audit',       v_care_log,
      'care_plan_audit',      v_care_plan,
      'spot_check',           v_spot_check,
      'safeguarding',         v_safeguarding,
      'accidents_log',        v_accidents,
      'complaints',           v_complaints,
      'compliments',          v_compliments,
      'whistleblowers',       v_whistleblowers,
      'serious_incidents',    v_serious_inc,
      'disciplinary',         v_disciplinary,
      'employee_welfare',     v_emp_welfare,
      'training_matrix',      v_training,
      'appraisals',           v_appraisals,
      'supervision_matrix',   v_supervision,
      'competency_dashboard', v_competency
    ),
    'period_start', p_start_date,
    'period_end',   p_end_date
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 3. get_dashboard_category_scores()
--    Returns aggregated average scores across ALL carers for
--    the dashboard overview.
-- ============================================================
CREATE OR REPLACE FUNCTION get_dashboard_category_scores(
  p_start_date DATE DEFAULT (CURRENT_DATE - INTERVAL '30 days'),
  p_end_date   DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_mar            NUMERIC := 0;
  v_care_log       NUMERIC := 0;
  v_care_plan      NUMERIC := 0;
  v_spot_check     NUMERIC := 0;
  v_safeguarding   NUMERIC := 0;
  v_accidents      NUMERIC := 0;
  v_complaints     NUMERIC := 0;
  v_compliments    NUMERIC := 0;
  v_whistleblowers NUMERIC := 0;
  v_serious_inc    NUMERIC := 0;
  v_disciplinary   NUMERIC := 0;
  v_emp_welfare    NUMERIC := 0;
  v_training       NUMERIC := 0;
  v_appraisals     NUMERIC := 0;
  v_supervision    NUMERIC := 0;
  v_competency     NUMERIC := 0;
  v_total          NUMERIC;
  v_carer_count    INTEGER;
BEGIN
  SELECT COUNT(DISTINCT id) INTO v_carer_count FROM carers;

  -- 1. MAR Audit
  SELECT COALESCE(ROUND(
    CASE WHEN COUNT(*) = 0 THEN 100
    ELSE (COUNT(*) FILTER (WHERE total_accuracy_score IS NOT NULL AND total_accuracy_score >= 8)) * 100.0 / COUNT(*)
    END, 1), 100)
  INTO v_mar
  FROM mar_audits
  WHERE audit_date BETWEEN p_start_date AND p_end_date;

  -- 2. Care Log Audit
  SELECT COALESCE(ROUND(
    CASE WHEN COUNT(*) = 0 THEN 100
    ELSE (COUNT(*) FILTER (WHERE total_compliance_score IS NOT NULL AND total_compliance_score >= 7)) * 100.0 / COUNT(*)
    END, 1), 100)
  INTO v_care_log
  FROM care_log_audits
  WHERE audit_date BETWEEN p_start_date AND p_end_date;

  -- 3. Care Plan Audit
  SELECT COALESCE(ROUND(
    CASE WHEN COUNT(*) = 0 THEN 100
    ELSE (COUNT(*) FILTER (WHERE overall_score IS NOT NULL AND overall_score >= 7)) * 100.0 / COUNT(*)
    END, 1), 100)
  INTO v_care_plan
  FROM care_plan_audits
  WHERE audit_date BETWEEN p_start_date AND p_end_date;

  -- 4. Spot Check
  SELECT COALESCE(ROUND(
    CASE WHEN COUNT(*) = 0 THEN 100
    ELSE (COUNT(*) FILTER (WHERE overall_score IS NOT NULL AND overall_score >= 7)) * 100.0 / COUNT(*)
    END, 1), 100)
  INTO v_spot_check
  FROM spot_checks
  WHERE check_date BETWEEN p_start_date AND p_end_date;

  -- 5. Safeguarding
  SELECT COALESCE(ROUND(
    GREATEST(0, 100 - (COUNT(*) * 10.0)), 1), 100)
  INTO v_safeguarding
  FROM compliance_flags
  WHERE rule_id ILIKE '%safeguarding%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 6. Accidents Log
  SELECT COALESCE(ROUND(
    GREATEST(0, 100 - (COUNT(*) * 5.0)), 1), 100)
  INTO v_accidents
  FROM compliance_flags
  WHERE rule_id ILIKE '%accident%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 7. Complaints
  SELECT COALESCE(ROUND(
    GREATEST(0, 100 - (COUNT(*) * 10.0)), 1), 100)
  INTO v_complaints
  FROM compliance_flags
  WHERE rule_id ILIKE '%complaint%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 8. Compliments
  SELECT COALESCE(ROUND(
    LEAST(100, 70 + (COUNT(*) * 5.0)), 1), 85)
  INTO v_compliments
  FROM compliance_flags
  WHERE rule_id ILIKE '%compliment%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 9. Whistleblowers
  SELECT COALESCE(ROUND(
    GREATEST(0, 100 - (COUNT(*) * 15.0)), 1), 100)
  INTO v_whistleblowers
  FROM compliance_flags
  WHERE rule_id ILIKE '%whistle%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 10. Serious Incidents
  SELECT COALESCE(ROUND(
    GREATEST(0, 100 - (COUNT(*) * 20.0)), 1), 100)
  INTO v_serious_inc
  FROM compliance_flags
  WHERE rule_id ILIKE '%serious%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 11. Disciplinary
  SELECT COALESCE(ROUND(
    GREATEST(0, 100 - (COUNT(*) * 15.0)), 1), 100)
  INTO v_disciplinary
  FROM compliance_flags
  WHERE rule_id ILIKE '%disciplinary%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 12. Employee Welfare
  SELECT COALESCE(ROUND(
    CASE WHEN COUNT(*) = 0 THEN 90
    ELSE (COUNT(*) FILTER (WHERE status = 'resolved')) * 100.0 / COUNT(*)
    END, 1), 90)
  INTO v_emp_welfare
  FROM compliance_flags
  WHERE rule_id ILIKE '%welfare%'
    AND created_at::date BETWEEN p_start_date AND p_end_date;

  -- 13. Training Matrix
  SELECT COALESCE(ROUND(
    CASE WHEN COUNT(*) = 0 THEN 100
    ELSE (COUNT(*) FILTER (WHERE completed_at IS NOT NULL)) * 100.0 / COUNT(*)
    END, 1), 100)
  INTO v_training
  FROM teaching_moments
  WHERE created_at::date BETWEEN p_start_date AND p_end_date;

  -- 14. Appraisals
  SELECT COALESCE(ROUND(
    CASE WHEN COUNT(*) = 0 THEN 100
    ELSE (COUNT(*) FILTER (WHERE status = 'completed')) * 100.0 / COUNT(*)
    END, 1), 100)
  INTO v_appraisals
  FROM appraisal_forms
  WHERE appraisal_date BETWEEN p_start_date AND p_end_date;

  -- 15. Supervision Matrix
  SELECT COALESCE(ROUND(
    CASE WHEN COUNT(*) = 0 THEN 100
    ELSE (COUNT(*) FILTER (WHERE status = 'completed')) * 100.0 / COUNT(*)
    END, 1), 100)
  INTO v_supervision
  FROM supervision_records
  WHERE supervision_date BETWEEN p_start_date AND p_end_date;

  -- 16. Competency Dashboard
  SELECT COALESCE(ROUND(
    CASE WHEN COUNT(*) = 0 THEN 100
    ELSE AVG(COALESCE(overall_score, 0))
    END, 1), 100)
  INTO v_competency
  FROM competency_assessments
  WHERE assessment_date BETWEEN p_start_date AND p_end_date;

  v_total := ROUND((v_mar + v_care_log + v_care_plan + v_spot_check
    + v_safeguarding + v_accidents + v_complaints + v_compliments
    + v_whistleblowers + v_serious_inc + v_disciplinary + v_emp_welfare
    + v_training + v_appraisals + v_supervision + v_competency) / 16.0, 1);

  v_result := jsonb_build_object(
    'overall_score', v_total,
    'carer_count', v_carer_count,
    'category_scores', jsonb_build_object(
      'mar_audit',            v_mar,
      'care_log_audit',       v_care_log,
      'care_plan_audit',      v_care_plan,
      'spot_check',           v_spot_check,
      'safeguarding',         v_safeguarding,
      'accidents_log',        v_accidents,
      'complaints',           v_complaints,
      'compliments',          v_compliments,
      'whistleblowers',       v_whistleblowers,
      'serious_incidents',    v_serious_inc,
      'disciplinary',         v_disciplinary,
      'employee_welfare',     v_emp_welfare,
      'training_matrix',      v_training,
      'appraisals',           v_appraisals,
      'supervision_matrix',   v_supervision,
      'competency_dashboard', v_competency
    ),
    'period_start', p_start_date,
    'period_end',   p_end_date
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 4. get_compliance_trends_data()
--    Returns weekly / monthly / quarterly score snapshots
--    for the compliance trends chart.
-- ============================================================
CREATE OR REPLACE FUNCTION get_compliance_trends_data(
  p_interval TEXT DEFAULT 'weekly',   -- 'weekly', 'monthly', 'quarterly'
  p_start_date DATE DEFAULT (CURRENT_DATE - INTERVAL '6 months'),
  p_end_date   DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_trunc  TEXT;
BEGIN
  CASE p_interval
    WHEN 'weekly'    THEN v_trunc := 'week';
    WHEN 'monthly'   THEN v_trunc := 'month';
    WHEN 'quarterly' THEN v_trunc := 'quarter';
    ELSE v_trunc := 'week';
  END CASE;

  SELECT jsonb_agg(
    jsonb_build_object(
      'period', period_start,
      'avg_score', avg_score,
      'min_score', min_score,
      'max_score', max_score,
      'flag_count', flag_count
    )
    ORDER BY period_start
  )
  INTO v_result
  FROM (
    SELECT
      date_trunc(v_trunc, cs.score_date)::date AS period_start,
      ROUND(AVG(cs.overall_score), 1)           AS avg_score,
      ROUND(MIN(cs.overall_score), 1)           AS min_score,
      ROUND(MAX(cs.overall_score), 1)           AS max_score,
      COALESCE(SUM(cs.flags_count), 0)          AS flag_count
    FROM compliance_scores cs
    WHERE cs.score_date BETWEEN p_start_date AND p_end_date
    GROUP BY date_trunc(v_trunc, cs.score_date)
    ORDER BY period_start
  ) sub;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 5. RLS – allow admins to call the new functions
-- ============================================================
-- The SECURITY DEFINER functions run as the function owner,
-- so no extra RLS policies are needed for the RPC calls.