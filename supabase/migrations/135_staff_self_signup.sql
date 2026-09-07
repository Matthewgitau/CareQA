-- Staff self-service sign-up
-- Staff enter their email + password, then select their carer record to confirm identity.
-- Only emails that exist in public.carers can sign up.

-- RPC 1: Find carers matching an email (for the selection step)
CREATE OR REPLACE FUNCTION public.find_carers_by_email(p_email text)
RETURNS TABLE (id uuid, name text, job_role text, staff_type text, organisation_id uuid)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $function$
BEGIN
  RETURN QUERY
  SELECT c.id, c.name, c.job_role, c.staff_type, c.organisation_id
  FROM public.carers c
  WHERE lower(c.email) = lower(p_email)
    AND c.is_active = true;
END;
$function$;
REVOKE ALL ON FUNCTION public.find_carers_by_email(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.find_carers_by_email(text) TO anon, authenticated;

-- RPC 2: Complete sign-up - create auth user + profile linked to a carer
CREATE OR REPLACE FUNCTION public.staff_signup(
  p_email text,
  p_password text,
  p_carer_id uuid,
  p_full_name text
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions
AS $function$
DECLARE
  v_carer RECORD;
  v_pwd_hash text;
  v_role text;
BEGIN
  -- Validate inputs
  IF p_email IS NULL OR p_email = '' THEN RAISE EXCEPTION 'Email is required'; END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN RAISE EXCEPTION 'Password must be at least 6 characters'; END IF;
  IF p_carer_id IS NULL THEN RAISE EXCEPTION 'Please select your carer record'; END IF;

  -- Verify the carer exists and email matches
  SELECT * INTO v_carer FROM public.carers WHERE id = p_carer_id AND is_active = true;
  IF NOT FOUND THEN RAISE EXCEPTION 'Carer record not found or inactive'; END IF;
  IF lower(v_carer.email) <> lower(p_email) THEN RAISE EXCEPTION 'Email does not match the selected carer record'; END IF;

  -- Determine role from staff_type
  v_role := COALESCE(v_carer.staff_type, v_carer.job_role, 'carer');
  IF v_role NOT IN ('carer','senior_carer','team_leader','manager','admin','super_admin') THEN
    v_role := 'carer';
  END IF;

  v_pwd_hash := crypt(p_password, gen_salt('bf'));

  -- If an auth user already exists for this carer, just update the password + email.
  -- Otherwise create the auth user with the carer's UUID as the ID.
  IF EXISTS (SELECT 1 FROM auth.users WHERE id = p_carer_id) THEN
    UPDATE auth.users
    SET email = p_email,
        encrypted_password = v_pwd_hash,
        raw_user_meta_data = jsonb_build_object('role', v_role, 'full_name', p_full_name),
        updated_at = now()
    WHERE id = p_carer_id;
  ELSE
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', p_carer_id, 'authenticated', 'authenticated',
      p_email, v_pwd_hash, now(),
      jsonb_build_object('provider','email','providers',jsonb_build_array('email')),
      jsonb_build_object('role', v_role, 'full_name', p_full_name),
      now(), now(), '', '', '', ''
    );
  END IF;

  -- Create profile linked to the carer
  INSERT INTO public.profiles (
    id, email, full_name, name, role, organisation_id, is_active
  ) VALUES (
    p_carer_id, p_email, p_full_name, p_full_name, v_role, v_carer.organisation_id, true
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    name = EXCLUDED.name,
    role = EXCLUDED.role,
    organisation_id = EXCLUDED.organisation_id,
    is_active = true;

  -- Mark carer as active
  UPDATE public.carers SET invite_status = 'active', is_active = true, updated_at = now()
  WHERE id = p_carer_id;

  RETURN true;
END;
$function$;
REVOKE ALL ON FUNCTION public.staff_signup(text, text, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.staff_signup(text, text, uuid, text) TO anon;