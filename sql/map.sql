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

UPDATE map_import SET country = regexp_replace(country, ' and ', ' & ') WHERE country ~ ' and ';
UPDATE map_import SET country = regexp_replace(country, 'I\.', 'Island') WHERE country ~ 'I\.';
UPDATE map_import SET country = regexp_replace(country, 'Is\.', 'Islands') WHERE country ~ 'Is\.';
UPDATE map_import SET country = regexp_replace(country, 'S\. ', 'South ') WHERE country ~ 'S\.';

UPDATE map_import SET country = 'Asiatic '||country WHERE continent = 'Asia' AND country IN ('Russia', 'Turkey');
UPDATE map_import SET country = 'European '||country WHERE continent = 'Europe' AND country IN ('Russia', 'Turkey');

WITH rename (rename_to, rename_from) AS (VALUES
  ('Aland Islands', 'Åland'),
  ('Annobon Island', 'Annobón'),
  ('Ascension Island', 'Ascension'),
  ('Bosnia-Herzegovina', 'Bosnia & Herzegovina'),
  ('Bouvet', 'Bouvet Island'),
  ('Brunei Darussalam', 'Brunei'),
  ('Cape Verde', 'Cabo Verde'),
  ('Cote d''Ivoire', 'Côte d''Ivoire'),
  ('Curacao', 'Curaçao'),
  ('Czech Republic', 'Czechia'),
  ('Faroe Islands', 'Faeroe Islands'),
  ('Fed. Rep. of Germany', 'Germany'),
  ('French Polynesia', 'Fr. Polynesia'),
  ('Heard Island', 'Heard Island & McDonald Islands'),
  ('Jan Mayen', 'Jan Mayen Island'),
  ('Johnston Island', 'Johnston Atoll'),
  ('Madeira Islands', 'Madeira'),
  ('Midway Island', 'Midway Islands'),
  ('Northern Ireland', 'N. Ireland'),
  ('Peter 1 Island', 'Peter I Island'),
  ('Pitcairn Island', 'Pitcairn Islands'),
  ('Republic of Kosovo', 'Kosovo'),
  ('Reunion Island', 'Réunion'),
  ('Slovak Republic', 'Slovakia'),
  ('St. Martin', 'St-Martin'),
  ('Svalbard', 'Svalbard Islands'),
  ('Timor - Leste', 'Timor-Leste'),
  ('The Gambia', 'Gambia'),
  ('Tokelau Islands', 'Tokelau'),
  ('United States', 'United States of America'),
  ('Vatican City', 'Vatican'),
  ('Wake Island', 'Wake Atoll'),
  ('Western Sahara', 'W. Sahara'))
UPDATE map_import SET country = rename_to
  FROM rename
  WHERE map_import.country = rename_from;

WITH b AS (DELETE FROM map_import WHERE country IN ('Isole Pelagie', 'Pantelleria') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'African Italy', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Andaman Islands', 'Nicobar Islands') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Andaman & Nicobar Is.', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Antigua', 'Barbuda') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Antigua & Barbuda', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Australia', 'Tasmania') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Australia', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Baker Island', 'Howland Island') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Baker & Howland Islands', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Ceuta', 'Melilla') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Ceuta & Melilla', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('China', 'Hainan', 'Paracel Islands') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'China', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Denmark', 'Bornholm') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Denmark', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('European Russia', 'Crimea') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'European Russia', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Georgia', 'Adjara') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Georgia', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Guernsey', 'Alderney', 'Herm', 'Sark') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Guernsey', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('India', 'Siachen Glacier') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'India', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Iraq', 'Iraqi Kurdistan') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Iraq', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Japan', 'Hokkaido', 'Honshu', 'Izu-shoto', 'Kyushu', 'Nansei-shoto', 'Shikoku') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Japan', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Juan De Nova Island', 'Europa Island') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Juan de Nova & Europa', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('North Island', 'South Island') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'New Zealand', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('North Korea', 'Korean DMZ (north)') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'DPR of Korea', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Kazakhstan', 'Baikonur') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Kazakhstan', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('South Korea', 'Baengnyeongdo', 'Dokdo', 'Jejudo', 'Ulleungdo', 'Korean DMZ (south)') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Republic of Korea', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Gaza', 'West Bank') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Palestine', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Syria', 'UNDOF Zone') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Syria', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Serbia', 'Vojvodina') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Serbia', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Trinidad', 'Tobago') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Trinidad & Tobago', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Akrotiri', 'Dhekelia') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'UK Base Areas on Cyprus', ST_Multi(ST_Union(geom)) FROM b;

INSERT INTO map_import (country, geom)
  SELECT 'West Malaysia', ST_Intersection(geom, ST_SetSRID('POLYGON((90 0,108 0,108 10,90 10,90 0))'::geometry, 4326))
  FROM map_import WHERE country = 'Malaysia';
INSERT INTO map_import (country, geom)
  SELECT 'East Malaysia', ST_Intersection(geom, ST_SetSRID('POLYGON((120 0,108 0,108 10,120 10,120 0))'::geometry, 4326))
  FROM map_import WHERE country = 'Malaysia';
DELETE FROM map_import WHERE country = 'Malaysia';

UPDATE country c SET geom = m.geom
  FROM map_import m
  WHERE c.country = m.country
  AND c.geom IS distinct from m.geom;

CLUSTER country USING country_pkey;

SELECT c.country, m.*
  FROM country c FULL JOIN map_import m ON c.country = m.country
  WHERE c.country IS NULL OR m.country IS NULL
  ORDER BY COALESCE(c.country, m.country);
