-- ===========================================================================
-- AFROSTAND - security fixes found by auditing the schema against the fact
-- that the repository is public and the anon key is committed.
-- ===========================================================================
-- Paste into the Supabase SQL editor and Run. Safe to re-run.
--
-- Each fix below was reproduced on a local Postgres against this exact schema
-- before being written, and db/test/security_test.sql asserts every one of
-- them. They are ordered by how much damage the hole allowed.
-- ===========================================================================


-- ───────────────────────────────────────────────────────────────────────────
-- 1) CRITICAL - cancel_my_order() cancelled ANYONE's payment
-- ───────────────────────────────────────────────────────────────────────────
-- The ownership test was on the first statement and not the second:
--
--   update orders   set status='cancelled' where id = p_order_id
--                     and user_id = auth.uid() and status in ('pending','paid');
--   update payments set status='cancelled' where order_id = p_order_id
--                     and status = 'pending';          -- <- no owner check
--
-- SECURITY DEFINER means RLS does not catch it. Any signed-in account could
-- cancel a stranger's pending payment, and the orders update silently matched
-- nothing so there was no error and no trace.
--
-- The follow-on was worse than the denial of service. settle_stub_payment()
-- guards its payments update on status='pending' but updates the order
-- unconditionally, so after this the victim's own checkout produced an order
-- marked PAID with a CANCELLED payment row and no provider reference: a
-- corrupted money record, and goods dispatched against a charge that never
-- settled.
create or replace function cancel_my_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;

  -- Decided once, at the top, the way settle_stub_payment already did it.
  if not exists (select 1 from orders o
                  where o.id = p_order_id and o.user_id = auth.uid()) then
    raise exception 'no such order';
  end if;

  update orders
     set status = 'cancelled'
   where id = p_order_id and user_id = auth.uid() and status in ('pending', 'paid');

  update payments
     set status = 'cancelled', updated_at = now()
   where order_id = p_order_id
     and status = 'pending'
     and exists (select 1 from orders o
                  where o.id = payments.order_id and o.user_id = auth.uid());
end $$;

-- While here: settle_stub_payment() marked the order paid whatever happened to
-- the payment row. It now only does so if a payment actually moved to
-- succeeded, so the two records cannot disagree.
create or replace function settle_stub_payment(p_order_id uuid, p_reference text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user  uuid := auth.uid();
  v_moved integer;
begin
  if v_user is null then raise exception 'not signed in'; end if;

  if not exists (select 1 from orders o where o.id = p_order_id and o.user_id = v_user) then
    raise exception 'no such order';
  end if;

  update payments
     set status = 'succeeded', provider_ref = p_reference, updated_at = now()
   where order_id = p_order_id and status = 'pending';
  get diagnostics v_moved = row_count;

  if v_moved = 0 then
    raise exception 'no pending payment for this order';
  end if;

  update orders set status = 'paid' where id = p_order_id and status = 'pending';
end $$;


-- ───────────────────────────────────────────────────────────────────────────
-- 2) HIGH - a chat recipient could rewrite the other person's messages
-- ───────────────────────────────────────────────────────────────────────────
-- The policy's comment said "marking as read is the only update allowed". RLS
-- cannot express that: a row policy decides WHICH ROWS, never which columns,
-- and `sender_id <> auth.uid()` selected precisely the other party's messages.
-- One PATCH rewrote what somebody else had said, with no edit marker — in the
-- only evidence channel a buyer and a seller have, while payments are stubbed.
-- The with check also allowed moving a received message into any other thread
-- the attacker belonged to.
--
-- Column privileges are the right tool. The policy still decides the rows; the
-- grant decides that read_at is the only column that can be written.
drop policy if exists messages_mark_read on messages;
create policy messages_mark_read on messages for update
  using (in_thread(thread_id) and sender_id <> auth.uid())
  with check (in_thread(thread_id) and sender_id <> auth.uid()
              and thread_id = (select m.thread_id from messages m where m.id = messages.id));

revoke update on messages from authenticated, anon;
grant  update (read_at) on messages to authenticated;


