-- Add indexes for foreign keys flagged by the Supabase performance advisor.
-- Safe additive migration; does not alter existing rows or access policies.
create index if not exists post_comments_author_id_idx on public.post_comments (author_id);
create index if not exists post_reactions_user_id_idx on public.post_reactions (user_id);
create index if not exists user_roles_granted_by_idx on public.user_roles (granted_by);
