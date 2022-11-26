-- schemas for gym management system
create schema if not exists api;

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


drop table if exists api.clients;
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
  plan_id uuid references api.plans(id) not null
);

create table if not exists
api.suscriptions (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  client_id uuid not null references api.clients(id),
  membership_id uuid not null references api.memberships(id),
  start_date date not null,
  end_date date not null,
  is_active boolean not null default true,
  price numeric not null check (price > 0),
  payment_amount numeric not null check (payment_amount > 0),
  balance numeric not null check (balance >= 0),
  check (end_date > start_date),
  check (start_date >= current_date),
  check (created_at <= now())
);

create table if not exists
api.payments (
    id uuid primary key default uuid_generate_v1(),
    client_membership_id uuid not null references api.clients_memberships(id),
    amount numeric not null check (amount > 0),
    created_at timestamptz default now(),
    date date not null,
    check (created_at <= now())
);

create table if not exists
api.products (
  id uuid primary key default uuid_generate_v1(),
  name text not null check (length(name) < 512),
  price numeric not null check (price > 0),
    stock integer not null check (stock >= 0),
    image bytea
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
api.sales (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz default now(),
  user_id uuid not null references api.users(id),
  total numeric not null check (total > 0),
  client_id uuid references api.clients(id) not null,
    check (created_at <= now())
);

create table if not exists
api.sale_items (
  id uuid primary key default uuid_generate_v1(),
  sale_id uuid not null references api.sales(id),
  product_id uuid not null references api.products(id),
  quantity integer not null check (quantity > 0),
  price numeric not null check (price > 0)
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

-- create table if not exists
-- api.workouts (
--   id uuid primary key default uuid_generate_v1(),
--   name text not null check (length(name) < 512),
--   description text not null check (length(description) < 512)
-- );

-- create table if not exists
-- api.exercises (
--   id uuid primary key default uuid_generate_v1(),
--   name text not null check (length(name) < 512),
--   description text not null check (length(description) < 512)
-- );

-- create table if not exists
-- api.workout_exercises (
--   id uuid primary key default uuid_generate_v1(),
--   workout_id uuid references api.workouts(id) not null,
--   exercise_id uuid references api.exercises(id) not null,
--   sets integer not null check (sets > 0),
--   reps integer not null check (reps > 0),
--   weight numeric not null check (weight > 0)
-- );



-- create table if not exists
-- api.workout_clients (
--   id uuid primary key default uuid_generate_v1(),
--   workout_id uuid references api.workouts(id) not null,
--   client_id uuid references api.clients(id) not null
-- );



