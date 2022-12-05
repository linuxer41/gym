-- create get subscription function
create or replace function functions.get_client_subscription(
    client_id uuid
) returns setof api.subscriptions as $$
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
$$ language plpgsql;


create or replace function functions.check_client_subscription(
    client_id uuid
) returns setof api.subscriptions as $$
declare
    subscription_record api.subscriptions;
BEGIN
    select * from api.subscriptions where subscriptions.client_id = check_client_subscription.client_id and is_active = true
    and current_date between start_date and end_date order by start_date desc limit 1
    into subscription_record;
    return next subscription_record;
END;
$$ language plpgsql;

-- create get client function
create or replace function functions.get_client(
    client_id uuid
) returns api.clients as $$
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
$$ language plpgsql;

-- create get date subscription attendance function
create or replace function functions.get_date_subscription_attendance(
    subscription_id uuid,
    date date default current_date
) returns setof api.attendances as $$
declare
    attendance_record api.attendances;
BEGIN
    select * from api.attendances where attendances.subscription_id = get_date_subscription_attendance.subscription_id
    and attendances.date = get_date_subscription_attendance.date
    into attendance_record;
    return next attendance_record;
END;
$$ language plpgsql;

-- create get date subscription permission function
create or replace function functions.get_date_subscription_permission(
    subscription_id uuid,
    date date default current_date
) returns setof api.permissions as $$
declare
    permission_record api.permissions;
BEGIN
    select * from api.permissions where permissions.subscription_id = get_date_subscription_permission.subscription_id
    and permissions.date = get_date_subscription_permission.date
    into permission_record;
    return next permission_record;
END;
$$ language plpgsql;

-- check attendance_permission function for date
create or replace function functions.check_attendance_permission(
    subscription_id uuid,
    date date default current_date
) returns boolean as $$
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
$$ language plpgsql;