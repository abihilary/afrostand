-- ===========================================================================
-- AFROSTAND - paste this whole file into the Supabase SQL editor and Run.
-- ===========================================================================
-- GENERATED from db/0001_schema.sql + db/0002_seed.sql. Regenerate with
-- db/build_apply.sh rather than editing this file.
--
-- Safe to re-run: every object is guarded and every seed row is ON CONFLICT
-- DO NOTHING against a deterministic id.
--
-- Verified before shipping, against a local Postgres with an auth shim:
-- 17 tables, all with RLS, 29 policies, db/test/rls_test.sql passing 33/33,
-- db/test/fulfilment_test.sql 16/16 and db/test/security_test.sql 17/17, including "one seller cannot ship
-- another seller's goods",
-- "anon cannot write to products" and "a third party reads nothing from a chat
-- thread".
-- ===========================================================================

-- ===========================================================================
-- AFROSTAND — schema, row level security, and the order function.
-- ===========================================================================
-- Idempotent and additive. Safe to run more than once.
--
-- READ THIS BEFORE ADDING A TABLE.
--
-- github.com/abihilary/afrostand is a PUBLIC repository and lib/app/constants.dart
-- carries the anon key. That is fine for an anon key and only for as long as
-- every table has row level security with policies that mean something. A table
-- added here without RLS is a table that anyone who has read the repo can read
-- and write in production. RLS is part of creating a table, not a later pass.
--
-- Two things are computed in Postgres rather than in the app, for the same
-- reason: the client holds a public key and cannot be trusted with either.
--   * place_order() prices the cart from the products table. The app sends an
--     address, never a total.
--   * order_items snapshot the name, price and image at the time of sale, so an
--     order still reads correctly after the product is edited or delisted.
-- ===========================================================================

-- ───────────────────────────────────────────────────────────────────────────
-- 1) Enums
-- ───────────────────────────────────────────────────────────────────────────
do $$ begin
  if not exists (select 1 from pg_type where typname = 'creator_status') then
    create type creator_status as enum ('none', 'requested', 'approved', 'rejected');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type order_status as enum ('pending', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type payment_status as enum ('pending', 'succeeded', 'failed', 'cancelled');
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'payment_kind') then
    create type payment_kind as enum ('mobile_money', 'card', 'cash_on_delivery');
  end if;
end $$;

-- ───────────────────────────────────────────────────────────────────────────
-- 2) Identity
-- ───────────────────────────────────────────────────────────────────────────

-- One row per auth user, created by the trigger below. Holds the preferences
-- the app used to keep only in memory, so theme and language survive a reinstall
-- and follow the account to a second device.
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  avatar_url  text,
  phone       text,
  locale      text not null default 'fr',
  theme       text not null default 'system',
  -- Selling is requested and then granted. 'approved' is set by hand in SQL
  -- until there is an admin screen; nothing in the app may write this column,
  -- which is why the profiles update policy below excludes it.
  creator_status creator_status not null default 'none',
  created_at  timestamptz not null default now()
);

-- A signup with no profile row would leave the app unable to read its own
-- user's name. Doing it in a trigger rather than from the client means it
-- cannot be skipped by a client that fails between the two calls.
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into profiles (id, full_name)
  values (new.id, nullif(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Backfill. The trigger only fires on new signups, and accounts created while
-- testing sign-in — before this schema existed — have no profile row at all.
-- Without this they hit a foreign key the first time anything references them,
-- and `update profiles ... where id = <them>` quietly matches nothing.
insert into profiles (id, full_name)
select u.id, nullif(u.raw_user_meta_data->>'full_name', '')
  from auth.users u
 where not exists (select 1 from profiles p where p.id = u.id);

-- A storefront. profile_id is nullable because the seeded catalogue creators
-- are not accounts — they are the shops the marketplace launched with, and they
-- get claimed later.
create table if not exists creators (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid unique references profiles(id) on delete set null,
  name        text not null,
  slug        text unique not null,
  location    text,
  bio         text,
  avatar_url  text,
  banner_url  text,
  is_approved boolean not null default false,
  created_at  timestamptz not null default now()
);

-- ───────────────────────────────────────────────────────────────────────────
-- 3) Catalogue
-- ───────────────────────────────────────────────────────────────────────────
create table if not exists categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text unique not null,
  image_url   text,
  description text,
  sort        integer not null default 0
);

