-- ============================================================
-- MIGRATION 156: Notification archive
--
-- Adds an `archived_at` column to the public.notifications table so
-- the admin-app notification hub can hide a notification without
-- deleting it. The Dart UI exposes long-press -> "Archive" and a
-- dedicated "Archived" tab (see admin-app/lib/services/notification_service.dart
-- and admin-app/lib/ui/notifications/notification_hub_screen.dart).
--
-- Notes:
--   * This migration is purely additive - no rows are modified.
--   * A partial index makes the "active" view fast (the default
--     filter on the hub is `archived_at IS NULL`).
--   * RLS UPDATE was already granted in migration 155, so this
--     migration just re-confirms it.
-- ============================================================

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

-- Partial index: only the active (non-archived) rows are queried by
-- the default hub view, so we don't need to index archived rows.
CREATE INDEX IF NOT EXISTS idx_notifications_active
  ON public.notifications(user_id, created_at DESC)
  WHERE archived_at IS NULL;

-- Confirm the existing UPDATE grant - no-op if already present.
GRANT SELECT, UPDATE ON public.notifications TO authenticated;

-- RLS: keep the existing 155 policy. UPDATE already covers archived_at.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'notifications'
      AND policyname = 'Users can mark notifications read'
  ) THEN
    EXECUTE $POL$
      CREATE POLICY "Users can mark notifications read"
        ON public.notifications
        FOR UPDATE TO authenticated
        USING (TRUE)
        WITH CHECK (TRUE);
    $POL$;
  END IF;
END
$$;

NOTIFY pgrst, 'reload schema';
