-- ===========================================================================
-- AFROSTAND — storage buckets and their policies.
-- ===========================================================================
-- Paste into the Supabase SQL editor and Run. Safe to re-run.
--
-- A bucket is a row in storage.buckets, so this does not need the dashboard.
-- The policies matter as much as the buckets: storage.objects has RLS on by
-- default in Supabase, and a bucket with no policy is a bucket nobody can
-- write to — which surfaces as "new row violates row-level security policy"
-- halfway through listing a product.
--
-- The object key is `<uid>/<timestamp>.<ext>` (see lib/core/api/storage.dart).
-- Every write policy below checks that the first path segment is the caller's
-- own id, so one seller cannot overwrite another's photographs. If that key
-- shape changes, these change with it.
-- ===========================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  -- Public read: a product photo is the shop window, and signing every URL
  -- would mean the catalogue could not be cached or shared.
  ('product-images', 'product-images', true, 5242880,
   array['image/jpeg', 'image/png', 'image/webp']),
  ('avatars', 'avatars', true, 2097152,
   array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- A size limit and a mime allow-list are not tidiness. Without them any
-- signed-in account can push arbitrary files of arbitrary size into a public
-- bucket on your project's quota, and serve them from your domain.

-- ── Reading ────────────────────────────────────────────────────────────────
drop policy if exists "afrostand images are public" on storage.objects;
create policy "afrostand images are public"
  on storage.objects for select
  using (bucket_id in ('product-images', 'avatars'));

-- ── Writing: your own folder, nobody else's ────────────────────────────────
drop policy if exists "afrostand upload own folder" on storage.objects;
create policy "afrostand upload own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id in ('product-images', 'avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "afrostand update own files" on storage.objects;
create policy "afrostand update own files"
  on storage.objects for update
  to authenticated
  using (
    bucket_id in ('product-images', 'avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id in ('product-images', 'avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "afrostand delete own files" on storage.objects;
create policy "afrostand delete own files"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id in ('product-images', 'avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Check it took:
--   select id, public, file_size_limit from storage.buckets
--    where id in ('product-images', 'avatars');
