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
-- 17 tables, all with RLS, 29 policies, and db/test/rls_test.sql passing 27/27
-- including "anon cannot write to products" and "a third party reads nothing
-- from a chat thread".
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
  v_ship     jsonb;
begin
  if v_user is null then
    raise exception 'not signed in';
  end if;

  if p_delivery_xaf < 0 then
    raise exception 'delivery cannot be negative';
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

  insert into orders (user_id, subtotal_xaf, delivery_xaf, total_xaf, ship_to)
  values (v_user, v_subtotal, p_delivery_xaf, v_subtotal + p_delivery_xaf, v_ship)
  returning id into v_order;

  insert into order_items (order_id, product_id, creator_id, name, image_url, unit_price_xaf, qty, size, color)
  select v_order, p.id, p.creator_id, p.name, p.image_url, p.price_xaf, ci.qty, ci.size, ci.color
    from cart_items ci
    join products p on p.id = ci.product_id
   where ci.user_id = v_user and p.is_active;

  insert into payments (order_id, amount_xaf) values (v_order, v_subtotal + p_delivery_xaf);

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

revoke all on function place_order(uuid, integer) from public;
grant execute on function place_order(uuid, integer) to authenticated;
revoke all on function open_thread(uuid) from public;
grant execute on function open_thread(uuid) to authenticated;
revoke all on function request_creator_status() from public;
grant execute on function request_creator_status() to authenticated;

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
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('2f92b189-69c2-5ddf-aa9c-4c83f9039814', '6bb89b69-8323-5818-958d-fa1935588c4f', null, 'Veste Bogolan', 18000, null, 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('28f79ab3-8ecc-5ab4-b5be-6d736afc0aba', '0ae43481-ac5a-5a30-a8c5-e47f4ea648a1', null, 'Jupe Plissée Wax', 7500, null, 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('a2081627-f06b-5790-b218-2f67679e59e1', 'e8a18e63-21fa-5606-8e1f-b98068b5d3db', null, 'Panier Osier', 5200, null, 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('fddfdbd8-4c35-59df-a927-de96429d11df', '379cef87-9ec4-566f-baab-d6832c86174c', null, 'Ceinture Jute', 3500, null, 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('4052f22a-009d-5468-b416-485c335c39d4', '4803ea25-6c33-529e-ae33-c59634c1a28d', null, 'Tote Bag Coton', 4000, null, 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('6d560a3c-3efd-5aca-b6d6-78821ce7460e', 'e8a18e63-21fa-5606-8e1f-b98068b5d3db', null, 'Pochette Sisal', 6800, null, 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', '{}', true) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('d57638eb-27dd-57ca-86d2-e0a483259c05', 'f926ed01-0ca8-5f96-8f7b-1f90c8ed9264', null, 'Masque Sculpté', 25000, 15, 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('6d6b0476-7b04-51af-a31e-9d12d50eba31', '489638fb-9029-56ae-8f60-f4f09ed6c5b5', null, 'Écharpe Soie Sauvage', 12000, null, 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('c24cd83a-7492-54ad-83bc-f65239a58f58', '4626bd98-5ea2-554e-be43-db53afab419d', null, 'Bougie Parfumée', 4500, null, 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('a3582eb8-913c-5a56-94cf-8da7b4536892', 'e182fc29-eb10-5ca0-a72b-329374ff89d5', null, 'Coffret Épices', 8900, null, 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=800&auto=format&fit=crop', '{}', true) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('fbf163e7-c3f2-5a75-b018-6414eb50973f', 'a2b577cf-9f9e-5e95-8401-674b9ecfacfc', null, 'Tissage Traditionnel', 15000, null, 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop', '{}', true) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('91c034eb-01e5-5d1f-925f-9cbee7796147', '1ffd976c-8479-5e3f-98ae-252ba21d0040', null, 'Potterie Artisanale', 4500, null, 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('06b535e1-676e-5f0e-bf5f-3f8e0d83eb6e', '1ffd976c-8479-5e3f-98ae-252ba21d0040', null, 'Vase Céramique', 9500, null, 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&auto=format&fit=crop', '{}', false) on conflict (id) do nothing;
insert into products (id, creator_id, category_id, name, price_xaf, discount_pct, image_url, tags, is_new) values ('84919b3f-9e4c-54c4-89ef-92637c7e4bee', 'f926ed01-0ca8-5f96-8f7b-1f90c8ed9264', null, 'Statue Bronze', 45000, null, 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?q=80&w=800&auto=format&fit=crop', '{}', true) on conflict (id) do nothing;
