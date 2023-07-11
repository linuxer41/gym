
create schema if not exists api;

-- add token type if not exists

create type api.jwt_token as (
  token text
);

-- login should be on your exposed schema
create or replace function
api.login(email text, pass text) returns json as $$
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
$$ language plpgsql security definer;

-- add register function returning jwt_token and user data
create or replace function
api.register(
  -- email text,
  -- pass text,
  -- role name,
  -- name text,
  -- phone text default null,
  -- address text default null,
  -- dni text default null
  
  --order a-z and convert to named parameters
  address text default null,
  dni text default null,
  email text default null,
  name text default null,
  pass text default null,
  phone text default null,
  role name default null
  

) returns json as $$
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
$$ language plpgsql security definer;
