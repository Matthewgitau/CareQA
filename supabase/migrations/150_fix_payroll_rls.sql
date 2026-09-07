-- ============================================================
-- MIGRATION 150: Fix payroll_history RLS for P&L + admin
--
-- Problem: tenant_isolation_payroll_history checks
-- organisation_id, but many rows (including auto-generated ones)
-- have NULL. The P&L query returns 400.
--
-- Fix: Add admin/manager override policy, and a carer
-- self-access policy so staff can see their own pay records.
-- ============================================================

-- 1. Add admin/manager override - any admin/manager can see ALL
--    payroll_history regardless of organisation_id.
DROP POLICY IF EXISTS "Admins can view all payroll history" ON public.payroll_history;
CREATE POLICY "Admins can view all payroll history"
  ON public.payroll_history FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'manager', 'super_admin'))
    OR organisation_id = (SELECT organisation_id FROM public.profiles WHERE id = auth.uid())
    OR organisation_id IS NULL
  );

-- 2. Carer self-access - carers can see their own payslips.
DROP POLICY IF EXISTS "Carers can view their own payroll" ON public.payroll_history;
CREATE POLICY "Carers can view their own payroll"
  ON public.payroll_history FOR SELECT TO authenticated
  USING (staff_id = auth.uid());

-- 3. INSERT policy - admins/managers can insert payroll rows.
DROP POLICY IF EXISTS "Admins can insert payroll" ON public.payroll_history;
CREATE POLICY "Admins can insert payroll"
  ON public.payroll_history FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'manager', 'super_admin'))
  );

NOTIFY pgrst, 'reload schema';