-- ───────────────────────────────────────────────────────────────────────────
-- 3) HIGH - a suspended seller could re-approve themselves
-- ───────────────────────────────────────────────────────────────────────────
-- creators_update_own pinned profile_id and nothing else, and is_approved is
-- the single thing my_creator_id() checks — the gate on writing products,
-- posting to the public feed, reading every buyer's name and address on an
-- order containing their goods, and moving fulfilment. Setting is_approved
-- false (the only lever db/make_seller.sql has for suspending a bad shop) was
-- undone by one PATCH.
--
-- The same pin profiles_update_own already applies to creator_status.
drop policy if exists creators_update_own on creators;
create policy creators_update_own on creators for update
  using (profile_id = auth.uid())
  with check (
    profile_id = auth.uid()
    and is_approved = (select c.is_approved from creators c where c.profile_id = auth.uid())
    and slug        = (select c.slug        from creators c where c.profile_id = auth.uid())
  );


-- ───────────────────────────────────────────────────────────────────────────
-- 4) Every account's phone number was readable with the public anon key
-- ───────────────────────────────────────────────────────────────────────────
-- `profiles_read using (true)` is right for what it was written for — a chat
-- and a comment need a name and an avatar for somebody who is not you — but it
-- is a whole-row grant, and the row carries phone. Nobody has set one yet,
-- because no screen calls updateMe(); the moment one does, one unauthenticated
-- request with the committed key dumps the name and mobile number of every
-- account. A phone number is the mobile-money identifier here.
--
-- Column privileges again: the policy keeps saying "any row", the grant says
-- which columns. Your own row stays fully readable through the second policy.
revoke select on profiles from anon, authenticated;
grant  select (id, full_name, avatar_url, creator_status, created_at)
  on profiles to anon, authenticated;

-- A column grant is per ROLE, not per row, so it cannot say "everyone sees a
-- name, you also see your own phone". That needs a function, and the app's own
-- profile read goes through it.
--
-- Getting this wrong was caught by testing rather than by thinking: the first
-- version of this file stopped at the revoke above, and the app reads its own
-- profile with PostgREST's `.select()`, which is `select *`. Every column in
-- that star has to be granted, so signing in would have failed with permission
-- denied for the whole user base.
create or replace function my_profile()
returns profiles
language sql
stable
security definer
set search_path = public, pg_temp
as $$ select p.* from profiles p where p.id = auth.uid() $$;

revoke all on function my_profile() from public, anon;
grant execute on function my_profile() to authenticated;


-- ───────────────────────────────────────────────────────────────────────────
-- 5) threads.last_message_at never advanced, so the inbox never reordered
-- ───────────────────────────────────────────────────────────────────────────
-- touch_thread() was not SECURITY DEFINER, so it ran as the sender with RLS
-- applied — and threads has a select and an insert policy and no update policy
-- at all. The update matched zero rows and Postgres raised nothing. The column
-- kept its insert-time default forever, so the thread list, which orders by
-- it, was really ordering by when each conversation was created.
--
-- 0006_realtime.sql adds threads to the publication specifically so a
-- conversation jumps to the top while the list is open. That could never have
-- fired.
create or replace function touch_thread()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update threads set last_message_at = new.created_at where id = new.thread_id;
  return new;
end $$;


