-- Add scoring columns to choking_risk_assessments
ALTER TABLE choking_risk_assessments 
ADD COLUMN IF NOT EXISTS risk_factors JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS total_score INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS risk_level TEXT DEFAULT 'Low';

-- Create function to calculate risk level from risk_factors JSONB
CREATE OR REPLACE FUNCTION calculate_choking_risk_level()
RETURNS TRIGGER AS $$
DECLARE
  score_total INTEGER;
BEGIN
  score_total := 0;
  
  -- Physical Conditions (6)
  score_total := score_total + COALESCE((NEW.risk_factors->>'weak_cough')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'chest_infections')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'breathing_difficulties')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'known_to_aspirate')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'history_of_choking')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'gurgly_wet_voice')::int, 0);
  
  -- Neurological Conditions (6)
  score_total := score_total + COALESCE((NEW.risk_factors->>'epilepsy')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'cerebral_palsy')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'dementia_confusion')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'mental_health_history')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'neurological_conditions')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'learning_disabilities')::int, 0);
  
  -- Physical Limitations (6)
  score_total := score_total + COALESCE((NEW.risk_factors->>'postural_problems')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'poor_head_control')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'tongue_thrust')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'chewing_difficulties')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'slurred_speech')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'neck_throat_injury')::int, 0);
  
  -- Behavioral Factors (8)
  score_total := score_total + COALESCE((NEW.risk_factors->>'eats_rapidly')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'drinks_rapidly')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'continues_eating_while_coughing')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'continues_drinking_while_coughing')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'cramming_food')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'pocketing_food')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'swallowing_without_chewing')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'takes_food_from_others')::int, 0);
  
  -- Eating/Drinking Independence (2)
  score_total := score_total + COALESCE((NEW.risk_factors->>'drinks_independently')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'eats_independently')::int, 0);
  
  -- Dental/Oral Health (1)
  score_total := score_total + COALESCE((NEW.risk_factors->>'dental_issues')::int, 0);
  
  -- Physical/Mental State (5)
  score_total := score_total + COALESCE((NEW.risk_factors->>'fatigue_at_meals')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'needs_food_prepared')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'modified_consistency_diet')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'requires_thickened_fluids')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'requires_specialist_aids')::int, 0);
  score_total := score_total + COALESCE((NEW.risk_factors->>'puts_non_food_items_in_mouth')::int, 0);
  
  -- Medication (1)
  score_total := score_total + COALESCE((NEW.risk_factors->>'medication_affects_swallowing')::int, 0);
  
  NEW.total_score := score_total;
  
  IF NEW.total_score <= 24 THEN
    NEW.risk_level := 'Low';
  ELSIF NEW.total_score <= 49 THEN
    NEW.risk_level := 'Medium';
  ELSE
    NEW.risk_level := 'High';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-calculate risk level on insert or update
DROP TRIGGER IF EXISTS trg_calculate_choking_risk ON choking_risk_assessments;
CREATE TRIGGER trg_calculate_choking_risk
BEFORE INSERT OR UPDATE OF risk_factors ON choking_risk_assessments
FOR EACH ROW
EXECUTE FUNCTION calculate_choking_risk_level();