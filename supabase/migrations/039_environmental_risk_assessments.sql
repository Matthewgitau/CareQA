-- Create environmental risk assessments table
create table if not exists environmental_risk_assessments (
  id uuid default gen_random_uuid() primary key,
  assessment_date date not null,
  assessor_name varchar(255) not null,
  location varchar(255) not null,
  lighting_adequacy assessment_status default 'good',
  ventilation assessment_status default 'good',
  temperature_control assessment_status default 'adequate',
  flooring_condition assessment_status default 'safe',
  walkways assessment_status default 'clear',
  stairs assessment_status default 'good',
  doors_exits assessment_status default 'accessible',
  fire_exits assessment_status default 'clear',
  emergency_lighting assessment_status default 'working',
  electrical_safety assessment_status default 'pat_tested',
  water_safety assessment_status default 'adequate',
  coshh_storage assessment_status default 'secure',
  waste_management assessment_status default 'appropriate',
  security assessment_status default 'secure',
  outdoor_areas assessment_status default 'safe',
  equipment_storage assessment_status default 'safe',
  risk_level risk_level default 'low',
  action_plan text,
  review_date date,
  photo_url text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint fk_environmental_assessor foreign key (assessor_name) references users(full_name) on delete set null
);

-- Create trigger for updated_at
create trigger update_environmental_risk_assessments_updated_at 
  before update on environmental_risk_assessments 
  for each row execute function update_updated_at_column();

-- Create indexes for performance
create index idx_environmental_assessments_date on environmental_risk_assessments(assessment_date);
create index idx_environmental_assessments_location on environmental_risk_assessments(location);
create index idx_environmental_assessments_risk_level on environmental_risk_assessments(risk_level);
create index idx_environmental_assessments_review_date on environmental_risk_assessments(review_date);

-- Create RLS policies
alter table environmental_risk_assessments enable row level security;

-- Allow authenticated users to view assessments for their care home
create policy "Users can view environmental assessments" on environmental_risk_assessments
  for select using (
    auth.uid() in (
      select user_id from carehome_users 
      where carehome_id = (
        select carehome_id from users where id = auth.uid()
      )
    )
  );

-- Allow authenticated users to insert assessments for their care home
create policy "Users can insert environmental assessments" on environmental_risk_assessments
  for insert with check (
    auth.uid() in (
      select user_id from carehome_users 
      where carehome_id = (
        select carehome_id from users where id = auth.uid()
      )
    )
  );

-- Allow authenticated users to update assessments for their care home
create policy "Users can update environmental assessments" on environmental_risk_assessments
  for update using (
    auth.uid() in (
      select user_id from carehome_users 
      where carehome_id = (
        select carehome_id from users where id = auth.uid()
      )
    )
  );

-- Allow authenticated users to delete assessments for their care home
create policy "Users can delete environmental assessments" on environmental_risk_assessments
  for delete using (
    auth.uid() in (
      select user_id from carehome_users 
      where carehome_id = (
        select carehome_id from users where id = auth.uid()
      )
    )
  );

-- Create function to get environmental assessments summary
create or replace function get_environmental_assessments_summary()
returns table (
  carehome_id uuid,
  total_assessments bigint,
  low_risk bigint,
  medium_risk bigint,
  high_risk bigint,
  critical_risk bigint,
  overdue_reviews bigint,
  average_risk_score numeric
)
language sql
security definer
as $$
  select 
    u.carehome_id,
    count(era.id)::bigint as total_assessments,
    count(case when era.risk_level = 'low' then 1 end)::bigint as low_risk,
    count(case when era.risk_level = 'medium' then 1 end)::bigint as medium_risk,
    count(case when era.risk_level = 'high' then 1 end)::bigint as high_risk,
    count(case when era.risk_level = 'critical' then 1 end)::bigint as critical_risk,
    count(case when era.review_date < current_date then 1 end)::bigint as overdue_reviews,
    avg(
      case era.risk_level
        when 'low' then 1
        when 'medium' then 2
        when 'high' then 3
        when 'critical' then 4
        else 0
      end
    ) as average_risk_score
  from users u
  left join environmental_risk_assessments era on u.carehome_id = (
    select carehome_id from users where id = auth.uid()
  )
  where u.id = auth.uid()
  group by u.carehome_id;
$$;

-- Create function to get urgent environmental assessments
create or replace function get_urgent_environmental_assessments()
returns table (
  id uuid,
  location varchar,
  risk_level risk_level,
  assessment_date date,
  review_date date,
  days_overdue integer
)
language sql
security definer
as $$
  select 
    era.id,
    era.location,
    era.risk_level,
    era.assessment_date,
    era.review_date,
    case 
      when era.review_date < current_date then (current_date - era.review_date)::integer
      else 0
    end as days_overdue
  from environmental_risk_assessments era
  where era.risk_level in ('high', 'critical') 
    or (era.review_date < current_date)
    and era.carehome_id = (
      select carehome_id from users where id = auth.uid()
    )
  order by 
    case era.risk_level when 'critical' then 1 when 'high' then 2 else 3 end,
    era.review_date asc;
$$;