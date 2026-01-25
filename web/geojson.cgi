#!/usr/bin/python3

import cgi
import cgitb
import psycopg2
import re

conn = psycopg2.connect("dbname=cb")
cur = conn.cursor()

form = cgi.FieldStorage()

print("Content-Type: application/geo+json")
print()

logtable = 'alllog'
map_type = 'cty'
n = 4
if 'type' in form:
    m = re.search('^(loc|ctyloc)([246])$', form.getvalue('type'))
    if m:
        map_type = m.group(1)
        n = m.group(2)
    elif form.getvalue('type') in ('cqzone', 'ituzone'):
        map_type = form.getvalue('type')

qual, param = '', []

if 'band' in form:
    band = form.getvalue('band')
    if band == 'hf':
        qual += "and qrg between 1.8 and 30 "
    elif band == 'low':
        qual += "and qrg between 1.8 and 10 "
    elif band == 'high':
        qual += "and qrg between 10 and 30 "
    elif band == 'main':
        qual += "and qrg between 1.8 and 30 and qrg::band in ('160m', '80m', '40m', '20m', '15m', '10m') "
    elif band == 'warc':
        qual += "and qrg between 5 and 25 and qrg::band in ('60m', '30m', '17m', '12m') "
    elif band == 'vhf':
        qual += "and qrg > 30 "
    elif re.search(r'^[\d.cm]+$', band):
        qual += "and qrg::band = %s "
        param.append(band)

if 'call' in form:
    call = form.getvalue('call')
    if re.search('^[A-Za-z0-9/]+$', call):
        qual += "and call collate \"C\" ~ upper(%s) "
        param.append(call)

if 'contest' in form:
    contest = form.getvalue('contest')
    if m := re.search('^([0-9-]+) (.+)$', contest):
        qual += "and week(start) = %s and contest = %s "
        param.append(m.group(1))
        param.append(m.group(2))

if 'mycall' in form:
    mycall = form.getvalue('mycall')
    if re.search('^[A-Za-z0-9/]+$', mycall) and mycall != 'all':
        qual += "and mycall = %s "
        param.append(mycall)

if 'mode' in form:
    mode = form.getvalue('mode')
    if mode == 'PHONE':
        qual += "and mode in ('SSB', 'FM') "
    elif mode == 'DATA':
        qual += "and mode not in ('CW', 'SSB', 'FM') "
    elif re.search('^[A-Za-z0-9 ./-]+$', mode) and mode != 'all':
        qual += "and mode = %s "
        param.append(mode)

if 'time' in form:
    time = form.getvalue('time')
    if time == 'today':
        qual += "and start >= current_date "
    elif time == 'yesterday':
        qual += "and start >= current_date - '1 day'::interval and start < current_date "
    elif m := re.search('^([0-9]+)day$', time):
        qual += "and start >= current_date - %s * '1 day'::interval "
        param.append(int(m.group(1)) - 1)
    elif m := re.search('^([0-9]+)week$', time):
        qual += "and start >= current_date - %s * '1 week'::interval "
        param.append(int(m.group(1)))
    elif time == 'month':
        qual += "and start >= date_trunc('month', now()) "
    elif re.search('^[0-9]+$', time):
        qual += "and start >= %s and start < %s "
        param.append("%d-01-01" % int(time))
        param.append("%d-01-01" % (int(time)+1))

common_columns = f"""count(*) as count,
  array_agg(distinct extract(year from start)) as years,
  array_agg(distinct major_mode(mode)) as modes,
  array_agg(distinct qrg::band) as bands,
  array_agg(distinct qso_via) as qso_via,
  string_agg(distinct call, ' ') as calls,
  bool_or(qslrx = 'Y') as qsl,
  bool_or(lotw) as lotw,
"""

