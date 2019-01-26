-- shp2pgsql -DIs 4326 ne_10m_admin_0_map_subunits | psql service=cb

DROP TABLE IF EXISTS map_import;
CREATE TABLE map_import (
  sovereignt text,
  country text,
  continent text,
  geom geometry(MultiPolygon,4326)
);

INSERT INTO map_import
  SELECT sovereignt, name, continent, geom FROM ne_10m_admin_0_map_subunits;

WITH b AS (DELETE FROM map_import
  WHERE sovereignt IN ('Belgium', 'Bosnia and Herzegovina')
  RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT sovereignt, ST_Multi(ST_Union(geom))
  FROM b
  GROUP BY sovereignt;

WITH b AS (DELETE FROM map_import WHERE country IN ('Ceuta', 'Melilla') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Ceuta & Melilla', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Baker Island', 'Howland Island') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Baker & Howland Islands', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('North Island', 'South Island') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'New Zealand', ST_Multi(ST_Union(geom)) FROM b;

UPDATE map_import SET country = regexp_replace(country, ' and ', ' & ') WHERE country ~ ' and ';
UPDATE map_import SET country = regexp_replace(country, 'I\.', 'Island') WHERE country ~ 'I\.';
UPDATE map_import SET country = regexp_replace(country, 'Is\.', 'Islands') WHERE country ~ 'Is\.';
UPDATE map_import SET country = regexp_replace(country, 'S\. ', 'South ') WHERE country ~ 'S\.';

UPDATE map_import SET country = 'Asiatic '||country WHERE continent = 'Asia' AND country IN ('Russia', 'Turkey');
UPDATE map_import SET country = 'European '||country WHERE continent = 'Europe' AND country IN ('Russia', 'Turkey');

WITH rename (rename_to, rename_from) AS (VALUES
  ('Aland Islands', 'Åland'),
  ('Bosnia-Herzegovina', 'Bosnia & Herzegovina'),
  ('Bouvet', 'Bouvet Island'),
  ('Brunei Darussalam', 'Brunei'),
  ('Cape Verde', 'Cabo Verde'),
  ('Czech Republic', 'Czechia'),
  ('Faroe Islands', 'Faeroe Islands'),
  ('Jan Mayen', 'Jan Mayen Island'),
  ('Johnston Island', 'Johnston Atoll'),
  ('Republic of Kosovo', 'Kosovo'),
  ('Peter 1 Island', 'Peter I Island'),
  ('Pitcairn Island', 'Pitcairn Islands'),
  ('Vatican City', 'Vatican'),
  ('Wake Island', 'Wake Atoll'),
  ('Western Sahara', 'W. Sahara'),
  ('The Gambia', 'Gambia'),
  ('', ''),
  ('Fed. Rep. of Germany', 'Germany'),
  ('Heard Island', 'Heard Island and McDonald Islands'),
  ('Northern Ireland', 'N. Ireland'),
  ('Reunion Island', 'Réunion'),
  ('Slovak Republic', 'Slovakia'),
  ('Svalbard', 'Svalbard Islands'),
  ('United States', 'United States of America'))
UPDATE map_import SET country = rename_to
  FROM rename
  WHERE map_import.country = rename_from;

SELECT c.country, m.*
  FROM country c FULL JOIN map_import m ON c.country = m.country
  WHERE c.country IS NULL OR m.country IS NULL
  ORDER BY COALESCE(c.country, m.country);

UPDATE country c SET geom = m.geom
  FROM map_import m
  WHERE c.country = m.country
  AND c.geom IS NULL;

CLUSTER country USING country_pkey;
