-- =============================================
-- Migration 132: Fix reset_subuser_password RPC
--
-- The gen_salt()/crypt() functions live in the
-- 'extensions' schema (pgcrypto extension), but the
-- function had SET search_path = public, so it could
-- not find them. Add 'extensions' to the search_path.
-- =============================================

CREATE OR REPLACE FUNCTION public.reset_subuser_password(
  target_user_id uuid,
  new_password text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $function$
DECLARE
  v_overseer_id uuid;
BEGIN
  -- Validate the password
  IF new_password IS NULL OR length(new_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;

  -- Verify the caller is the overseer (parent) of the target sub-user
  SELECT overseer_id INTO v_overseer_id
  FROM public.profiles
  WHERE id = target_user_id
    AND is_active = true;

  IF v_overseer_id IS NULL THEN
    RAISE EXCEPTION 'Sub-user not found or inactive';
  END IF;

  IF v_overseer_id <> auth.uid() THEN
    RAISE EXCEPTION 'You can only reset passwords for sub-users you created';
  END IF;

  -- Reset the password in auth.users
  UPDATE auth.users
  SET encrypted_password = crypt(new_password, gen_salt('bf'))
  WHERE id = target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Auth user not found';
  END IF;

  RETURN true;
END;
$function$;

-- Grant execute to authenticated users
REVOKE ALL ON FUNCTION public.reset_subuser_password(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reset_subuser_password(uuid, text) TO authenticated;