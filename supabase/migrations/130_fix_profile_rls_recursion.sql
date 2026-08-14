-- =============================================
-- Migration 130: Fix infinite recursion in
-- profiles RLS policy
--
-- The "Users can view profiles in same care home"
-- policy contained a subquery on `profiles` itself,
-- which caused infinite recursion (500 error) and
-- logged users out.
--
-- Fix: Drop the recursive policy. The sub-user list
-- is already covered by the non-recursive
-- "Users can view their sub-users" policy
-- (overseer_id = auth.uid()).
-- =============================================

DROP POLICY IF EXISTS "Users can view profiles in same care home" ON public.profiles;