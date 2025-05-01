CREATE EXTENSION if not exists prefix;
CREATE EXTENSION if not exists postgis;

-- 1A,Sov Mil Order of Malta,246,EU,15,28,41.90,-12.43,-1.0,1A;

CREATE TABLE country (
  cty text PRIMARY KEY,
  country text NOT NULL,
  official boolean,
  dxcc int NOT NULL,
  continent text NOT NULL,
  cq int NOT NULL,
  itu int NOT NULL,
  lat numeric NOT NULL,
  lon numeric NOT NULL,
  tz numeric NOT NULL,
  prefixes text NOT NULL
);

CREATE TABLE prefix (
  prefix prefix_range NOT NULL,
  cty cty NOT NULL REFERENCES country(cty),
  cq int,
  itu int,
  exact boolean not null
);
CREATE INDEX ON prefix USING gist(prefix);

\ir country_load.sql

SELECT '''' || string_agg(cty, ''',''') || '''' AS cty FROM country \gset
CREATE TYPE cty AS ENUM(:cty);

ALTER TABLE country ALTER COLUMN cty TYPE cty USING cty::cty,
  ADD COLUMN geom geometry(MULTIPOLYGON, 4326);

CREATE DOMAIN call AS text
  CONSTRAINT valid_callsign CHECK ((VALUE ~ '^[A-Z0-9]+(/[A-Z0-9]+)*$'::text));

CREATE OR REPLACE FUNCTION call2cty(call text)
  RETURNS cty
  LANGUAGE SQL
  begin atomic
    SELECT cty FROM prefix
    WHERE call <@ prefix and (call = prefix or not exact)
    ORDER BY length(prefix) DESC LIMIT 1;
  end;

--CREATE CAST (call AS cty) WITH FUNCTION call2cty AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION cq(call text)
  RETURNS text
  LANGUAGE SQL
  begin atomic
    SELECT lpad(coalesce(prefix.cq, country.cq)::text, 2, '0')
    FROM prefix JOIN country ON prefix.cty = country.cty
    WHERE call <@ prefix and (call = prefix or not exact)
    ORDER BY length(prefix) DESC LIMIT 1;
  end;

CREATE OR REPLACE FUNCTION itu(call text)
  RETURNS text
  LANGUAGE SQL
  begin atomic
    SELECT lpad(coalesce(prefix.itu, country.itu)::text, 2, '0')
    FROM prefix JOIN country ON prefix.cty = country.cty
    WHERE call <@ prefix and (call = prefix or not exact)
    ORDER BY length(prefix) DESC LIMIT 1;
  end;

CREATE OR REPLACE FUNCTION continent(call text)
  RETURNS text
  LANGUAGE SQL
  begin atomic
    SELECT continent FROM prefix JOIN country ON prefix.cty = country.cty
    WHERE call <@ prefix and (call = prefix or not exact)
    ORDER BY length(prefix) DESC LIMIT 1;
  end;

-- from https://wiki.postgresql.org/wiki/Round_time
CREATE FUNCTION date_round(base_date timestamptz, round_interval interval)
  RETURNS timestamptz AS $BODY$
SELECT to_timestamp((EXTRACT(epoch FROM $1)::integer + EXTRACT(epoch FROM $2)::integer / 2)
                / EXTRACT(epoch FROM $2)::integer * EXTRACT(epoch FROM $2)::integer)
$BODY$
  LANGUAGE SQL STABLE;

