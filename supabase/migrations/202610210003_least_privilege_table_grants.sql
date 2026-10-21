-- Apply least-privilege grants for exposed tables. RLS policies remain the row-level gate.
revoke all privileges on all tables in schema public from public;
revoke all privileges on all tables in schema public from anon;

grant select, insert, update, delete on public.profiles to authenticated;
grant select on public.user_roles to authenticated;
grant select on public.admin_audit_log to authenticated;
grant select, insert, update, delete on public.posts to authenticated;
grant select, insert, delete on public.follows to authenticated;
grant select, insert, update, delete on public.post_reactions to authenticated;
grant select, insert, update, delete on public.post_comments to authenticated;
grant select, insert, delete on public.user_blocks to authenticated;
grant insert on public.content_reports to authenticated;
