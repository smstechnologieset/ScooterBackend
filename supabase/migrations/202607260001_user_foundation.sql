-- ISOKO rider foundation: Auth-linked profiles, preferences, and private avatars.
-- Run this in the Supabase SQL Editor or through `supabase db push`.

do $$
begin
  create type public.user_account_status as enum ('active', 'suspended', 'deleted');
exception
  when duplicate_object then null;
end
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 80),
  avatar_path text check (
    avatar_path is null
    or avatar_path like id::text || '/%'
  ),
  status public.user_account_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  language_code text not null default 'en' check (language_code in ('en', 'rw', 'fr')),
  currency_code text not null default 'RWF' check (currency_code in ('RWF', 'USD')),
  distance_unit text not null default 'km' check (distance_unit in ('km', 'mi')),
  ride_notifications boolean not null default true,
  marketing_notifications boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists user_preferences_set_updated_at on public.user_preferences;
create trigger user_preferences_set_updated_at
before update on public.user_preferences
for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  initial_name text;
begin
  initial_name := nullif(trim(new.raw_user_meta_data ->> 'full_name'), '');
  if initial_name is null then
    initial_name := split_part(coalesce(new.email, new.phone, 'ISOKO Rider'), '@', 1);
  end if;
  if char_length(initial_name) < 2 then
    initial_name := 'ISOKO Rider';
  end if;

  insert into public.profiles (id, display_name)
  values (new.id, left(initial_name, 80))
  on conflict (id) do nothing;

  insert into public.user_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

revoke execute on function public.set_updated_at() from public, anon, authenticated;
revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;

-- Backfill profiles/preferences if Auth users were created before this migration.
insert into public.profiles (id, display_name)
select
  user_record.id,
  left(case
    when char_length(coalesce(
      nullif(trim(user_record.raw_user_meta_data ->> 'full_name'), ''),
      split_part(coalesce(user_record.email, user_record.phone, 'ISOKO Rider'), '@', 1)
    )) < 2 then 'ISOKO Rider'
    else coalesce(
      nullif(trim(user_record.raw_user_meta_data ->> 'full_name'), ''),
      split_part(coalesce(user_record.email, user_record.phone, 'ISOKO Rider'), '@', 1)
    )
  end, 80)
from auth.users as user_record
on conflict (id) do nothing;

insert into public.user_preferences (user_id)
select profile.id from public.profiles as profile
on conflict (user_id) do nothing;

alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.user_preferences from anon, authenticated;

grant select on table public.profiles to authenticated;
grant update (display_name, avatar_path) on table public.profiles to authenticated;

grant select on table public.user_preferences to authenticated;
grant update (
  language_code,
  currency_code,
  distance_unit,
  ride_notifications,
  marketing_notifications
) on table public.user_preferences to authenticated;

drop policy if exists "Riders can read their own profile" on public.profiles;
create policy "Riders can read their own profile"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "Riders can update their own profile" on public.profiles;
create policy "Riders can update their own profile"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists "Riders can read their own preferences" on public.user_preferences;
create policy "Riders can read their own preferences"
on public.user_preferences
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Riders can update their own preferences" on public.user_preferences;
create policy "Riders can update their own preferences"
on public.user_preferences
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Private object storage. Object names must be: <auth-user-id>/<filename>.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'avatars',
  'avatars',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Riders can read their own avatars" on storage.objects;
create policy "Riders can read their own avatars"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Riders can upload their own avatars" on storage.objects;
create policy "Riders can upload their own avatars"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Riders can update their own avatars" on storage.objects;
create policy "Riders can update their own avatars"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Riders can delete their own avatars" on storage.objects;
create policy "Riders can delete their own avatars"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
