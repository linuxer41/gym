-- create attendance function
create or replace function api.new_attendance(
    client_id uuid
) returns json as $$
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
$$ language plpgsql;