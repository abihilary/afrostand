-- ===========================================================================
-- AFROSTAND - fulfilment: getting the parcel to the door.
-- ===========================================================================
-- Paste into the Supabase SQL editor and Run. Safe to re-run.
--
-- `order_status` had 'shipped' and 'delivered' from the start and nothing in
-- the database could write them: orders has a select policy only, and the
-- SECURITY DEFINER functions covered placing, settling and cancelling. A
-- seller could see a sale and had no way to act on it. This is that half.
--
-- WHY THE STATE LIVES ON order_items AND NOT ON orders
--
-- place_order() prices the whole cart, and a cart may hold goods from several
-- shops. So "this order has shipped" is not a fact anybody owns: shop A can
-- have posted its parcel while shop B has not touched theirs. Putting a single
-- status on the order would mean either lying about half of it, or letting one
-- seller mark another seller's goods as sent.
--
-- Each line therefore carries its own state, each seller moves only their own
-- lines, and orders.status is DERIVED from the lines by a trigger - so the
-- buyer's existing screen keeps reading o.status and keeps being right.
-- ===========================================================================

do $$ begin
  if not exists (select 1 from pg_type where typname = 'fulfilment_status') then
    create type fulfilment_status as enum ('pending', 'shipped', 'delivered');
  end if;
end $$;

alter table order_items
  add column if not exists fulfilment  fulfilment_status not null default 'pending',
  add column if not exists tracking_ref text,
  add column if not exists shipped_at   timestamptz,
  add column if not exists delivered_at timestamptz;

-- The seller's queue: their own unshipped lines, newest order first.
create index if not exists order_items_creator_fulfilment_idx
  on order_items (creator_id, fulfilment);

-- ── orders.status, derived ─────────────────────────────────────────────────
--
-- Never touches an order that has left the fulfilment track. A cancelled or
-- refunded order must not be dragged back to 'shipped' by a trigger firing on
-- a line somebody updated a moment earlier, and an unpaid order must not look
-- dispatched because a seller jumped the gun.
create or replace function sync_order_status(p_order uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_current order_status;
  v_total   integer;
  v_shipped integer;
  v_done    integer;
begin
  select status into v_current from orders where id = p_order;
  if v_current not in ('paid', 'shipped', 'delivered') then
    return;
  end if;

  select count(*),
         count(*) filter (where fulfilment in ('shipped', 'delivered')),
         count(*) filter (where fulfilment = 'delivered')
    into v_total, v_shipped, v_done
    from order_items where order_id = p_order;

  update orders set status = case
      when v_total = 0      then v_current
      when v_done = v_total then 'delivered'::order_status
      when v_shipped > 0    then 'shipped'::order_status
      else 'paid'::order_status
    end
   where id = p_order;
end $$;

create or replace function on_order_item_fulfilment()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform sync_order_status(new.order_id);
  return new;
end $$;

drop trigger if exists order_items_fulfilment_sync on order_items;
create trigger order_items_fulfilment_sync
  after update of fulfilment on order_items
  for each row
  when (old.fulfilment is distinct from new.fulfilment)
  execute function on_order_item_fulfilment();

-- ── The seller posts their part of an order ────────────────────────────────
--
-- Returns the number of lines that moved rather than void. An UPDATE that
-- matches nothing succeeds, and a screen that cannot tell "sent" from "there
-- was nothing of yours here" will cheerfully report the wrong one.
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
  if v_creator is null then
    raise exception 'not an approved seller';
  end if;

  select status into v_status from orders where id = p_order_id;
  if v_status is null then
    raise exception 'no such order';
  end if;
  -- Unpaid goods do not leave the workshop, and a cancelled order is not a
  -- dispatch instruction.
  if v_status not in ('paid', 'shipped') then
    raise exception 'order is %, not ready to ship', v_status;
  end if;

  update order_items
     set fulfilment   = 'shipped',
         tracking_ref = nullif(trim(coalesce(p_tracking, '')), ''),
         shipped_at   = now()
   where order_id = p_order_id
     and creator_id = v_creator          -- only ever their own lines
     and fulfilment = 'pending';

  get diagnostics v_moved = row_count;
  return v_moved;
end $$;

-- ── Arrival ────────────────────────────────────────────────────────────────
--
-- Two ways in, because both failure modes are real: a buyer who never comes
-- back to confirm would leave the seller's sale open forever, and a seller
-- declaring delivery on goods nobody received is exactly the dispute this
-- should be able to survive. So the buyer confirms their whole order, the
-- seller can close their own lines, and both are recorded the same way.
create or replace function buyer_confirm_delivery(p_order_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_moved integer;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;

  if not exists (select 1 from orders o
                  where o.id = p_order_id and o.user_id = auth.uid()) then
    raise exception 'no such order';
  end if;

  -- Only what has actually been sent. Confirming receipt of something nobody
  -- posted is not a thing the buyer should be able to say.
  update order_items
     set fulfilment = 'delivered', delivered_at = now()
   where order_id = p_order_id and fulfilment = 'shipped';

  get diagnostics v_moved = row_count;
  perform sync_order_status(p_order_id);
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
  v_moved   integer;
begin
  if v_creator is null then
    raise exception 'not an approved seller';
  end if;

  update order_items
     set fulfilment = 'delivered', delivered_at = now()
   where order_id = p_order_id
     and creator_id = v_creator
     and fulfilment = 'shipped';

  get diagnostics v_moved = row_count;
  perform sync_order_status(p_order_id);
  return v_moved;
end $$;

revoke all on function seller_mark_shipped(uuid, text)   from public;
revoke all on function seller_mark_delivered(uuid)       from public;
revoke all on function buyer_confirm_delivery(uuid)      from public;
revoke all on function sync_order_status(uuid)           from public;
grant execute on function seller_mark_shipped(uuid, text)  to authenticated;
grant execute on function seller_mark_delivered(uuid)      to authenticated;
grant execute on function buyer_confirm_delivery(uuid)     to authenticated;
-- sync_order_status stays ungranted: it is the trigger's, not the client's.

-- Existing orders predate the column and default to 'pending', which is the
-- truth for anything not yet sent. Orders already marked delivered by hand (
-- there are none today) would need their lines moved to match.

-- Check:
--   select o.code, o.status, oi.name, oi.fulfilment, oi.tracking_ref
--     from orders o join order_items oi on oi.order_id = o.id
--    order by o.created_at desc;
