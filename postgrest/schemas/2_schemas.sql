-- schemas for gym management system
create schema if not exists functions;
create schema if not exists api;
create schema if not exists auth;

create table if not exists
api.users (
  id uuid primary key default uuid_generate_v1(),
  name text not null,
  created_at timestamptz default now(),
  email    text unique not null check ( email ~* '^.+@.+\..+$' ),
  pass     text not null check (length(pass) < 512),
  phone    text,
  address  text,
  dni      text,
  role     name not null check (length(role) < 512),
  check (created_at <= now())
);

create table if not exists
api.clients (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  name text not null check (length(name) < 512),
  phone text,
  address text,
  dni text not null unique check (length(dni) < 32),
  access_code text unique not null check (length(access_code) < 32) default generate_access_code(),
  email text,
  check (created_at <= now())
);

create table if not exists
api.plans (
    id uuid primary key default uuid_generate_v1(),
    name text not null,
    description text
);

create table if not exists
api.memberships (
  id uuid primary key default uuid_generate_v1(),
  name text not null check (length(name) < 512),
  price numeric not null check (price > 0),
  clients_limit integer not null check (clients_limit > 0),
  duration integer not null check (duration > 0), -- in days
  plan_id uuid references api.plans(id) not null,
  assistance_limit integer check (assistance_limit > 0 and assistance_limit <= duration)
  /* generated column for set type of subscription */
  item_type text generated always as (case when assistance_limit is null or assistance_limit = duration then 'continuous' else 'interval' end) stored
);

/* add assistance_limit as update table */
alter table api.memberships
  add column if not exists
  assistance_limit integer check (assistance_limit > 0 and assistance_limit <= duration);

/* generated column for set item_type of subscription */
alter table api.memberships
  add column if not exists
  item_type text generated always as (case when assistance_limit is null or assistance_limit = duration then 'continuous' else 'interval' end) stored;

create table if not exists
api.subscriptions (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  client_id uuid not null references api.clients(id),
  membership_id uuid not null references api.memberships(id),
  start_date date not null,
  end_date date not null,
  is_active boolean not null default true,
  price numeric not null check (price >= 0),
  payment_amount numeric not null check (payment_amount >= 0 and payment_amount <= price),
  balance numeric not null check (balance >= 0),
  refered_subscription_id uuid references api.subscriptions(id),
  user_id uuid references api.users(id),
  check (end_date >= start_date),
  check (created_at <= now())
);

alter table api.subscriptions
  add column if not exists
  refered_subscription_id uuid references api.subscriptions(id);

alter table api.subscriptions
  add column if not exists
  user_id uuid references api.users(id);

create table if not exists
api.payments (
    id uuid primary key default uuid_generate_v1(),
    created_at timestamptz default now(),
    subscription_id uuid not null references api.subscriptions(id),
    amount numeric not null check (amount > 0),
    user_id uuid references api.users(id),
    check (created_at <= now())
);

create table if not exists
api.attendances (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  subscription_id uuid not null references api.subscriptions(id),
  date date not null,
  start_time time not null,
  end_time time,
  user_id uuid references api.users(id),
  count integer not null default 0,
  check (created_at <= now()),
  check (end_time >= start_time)
);

/* add count */
alter table api.attendances
  add column if not exists
  count integer not null default 0;

create table if not exists api.permissions (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  subscription_id uuid not null references api.subscriptions(id),
  user_id uuid references api.users(id),
  date date not null,
  check (created_at <= now())
);

create table if not exists
api.products (
  id uuid primary key default uuid_generate_v1(),
  code text not null unique check (length(code) < 15),
  name text not null check (length(name) < 512),
  price numeric not null check (price > 0),
  stock numeric not null check (stock >= 0),
  image bytea
);

create table if not exists
api.sales (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  user_id uuid not null references api.users(id),
  total numeric not null check (total > 0),
  client_id uuid references api.clients(id),
  items jsonb not null default '[]',
  status_id int not null default 1,
    check (created_at <= now())
);

create table if not exists
api.purchases (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  user_id uuid not null references api.users(id),
  total numeric not null check (total > 0),
  client_id uuid references api.clients(id),
  items jsonb not null default '[]',
  status_id int not null default 1,
    check (created_at <= now())
);

create table if not exists
api.cash_register (
  id uuid primary key default uuid_generate_v1(),
  user_id uuid not null references api.users(id),
  created_at timestamptz default now(),
  amount numeric not null check (amount > 0),
  started_at timestamptz not null,
  ended_at timestamptz,
  check (created_at <= now()),
    check (started_at <= now()),
    check (ended_at <= now())

);

create table if not exists
api.expenses (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  user_id uuid not null references api.users(id),
  amount numeric not null check (amount > 0),
  description text not null check (length(description) < 512)
);

create table if not exists
api.incomes (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  user_id uuid not null references api.users(id),
  amount numeric not null check (amount > 0),
  description text not null check (length(description) < 512),
    check (created_at <= now())
);





-- triggers

-- Trigger function for insert on api.sales
CREATE OR REPLACE FUNCTION update_sales_stock_insert()
  RETURNS TRIGGER AS $$
DECLARE
  product_id UUID;
  quantity NUMERIC;
  item_record RECORD;
BEGIN
  IF NEW.items IS NOT NULL THEN -- Check if items exist
    -- Create a temporary table to hold the records
    CREATE TEMP TABLE temp_items AS SELECT * FROM jsonb_array_elements(NEW.items);

    -- Iterate over each item in the temporary table
    FOR item_record IN SELECT * FROM temp_items
    LOOP
      -- Get the product ID and quantity from each item
      product_id := item_record."value"->>'product_id';
      quantity := (item_record."value"->>'quantity')::NUMERIC;

      -- Decrease the stock of the product
      UPDATE api.products
      SET stock = stock - quantity
      WHERE id = product_id;
    END LOOP;

    -- Drop the temporary table
    DROP TABLE IF EXISTS temp_items;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for insert on api.sales
CREATE TRIGGER update_sales_stock_insert_trigger
AFTER INSERT ON api.sales
FOR EACH ROW
EXECUTE FUNCTION update_sales_stock_insert();


-- Trigger function for insert on api.purchases
CREATE OR REPLACE FUNCTION update_purchases_stock_insert()
  RETURNS TRIGGER AS $$
DECLARE
  product_id UUID;
  quantity NUMERIC;
  item_record RECORD;
BEGIN
  IF NEW.items IS NOT NULL THEN -- Check if items exist
    -- Create a temporary table to hold the records
    CREATE TEMP TABLE temp_items AS SELECT * FROM jsonb_array_elements(NEW.items);

    -- Iterate over each item in the temporary table
    FOR item_record IN SELECT * FROM temp_items
    LOOP
      -- Get the product ID and quantity from each item
      product_id := item_record."value"->>'product_id';
      quantity := (item_record."value"->>'quantity')::NUMERIC;

      -- Increase the stock of the product
      UPDATE api.products
      SET stock = stock + quantity
      WHERE id = product_id;
    END LOOP;

    -- Drop the temporary table
    DROP TABLE IF EXISTS temp_items;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for insert on api.purchases
CREATE TRIGGER update_purchases_stock_insert_trigger
AFTER INSERT ON api.purchases
FOR EACH ROW
EXECUTE FUNCTION update_purchases_stock_insert();