json_build_object = f"""
summary as (select
  json_agg(distinct qrg::band) as bands,
  count(*) as count,
  json_agg(distinct cty) as countries,
  json_agg(distinct loc::varchar({n})) FILTER (WHERE loc is not null) as locs,
  json_agg(distinct major_mode(mode)) as modes,
  json_agg(distinct extract(year from start)) as years,
  json_agg(distinct qso_via) filter (where qso_via is not null) as qso_via
  from {logtable} where true {qual}),
stats as (select major_mode(mode),
  qrg::band as band,
  case when qslrx = 'Y' and lotw then 'QSL+LoTW'
       when qslrx = 'Y' then 'QSL'
       when lotw then 'LoTW'
       else 'none'
  end as qsl,
  count(*) from {logtable}
  where true {qual}
  group by grouping sets((1), (2), (3), ())),
last_qsos as (select
  mycall,
  to_char(start, 'YYYY-MM-DD HH24:MI') as start,
  call,
  cty,
  concat_ws('/', mode, submode) as mode,
  round(qrg, 3) as qrg,
  concat_ws(' ', rsttx, extx) as rsttx,
  concat_ws(' ', rstrx, exrx) as rstrx,
  loc,
  case qslrx when 'Y' then '✅' when 'R' then '⌛' end as qsl,
  case when lotw then '✅' end as lotw,
  contest,
  comment,
  qso_via,
  qslid,
  myqth, myloc,
  mytrx, mypwr, myant
from {logtable} log where true {qual} order by log.start desc limit 1000),
u(geojson) as (select st_asgeojson(l.*, 'geometry', '4')::jsonb from l
  union all
  select jsonb_build_object(
      'type', 'Feature',
      'id', 'log',
      'geometry', null,
      'properties', jsonb_build_object('qso', json_agg(row_to_json(last_qsos.*)))
  ) from last_qsos
  union all
  select jsonb_build_object(
      'type', 'Feature',
      'id', 'stats',
      'geometry', null,
      'properties', jsonb_build_object(
          'count', (select count from stats where major_mode is null and band is null and qsl is null),
          'modes', (select jsonb_object_agg(major_mode, count) from stats where major_mode is not null),
          'bands', (select jsonb_object_agg(band, count) from stats where band is not null),
          'qsls', (select jsonb_object_agg(qsl, count) from stats where qsl is not null)
      )
  ) from stats
  union all
  select jsonb_build_object(
      'type', 'Feature',
      'id', 'summary',
      'geometry', null,
      'properties', jsonb_build_object(
        'bands', bands,
        'count', count,
        'countries', countries,
        'locs', locs,
        'modes', modes,
        'years', years,
        'qso_via', qso_via
      )
  ) from summary)
select json_build_object(
  'type', 'FeatureCollection',
  'features', jsonb_agg(u.geojson)
)::text
from u;
"""

if map_type == 'cty':
    query = f"""
with l as (
select
  country.cty as id,
  country.country,
  string_agg(distinct loc::varchar({n}), ' ') as locs,
  {common_columns}
  geom as geometry
from {logtable} log
join country on log.cty = country.cty
  where country.geom is not null
  {qual}
  group by country.cty
),
{json_build_object}
"""

elif map_type == 'loc':
    query = f"""
with l as (
select
  loc::varchar({n}) as id,
  array_agg(distinct cty) as ctys,
  {common_columns}
  st_locator(loc::varchar({n})::locator) as geometry
from {logtable} log
  where length(loc) >= {n}
  {qual}
  group by loc::varchar({n})
),
{json_build_object}
"""

elif map_type == 'ctyloc':
    query = f"""
with l as (
select
  country.cty || '/' || loc::varchar({n}) as id,
  country.country,
  {common_columns}
  st_simplify(st_intersection(geom, st_locator(loc::varchar({n})::locator)), 0.02) as geometry
from {logtable} log
join country on log.cty = country.cty
  where length(loc) >= {n} and country.geom is not null
  {qual}
  group by country.cty, loc::varchar({n})
),
{json_build_object}
"""

elif map_type == 'cqzone':
    query = f"""
with l as (
select
  'Zone ' || cqzone.cq::text as id,
  --'Zone ' || cqzone.cq::text as name,
  {common_columns}
  st_simplify(geom, 0.02) as geometry
from {logtable} log
join cqzone on log.cq = cqzone.cq
  where cqzone.geom is not null
  {qual}
  group by cqzone.cq
),
{json_build_object}
"""

elif map_type == 'ituzone':
    query = f"""
with l as (
select
  'Zone ' || ituzone.itu::text as id,
  --'Zone ' || ituzone.itu::text as name,
  {common_columns}
  st_simplify(geom, 0.02) as geometry
from {logtable} log
join ituzone on log.itu = ituzone.itu
  where ituzone.geom is not null
  {qual}
  group by ituzone.itu
),
{json_build_object}
"""

#print(query, param + param + param + param)
cur.execute(query, param + param + param + param)
print(cur.fetchone()[0])
