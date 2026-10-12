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
