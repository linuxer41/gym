--
-- PostgreSQL database dump
--

-- Dumped from database version 14.0
-- Dumped by pg_dump version 14.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: api; Type: SCHEMA; Schema: -; Owner: linuxer
--

CREATE SCHEMA api;


ALTER SCHEMA api OWNER TO linuxer;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: linuxer
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO linuxer;

--
-- Name: functions; Type: SCHEMA; Schema: -; Owner: linuxer
--

CREATE SCHEMA functions;


ALTER SCHEMA functions OWNER TO linuxer;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: jwt_token; Type: TYPE; Schema: api; Owner: linuxer
--

CREATE TYPE api.jwt_token AS (
	token text
);


ALTER TYPE api.jwt_token OWNER TO linuxer;

--
-- Name: login(text, text); Type: FUNCTION; Schema: api; Owner: linuxer
--

CREATE FUNCTION api.login(email text, pass text) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  user_data json;
  jwt_token api.jwt_token;
  result json;
begin
  -- check email and password
  select auth.sign_user(login.email, login.pass) into user_data;
  if user_data->>'role' is null then
    raise invalid_password using message = 'invalid user or password';
  end if;
  -- create empty record
  -- select * from api.users where email = login.email into user_data;

  select sign(
      row_to_json(r), 'reallyreallyreallyreallyverysafe' -- current_setting('app.settings.jwt_secret')
    ) as token
    from (
      select user_data->>'role' as role, user_data->>'email' as email, user_data->>'id' as user_id,
         extract(epoch from now())::integer + 60*60*60 as exp
    ) r
  into jwt_token;
  -- select user
    select json_build_object(
    'user', user_data,
    'token', jwt_token.token
  ) into result;
  return result;
end;
$$;


ALTER FUNCTION api.login(email text, pass text) OWNER TO linuxer;

--
-- Name: new_admission(json); Type: FUNCTION; Schema: api; Owner: linuxer
--

