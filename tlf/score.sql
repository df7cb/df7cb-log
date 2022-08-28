\set contest 'YO DX HF Contest'

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

