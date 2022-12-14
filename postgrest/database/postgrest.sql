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

         extract(epoch from now())::integer + 60*60*24*365 as exp

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

    current_user_id uuid;

    first_attendance boolean default false;

BEGIN

    current_user_id := (current_setting('request.jwt.claims', true)::json->>'user_id')::uuid;

    -- first attendance

    if admission->'first_attendance' is not null then

        first_attendance := admission->'first_attendance';

    end if;

    -- raise null

    if admission is null or admission->'client' is null then

        raise null_value_not_allowed using message = 'client is required';

    end if;



    -- check if client exists

    client_record := functions.get_client_by_dni(admission->'client'->>'dni');

    -- create client if not exists

    if client_record.id is null then

        insert into api.clients (name, phone, address, dni, email)

        values (admission->'client'->>'name', admission->'client'->>'phone', admission->'client'->>'address', admission->'client'->>'dni', admission->'client'->>'email')

        returning * into client_record;

    end if;

    -- create subscription if client was created and admission has subscription

    if client_record.id is not null and admission->'subscription' is not null then

        -- check if client has a subscription

        subscription_record := functions.check_client_subscription(client_record.id);

        if subscription_record.id is not null then

            raise exception using message = 'El cliente ya tiene una suscripci├â┬│n activa: finaliza en ' || subscription_record.end_date;

        end if;

        insert into api.subscriptions (client_id, membership_id, start_date, end_date, price, payment_amount, balance, user_id)

        values (

            client_record.id, (admission->'subscription'->>'membership_id')::uuid,

            (admission->'subscription'->>'start_date')::date, (admission->'subscription'->>'end_date')::date,

            (admission->'subscription'->>'price')::numeric, (admission->'subscription'->>'payment_amount')::numeric,

            (admission->'subscription'->>'balance')::numeric,

            current_user_id

        )

        returning * into subscription_record;

        -- create payment if subscription was created and admission has payment

        if subscription_record.id is not null and admission->'payment' is not null then

            insert into api.payments (subscription_id, amount, user_id)

            values (

                subscription_record.id, (admission->'payment'->>'amount')::numeric,

                current_user_id

            )

            returning * into payment_record;



            -- register first attendance if hast admission->>first_attendance

            if first_attendance then

                insert into api.attendances (subscription_id, date, start_time, user_id)

                values (subscription_record.id, current_date, current_time, current_user_id)

                returning * into attendance_record;

            end if;

        end if;

    end if;



    -- insert subscription and attendance to addmission->'referred_client_ids'

    if admission->'referred_client_ids' is not null then

        for referred_client_id in select json_array_elements_text(admission->'referred_client_ids') loop

            -- get referred client

            client_record := functions.get_client(referred_client_id::uuid);



            referred_subscription := functions.check_client_subscription(client_record.id);



            if referred_subscription.id is not null then

                raise exception using message = 'El cliente ya tiene una suscripci├â┬│n activa; cliente: ' || client_record.name;

            end if;

            -- insert subscription

            insert into api.subscriptions (client_id, membership_id, start_date, end_date, price, payment_amount, balance, referred_subscription_id)

            values (client_record.id, (admission->'subscription'->>'membership_id')::uuid, (admission->'subscription'->>'start_date')::date, (admission->'subscription'->>'end_date')::date, 0, 0, 0, subscription_record.id)

            returning * into referred_subscription;

            if referred_subscription.id is not null then

                -- register first attendance if hast admission->>first_attendance

                if first_attendance then

                    insert into api.attendances (subscription_id, date, start_time, user_id)

                    values (referred_subscription.id, current_date, current_time, current_user_id)

                    returning * into attendance_record;

                end if;

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

    insert into api.attendances (subscription_id, date, start_time, user_id)

    values (subscription_record.id, current_date, current_time,  (current_setting('request.jwt.claims', true)::json->>'user_id')::uuid)

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

            raise exception using message = 'La fecha de fin de la suscripci├â┬│n es menor a la fecha de inicio del permiso';

        end if;

        if not functions.check_attendance_permission(subscription_record.id, start_date + i) then

            raise exception using message = 'No tiene permiso para asistir';

        end if;

        -- create permission

        insert into api.permissions (subscription_id, date, user_id)

        values (subscription_record.id, start_date + i, (current_setting('request.jwt.claims', true)::json->>'user_id')::uuid)

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
-- Name: resume(date, date); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION api.resume(start_date date, end_date date) RETURNS json
    LANGUAGE plpgsql
    AS $$

