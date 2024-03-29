-- create attendance function
create or replace function api.new_attendance(
    client_id uuid
) returns json as $$
declare
    -- clients row type
    client_record api.clients;
    subscription_record api.subscriptions;
    attendance_record api.attendances;
    membership_record api.memberships;
    attendance_count integer;
    current_user_id uuid;
BEGIN
    current_user_id := (current_setting('request.jwt.claims', true)::json->>'user_id')::uuid;
    -- raise null
    if new_attendance.client_id is null then
        raise null_value_not_allowed using message = 'client_id is required';
    end if;
    client_record := functions.get_client(new_attendance.client_id);
    subscription_record := functions.get_client_subscription(client_record.id);
    if subscription_record.id is null then
        raise exception using message = 'El cliente no tiene una suscripción activa';
    end if;

    membership_record := functions.get_membership(subscription_record.membership_id);
    if membership_record.id is null then
        raise exception using message = 'La suscripción no tiene un plan de membresía';
    end if;

    -- if not functions.check_attendance_permission(subscription_record.id, current_date) then
    --     raise exception using message = 'No tiene permiso para asistir';
    -- end if;
    attendance_count := functions.get_attendance_count(subscription_record.id);
    if attendance_count >= membership_record.assistance_limit and membership_record.item_type = 'interval' then
        raise exception using message = 'El cliente ya alcanzó el máximo de asistencias permitidas';
    end if;

    attendance_record := functions.get_date_subscription_attendance(subscription_record.id, current_date);
    if attendance_record.id is null then
        -- create attendance
        insert into api.attendances (subscription_id, date, start_time, user_id, count)
        values (subscription_record.id, current_date, current_time,  current_user_id, 1)
        returning * into attendance_record;
    else
        -- update attendance
        update api.attendances
        set count = count + 1,
        user_id = current_user_id
        where id = attendance_record.id;
    end if;
    -- return client_id
    return json_build_object(
        'client', COALESCE(to_json(client_record), '{}'),
        'subscription', COALESCE(to_json(subscription_record), '{}'),
        'attendance', COALESCE(to_json(attendance_record), '{}')
    );
END;
$$ language plpgsql;


-- create new permission function
create or replace function api.new_permission(
    client_id uuid,
    days integer default 1,
    start_date date default current_date
) returns json as $$
declare
    -- clients row type
    client_record api.clients;
    subscription_record api.subscriptions;
    permission_record api.permissions;
    current_user_id uuid;
BEGIN
    current_user_id := (current_setting('request.jwt.claims', true)::json->>'user_id')::uuid;
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
$$ language plpgsql;


-- create function to create new client with subscription and payment
create or replace function api.new_admission(
    admission json
) returns json as $$
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
            raise exception using message = 'El cliente ya tiene una suscripción activa: finaliza en ' || subscription_record.end_date;
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
                raise exception using message = 'El cliente ya tiene una suscripción activa; cliente: ' || client_record.name;
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
$$ language plpgsql;


-- resume betwen dates
create or replace function api.resume(
    start_date date,
    end_date date
) returns json as $$
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
    total_sales numeric;
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
    -- get total sales
    select sum(total) into total_sales
    from api.sales
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
        'total_expenses', COALESCE(total_expenses, 0),
        'total_sales', COALESCE(total_sales, 0)
    );
END;
$$ language plpgsql;

-- create payment
create or replace function api.new_payment(
    payment json  -- format: {"amount": "numeric", "client_id": "uuid", "subscription_id": "uuid"}
) returns json as $$
declare
    subscription_record api.subscriptions;
    payment_record api.payments;
    total_balance numeric;
    input_payment_amount numeric;
    current_user_id uuid;
BEGIN
    current_user_id := (current_setting('request.jwt.claims', true)::json->>'user_id')::uuid;
    input_payment_amount := (payment->>'amount')::numeric;
    -- raise null
    if payment is null then
        raise null_value_not_allowed using message = 'payment is required';
    end if;
    -- select all subscriptions with balance > 0 for client_id
    select * into subscription_record
    from api.subscriptions
    where id = (payment->>'subscription_id')::uuid;

    -- raise exception if not found
    if subscription_record.id is null then
        raise exception using message = 'No se encontró la suscripción';
    end if;

    -- raise exception if balance is less than payment amount
    if subscription_record.balance < input_payment_amount then
        raise exception using message = 'El monto del pago es mayor al saldo de la suscripción';
    end if;

    -- insert payment
    insert into api.payments (amount,  subscription_id, user_id)
    values (input_payment_amount, (payment->>'subscription_id')::uuid, current_user_id)
    returning * into payment_record;

    -- update subscription balance
    update api.subscriptions
    set balance = balance - input_payment_amount, payment_amount = payment_amount + input_payment_amount
    where id = (payment->>'subscription_id')::uuid;

    -- return
    return json_build_object(
        'payment', COALESCE(to_json(payment_record), '{}')
    );
END;
$$ language plpgsql;