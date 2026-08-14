ALTER TABLE service_users 
ADD COLUMN IF NOT EXISTS reference_code text,
ADD COLUMN IF NOT EXISTS date_of_birth date,
ADD COLUMN IF NOT EXISTS nhs_number text,
ADD COLUMN IF NOT EXISTS gp_name text,
ADD COLUMN IF NOT EXISTS gp_phone text,
ADD COLUMN IF NOT EXISTS family_contact_name text,
ADD COLUMN IF NOT EXISTS family_contact_phone text,
ADD COLUMN IF NOT EXISTS family_contact_relation text,
ADD COLUMN IF NOT EXISTS family_contact_email text,
ADD COLUMN IF NOT EXISTS medication_list jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS respect_form_url text,
ADD COLUMN IF NOT EXISTS care_plan_url text;

CREATE TABLE IF NOT EXISTS service_user_calls (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  service_user_id uuid NOT NULL REFERENCES service_users(id) ON DELETE CASCADE,
  organisation_id uuid,
  calls_per_day integer NOT NULL DEFAULT 1,
  call_times jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);