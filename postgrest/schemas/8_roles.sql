ALTER DATABASE gym SET "app.jwt_secret" TO 'reallyreallyreallyreallyverysafe';

CREATE ROLE api_user nologin;
CREATE ROLE api_admin nologin;
CREATE ROLE api_anon nologin;

CREATE ROLE authenticator WITH NOINHERIT LOGIN PASSWORD 'gym*';

GRANT api_user TO authenticator;
GRANT api_admin TO authenticator;
GRANT api_anon TO authenticator;

GRANT USAGE on SCHEMA api to api_anon;
GRANT USAGE on SCHEMA auth to api_anon;
GRANT USAGE on SCHEMA functions to api_anon;


GRANT ALL on schema api to api_admin;
GRANT ALL on schema auth to api_admin;
GRANT ALL on schema functions to api_admin;

GRANT ALL on schema api to api_user;
GRANT ALL on schema auth to api_user;
GRANT ALL on schema functions to api_user;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA api TO api_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA api TO api_admin;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO api_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO api_admin;


-- assign roles to users
grant select, insert, update, delete on all tables in schema api to api_admin;
-- granular permissions to api_user
-- grant select on api.users to api_user;
-- grant select on api.plans to api_user;
-- grant select on api.memberships to api_user;
-- grant select, insert, update on api.clients to api_user;
-- grant select, insert, update on api.suscriptions to api_user;
-- grant select, insert on api.payments to api_user;
-- grant select, insert on api.products to api_user;
-- grant select, insert, update on api.cash_register to api_user;
-- grant select, insert on api.sales to api_user;
-- grant select, insert, update on api.sale_items to api_user;
-- grant select on api.expenses to api_user;
-- grant select on api.incomes to api_user;

-- granular permissions to api_anon
-- grant select on api.plans to api_anon;
-- grant select on api.memberships to api_anon;


-- momentany solution to allow al to api_anon
grant select, insert, update, delete on all tables in schema api to api_admin;
grant select, insert, update, delete on all tables in schema api to api_user;
grant select, insert, update, delete on all tables in schema api to api_anon;

-- gran on all views
grant all privileges on all tables in schema api to api_admin;
grant all privileges on all tables in schema api to api_user;
grant all privileges on all tables in schema api to api_anon;