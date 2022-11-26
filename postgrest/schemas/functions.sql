-- create postgres function to set unique random access_code 6 characters long
create or replace function generate_access_code () returns text as $$
declare
  access_code text;
  taken boolean;
BEGIN
    access_code := '';
    taken := true;
    while taken loop
        new_access_code := upper(substring(MD5(''||NOW()::TEXT||RANDOM()::TEXT), 1, 6));
        select count(*) > 0 from api.clients where clients.access_code = access_code into taken;
    end loop;
    return access_code;
    END;
$$ language plpgsql;
