-- Admin carer password/login management
-- Creates/updates auth user + profiles row for a carer.
-- Lets admins set/reset a carer's staff-app password on Add/Edit.
CREATE OR REPLACE FUNCTION public.admin_upsert_carer_auth(
  p_carer_id uuid,
  p_email text,
  p_full_name text,
  p_password text,
  p_role text,
  p_organisation_id uuid,
  p_invited_by uuid
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $function$
DECLARE v_auth_exists boolean; v_pwd_hash text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','super_admin','manager')) THEN
    RAISE EXCEPTION 'Only admins or managers can manage carer logins';
  END IF;
  IF p_carer_id IS NULL THEN RAISE EXCEPTION 'carer id is required'; END IF;
  IF p_email IS NULL OR p_email = '' THEN RAISE EXCEPTION 'Email is required'; END IF;
  IF p_role IS NULL OR p_role = '' THEN RAISE EXCEPTION 'Role is required'; END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN RAISE EXCEPTION 'Password must be at least 6 characters'; END IF;
  v_pwd_hash := crypt(p_password, gen_salt('bf'));
  SELECT EXISTS (SELECT 1 FROM auth.users WHERE id = p_carer_id) INTO v_auth_exists;

  IF NOT v_auth_exists THEN
    INSERT INTO auth.users (instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,confirmation_token,email_change,email_change_token_new,recovery_token)
    VALUES ('00000000-0000-0000-0000-000000000000',p_carer_id,'authenticated','authenticated',p_email,v_pwd_hash,now(),jsonb_build_object('provider','email','providers',jsonb_build_array('email')),jsonb_build_object('role',p_role,'full_name',p_full_name),now(),now(),'','','','');
  ELSE
    UPDATE auth.users SET email=p_email, encrypted_password=v_pwd_hash, raw_user_meta_data=jsonb_build_object('role',p_role,'full_name',p_full_name), updated_at=now() WHERE id=p_carer_id;
  END IF;

  INSERT INTO public.profiles (id,email,full_name,name,role,organisation_id,overseer_id,is_active)
  VALUES (p_carer_id,p_email,p_full_name,p_full_name,p_role,p_organisation_id,p_invited_by,true)
  ON CONFLICT (id) DO UPDATE SET email=EXCLUDED.email, full_name=EXCLUDED.full_name, name=EXCLUDED.name, role=EXCLUDED.role, organisation_id=EXCLUDED.organisation_id, overseer_id=EXCLUDED.overseer_id, is_active=true;

  UPDATE public.carers SET invite_status='active', is_active=true, updated_at=now() WHERE id=p_carer_id;
  RETURN true;
END;
$function$;
REVOKE ALL ON FUNCTION public.admin_upsert_carer_auth(uuid,text,text,text,text,uuid,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_carer_auth(uuid,text,text,text,text,uuid,uuid) TO authenticated;