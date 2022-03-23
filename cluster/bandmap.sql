create table bandmap (
  band band,
  qrg numeric not null,
  mode text,
  call call,
  db int,
  wpm int,
  msg text,
  spotter text,
  loc locator,
  start timestamptz(0) not null default now(),
  primary key (band, call),
  constraint qrg_in_band check (qrg::band = band)
);

-- rbn -> bandmap

create or replace function rbn_bandmap_trigger()
  returns trigger
  language plpgsql
as $$
declare
  new_qrg numeric := round(new.qrg/1000.0, 4);
  new_band band := new_qrg::band;
begin
  insert into bandmap (band, qrg, call, mode, db, wpm, spotter)
    values (new_band, new_qrg, new.dx, new.mode, new.db, new.wpm, new.spotter)
  on conflict on constraint bandmap_pkey
    do update set qrg = excluded.qrg,
      spotter = excluded.spotter, db = excluded.db, wpm = excluded.wpm,
      start = now();

  delete from bandmap where start < now() - '20min'::interval;

  notify bandmap;

  return new;
end;
$$;

create or replace trigger rbn_bandmap_trigger
  after insert on rbn
  for each row
  when (new.spotter ~ '^D[A-R]' and new.extra = 'CQ')
  execute function rbn_bandmap_trigger();

-- dxcluster -> bandmap

create or replace function dxcluster_bandmap_trigger()
  returns trigger
  language plpgsql
as $$
declare
  new_qrg numeric := round(new.qrg/1000.0, 4);
  new_band band := new_qrg::band;
begin
  insert into bandmap (band, qrg, call, msg, spotter, loc)
    values (new_band, new_qrg, new.dx, new.msg, new.spotter, new.loc)
  on conflict on constraint bandmap_pkey
    do update set qrg = excluded.qrg,
      msg = excluded.msg, spotter = excluded.spotter, loc = excluded.loc,
      start = now();

  delete from bandmap where start < now() - '20min'::interval;

  notify bandmap;

  return new;
end;
$$;

create or replace trigger dxcluster_bandmap_trigger
  after insert on dxcluster
  for each row
  when (new.spotter ~ '^D[A-R]')
  execute function dxcluster_bandmap_trigger();
