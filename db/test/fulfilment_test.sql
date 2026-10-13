-- Tests for db/0005_fulfilment.sql. Fresh database, shim + 0001 + 0005.
--
-- The case that matters is the two-shop order: these policies are the only
-- thing stopping one seller from marking another seller's goods as sent.
\set ON_ERROR_STOP on
\pset format unaligned
\pset tuples_only on

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'amina@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'kofi@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'bola@test.local')
on conflict do nothing;

-- Two shops, one buyer.
insert into creators (id, profile_id, name, slug, is_approved) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Atelier Amina', 'amina', true),
  ('aaaaaaaa-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', 'Bola Bijoux',   'bola',  true)
on conflict do nothing;

insert into products (id, creator_id, name, price_xaf, image_url) values
  ('bbbbbbbb-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Boubou', 8000,  'x'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000002', 'Boucles', 4000, 'x')
on conflict do nothing;

insert into addresses (id, user_id, full_name, phone, line1, city) values
  ('dddddddd-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222',
   'Kofi M.', '+237600000000', 'Rue 1', 'Douala')
on conflict do nothing;

create or replace function t_ok(label text, cond boolean) returns void
language plpgsql as $$
begin
  raise notice '%  %', case when cond then 'PASS' else '!! FAIL' end, label;
end $$;

-- ── Kofi buys from both shops in one order ─────────────────────────────────
set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
insert into cart_items (user_id, product_id, qty) values
  ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-0000-0000-0000-000000000001', 1),
  ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-0000-0000-0000-000000000002', 1);

create temp table ord as
  select place_order('dddddddd-0000-0000-0000-000000000001'::uuid, 0) as id;
select settle_stub_payment((select id from ord), 'STUB-1');
select t_ok('order is paid and has two shops'' goods',
  (select status from orders where id = (select id from ord)) = 'paid'
  and (select count(distinct creator_id) from order_items where order_id = (select id from ord)) = 2);

-- ── A seller ships only their own line ─────────────────────────────────────
reset role; set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select t_ok('amina ships exactly one line (hers)',
  seller_mark_shipped((select id from ord), 'TRK-AMINA') = 1);
select t_ok('her line is shipped and carries the tracking',
  (select fulfilment = 'shipped' and tracking_ref = 'TRK-AMINA' and shipped_at is not null
     from order_items where order_id = (select id from ord)
      and creator_id = 'aaaaaaaa-0000-0000-0000-000000000001'));
-- Amina cannot even SEE Bola's line: the order_items policy is
-- `owns_order(order_id) or creator_id = my_creator_id()`. Asserting the line's
-- value from here returned NULL on the first run and t_ok reported FAIL, which
-- is the right answer to the wrong question - so ask both questions.
select t_ok('amina cannot SEE bola''s line at all',
  (select count(*) from order_items where order_id = (select id from ord)
     and creator_id = 'aaaaaaaa-0000-0000-0000-000000000002') = 0);
select t_ok('the order reads shipped, not delivered',
  (select status from orders where id = (select id from ord)) = 'shipped');
select t_ok('shipping again moves nothing',
  seller_mark_shipped((select id from ord), 'TRK-AGAIN') = 0);

-- And from where it IS visible, Bola's line really is untouched.
reset role;
select t_ok('BOLA''S LINE IS UNTOUCHED',
  (select fulfilment = 'pending' and shipped_at is null and tracking_ref is null
     from order_items where order_id = (select id from ord)
      and creator_id = 'aaaaaaaa-0000-0000-0000-000000000002'));

-- ── A stranger with no shop cannot ship at all ─────────────────────────────
reset role; set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
do $$ begin
  perform seller_mark_shipped((select id from ord), 'HIJACK');
  raise notice '!! FAIL  a buyer could ship goods';
exception when others then
  raise notice 'PASS  a buyer CANNOT ship goods (%)', sqlerrm;
end $$;

-- ── The buyer confirms, and only for what was actually sent ────────────────
select t_ok('kofi confirms the one line that was sent',
  buyer_confirm_delivery((select id from ord)) = 1);
select t_ok('the order is still only shipped - bola has not sent hers',
  (select status from orders where id = (select id from ord)) = 'shipped');

-- ── Bola ships and closes hers; now the order is delivered ─────────────────
reset role; set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select t_ok('bola ships her line', seller_mark_shipped((select id from ord), null) = 1);
select t_ok('bola closes her line',  seller_mark_delivered((select id from ord)) = 1);
select t_ok('EVERY line delivered -> the order is delivered',
  (select status from orders where id = (select id from ord)) = 'delivered');

-- ── A delivered order cannot be cancelled, or shipped again ────────────────
reset role; set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select cancel_my_order((select id from ord));
select t_ok('a delivered order CANNOT be cancelled by the buyer',
  (select status from orders where id = (select id from ord)) = 'delivered');

-- ── An unpaid order cannot be shipped ──────────────────────────────────────
insert into cart_items (user_id, product_id, qty)
  values ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-0000-0000-0000-000000000001', 1);
create temp table ord2 as
  select place_order('dddddddd-0000-0000-0000-000000000001'::uuid, 0) as id;
reset role; set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
do $$ begin
  perform seller_mark_shipped((select id from ord2), null);
  raise notice '!! FAIL  an unpaid order could be shipped';
exception when others then
  raise notice 'PASS  an UNPAID order cannot be shipped (%)', sqlerrm;
end $$;

-- ── A cancelled order is not dragged back by the trigger ───────────────────
reset role; set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select cancel_my_order((select id from ord2));
reset role;
update order_items set fulfilment = 'shipped' where order_id = (select id from ord2);
select t_ok('a CANCELLED order stays cancelled even if a line moves',
  (select status from orders where id = (select id from ord2)) = 'cancelled');

reset role;
