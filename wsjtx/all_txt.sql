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


create table notification (
  start timestamptz(0),
  band band,
  mode text,
  item text,
  primary key (band, mode, item)
);


create or replace function notification(msg text, p_band band, p_mode text, p_item text)
  returns void
  language plpgsql
as $$
begin
  perform start from notification
    where start > now() - '1 hour'::interval
    and band = p_band
    and mode = p_mode
    and item = p_item;
  if found then return; end if;

  perform telegram(msg);

  insert into notification values (now(), p_band, p_mode, p_item)
  on conflict on constraint notification_pkey do update set start = now();

  return;
end;
$$;

create or replace function all_txt_notification()
  returns trigger
  language plpgsql
as $$
declare
  new_cty cty;
  msg text;
begin
  -- new country
  new_cty := call2cty(new.call::call);
  perform start from log where cty = new_cty and major_mode(mode) = 'DATA' and qrg::band = new.qrg::band;
  if not found then
    msg := format('New cty *%s*: %s *%s* %s %s', new_cty, new.qrg, new.mode, new.call, new.loc);
    perform notification(msg, new.qrg::band, 'DATA', new_cty::text);
    return new; -- skip new call check
  end if;

  -- new locator
  if new.loc is not null then
    perform start from log where loc::varchar(4) = new.loc::varchar(4) and major_mode(mode) = 'DATA' and qrg::band = new.qrg::band;
    if not found then
      msg := format('New loc: %s *%s* %s *%s*', new.qrg, new.mode, new.call, new.loc);
      perform notification(msg, new.qrg::band, 'DATA', new.loc::varchar(4));
      return new; -- skip new call check
    end if;
  end if;

  -- new call
  perform start from log where call = new.call and major_mode(mode) = 'DATA' and qrg::band = new.qrg::band;
  if not found then
    msg := format('%s *%s* *%s* %s', new.qrg, new.mode, new.call, new.loc);
    perform notification(msg, new.qrg::band, 'DATA', new.call);
  end if;

  return new;
end
$$;

create or replace trigger all_txt_notification after insert on all_txt
  for each row when (new.rx = 'Rx' and new.qrg is not null and new.call is not null and new.qrg::band = '13cm' and new.call <> 'DF7CB')
  execute function all_txt_notification();

create or replace function qo100_notification()
  returns trigger
  language plpgsql
as $$
declare
  msg text;
begin
  perform start from log where call = new.call and mode = 'CW' and qrg::band = '13cm';
  if not found then
    msg := format('%s *CW* %s*%s* %s wpm', new.qrg, new.extra||' ', new.call, new.wpm);
    perform notification(msg, '13cm', 'CW', new.call);
  end if;

  return new;
end
$$;

create or replace trigger qo100_notification after insert on qo100
  for each row when (new.call <> 'DF7CB')
  execute function qo100_notification();
