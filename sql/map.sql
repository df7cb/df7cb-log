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

WITH rename (rename_to, rename_from) AS (VALUES
  ('Aland Islands', 'Åland'),
  ('Annobon Island', 'Annobón'),
  ('Ascension Island', 'Ascension'),
  ('Bosnia-Herzegovina', 'Bosnia & Herzegovina'),
  ('Bonaire', 'Caribbean Netherlands'),
  ('Bouvet', 'Bouvet Island'),
  ('Brunei Darussalam', 'Brunei'),
  ('Cape Verde', 'Cabo Verde'),
  ('Central African Republic', 'Central African Rep.'),
  ('Cote d''Ivoire', 'Côte d''Ivoire'),
  ('Curacao', 'Curaçao'),
  ('Czech Republic', 'Czechia'),
  ('Dem. Rep. of the Congo', 'Dem. Rep. Congo'),
  ('Dominican Republic', 'Dominican Rep.'),
  ('Faroe Islands', 'Faeroe Islands'),
  ('Fed. Rep. of Germany', 'Germany'),
  ('French Polynesia', 'Fr. Polynesia'),
  ('Galapagos Islands', 'Galápagos Islands'),
  ('Guantanamo Bay', 'USNB Guantanamo Bay'),
  ('Heard Island', 'Heard Island & McDonald Islands'),
  ('Jan Mayen', 'Jan Mayen Island'),
  ('Johnston Island', 'Johnston Atoll'),
  ('Lakshadweep Islands', 'Lakshadweep'),
  ('Madeira Islands', 'Madeira'),
  ('Mariana Islands', 'N. Mariana Islands'),
  ('Midway Island', 'Midway Islands'),
  ('Northern Ireland', 'N. Ireland'),
  ('Peter 1 Island', 'Peter I Island'),
  ('Pitcairn Island', 'Pitcairn Islands'),
  ('Republic of Kosovo', 'Kosovo'),
  ('Republic of South Sudan', 'South Sudan'),
  ('Republic of the Congo', 'Congo'),
  ('Reunion Island', 'Réunion'),
  ('Slovak Republic', 'Slovakia'),
  ('South Georgia Island', 'South Georgia'),
  ('St. Barthelemy', 'St-Barthélemy'),
  ('St. Lucia', 'Saint Lucia'),
  ('St. Martin', 'St-Martin'),
  ('St. Vincent', 'St. Vin. & Gren.'),
  ('Svalbard', 'Svalbard Islands'),
  ('Swaziland', 'eSwatini'),
  ('Timor - Leste', 'Timor-Leste'),
  ('The Gambia', 'Gambia'),
  ('Tokelau Islands', 'Tokelau'),
  ('United States', 'United States of America'),
  ('US Virgin Islands', 'U.South Virgin Islands'),
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

WITH b AS (DELETE FROM map_import WHERE country IN ('Diego Garcia NSF', 'Br. Indian Ocean Ter.') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Chagos Islands', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('China', 'Hainan', 'Paracel Islands') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'China', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Denmark', 'Bornholm') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Denmark', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE sovereignt = 'Equatorial Guinea' RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Equatorial Guinea', ST_Multi(ST_Union(geom)) FROM b;

UPDATE map_import SET country = 'Asiatic Russia' WHERE continent = 'Asia' AND country = 'Russia';
WITH b AS (DELETE FROM map_import WHERE country IN ('Russia', 'Crimea') RETURNING *)
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

-- Japanese islands
WITH b AS (DELETE FROM map_import WHERE country IN ('Bonin Islands', 'Volcano Islands') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Ogasawara', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE sovereignt = 'Japan' RETURNING *)
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

/* TODO: split San Andres from Columbia */
WITH b AS (DELETE FROM map_import WHERE country IN ('Serranilla Bank', 'Bajo Nuevo Bank') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'San Andres & Providencia', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE sovereignt = 'São Tomé and Principe' RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Sao Tome & Principe', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE sovereignt IN ('Somalia' /*, 'Somaliland'*/) RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Somalia', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Syria', 'UNDOF Zone') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Syria', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Serbia', 'Vojvodina') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Serbia', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Tanzania', 'Zanzibar') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Tanzania', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Trinidad', 'Tobago') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Trinidad & Tobago', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Akrotiri', 'Dhekelia') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'UK Base Areas on Cyprus', ST_Multi(ST_Union(geom)) FROM b;

WITH b AS (DELETE FROM map_import WHERE country IN ('Yemen', 'Socotra') RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT 'Yemen', ST_Multi(ST_Union(geom)) FROM b;

-- split Greece
WITH greece AS (DELETE FROM map_import WHERE country = 'Greece' RETURNING geom),
  cut_athos AS (SELECT s.geom FROM greece, ST_Split(geom, ST_SetSRID('LINESTRING(24.0 40.4,24.0 40.3)'::geometry, 4326)) s(geom)),
  parts AS (SELECT d.geom FROM cut_athos, ST_Dump(geom) d),
  athos AS (INSERT INTO map_import (country, geom)
    SELECT 'Mount Athos', ST_Multi(ST_Union(geom)) FROM parts
      WHERE ST_Intersects(geom, ST_Locator('KN20de'))),
  crete AS (INSERT INTO map_import (country, geom)
    SELECT 'Crete', ST_Union(geom) FROM parts
      WHERE ST_Intersects(geom, ST_Collect(ST_Locator('KM24'), ST_Locator('KM25')))),
  dodecanese AS (INSERT INTO map_import (country, geom)
    SELECT 'Dodecanese', ST_Union(geom) FROM parts
      WHERE ST_Intersects(geom, ST_SetSRID('POLYGON((26.2 35.4,30 35.4,30 37.5,26.2 37.5,26.2 35.4))'::geometry, 4326)))
INSERT INTO map_import (country, geom)
  SELECT 'Greece', ST_Union(geom) FROM parts
    WHERE NOT ST_Intersects(geom, ST_Collect(ST_Collect(ST_Collect(ST_Locator('KN20de'), ST_Locator('KM24')), ST_Locator('KM25')),
      ST_SetSRID('POLYGON((26.2 35.4,30 35.4,30 37.5,26.2 37.5,26.2 35.4))'::geometry, 4326)
    ));

-- split Malaysia
INSERT INTO map_import (country, geom)
  SELECT 'West Malaysia', ST_Intersection(geom, ST_SetSRID('POLYGON((90 0,108 0,108 10,90 10,90 0))'::geometry, 4326))
  FROM map_import WHERE country = 'Malaysia';
INSERT INTO map_import (country, geom)
  SELECT 'East Malaysia', ST_Intersection(geom, ST_SetSRID('POLYGON((120 0,108 0,108 10,120 10,120 0))'::geometry, 4326))
  FROM map_import WHERE country = 'Malaysia';
DELETE FROM map_import WHERE country = 'Malaysia';

-- split Scotland
WITH scotland AS (DELETE FROM map_import WHERE country = 'Scotland' RETURNING geom),
  parts AS (SELECT d.geom FROM scotland, ST_Dump(geom) d),
  shetland AS (INSERT INTO map_import (country, geom)
    SELECT 'Shetland Islands', ST_Union(geom) FROM parts
      WHERE ST_Intersects(geom, ST_Collect(ST_Collect(ST_Locator('IO99'), ST_Locator('IP90')), ST_Locator('IP80'))))
INSERT INTO map_import (country, geom)
  SELECT 'Scotland', ST_Union(geom) FROM parts
    WHERE NOT ST_Intersects(geom, ST_Collect(ST_Collect(ST_Locator('IO99'), ST_Locator('IP90')), ST_Locator('IP80')));

-- split Turkey
WITH turkey AS (DELETE FROM map_import WHERE country = 'Turkey' RETURNING geom),
  parts AS (SELECT d.geom FROM turkey, ST_Dump(geom) d),
  europe AS (INSERT INTO map_import (country, geom)
    SELECT 'European Turkey', ST_Union(geom) FROM parts
      WHERE ST_Intersects(geom, ST_Collect(ST_Locator('KN20'), ST_Locator('KN31'))))
INSERT INTO map_import (country, geom)
  SELECT 'Asiatic Turkey', ST_Union(geom) FROM parts
    WHERE NOT ST_Intersects(geom, ST_Collect(ST_Locator('KN20'), ST_Locator('KN31')));

/*
 * Not present in cty.csv:
 * N. Cyprus
 * Somaliland
 */

UPDATE country c SET geom = m.geom
  FROM map_import m
  WHERE c.country = m.country
  AND c.geom IS distinct from m.geom;

CLUSTER country USING country_pkey;

SELECT c.country, m.*
  FROM country c FULL JOIN map_import m ON c.country = m.country
  WHERE c.country IS NULL OR m.country IS NULL
  ORDER BY COALESCE(c.country, m.country);
