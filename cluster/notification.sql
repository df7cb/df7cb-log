create table notification (
  start timestamptz(0),
  band band,
  mode text,
  item text,
  primary key (band, mode, item)
);


create or replace function notification(msg text, p_band band, p_mode text, p_item text, notify text default 'irc_notify', telegram bool default false)
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

  -- send message to IRC
  if notify is not null then
    perform pg_notify(notify, msg);
  end if;
  -- send message to Telegram
  if telegram then
    perform telegram(msg);
  end if;

  insert into notification values (now(), p_band, p_mode, p_item)
  on conflict on constraint notification_pkey do update set start = now();

  return;
end;
$$;