-- ───────────────────────────────────────────────────────────────────────────
-- 6) place_order() ignored discount_pct - the buyer paid more than the price
-- ───────────────────────────────────────────────────────────────────────────
-- The app has applied the discount everywhere a price is shown since the
-- models were written (Product.effectivePriceXaf, "what the buyer actually
-- pays"), the cart totals it, and the server charged the list price. On an
-- 8 000 item at 30% off the card said 5 600 and the order was written at
-- 8 000. It also moved the free-delivery threshold, so the displayed total and
-- orders.total_xaf disagreed on two lines at once.
--
-- The rule now lives here, once, where the money is decided.
create or replace function effective_price_xaf(p_price integer, p_discount integer)
returns integer
language sql
immutable
as $$
  select greatest(0, round(p_price * (100 - least(greatest(coalesce(p_discount, 0), 0), 100)) / 100.0)::integer)
$$;
grant execute on function effective_price_xaf(integer, integer) to anon, authenticated;

create or replace function place_order(p_address_id uuid, p_delivery_xaf integer default 0)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user     uuid := auth.uid();
  v_order    uuid;
  v_subtotal integer;
  v_delivery integer;
  v_ship     jsonb;
begin
  if v_user is null then
    raise exception 'not signed in';
  end if;

  select to_jsonb(a) - 'user_id' into v_ship
    from addresses a
   where a.id = p_address_id and a.user_id = v_user;
  if v_ship is null then
    raise exception 'no such address';
  end if;

  select coalesce(sum(effective_price_xaf(p.price_xaf, p.discount_pct)::bigint * ci.qty), 0)
    into v_subtotal
    from cart_items ci
    join products p on p.id = ci.product_id
   where ci.user_id = v_user and p.is_active;

  if v_subtotal = 0 then
    raise exception 'cart is empty';
  end if;

  v_delivery := delivery_quote(v_subtotal);

  insert into orders (user_id, subtotal_xaf, delivery_xaf, total_xaf, ship_to)
  values (v_user, v_subtotal, v_delivery, v_subtotal + v_delivery, v_ship)
  returning id into v_order;

  insert into order_items (order_id, product_id, creator_id, name, image_url, unit_price_xaf, qty, size, color)
  select v_order, p.id, p.creator_id, p.name, p.image_url,
         effective_price_xaf(p.price_xaf, p.discount_pct), ci.qty, ci.size, ci.color
    from cart_items ci
    join products p on p.id = ci.product_id
   where ci.user_id = v_user and p.is_active;

  insert into payments (order_id, amount_xaf) values (v_order, v_subtotal + v_delivery);

  delete from cart_items where user_id = v_user;

  return v_order;
end $$;

-- A client-chosen qty went straight into price * qty as integer * integer, so
-- a large enough number killed checkout with `integer out of range` from
-- inside the function. Bounded, and the sum above is bigint now anyway.
alter table cart_items drop constraint if exists cart_items_qty_sane;
alter table cart_items add constraint cart_items_qty_sane check (qty between 1 and 999);


-- ───────────────────────────────────────────────────────────────────────────
-- 7) The delivery functions had no order-status guard
-- ───────────────────────────────────────────────────────────────────────────
-- seller_mark_shipped refuses anything that is not paid or shipped; the other
-- two never looked. There is no route to it today — cancelling is refused once
-- anything has shipped — so the invariant held by luck rather than by design,
-- and a refund path would have been the route. Guarded properly, and the
-- tracking reference is bounded.
create or replace function seller_mark_shipped(p_order_id uuid, p_tracking text default null)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_creator uuid := my_creator_id();
  v_status  order_status;
  v_moved   integer;
begin
  if v_creator is null then raise exception 'not an approved seller'; end if;

  select status into v_status from orders where id = p_order_id;
  if v_status is null then raise exception 'no such order'; end if;
  if v_status not in ('paid', 'shipped') then
    raise exception 'order is %, not ready to ship', v_status;
  end if;

  update order_items
     set fulfilment   = 'shipped',
         tracking_ref = left(nullif(trim(coalesce(p_tracking, '')), ''), 64),
         shipped_at   = now()
   where order_id = p_order_id and creator_id = v_creator and fulfilment = 'pending';

  get diagnostics v_moved = row_count;
  return v_moved;
end $$;