declare

    attendance_count integer;

    clients_count integer;

    subscriptions_count integer;

    debts_count integer;

    debts_amount numeric;

    payments_count integer;

    payments_amount numeric;

    permissions_count integer;

    total_income numeric;

    total_expenses numeric;

BEGIN

    -- raise null

    if start_date is null or end_date is null then

        raise null_value_not_allowed using message = 'start_date and end_date are required';

    end if;

    -- get attendance count

    select count(*) into attendance_count

    from api.attendances

    where date between start_date and end_date;

    -- get clients count

    select count(*) into clients_count

    from api.clients

    where created_at between start_date and end_date;

    -- get subscriptions count

    select count(*) into subscriptions_count

    from api.subscriptions

    where created_at between resume.start_date and resume.end_date;

    -- get debts count

    select count(*) into debts_count

    from api.subscriptions

    where balance > 0 and created_at between resume.start_date and resume.end_date;

    -- get debts amount

    select sum(balance) into debts_amount

    from api.subscriptions

    where balance > 0 and created_at between resume.start_date and resume.end_date;

    -- get payments count

    select count(*) into payments_count

    from api.payments

    where created_at between start_date and end_date;

    -- get payments amount

    select sum(amount) into payments_amount

    from api.payments

    where created_at between start_date and end_date;

    -- get permissions count

    select count(*) into permissions_count

    from api.permissions

    where created_at between start_date and end_date;

    -- get total income

    select sum(amount) into total_income

    from api.payments

    where created_at between start_date and end_date;

    -- get total expenses

    select sum(amount) into total_expenses

    from api.expenses

    where created_at between start_date and end_date;

    -- return json

    return json_build_object(

        'attendance_count', COALESCE(attendance_count, 0),

        'clients_count', COALESCE(clients_count, 0),

        'subscriptions_count', COALESCE(subscriptions_count, 0),

        'debts_count', COALESCE(debts_count, 0),

        'debts_amount', COALESCE(debts_amount, 0),

        'payments_count', COALESCE(payments_count, 0),

        'payments_amount', COALESCE(payments_amount, 0),

        'permissions_count', COALESCE(permissions_count, 0),

        'total_income', COALESCE(total_income, 0),

        'total_expenses', COALESCE(total_expenses, 0)

    );

END;

$$;


ALTER FUNCTION api.resume(start_date date, end_date date) OWNER TO postgres;

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

        raise exception using message = 'El cliente tiene una permiso para el d├â┬¡a ' || date;

    end if;

    attendance_record := functions.get_date_subscription_attendance(subscription_id, date);

    if attendance_record.id is not null then

        raise exception using message = 'El cliente ya tiene una asistencia para el d├â┬¡a ' || date;

    end if;

    return true;

END;

$$;


ALTER FUNCTION functions.check_attendance_permission(subscription_id uuid, date date) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: subscriptions; Type: TABLE; Schema: api; Owner: linuxer
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
    refered_subscription_id uuid,
    user_id uuid,
    CONSTRAINT subscriptions_balance_check CHECK ((balance >= (0)::numeric)),
    CONSTRAINT subscriptions_check CHECK (((payment_amount >= (0)::numeric) AND (payment_amount <= price))),
    CONSTRAINT subscriptions_check1 CHECK ((end_date >= start_date)),
    CONSTRAINT subscriptions_created_at_check CHECK ((created_at <= now())),
    CONSTRAINT subscriptions_price_check CHECK ((price >= (0)::numeric))
);


