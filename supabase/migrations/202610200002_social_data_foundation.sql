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
    not exists (
      select 1 from public.user_blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = posts.author_id)
         or (b.blocker_id = posts.author_id and b.blocked_id = (select auth.uid()))
    )
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
    not exists (
      select 1 from public.user_blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = follows.follower_id)
         or (b.blocker_id = follows.follower_id and b.blocked_id = (select auth.uid()))
         or (b.blocker_id = (select auth.uid()) and b.blocked_id = follows.followed_id)
         or (b.blocker_id = follows.followed_id and b.blocked_id = (select auth.uid()))
    )
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
      join public.user_blocks b on
        (b.blocker_id = (select auth.uid()) and b.blocked_id = p.author_id)
        or (b.blocker_id = p.author_id and b.blocked_id = (select auth.uid()))
      where p.id = post_reactions.post_id
    )
    and not exists (
      select 1 from public.user_blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = post_reactions.user_id)
         or (b.blocker_id = post_reactions.user_id and b.blocked_id = (select auth.uid()))
    )
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
      join public.user_blocks b on
        (b.blocker_id = (select auth.uid()) and b.blocked_id = p.author_id)
        or (b.blocker_id = p.author_id and b.blocked_id = (select auth.uid()))
      where p.id = post_comments.post_id
    )
    and not exists (
      select 1 from public.user_blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = post_comments.author_id)
         or (b.blocker_id = post_comments.author_id and b.blocked_id = (select auth.uid()))
    )
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
