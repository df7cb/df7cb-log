-- 1A,Sov Mil Order of Malta,246,EU,15,28,41.90,-12.43,-1.0,1A;
CREATE TABLE cty (
  cty text PRIMARY KEY,
  country text NOT NULL,
  beam int NOT NULL,
  continent text NOT NULL,
  itu int NOT NULL,
  cq int NOT NULL,
  lat numeric NOT NULL,
  lon numeric NOT NULL,
  tz numeric NOT NULL,
  prefixes text NOT NULL
);

\copy cty from 'cty.csv' (format csv, delimiter ',')

ALTER TABLE cty DROP COLUMN beam, ADD COLUMN geom geometry(MULTIPOLYGON, 4326);

UPDATE cty SET
  cty = regexp_replace(cty, '^\*', ''),
  lon = -lon,
  tz = -tz,
  prefixes = regexp_replace(prefixes, ';$', '');

--SELECT string_agg(''',''', prefix) AS prefix0 FROM cty \gset
--SELECT regexp_replace(:'prefix0', '^'',|,''$', '', 'g') AS prefix \gset
--CREATE TYPE prefix AS ENUM(:prefix);

CREATE TABLE prefix (
  prefix text NOT NULL,
  cty text NOT NULL REFERENCES cty(cty)
);
INSERT INTO prefix
  SELECT regexp_replace(m[1], '=|[\[(].*', '', 'g'), cty -- remove = and everything after [ or (
  FROM cty, regexp_matches(prefixes, '[^ ]+', 'g') m(m); -- blank-separated words

-- shp2pgsql -DIs 4326 ne_10m_admin_0_map_subunits | psql service=cb

CREATE TABLE map_import (
  sovereignt text,
  country text,
  geom geometry(MultiPolygon,4326)
);

INSERT INTO map_import
  SELECT sovereignt, name, geom FROM ne_10m_admin_0_map_subunits;

UPDATE map_import
  SET country = regexp_replace(country, 'I\.', 'Island')
  WHERE country ~ 'I\.';

UPDATE map_import
  SET country = regexp_replace(country, 'Is\.', 'Islands')
  WHERE country ~ 'Is\.';

UPDATE map_import SET country = 'Fed. Rep. of Germany' WHERE country = 'Germany';
UPDATE map_import SET country = 'United States' WHERE country = 'United States of America';

WITH b AS (DELETE FROM map_import
  WHERE sovereignt IN ('Belgium', 'Bosnia and Herzegovina')
  RETURNING *)
INSERT INTO map_import
  SELECT sovereignt, sovereignt, ST_Multi(ST_Union(geom))
  FROM b
  GROUP BY sovereignt;

WITH b AS (DELETE FROM map_import
  WHERE country IN ('Ceuta', 'Melilla')
  RETURNING *)
INSERT INTO map_import
  SELECT sovereignt, 'Ceuta & Melilla', ST_Multi(ST_Union(geom))
  FROM b
  GROUP BY sovereignt;

SELECT c.country, m.country
  FROM cty c FULL JOIN map_import m ON c.country = m.country
  WHERE c.country IS NULL OR m.country IS NULL
  ORDER BY COALESCE(c.country, m.country);

UPDATE cty c SET geom = m.geom
  FROM map_import m
  WHERE c.country = m.country;

CLUSTER cty USING cty_pkey;
