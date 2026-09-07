-- ============================================================
-- RLS AUDIT: route/visits feature — see every policy + data state
-- Run this in the Supabase SQL editor as the postgres/service role.
-- ============================================================

-- (1) Is RLS enabled on each table, and every policy on it
SELECT t.tablename,
       t.rowsecurity AS rls_enabled,
       p.policyname,
       p.cmd,
       p.roles,
       p.qual  AS using_expression,
       p.with_check
FROM pg_tables t
LEFT JOIN pg_policies p
       ON p.schemaname = t.schemaname AND p.tablename = t.tablename
WHERE t.schemaname = 'public'
  AND t.tablename IN (
        'routes', 'route_visits', 'route_change_log',
        'route_service_users', 'service_user_weekly_calls',
        'service_user_calls', 'service_user_statuses',
        'shifts', 'carers', 'profiles'
      )
ORDER BY t.tablename, p.cmd, p.policyname;

-- (2) Current state of the org columns on the data (do rows even have an org?)
SELECT 'routes'  AS tbl, id::text, name, organisation_id, client_organisation_id, carer_id, second_carer_id, is_recurring
FROM public.routes
ORDER BY created_at DESC
LIMIT 20;

SELECT 'route_visits' AS tbl, id::text, route_id, service_user_id, carer_id,
       visit_date, visit_time, status, organisation_id, client_organisation_id
FROM public.route_visits
ORDER BY visit_time DESC
LIMIT 30;

-- (3) mia's profile rows (what auth.uid() resolves to + orgs)
SELECT id, email, name, role, organisation_id, client_organisation_id, is_active
FROM public.profiles
WHERE email ILIKE 'mia@care.com';

-- (4) The EXACT rows her lookup depends on: direct carer OR via route 2nd carer
SELECT rv.id::text AS visit_id, r.name AS route, r.organisation_id AS route_org,
       rv.organisation_id AS visit_org, rv.client_organisation_id AS visit_client_org,
       rv.carer_id, r.carer_id AS route_carer, r.second_carer_id AS route_second_carer,
       rv.status, rv.visit_date, to_char(rv.visit_time, 'HH24:MI') AS at,
       su.name AS service_user
FROM public.route_visits rv
LEFT JOIN public.routes r      ON r.id = rv.route_id
LEFT JOIN public.service_users su ON su.id = rv.service_user_id
WHERE rv.carer_id = 'c3bb12d7-86ca-4898-9e45-78a79b4c022a'
-- (5) Re-run the actual staff-app query AS the staff role to prove RLS
--     (this is exactly what getRouteCallsForCurrentCarer() sends)
SET ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"c3bb12d7-86ca-4898-9e45-78a79b4c022a","role":"authenticated"}', true);
SELECT '--- staff sees these route_visits ---';
SELECT id::text, carer_id, route_id, status, organisation_id
FROM public.route_visits
WHERE carer_id = 'c3bb12d7-86ca-4898-9e45-78a79b4c022a'
   OR route_id IN (
        SELECT id FROM public.routes
        WHERE second_carer_id = 'c3bb12d7-86ca-4898-9e45-78a79b4c022a'
   );
SELECT '--- staff sees these routes ---';
SELECT id::text, name, carer_id, second_carer_id, organisation_id
FROM public.routes
WHERE carer_id = 'c3bb12d7-86ca-4898-9e45-78a79b4c022a'
   OR second_carer_id = 'c3bb12d7-86ca-4898-9e45-78a79b4c022a';
RESET ROLE;
NOTIFY pgrst, 'reload schema';
   OR r.id IN (
        SELECT id FROM public.routes
        WHERE second_carer_id = 'c3bb12d7-86ca-4898-9e45-78a79b4c022a'
   )
ORDER BY rv.visit_date DESC, rv.visit_time;