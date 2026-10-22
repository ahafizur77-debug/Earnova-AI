-- Earnova AI: real job listings and employer verification foundation.
-- Additive migration; does not create fake/sample listings or auto-verify employers.
create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 160),
  website_url text check (website_url is null or char_length(website_url) <= 2048),
  business_email text check (business_email is null or char_length(business_email) <= 320),
  description text not null default '' check (char_length(description) <= 5000),
  verification_status text not null default 'pending'
    check (verification_status in ('pending','verified','rejected','suspended')),
  verification_notes text not null default '' check (char_length(verification_notes) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  title text not null check (char_length(trim(title)) between 3 and 200),
  description text not null check (char_length(trim(description)) between 20 and 12000),
  location text not null default 'Not specified' check (char_length(location) <= 200),
  employment_type text not null default 'unspecified'
    check (employment_type in ('full_time','part_time','contract','internship','gig','unspecified')),
  salary_min numeric(12,2) check (salary_min is null or salary_min >= 0),
  salary_max numeric(12,2) check (salary_max is null or salary_max >= 0),
  salary_currency text not null default 'INR' check (salary_currency ~ '^[A-Z]{3}$'),
  source_type text not null default 'employer_submitted'
    check (source_type in ('employer_submitted','authorized_feed','public_source')),
  source_url text check (source_url is null or char_length(source_url) <= 2048),
  apply_url text check (apply_url is null or char_length(apply_url) <= 2048),
  source_checked_at timestamptz,
  status text not null default 'pending_review'
    check (status in ('pending_review','published','rejected','expired','paused')),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (salary_min is null or salary_max is null or salary_max >= salary_min),
  check (source_type = 'employer_submitted' or source_url is not null)
);

create index if not exists companies_owner_created_idx on public.companies(owner_id, created_at desc);
create index if not exists companies_verification_idx on public.companies(verification_status);
create index if not exists jobs_company_status_created_idx on public.jobs(company_id, status, created_at desc);
create index if not exists jobs_status_expiry_idx on public.jobs(status, expires_at);
create index if not exists jobs_location_type_idx on public.jobs(location, employment_type);

alter table public.companies enable row level security;
alter table public.jobs enable row level security;

-- Anyone may see verified company profiles; owners may see their own pending profile.
drop policy if exists companies_public_verified_or_owner_read on public.companies;
create policy companies_public_verified_or_owner_read on public.companies
  for select to anon, authenticated
  using (verification_status = 'verified' or owner_id = (select auth.uid()));

-- Owners may submit/edit only their own company, and cannot change verification state.
drop policy if exists companies_owner_insert_pending on public.companies;
create policy companies_owner_insert_pending on public.companies
  for insert to authenticated
  with check (owner_id = (select auth.uid()) and verification_status = 'pending');

drop policy if exists companies_owner_update_pending on public.companies;
create policy companies_owner_update_pending on public.companies
  for update to authenticated
  using (owner_id = (select auth.uid()) and verification_status = 'pending')
  with check (owner_id = (select auth.uid()) and verification_status = 'pending');

-- Only published jobs from verified companies are public. Employers can see their own drafts.
drop policy if exists jobs_public_published_verified on public.jobs;
create policy jobs_public_published_verified on public.jobs
  for select to anon, authenticated
  using (
    (status = 'published' and (expires_at is null or expires_at > now())
      and exists (select 1 from public.companies c
        where c.id = jobs.company_id and c.verification_status = 'verified'))
    or exists (select 1 from public.companies c
      where c.id = jobs.company_id and c.owner_id = (select auth.uid()))
  );

drop policy if exists jobs_employer_insert_pending on public.jobs;
create policy jobs_employer_insert_pending on public.jobs
  for insert to authenticated
  with check (
    created_by = (select auth.uid())
    and status = 'pending_review'
    and exists (select 1 from public.companies c
      where c.id = jobs.company_id and c.owner_id = (select auth.uid())
        and c.verification_status in ('pending','verified'))
  );

drop policy if exists jobs_employer_update_pending on public.jobs;
create policy jobs_employer_update_pending on public.jobs
  for update to authenticated
  using (created_by = (select auth.uid()) and status in ('pending_review','paused'))
  with check (
    created_by = (select auth.uid())
    and status in ('pending_review','paused')
    and exists (select 1 from public.companies c
      where c.id = jobs.company_id and c.owner_id = (select auth.uid()))
  );

grant select on public.companies, public.jobs to anon, authenticated;
grant insert, update on public.companies, public.jobs to authenticated;
