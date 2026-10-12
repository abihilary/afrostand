-- Tests for the policies in 0001_schema.sql, run against a local Postgres with
-- db/test/_supabase_shim.sql applied. Each block sets the role and the JWT
-- subject the way PostgREST would, then asserts what that caller can see or do.
--
-- Worth having as a file rather than ad-hoc psql: the public repo plus a public
-- anon key means "can anon write to products" has exactly one correct answer,
-- and it should be possible to re-check it after any schema change.

\set ON_ERROR_STOP on
\pset format unaligned
\pset tuples_only on

-- ── fixtures ───────────────────────────────────────────────────────────────
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'amina@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'kofi@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'snoop@test.local')
on conflict do nothing;

insert into creators (id, profile_id, name, slug, location, is_approved) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   'Atelier Amina', 'atelier-amina', 'Douala, Cameroun', true)
on conflict do nothing;

insert into categories (id, name, slug) values
  ('cccccccc-0000-0000-0000-000000000001', 'Wax', 'wax') on conflict do nothing;

insert into products (id, creator_id, category_id, name, price_xaf, image_url) values
  ('bbbbbbbb-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001',
   'cccccccc-0000-0000-0000-000000000001', 'Boubou Wax Royal', 8000, 'https://x/1.jpg')
on conflict do nothing;

insert into addresses (id, user_id, full_name, phone, line1, city) values
  ('dddddddd-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222',
   'Kofi M.', '+237600000000', 'Rue 1', 'Douala')
on conflict do nothing;

-- ── helpers ────────────────────────────────────────────────────────────────
create or replace function t_ok(label text, cond boolean) returns void
language plpgsql as $$
begin
  raise notice '%  %', case when cond then 'PASS' else '!! FAIL' end, label;
end $$;

-- Did a statement raise? For INSERTs, where a policy violation is an error.
create or replace function t_denied(label text, stmt text) returns void
language plpgsql as $$
begin
  execute stmt;
  raise notice '!! FAIL  % (it was ALLOWED)', label;
exception when others then
  raise notice 'PASS  % (denied: %)', label, left(sqlerrm, 48);
end $$;

-- For UPDATE and DELETE, RLS does not raise - it filters the rows away and
-- reports "UPDATE 0". That is the correct, safe behaviour, so the test has to
-- assert that nothing changed rather than that something threw.
create or replace function t_no_rows(label text, stmt text) returns void
language plpgsql as $$
declare n integer;
begin
  execute stmt;
  get diagnostics n = row_count;
  raise notice '%  % (% rows affected)',
    case when n = 0 then 'PASS' else '!! FAIL' end, label, n;
end $$;

-- ═══ ANON — the key that is committed to a public repo ═════════════════════
set role anon;
select set_config('request.jwt.claim.sub', '', false);

select t_ok('anon reads the catalogue', (select count(*) from products) = 1);
select t_ok('anon reads creators',      (select count(*) from creators) = 1);
select t_ok('anon reads categories',    (select count(*) from categories) = 1);
select t_denied('anon CANNOT insert a product',
  $$insert into products (creator_id, name, price_xaf, image_url)
    values ('aaaaaaaa-0000-0000-0000-000000000001','Fake',1,'x')$$);
select t_no_rows('anon CANNOT update a price',
  $$update products set price_xaf = 1 where name = 'Boubou Wax Royal'$$);
select t_no_rows('anon CANNOT delete a product',
  $$delete from products where name = 'Boubou Wax Royal'$$);
select t_ok('anon sees no carts',     (select count(*) from cart_items) = 0);
select t_ok('anon sees no addresses', (select count(*) from addresses) = 0);
select t_ok('anon sees no orders',    (select count(*) from orders) = 0);
select t_ok('anon sees no messages',  (select count(*) from messages) = 0);
reset role;

-- ═══ KOFI — an ordinary signed-in buyer ════════════════════════════════════
set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);

insert into cart_items (user_id, product_id, qty) values
  ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-0000-0000-0000-000000000001', 2);
select t_ok('kofi sees his own cart', (select count(*) from cart_items) = 1);

select t_denied('kofi CANNOT put things in someone else''s cart',
  $$insert into cart_items (user_id, product_id) values
    ('11111111-1111-1111-1111-111111111111','bbbbbbbb-0000-0000-0000-000000000001')$$);

select t_denied('kofi CANNOT list a product (not a creator)',
  $$insert into products (creator_id, name, price_xaf, image_url)
    values ('aaaaaaaa-0000-0000-0000-000000000001','Counterfeit',1,'x')$$);

-- The one that matters most: the price is read from products inside the
-- function, so a caller passing a bargain delivery cost still pays 2 x 8000.
--
-- Placed in its own statement. place_order is volatile and inserts rows; called
-- inside `select ... from orders` it would run against that statement's
-- snapshot, which predates its own writes, and the test would read nothing and
-- report a failure that is not there.
create temp table _o as select place_order('dddddddd-0000-0000-0000-000000000001', 500) as id;
select t_ok('place_order prices from the catalogue, not the caller',
  (select o.total_xaf from orders o join _o on o.id = _o.id) = 16500);
select t_ok('cart is cleared by placing the order', (select count(*) from cart_items) = 0);
select t_ok('order items snapshot the name', (select name from order_items limit 1) = 'Boubou Wax Royal');
select t_ok('a pending payment was written',
  (select status from payments limit 1) = 'pending');

select t_denied('kofi CANNOT order to an address that is not his',
  $$select place_order('dddddddd-0000-0000-0000-000000000009', 0)$$);

select t_denied('kofi CANNOT grant himself creator status',
  $$update profiles set creator_status = 'approved' where id = auth.uid()$$);
reset role;

-- ═══ AMINA — an approved creator ═══════════════════════════════════════════
set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);

insert into products (creator_id, name, price_xaf, image_url)
  values ('aaaaaaaa-0000-0000-0000-000000000001', 'Sac Raphia', 9800, 'https://x/2.jpg');
select t_ok('amina lists her own product', (select count(*) from products) = 2);
select t_ok('amina sees the order containing her goods', (select count(*) from orders) = 1);
reset role;

-- ═══ CHAT — the strictest boundary in the schema ═══════════════════════════
set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
create temp table _t as select open_thread('22222222-2222-2222-2222-222222222222') as id;
insert into messages (thread_id, sender_id, body)
  select id, '11111111-1111-1111-1111-111111111111', 'Bonjour Kofi' from _t;
select t_ok('amina reads her own thread', (select count(*) from messages) = 1);

select t_denied('amina CANNOT send as somebody else',
  $$insert into messages (thread_id, sender_id, body)
    select id, '33333333-3333-3333-3333-333333333333', 'spoofed' from _t$$);
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
select t_ok('kofi reads the thread he is in', (select count(*) from messages) = 1);
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', false);
select t_ok('!! a third party reads NOTHING', (select count(*) from messages) = 0);
select t_ok('!! a third party sees no thread', (select count(*) from threads) = 0);
select t_denied('a third party CANNOT post into their thread',
  $$insert into messages (thread_id, sender_id, body)
    select id, '33333333-3333-3333-3333-333333333333', 'intruding' from _t$$);
reset role;
