-- Earnova AI development-only bootstrap SQL
-- Target: a fresh, dedicated Supabase project named earnova-dev.
-- Review before running. Do NOT run against a production database.
-- This creates core/social tables and RLS policies; it does NOT connect the frontend.
-- Keep all service-role/secret keys and database passwords out of browser code and Git.
-- Source migrations are concatenated below in the required order.


-- ===== SOURCE supabase/migrations/202610200001_core_security.sql =====

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

-- ===== SOURCE supabase/migrations/202610200002_social_data_foundation.sql =====

-- Earnova AI social-data foundation (Supabase/PostgreSQL).
-- Review and apply only to a dedicated development Supabase project.
-- This migration is intentionally NOT applied to any live database.
-- Provider/service-role secrets must never be placed in browser code or Git.

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null default '' check (char_length(body) <= 5000),
  media_url text,
  media_type text not null default 'none' check (media_type in ('none', 'image', 'video')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint posts_require_body_or_media check (char_length(trim(body)) > 0 or media_url is not null),
  constraint posts_media_url_length check (media_url is null or char_length(media_url) <= 2048)
);

create table if not exists public.follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  followed_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followed_id),
  constraint follows_no_self_follow check (follower_id <> followed_id)
);

create table if not exists public.post_reactions (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction text not null default 'like' check (reaction in ('like', 'love', 'support', 'insightful')),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_no_self_block check (blocker_id <> blocked_id)
);

create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('post', 'comment', 'profile', 'job', 'message')),
  target_id text not null check (char_length(trim(target_id)) between 1 and 200),
  reason text not null check (reason in ('spam', 'harassment', 'scam', 'unsafe', 'copyright', 'other')),
  details text not null default '' check (char_length(details) <= 2000),
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at timestamptz not null default now(),
  constraint content_reports_target_unique unique (reporter_id, target_type, target_id)
);

create index if not exists posts_author_created_idx on public.posts (author_id, created_at desc);
create index if not exists posts_created_idx on public.posts (created_at desc);
create index if not exists follows_followed_idx on public.follows (followed_id, created_at desc);
create index if not exists reactions_post_idx on public.post_reactions (post_id, created_at desc);
create index if not exists comments_post_created_idx on public.post_comments (post_id, created_at);
create index if not exists blocks_blocked_idx on public.user_blocks (blocked_id);
create index if not exists reports_status_created_idx on public.content_reports (status, created_at);

-- RLS policies need to check blocks in both directions. This narrowly scoped
-- SECURITY DEFINER helper avoids the caller's own-row-only RLS on user_blocks
-- hiding reverse blocks during policy evaluation. It returns only a boolean.
create or replace function public.earnova_users_block_each_other(p_user_a uuid, p_user_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when (select auth.uid()) is null
      or ((select auth.uid()) <> p_user_a and (select auth.uid()) <> p_user_b)
    then false
    else exists (
      select 1
      from public.user_blocks b
      where (b.blocker_id = p_user_a and b.blocked_id = p_user_b)
         or (b.blocker_id = p_user_b and b.blocked_id = p_user_a)
    )
  end;
$$;

revoke all on function public.earnova_users_block_each_other(uuid, uuid) from public;
grant execute on function public.earnova_users_block_each_other(uuid, uuid) to authenticated;

alter table public.posts enable row level security;
alter table public.follows enable row level security;
alter table public.post_reactions enable row level security;
alter table public.post_comments enable row level security;
alter table public.user_blocks enable row level security;
alter table public.content_reports enable row level security;

-- Initial beta policy: signed-in users can read community content only when
-- neither side has blocked the other. Private/follower-only visibility remains
-- a separate launch requirement.
drop policy if exists posts_select_authenticated on public.posts;
create policy posts_select_authenticated on public.posts
  for select to authenticated using (
    not public.earnova_users_block_each_other((select auth.uid()), posts.author_id)
  );
drop policy if exists posts_insert_own on public.posts;
create policy posts_insert_own on public.posts
  for insert to authenticated with check (author_id = (select auth.uid()));
drop policy if exists posts_update_own on public.posts;
create policy posts_update_own on public.posts
  for update to authenticated using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()));
drop policy if exists posts_delete_own on public.posts;
create policy posts_delete_own on public.posts
  for delete to authenticated using (author_id = (select auth.uid()));

drop policy if exists follows_read_authenticated on public.follows;
create policy follows_read_authenticated on public.follows
  for select to authenticated using (
    not public.earnova_users_block_each_other((select auth.uid()), follows.follower_id)
    and not public.earnova_users_block_each_other((select auth.uid()), follows.followed_id)
  );
drop policy if exists follows_insert_self on public.follows;
create policy follows_insert_self on public.follows
  for insert to authenticated with check (follower_id = (select auth.uid()));
drop policy if exists follows_delete_self on public.follows;
create policy follows_delete_self on public.follows
  for delete to authenticated using (follower_id = (select auth.uid()));

drop policy if exists reactions_read_authenticated on public.post_reactions;
create policy reactions_read_authenticated on public.post_reactions
  for select to authenticated using (
    exists (
      select 1 from public.posts p
      where p.id = post_reactions.post_id
    )
    and not exists (
      select 1 from public.posts p
      where p.id = post_reactions.post_id
        and public.earnova_users_block_each_other((select auth.uid()), p.author_id)
    )
    and not public.earnova_users_block_each_other((select auth.uid()), post_reactions.user_id)
  );
