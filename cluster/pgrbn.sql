create table rbn (
  start timestamptz(0) not null default now(),
  spotter text not null,
  qrg numeric not null,
  dx text not null,
  db int,
  wpm int,
  extra text
);

create or replace function rbn_notification()
  returns trigger
  language plpgsql
as $$
declare
  new_band band := (new.qrg / 1000.0)::band;
  new_cty cty := call2cty(new.dx::call);
  msg text;
begin

  perform call from log where cty = new_cty and qrg::band = new_band and mode = new.mode;
  if not found then
    msg := format('%s %s %s (%s wpm, de %s)', new.qrg, new.mode, new.dx, new.wpm, new.spotter);
    perform notification(msg, new_band, new.mode, new.dx, notify := 'irc');
  end if;

  return new;
end;
$$;

create or replace trigger rbn_trigger
  after insert on rbn
  for each row
  when (new.spotter ~ '^D[A-R]' and new.extra = 'CQ')
  execute function rbn_notification();
