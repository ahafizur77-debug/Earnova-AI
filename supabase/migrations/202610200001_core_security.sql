-- Earnova AI core security foundation (Supabase/PostgreSQL)
-- Apply only to a fresh/compatible Supabase project after reviewing the migration.
-- Never put the service-role key in browser code or commit it to Git.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'moderator', 'admin')),
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users(id) on delete set null,
  primary key (user_id, role)
);

create table if not exists public.admin_audit_log (
  id bigint generated always as identity primary key,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null check (length(action) between 1 and 120),
  target_type text not null check (length(target_type) between 1 and 80),
  target_id text,
  request_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists admin_audit_log_created_at_idx on public.admin_audit_log (created_at desc);
create index if not exists admin_audit_log_actor_created_idx on public.admin_audit_log (actor_user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.admin_audit_log enable row level security;

create or replace function public.has_earnova_role(required_role text)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.user_roles ur where ur.user_id = (select auth.uid()) and ur.role = required_role);
$$;

revoke all on function public.has_earnova_role(text) from public;
grant execute on function public.has_earnova_role(text) to authenticated;

drop policy if exists profiles_select_authenticated on public.profiles;
create policy profiles_select_authenticated on public.profiles for select to authenticated using (true);
drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles for insert to authenticated with check (id = (select auth.uid()));
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists user_roles_select_self_or_admin on public.user_roles;
create policy user_roles_select_self_or_admin on public.user_roles for select to authenticated using (user_id = (select auth.uid()) or public.has_earnova_role('admin'));
-- Intentionally no client INSERT/UPDATE/DELETE policies for user_roles.
-- Grant roles only through a trusted server-side operator process.

drop policy if exists admin_audit_select_admin on public.admin_audit_log;
create policy admin_audit_select_admin on public.admin_audit_log for select to authenticated using (public.has_earnova_role('admin'));
-- Client writes to the audit log are intentionally disabled; trusted server-side code writes events.

comment on table public.user_roles is 'Privileged roles. Never allow end users to self-assign roles; grant only through trusted server-side operations.';
comment on table public.admin_audit_log is 'Administrative audit trail. Writes should be performed by trusted server-side operations.';
