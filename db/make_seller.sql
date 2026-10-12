-- ===========================================================================
-- Turn an existing account into an approved seller.
-- ===========================================================================
-- EDIT ONE LINE — v_email, just below — then paste the whole file and Run.
--
-- This is the admin path for now. There is no approval screen in the app, and
-- a button that silently did nothing would be worse than being honest that
-- approval happens here.
--
-- The account must already exist. Register in the app, or Authentication →
-- Users → Add user with "Auto Confirm User" ticked — no mail provider is
-- configured, so an unconfirmed user can never sign in.
-- ===========================================================================

do $$
declare
  v_email text := 'CHANGE-ME@example.com';   -- <<<<<< EDIT THIS
  v_shop  text := 'Ma Boutique';             -- and this, if you like
  v_uid   uuid;
begin
  select id into v_uid from auth.users where lower(email) = lower(v_email);

  -- Loud rather than silent. An UPDATE that matches nothing reports success,
  -- and you would go looking for the bug in the app instead of in the email.
  if v_uid is null then
    raise exception
      'No account with email %. Register in the app first, or add the user under Authentication -> Users.',
      v_email;
  end if;

  -- The profile may genuinely be missing: handle_new_user() fires on insert
  -- into auth.users, so an account created while testing sign-in — before the
  -- schema existed — never got one. The first version of this file assumed
  -- otherwise, the UPDATE below matched nothing, and the creators insert then
  -- failed on creators_profile_id_fkey. Create it if it is not there.
  insert into profiles (id, full_name)
  values (v_uid, (select nullif(raw_user_meta_data->>'full_name', '')
                    from auth.users where id = v_uid))
  on conflict (id) do nothing;

  -- Approval. The app cannot write this column - the profiles update policy
  -- forbids it - which is the point: wanting to sell and being allowed to
  -- sell stay separate things.
  update profiles set creator_status = 'approved' where id = v_uid;

  -- The shop. profile_id is what makes my_creator_id() return this row, and
  -- therefore what lets this account write products at all.
  insert into creators (profile_id, name, slug, location, bio, is_approved)
  values (
    v_uid,
    v_shop,
    'shop-' || left(replace(v_uid::text, '-', ''), 8),
    'Douala, Cameroun',
    'Pièces faites main.',
    true
  )
  on conflict (profile_id) do update
    set is_approved = true,
        name        = excluded.name;

  raise notice 'Seller ready: % (%)', v_email, v_uid;
end $$;

-- ---------------------------------------------------------------------------
-- Same gap, everybody else: accounts that predate the schema have no profile.
-- Harmless to run, and it is why the app shows nothing for such an account.
-- ---------------------------------------------------------------------------
insert into profiles (id, full_name)
select u.id, nullif(u.raw_user_meta_data->>'full_name', '')
  from auth.users u
 where not exists (select 1 from profiles p where p.id = u.id);

-- Confirm (edit the email here too):
-- select p.creator_status, c.name, c.slug, c.is_approved
--   from profiles p join creators c on c.profile_id = p.id
--  where p.id = (select id from auth.users where lower(email) = lower('CHANGE-ME@example.com'));
