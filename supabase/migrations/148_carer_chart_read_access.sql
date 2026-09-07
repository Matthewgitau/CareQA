-- ============================================================
-- MIGRATION 148: Carer read access to care chart tables
--
-- The chart tables (food_fluid, bowel_bladder, repositioning, 
-- sleep) were revised by migrations 011-014 using
-- `assessor_id` / `assessment_date` instead of
-- `created_by` / `chart_date`.
--
-- Existing RLS policies on these tables use:
--   assessor_id = auth.uid() OR admin role
-- This already works for carers WHEN the carer is set as
-- assessor_id. But the tenant_isolation from 073 also applies
-- and may block if organisation_id is NULL.
--
-- This migration adds ADDITIVE carer read policies that check
-- assessor_id = auth.uid() (which the staff-app sets when
-- creating charts via the rewritten services).
-- ============================================================

-- 1. food_fluid_charts - additive carer policy
DROP POLICY IF EXISTS "Carers can read charts they assessed" ON public.food_fluid_charts;
CREATE POLICY "Carers can read charts they assessed"
  ON public.food_fluid_charts FOR SELECT TO authenticated
  USING (assessor_id = auth.uid());

-- 2. bowel_bladder_charts
DROP POLICY IF EXISTS "Carers can read charts they assessed" ON public.bowel_bladder_charts;
CREATE POLICY "Carers can read charts they assessed"
  ON public.bowel_bladder_charts FOR SELECT TO authenticated
  USING (assessor_id = auth.uid());

-- 3. repositioning_charts
DROP POLICY IF EXISTS "Carers can read charts they assessed" ON public.repositioning_charts;
CREATE POLICY "Carers can read charts they assessed"
  ON public.repositioning_charts FOR SELECT TO authenticated
  USING (assessor_id = auth.uid());

-- 4. sleep_charts
DROP POLICY IF EXISTS "Carers can read charts they assessed" ON public.sleep_charts;
CREATE POLICY "Carers can read charts they assessed"
  ON public.sleep_charts FOR SELECT TO authenticated
  USING (assessor_id = auth.uid());

-- 5. daily_notes - uses carer_id
DROP POLICY IF EXISTS "Carers can read their own daily notes" ON public.daily_notes;
CREATE POLICY "Carers can read their own daily notes"
  ON public.daily_notes FOR SELECT TO authenticated
  USING (carer_id = auth.uid());

-- 6. body_map_assessments - uses assessed_by
DROP POLICY IF EXISTS "Carers can read their own body maps" ON public.body_map_assessments;
CREATE POLICY "Carers can read their own body maps"
  ON public.body_map_assessments FOR SELECT TO authenticated
  USING (assessed_by = auth.uid());

NOTIFY pgrst, 'reload schema';