ALTER TABLE api.subscriptions OWNER TO linuxer;

--
-- Name: check_client_subscription(uuid); Type: FUNCTION; Schema: functions; Owner: linuxer
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


ALTER FUNCTION functions.check_client_subscription(client_id uuid) OWNER TO linuxer;

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
-- Name: get_client_by_dni(text); Type: FUNCTION; Schema: functions; Owner: linuxer
--

CREATE FUNCTION functions.get_client_by_dni(dni text) RETURNS api.clients
    LANGUAGE plpgsql
    AS $$

declare

    client_record api.clients;

BEGIN

    select * from api.clients where clients.dni = get_client_by_dni.dni limit 1

    into client_record;

    return client_record;

END;

$$;


ALTER FUNCTION functions.get_client_by_dni(dni text) OWNER TO linuxer;

--
-- Name: get_client_subscription(uuid); Type: FUNCTION; Schema: functions; Owner: linuxer
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

        raise exception using message = 'El cliente no tiene una suscripci├â┬│n activa';

    end if;

    return next subscription_record;

END;

$$;


ALTER FUNCTION functions.get_client_subscription(client_id uuid) OWNER TO linuxer;

--
-- Name: attendances; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.attendances (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    subscription_id uuid NOT NULL,
    date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone,
    user_id uuid,
    CONSTRAINT attendances_check CHECK ((end_time >= start_time)),
    CONSTRAINT attendances_created_at_check CHECK ((created_at <= now()))
);


ALTER TABLE api.attendances OWNER TO linuxer;

--
-- Name: get_date_subscription_attendance(uuid, date); Type: FUNCTION; Schema: functions; Owner: linuxer
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


ALTER FUNCTION functions.get_date_subscription_attendance(subscription_id uuid, date date) OWNER TO linuxer;

--
-- Name: permissions; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.permissions (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    subscription_id uuid NOT NULL,
    user_id uuid,
    date date NOT NULL,
    CONSTRAINT permissions_created_at_check CHECK ((created_at <= now()))
);


ALTER TABLE api.permissions OWNER TO linuxer;

--
-- Name: get_date_subscription_permission(uuid, date); Type: FUNCTION; Schema: functions; Owner: linuxer
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


ALTER FUNCTION functions.get_date_subscription_permission(subscription_id uuid, date date) OWNER TO linuxer;

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
-- Name: payments; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.payments (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    subscription_id uuid NOT NULL,
    amount numeric NOT NULL,
    user_id uuid,
    CONSTRAINT payments_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT payments_created_at_check CHECK ((created_at <= now()))
);


ALTER TABLE api.payments OWNER TO linuxer;

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
-- Name: cash_flow; Type: VIEW; Schema: api; Owner: postgres
--

CREATE VIEW api.cash_flow AS
 SELECT sum(payments.amount) AS amount,
    (payments.created_at)::date AS date,
    payments.user_id,
    array_agg(payments.*) AS payments,
    count(payments.*) AS payments_count,
    (array_agg(users.name))[1] AS user_name
   FROM (api.payments
     JOIN api.users ON ((payments.user_id = users.id)))
  GROUP BY ((payments.created_at)::date), payments.user_id
  ORDER BY ((payments.created_at)::date) DESC;


ALTER TABLE api.cash_flow OWNER TO postgres;

--
-- Name: cash_register; Type: TABLE; Schema: api; Owner: linuxer
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


ALTER TABLE api.cash_register OWNER TO linuxer;

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
-- Name: plans; Type: TABLE; Schema: api; Owner: linuxer
--