create table if not exists products (
  id           uuid primary key default gen_random_uuid(),
  creator_id   uuid not null references creators(id) on delete cascade,
  category_id  uuid references categories(id) on delete set null,
  name         text not null,
  description  text,
  -- Integer minor-unit-free XAF. The franc has no subdivision in practice, and
  -- a float price in a shop is a rounding bug waiting for a large order.
  price_xaf    integer not null check (price_xaf >= 0),
  discount_pct integer check (discount_pct between 0 and 100),
  image_url    text not null,
  gallery      text[] not null default '{}',
  tags         text[] not null default '{}',
  is_new       boolean not null default false,
  -- Delisting rather than deleting: an order_item points at this row, and a
  -- sold product must stay resolvable.
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

create index if not exists products_creator_idx  on products(creator_id);
create index if not exists products_category_idx on products(category_id);
create index if not exists products_active_idx   on products(is_active, created_at desc);
create index if not exists products_tags_idx     on products using gin(tags);

-- ───────────────────────────────────────────────────────────────────────────
-- 4) Shopping
-- ───────────────────────────────────────────────────────────────────────────
-- size and color default to '' rather than null: Postgres treats nulls as
-- distinct in a unique index, so a nullable variant column would let the same
-- product be added to a cart over and over as separate rows.
create table if not exists cart_items (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  qty        integer not null default 1 check (qty > 0),
  size       text not null default '',
  color      text not null default '',
  added_at   timestamptz not null default now(),
  unique (user_id, product_id, size, color)
);
create index if not exists cart_items_user_idx on cart_items(user_id);

create table if not exists wishlist (
  user_id    uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  added_at   timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table if not exists addresses (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  label      text,
  full_name  text not null,
  phone      text not null,
  line1      text not null,
  line2      text,
  city       text not null,
  country    text not null default 'CM',
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists addresses_user_idx on addresses(user_id);

-- No card numbers. `masked` is a display string the app shows back to the
-- operator and nothing more; the real instrument lives with whichever provider
-- replaces the stub.
create table if not exists payment_methods (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  kind       payment_kind not null,
  label      text not null,
  masked     text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists payment_methods_user_idx on payment_methods(user_id);

-- ───────────────────────────────────────────────────────────────────────────
-- 5) Orders
-- ───────────────────────────────────────────────────────────────────────────
create sequence if not exists order_code_seq start 1000;

create table if not exists orders (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  code         text unique not null default ('AS-' || nextval('order_code_seq')::text),
  status       order_status not null default 'pending',
  subtotal_xaf integer not null check (subtotal_xaf >= 0),
  delivery_xaf integer not null default 0 check (delivery_xaf >= 0),
  total_xaf    integer not null check (total_xaf >= 0),
  -- A snapshot, not a reference. Editing an address must not rewrite where a
  -- parcel was already sent.
  ship_to      jsonb not null,
  created_at   timestamptz not null default now()
);
create index if not exists orders_user_idx on orders(user_id, created_at desc);

create table if not exists order_items (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references orders(id) on delete cascade,
  product_id     uuid references products(id) on delete set null,
  creator_id     uuid references creators(id) on delete set null,
  -- Snapshots. The product may be renamed, repriced or delisted tomorrow.
  name           text not null,
  image_url      text,
  unit_price_xaf integer not null check (unit_price_xaf >= 0),
  qty            integer not null check (qty > 0),
  size           text not null default '',
  color          text not null default ''
);
create index if not exists order_items_order_idx   on order_items(order_id);
create index if not exists order_items_creator_idx on order_items(creator_id);

create table if not exists payments (
  id           uuid primary key default gen_random_uuid(),
  order_id     uuid not null references orders(id) on delete cascade,
  provider     text not null default 'stub',
  provider_ref text,
  status       payment_status not null default 'pending',
  amount_xaf   integer not null check (amount_xaf >= 0),
  raw          jsonb not null default '{}',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists payments_order_idx on payments(order_id);

-- ───────────────────────────────────────────────────────────────────────────
-- 6) Social
-- ───────────────────────────────────────────────────────────────────────────
create table if not exists follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  creator_id  uuid not null references creators(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, creator_id)
);
create index if not exists follows_creator_idx on follows(creator_id);

create table if not exists posts (
  id         uuid primary key default gen_random_uuid(),
  creator_id uuid not null references creators(id) on delete cascade,
  product_id uuid references products(id) on delete set null,
  image_url  text not null,
  caption    text,
  created_at timestamptz not null default now()
);
create index if not exists posts_created_idx on posts(created_at desc);
create index if not exists posts_creator_idx on posts(creator_id);

create table if not exists post_likes (
  post_id    uuid not null references posts(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists post_comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references posts(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  body       text not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now()
);
create index if not exists post_comments_post_idx on post_comments(post_id, created_at);

-- ───────────────────────────────────────────────────────────────────────────
-- 7) Chat
-- ───────────────────────────────────────────────────────────────────────────
-- a_id < b_id is enforced so a pair of people has exactly one thread however
-- they reach it. Without it, two people opening a conversation at the same
-- moment end up with two threads and each sees half the messages.
create table if not exists threads (
  id              uuid primary key default gen_random_uuid(),
  a_id            uuid not null references auth.users(id) on delete cascade,
  b_id            uuid not null references auth.users(id) on delete cascade,
  last_message_at timestamptz not null default now(),
  created_at      timestamptz not null default now(),
  constraint threads_ordered check (a_id < b_id),
  unique (a_id, b_id)
);

create table if not exists messages (
  id         uuid primary key default gen_random_uuid(),
  thread_id  uuid not null references threads(id) on delete cascade,
  sender_id  uuid not null references auth.users(id) on delete cascade,
  body       text not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now(),
  read_at    timestamptz
);
create index if not exists messages_thread_idx on messages(thread_id, created_at);

create or replace function touch_thread()
returns trigger language plpgsql as $$
begin
  update threads set last_message_at = new.created_at where id = new.thread_id;
  return new;
end $$;

drop trigger if exists on_message_sent on messages;
create trigger on_message_sent
  after insert on messages
  for each row execute function touch_thread();

-- ───────────────────────────────────────────────────────────────────────────
-- 8) Helpers used by policies
-- ───────────────────────────────────────────────────────────────────────────

-- The creator row the caller owns, or null. Used by every creator-writes-own
-- policy, so the rule lives in one place rather than being restated per table.
create or replace function my_creator_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select c.id from creators c
  where c.profile_id = auth.uid() and c.is_approved
  limit 1
$$;

-- Both of these exist to break a recursion rather than to save typing.
--
-- The orders policy needs to know "does this order contain my goods", which
-- means reading order_items -- whose own policy needs to know "is this my
-- order", which means reading orders. Each policy triggers the other and
-- Postgres raises `infinite recursion detected in policy for relation
-- "orders"`, which makes orders unreadable for everyone, not just creators.
--
-- SECURITY DEFINER runs the inner query as the owner, so it does not re-enter
-- the policy being evaluated. The functions are narrow on purpose: each
-- answers one boolean about one order and leaks nothing else.
create or replace function owns_order(p_order uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from orders o where o.id = p_order and o.user_id = auth.uid())
$$;

create or replace function sells_in_order(p_order uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from order_items oi
    where oi.order_id = p_order and oi.creator_id = my_creator_id()
  )
$$;

create or replace function in_thread(t_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from threads t
    where t.id = t_id and (t.a_id = auth.uid() or t.b_id = auth.uid())
  )
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- 9) Row level security
-- ───────────────────────────────────────────────────────────────────────────
alter table profiles        enable row level security;
alter table creators        enable row level security;
alter table categories      enable row level security;
alter table products        enable row level security;
alter table cart_items      enable row level security;
alter table wishlist        enable row level security;
alter table addresses       enable row level security;
alter table payment_methods enable row level security;
alter table orders          enable row level security;
alter table order_items     enable row level security;
alter table payments        enable row level security;
alter table follows         enable row level security;
alter table posts           enable row level security;
alter table post_likes      enable row level security;
alter table post_comments   enable row level security;
alter table threads         enable row level security;
alter table messages        enable row level security;

