CREATE EXTENSION prefix;
CREATE EXTENSION postgis;

-- 1A,Sov Mil Order of Malta,246,EU,15,28,41.90,-12.43,-1.0,1A;

CREATE TABLE country (
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

\copy country from 'cty.csv' (format csv, delimiter ',')

UPDATE country SET
  cty = regexp_replace(cty, '^\*', ''),
  lon = -lon,
  tz = -tz,
  prefixes = regexp_replace(prefixes, ';$', '');

SELECT '''' || string_agg(cty, ''',''') || '''' AS cty FROM country \gset
CREATE TYPE cty AS ENUM(:cty);

ALTER TABLE country ALTER COLUMN cty TYPE cty USING cty::cty,
  DROP COLUMN beam,
  ADD COLUMN geom geometry(MULTIPOLYGON, 4326);

CREATE TABLE prefix (
  prefix prefix_range NOT NULL,
  cty cty NOT NULL REFERENCES country(cty)
);
INSERT INTO prefix
  SELECT regexp_replace(m[1], '=|[\[(].*', '', 'g'), cty -- remove = and everything after [ or (
  FROM country, regexp_matches(prefixes, '[^ ]+', 'g') m(m); -- blank-separated words
CREATE INDEX ON prefix USING gist(prefix);

CREATE OR REPLACE FUNCTION cty(call call)
  RETURNS cty
  LANGUAGE SQL
  AS $$SELECT cty FROM prefix WHERE call <@ prefix ORDER BY length(prefix) DESC LIMIT 1$$;

--CREATE CAST (call AS cty) WITH FUNCTION cty AS ASSIGNMENT;

-- shp2pgsql -DIs 4326 ne_10m_admin_0_map_subunits | psql service=cb

CREATE TABLE map_import (
  sovereignt text,
  country text,
  geom geometry(MultiPolygon,4326)
);

INSERT INTO map_import
  SELECT sovereignt, name, geom FROM ne_10m_admin_0_map_subunits;

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

UPDATE map_import SET country = regexp_replace(country, 'I\.', 'Island') WHERE country ~ 'I\.';
UPDATE map_import SET country = regexp_replace(country, 'Is\.', 'Islands') WHERE country ~ 'Is\.';
UPDATE map_import SET country = regexp_replace(country, 'S\. ', 'South ') WHERE country ~ 'S\.';

UPDATE map_import SET country = 'Bosnia-Herzegovina' WHERE country = 'Bosnia and Herzegovina';
UPDATE map_import SET country = 'Fed. Rep. of Germany' WHERE country = 'Germany';
UPDATE map_import SET country = 'Northern Ireland' WHERE country = 'N. Ireland';
UPDATE map_import SET country = 'Reunion Island' WHERE country = 'Réunion';
UPDATE map_import SET country = 'United States' WHERE country = 'United States of America';

SELECT c.country, m.country
  FROM country c FULL JOIN map_import m ON c.country = m.country
  WHERE c.country IS NULL OR m.country IS NULL
  ORDER BY COALESCE(c.country, m.country);

UPDATE country c SET geom = m.geom
  FROM map_import m
  WHERE c.country = m.country
  AND c.geom IS NULL;

CLUSTER country USING country_pkey;
