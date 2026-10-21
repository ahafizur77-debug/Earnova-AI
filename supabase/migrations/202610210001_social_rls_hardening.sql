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
