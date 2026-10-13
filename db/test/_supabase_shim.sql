-- Local-only stand-in for the parts of Supabase the migration leans on, so the
-- schema and its policies can be tested on a laptop before being pasted into
-- the dashboard. Never applied to the real project — it already has these.
create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  raw_user_meta_data jsonb not null default '{}'
);

-- Supabase derives auth.uid() from the request JWT. Locally we read the same
-- GUC the real one reads, so policies behave identically under test.
create or replace function auth.uid()
returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

-- The two roles PostgREST connects as.
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
end $$;
grant usage on schema public to anon, authenticated;
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant all on sequences to anon, authenticated;

-- Real Supabase grants these; without them `authenticated` cannot call
-- auth.uid() and every policy fails with "permission denied for schema auth",
-- which a test can easily mistake for the policy correctly denying something.
grant usage on schema auth to anon, authenticated;
grant select on auth.users to anon, authenticated;

-- A stand-in for the parts of Supabase Storage that 0003_storage.sql touches,
-- so the one-paste bundle can be run end to end on a laptop before it is
-- pasted anywhere. Real Supabase has all of this already.
create schema if not exists storage;
create table if not exists storage.buckets (
  id text primary key, name text, public boolean,
  file_size_limit bigint, allowed_mime_types text[]
);
create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets(id),
  name text, owner uuid
);
alter table storage.objects enable row level security;
create or replace function storage.foldername(n text)
returns text[] language sql immutable as $$ select string_to_array(n, '/') $$;
grant usage on schema storage to anon, authenticated;
grant select, insert, update, delete on storage.objects to anon, authenticated;
grant select on storage.buckets to anon, authenticated;
