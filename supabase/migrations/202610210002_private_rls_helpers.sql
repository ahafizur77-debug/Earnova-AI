-- Move SECURITY DEFINER policy helpers out of the exposed public API schema.
-- Apply after 202610210001_social_rls_hardening.sql.
create schema if not exists private;
revoke all on schema private from public;
revoke all on schema private from anon;
grant usage on schema private to authenticated;

create or replace function private.has_earnova_role(required_role text)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles ur
    where ur.user_id = (select auth.uid()) and ur.role = required_role
  );
$$;
revoke all on function private.has_earnova_role(text) from public;
revoke all on function private.has_earnova_role(text) from anon;
grant execute on function private.has_earnova_role(text) to authenticated;

create or replace function private.earnova_users_block_each_other(p_user_a uuid, p_user_b uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select case
    when (select auth.uid()) is null
      or ((select auth.uid()) <> p_user_a and (select auth.uid()) <> p_user_b)
    then false
    else exists (
      select 1 from public.user_blocks b
      where (b.blocker_id = p_user_a and b.blocked_id = p_user_b)
         or (b.blocker_id = p_user_b and b.blocked_id = p_user_a)
    )
  end;
$$;
revoke all on function private.earnova_users_block_each_other(uuid, uuid) from public;
revoke all on function private.earnova_users_block_each_other(uuid, uuid) from anon;
grant execute on function private.earnova_users_block_each_other(uuid, uuid) to authenticated;

drop policy if exists user_roles_select_self_or_admin on public.user_roles;
create policy user_roles_select_self_or_admin on public.user_roles
for select to authenticated using (user_id = (select auth.uid()) or private.has_earnova_role('admin'));
drop policy if exists admin_audit_select_admin on public.admin_audit_log;
create policy admin_audit_select_admin on public.admin_audit_log
for select to authenticated using (private.has_earnova_role('admin'));

drop policy if exists posts_select_authenticated on public.posts;
create policy posts_select_authenticated on public.posts for select to authenticated using (
  not private.earnova_users_block_each_other((select auth.uid()), posts.author_id)
);
drop policy if exists follows_read_authenticated on public.follows;
create policy follows_read_authenticated on public.follows for select to authenticated using (
  not private.earnova_users_block_each_other((select auth.uid()), follows.follower_id)
  and not private.earnova_users_block_each_other((select auth.uid()), follows.followed_id)
);
drop policy if exists follows_insert_self on public.follows;
create policy follows_insert_self on public.follows for insert to authenticated with check (
  follower_id = (select auth.uid())
  and not private.earnova_users_block_each_other((select auth.uid()), followed_id)
);

drop policy if exists reactions_read_authenticated on public.post_reactions;
create policy reactions_read_authenticated on public.post_reactions for select to authenticated using (
  exists (select 1 from public.posts p where p.id = post_reactions.post_id)
  and not exists (
    select 1 from public.posts p where p.id = post_reactions.post_id
      and private.earnova_users_block_each_other((select auth.uid()), p.author_id)
  )
  and not private.earnova_users_block_each_other((select auth.uid()), post_reactions.user_id)
);
drop policy if exists reactions_insert_self on public.post_reactions;
create policy reactions_insert_self on public.post_reactions for insert to authenticated with check (
  user_id = (select auth.uid())
  and exists (select 1 from public.posts p where p.id = post_reactions.post_id
    and not private.earnova_users_block_each_other((select auth.uid()), p.author_id))
);
drop policy if exists reactions_update_self on public.post_reactions;
create policy reactions_update_self on public.post_reactions for update to authenticated using (
  user_id = (select auth.uid())
  and exists (select 1 from public.posts p where p.id = post_reactions.post_id
    and not private.earnova_users_block_each_other((select auth.uid()), p.author_id))
) with check (
  user_id = (select auth.uid())
  and exists (select 1 from public.posts p where p.id = post_reactions.post_id
    and not private.earnova_users_block_each_other((select auth.uid()), p.author_id))
);

drop policy if exists comments_read_authenticated on public.post_comments;
create policy comments_read_authenticated on public.post_comments for select to authenticated using (
  exists (select 1 from public.posts p where p.id = post_comments.post_id)
  and not exists (select 1 from public.posts p where p.id = post_comments.post_id
    and private.earnova_users_block_each_other((select auth.uid()), p.author_id))
  and not private.earnova_users_block_each_other((select auth.uid()), post_comments.author_id)
);
drop policy if exists comments_insert_self on public.post_comments;
create policy comments_insert_self on public.post_comments for insert to authenticated with check (
  author_id = (select auth.uid())
  and exists (select 1 from public.posts p where p.id = post_comments.post_id
    and not private.earnova_users_block_each_other((select auth.uid()), p.author_id))
);
drop policy if exists comments_update_self on public.post_comments;
create policy comments_update_self on public.post_comments for update to authenticated using (
  author_id = (select auth.uid())
  and exists (select 1 from public.posts p where p.id = post_comments.post_id
    and not private.earnova_users_block_each_other((select auth.uid()), p.author_id))
) with check (
  author_id = (select auth.uid())
  and exists (select 1 from public.posts p where p.id = post_comments.post_id
    and not private.earnova_users_block_each_other((select auth.uid()), p.author_id))
);

drop function if exists public.has_earnova_role(text);
drop function if exists public.earnova_users_block_each_other(uuid, uuid);
