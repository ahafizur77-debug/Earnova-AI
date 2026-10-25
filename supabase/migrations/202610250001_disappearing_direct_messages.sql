-- Earnova AI direct messaging and disappearing media foundation.
-- Apply to the dedicated Earnova Supabase project only.
-- No service-role key belongs in browser code or Git.
create extension if not exists pgcrypto;

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table if not exists public.dm_conversations (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);
create table if not exists public.dm_conversation_members (
  conversation_id uuid not null references public.dm_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id,user_id)
);
create table if not exists public.dm_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.dm_conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null default '',
  media_path text,
  media_type text check (media_type in ('image','video')),
  media_mode text check (media_mode in ('view_once','view_twice','unlimited')),
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  constraint dm_message_has_content check (length(trim(body))>0 or media_path is not null),
  constraint dm_message_body_length check (length(body)<=2000)
);
create table if not exists public.dm_message_views (
  message_id uuid not null references public.dm_messages(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  views_count integer not null default 0 check (views_count>=0 and views_count<=2),
  last_viewed_at timestamptz,
  primary key (message_id,user_id)
);
create index if not exists dm_conversations_created_by_idx on public.dm_conversations(created_by);
create index if not exists dm_message_views_user_idx on public.dm_message_views(user_id);
create index if not exists dm_messages_sender_idx on public.dm_messages(sender_id);
create index if not exists dm_members_user_idx on public.dm_conversation_members(user_id,conversation_id);
create index if not exists dm_messages_conversation_created_idx on public.dm_messages(conversation_id,created_at);
alter table public.dm_conversations enable row level security;
alter table public.dm_conversation_members enable row level security;
alter table public.dm_messages enable row level security;
alter table public.dm_message_views enable row level security;

create or replace function private.is_dm_member(conversation_uuid uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
 select auth.uid() is not null and exists(select 1 from public.dm_conversation_members m where m.conversation_id=conversation_uuid and m.user_id=auth.uid());
$$;
revoke all on function private.is_dm_member(uuid) from public, anon;
grant execute on function private.is_dm_member(uuid) to authenticated;

drop policy if exists "Members can read their conversations" on public.dm_conversations;
create policy "Members can read their conversations" on public.dm_conversations for select to authenticated using (private.is_dm_member(id));
drop policy if exists "Authenticated can create their conversations" on public.dm_conversations;
create policy "Authenticated can create their conversations" on public.dm_conversations for insert to authenticated with check (created_by=(select auth.uid()));
drop policy if exists "Members can read conversation membership" on public.dm_conversation_members;
create policy "Members can read conversation membership" on public.dm_conversation_members for select to authenticated using (private.is_dm_member(conversation_id));
drop policy if exists "Users can join conversations through RPC only" on public.dm_conversation_members;
create policy "Users can join conversations through RPC only" on public.dm_conversation_members for insert to authenticated with check (user_id=(select auth.uid()) and exists(select 1 from public.dm_conversations c where c.id=conversation_id and c.created_by=(select auth.uid())));
drop policy if exists "Members can read messages" on public.dm_messages;
create policy "Members can read messages" on public.dm_messages for select to authenticated using (private.is_dm_member(conversation_id));
drop policy if exists "Members can send messages as themselves" on public.dm_messages;
create policy "Members can send messages as themselves" on public.dm_messages for insert to authenticated with check (sender_id=(select auth.uid()) and private.is_dm_member(conversation_id));
drop policy if exists "Users can read their own media view state" on public.dm_message_views;
create policy "Users can read their own media view state" on public.dm_message_views for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists "Users can record their own media views" on public.dm_message_views;
create policy "Users can record their own media views" on public.dm_message_views for insert to authenticated with check (user_id=(select auth.uid()) and exists(select 1 from public.dm_messages msg where msg.id=message_id and msg.sender_id<>(select auth.uid()) and private.is_dm_member(msg.conversation_id)));
drop policy if exists "Users can update their own media views" on public.dm_message_views;
create policy "Users can update their own media views" on public.dm_message_views for update to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()) and views_count<=2);
grant select,insert on public.dm_conversations to authenticated;
grant select,insert on public.dm_conversation_members to authenticated;
grant select,insert on public.dm_messages to authenticated;
grant select,insert,update on public.dm_message_views to authenticated;