-- Catalogue: the shop window. Readable by anyone, including signed-out.
drop policy if exists categories_read on categories;
create policy categories_read on categories for select using (true);

drop policy if exists creators_read on creators;
create policy creators_read on creators for select using (true);

drop policy if exists products_read on products;
create policy products_read on products for select using (is_active);

-- A creator writes only their own products, and only once approved —
-- my_creator_id() returns null for everyone else, and null never equals a uuid.
drop policy if exists products_insert_own on products;
create policy products_insert_own on products for insert
  with check (creator_id = my_creator_id());

drop policy if exists products_update_own on products;
create policy products_update_own on products for update
  using (creator_id = my_creator_id()) with check (creator_id = my_creator_id());

drop policy if exists products_delete_own on products;
create policy products_delete_own on products for delete
  using (creator_id = my_creator_id());

drop policy if exists creators_update_own on creators;
create policy creators_update_own on creators for update
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- Profiles are public to read — a comment and a chat both need a name and an
-- avatar for somebody who is not you.
drop policy if exists profiles_read on profiles;
create policy profiles_read on profiles for select using (true);

-- You may edit your own profile, but creator_status is granted, never claimed.
-- The app asks for it through request_creator_status() below.
drop policy if exists profiles_update_own on profiles;
create policy profiles_update_own on profiles for update
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and creator_status = (select p.creator_status from profiles p where p.id = auth.uid())
  );

-- Owner-only. The same shape for all five.
drop policy if exists cart_own on cart_items;
create policy cart_own on cart_items for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists wishlist_own on wishlist;
create policy wishlist_own on wishlist for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists addresses_own on addresses;
create policy addresses_own on addresses for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists payment_methods_own on payment_methods;
create policy payment_methods_own on payment_methods for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Orders are readable by the buyer, and by the creator of anything in them so
-- a shop can see what it has to send. Nobody inserts an order directly: that is
-- place_order()'s job, which is why there is no insert policy here at all.
drop policy if exists orders_read_own on orders;
create policy orders_read_own on orders for select
  using (user_id = auth.uid() or sells_in_order(id));

drop policy if exists order_items_read on order_items;
create policy order_items_read on order_items for select
  using (owns_order(order_id) or creator_id = my_creator_id());

drop policy if exists payments_read on payments;
create policy payments_read on payments for select using (owns_order(order_id));

-- Follows: public counts, own writes.
drop policy if exists follows_read on follows;
create policy follows_read on follows for select using (true);

drop policy if exists follows_write_own on follows;
create policy follows_write_own on follows for all
  using (follower_id = auth.uid()) with check (follower_id = auth.uid());

