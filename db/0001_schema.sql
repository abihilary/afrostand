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
