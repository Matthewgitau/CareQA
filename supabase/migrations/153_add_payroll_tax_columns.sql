-- ============================================================
-- MIGRATION 153: Payroll tax & deduction columns
--
-- Extends payroll_history with the UK PAYE tax fields used by the
-- payroll tab (UK_tax_calculator.dart) so every generated payslip
-- stores its tax configuration and computed deductions.
--
-- Columns added:
--   gross_pay                 computed gross (regular + OT + holiday + sick + bonus)
--   tax_code                  HMRC tax code (default 1257L)
--   ni_category               NI letter (A, B, C, J)
--   pension_rate              employee pension % of gross (auto-enrolment default 0 = off)
--   pension_contribution      £ employee pension deducted
--   employer_pension          £ employer pension contribution
--   student_loan_plan         none / plan1 / plan2 / plan4 / plan5 / pgl
--   student_loan_repayment    £ student loan deducted
--   employer_ni               £ employer (secondary) NI -- company cost
--   net_pay                   take-home pay
--
-- (tax_deducted / ni_deducted already exist on the table.)
-- ============================================================

ALTER TABLE public.payroll_history
  ADD COLUMN IF NOT EXISTS gross_pay NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tax_code TEXT DEFAULT '1257L',
  ADD COLUMN IF NOT EXISTS ni_category TEXT DEFAULT 'A',
  ADD COLUMN IF NOT EXISTS pension_rate NUMERIC(5,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS pension_contribution NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS employer_pension NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS student_loan_plan TEXT DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS student_loan_repayment NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS employer_ni NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS net_pay NUMERIC(10,2) DEFAULT 0;

-- Backfill gross/net for any existing rows so reports are not broken.
UPDATE public.payroll_history
SET gross_pay = COALESCE(regular_hours,0)*COALESCE(hourly_rate,0)
              + COALESCE(overtime_hours,0)*COALESCE(overtime_rate,0)
              + COALESCE(holiday_pay,0) + COALESCE(sick_pay,0) + COALESCE(bonus_pay,0),
    net_pay   = COALESCE(regular_pay,0) + COALESCE(overtime_pay,0)
              + COALESCE(holiday_pay,0) + COALESCE(sick_pay,0) + COALESCE(bonus_pay,0)
              - COALESCE(deductions,0) - COALESCE(tax_deducted,0) - COALESCE(ni_deducted,0)
WHERE gross_pay IS NULL OR gross_pay = 0;

NOTIFY pgrst, 'reload schema';