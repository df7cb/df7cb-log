\set contest 'XYZ Contest'
\pset null ''
\pset title :contest

-- generic contest with country as multiplier
with bands as (
    select qrg::band as "Band",
        count(*) as "QSO",
        --sum(case when cty = 'DL' then 1
        --        when continent(cty::text) = 'EU' then 2
        --        else 3 end)
        sum(1)
          as "QSO-Punkte",
        count(distinct cty) as "DXCC",
        array_agg(distinct cty) as "Multis"
        from log
        where contest = :'contest' and start >= current_date - '5 days'::interval
        group by qrg::band)
select "Band"::text, "QSO", "QSO-Punkte", "DXCC", "Multis" from bands
union all
select 'Summe', sum("QSO"), sum("QSO-Punkte"), sum("DXCC"), null from bands
union all
select 'Score', null, null, sum("QSO-Punkte") * sum("DXCC"), null from bands;

-- generic contest with exchange as multiplier
with bands as (
    select qrg::band as "Band",
        count(*) as "QSO",
        --sum(case when cty = 'DL' then 1
        --        when continent(cty::text) = 'EU' then 2
        --        else 3 end)
        sum(1)
          as "QSO-Punkte",
        count(distinct exrx) as "Multi",
        array_agg(distinct exrx) as "Multis"
        from log
        where contest = :'contest' and start >= current_date - '5 days'::interval
        group by qrg::band)
select "Band"::text, "QSO", "QSO-Punkte", "Multi", "Multis" from bands
union all
select 'Summe', sum("QSO"), sum("QSO-Punkte"), sum("Multi"), null from bands
union all
select 'Score', null, null, sum("QSO-Punkte") * sum("Multi"), null from bands;

-- CQWWDX
with bands as (
    select qrg::band as band,
        count(distinct call) as qso,
        count(distinct cty) as dxcc,
        count(distinct exrx) as cqzone,
        sum(case when cty = 'DL' then 0
                when continent(cty::text) = 'EU' then 1
                else 3 end) as points
        from log
        where contest = :'contest' and start >= current_date - '5 days'::interval
        group by qrg::band
        order by qrg::band desc)
select * from bands
union all
select null, sum(qso), sum(dxcc), sum(cqzone), sum(points) from bands
union all
select null, null, null, null, (sum(dxcc) + sum(cqzone)) * sum(points) from bands;

-- CQWW
with bands as (
    select qrg::band as band,
        count(*) as qso,
        count(distinct (qrg::band, cty)) as dxcc,
        count(distinct (qrg::band, regexp_replace(exrx, ' .*', ''))) as cqzone,
        count(distinct (qrg::band, case when exrx ~ ' ' then exrx end)) as states,
        sum(case when cty = 'DL' then 1
                when continent(cty::text) = 'EU' then 2
                else 3 end) as points
        from log
        where contest = :'contest' and start >= current_date - '5 days'::interval
        group by qrg::band)
select * from bands
union all
select null, sum(qso), sum(dxcc), sum(cqzone), sum(states), sum(points) from bands
union all
select null, null, null, null, null, (sum(dxcc) + sum(cqzone) + sum(states)) * sum(points) from bands;

-- Deutscher Telegrafie Contest
with bands as (
    select qrg::band as "Band",
        count(*) as "QSO",
        sum(case when call COLLATE "C" ~ '0(HSC|ACW|AGC|AG|DA)$' then 2
                else 1 end)
          as "QSO-Punkte",
        count(distinct exrx) as "LDK",
        array_agg(distinct exrx) as "Multis"
        from log
        where contest = :'contest' and start >= current_date - '5 days'::interval
        group by qrg::band)
select "Band"::text, "QSO", "QSO-Punkte", "LDK", "Multis" from bands
union all
select 'Summe', sum("QSO"), sum("QSO-Punkte"), sum("LDK"), null from bands
union all
select 'Score', null, null, sum("QSO-Punkte") * sum("LDK"), null from bands;

-- YO DX
with bands as (
    select qrg::band as band,
        count(*) as qso,
        count(distinct cty) as dxcc,
        count(distinct case when cty = 'YO' then rstrx end) as county,
        sum(case when cty = 'DL' then 1
                when cty = 'YO' then 8
                when continent(cty::text) = 'EU' then 4
                else 8 end) as points
        from log
        where contest = :'contest' and start >= current_date - '5 days'::interval
        group by qrg::band)
select * from bands
union all
select null, sum(qso), sum(dxcc), sum(county), sum(points) from bands
union all
select null, null, null, null, (sum(dxcc) + sum(county)) * sum(points) from bands;

-- operating time
select
  count(distinct date_round(start, '10 min')) * '10 min'::interval as operating_time
from log
where contest = :'contest' and start >= current_date - '5 days'::interval;

-- 5-band QSOs
select call, array_agg(distinct qrg::band) as bands
from log
where contest = :'contest' and start >= current_date - '5 days'::interval
group by call
having count(distinct qrg::band) >= 5;
