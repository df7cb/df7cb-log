create table dxcluster (
  start timestamptz(0) not null default now(),
  spotter text not null,
  qrg numeric not null,
  dx text not null,
  msg text,
  loc text
);

create or replace function dxcluster_notification()
  returns trigger
  language plpgsql
as $$
declare
  new_band band := (new.qrg / 1000.0)::band;
  new_cty cty := call2cty(new.dx::call);
  msg text;
begin

  perform call from log where cty = new_cty and qrg::band = new_band;
  if not found then
    msg := format('%s %s (cluster de %s)', new.qrg, new.dx, new.spotter);
    perform notification(msg, new_band, 'xxx', new.dx, notify := 'irc');
  end if;

  return new;
end;
$$;

create or replace trigger dxcluster_trigger
  after insert on dxcluster
  for each row
  when (new.spotter ~ '^D[A-R]')
  execute function dxcluster_notification();