create or replace function public.create_direct_conversation(target_user uuid)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare caller uuid:=auth.uid(); conv_id uuid;
begin
 if caller is null then raise exception 'Sign in required'; end if;
 if target_user is null or target_user=caller then raise exception 'Choose another user'; end if;
 if not exists(select 1 from auth.users u where u.id=target_user) then raise exception 'User not found'; end if;
 select c.id into conv_id from public.dm_conversations c
 join public.dm_conversation_members a on a.conversation_id=c.id and a.user_id=caller
 join public.dm_conversation_members b on b.conversation_id=c.id and b.user_id=target_user
 where (select count(*) from public.dm_conversation_members n where n.conversation_id=c.id)=2 limit 1;
 if conv_id is not null then return conv_id; end if;
 insert into public.dm_conversations(created_by) values(caller) returning id into conv_id;
 insert into public.dm_conversation_members(conversation_id,user_id) values(conv_id,caller),(conv_id,target_user);
 return conv_id;
end;
$$;
revoke all on function public.create_direct_conversation(uuid) from public,anon;
grant execute on function public.create_direct_conversation(uuid) to authenticated;

create or replace function public.consume_disappearing_media(message_uuid uuid)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare caller uuid:=auth.uid(); msg public.dm_messages%rowtype; current_views integer:=0;
begin
 if caller is null then raise exception 'Sign in required'; end if;
 select * into msg from public.dm_messages where id=message_uuid;
 if not found or msg.media_path is null then raise exception 'Media not found'; end if;
 if not private.is_dm_member(msg.conversation_id) then raise exception 'Not a conversation member'; end if;
 if msg.sender_id=caller or msg.media_mode='unlimited' then return true; end if;
 if msg.expires_at is not null and msg.expires_at<=now() then return false; end if;
 insert into public.dm_message_views(message_id,user_id,views_count,last_viewed_at) values(message_uuid,caller,1,now())
 on conflict(message_id,user_id) do update set views_count=public.dm_message_views.views_count+1,last_viewed_at=now()
 where public.dm_message_views.views_count<2 returning views_count into current_views;
 if current_views is null then return false; end if;
 if (msg.media_mode='view_once' and current_views>=1) or (msg.media_mode='view_twice' and current_views>=2) then
   update public.dm_messages set expires_at=now() where id=message_uuid;
 end if;
 return true;
end;
$$;
revoke all on function public.consume_disappearing_media(uuid) from public,anon;
grant execute on function public.consume_disappearing_media(uuid) to authenticated;

create or replace function public.touch_dm_conversation_on_message()
returns trigger language plpgsql security definer set search_path = ''
as $$ begin update public.dm_conversations set last_message_at=new.created_at where id=new.conversation_id; return new; end; $$;
drop trigger if exists dm_message_touch_conversation on public.dm_messages;
create trigger dm_message_touch_conversation after insert on public.dm_messages for each row execute function public.touch_dm_conversation_on_message();
revoke all on function public.touch_dm_conversation_on_message() from public, anon, authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('earnova-dm-media','earnova-dm-media',false,10485760,array['image/jpeg','image/png','image/webp','video/mp4','video/webm','video/quicktime'])
on conflict(id) do update set public=false,file_size_limit=10485760,allowed_mime_types=array['image/jpeg','image/png','image/webp','video/mp4','video/webm','video/quicktime'];
drop policy if exists "DM members can upload media" on storage.objects;
create policy "DM members can upload media" on storage.objects for insert to authenticated with check (bucket_id='earnova-dm-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "DM media owners and conversation members can read" on storage.objects;
create policy "DM media owners and conversation members can read" on storage.objects for select to authenticated using (
 bucket_id='earnova-dm-media' and (
  (storage.foldername(name))[1]=(select auth.uid())::text
  or exists(select 1 from public.dm_messages msg join public.dm_conversation_members m on m.conversation_id=msg.conversation_id
   left join public.dm_message_views v on v.message_id=msg.id and v.user_id=(select auth.uid())
   where msg.media_path=name and m.user_id=(select auth.uid()) and (
    msg.media_mode='unlimited' or ((msg.expires_at is null or msg.expires_at>now()) and
     ((msg.media_mode='view_once' and coalesce(v.views_count,0)<1) or (msg.media_mode='view_twice' and coalesce(v.views_count,0)<2)))
   ))
 )
);
