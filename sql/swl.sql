CREATE TABLE swl (
    start timestamp with time zone NOT NULL,
    stop timestamp with time zone,
    call text NOT NULL,
    cty cty REFERENCES country(cty),
    qrg numeric NOT NULL,
    mode text NOT NULL,
    submode text,
    rsttx text,
    rstrx text,
    qsltx character(1) DEFAULT 'N'::bpchar NOT NULL,
    qslrx character(1) DEFAULT 'N'::bpchar NOT NULL,
    qso_via text,
    name text,
    qth text,
    loc locator,
    dok text,
    contest text,
    comment text,
    mycall call DEFAULT 'DF7CB'::text NOT NULL,
    mytrx text,
    mypwr numeric,
    myqth text,
    myloc text,
    myant text,
    last_update timestamptz(0) default now(),
    PRIMARY KEY (start, call),
    CONSTRAINT start_before_stop CHECK (start <= stop),
    CONSTRAINT valid_band CHECK (band(qrg) IS NOT NULL)
);

COMMENT ON COLUMN swl.qrg IS 'Frequency in MHz';

begin;

drop view if exists swl_adif;

create or replace view swl_adif as
select
    start,
    to_char(start, 'YYYYMMDD') as qso_date,
    to_char(start, 'hh24mi') as time_on,
    nullif(to_char(stop, 'YYYYMMDD'), to_char(start, 'YYYYMMDD')) as qso_date_off,
    nullif(to_char(stop, 'hh24mi'), to_char(start, 'hh24mi')) as time_off,

    call as call,

    qrg as freq,
    qrg::band as band,
    case when qso_via in ('RS-44', 'SO-50', 'ARISS') then '70cm'
         when qso_via = 'QO-100' then '3cm'
         when qso_via ~ '^DB0' then null
         when qso_via is null then null
         else error('Sat unknown: ' || qso_via)
    end as band_rx,

    case mode
      when 'FSQ' then 'MFSK'
      when 'FST4' then 'MFSK'
      when 'FT4' then 'MFSK'
      else mode
    end as mode,
    case mode
      when 'FSQ' then 'FSQCALL'
      when 'FST4' then 'FST4'
      when 'FT4' then 'FT4'
      else submode
    end as submode,

    case when qso_via ~ '^DB0' then 'RPT'
         when qso_via is not null then 'SAT'
    end as prop_mode,
    case when qso_via ~ '^DB0' then null
         when qso_via is not null then qso_via
    end as sat_name,

    regexp_replace(rsttx, '^599(.)', '599 \\1') AS rst_sent,
    --extx as stx_string,
    regexp_replace(rstrx, '^599(.)', '599 \\1') AS rst_rcvd,
    --exrx as srx_string,

    coalesce(qsltx, 'N') AS qsl_sent,
    case qslrx
      when 'Y' then 'Y' -- TNX
      when 'R' then 'R' -- PSE
      else 'i' -- N means PSE at qslshop.de
    end as qsl_rcvd,
    --case when lotw then 'Y' end as lotw_qsl_rcvd,

    loc as gridsquare,
    contest as contest_id,
    comment,

    mycall as station_callsign,
    nullif(mycall, 'DF7CB') operator,
    mytrx as my_rig,
    myant as my_antenna,
    mypwr as tx_pwr,
    myqth as my_city,
    myloc as my_gridsquare,

    coalesce(last_update, start) as last_update
    from swl;

commit;
