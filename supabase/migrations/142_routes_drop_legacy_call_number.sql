-- ============================================================
-- MIGRATION 142: Remove legacy per-call constraints from `routes`
--
-- The `routes` table started life (migrations 104/116) as a
-- row-per-service-user-per-call design with:
--     call_number INTEGER NOT NULL
--     UNIQUE(client_organisation_id, service_user_id, route_date, call_number)
--
-- Migration 137 converted `routes` into a *route container* (a named
-- cluster of visits handled by route_visits), and made service_user_id /
-- proposed_start_time / proposed_end_time nullable — but it left
-- `call_number NOT NULL` behind.
--
-- Modern inserts (route_service.dart createRoute/createRouteWithVisits/
-- buildRoutesFromPreferences) never send call_number, so every
-- create-route attempt fails with:
--     null value in column "call_number" of relation "routes"
--     violates not null constraints  (SQLSTATE 23502)
--
-- Fix: drop NOT NULL on call_number and drop the legacy UNIQUE that
-- depends on it (NULLs are treated as distinct by a UNIQUE index, so
-- old rows + the container model coexist cleanly).
-- ============================================================

-- 1. Drop the legacy unique constraint (auto-named by migration 104's
--    inline `UNIQUE(...)`); also try the generic name in case a
--    different migration applied first.
ALTER TABLE public.routes
  DROP CONSTRAINT IF EXISTS routes_client_organisation_id_service_user_id_route_date_call_number_key;

-- 2. Let call_number be NULL (route containers don't have a "call number").
ALTER TABLE public.routes ALTER COLUMN call_number DROP NOT NULL;

-- 3. The container model keys uniqueness on (organisation, day, name),
--    not on (user, day, call_number). Add a targeted unique index is
--    optional; add a partial one on the modern org column to prevent
--    accidental duplicate route names per day per admin organisation.
CREATE UNIQUE INDEX IF NOT EXISTS idx_routes_org_date_name_unique
  ON public.routes(organisation_id, route_date, name)
  WHERE organisation_id IS NOT NULL AND name IS NOT NULL;

NOTIFY pgrst, 'reload schema';