create or replace function seller_mark_delivered(p_order_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_creator uuid := my_creator_id();
  v_status  order_status;
  v_moved   integer;
begin
  if v_creator is null then raise exception 'not an approved seller'; end if;

  select status into v_status from orders where id = p_order_id;
  if v_status is null then raise exception 'no such order'; end if;
  if v_status not in ('paid', 'shipped', 'delivered') then
    raise exception 'order is %, nothing to deliver', v_status;
  end if;

  update order_items
     set fulfilment = 'delivered', delivered_at = now()
   where order_id = p_order_id and creator_id = v_creator and fulfilment = 'shipped';

  get diagnostics v_moved = row_count;
  perform sync_order_status(p_order_id);
  return v_moved;
end $$;

create or replace function buyer_confirm_delivery(p_order_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status order_status;
  v_moved  integer;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;

  select status into v_status from orders
   where id = p_order_id and user_id = auth.uid();
  if v_status is null then raise exception 'no such order'; end if;
  if v_status not in ('paid', 'shipped', 'delivered') then
    raise exception 'order is %, nothing to confirm', v_status;
  end if;

  update order_items
     set fulfilment = 'delivered', delivered_at = now()
   where order_id = p_order_id and fulfilment = 'shipped';

  get diagnostics v_moved = row_count;
  perform sync_order_status(p_order_id);
  return v_moved;
end $$;


-- ───────────────────────────────────────────────────────────────────────────
-- 8) A seller could post a feed item pointing at a rival's product
-- ───────────────────────────────────────────────────────────────────────────
-- posts_write_own checked who the post belonged to and never what it linked
-- to, and posts are world-readable.
drop policy if exists posts_write_own on posts;
create policy posts_write_own on posts for all
  using (creator_id = my_creator_id())
  with check (
    creator_id = my_creator_id()
    and (product_id is null
         or exists (select 1 from products p
                     where p.id = product_id and p.creator_id = my_creator_id()))
  );


-- ───────────────────────────────────────────────────────────────────────────
-- 9) A seller could not see their own delisted products
-- ───────────────────────────────────────────────────────────────────────────
-- `using (is_active)` hid the row from the person who owns it, so delisting
-- was a one-way door: nothing could list it again because nothing could read
-- it. Buyers still see only active ones.
drop policy if exists products_read on products;
create policy products_read on products for select
  using (is_active or creator_id = my_creator_id());


-- ───────────────────────────────────────────────────────────────────────────
-- 10) The grants were not doing what the file said they were
-- ───────────────────────────────────────────────────────────────────────────
-- Every RPC in 0001 and 0005 ends with `revoke all ... from public` and
-- `grant execute ... to authenticated`. Supabase's default privileges grant
-- EXECUTE on new functions to anon EXPLICITLY, and revoking from PUBLIC does
-- not remove an explicit grant. So all of them were in fact callable with the
-- anon key — each one refused on its own `auth.uid() is null` check, which is
-- why nothing leaked, but the outer boundary the comments describe was not
-- there. Proven against the live project: an anonymous call to place_order
-- reached the function body and answered 'not signed in'.
-- The RPC entry points: anon has no business calling any of them.
do $$
declare f text;
begin
  foreach f in array array[
    'place_order(uuid, integer)', 'open_thread(uuid)', 'request_creator_status()',
    'settle_stub_payment(uuid, text)', 'cancel_my_order(uuid)',
    'seller_mark_shipped(uuid, text)', 'seller_mark_delivered(uuid)',
    'buyer_confirm_delivery(uuid)', 'sync_order_status(uuid)'
  ] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
  end loop;

  foreach f in array array[
    'place_order(uuid, integer)', 'open_thread(uuid)', 'request_creator_status()',
    'settle_stub_payment(uuid, text)', 'cancel_my_order(uuid)',
    'seller_mark_shipped(uuid, text)', 'seller_mark_delivered(uuid)',
    'buyer_confirm_delivery(uuid)'
  ] loop
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;
-- sync_order_status is left granted to nobody: it belongs to the trigger.

-- The four policy helpers are deliberately NOT in that list, and the first
-- draft of this file had them there. It broke the entire public catalogue:
-- products_read calls my_creator_id() so a seller can see their own delisted
-- rows, and a policy is evaluated as the caller — so revoking it from anon
-- turned every anonymous `select from products` into "permission denied for
-- function my_creator_id". A shop nobody can browse.
--
-- They are safe to expose. Each derives its answer from auth.uid() and
-- returns one boolean or one uuid about the caller alone; for anon, auth.uid()
-- is null and every one of them returns null or false.
grant execute on function my_creator_id()           to anon, authenticated;
grant execute on function owns_order(uuid)          to anon, authenticated;
grant execute on function sells_in_order(uuid)      to anon, authenticated;
grant execute on function in_thread(uuid)           to anon, authenticated;
grant execute on function effective_price_xaf(integer, integer) to anon, authenticated;
