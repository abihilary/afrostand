-- ===========================================================================
-- AFROSTAND - turn on Postgres Changes for chat.
-- ===========================================================================
-- Paste into the Supabase SQL editor and Run. Safe to re-run.
--
-- The app subscribes to inserts on `messages` (lib/core/api/repositories.dart,
-- subscribeToThread) and nothing ever added that table to the publication
-- Supabase replicates from. A table outside `supabase_realtime` emits nothing,
-- and the subscription still succeeds — so chat LOOKED like it worked: you saw
-- your own message, because the sender appends it optimistically, and the
-- other person's never arrived until you left the screen and came back.
--
-- This is also why it could not have been caught by the policy tests. Nothing
-- about it is a policy; the rows simply never leave the database.
-- ===========================================================================

do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    -- Local test databases have no such publication. The real project does.
    create publication supabase_realtime;
  end if;

  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table messages;
  end if;

  -- The thread list orders by last_message_at, which a trigger updates. With
  -- this, a conversation jumps to the top while the list is open.
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'threads'
  ) then
    alter publication supabase_realtime add table threads;
  end if;
end $$;

-- RLS still applies to what comes down the socket: Realtime evaluates the
-- subscriber's own policies, so a third party subscribing to someone else's
-- thread id receives nothing. `in_thread()` is doing that work, and
-- db/test/rls_test.sql asserts it.

-- Check:
--   select tablename from pg_publication_tables
--    where pubname = 'supabase_realtime' and schemaname = 'public';
