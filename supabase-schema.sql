-- LeanBuild Community schema for Supabase Postgres.
-- Run the whole file in Supabase Dashboard -> SQL Editor -> New query.
-- Uses only the public/anon key in the browser; row-level security protects private data.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-zA-Z0-9_]{3,24}$'),
  display_name text not null default 'Athlete' check (char_length(display_name) between 1 and 40),
  bio text not null default '' check (char_length(bio) <= 160),
  role text not null default 'member' check (role in ('member','admin')),
  leaderboard_opt_in boolean not null default false,
  workout_count integer not null default 0 check (workout_count >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.private_tracker_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted')),
  created_at timestamptz not null default now(),
  constraint friend_not_self check (sender_id <> receiver_id),
  constraint unique_friend_pair unique (sender_id, receiver_id)
);

create table if not exists public.progress_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 500),
  created_at timestamptz not null default now()
);

create index if not exists friend_requests_sender_idx on public.friend_requests(sender_id);
create index if not exists friend_requests_receiver_idx on public.friend_requests(receiver_id);
create index if not exists progress_posts_created_idx on public.progress_posts(created_at desc);

-- This view exposes workout counts only for members who explicitly opt in.
-- The base profiles table does not grant authenticated users access to workout_count.
create or replace view public.leaderboard_public with (security_barrier = true) as
  select id, username, display_name, workout_count
  from public.profiles
  where leaderboard_opt_in = true;
revoke all on public.leaderboard_public from anon, public;
grant select on public.leaderboard_public to authenticated;

-- Ensure user profiles are created when an account signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
declare base_name text;
begin
  base_name := lower(regexp_replace(split_part(coalesce(new.email, 'athlete'), '@', 1), '[^a-zA-Z0-9_]', '', 'g'));
  if length(base_name) < 3 then base_name := 'athlete'; end if;
  base_name := left(base_name, 18);
  insert into public.profiles (id, username, display_name)
  values (new.id, base_name || '_' || left(replace(new.id::text, '-', ''), 5), coalesce(nullif(new.raw_user_meta_data->>'display_name',''), base_name))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_leanbuild on auth.users;
create trigger on_auth_user_created_leanbuild after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Keep leaderboard workout counts derived from private tracker data, not user-entered values.
create or replace function public.sync_workout_count()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  update public.profiles
  set workout_count = coalesce(jsonb_array_length(coalesce(new.payload->'sessions', '[]'::jsonb)), 0)
  where id = new.user_id;
  return new;
end;
$$;
drop trigger if exists private_data_sync_workouts on public.private_tracker_data;
create trigger private_data_sync_workouts after insert or update of payload on public.private_tracker_data
for each row execute procedure public.sync_workout_count();

-- Prevent users from granting themselves admin privileges or editing the derived count.
create or replace function public.protect_profile_fields()
returns trigger language plpgsql set search_path = public
as $$
begin
  if current_user not in ('postgres','service_role') and coalesce(auth.role(),'') <> 'service_role' then
    if new.role is distinct from old.role then raise exception 'Role changes must be performed by the project owner.'; end if;
    if new.workout_count is distinct from old.workout_count then raise exception 'Workout count is calculated automatically.'; end if;
  end if;
  return new;
end;
$$;
drop trigger if exists protect_profile_fields_trigger on public.profiles;
create trigger protect_profile_fields_trigger before update on public.profiles
for each row execute procedure public.protect_profile_fields();

create or replace function public.is_leanbuild_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'); $$;

alter table public.profiles enable row level security;
alter table public.private_tracker_data enable row level security;
alter table public.friend_requests enable row level security;
alter table public.progress_posts enable row level security;

-- Column-level grants prevent members from reading opted-out workout counts directly.
revoke select on public.profiles from anon, authenticated;
grant select (id, username, display_name, bio, role, leaderboard_opt_in, created_at) on public.profiles to authenticated;

drop policy if exists "Signed-in users can view community profiles" on public.profiles;
create policy "Signed-in users can view community profiles" on public.profiles for select to authenticated using (true);
drop policy if exists "Members can update their own public profile" on public.profiles;
create policy "Members can update their own public profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists "Members can insert their own profile" on public.profiles;
create policy "Members can insert their own profile" on public.profiles for insert to authenticated with check (id = auth.uid() and role = 'member');

-- A person's entire tracker JSON is private to that account.
drop policy if exists "Read own tracker data" on public.private_tracker_data;
create policy "Read own tracker data" on public.private_tracker_data for select to authenticated using (user_id = auth.uid());
drop policy if exists "Insert own tracker data" on public.private_tracker_data;
create policy "Insert own tracker data" on public.private_tracker_data for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "Update own tracker data" on public.private_tracker_data;
create policy "Update own tracker data" on public.private_tracker_data for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Only the participants can view their friend requests. Only the receiver can accept/delete an incoming request.
drop policy if exists "Participants can view friend requests" on public.friend_requests;
create policy "Participants can view friend requests" on public.friend_requests for select to authenticated using (sender_id = auth.uid() or receiver_id = auth.uid());
drop policy if exists "Members can send friend requests" on public.friend_requests;
create policy "Members can send friend requests" on public.friend_requests for insert to authenticated with check (sender_id = auth.uid() and status = 'pending');
drop policy if exists "Receiver can accept requests" on public.friend_requests;
create policy "Receiver can accept requests" on public.friend_requests for update to authenticated using (receiver_id = auth.uid() and status = 'pending') with check (receiver_id = auth.uid() and status = 'accepted');
drop policy if exists "Participants can remove requests" on public.friend_requests;
create policy "Participants can remove requests" on public.friend_requests for delete to authenticated using (sender_id = auth.uid() or receiver_id = auth.uid());

-- Posts are shared with signed-in community members; members can delete their own posts, admins can moderate any post.
drop policy if exists "Signed-in members can read community posts" on public.progress_posts;
create policy "Signed-in members can read community posts" on public.progress_posts for select to authenticated using (true);
drop policy if exists "Members can create their own posts" on public.progress_posts;
create policy "Members can create their own posts" on public.progress_posts for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "Authors and admins can delete posts" on public.progress_posts;
create policy "Authors and admins can delete posts" on public.progress_posts for delete to authenticated using (user_id = auth.uid() or public.is_leanbuild_admin());

-- Admin bootstrap: after you sign up, run this in SQL Editor, replacing the email:
-- update public.profiles set role = 'admin' where id = (select id from auth.users where email = 'YOUR-EMAIL@example.com');
