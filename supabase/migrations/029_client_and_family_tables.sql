-- Add new roles to profiles role check constraint
ALTER TABLE public.profiles 
  DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check 
  CHECK (role IN (
    'carer', 
    'senior_carer', 
    'team_leader', 
    'manager', 
    'admin', 
    'super_admin',
    'client',
    'family_member',
    'inspector'
  ));

-- Create client_organisations table (separate from care organisations)
CREATE TABLE IF NOT EXISTS public.client_organisations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('care_home', 'warehouse', 'hospital', 'other')),
  address TEXT,
  contact_name TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.client_organisations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view client organisations in their org"
  ON public.client_organisations FOR SELECT
  USING (organisation_id = public.get_user_organisation_id());

CREATE POLICY "Managers can manage client organisations"
  ON public.client_organisations FOR ALL
  USING (
    organisation_id = public.get_user_organisation_id()
    AND public.get_user_role() IN ('manager', 'admin', 'super_admin')
  );

-- Create inspector_tokens table for temporary inspector access
CREATE TABLE IF NOT EXISTS public.inspector_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  inspector_name TEXT NOT NULL,
  inspector_organisation TEXT,
  created_by UUID REFERENCES auth.users(id),
  service_user_id UUID REFERENCES public.service_users(id) ON DELETE CASCADE,
  organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  accessed_at TIMESTAMPTZ,
  access_count INTEGER DEFAULT 0,
  max_accesses INTEGER DEFAULT 10,
  is_revoked BOOLEAN DEFAULT false,
  documents_scope TEXT[] DEFAULT ARRAY['care_plan', 'assessments', 'visit_logs'],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.inspector_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can manage tokens for their service user"
  ON public.inspector_tokens FOR ALL
  USING (
    created_by = auth.uid()
    AND organisation_id = public.get_user_organisation_id()
  );

CREATE POLICY "Inspectors can read their own token"
  ON public.inspector_tokens FOR SELECT
  USING (token = current_setting('app.inspector_token', true));

-- Create messages table for family-admin communication
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES auth.users(id),
  recipient_organisation_id UUID REFERENCES public.organisations(id),
  service_user_id UUID REFERENCES public.service_users(id),
  subject TEXT,
  body TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Family members can send and view their own messages"
  ON public.messages FOR ALL
  USING (
    sender_id = auth.uid()
    OR recipient_organisation_id = public.get_user_organisation_id()
  );

-- Create timesheet_confirmations table for client 2FA
CREATE TABLE IF NOT EXISTS public.timesheet_confirmations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_id UUID REFERENCES public.shifts(id) ON DELETE CASCADE,
  carer_id UUID REFERENCES auth.users(id),
  client_organisation_id UUID REFERENCES public.client_organisations(id),
  confirmed_by UUID REFERENCES auth.users(id),
  confirmed_at TIMESTAMPTZ DEFAULT NOW(),
  confirmation_method TEXT DEFAULT 'client_portal',
  organisation_id UUID REFERENCES public.organisations(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.timesheet_confirmations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Client users can confirm timesheets for their organisation"
  ON public.timesheet_confirmations FOR ALL
  USING (organisation_id = public.get_user_organisation_id());