-- Each assertion here is an attack that WORKED against the schema before
-- db/0007_security.sql. Fresh database: shim + 0001 + 0005 + 0007.
\set ON_ERROR_STOP off
\pset format unaligned
\pset tuples_only on

insert into auth.users (id,email) values
 ('11111111-1111-1111-1111-111111111111','seller@t'),
 ('22222222-2222-2222-2222-222222222222','victim@t'),
 ('33333333-3333-3333-3333-333333333333','attacker@t') on conflict do nothing;
insert into creators (id,profile_id,name,slug,is_approved) values
 ('aaaaaaaa-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','Shop','shop',true)
 on conflict do nothing;
insert into creators (id,profile_id,name,slug,is_approved) values
 ('aaaaaaaa-0000-0000-0000-000000000002','33333333-3333-3333-3333-333333333333','Rival','rival',true)
 on conflict do nothing;
insert into products (id,creator_id,name,price_xaf,discount_pct,image_url) values
 ('bbbbbbbb-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','Thing',8000,30,'x')
 on conflict do nothing;
insert into addresses (id,user_id,full_name,phone,line1,city) values
 ('dddddddd-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','V','+237600','R','D')
 on conflict do nothing;
update profiles set phone = '+237699999999' where id = '22222222-2222-2222-2222-222222222222';

create or replace function t_ok(label text, cond boolean) returns void
language plpgsql as $$
begin raise notice '%  %', case when cond then 'PASS' else '!! FAIL' end, label; end $$;

-- ── 1. a stranger cannot cancel somebody else's payment ────────────────────
set role authenticated; select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
insert into cart_items (user_id,product_id,qty) values ('22222222-2222-2222-2222-222222222222','bbbbbbbb-0000-0000-0000-000000000001',1);
create temp table o as select place_order('dddddddd-0000-0000-0000-000000000001'::uuid,0) as id;

reset role; set role authenticated; select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333',false);
do $$ begin
  perform cancel_my_order((select id from o));
  raise notice '!! FAIL  a stranger could cancel another buyer''s order';
exception when others then
  raise notice 'PASS  a stranger CANNOT cancel another buyer''s order (%)', sqlerrm;
end $$;
reset role;
select t_ok('and the victim''s payment is still pending',
  (select status from payments where order_id=(select id from o)) = 'pending');

-- ── 2. an order cannot become paid without a payment succeeding ────────────
set role authenticated; select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
select settle_stub_payment((select id from o),'REF-1');
reset role;
select t_ok('settling moves BOTH the payment and the order',
  (select status from orders where id=(select id from o))='paid'
  and (select status from payments where order_id=(select id from o))='succeeded');
set role authenticated; select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
do $$ begin
  perform settle_stub_payment((select id from o),'REF-REPLAY');
  raise notice '!! FAIL  a settled order could be settled again';
exception when others then
  raise notice 'PASS  a settled order CANNOT be settled again (%)', sqlerrm;
end $$;

-- ── 3. the discount is the price that is charged ───────────────────────────
reset role;
select t_ok('8000 at 30% off is charged as 5600, not 8000',
  (select subtotal_xaf from orders where id=(select id from o)) = 5600
  and (select unit_price_xaf from order_items where order_id=(select id from o)) = 5600);

-- ── 4. a recipient cannot rewrite the sender's words ───────────────────────
set role authenticated; select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
create temp table th as select open_thread('33333333-3333-3333-3333-333333333333'::uuid) as id;
insert into messages (thread_id,sender_id,body) values ((select id from th),'22222222-2222-2222-2222-222222222222','I will pay you later');
reset role; set role authenticated; select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333',false);
do $$ begin
  update messages set body='I already paid you 200000 XAF'
   where thread_id=(select id from th) and sender_id='22222222-2222-2222-2222-222222222222';
  raise notice '!! FAIL  the recipient rewrote the sender''s message';
exception when others then
  raise notice 'PASS  the recipient CANNOT rewrite the sender''s message (%)', left(sqlerrm,60);
end $$;
-- but marking it read still works, which is what the policy is for
update messages set read_at = now()
 where thread_id=(select id from th) and sender_id='22222222-2222-2222-2222-222222222222';
reset role;
select t_ok('marking the message read still works',
  (select read_at is not null from messages where thread_id=(select id from th)));
select t_ok('and the body is untouched',
  (select body from messages where thread_id=(select id from th)) = 'I will pay you later');

-- ── 5. a suspended shop cannot re-approve itself ───────────────────────────
update creators set is_approved=false where id='aaaaaaaa-0000-0000-0000-000000000001';
set role authenticated; select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
do $$ begin
  update creators set is_approved=true where profile_id='11111111-1111-1111-1111-111111111111';
  raise notice '!! FAIL  a suspended shop re-approved itself';