-- The feed is public; posting belongs to the creator it is attributed to.
drop policy if exists posts_read on posts;
create policy posts_read on posts for select using (true);

drop policy if exists posts_write_own on posts;
create policy posts_write_own on posts for all
  using (creator_id = my_creator_id()) with check (creator_id = my_creator_id());

drop policy if exists post_likes_read on post_likes;
create policy post_likes_read on post_likes for select using (true);

drop policy if exists post_likes_own on post_likes;
create policy post_likes_own on post_likes for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists post_comments_read on post_comments;
create policy post_comments_read on post_comments for select using (true);

-- Write your own, and edit or delete only your own. A comment is somebody's
-- words; nobody else gets to change them.
drop policy if exists post_comments_own on post_comments;
create policy post_comments_own on post_comments for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Chat: participants only, on both tables. This is the strictest thing here and
-- the one most worth getting right — a leak is somebody's private conversation.
drop policy if exists threads_participants on threads;
create policy threads_participants on threads for select
  using (a_id = auth.uid() or b_id = auth.uid());

drop policy if exists threads_create on threads;
create policy threads_create on threads for insert
  with check (a_id = auth.uid() or b_id = auth.uid());

drop policy if exists messages_read on messages;
create policy messages_read on messages for select using (in_thread(thread_id));

-- You may only send as yourself, and only into a thread you are in.
drop policy if exists messages_send on messages;
create policy messages_send on messages for insert
  with check (sender_id = auth.uid() and in_thread(thread_id));

-- Marking as read is the only update allowed, and only by the recipient.
drop policy if exists messages_mark_read on messages;
create policy messages_mark_read on messages for update
  using (in_thread(thread_id) and sender_id <> auth.uid())
  with check (in_thread(thread_id) and sender_id <> auth.uid());

-- ───────────────────────────────────────────────────────────────────────────
-- 10) Operations the client is not trusted to do itself
-- ───────────────────────────────────────────────────────────────────────────

-- Ask to become a seller. Separate from the profile update policy so that
-- wanting to sell and being allowed to sell stay different things: this can
-- only ever move 'none'/'rejected' to 'requested'.
create or replace function request_creator_status()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  update profiles
     set creator_status = 'requested'
   where id = auth.uid()
     and creator_status in ('none', 'rejected');
end $$;

-- Turn the caller's cart into an order.
--
-- Prices come from the products table inside this function. The app passes an
-- address and nothing else — no totals, no line prices. A client that sends a
-- cheaper number has nowhere to send it.
-- Delivery is decided here, not sent. The signature still takes the argument so
-- an older build does not break, but the value is ignored: a client that posts
-- `p_delivery_xaf = 0` is a client that has patched out the shipping fee, and
-- there is no way to tell that apart from an honest one.
--
-- A flat rate with a free threshold, which is what the cart has always shown.
-- When there is a real rate card (by city, by weight) it becomes a table read
-- here — still server side.
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
  c_flat     constant integer := 1500;
  c_free_over constant integer := 50000;
begin
  if v_user is null then
    raise exception 'not signed in';
  end if;

  -- The address must belong to the caller. Without this check anyone could
  -- post an order to somebody else's saved address by guessing an id.
  select to_jsonb(a) - 'user_id' into v_ship
    from addresses a
   where a.id = p_address_id and a.user_id = v_user;
  if v_ship is null then
    raise exception 'no such address';
  end if;

  -- Priced here, from products, at the moment of sale.
  select coalesce(sum(p.price_xaf * ci.qty), 0) into v_subtotal
    from cart_items ci
    join products p on p.id = ci.product_id
   where ci.user_id = v_user and p.is_active;

  if v_subtotal = 0 then
    raise exception 'cart is empty';
  end if;

  v_delivery := case when v_subtotal >= c_free_over then 0 else c_flat end;

  insert into orders (user_id, subtotal_xaf, delivery_xaf, total_xaf, ship_to)
  values (v_user, v_subtotal, v_delivery, v_subtotal + v_delivery, v_ship)
  returning id into v_order;

  insert into order_items (order_id, product_id, creator_id, name, image_url, unit_price_xaf, qty, size, color)
  select v_order, p.id, p.creator_id, p.name, p.image_url, p.price_xaf, ci.qty, ci.size, ci.color
    from cart_items ci
    join products p on p.id = ci.product_id
   where ci.user_id = v_user and p.is_active;

  insert into payments (order_id, amount_xaf) values (v_order, v_subtotal + v_delivery);

  delete from cart_items where user_id = v_user;

  return v_order;
end $$;

