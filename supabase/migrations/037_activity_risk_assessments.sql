-- Create enum types for activity risk assessments
create type if not exists activity_type as enum (
    'bathing', 'dressing', 'toileting', 'mobility', 'eating', 'drinking', 
    'cooking', 'cleaning', 'shopping', 'appointments', 'visits', 'outings', 
    'hobbies', 'exercise', 'personal_care'
);

create type if not exists frequency_type as enum (
    'daily', 'multiple_times_per_day', 'weekly', 'monthly', 'occasionally', 'as_needed'
);

create type if not exists support_level_type as enum (
    'independent', 'supervision', 'assistance', 'full_assistance'
);

-- Create activity_risk_assessments table
create table if not exists public.activity_risk_assessments (
    id uuid default gen_random_uuid() primary key,
    service_user_id uuid not null references public.service_users(id) on delete cascade,
    assessor_id uuid not null references auth.users(id),
    activity_type activity_type not null,
    frequency frequency_type not null,
    support_level support_level_type not null,
    equipment_required text[] default '{}',
    identified_risks text[] default '{}',
    risk_level risk_level_type not null,
    control_measures text[] default '{}',
    staff_competency_required text[] default '{}',
    emergency_procedures text default '',
    review_date date not null,
    status assessment_status_type default 'pending',
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    submitted_at timestamp with time zone,
    submitted_by uuid references auth.users(id),
    escalated_at timestamp with time zone,
    escalated_by uuid references auth.users(id),
    completed_at timestamp with time zone,
    completed_by uuid references auth.users(id),
    notes text,
    assessment_data jsonb default '{}'
);

-- Create index for performance
create index if not exists idx_activity_risk_assessments_service_user on public.activity_risk_assessments(service_user_id);
create index if not exists idx_activity_risk_assessments_assessor on public.activity_risk_assessments(assessor_id);
create index if not exists idx_activity_risk_assessments_activity_type on public.activity_risk_assessments(activity_type);
create index if not exists idx_activity_risk_assessments_risk_level on public.activity_risk_assessments(risk_level);
create index if not exists idx_activity_risk_assessments_status on public.activity_risk_assessments(status);
create index if not exists idx_activity_risk_assessments_review_date on public.activity_risk_assessments(review_date);

-- Create trigger for updated_at
create trigger handle_updated_at before update on public.activity_risk_assessments 
    for each row execute procedure moddatetime(updated_at);

-- Enable RLS
alter table public.activity_risk_assessments enable row level security;

-- RLS Policies
create policy "Users can view their own assessments" on public.activity_risk_assessments
    for select using (
        auth.uid() = assessor_id or 
        auth.uid() in (select user_id from public.carers where service_user_id = activity_risk_assessments.service_user_id)
    );

create policy "Users can insert their own assessments" on public.activity_risk_assessments
    for insert with check (auth.uid() = assessor_id);

create policy "Users can update their own assessments" on public.activity_risk_assessments
    for update using (auth.uid() = assessor_id);

create policy "Users can delete their own assessments" on public.activity_risk_assessments
    for delete using (auth.uid() = assessor_id);

-- Insert sample data
insert into public.activity_risk_assessments (
    service_user_id,
    assessor_id,
    activity_type,
    frequency,
    support_level,
    equipment_required,
    identified_risks,
    risk_level,
    control_measures,
    staff_competency_required,
    emergency_procedures,
    review_date,
    status,
    notes
) values 
(
    (select id from public.service_users limit 1),
    (select id from auth.users limit 1),
    'bathing',
    'daily',
    'assistance',
    array['hoist', 'shower chair'],
    array['slips and falls', 'pressure sores'],
    'medium',
    array['non-slip mats', 'proper positioning'],
    array['manual handling', 'infection control'],
    'Call for assistance if falls occur, apply pressure to wounds',
    current_date + interval '6 months',
    'pending',
    'Initial assessment for bathing activities'
),
(
    (select id from public.service_users limit 1),
    (select id from auth.users limit 1),
    'mobility',
    'multiple_times_per_day',
    'supervision',
    array['walking frame', 'grab rails'],
    array['falls', 'balance issues'],
    'high',
    array['supervision required', 'clear pathways'],
    array['falls prevention', 'mobility assistance'],
    'Call emergency services if serious fall occurs',
    current_date + interval '3 months',
    'escalated',
    'High risk due to balance issues and previous falls'
),
(
    (select id from public.service_users offset 1 limit 1),
    (select id from auth.users limit 1),
    'eating',
    'daily',
    'independent',
    array['adaptive cutlery'],
    array['choking', 'swallowing difficulties'],
    'low',
    array['cut food into small pieces', 'supervise initially'],
    array['choking first aid'],
    'Perform Heimlich maneuver if choking occurs',
    current_date + interval '12 months',
    'completed',
    'Completed after successful implementation of control measures'
);