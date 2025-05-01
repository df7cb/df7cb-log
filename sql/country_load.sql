begin;

create temp table country_import (
  cty text PRIMARY KEY NOT NULL,
  country text NOT NULL,
  dxcc int NOT NULL,
  continent text NOT NULL,
  cq int NOT NULL,
  itu int NOT NULL,
  lat numeric NOT NULL,
  lon numeric NOT NULL,
  tz numeric NOT NULL,
  prefixes text NOT NULL
);

\copy country_import from 'cty.csv' (format csv, header false, delimiter ',')

insert into country (
  cty,
  country,
  official,
  dxcc,
  continent,
  cq,
  itu,
  lat,
  lon,
  tz,
  prefixes)
select
  regexp_replace(cty::text, '^\*', '')::cty as cty,
  country,
  cty::text !~ '^\*' as official,
  dxcc,
  continent,
  cq,
  itu,
  lat,
  -lon as lon,
  -tz as tz,
  regexp_replace(prefixes, ';$', '') as prefixes
from country_import
where cty !~ '^\*' and cty <> '1S'
on conflict on constraint country_pkey
do update set
  country = excluded.country,
  dxcc = excluded.dxcc,
  official = excluded.official,
  continent = excluded.continent,
  cq = excluded.cq,
  itu = excluded.itu,
  lat = excluded.lat,
  lon = -excluded.lon,
  tz = -excluded.tz,
  prefixes = regexp_replace(excluded.prefixes, ';$', '');

truncate prefix;
insert into prefiX
  select
    regexp_replace(m[1], '=|[\[(].*', '', 'g') as prefix, -- remove = and everything after [ or (
    cty,
    (regexp_match(m[1], '\((.*)\)'))[1]::int as cq,
    (regexp_match(m[1], '\[(.*)\]'))[1]::int as itu
  from country, regexp_matches(prefixes, '[^ ]+', 'g') m(m); -- blank-separated words

commit;