-- Open (or find) the conversation between the caller and another person.
-- Canonicalises the pair so the a_id < b_id constraint is never the app's
-- problem, and returns the existing thread rather than failing on the unique.
create or replace function open_thread(p_other uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_me uuid := auth.uid();
  v_a  uuid;
  v_b  uuid;
  v_id uuid;
begin
  if v_me is null then raise exception 'not signed in'; end if;
  if p_other = v_me then raise exception 'cannot open a thread with yourself'; end if;

  v_a := least(v_me, p_other);
  v_b := greatest(v_me, p_other);

  select id into v_id from threads where a_id = v_a and b_id = v_b;
  if v_id is not null then return v_id; end if;

  insert into threads (a_id, b_id) values (v_a, v_b) returning id into v_id;
  return v_id;
end $$;

-- ⚠ THE STUB'S SEAM — DELETE THIS WHEN A REAL PROVIDER ARRIVES ⚠
--
-- Settles a payment the app says went through. With a stubbed gateway there is
-- no honest alternative: nothing but the client knows the charge "happened", so
-- the client has to say so. That makes this the one function here a determined
-- customer could abuse to mark their own order paid without paying.
--
-- It is tolerable only because the gateway is a stub and no money moves either
-- way. The moment Campay or MoMo is wired up, this function is dropped and the
-- provider's webhook does the same job from the server side, where the claim
-- comes from whoever actually took the money.
--
-- It is deliberately narrow even so: it only ever moves a *pending* payment on
-- the caller's *own* order, so it cannot re-settle, cannot refund, and cannot
-- touch somebody else's order.
create or replace function settle_stub_payment(p_order_id uuid, p_reference text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'not signed in'; end if;

  if not exists (select 1 from orders o where o.id = p_order_id and o.user_id = v_user) then
    raise exception 'no such order';
  end if;

  update payments
     set status = 'succeeded', provider_ref = p_reference, updated_at = now()
   where order_id = p_order_id and status = 'pending';

  update orders set status = 'paid' where id = p_order_id and status = 'pending';
end $$;

-- Cancelling is the buyer's to do and carries no such caveat.
create or replace function cancel_my_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  update orders
     set status = 'cancelled'
   where id = p_order_id and user_id = auth.uid() and status in ('pending', 'paid');
  update payments
     set status = 'cancelled', updated_at = now()
   where order_id = p_order_id and status = 'pending';
end $$;

revoke all on function settle_stub_payment(uuid, text) from public;
grant execute on function settle_stub_payment(uuid, text) to authenticated;
revoke all on function cancel_my_order(uuid) from public;
grant execute on function cancel_my_order(uuid) to authenticated;
-- So the cart can show the figure the server will actually charge, rather than
-- a second copy of the rule in Dart that can drift from this one.
create or replace function delivery_quote(p_subtotal_xaf integer)
returns integer
language sql
immutable
as $$ select case when p_subtotal_xaf >= 50000 then 0 else 1500 end $$;

grant execute on function delivery_quote(integer) to anon, authenticated;

revoke all on function place_order(uuid, integer) from public;
grant execute on function place_order(uuid, integer) to authenticated;
revoke all on function open_thread(uuid) from public;
grant execute on function open_thread(uuid) to authenticated;
revoke all on function request_creator_status() from public;
grant execute on function request_creator_status() to authenticated;

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

-- Wrapped so this file can live in db/apply.sql: Supabase always has the
-- storage schema, a local test database does not, and a bundle that dies
-- halfway through on a laptop cannot be tested before it is pasted.
do $do$
begin
if to_regclass('storage.objects') is null then
  raise notice 'no storage schema here - skipping buckets and their policies';
  return;
end if;

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
end
$do$;

-- ===========================================================================
-- AFROSTAND seed - GENERATED, do not edit.
-- Source: supabase_init/{categories,creators,products}.json
-- Regenerate: python3 db/build_seed.py
-- ===========================================================================
-- Ids are uuid5 over the slug, so this is safe to re-run: the same rows get
-- the same ids and ON CONFLICT turns a second run into a no-op rather than a
-- duplicate catalogue.
--
-- These creators have no profile_id. They are the shops the marketplace
-- launches with, not accounts - a real person claims one later by having
-- profile_id set. Until then nobody can edit their products, because
-- my_creator_id() can never return their id.

-- categories
insert into categories (id, name, slug, image_url, description, sort) values ('12952e63-8808-5a67-9b3b-da33c924ddf3', 'Local', 'local', 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop', 'New Collection - Mode locale authentique', 0) on conflict (id) do nothing;
insert into categories (id, name, slug, image_url, description, sort) values ('fefed0d2-10e5-5782-91e0-dcb1223c20de', 'Sustainable', 'sustainable', 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&auto=format&fit=crop', 'Eco-Fashion 2025 - Mode éthique et durable', 1) on conflict (id) do nothing;
insert into categories (id, name, slug, image_url, description, sort) values ('dd41565b-7594-596d-bba3-d21adf8927ae', 'Gift', 'gift', 'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?q=80&w=800&auto=format&fit=crop', 'Cadeaux Uniques - Offrez le meilleur de l’artisanat', 2) on conflict (id) do nothing;
insert into categories (id, name, slug, image_url, description, sort) values ('aaab66ad-9f1f-5dd2-a27d-6038de667920', 'Handmade', 'handmade', 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', 'Savoir-faire Manuel - Chaque pièce est unique', 3) on conflict (id) do nothing;
insert into categories (id, name, slug, image_url, description, sort) values ('e42b3238-5882-54cd-b265-644d74f627ed', 'Wax', 'wax', 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?q=80&w=800&auto=format&fit=crop', null, 4) on conflict (id) do nothing;
insert into categories (id, name, slug, image_url, description, sort) values ('a730dda2-4798-5691-ab1c-6d679a109b85', 'Bijoux', 'bijoux', 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?q=80&w=800&auto=format&fit=crop', null, 5) on conflict (id) do nothing;
insert into categories (id, name, slug, image_url, description, sort) values ('844b0adf-7c7f-5447-9e60-434868f9f7ab', 'Cuir', 'cuir', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?q=80&w=800&auto=format&fit=crop', null, 6) on conflict (id) do nothing;
insert into categories (id, name, slug, image_url, description, sort) values ('fb85fe42-14f4-5064-b1aa-054bcf083fe0', 'Raphia', 'raphia', 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', null, 7) on conflict (id) do nothing;

-- creators
insert into creators (id, name, slug, is_approved) values ('6bb89b69-8323-5818-958d-fa1935588c4f', 'MIDE Stores', 'mide-stores', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('0ae43481-ac5a-5a30-a8c5-e47f4ea648a1', 'Aïsha K.', 'aisha-k', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('7dd7a07d-5f95-5721-838e-42b85f822eed', 'Ghanart', 'ghanart', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('4803ea25-6c33-529e-ae33-c59634c1a28d', 'Atelier Dakar', 'atelier-dakar', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('8ab8e80c-4f75-5fdf-81c5-22d4b5b86494', 'Maro Dakar', 'maro-dakar', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('a8d87b1a-75bd-5f3b-a681-ed787410c060', 'Bijoux Baobab', 'bijoux-baobab', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('9dc41081-dbe6-5159-b1dc-8f3e25fb8d71', 'Galerie Nomade', 'galerie-nomade', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('f926ed01-0ca8-5f96-8f7b-1f90c8ed9264', 'Heritage', 'heritage', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('9476ae6b-c288-53b0-8d00-0ee38d1301be', 'Indigo Studio', 'indigo-studio', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('489638fb-9029-56ae-8f60-f4f09ed6c5b5', 'Artisanat Mali', 'artisanat-mali', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('379cef87-9ec4-566f-baab-d6832c86174c', 'Eco Wear', 'eco-wear', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('e8a18e63-21fa-5606-8e1f-b98068b5d3db', 'Nature Art', 'nature-art', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('4626bd98-5ea2-554e-be43-db53afab419d', 'Dakar Scent', 'dakar-scent', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('e182fc29-eb10-5ca0-a72b-329374ff89d5', 'Terroir', 'terroir', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('a2b577cf-9f9e-5e95-8401-674b9ecfacfc', 'Kente Craft', 'kente-craft', true) on conflict (id) do nothing;
insert into creators (id, name, slug, is_approved) values ('1ffd976c-8479-5e3f-98ae-252ba21d0040', 'Dakar Art', 'dakar-art', true) on conflict (id) do nothing;

-- products
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('b2506a20-529f-5fa7-91c1-a52e0ee92985', '6bb89b69-8323-5818-958d-fa1935588c4f', 'e42b3238-5882-54cd-b265-644d74f627ed', 'Boubou Wax Royal', 8000, null, 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?q=80&w=800&auto=format&fit=crop', array['Wax', 'Royal', 'MIDE', 'Habits', 'Dakar']::text[], true) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('e8a36cf1-305d-5aee-bfbd-27b964965687', '0ae43481-ac5a-5a30-a8c5-e47f4ea648a1', '12952e63-8808-5a67-9b3b-da33c924ddf3', 'Ensemble Ankara', 12500, 30, 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop', array['Ankara', 'Ensemble', 'Habits']::text[], false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('68b5b753-282e-5112-8f7d-32de4999e9fb', '7dd7a07d-5f95-5721-838e-42b85f822eed', 'aaab66ad-9f1f-5dd2-a27d-6038de667920', 'Tunique Kente', 10500, null, 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop', array['Kente', 'Tunique', 'Handmade']::text[], false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('424c160d-4f81-573b-b917-0eccea936cf0', '4803ea25-6c33-529e-ae33-c59634c1a28d', 'fb85fe42-14f4-5064-b1aa-054bcf083fe0', 'Sac Raphia Tressé', 9800, null, 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', array['Raphia', 'Sac', 'Sustainable']::text[], false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('83d7b911-241a-5d91-be2c-f46d8fc91063', '8ab8e80c-4f75-5fdf-81c5-22d4b5b86494', '844b0adf-7c7f-5447-9e60-434868f9f7ab', 'Sandales Cuir Bio', 7400, null, 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?q=80&w=800&auto=format&fit=crop', array['Cuir', 'Bio', 'Sandales', 'Sustainable']::text[], true) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('c8be2539-4404-5209-957e-23d14ce58270', 'a8d87b1a-75bd-5f3b-a681-ed787410c060', 'a730dda2-4798-5691-ab1c-6d679a109b85', 'Boucles Cauri Gold', 3200, null, 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?q=80&w=800&auto=format&fit=crop', array['Bijoux', 'Cauri', 'Gold', 'Cadeau']::text[], true) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('dd861805-fd37-5181-bc49-74fe2d3f4806', '6bb89b69-8323-5818-958d-fa1935588c4f', 'dd41565b-7594-596d-bba3-d21adf8927ae', 'Chemise Bogolan', 6500, null, 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop', array['Bogolan', 'Chemise', 'Cadeau']::text[], false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('e7a764e8-1957-5320-873a-faa95d216312', '9dc41081-dbe6-5159-b1dc-8f3e25fb8d71', 'aaab66ad-9f1f-5dd2-a27d-6038de667920', 'Tableau Batik', 32000, null, 'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?q=80&w=800&auto=format&fit=crop', array['Batik', 'Tableau', 'Art', 'Handmade']::text[], false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('1f5ba491-561b-5463-b579-b6c880829d3b', 'f926ed01-0ca8-5f96-8f7b-1f90c8ed9264', 'aaab66ad-9f1f-5dd2-a27d-6038de667920', 'Poupée Akan', 6000, null, 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&auto=format&fit=crop', array['Akan', 'Handmade', 'Cadeau']::text[], false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('74565403-d868-5699-b158-b1b9d3fd3d3a', '9476ae6b-c288-53b0-8d00-0ee38d1301be', 'e42b3238-5882-54cd-b265-644d74f627ed', 'Robe Indigo', 14200, null, 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', array['Indigo', 'Robe', 'Wax']::text[], false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('2f92b189-69c2-5ddf-aa9c-4c83f9039814', '6bb89b69-8323-5818-958d-fa1935588c4f', '12952e63-8808-5a67-9b3b-da33c924ddf3', 'Veste Bogolan', 18000, null, 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('28f79ab3-8ecc-5ab4-b5be-6d736afc0aba', '0ae43481-ac5a-5a30-a8c5-e47f4ea648a1', 'e42b3238-5882-54cd-b265-644d74f627ed', 'Jupe Plissée Wax', 7500, null, 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('a2081627-f06b-5790-b218-2f67679e59e1', 'e8a18e63-21fa-5606-8e1f-b98068b5d3db', 'fb85fe42-14f4-5064-b1aa-054bcf083fe0', 'Panier Osier', 5200, null, 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('fddfdbd8-4c35-59df-a927-de96429d11df', '379cef87-9ec4-566f-baab-d6832c86174c', 'fefed0d2-10e5-5782-91e0-dcb1223c20de', 'Ceinture Jute', 3500, null, 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('4052f22a-009d-5468-b416-485c335c39d4', '4803ea25-6c33-529e-ae33-c59634c1a28d', 'fefed0d2-10e5-5782-91e0-dcb1223c20de', 'Tote Bag Coton', 4000, null, 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('6d560a3c-3efd-5aca-b6d6-78821ce7460e', 'e8a18e63-21fa-5606-8e1f-b98068b5d3db', 'fb85fe42-14f4-5064-b1aa-054bcf083fe0', 'Pochette Sisal', 6800, null, 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', '{}', true) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('d57638eb-27dd-57ca-86d2-e0a483259c05', 'f926ed01-0ca8-5f96-8f7b-1f90c8ed9264', 'aaab66ad-9f1f-5dd2-a27d-6038de667920', 'Masque Sculpté', 25000, 15, 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('6d6b0476-7b04-51af-a31e-9d12d50eba31', '489638fb-9029-56ae-8f60-f4f09ed6c5b5', '12952e63-8808-5a67-9b3b-da33c924ddf3', 'Écharpe Soie Sauvage', 12000, null, 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('c24cd83a-7492-54ad-83bc-f65239a58f58', '4626bd98-5ea2-554e-be43-db53afab419d', 'dd41565b-7594-596d-bba3-d21adf8927ae', 'Bougie Parfumée', 4500, null, 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('a3582eb8-913c-5a56-94cf-8da7b4536892', 'e182fc29-eb10-5ca0-a72b-329374ff89d5', 'dd41565b-7594-596d-bba3-d21adf8927ae', 'Coffret Épices', 8900, null, 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', '{}', true) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('fbf163e7-c3f2-5a75-b018-6414eb50973f', 'a2b577cf-9f9e-5e95-8401-674b9ecfacfc', 'aaab66ad-9f1f-5dd2-a27d-6038de667920', 'Tissage Traditionnel', 15000, null, 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', '{}', true) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('91c034eb-01e5-5d1f-925f-9cbee7796147', '1ffd976c-8479-5e3f-98ae-252ba21d0040', 'aaab66ad-9f1f-5dd2-a27d-6038de667920', 'Potterie Artisanale', 4500, null, 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('06b535e1-676e-5f0e-bf5f-3f8e0d83eb6e', '1ffd976c-8479-5e3f-98ae-252ba21d0040', 'aaab66ad-9f1f-5dd2-a27d-6038de667920', 'Vase Céramique', 9500, null, 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('84919b3f-9e4c-54c4-89ef-92637c7e4bee', 'f926ed01-0ca8-5f96-8f7b-1f90c8ed9264', 'aaab66ad-9f1f-5dd2-a27d-6038de667920', 'Statue Bronze', 45000, null, 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?q=80&w=800&auto=format&fit=crop', '{}', true) on conflict (id) do nothing;

-- posts: each seeded shop showing one of its own products
insert into posts (id, creator_id, product_id, image_url, caption) values ('71a53cbd-1722-574b-bbfc-0ac070d0d4a0', '6bb89b69-8323-5818-958d-fa1935588c4f', 'b2506a20-529f-5fa7-91c1-a52e0ee92985', 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?q=80&w=800&auto=format&fit=crop', 'Boubou Wax Royal') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('65bf6a56-ba61-5c73-8a79-ec2e34dbbd02', '0ae43481-ac5a-5a30-a8c5-e47f4ea648a1', 'e8a36cf1-305d-5aee-bfbd-27b964965687', 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop', 'Ensemble Ankara') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('f2ac3610-aa4e-5752-a697-8d547b66d873', '7dd7a07d-5f95-5721-838e-42b85f822eed', '68b5b753-282e-5112-8f7d-32de4999e9fb', 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=800&auto=format&fit=crop', 'Tunique Kente') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('733b4aa5-46c0-504a-855f-57a6d74b2e63', '4803ea25-6c33-529e-ae33-c59634c1a28d', '424c160d-4f81-573b-b917-0eccea936cf0', 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', 'Sac Raphia Tressé') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('48f376db-da7a-55af-8de0-649d83b37f3a', '8ab8e80c-4f75-5fdf-81c5-22d4b5b86494', '83d7b911-241a-5d91-be2c-f46d8fc91063', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?q=80&w=800&auto=format&fit=crop', 'Sandales Cuir Bio') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('c519d9eb-c794-582e-a388-345ad063a1e1', 'a8d87b1a-75bd-5f3b-a681-ed787410c060', 'c8be2539-4404-5209-957e-23d14ce58270', 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?q=80&w=800&auto=format&fit=crop', 'Boucles Cauri Gold') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('c09005d3-b755-5a81-a318-559624f2436b', '9dc41081-dbe6-5159-b1dc-8f3e25fb8d71', 'e7a764e8-1957-5320-873a-faa95d216312', 'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?q=80&w=800&auto=format&fit=crop', 'Tableau Batik') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('a0e68aec-fd50-50d4-a690-1b4aa8806e0b', 'f926ed01-0ca8-5f96-8f7b-1f90c8ed9264', '1f5ba491-561b-5463-b579-b6c880829d3b', 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&auto=format&fit=crop', 'Poupée Akan') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('ce2a3a26-663c-5026-8610-4be66205ea1e', '9476ae6b-c288-53b0-8d00-0ee38d1301be', '74565403-d868-5699-b158-b1b9d3fd3d3a', 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', 'Robe Indigo') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('f7d62eec-1853-5567-830c-003584eb9870', 'e8a18e63-21fa-5606-8e1f-b98068b5d3db', 'a2081627-f06b-5790-b218-2f67679e59e1', 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&auto=format&fit=crop', 'Panier Osier') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('87518132-f984-5ec0-8382-f384d593fbee', '379cef87-9ec4-566f-baab-d6832c86174c', 'fddfdbd8-4c35-59df-a927-de96429d11df', 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?q=80&w=800&auto=format&fit=crop', 'Ceinture Jute') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('a77a3545-e3a3-5208-8506-9d84d5c50a8b', '489638fb-9029-56ae-8f60-f4f09ed6c5b5', '6d6b0476-7b04-51af-a31e-9d12d50eba31', 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop', 'Écharpe Soie Sauvage') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('c24ce723-a6e5-5906-a750-e8ed310a55a4', '4626bd98-5ea2-554e-be43-db53afab419d', 'c24cd83a-7492-54ad-83bc-f65239a58f58', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?q=80&w=800&auto=format&fit=crop', 'Bougie Parfumée') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('7f6d6a2a-64e6-562b-a603-b18c6c1c2df0', 'e182fc29-eb10-5ca0-a72b-329374ff89d5', 'a3582eb8-913c-5a56-94cf-8da7b4536892', 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', 'Coffret Épices') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('7bc08ab6-40b9-5c99-8564-1601b73d4b8d', 'a2b577cf-9f9e-5e95-8401-674b9ecfacfc', 'fbf163e7-c3f2-5a75-b018-6414eb50973f', 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', 'Tissage Traditionnel') on conflict (id) do nothing;
insert into posts (id, creator_id, product_id, image_url, caption) values ('abe4574c-724b-5c3b-871d-0cfc844c045c', '1ffd976c-8479-5e3f-98ae-252ba21d0040', '91c034eb-01e5-5d1f-925f-9cbee7796147', 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?q=80&w=800&auto=format&fit=crop', 'Potterie Artisanale') on conflict (id) do nothing;