drop policy if exists reactions_insert_self on public.post_reactions;
create policy reactions_insert_self on public.post_reactions
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists reactions_update_self on public.post_reactions;
create policy reactions_update_self on public.post_reactions
  for update to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
drop policy if exists reactions_delete_self on public.post_reactions;
create policy reactions_delete_self on public.post_reactions
  for delete to authenticated using (user_id = (select auth.uid()));

drop policy if exists comments_read_authenticated on public.post_comments;
create policy comments_read_authenticated on public.post_comments
  for select to authenticated using (
    exists (
      select 1 from public.posts p
      where p.id = post_comments.post_id
    )
    and not exists (
      select 1 from public.posts p
      where p.id = post_comments.post_id
        and public.earnova_users_block_each_other((select auth.uid()), p.author_id)
    )
    and not public.earnova_users_block_each_other((select auth.uid()), post_comments.author_id)
  );
drop policy if exists comments_insert_self on public.post_comments;
create policy comments_insert_self on public.post_comments
  for insert to authenticated with check (author_id = (select auth.uid()));
drop policy if exists comments_update_self on public.post_comments;
create policy comments_update_self on public.post_comments
  for update to authenticated using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()));
drop policy if exists comments_delete_self on public.post_comments;
create policy comments_delete_self on public.post_comments
  for delete to authenticated using (author_id = (select auth.uid()));

drop policy if exists blocks_read_own on public.user_blocks;
create policy blocks_read_own on public.user_blocks
  for select to authenticated using (blocker_id = (select auth.uid()));
drop policy if exists blocks_insert_self on public.user_blocks;
create policy blocks_insert_self on public.user_blocks
  for insert to authenticated with check (blocker_id = (select auth.uid()));
drop policy if exists blocks_delete_self on public.user_blocks;
create policy blocks_delete_self on public.user_blocks
  for delete to authenticated using (blocker_id = (select auth.uid()));

-- Users may submit reports, but cannot list or change moderation outcomes.
drop policy if exists reports_insert_self on public.content_reports;
create policy reports_insert_self on public.content_reports
  for insert to authenticated with check (reporter_id = (select auth.uid()));
-- No client SELECT/UPDATE/DELETE policies: moderation access belongs to trusted staff APIs.

-- ===== SOURCE supabase/migrations/202610210001_social_rls_hardening.sql =====

-- Earnova AI social RLS hardening.
-- Apply only after migrations 202610200001 and 202610200002 in the dedicated dev project.
-- This does not connect or deploy the frontend.

create or replace function public.earnova_users_block_each_other(p_user_a uuid, p_user_b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when (select auth.uid()) is null
      or ((select auth.uid()) <> p_user_a and (select auth.uid()) <> p_user_b)
    then false
    else exists (
      select 1
      from public.user_blocks b
      where (b.blocker_id = p_user_a and b.blocked_id = p_user_b)
         or (b.blocker_id = p_user_b and b.blocked_id = p_user_a)
    )
  end;
$$;

revoke all on function public.earnova_users_block_each_other(uuid, uuid) from public;
grant execute on function public.earnova_users_block_each_other(uuid, uuid) to authenticated;

-- Prevent creating follows that bypass either-direction block rules.
drop policy if exists follows_insert_self on public.follows;
create policy follows_insert_self on public.follows
  for insert to authenticated
  with check (
    follower_id = (select auth.uid())
    and not public.earnova_users_block_each_other((select auth.uid()), followed_id)
  );

-- A user must be allowed to see the target post before reacting/commenting.
drop policy if exists reactions_insert_self on public.post_reactions;
create policy reactions_insert_self on public.post_reactions
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.posts p
      where p.id = post_reactions.post_id
        and not public.earnova_users_block_each_other((select auth.uid()), p.author_id)
    )
  );

drop policy if exists reactions_update_self on public.post_reactions;
create policy reactions_update_self on public.post_reactions
  for update to authenticated
  using (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.posts p
      where p.id = post_reactions.post_id
        and not public.earnova_users_block_each_other((select auth.uid()), p.author_id)
    )
  )
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.posts p
      where p.id = post_reactions.post_id
        and not public.earnova_users_block_each_other((select auth.uid()), p.author_id)
    )
  );

drop policy if exists comments_insert_self on public.post_comments;
create policy comments_insert_self on public.post_comments
  for insert to authenticated
  with check (
    author_id = (select auth.uid())
    and exists (
      select 1 from public.posts p
      where p.id = post_comments.post_id
        and not public.earnova_users_block_each_other((select auth.uid()), p.author_id)
    )
  );

drop policy if exists comments_update_self on public.post_comments;
create policy comments_update_self on public.post_comments
  for update to authenticated
  using (
    author_id = (select auth.uid())
    and exists (
      select 1 from public.posts p
      where p.id = post_comments.post_id
        and not public.earnova_users_block_each_other((select auth.uid()), p.author_id)
    )
  )
  with check (
    author_id = (select auth.uid())
    and exists (
      select 1 from public.posts p
      where p.id = post_comments.post_id
        and not public.earnova_users_block_each_other((select auth.uid()), p.author_id)
    )
  );
