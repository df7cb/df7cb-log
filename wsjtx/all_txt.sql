-- 220111_202800  2400.040 Rx FT8     -4  1.2  996 CQ DL6SMA JN58

create table all_txt (
    start timestamptz,
    qrg numeric,
    rx text,
    mode text,
    rst int,
    off numeric, -- time offset
    freq int,
    msg text,
    primary key (start, msg),
    cq text,
    dx text,
    call text,
    loc text,
    rprt int,
);

create or replace function all_txt_split()
  returns trigger
  language plpgsql
as $$
declare
  match text;
begin

  select m[1] into match from regexp_matches(new.msg, '^(CQ(?: .{1,4})?\M) [A-Z0-9]*[A-Z][0-9]+[A-Z]+') m;
  if match is not null then
    new.cq := match;
  end if;

  for match in select m[1] from regexp_matches(new.msg, '<?([A-Z0-9]*[A-Z][0-9]+[A-Z]+(?:/[A-Z0-9]+)*)>?', 'g') m loop
    if new.call is not null then
      new.dx := new.call;
    end if;
    new.call := match;
  end loop;

  select m[1] into match from regexp_matches(new.msg, '\m[A-Q][A-Q][0-9][0-9]\M') m;
  if match <> 'RR73' then
    new.loc := match;
  end if;

  select m[1] into match from regexp_matches(new.msg, 'R?[+-]([0-9]+)\M') m;
  if match is not null then
    new.rprt := match;
  end if;

  return new;
end
$$;

create trigger all_txt_split before insert on all_txt
for each row execute function all_txt_split();

create or replace function all_txt_notify()
  returns trigger
  language plpgsql
as $$
declare
  msg text;
begin
  msg := format('%s %s %s %s', new.start, new.qrg, new.mode, new.msg);
  perform pg_notify('all_txt', msg);
  return new;
end
$$;

create trigger all_txt_notify after insert on all_txt
for each row execute function all_txt_notify();
