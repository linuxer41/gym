-- create subscriptor view psql join clients and grouded by client_id subscriptions and grouded by subscription_id
create or replace view api.client_subscriptions as
select api.subscriptions.*,
COALESCE(to_json(api.memberships.*), '{}') as membership,
COALESCE(to_json(api.plans.*),   '{}') as plan,
COALESCE(payments.payments, '[]') as payments,
COALESCE(payments.payments_count, 0) as payments_count,
COALESCE(payments.total_paid, 0) as total_paid,
COALESCE(attendances.attendances, '[]') as attendances,
COALESCE(attendances.attendances_count, 0) as attendances_count,
COALESCE(permissions.permissions, '[]') as permissions,
COALESCE(permissions.permissions_count, 0) as permissions_count,
left_days.left_days,
total_days.total_days,
COALESCE(total_days.total_days - left_days.left_days, 0) as used_days,
COALESCE(current_date > api.subscriptions.end_date, false) as expired
from api.subscriptions
inner JOIN api.memberships ON api.subscriptions.membership_id = api.memberships.id
INNER JOIN api.plans ON api.memberships.plan_id = api.plans.id
left join (
    select api.payments.subscription_id as subscription_id, COALESCE(json_agg(
      to_json(api.payments.*)
    ), '[]') as payments, count(api.payments.*) as payments_count,
    sum(api.payments.amount) as total_paid
    from api.payments
    group by api.payments.subscription_id
) as payments on api.subscriptions.id = payments.subscription_id
left join (
    select api.attendances.subscription_id as subscription_id, COALESCE(json_agg(
      to_json(api.attendances.*)
    ), '[]') as attendances,
    count(api.attendances.*) as attendances_count
    from api.attendances
    group by api.attendances.subscription_id
) as attendances on api.subscriptions.id = attendances.subscription_id
left join (
    select api.permissions.subscription_id as subscription_id, COALESCE(json_agg(
      to_json(api.permissions.*)
    ), '[]') as permissions,
    count(api.permissions.*) as permissions_count
    from api.permissions
    group by api.permissions.subscription_id
) as permissions on api.subscriptions.id = permissions.subscription_id
-- lateral calculate used
, lateral (
    select case
        when api.subscriptions.start_date = api.subscriptions.end_date then 1
        else (api.subscriptions.end_date - api.subscriptions.start_date)
    end as total_days
) as total_days

, lateral (
    select total_days.total_days - (COALESCE(attendances.attendances_count, 0) + COALESCE(permissions.permissions_count, 0)) as left_days
) as left_days
;


create or replace view api.subscribers as
select api.clients.*,
case when active_subscription.active_subscription is not null then true else false end as has_active_subscription,
case when subscriptions.subscriptions is not null then true else false end as has_subscriptions,
subscriptions.*,
active_subscription.active_subscription
from api.clients
left join (
    select api.client_subscriptions.client_id as client_id, json_agg(
      to_json(api.client_subscriptions.*)
    ) as subscriptions,
		count(api.client_subscriptions.*) as subscriptions_count,
		sum(api.client_subscriptions.balance) as balance,
		sum(api.client_subscriptions.payment_amount) as payment_amount,
		sum(api.client_subscriptions.price) as price,
		sum(api.client_subscriptions.payment_amount) - sum(api.client_subscriptions.price) as debt,
		sum(api.client_subscriptions.payment_amount) - sum(api.client_subscriptions.price) > 0 as in_debt
    from api.client_subscriptions
    group by api.client_subscriptions.client_id
) as subscriptions on api.clients.id = subscriptions.client_id
left join (
    select (array_agg(to_json(client_subscriptions.*)))[1] as active_subscription, client_subscriptions.client_id from api.client_subscriptions
    where not api.client_subscriptions.expired and api.client_subscriptions.is_active
    group by client_subscriptions.client_id
) as active_subscription on api.clients.id = active_subscription.client_id;