CREATE FUNCTION api.new_admission(admission json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
    -- clients row type
    client_record api.clients;
    subscription_record api.subscriptions;
    payment_record api.payments;
    attendance_record api.attendances;
    referred_subscription api.subscriptions;
		referred_client_id text;
BEGIN
    -- raise null
    if admission is null or admission->'client' is null then
        raise null_value_not_allowed using message = 'client is required';
    end if;
    -- create client
    insert into api.clients (name, phone, address, dni, email)
    values (admission->'client'->>'name', admission->'client'->>'phone', admission->'client'->>'address', admission->'client'->>'dni', admission->'client'->>'email')
    returning * into client_record;
    -- create subscription if client was created and admission has subscription
    if client_record.id is not null and admission->'subscription' is not null then
        insert into api.subscriptions (client_id, membership_id, start_date, end_date, price, payment_amount, balance)
        values (client_record.id, (admission->'subscription'->>'membership_id')::uuid, (admission->'subscription'->>'start_date')::date, (admission->'subscription'->>'end_date')::date, (admission->'subscription'->>'price')::numeric, (admission->'subscription'->>'payment_amount')::numeric, (admission->'subscription'->>'balance')::numeric)
        returning * into subscription_record;
        -- create payment if subscription was created and admission has payment
        if subscription_record.id is not null and admission->'payment' is not null then
            insert into api.payments (subscription_id, amount)
            values (subscription_record.id, (admission->'payment'->>'amount')::numeric)
            returning * into payment_record;

            -- register first attendance
            insert into api.attendances (subscription_id, date, start_time)
            values (subscription_record.id, current_date, current_time)
            returning * into attendance_record;
        end if;
    end if;

    -- insert subscription and attendance to addmission->'referred_client_ids'
    if admission->'referred_client_ids' is not null then
        for referred_client_id in select json_array_elements_text(admission->'referred_client_ids') loop
            -- get referred client
            client_record := functions.get_client(referred_client_id::uuid);

            referred_subscription := functions.check_client_subscription(client_record.id);

            if referred_subscription.id is not null then
                raise exception using message = 'El cliente ya tiene una suscripción activa; cliente: ' || client_record.name;
            end if;
            -- insert subscription
            insert into api.subscriptions (client_id, membership_id, start_date, end_date, price, payment_amount, balance, referred_subscription_id)
            values (client_record.id, (admission->'subscription'->>'membership_id')::uuid, (admission->'subscription'->>'start_date')::date, (admission->'subscription'->>'end_date')::date, 0, 0, 0, subscription_record.id)
            returning * into referred_subscription;
            if referred_subscription.id is not null then
                -- register first attendance
                insert into api.attendances (subscription_id, date, start_time)
                values (referred_subscription.id, current_date, current_time)
                returning * into attendance_record;
            end if;
        end loop;
    end if;
    -- return client_id
    return json_build_object(
        'client', COALESCE(to_json(client_record), '{}'),
        'subscription', COALESCE(to_json(subscription_record), '{}'),
        'payment', COALESCE(to_json(payment_record), '{}'),
        'attendance', COALESCE(to_json(attendance_record), '{}')
    );
END;
$$;


ALTER FUNCTION api.new_admission(admission json) OWNER TO linuxer;

--
-- Name: new_attendance(uuid); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.new_attendance(client_id uuid) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
    -- clients row type
    client_record api.clients;
    subscription_record api.subscriptions;
    attendance_record api.attendances;
BEGIN
    -- raise null
    if new_attendance.client_id is null then
        raise null_value_not_allowed using message = 'client_id is required';
    end if;
    client_record := functions.get_client(new_attendance.client_id);
    subscription_record := functions.get_client_subscription(client_record.id);

    if not functions.check_attendance_permission(subscription_record.id, current_date) then
        raise exception using message = 'No tiene permiso para asistir';
    end if;
    -- create attendance
    insert into api.attendances (subscription_id, date, start_time)
    values (subscription_record.id, current_date, current_time)
    returning * into attendance_record;
    -- return client_id
    return json_build_object(
        'client', COALESCE(to_json(client_record), '{}'),
        'subscription', COALESCE(to_json(subscription_record), '{}'),
        'attendance', COALESCE(to_json(attendance_record), '{}')
    );
END;
$$;


ALTER FUNCTION api.new_attendance(client_id uuid) OWNER TO postgres;

--
-- Name: new_permission(uuid, integer, date); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.new_permission(client_id uuid, days integer DEFAULT 1, start_date date DEFAULT CURRENT_DATE) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
    -- clients row type
    client_record api.clients;
    subscription_record api.subscriptions;
    permission_record api.permissions;
BEGIN
    -- raise null
    if new_permission.client_id is null then
        raise null_value_not_allowed using message = 'client_id is required';
    end if;
    client_record := functions.get_client(new_permission.client_id);
    subscription_record := functions.get_client_subscription(client_record.id);
    -- loop for days
    for i in 0..(days -1) loop
        -- check subscription end_date is lower start_date + days integer
        if subscription_record.end_date < (start_date + i) then
            raise exception using message = 'La fecha de fin de la suscripción es menor a la fecha de inicio del permiso';
        end if;
        if not functions.check_attendance_permission(subscription_record.id, start_date + i) then
            raise exception using message = 'No tiene permiso para asistir';
        end if;
        -- create permission
        insert into api.permissions (subscription_id, date)
        values (subscription_record.id, start_date + i)
        returning * into permission_record;
        -- update subscription end_date
        update api.subscriptions
        set end_date = end_date + 1
        where id = subscription_record.id
        returning * into subscription_record;
    end loop;
    return json_build_object(
        'client', COALESCE(to_json(client_record), '{}'),
        'subscription', COALESCE(to_json(subscription_record), '{}'),
        'permission', COALESCE(to_json(permission_record), '{}')
    );
END;
$$;


ALTER FUNCTION api.new_permission(client_id uuid, days integer, start_date date) OWNER TO postgres;

--
-- Name: register(text, text, text, text, text, text, name); Type: FUNCTION; Schema: api; Owner: linuxer
--

CREATE FUNCTION api.register(address text DEFAULT NULL::text, dni text DEFAULT NULL::text, email text DEFAULT NULL::text, name text DEFAULT NULL::text, pass text DEFAULT NULL::text, phone text DEFAULT NULL::text, role name DEFAULT NULL::name) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  result json;
begin
  -- check if email is already registered
  if exists(select 1 from api.users where users.email = register.email) then
    raise unique_violation using message = 'email already registered';
  end if;
  -- insert user
  insert into api.users (email, pass, role, name, phone, address, dni)
  values (register.email, register.pass, register.role, register.name, register.phone, register.address, register.dni);
  -- login and return jwt_token
  select api.login(email, pass) into result;
  -- return user data and jwt_token
  return result;
end;
$$;


ALTER FUNCTION api.register(address text, dni text, email text, name text, pass text, phone text, role name) OWNER TO linuxer;

--
-- Name: check_role_exists(); Type: FUNCTION; Schema: auth; Owner: linuxer
--

CREATE FUNCTION auth.check_role_exists() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if not exists (select 1 from pg_roles as r where r.rolname = new.role) then
    raise foreign_key_violation using message =
      'unknown database role: ' || new.role;
    return null;
  end if;
  return new;
end
$$;


ALTER FUNCTION auth.check_role_exists() OWNER TO linuxer;

--
-- Name: check_user(); Type: FUNCTION; Schema: auth; Owner: linuxer
--

CREATE FUNCTION auth.check_user() RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
  if current_setting('request.jwt.claims', true)::json->>'email' =
     'disgruntled@mycompany.com' then
    raise insufficient_privilege
      using hint = 'No, estamos contigo';
  end if;
end
$$;


ALTER FUNCTION auth.check_user() OWNER TO linuxer;

--
-- Name: encrypt_pass(); Type: FUNCTION; Schema: auth; Owner: linuxer
--

CREATE FUNCTION auth.encrypt_pass() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if tg_op = 'INSERT' or new.pass <> old.pass then
    new.pass = crypt(new.pass, gen_salt('bf'));
  end if;
  return new;
end
$$;


ALTER FUNCTION auth.encrypt_pass() OWNER TO linuxer;

--
-- Name: sign_user(text, text); Type: FUNCTION; Schema: auth; Owner: linuxer
--

CREATE FUNCTION auth.sign_user(email text, pass text) RETURNS json
    LANGUAGE plpgsql
    AS $$
begin
  return (
  select to_json(users.*) from api.users
   where users.email = sign_user.email
     and users.pass = crypt(sign_user.pass, users.pass)
  );
end;
$$;


ALTER FUNCTION auth.sign_user(email text, pass text) OWNER TO linuxer;

--
-- Name: check_attendance_permission(uuid, date); Type: FUNCTION; Schema: functions; Owner: postgres
--

CREATE FUNCTION functions.check_attendance_permission(subscription_id uuid, date date DEFAULT CURRENT_DATE) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
    permission_record api.permissions;
    attendance_record api.attendances;
BEGIN
    permission_record := functions.get_date_subscription_permission(subscription_id, date);
    if permission_record.id is not null then
        raise exception using message = 'El cliente tiene una permiso para el día ' || date;
    end if;
    attendance_record := functions.get_date_subscription_attendance(subscription_id, date);
    if attendance_record.id is not null then
        raise exception using message = 'El cliente ya tiene una asistencia para el día ' || date;
    end if;
    return true;
END;
$$;


ALTER FUNCTION functions.check_attendance_permission(subscription_id uuid, date date) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: subscriptions; Type: TABLE; Schema: api; Owner: postgres
--

CREATE TABLE api.subscriptions (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    client_id uuid NOT NULL,
    membership_id uuid NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    price numeric NOT NULL,
    payment_amount numeric NOT NULL,
    balance numeric NOT NULL,
    referred_subscription_id uuid,
    CONSTRAINT subscriptions_balance_check CHECK ((balance >= (0)::numeric)),
    CONSTRAINT subscriptions_check CHECK ((end_date >= start_date)),
    CONSTRAINT subscriptions_created_at_check CHECK ((created_at <= now())),
    CONSTRAINT subscriptions_payment_amount_check CHECK (((payment_amount >= (0)::numeric) AND (payment_amount <= price))),
    CONSTRAINT subscriptions_price_check CHECK ((balance >= (0)::numeric))
);


ALTER TABLE api.subscriptions OWNER TO postgres;

--
-- Name: check_client_subscription(uuid); Type: FUNCTION; Schema: functions; Owner: postgres
--

CREATE FUNCTION functions.check_client_subscription(client_id uuid) RETURNS SETOF api.subscriptions
    LANGUAGE plpgsql
    AS $$
declare
    subscription_record api.subscriptions;
BEGIN
    select * from api.subscriptions where subscriptions.client_id = check_client_subscription.client_id and is_active = true
    and current_date between start_date and end_date order by start_date desc limit 1
    into subscription_record;
    return next subscription_record;
END;
$$;


ALTER FUNCTION functions.check_client_subscription(client_id uuid) OWNER TO postgres;

--
-- Name: generate_access_code(); Type: FUNCTION; Schema: public; Owner: linuxer
--

CREATE FUNCTION public.generate_access_code() RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
  new_access_code text;
  taken boolean;
BEGIN
    new_access_code := '';
    taken := true;
    while taken loop
        new_access_code := upper(substring(MD5(''||NOW()::TEXT||RANDOM()::TEXT), 1, 6));
        select count(*) > 0 from api.clients where clients.access_code = new_access_code into taken;
    end loop;
    return new_access_code;
    END;
$$;


ALTER FUNCTION public.generate_access_code() OWNER TO linuxer;

--
-- Name: clients; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.clients (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    name text NOT NULL,
    phone text,
    address text,
    dni text NOT NULL,
    access_code text DEFAULT public.generate_access_code() NOT NULL,
    email text,
    CONSTRAINT clients_access_code_check CHECK ((length(access_code) < 32)),
    CONSTRAINT clients_created_at_check CHECK ((created_at <= now())),
    CONSTRAINT clients_dni_check CHECK ((length(dni) < 32)),
    CONSTRAINT clients_name_check CHECK ((length(name) < 512))
);


ALTER TABLE api.clients OWNER TO linuxer;

--
-- Name: get_client(uuid); Type: FUNCTION; Schema: functions; Owner: linuxer
--

CREATE FUNCTION functions.get_client(client_id uuid) RETURNS api.clients
    LANGUAGE plpgsql
    AS $$
declare
    client_record api.clients;
BEGIN
    select * from api.clients where clients.id = get_client.client_id limit 1
    into client_record;
    if client_record.id is null then
        raise exception using message = 'El cliente no existe';
    end if;
    return client_record;
END;
$$;


ALTER FUNCTION functions.get_client(client_id uuid) OWNER TO linuxer;

--
-- Name: get_client_subscription(uuid); Type: FUNCTION; Schema: functions; Owner: postgres
--

CREATE FUNCTION functions.get_client_subscription(client_id uuid) RETURNS SETOF api.subscriptions
    LANGUAGE plpgsql
    AS $$
declare
    subscription_record api.subscriptions;
BEGIN
    select * from api.subscriptions where subscriptions.client_id = get_client_subscription.client_id and is_active = true
    and current_date between start_date and end_date order by start_date desc limit 1
    into subscription_record;
    if subscription_record.id is null then
        raise exception using message = 'El cliente no tiene una suscripción activa';
    end if;
    return next subscription_record;
END;
$$;


ALTER FUNCTION functions.get_client_subscription(client_id uuid) OWNER TO postgres;

--
-- Name: attendances; Type: TABLE; Schema: api; Owner: postgres
--

CREATE TABLE api.attendances (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    subscription_id uuid NOT NULL,
    date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone,
    CONSTRAINT attendances_check CHECK ((end_time >= start_time)),
    CONSTRAINT attendances_created_at_check CHECK ((created_at <= now()))
);


ALTER TABLE api.attendances OWNER TO postgres;

--
-- Name: get_date_subscription_attendance(uuid, date); Type: FUNCTION; Schema: functions; Owner: postgres
--

CREATE FUNCTION functions.get_date_subscription_attendance(subscription_id uuid, date date DEFAULT CURRENT_DATE) RETURNS SETOF api.attendances
    LANGUAGE plpgsql
    AS $$
declare
    attendance_record api.attendances;
BEGIN
    select * from api.attendances where attendances.subscription_id = get_date_subscription_attendance.subscription_id
    and attendances.date = get_date_subscription_attendance.date
    into attendance_record;
    return next attendance_record;
END;
$$;


ALTER FUNCTION functions.get_date_subscription_attendance(subscription_id uuid, date date) OWNER TO postgres;

--
-- Name: permissions; Type: TABLE; Schema: api; Owner: postgres
--

CREATE TABLE api.permissions (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    subscription_id uuid NOT NULL,
    date date NOT NULL,
    CONSTRAINT permissions_created_at_check CHECK ((created_at <= now()))
);


ALTER TABLE api.permissions OWNER TO postgres;

--
-- Name: get_date_subscription_permission(uuid, date); Type: FUNCTION; Schema: functions; Owner: postgres
--

CREATE FUNCTION functions.get_date_subscription_permission(subscription_id uuid, date date DEFAULT CURRENT_DATE) RETURNS SETOF api.permissions
    LANGUAGE plpgsql
    AS $$
declare
    permission_record api.permissions;
BEGIN
    select * from api.permissions where permissions.subscription_id = get_date_subscription_permission.subscription_id
    and permissions.date = get_date_subscription_permission.date
    into permission_record;
    return next permission_record;
END;
$$;


ALTER FUNCTION functions.get_date_subscription_permission(subscription_id uuid, date date) OWNER TO postgres;

--
-- Name: algorithm_sign(text, text, text); Type: FUNCTION; Schema: public; Owner: linuxer
--

CREATE FUNCTION public.algorithm_sign(signables text, secret text, algorithm text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
WITH
  alg AS (
    SELECT CASE
      WHEN algorithm = 'HS256' THEN 'sha256'
      WHEN algorithm = 'HS384' THEN 'sha384'
      WHEN algorithm = 'HS512' THEN 'sha512'
      ELSE '' END AS id)  -- hmac throws error
SELECT url_encode(hmac(signables, secret, alg.id)) FROM alg;
$$;


ALTER FUNCTION public.algorithm_sign(signables text, secret text, algorithm text) OWNER TO linuxer;

--
-- Name: sign(json, text, text); Type: FUNCTION; Schema: public; Owner: linuxer
--

CREATE FUNCTION public.sign(payload json, secret text, algorithm text DEFAULT 'HS256'::text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
WITH
  header AS (
    SELECT url_encode(convert_to('{"alg":"' || algorithm || '","typ":"JWT"}', 'utf8')) AS data
    ),
  payload AS (
    SELECT url_encode(convert_to(payload::text, 'utf8')) AS data
    ),
  signables AS (
    SELECT header.data || '.' || payload.data AS data FROM header, payload
    )
SELECT
    signables.data || '.' ||
    algorithm_sign(signables.data, secret, algorithm) FROM signables;
$$;


ALTER FUNCTION public.sign(payload json, secret text, algorithm text) OWNER TO linuxer;

--
-- Name: try_cast_double(text); Type: FUNCTION; Schema: public; Owner: linuxer
--

CREATE FUNCTION public.try_cast_double(inp text) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE
    AS $$
  BEGIN
    BEGIN
      RETURN inp::double precision;
    EXCEPTION
      WHEN OTHERS THEN RETURN NULL;
    END;
  END;
$$;


ALTER FUNCTION public.try_cast_double(inp text) OWNER TO linuxer;

--
-- Name: url_decode(text); Type: FUNCTION; Schema: public; Owner: linuxer
--

CREATE FUNCTION public.url_decode(data text) RETURNS bytea
    LANGUAGE sql IMMUTABLE
    AS $$
WITH t AS (SELECT translate(data, '-_', '+/') AS trans),
     rem AS (SELECT length(t.trans) % 4 AS remainder FROM t) -- compute padding size
    SELECT decode(
        t.trans ||
        CASE WHEN rem.remainder > 0
           THEN repeat('=', (4 - rem.remainder))
           ELSE '' END,
    'base64') FROM t, rem;
$$;


ALTER FUNCTION public.url_decode(data text) OWNER TO linuxer;

--
-- Name: url_encode(bytea); Type: FUNCTION; Schema: public; Owner: linuxer
--

CREATE FUNCTION public.url_encode(data bytea) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT translate(encode(data, 'base64'), E'+/=\n', '-_');
$$;


ALTER FUNCTION public.url_encode(data bytea) OWNER TO linuxer;

--
-- Name: verify(text, text, text); Type: FUNCTION; Schema: public; Owner: linuxer
--

CREATE FUNCTION public.verify(token text, secret text, algorithm text DEFAULT 'HS256'::text) RETURNS TABLE(header json, payload json, valid boolean)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT
    jwt.header AS header,
    jwt.payload AS payload,
    jwt.signature_ok AND tstzrange(
      to_timestamp(try_cast_double(jwt.payload->>'nbf')),
      to_timestamp(try_cast_double(jwt.payload->>'exp'))
    ) @> CURRENT_TIMESTAMP AS valid
  FROM (
    SELECT
      convert_from(url_decode(r[1]), 'utf8')::json AS header,
      convert_from(url_decode(r[2]), 'utf8')::json AS payload,
      r[3] = algorithm_sign(r[1] || '.' || r[2], secret, algorithm) AS signature_ok
    FROM regexp_split_to_array(token, '\.') r
  ) jwt
$$;


ALTER FUNCTION public.verify(token text, secret text, algorithm text) OWNER TO linuxer;

--
-- Name: cash_register; Type: TABLE; Schema: api; Owner: postgres
--

CREATE TABLE api.cash_register (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    amount numeric NOT NULL,
    started_at timestamp with time zone NOT NULL,
    ended_at timestamp with time zone,
    CONSTRAINT cash_register_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT cash_register_check CHECK ((ended_at >= started_at)),
    CONSTRAINT cash_register_created_at_check CHECK ((created_at <= now()))
);


ALTER TABLE api.cash_register OWNER TO postgres;

--
-- Name: memberships; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.memberships (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    name text NOT NULL,
    price numeric NOT NULL,
    clients_limit integer NOT NULL,
    duration integer NOT NULL,
    plan_id uuid NOT NULL,
    CONSTRAINT memberships_clients_limit_check CHECK ((clients_limit > 0)),
    CONSTRAINT memberships_duration_check CHECK ((duration > 0)),
    CONSTRAINT memberships_name_check CHECK ((length(name) < 512)),
    CONSTRAINT memberships_price_check CHECK ((price > (0)::numeric))
);


ALTER TABLE api.memberships OWNER TO linuxer;

--
-- Name: payments; Type: TABLE; Schema: api; Owner: postgres
--

CREATE TABLE api.payments (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    subscription_id uuid NOT NULL,
    amount numeric NOT NULL,
    CONSTRAINT payments_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT payments_created_at_check CHECK ((created_at <= now()))
);


ALTER TABLE api.payments OWNER TO postgres;

--
-- Name: plans; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.plans (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE api.plans OWNER TO linuxer;

--
-- Name: client_subscriptions; Type: VIEW; Schema: api; Owner: postgres
--

CREATE VIEW api.client_subscriptions AS
 SELECT subscriptions.id,
    subscriptions.created_at,
    subscriptions.client_id,
    subscriptions.membership_id,
    subscriptions.start_date,
    subscriptions.end_date,
    subscriptions.is_active,
    subscriptions.price,
    subscriptions.payment_amount,
    subscriptions.balance,
    COALESCE(to_json(memberships.*), '{}'::json) AS membership,
    COALESCE(to_json(plans.*), '{}'::json) AS plan,
    COALESCE(payments.payments, '[]'::json) AS payments,
    COALESCE(payments.payments_count, (0)::bigint) AS payments_count,
    COALESCE(payments.total_paid, (0)::numeric) AS total_paid,
    COALESCE(attendances.attendances, '[]'::json) AS attendances,
    COALESCE(attendances.attendances_count, (0)::bigint) AS attendances_count,
    COALESCE(permissions.permissions, '[]'::json) AS permissions,
    COALESCE(permissions.permissions_count, (0)::bigint) AS permissions_count,
    left_days.left_days,
    total_days.total_days,
    COALESCE((total_days.total_days - left_days.left_days), (0)::bigint) AS used_days,
    COALESCE((CURRENT_DATE > subscriptions.end_date), false) AS expired
   FROM (((((api.subscriptions
     JOIN api.memberships ON ((subscriptions.membership_id = memberships.id)))
     JOIN api.plans ON ((memberships.plan_id = plans.id)))
     LEFT JOIN ( SELECT payments_1.subscription_id,
            COALESCE(json_agg(to_json(payments_1.*)), '[]'::json) AS payments,
            count(payments_1.*) AS payments_count,
            sum(payments_1.amount) AS total_paid
           FROM api.payments payments_1
          GROUP BY payments_1.subscription_id) payments ON ((subscriptions.id = payments.subscription_id)))
     LEFT JOIN ( SELECT attendances_1.subscription_id,
            COALESCE(json_agg(to_json(attendances_1.*)), '[]'::json) AS attendances,
            count(attendances_1.*) AS attendances_count
           FROM api.attendances attendances_1
          GROUP BY attendances_1.subscription_id) attendances ON ((subscriptions.id = attendances.subscription_id)))
     LEFT JOIN ( SELECT permissions_1.subscription_id,
            COALESCE(json_agg(to_json(permissions_1.*)), '[]'::json) AS permissions,
            count(permissions_1.*) AS permissions_count
           FROM api.permissions permissions_1
          GROUP BY permissions_1.subscription_id) permissions ON ((subscriptions.id = permissions.subscription_id))),
    LATERAL ( SELECT
                CASE
                    WHEN (subscriptions.start_date = subscriptions.end_date) THEN 1
                    ELSE (subscriptions.end_date - subscriptions.start_date)
                END AS total_days) total_days,
    LATERAL ( SELECT (total_days.total_days - (COALESCE(attendances.attendances_count, (0)::bigint) + COALESCE(permissions.permissions_count, (0)::bigint))) AS left_days) left_days;


ALTER TABLE api.client_subscriptions OWNER TO postgres;

--
-- Name: expenses; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.expenses (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    user_id uuid NOT NULL,
    amount numeric NOT NULL,
    description text NOT NULL,
    CONSTRAINT expenses_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT expenses_description_check CHECK ((length(description) < 512))
);


ALTER TABLE api.expenses OWNER TO linuxer;

--
-- Name: incomes; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.incomes (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    user_id uuid NOT NULL,
    amount numeric NOT NULL,
    description text NOT NULL,
    CONSTRAINT incomes_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT incomes_created_at_check CHECK ((created_at <= now())),
    CONSTRAINT incomes_description_check CHECK ((length(description) < 512))
);


ALTER TABLE api.incomes OWNER TO linuxer;

--
-- Name: products; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.products (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    name text NOT NULL,
    price numeric NOT NULL,
    stock integer NOT NULL,
    image bytea,
    CONSTRAINT products_name_check CHECK ((length(name) < 512)),
    CONSTRAINT products_price_check CHECK ((price > (0)::numeric)),
    CONSTRAINT products_stock_check CHECK ((stock >= 0))
);


ALTER TABLE api.products OWNER TO linuxer;

--
-- Name: sale_items; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.sale_items (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    sale_id uuid NOT NULL,
    product_id uuid NOT NULL,
    quantity integer NOT NULL,
    price numeric NOT NULL,
    CONSTRAINT sale_items_price_check CHECK ((price > (0)::numeric)),
    CONSTRAINT sale_items_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE api.sale_items OWNER TO linuxer;

--
-- Name: sales; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.sales (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    user_id uuid NOT NULL,
    total numeric NOT NULL,
    client_id uuid NOT NULL,
    CONSTRAINT sales_created_at_check CHECK ((created_at <= now())),
    CONSTRAINT sales_total_check CHECK ((total > (0)::numeric))
);


ALTER TABLE api.sales OWNER TO linuxer;

--
-- Name: subscribers; Type: VIEW; Schema: api; Owner: postgres
--

CREATE VIEW api.subscribers AS
 SELECT clients.id,
    clients.created_at,
    clients.name,
    clients.phone,
    clients.address,
    clients.dni,
    clients.access_code,
    clients.email,
        CASE
            WHEN (active_subscription.active_subscription IS NOT NULL) THEN true
            ELSE false
        END AS has_active_subscription,
        CASE
            WHEN (subscriptions.subscriptions IS NOT NULL) THEN true
            ELSE false
        END AS has_subscriptions,
    subscriptions.client_id,
    subscriptions.subscriptions,
    subscriptions.subscriptions_count,
    subscriptions.balance,
    subscriptions.payment_amount,
    subscriptions.price,
    subscriptions.debt,
    subscriptions.in_debt,
    active_subscription.active_subscription
   FROM ((api.clients
     LEFT JOIN ( SELECT client_subscriptions.client_id,
            json_agg(to_json(client_subscriptions.*)) AS subscriptions,
            count(client_subscriptions.*) AS subscriptions_count,
            sum(client_subscriptions.balance) AS balance,
            sum(client_subscriptions.payment_amount) AS payment_amount,
            sum(client_subscriptions.price) AS price,
            (sum(client_subscriptions.payment_amount) - sum(client_subscriptions.price)) AS debt,
            ((sum(client_subscriptions.payment_amount) - sum(client_subscriptions.price)) > (0)::numeric) AS in_debt
           FROM api.client_subscriptions
          GROUP BY client_subscriptions.client_id) subscriptions ON ((clients.id = subscriptions.client_id)))
     LEFT JOIN ( SELECT (array_agg(to_json(client_subscriptions.*)))[1] AS active_subscription,
            client_subscriptions.client_id
           FROM api.client_subscriptions
          WHERE ((NOT client_subscriptions.expired) AND client_subscriptions.is_active)
          GROUP BY client_subscriptions.client_id) active_subscription ON ((clients.id = active_subscription.client_id)));


ALTER TABLE api.subscribers OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.users (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    email text NOT NULL,
    pass text NOT NULL,
    phone text,
    address text,
    dni text,
    role name NOT NULL,
    CONSTRAINT users_created_at_check CHECK ((created_at <= now())),
    CONSTRAINT users_email_check CHECK ((email ~* '^.+@.+\..+$'::text)),
    CONSTRAINT users_pass_check CHECK ((length(pass) < 512)),
    CONSTRAINT users_role_check CHECK ((length((role)::text) < 512))
);


ALTER TABLE api.users OWNER TO linuxer;

--
-- Data for Name: attendances; Type: TABLE DATA; Schema: api; Owner: postgres
--

COPY api.attendances (id, created_at, subscription_id, date, start_time, end_time) FROM stdin;
6c3423d4-6ed7-11ed-972d-48ba4e57ef6c	2022-11-28 00:45:03.070828-04	31ce2213-6ed7-11ed-972b-48ba4e57ef6c	2022-11-28	00:45:03.070828	\N
01e01b72-6ed8-11ed-9731-48ba4e57ef6c	2022-11-28 00:49:14.177882-04	c9267223-6ed7-11ed-972f-48ba4e57ef6c	2022-11-28	00:49:14.177882	\N
886576d2-6ede-11ed-9738-48ba4e57ef6c	2022-11-28 01:35:56.849304-04	71a88fba-6ede-11ed-9733-48ba4e57ef6c	2022-11-28	01:35:56.849304	\N
9c989d1e-6ede-11ed-9739-48ba4e57ef6c	2022-11-28 01:36:30.737899-04	78e358a1-6ede-11ed-9736-48ba4e57ef6c	2022-11-28	01:36:30.737899	\N
f3e434e0-6ee1-11ed-973e-48ba4e57ef6c	2022-11-28 02:00:25.685973-04	e36f410e-6ee1-11ed-973c-48ba4e57ef6c	2022-11-28	02:00:25.685973	\N
6efce3f3-6ee2-11ed-9742-48ba4e57ef6c	2022-11-28 02:03:52.204463-04	6efcbcec-6ee2-11ed-9740-48ba4e57ef6c	2022-11-28	02:03:52.204463	\N
01a2f67d-6ee7-11ed-9746-48ba4e57ef6c	2022-11-28 02:36:36.229558-04	01a2f67b-6ee7-11ed-9744-48ba4e57ef6c	2022-11-28	02:36:36.229558	\N
07268699-6ee7-11ed-974a-48ba4e57ef6c	2022-11-28 02:36:45.479702-04	07265fb1-6ee7-11ed-9748-48ba4e57ef6c	2022-11-28	02:36:45.479702	\N
e942cd7c-6eea-11ed-9751-48ba4e57ef6c	2022-11-28 03:04:33.321139-04	e942a681-6eea-11ed-974f-48ba4e57ef6c	2022-11-28	03:04:33.321139	\N
1472f6fd-6eeb-11ed-9755-48ba4e57ef6c	2022-11-28 03:05:45.778587-04	1472cfed-6eeb-11ed-9753-48ba4e57ef6c	2022-11-28	03:05:45.778587	\N
5d2dea0b-6eeb-11ed-9759-48ba4e57ef6c	2022-11-28 03:07:47.799116-04	5d2dc30f-6eeb-11ed-9757-48ba4e57ef6c	2022-11-28	03:07:47.799116	\N
45796ca1-6eec-11ed-9761-48ba4e57ef6c	2022-11-28 03:14:17.526535-04	45796c9f-6eec-11ed-975f-48ba4e57ef6c	2022-11-28	03:14:17.526535	\N
8880642d-6eec-11ed-9765-48ba4e57ef6c	2022-11-28 03:16:09.98567-04	8880642b-6eec-11ed-9763-48ba4e57ef6c	2022-11-28	03:16:09.98567	\N
4e2e9101-6eee-11ed-9776-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	4e2e431c-6eee-11ed-9774-48ba4e57ef6c	2022-11-28	03:28:51.126515	\N
4e2eb7f3-6eee-11ed-9778-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	4e2eb7f2-6eee-11ed-9777-48ba4e57ef6c	2022-11-28	03:28:51.126515	\N
4e2eb7f5-6eee-11ed-977a-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	4e2eb7f4-6eee-11ed-9779-48ba4e57ef6c	2022-11-28	03:28:51.126515	\N
4e2edeef-6eee-11ed-977c-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	4e2edeee-6eee-11ed-977b-48ba4e57ef6c	2022-11-28	03:28:51.126515	\N
0f53f73c-6eef-11ed-9782-48ba4e57ef6c	2022-11-28 03:34:15.174074-04	0f53f73a-6eef-11ed-9780-48ba4e57ef6c	2022-11-28	03:34:15.174074	\N
0f541e55-6eef-11ed-9784-48ba4e57ef6c	2022-11-28 03:34:15.174074-04	0f541e54-6eef-11ed-9783-48ba4e57ef6c	2022-11-28	03:34:15.174074	\N
0f541e57-6eef-11ed-9786-48ba4e57ef6c	2022-11-28 03:34:15.174074-04	0f541e56-6eef-11ed-9785-48ba4e57ef6c	2022-11-28	03:34:15.174074	\N
d3aa715b-74e8-11ed-a78d-48ba4e57ef6c	2022-12-05 18:04:45.017782-04	d3a97048-74e8-11ed-a78b-48ba4e57ef6c	2022-12-05	18:04:45.017782	\N
66d63c70-74e9-11ed-941d-48ba4e57ef6c	2022-12-05 18:08:51.978582-04	4e2e431c-6eee-11ed-9774-48ba4e57ef6c	2022-12-05	18:08:51.978582	\N
95340cf0-74e9-11ed-a6ec-48ba4e57ef6c	2022-12-05 18:10:09.761713-04	1472cfed-6eeb-11ed-9753-48ba4e57ef6c	2022-12-05	18:10:09.761713	\N
9f628a4e-74e9-11ed-941e-48ba4e57ef6c	2022-12-05 18:10:26.856993-04	5d2dc30f-6eeb-11ed-9757-48ba4e57ef6c	2022-12-05	18:10:26.856993	\N
\.


--
-- Data for Name: cash_register; Type: TABLE DATA; Schema: api; Owner: postgres
--

COPY api.cash_register (id, user_id, created_at, amount, started_at, ended_at) FROM stdin;
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.clients (id, created_at, name, phone, address, dni, access_code, email) FROM stdin;
a9e5b6c4-6e83-11ed-ba7b-48ba4e57ef6c	2022-11-27 14:45:28.850201-04	francisco ochoa			71307408	B4F3F6	
b335bc42-6e83-11ed-ba7e-48ba4e57ef6c	2022-11-27 14:45:44.475956-04	francisco ochoa			71307408013	36949B	
3d8841a0-6ea0-11ed-ba81-48ba4e57ef6c	2022-11-27 18:10:02.450295-04	francisco ochoa			747444554	8A97CC	
51bef776-6ea6-11ed-ba84-48ba4e57ef6c	2022-11-27 18:53:33.344519-04	sadsad			safdasf	F7ACD9	
d30ec820-6eb9-11ed-bcba-48ba4e57ef6c	2022-11-27 21:13:10.730679-04	jose manuel pando	+59171307408	av. marcelo quiroga santa cruz	748564	F54A9C	linuxer41@gmail.com
bd081c7c-6ec1-11ed-bcbe-48ba4e57ef6c	2022-11-27 22:09:49.751614-04	jose			sadasdsad	BD0312	
d4b0bff0-6ec1-11ed-bcc2-48ba4e57ef6c	2022-11-27 22:10:29.444017-04	jose1			gfhggfhg	6EA515	
7ae8ddc0-6ec8-11ed-8886-48ba4e57ef6c	2022-11-27 22:58:05.27951-04	francisco ochoa			54556456	0137DA	
a84e57fe-6ec8-11ed-8887-48ba4e57ef6c	2022-11-27 22:59:21.456881-04	francisco ochoa			dsgffdgfg	7D95B6	
0abb6560-6ecb-11ed-bcc5-48ba4e57ef6c	2022-11-27 23:16:25.578969-04	francisco ochoa			fdbfhdf	15C38C	
b2130c9c-6ecf-11ed-888c-48ba4e57ef6c	2022-11-27 23:49:44.321403-04	francisco ochoa			cdsfsdfdsf	36E01E	
de0d0776-6ed4-11ed-971f-48ba4e57ef6c	2022-11-28 00:26:45.58668-04	jose			545465	1A0CEC	
31ce2212-6ed7-11ed-972a-48ba4e57ef6c	2022-11-28 00:43:25.095471-04	francisco ochoa			francisco ochoa	170F68	
c9267222-6ed7-11ed-972e-48ba4e57ef6c	2022-11-28 00:47:39.010977-04	francisco ochoa			71307408dc	23D83A	
71a868b4-6ede-11ed-9732-48ba4e57ef6c	2022-11-28 01:35:18.700291-04	perez			sd	D7C027	
78e358a0-6ede-11ed-9735-48ba4e57ef6c	2022-11-28 01:35:30.830465-04	perez			sdgfdg	D60994	
e36f1a26-6ee1-11ed-973b-48ba4e57ef6c	2022-11-28 01:59:58.074704-04	perex			7845454	4034C1	
6efc95dc-6ee2-11ed-973f-48ba4e57ef6c	2022-11-28 02:03:52.204463-04	perex			71307408a	A77BB8	
01a2f67a-6ee7-11ed-9743-48ba4e57ef6c	2022-11-28 02:36:36.229558-04	francisco ochoa			dsfsdgg	3A3BAE	
07265fb0-6ee7-11ed-9747-48ba4e57ef6c	2022-11-28 02:36:45.479702-04	francisco ochoa			dsfsdggfsd	9A0253	
ba3d354e-6eea-11ed-974b-48ba4e57ef6c	2022-11-28 03:03:14.4327-04	rex1			545a4sdsad	F1CAE2	
c0279044-6eea-11ed-974c-48ba4e57ef6c	2022-11-28 03:03:24.356077-04	rex2			545a4sdsadb	D8AE04	
c4a60ec0-6eea-11ed-974d-48ba4e57ef6c	2022-11-28 03:03:31.896319-04	rex3			545a4sdsadbd	6BA198	
e942a680-6eea-11ed-974e-48ba4e57ef6c	2022-11-28 03:04:33.321139-04	rex4			545a4sdsadbdsadas	0B7B35	
1472cfec-6eeb-11ed-9752-48ba4e57ef6c	2022-11-28 03:05:45.778587-04	rex5			asdsafdsf	D1A5FE	
5d2dc30e-6eeb-11ed-9756-48ba4e57ef6c	2022-11-28 03:07:47.799116-04	rex6			asdfasgag	818C87	
45796c9e-6eec-11ed-975e-48ba4e57ef6c	2022-11-28 03:14:17.526535-04	rex7			sdsafc	CBF9C5	
8880642a-6eec-11ed-9762-48ba4e57ef6c	2022-11-28 03:16:09.98567-04	rex7			sdsafchj	49CF24	
4e2e1c3e-6eee-11ed-9773-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	rex8			sdsafchjsd	4A70A7	
be685af0-6eee-11ed-977d-48ba4e57ef6c	2022-11-28 03:31:59.413606-04	jura1			asds cv	4FF0C7	
c8c47ff6-6eee-11ed-977e-48ba4e57ef6c	2022-11-28 03:32:16.793196-04	juda2			safsvfhyytj	DBF55B	
0f53cf08-6eef-11ed-977f-48ba4e57ef6c	2022-11-28 03:34:15.174074-04	jura3			47df5d4sf	0C755B	
d3a577cc-74e8-11ed-a78a-48ba4e57ef6c	2022-12-05 18:04:45.017782-04	francisco ochaoi	7474483		7474483013	5CBF3C	linxer41
\.


--
-- Data for Name: expenses; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.expenses (id, created_at, user_id, amount, description) FROM stdin;
\.


--
-- Data for Name: incomes; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.incomes (id, created_at, user_id, amount, description) FROM stdin;
\.


--
-- Data for Name: memberships; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.memberships (id, name, price, clients_limit, duration, plan_id) FROM stdin;
7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	Sesion	15	1	1	67d32f50-6e83-11ed-ba76-48ba4e57ef6c
8f0655c0-6e83-11ed-ba79-48ba4e57ef6c	Mensual	150	1	30	67d32f50-6e83-11ed-ba76-48ba4e57ef6c
9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	Familiar	300	3	30	67d32f50-6e83-11ed-ba76-48ba4e57ef6c
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: api; Owner: postgres
--

COPY api.payments (id, created_at, subscription_id, amount) FROM stdin;
31ce6ff6-6ed7-11ed-972c-48ba4e57ef6c	2022-11-28 00:43:25.095471-04	31ce2213-6ed7-11ed-972b-48ba4e57ef6c	15
c9269900-6ed7-11ed-9730-48ba4e57ef6c	2022-11-28 00:47:39.010977-04	c9267223-6ed7-11ed-972f-48ba4e57ef6c	300
71a88fbb-6ede-11ed-9734-48ba4e57ef6c	2022-11-28 01:35:18.700291-04	71a88fba-6ede-11ed-9733-48ba4e57ef6c	15
78e358a2-6ede-11ed-9737-48ba4e57ef6c	2022-11-28 01:35:30.830465-04	78e358a1-6ede-11ed-9736-48ba4e57ef6c	150
e36f6832-6ee1-11ed-973d-48ba4e57ef6c	2022-11-28 01:59:58.074704-04	e36f410e-6ee1-11ed-973c-48ba4e57ef6c	15
6efce3f2-6ee2-11ed-9741-48ba4e57ef6c	2022-11-28 02:03:52.204463-04	6efcbcec-6ee2-11ed-9740-48ba4e57ef6c	15
01a2f67c-6ee7-11ed-9745-48ba4e57ef6c	2022-11-28 02:36:36.229558-04	01a2f67b-6ee7-11ed-9744-48ba4e57ef6c	15
07268698-6ee7-11ed-9749-48ba4e57ef6c	2022-11-28 02:36:45.479702-04	07265fb1-6ee7-11ed-9748-48ba4e57ef6c	15
e942a682-6eea-11ed-9750-48ba4e57ef6c	2022-11-28 03:04:33.321139-04	e942a681-6eea-11ed-974f-48ba4e57ef6c	300
1472f6fc-6eeb-11ed-9754-48ba4e57ef6c	2022-11-28 03:05:45.778587-04	1472cfed-6eeb-11ed-9753-48ba4e57ef6c	300
5d2dea0a-6eeb-11ed-9758-48ba4e57ef6c	2022-11-28 03:07:47.799116-04	5d2dc30f-6eeb-11ed-9757-48ba4e57ef6c	300
45796ca0-6eec-11ed-9760-48ba4e57ef6c	2022-11-28 03:14:17.526535-04	45796c9f-6eec-11ed-975f-48ba4e57ef6c	300
8880642c-6eec-11ed-9764-48ba4e57ef6c	2022-11-28 03:16:09.98567-04	8880642b-6eec-11ed-9763-48ba4e57ef6c	300
4e2e9100-6eee-11ed-9775-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	4e2e431c-6eee-11ed-9774-48ba4e57ef6c	300
0f53f73b-6eef-11ed-9781-48ba4e57ef6c	2022-11-28 03:34:15.174074-04	0f53f73a-6eef-11ed-9780-48ba4e57ef6c	300
d3aa715a-74e8-11ed-a78c-48ba4e57ef6c	2022-12-05 18:04:45.017782-04	d3a97048-74e8-11ed-a78b-48ba4e57ef6c	15
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: api; Owner: postgres
--

COPY api.permissions (id, created_at, subscription_id, date) FROM stdin;
f3c4a636-6edf-11ed-973a-48ba4e57ef6c	2022-11-28 01:46:06.489177-04	71a88fba-6ede-11ed-9733-48ba4e57ef6c	2022-11-28
\.


--
-- Data for Name: plans; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.plans (id, name, description) FROM stdin;
67d32f50-6e83-11ed-ba76-48ba4e57ef6c	Básico	maquinas + cardio
775bcf0e-6e83-11ed-ba77-48ba4e57ef6c	Completo	todo
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.products (id, name, price, stock, image) FROM stdin;
\.


--
-- Data for Name: sale_items; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.sale_items (id, sale_id, product_id, quantity, price) FROM stdin;
\.


--
-- Data for Name: sales; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.sales (id, created_at, user_id, total, client_id) FROM stdin;
\.


--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: api; Owner: postgres
--

COPY api.subscriptions (id, created_at, client_id, membership_id, start_date, end_date, is_active, price, payment_amount, balance, referred_subscription_id) FROM stdin;
31ce2213-6ed7-11ed-972b-48ba4e57ef6c	2022-11-28 00:43:25.095471-04	31ce2212-6ed7-11ed-972a-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-11-28	2022-11-28	t	15	15	0	\N
c9267223-6ed7-11ed-972f-48ba4e57ef6c	2022-11-28 00:47:39.010977-04	c9267222-6ed7-11ed-972e-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-27	t	300	300	0	\N
78e358a1-6ede-11ed-9736-48ba4e57ef6c	2022-11-28 01:35:30.830465-04	78e358a0-6ede-11ed-9735-48ba4e57ef6c	8f0655c0-6e83-11ed-ba79-48ba4e57ef6c	2022-11-28	2022-12-28	t	150	150	0	\N
71a88fba-6ede-11ed-9733-48ba4e57ef6c	2022-11-28 01:35:18.700291-04	71a868b4-6ede-11ed-9732-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-11-28	2022-11-29	t	15	15	0	\N
e36f410e-6ee1-11ed-973c-48ba4e57ef6c	2022-11-28 01:59:58.074704-04	e36f1a26-6ee1-11ed-973b-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-11-28	2022-11-28	t	15	15	0	\N
6efcbcec-6ee2-11ed-9740-48ba4e57ef6c	2022-11-28 02:03:52.204463-04	6efc95dc-6ee2-11ed-973f-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-11-28	2022-11-28	t	15	15	0	\N
01a2f67b-6ee7-11ed-9744-48ba4e57ef6c	2022-11-28 02:36:36.229558-04	01a2f67a-6ee7-11ed-9743-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-11-28	2022-11-28	t	15	15	0	\N
07265fb1-6ee7-11ed-9748-48ba4e57ef6c	2022-11-28 02:36:45.479702-04	07265fb0-6ee7-11ed-9747-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-11-28	2022-11-28	t	15	15	0	\N
e942a681-6eea-11ed-974f-48ba4e57ef6c	2022-11-28 03:04:33.321139-04	e942a680-6eea-11ed-974e-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	300	300	0	\N
1472cfed-6eeb-11ed-9753-48ba4e57ef6c	2022-11-28 03:05:45.778587-04	1472cfec-6eeb-11ed-9752-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	300	300	0	\N
5d2dc30f-6eeb-11ed-9757-48ba4e57ef6c	2022-11-28 03:07:47.799116-04	5d2dc30e-6eeb-11ed-9756-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	300	300	0	\N
45796c9f-6eec-11ed-975f-48ba4e57ef6c	2022-11-28 03:14:17.526535-04	45796c9e-6eec-11ed-975e-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	300	300	0	\N
8880642b-6eec-11ed-9763-48ba4e57ef6c	2022-11-28 03:16:09.98567-04	8880642a-6eec-11ed-9762-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	300	300	0	\N
4e2e431c-6eee-11ed-9774-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	4e2e1c3e-6eee-11ed-9773-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	300	300	0	\N
4e2eb7f2-6eee-11ed-9777-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	c4a60ec0-6eea-11ed-974d-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	0	0	0	4e2e431c-6eee-11ed-9774-48ba4e57ef6c
4e2eb7f4-6eee-11ed-9779-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	c0279044-6eea-11ed-974c-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	0	0	0	4e2e431c-6eee-11ed-9774-48ba4e57ef6c
4e2edeee-6eee-11ed-977b-48ba4e57ef6c	2022-11-28 03:28:51.126515-04	ba3d354e-6eea-11ed-974b-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	0	0	0	4e2e431c-6eee-11ed-9774-48ba4e57ef6c
0f53f73a-6eef-11ed-9780-48ba4e57ef6c	2022-11-28 03:34:15.174074-04	0f53cf08-6eef-11ed-977f-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	300	300	0	\N
0f541e54-6eef-11ed-9783-48ba4e57ef6c	2022-11-28 03:34:15.174074-04	be685af0-6eee-11ed-977d-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	0	0	0	0f53f73a-6eef-11ed-9780-48ba4e57ef6c
0f541e56-6eef-11ed-9785-48ba4e57ef6c	2022-11-28 03:34:15.174074-04	c8c47ff6-6eee-11ed-977e-48ba4e57ef6c	9a2a8638-6e83-11ed-ba7a-48ba4e57ef6c	2022-11-28	2022-12-28	t	0	0	0	0f53f73a-6eef-11ed-9780-48ba4e57ef6c
d3a97048-74e8-11ed-a78b-48ba4e57ef6c	2022-12-05 18:04:45.017782-04	d3a577cc-74e8-11ed-a78a-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-12-05	2022-12-05	t	15	15	0	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.users (id, name, created_at, email, pass, phone, address, dni, role) FROM stdin;
ef7fa100-6e82-11ed-ba74-48ba4e57ef6c	Francisco ochoa 	2022-11-27 14:40:16.116202-04	linuxer@gmail.com	$2a$06$y2O2bYTXd5PO.KEUOEa4eOEZmWThUXvHkAsZh7D/V/l4CTzzdZIme	71307408	sucre	7474483	api_user
0b07510c-6e83-11ed-ba75-48ba4e57ef6c	Francisco ochoa 	2022-11-27 14:41:02.314828-04	linuxer41@gmail.com	$2a$06$mmgzf9sC5tXMBoGKhiXMo.otXGlFuTkXkWuirak1PYu.cyBHVKnU.	71307408	sucre	7474483	api_user
\.


--
-- Name: attendances attendances_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.attendances
    ADD CONSTRAINT attendances_pkey PRIMARY KEY (id);


--
-- Name: cash_register cash_register_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.cash_register
    ADD CONSTRAINT cash_register_pkey PRIMARY KEY (id);


--
-- Name: clients clients_access_code_key; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.clients
    ADD CONSTRAINT clients_access_code_key UNIQUE (access_code);


--
-- Name: clients clients_dni_key; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.clients
    ADD CONSTRAINT clients_dni_key UNIQUE (dni);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: incomes incomes_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.incomes
    ADD CONSTRAINT incomes_pkey PRIMARY KEY (id);


--
-- Name: memberships memberships_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: sale_items sale_items_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.sale_items
    ADD CONSTRAINT sale_items_pkey PRIMARY KEY (id);


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users encrypt_pass; Type: TRIGGER; Schema: api; Owner: linuxer
--

CREATE TRIGGER encrypt_pass BEFORE INSERT OR UPDATE ON api.users FOR EACH ROW EXECUTE FUNCTION auth.encrypt_pass();


--
-- Name: users ensure_user_role_exists; Type: TRIGGER; Schema: api; Owner: linuxer
--

CREATE CONSTRAINT TRIGGER ensure_user_role_exists AFTER INSERT OR UPDATE ON api.users NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION auth.check_role_exists();


--
-- Name: attendances attendances_subscription_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.attendances
    ADD CONSTRAINT attendances_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES api.subscriptions(id);


--
-- Name: cash_register cash_register_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.cash_register
    ADD CONSTRAINT cash_register_user_id_fkey FOREIGN KEY (user_id) REFERENCES api.users(id);


--
-- Name: expenses expenses_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.expenses
    ADD CONSTRAINT expenses_user_id_fkey FOREIGN KEY (user_id) REFERENCES api.users(id);


--
-- Name: incomes incomes_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.incomes
    ADD CONSTRAINT incomes_user_id_fkey FOREIGN KEY (user_id) REFERENCES api.users(id);


--
-- Name: memberships memberships_plan_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.memberships
    ADD CONSTRAINT memberships_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES api.plans(id);


--
-- Name: payments payments_subscription_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.payments
    ADD CONSTRAINT payments_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES api.subscriptions(id);


--
-- Name: permissions permissions_subscription_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.permissions
    ADD CONSTRAINT permissions_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES api.subscriptions(id);


--
-- Name: sale_items sale_items_product_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.sale_items
    ADD CONSTRAINT sale_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES api.products(id);


--
-- Name: sale_items sale_items_sale_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.sale_items
    ADD CONSTRAINT sale_items_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES api.sales(id);


--
-- Name: sales sales_client_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.sales
    ADD CONSTRAINT sales_client_id_fkey FOREIGN KEY (client_id) REFERENCES api.clients(id);


--
-- Name: sales sales_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.sales
    ADD CONSTRAINT sales_user_id_fkey FOREIGN KEY (user_id) REFERENCES api.users(id);


--
-- Name: subscriptions subscriptions_client_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.subscriptions
    ADD CONSTRAINT subscriptions_client_id_fkey FOREIGN KEY (client_id) REFERENCES api.clients(id);


--
-- Name: subscriptions subscriptions_membership_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.subscriptions
    ADD CONSTRAINT subscriptions_membership_id_fkey FOREIGN KEY (membership_id) REFERENCES api.memberships(id);


--
-- Name: subscriptions subscriptions_referred_subscription_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY api.subscriptions
    ADD CONSTRAINT subscriptions_referred_subscription_id_fkey FOREIGN KEY (referred_subscription_id) REFERENCES api.subscriptions(id);


--
-- Name: SCHEMA api; Type: ACL; Schema: -; Owner: linuxer
--

GRANT ALL ON SCHEMA api TO api_anon;
GRANT ALL ON SCHEMA api TO api_admin;
GRANT ALL ON SCHEMA api TO api_user;


--
-- Name: SCHEMA auth; Type: ACL; Schema: -; Owner: linuxer
--

GRANT USAGE ON SCHEMA auth TO api_anon;
GRANT ALL ON SCHEMA auth TO api_admin;
GRANT ALL ON SCHEMA auth TO api_user;


--
-- Name: SCHEMA functions; Type: ACL; Schema: -; Owner: linuxer
--

GRANT USAGE ON SCHEMA functions TO api_anon;
GRANT ALL ON SCHEMA functions TO api_admin;
GRANT ALL ON SCHEMA functions TO api_user;


--
-- Name: TABLE subscriptions; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.subscriptions TO api_admin;
GRANT ALL ON TABLE api.subscriptions TO api_user;
GRANT ALL ON TABLE api.subscriptions TO api_anon;


--
-- Name: TABLE clients; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.clients TO api_admin;
GRANT ALL ON TABLE api.clients TO api_user;
GRANT ALL ON TABLE api.clients TO api_anon;


--
-- Name: TABLE attendances; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.attendances TO api_admin;
GRANT ALL ON TABLE api.attendances TO api_user;
GRANT ALL ON TABLE api.attendances TO api_anon;


--
-- Name: TABLE permissions; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.permissions TO api_admin;
GRANT ALL ON TABLE api.permissions TO api_user;
GRANT ALL ON TABLE api.permissions TO api_anon;


--
-- Name: TABLE cash_register; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.cash_register TO api_admin;
GRANT ALL ON TABLE api.cash_register TO api_user;
GRANT ALL ON TABLE api.cash_register TO api_anon;


--
-- Name: TABLE memberships; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.memberships TO api_admin;
GRANT ALL ON TABLE api.memberships TO api_user;
GRANT ALL ON TABLE api.memberships TO api_anon;


--
-- Name: TABLE payments; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.payments TO api_admin;
GRANT ALL ON TABLE api.payments TO api_user;
GRANT ALL ON TABLE api.payments TO api_anon;


--
-- Name: TABLE plans; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.plans TO api_admin;
GRANT ALL ON TABLE api.plans TO api_user;
GRANT ALL ON TABLE api.plans TO api_anon;


--
-- Name: TABLE client_subscriptions; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.client_subscriptions TO api_admin;
GRANT ALL ON TABLE api.client_subscriptions TO api_user;
GRANT ALL ON TABLE api.client_subscriptions TO api_anon;


--
-- Name: TABLE expenses; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.expenses TO api_admin;
GRANT ALL ON TABLE api.expenses TO api_user;
GRANT ALL ON TABLE api.expenses TO api_anon;


--
-- Name: TABLE incomes; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.incomes TO api_admin;
GRANT ALL ON TABLE api.incomes TO api_user;
GRANT ALL ON TABLE api.incomes TO api_anon;


--
-- Name: TABLE products; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.products TO api_admin;
GRANT ALL ON TABLE api.products TO api_user;
GRANT ALL ON TABLE api.products TO api_anon;


--
-- Name: TABLE sale_items; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.sale_items TO api_admin;
GRANT ALL ON TABLE api.sale_items TO api_user;
GRANT ALL ON TABLE api.sale_items TO api_anon;


--
-- Name: TABLE sales; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.sales TO api_admin;
GRANT ALL ON TABLE api.sales TO api_user;
GRANT ALL ON TABLE api.sales TO api_anon;


--
-- Name: TABLE subscribers; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.subscribers TO api_admin;
GRANT ALL ON TABLE api.subscribers TO api_user;
GRANT ALL ON TABLE api.subscribers TO api_anon;


--
-- Name: TABLE users; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.users TO api_admin;
GRANT ALL ON TABLE api.users TO api_user;
GRANT ALL ON TABLE api.users TO api_anon;


--
-- PostgreSQL database dump complete
--

