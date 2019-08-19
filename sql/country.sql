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

CREATE DOMAIN call AS text
  CONSTRAINT valid_callsign CHECK ((VALUE ~ '^[A-Z0-9]+(/[A-Z0-9]+)*$'::text));

CREATE OR REPLACE FUNCTION cty(call call)
  RETURNS cty
  LANGUAGE SQL
  AS $$SELECT cty FROM prefix WHERE call <@ prefix ORDER BY length(prefix) DESC LIMIT 1$$;

--CREATE CAST (call AS cty) WITH FUNCTION cty AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION cq(call call)
  RETURNS text
  LANGUAGE SQL
  AS $$SELECT lpad(cq::text, 2, '0') FROM prefix JOIN country ON prefix.cty = country.cty WHERE call <@ prefix ORDER BY length(prefix) DESC LIMIT 1$$;

CREATE OR REPLACE FUNCTION itu(call call)
  RETURNS text
  LANGUAGE SQL
  AS $$SELECT lpad(itu::text, 2, '0') FROM prefix JOIN country ON prefix.cty = country.cty WHERE call <@ prefix ORDER BY length(prefix) DESC LIMIT 1$$;
