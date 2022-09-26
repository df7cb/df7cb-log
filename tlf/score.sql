\set contest 'XYZ Contest'

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
        where contest = 'CQWW RTTY' and start >= current_date - '5 days'::interval
        group by qrg::band)
select * from bands
union all
select null, sum(qso), sum(dxcc), sum(cqzone), sum(states), sum(points) from bands
union all
select null, null, null, null, null, (sum(dxcc) + sum(cqzone) + sum(states)) * sum(points) from bands;

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

select
  count(distinct date_round(start, '10 min')) * '10 min'::interval as operating_time
from log
where contest = :'contest' and start >= current_date - '5 days'::interval;

