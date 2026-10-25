-- Earnova Reels: public playback, authenticated uploads, owner-scoped object paths.
-- Public bucket means anyone with a video URL can watch it; uploads/deletes remain owner-scoped.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('earnova-reels', 'earnova-reels', true, 52428800, array['video/mp4','video/webm','video/quicktime'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create table if not exists public.reels (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  caption text not null default '' check (char_length(caption) <= 500),
  video_path text not null unique check (char_length(video_path) <= 1024),
  video_url text not null check (char_length(video_url) <= 2048),
  mime_type text not null check (mime_type in ('video/mp4','video/webm','video/quicktime')),
  size_bytes bigint not null check (size_bytes > 0 and size_bytes <= 52428800),
  created_at timestamptz not null default now()
);

alter table public.reels enable row level security;
grant select on public.reels to anon, authenticated;
grant insert, delete on public.reels to authenticated;

drop policy if exists "Anyone can view reels" on public.reels;
create policy "Anyone can view reels" on public.reels for select to anon, authenticated using (true);
drop policy if exists "Users can publish their own reels" on public.reels;
create policy "Users can publish their own reels" on public.reels for insert to authenticated
with check (author_id = (select auth.uid()));
drop policy if exists "Users can delete their own reels" on public.reels;
create policy "Users can delete their own reels" on public.reels for delete to authenticated
using (author_id = (select auth.uid()));

drop policy if exists "Public can read Earnova reel files" on storage.objects;
create policy "Public can read Earnova reel files" on storage.objects for select to anon, authenticated
using (bucket_id = 'earnova-reels');
drop policy if exists "Users upload reels to their own folder" on storage.objects;
create policy "Users upload reels to their own folder" on storage.objects for insert to authenticated
with check (bucket_id = 'earnova-reels' and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists "Users delete reels from their own folder" on storage.objects;
create policy "Users delete reels from their own folder" on storage.objects for delete to authenticated
using (bucket_id = 'earnova-reels' and (storage.foldername(name))[1] = (select auth.uid())::text);
