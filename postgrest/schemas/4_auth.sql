create schema if not exists auth;


-- trigger to check if role exists
create or replace function
auth.check_role_exists() returns trigger as $$
begin
  if not exists (select 1 from pg_roles as r where r.rolname = new.role) then
    raise foreign_key_violation using message =
      'unknown database role: ' || new.role;
    return null;
  end if;
  return new;
end
$$ language plpgsql;


drop trigger if exists ensure_user_role_exists on api.users;
create constraint trigger ensure_user_role_exists
  after insert or update on api.users
  for each row
  execute procedure auth.check_role_exists();


-- encrypt password
create extension if not exists pgcrypto;

create or replace function
auth.encrypt_pass() returns trigger as $$
begin
  if tg_op = 'INSERT' or new.pass <> old.pass then
    new.pass = crypt(new.pass, gen_salt('bf'));
  end if;
  return new;
end
$$ language plpgsql;

drop trigger if exists encrypt_pass on api.users;
create trigger encrypt_pass
  before insert or update on api.users
  for each row
  execute procedure auth.encrypt_pass();


-- verify password
create or replace function
auth.sign_user(email text, pass text) returns json
  language plpgsql
  as $$
begin
  return (
  select to_json(users.*) from api.users
   where users.email = sign_user.email
     and users.pass = crypt(sign_user.pass, users.pass)
  );
end;
$$;

create or replace function auth.check_user() returns void
  language plpgsql
  as $$
begin
  if current_setting('request.jwt.claims', true)::json->>'email' =
     'disgruntled@mycompany.com' then
    raise insufficient_privilege
      using hint = 'No, estamos contigo';
  end if;
end
$$;