CREATE TABLE api.plans (
    id uuid DEFAULT public.uuid_generate_v1() NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE api.plans OWNER TO linuxer;

--
-- Name: client_subscriptions; Type: VIEW; Schema: api; Owner: linuxer
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
    subscriptions.refered_subscription_id,
    subscriptions.user_id,
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


ALTER TABLE api.client_subscriptions OWNER TO linuxer;

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
-- Name: subscribers; Type: VIEW; Schema: api; Owner: linuxer
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


ALTER TABLE api.subscribers OWNER TO linuxer;

--
-- Data for Name: attendances; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.attendances (id, created_at, subscription_id, date, start_time, end_time, user_id) FROM stdin;
bee0ab42-8166-11ed-b8f3-48ba4e57ef6c	2022-12-21 15:36:20.723423-04	8230a040-8165-11ed-909f-48ba4e57ef6c	2022-12-21	15:36:20.723423	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
212e67f6-816e-11ed-b8f4-48ba4e57ef6c	2022-12-21 16:29:12.141469-04	e932ddb4-816d-11ed-90a3-48ba4e57ef6c	2022-12-21	16:29:12.141469	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
672e031a-816e-11ed-b8f5-48ba4e57ef6c	2022-12-21 16:31:09.583394-04	54992e82-816e-11ed-a54c-48ba4e57ef6c	2022-12-21	16:31:09.583394	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
8924f0a0-81e6-11ed-abab-48ba4e57ef6c	2022-12-22 06:51:06.134807-04	8230a040-8165-11ed-909f-48ba4e57ef6c	2022-12-22	06:51:06.134807	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
2ceceb6a-81ed-11ed-abad-48ba4e57ef6c	2022-12-22 07:38:37.931607-04	23711463-81ed-11ed-98b5-48ba4e57ef6c	2022-12-22	07:38:37.931607	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
318350e6-81ee-11ed-abae-48ba4e57ef6c	2022-12-22 07:45:55.123186-04	2789f8ba-81ee-11ed-98ba-48ba4e57ef6c	2022-12-22	07:45:55.123186	\N	ef7fa100-6e82-11ed-ba74-48ba4e57ef6c
1043ad19-81f3-11ed-abb5-48ba4e57ef6c	2022-12-22 08:20:46.822325-04	10438f22-81f3-11ed-abb3-48ba4e57ef6c	2022-12-22	08:20:46.822325	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
\.


--
-- Data for Name: cash_register; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.cash_register (id, user_id, created_at, amount, started_at, ended_at) FROM stdin;
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.clients (id, created_at, name, phone, address, dni, access_code, email) FROM stdin;
822fb4dc-8165-11ed-909e-48ba4e57ef6c	2022-12-21 15:27:29.417311-04	francisco ochoa	+59171307408	av. marcelo quiroga santa cruz	7474483	01891C	linuxer41@gmail.com
5851dc76-816a-11ed-90a2-48ba4e57ef6c	2022-12-21 16:02:06.661727-04	Jose saramago			123	099961	
54979bd0-816e-11ed-a54b-48ba4e57ef6c	2022-12-21 16:30:38.392288-04	Fleipe sanches	+59171307408	av. marcelo quiroga santa cruz	1234	D08D9D	linuxer41@gmail.com
ecd3c568-81eb-11ed-98b2-48ba4e57ef6c	2022-12-22 07:29:40.887557-04	Flipe sanches	+59171307408	av. marcelo quiroga santa cruz	jose ma	27A068	linuxer41@gmail.com
19931a68-81ec-11ed-9e8b-48ba4e57ef6c	2022-12-22 07:30:55.95657-04	Flipe sanches	+59171307408	av. marcelo quiroga santa cruz	74744831	235A4B	linuxer41@gmail.com
6b3e3776-81ec-11ed-9e8c-48ba4e57ef6c	2022-12-22 07:33:12.985559-04	Flipe sanches	+59171307408	av. marcelo quiroga santa cruz	7895	9AD6F6	linuxer41@gmail.com
75f671ce-81ec-11ed-9e8d-48ba4e57ef6c	2022-12-22 07:33:30.970327-04	Flipe sanches	+59171307408	av. marcelo quiroga santa cruz	7889	AC60E9	linuxer41@gmail.com
ac39702e-81ec-11ed-9e8e-48ba4e57ef6c	2022-12-22 07:35:02.005719-04	Flipe sanches	+59171307408	av. marcelo quiroga santa cruz	78956	3043A1	linuxer41@gmail.com
f4757d88-81ec-11ed-98b3-48ba4e57ef6c	2022-12-22 07:37:03.193634-04	Flipe sanches	+59171307408	av. marcelo quiroga santa cruz	78958	B4B5C5	linuxer41@gmail.com
f897d834-81ec-11ed-abac-48ba4e57ef6c	2022-12-22 07:37:10.130975-04	Flipe sanches	+59171307408	av. marcelo quiroga santa cruz	78959	D064BD	linuxer41@gmail.com
23711462-81ed-11ed-98b4-48ba4e57ef6c	2022-12-22 07:38:22.018579-04	marcela perez	+59171307408	av. marcelo quiroga santa cruz	7474484	58BB94	linuxer41@gmail.com
2789d1a0-81ee-11ed-98b9-48ba4e57ef6c	2022-12-22 07:45:38.38967-04	felipe sandot			7474	31B377	
c718827c-81f1-11ed-abaf-48ba4e57ef6c	2022-12-22 08:11:34.570462-04	francisco ochoa			74744837	E9E30A	
1043683a-81f3-11ed-abb2-48ba4e57ef6c	2022-12-22 08:20:46.822325-04	joel mercado			7474482	D8DE50	
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
d8009e94-7fcb-11ed-a958-48ba4e57ef6c	Estudiantil mensual	150	1	30	775bcf0e-6e83-11ed-ba77-48ba4e57ef6c
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.payments (id, created_at, subscription_id, amount, user_id) FROM stdin;
8230c700-8165-11ed-90a0-48ba4e57ef6c	2022-12-21 15:27:29.417311-04	8230a040-8165-11ed-909f-48ba4e57ef6c	150	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
e94196f6-816d-11ed-90a4-48ba4e57ef6c	2022-12-21 16:27:38.219583-04	e932ddb4-816d-11ed-90a3-48ba4e57ef6c	15	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
54992e83-816e-11ed-a54d-48ba4e57ef6c	2022-12-21 16:30:38.392288-04	54992e82-816e-11ed-a54c-48ba4e57ef6c	150	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
23711464-81ed-11ed-98b6-48ba4e57ef6c	2022-12-22 07:38:22.018579-04	23711463-81ed-11ed-98b5-48ba4e57ef6c	150	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
2789f8bb-81ee-11ed-98bb-48ba4e57ef6c	2022-12-22 07:45:38.38967-04	2789f8ba-81ee-11ed-98ba-48ba4e57ef6c	15	ef7fa100-6e82-11ed-ba74-48ba4e57ef6c
c718d06a-81f1-11ed-abb1-48ba4e57ef6c	2022-12-22 08:11:34.570462-04	c718a978-81f1-11ed-abb0-48ba4e57ef6c	15	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
1043ad18-81f3-11ed-abb4-48ba4e57ef6c	2022-12-22 08:20:46.822325-04	10438f22-81f3-11ed-abb3-48ba4e57ef6c	15	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.permissions (id, created_at, subscription_id, user_id, date) FROM stdin;
cf276928-81ed-11ed-98b7-48ba4e57ef6c	2022-12-22 07:43:10.110584-04	8230a040-8165-11ed-909f-48ba4e57ef6c	0b07510c-6e83-11ed-ba75-48ba4e57ef6c	2022-12-23
cf28dc9a-81ed-11ed-98b8-48ba4e57ef6c	2022-12-22 07:43:10.110584-04	8230a040-8165-11ed-909f-48ba4e57ef6c	0b07510c-6e83-11ed-ba75-48ba4e57ef6c	2022-12-24
\.


--
-- Data for Name: plans; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.plans (id, name, description) FROM stdin;
67d32f50-6e83-11ed-ba76-48ba4e57ef6c	B├ísico	maquinas + cardio
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
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.subscriptions (id, created_at, client_id, membership_id, start_date, end_date, is_active, price, payment_amount, balance, refered_subscription_id, user_id) FROM stdin;
e932ddb4-816d-11ed-90a3-48ba4e57ef6c	2022-12-21 16:27:38.219583-04	5851dc76-816a-11ed-90a2-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-12-21	2022-12-21	t	15	15	0	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
54992e82-816e-11ed-a54c-48ba4e57ef6c	2022-12-21 16:30:38.392288-04	54979bd0-816e-11ed-a54b-48ba4e57ef6c	8f0655c0-6e83-11ed-ba79-48ba4e57ef6c	2022-12-21	2023-01-20	t	150	150	0	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
23711463-81ed-11ed-98b5-48ba4e57ef6c	2022-12-22 07:38:22.018579-04	23711462-81ed-11ed-98b4-48ba4e57ef6c	8f0655c0-6e83-11ed-ba79-48ba4e57ef6c	2022-12-22	2023-01-21	t	150	150	0	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
8230a040-8165-11ed-909f-48ba4e57ef6c	2022-12-21 15:27:29.417311-04	822fb4dc-8165-11ed-909e-48ba4e57ef6c	d8009e94-7fcb-11ed-a958-48ba4e57ef6c	2022-12-21	2023-01-22	t	150	150	0	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
2789f8ba-81ee-11ed-98ba-48ba4e57ef6c	2022-12-22 07:45:38.38967-04	2789d1a0-81ee-11ed-98b9-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-12-22	2022-12-22	t	15	15	0	\N	ef7fa100-6e82-11ed-ba74-48ba4e57ef6c
c718a978-81f1-11ed-abb0-48ba4e57ef6c	2022-12-22 08:11:34.570462-04	c718827c-81f1-11ed-abaf-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-12-22	2022-12-22	t	15	15	0	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
10438f22-81f3-11ed-abb3-48ba4e57ef6c	2022-12-22 08:20:46.822325-04	1043683a-81f3-11ed-abb2-48ba4e57ef6c	7ebf239a-6e83-11ed-ba78-48ba4e57ef6c	2022-12-22	2022-12-22	t	15	15	0	\N	0b07510c-6e83-11ed-ba75-48ba4e57ef6c
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: api; Owner: linuxer
--

COPY api.users (id, name, created_at, email, pass, phone, address, dni, role) FROM stdin;
0b07510c-6e83-11ed-ba75-48ba4e57ef6c	Francisco ochoa 	2022-11-27 14:41:02.314828-04	linuxer41@gmail.com	$2a$06$mmgzf9sC5tXMBoGKhiXMo.otXGlFuTkXkWuirak1PYu.cyBHVKnU.	71307408	sucre	7474483	api_admin
ef7fa100-6e82-11ed-ba74-48ba4e57ef6c	Celicia Martinez	2022-11-27 14:40:16.116202-04	linuxer@gmail.com	$2a$06$y2O2bYTXd5PO.KEUOEa4eOEZmWThUXvHkAsZh7D/V/l4CTzzdZIme	71307408	sucre	7474483	api_user
0f0199ca-7d8d-11ed-96ef-48ba4e57ef6c	Juan Perez	2022-12-16 18:00:31.393449-04	linuxer42@gmail.com	$2a$06$XrsfD/ShmX5HSeErx5RTberqlpxy5Y.WmUdaVgcZVYSVKCVI.qfzK				api_admin
\.


--
-- Name: attendances attendances_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.attendances
    ADD CONSTRAINT attendances_pkey PRIMARY KEY (id);


--
-- Name: cash_register cash_register_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
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
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
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
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: api; Owner: linuxer
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
-- Name: attendances attendances_subscription_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.attendances
    ADD CONSTRAINT attendances_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES api.subscriptions(id);


--
-- Name: attendances attendances_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.attendances
    ADD CONSTRAINT attendances_user_id_fkey FOREIGN KEY (user_id) REFERENCES api.users(id);


--
-- Name: cash_register cash_register_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
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
-- Name: payments payments_subscription_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.payments
    ADD CONSTRAINT payments_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES api.subscriptions(id);


--
-- Name: payments payments_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.payments
    ADD CONSTRAINT payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES api.users(id);


--
-- Name: permissions permissions_subscription_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.permissions
    ADD CONSTRAINT permissions_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES api.subscriptions(id);


--
-- Name: permissions permissions_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.permissions
    ADD CONSTRAINT permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES api.users(id);


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
-- Name: sales sales_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.sales
    ADD CONSTRAINT sales_user_id_fkey FOREIGN KEY (user_id) REFERENCES api.users(id);


--
-- Name: subscriptions subscriptions_client_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.subscriptions
    ADD CONSTRAINT subscriptions_client_id_fkey FOREIGN KEY (client_id) REFERENCES api.clients(id);


--
-- Name: subscriptions subscriptions_membership_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.subscriptions
    ADD CONSTRAINT subscriptions_membership_id_fkey FOREIGN KEY (membership_id) REFERENCES api.memberships(id);


--
-- Name: subscriptions subscriptions_refered_subscription_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.subscriptions
    ADD CONSTRAINT subscriptions_refered_subscription_id_fkey FOREIGN KEY (refered_subscription_id) REFERENCES api.subscriptions(id);


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: api; Owner: linuxer
--

ALTER TABLE ONLY api.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES api.users(id);


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
-- Name: TABLE subscriptions; Type: ACL; Schema: api; Owner: linuxer
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
-- Name: TABLE attendances; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.attendances TO api_admin;
GRANT ALL ON TABLE api.attendances TO api_user;
GRANT ALL ON TABLE api.attendances TO api_anon;


--
-- Name: TABLE permissions; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.permissions TO api_admin;
GRANT ALL ON TABLE api.permissions TO api_user;
GRANT ALL ON TABLE api.permissions TO api_anon;


--
-- Name: TABLE payments; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.payments TO api_admin;
GRANT ALL ON TABLE api.payments TO api_user;
GRANT ALL ON TABLE api.payments TO api_anon;


--
-- Name: TABLE users; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.users TO api_admin;
GRANT ALL ON TABLE api.users TO api_user;
GRANT ALL ON TABLE api.users TO api_anon;


--
-- Name: TABLE cash_flow; Type: ACL; Schema: api; Owner: postgres
--

GRANT ALL ON TABLE api.cash_flow TO api_admin;
GRANT ALL ON TABLE api.cash_flow TO api_user;
GRANT ALL ON TABLE api.cash_flow TO api_anon;


--
-- Name: TABLE cash_register; Type: ACL; Schema: api; Owner: linuxer
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
-- Name: TABLE plans; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.plans TO api_admin;
GRANT ALL ON TABLE api.plans TO api_user;
GRANT ALL ON TABLE api.plans TO api_anon;


--
-- Name: TABLE client_subscriptions; Type: ACL; Schema: api; Owner: linuxer
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
-- Name: TABLE subscribers; Type: ACL; Schema: api; Owner: linuxer
--

GRANT ALL ON TABLE api.subscribers TO api_admin;
GRANT ALL ON TABLE api.subscribers TO api_user;
GRANT ALL ON TABLE api.subscribers TO api_anon;


--
-- PostgreSQL database dump complete
--