exception when others then
  raise notice 'PASS  a suspended shop CANNOT re-approve itself (%)', left(sqlerrm,50);
end $$;
-- editing its own name still works, which is the point of the policy
update creators set name='Nouvelle Boutique' where profile_id='11111111-1111-1111-1111-111111111111';
reset role;
select t_ok('but it can still rename itself',
  (select name from creators where id='aaaaaaaa-0000-0000-0000-000000000001') = 'Nouvelle Boutique');
update creators set is_approved=true where id='aaaaaaaa-0000-0000-0000-000000000001';

-- ── 6. the anon key cannot read a phone number ─────────────────────────────
set role anon; select set_config('request.jwt.claim.sub','',false);
select t_ok('anon can still read a stranger''s NAME',
  (select count(*) from (select id, full_name from profiles) x) >= 1);
do $$ begin
  perform (select phone from profiles limit 1);
  raise notice '!! FAIL  anon read a phone number';
exception when insufficient_privilege then
  raise notice 'PASS  anon CANNOT read a phone number (permission denied)';
end $$;

-- The queries the app actually runs, under the new grants. The first draft of
-- 0007 would have broken sign-in for everybody, because PostgREST's
-- `.select()` is `select *` and the star includes a column this role is now
-- deliberately not granted. These assert the real shapes, not the idea.
reset role; set role authenticated;
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
select t_ok('I can read MY OWN profile in full, phone included, via my_profile()',
  (select (my_profile()).phone) = '+237699999999');
do $$ begin
  perform (select row_to_json(p) from profiles p where p.id = auth.uid());
  raise notice '!! FAIL  select * on profiles still works - the grant did nothing';
exception when insufficient_privilege then
  raise notice 'PASS  and a bare `select *` on profiles is refused, as intended';
end $$;
select t_ok('the inbox''s explicit column list still works',
  (select count(*) from (
     select id, full_name, avatar_url, creator_status, created_at
       from profiles where id = '11111111-1111-1111-1111-111111111111') x) = 1);
do $$ begin
  perform (select (my_profile()).phone);
  raise notice 'PASS  (my_profile is granted to authenticated)';
end $$;
reset role; set role anon; select set_config('request.jwt.claim.sub','',false);
do $$ begin
  perform my_profile();
  raise notice '!! FAIL  anon could call my_profile()';
exception when insufficient_privilege then
  raise notice 'PASS  anon CANNOT call my_profile()';
end $$;

-- ── 7. the inbox reorders ──────────────────────────────────────────────────
reset role;
do $$ declare b timestamptz; a timestamptz; begin
  select last_message_at into b from threads where id=(select id from th);
  perform pg_sleep(0.05);
  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
  insert into messages (thread_id,sender_id,body) values ((select id from th),'22222222-2222-2222-2222-222222222222','ping');
  execute 'reset role';
  select last_message_at into a from threads where id=(select id from th);
  perform t_ok('threads.last_message_at advances when a message is sent', a > b);
end $$;

-- ── 8. a seller cannot post pointing at a rival's product ──────────────────
set role authenticated; select set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333',false);
do $$ begin
  insert into posts (creator_id, product_id, image_url)
  values ('aaaaaaaa-0000-0000-0000-000000000002','bbbbbbbb-0000-0000-0000-000000000001','x');
  raise notice '!! FAIL  a seller posted about a rival''s product';
exception when others then
  raise notice 'PASS  a seller CANNOT post about a rival''s product (%)', left(sqlerrm,50);
end $$;

-- ── 9. a seller can see their own delisted product ─────────────────────────
reset role;
update products set is_active=false where id='bbbbbbbb-0000-0000-0000-000000000001';
set role authenticated; select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
select t_ok('a seller CAN see their own delisted product (so it can be relisted)',
  (select count(*) from products where id='bbbbbbbb-0000-0000-0000-000000000001') = 1);
reset role; set role anon; select set_config('request.jwt.claim.sub','',false);
select t_ok('but a shopper cannot',
  (select count(*) from products where id='bbbbbbbb-0000-0000-0000-000000000001') = 0);

-- ── 10. a silly quantity is refused rather than crashing checkout ──────────
reset role; set role authenticated; select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
do $$ begin
  insert into cart_items (user_id,product_id,qty)
  values ('22222222-2222-2222-2222-222222222222','bbbbbbbb-0000-0000-0000-000000000001',1000000);
  raise notice '!! FAIL  a qty of a million was accepted';
exception when others then
  raise notice 'PASS  an absurd quantity is REFUSED at the column (%)', left(sqlerrm,45);
end $$;
reset role;
