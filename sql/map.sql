DROP TABLE IF EXISTS map_import;
CREATE TABLE map_import (
  sovereignt text,
  country text,
  continent text,
  geom geometry(MultiPolygon,4326)
);

INSERT INTO map_import
  SELECT sovereignt, name, continent, geom FROM ne_10m_admin_0_map_subunits;

UPDATE map_import SET country = regexp_replace(country, ' and ', ' & ') WHERE country ~ ' and ';
UPDATE map_import SET country = regexp_replace(country, 'I\.', 'Island') WHERE country ~ 'I\.';
UPDATE map_import SET country = regexp_replace(country, 'Is\.', 'Islands') WHERE country ~ 'Is\.';
UPDATE map_import SET country = regexp_replace(country, 'S\. ', 'South ') WHERE country ~ 'S\.';

WITH rename (rename_to, rename_from) AS (VALUES
  ('Aland Islands', 'Åland'),
  ('Annobon Island', 'Annobón'),
  ('Ascension Island', 'Ascension'),
  ('Bouvet', 'Bouvet Island'),
  ('Brunei Darussalam', 'Brunei'),
  ('Cape Verde', 'Cabo Verde'),
  ('Central African Republic', 'Central African Rep.'),
  ('Cocos (Keeling) Islands', 'Cocos Islands'),
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
  ('N.Z. Subantarctic Is.', 'N.Z. SubAntarctic Islands'),
  ('Peter 1 Island', 'Peter I Island'),
  ('Pitcairn Island', 'Pitcairn Islands'),
  ('Pr. Edward & Marion Is.', 'Prince Edward Islands'),
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
  ('Tristan da Cunha & Gough Islands', 'Tristan da Cunha'),
  ('United States', 'United States of America'),
  ('US Virgin Islands', 'U.South Virgin Islands'),
  ('Vatican City', 'Vatican'),
  ('Wake Island', 'Wake Atoll'),
  ('Western Sahara', 'W. Sahara'))
UPDATE map_import SET country = rename_to
  FROM rename
  WHERE map_import.country = rename_from;

CREATE OR REPLACE FUNCTION join_country(to_cty text, VARIADIC from_ctys text[])
RETURNS void LANGUAGE SQL AS
$$WITH b AS (DELETE FROM map_import WHERE country = ANY(from_ctys) RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT to_cty, ST_Multi(ST_Union(geom)) FROM b$$;

CREATE OR REPLACE FUNCTION join_sovereignt(to_cty text, VARIADIC from_ctys text[])
RETURNS void LANGUAGE SQL AS
$$WITH b AS (DELETE FROM map_import WHERE sovereignt = ANY(from_ctys) RETURNING *)
INSERT INTO map_import (country, geom)
  SELECT to_cty, ST_Multi(ST_Union(geom)) FROM b$$;

SELECT join_country('African Italy', 'Isole Pelagie', 'Pantelleria');
SELECT join_country('Andaman & Nicobar Is.', 'Andaman Islands', 'Nicobar Islands');
SELECT join_country('Antigua & Barbuda', 'Antigua', 'Barbuda');
SELECT join_country('Australia', 'Australia', 'Tasmania', 'Ashmore & Cartier Islands', 'Coral Sea Islands');
SELECT join_country('Baker & Howland Islands', 'Baker Island', 'Howland Island');
SELECT join_sovereignt('Belgium', 'Belgium');
SELECT join_sovereignt('Bosnia-Herzegovina', 'Bosnia and Herzegovina');
SELECT join_country('Ceuta & Melilla', 'Ceuta', 'Melilla');
SELECT join_country('Chagos Islands', 'Diego Garcia NSF', 'Br. Indian Ocean Ter.');
SELECT join_country('China', 'China', 'Hainan', 'Paracel Islands');
SELECT join_country('Denmark', 'Denmark', 'Bornholm');
SELECT join_sovereignt('Timor - Leste', 'East Timor');
SELECT join_country('Equatorial Guinea', 'Bioko', 'Río Muni');
SELECT join_country('Georgia', 'Georgia', 'Adjara');
SELECT join_country('Guernsey', 'Guernsey', 'Alderney', 'Herm', 'Sark');
SELECT join_country('India', 'India', 'Siachen Glacier');
SELECT join_country('Iraq', 'Iraq', 'Iraqi Kurdistan');
SELECT join_country('Palmyra & Jarvis Islands', 'Palmyra Atoll', 'Jarvis Island', 'Kingman Reef'); -- Kingman Reef removed as DXCC entity in 2016
SELECT join_country('Ogasawara', 'Bonin Islands', 'Volcano Islands'); -- Japanese islands
SELECT join_sovereignt('Japan', 'Japan');
SELECT join_country('Juan de Nova & Europa', 'Juan De Nova Island', 'Europa Island', 'Bassas da India'); -- unclean of Bassas da India belongs here
SELECT join_country('New Zealand', 'North Island', 'South Island');
SELECT join_country('DPR of Korea', 'North Korea', 'Korean DMZ (north)');
SELECT join_country('Kazakhstan', 'Kazakhstan', 'Baikonur');
SELECT join_country('Republic of Korea','South Korea', 'Baengnyeongdo', 'Dokdo', 'Jejudo', 'Ulleungdo', 'Korean DMZ (south)');
SELECT join_country('Palestine', 'Gaza', 'West Bank');
SELECT join_country('Papua New Guinea', 'Papua New Guinea', 'Bougainville'); -- Bougainville is an autonomous province without assigned prefix
SELECT join_sovereignt('Sao Tome & Principe', 'São Tomé and Principe');
SELECT join_country('Somalia', 'Somalia' /*, 'Somaliland'*/);
SELECT join_country('Syria', 'Syria', 'UNDOF Zone');
SELECT join_country('Serbia', 'Serbia', 'Vojvodina');
SELECT join_country('Tanzania', 'Tanzania', 'Zanzibar');
SELECT join_country('Trinidad & Tobago', 'Trinidad', 'Tobago');
SELECT join_country('UK Base Areas on Cyprus', 'Akrotiri', 'Dhekelia');
SELECT join_country('Yemen', 'Yemen', 'Socotra');

CREATE OR REPLACE FUNCTION split_country(cty text, new_cty text, selector geometry)
RETURNS void LANGUAGE SQL AS
$$WITH parts AS (SELECT d.geom AS part FROM map_import, ST_Dump(geom) d WHERE country = cty),
  new_part AS (INSERT INTO map_import (country, geom)
    SELECT new_cty, ST_Multi(ST_Union(part)) FROM parts WHERE ST_Intersects(part, selector))
  UPDATE map_import SET geom =
    (SELECT ST_Multi(ST_Union(part)) FROM parts WHERE NOT ST_Intersects(part, selector))
    WHERE country = cty$$;

-- Greece
SELECT split_country('Greece', 'Crete', ST_Collect(ST_Locator('KM24'), ST_Locator('KM25')));
SELECT split_country('Greece', 'Dodecanese', ST_SetSRID('POLYGON((26.2 35.4,30 35.4,30 37.5,26.2 37.5,26.2 35.4))'::geometry, 4326));
-- cut Mount Athos from mainland Greece so we can split it
UPDATE map_import SET geom =
  (SELECT ST_CollectionHomogenize(ST_Split(geom, ST_SetSRID('LINESTRING(24.0 40.4,24.0 40.3)'::geometry, 4326)))
     FROM map_import WHERE country = 'Greece')
  WHERE country = 'Greece';
SELECT split_country('Greece', 'Mount Athos', ST_Locator('KN20de'));

-- Malaysia
SELECT split_country('Malaysia', 'West Malaysia', ST_SetSRID('POLYGON((90 0,108 0,108 10,90 10,90 0))'::geometry, 4326));
UPDATE map_import SET country = 'East Malaysia' WHERE country = 'Malaysia';

-- Russia
UPDATE map_import SET country = 'Asiatic Russia' WHERE continent = 'Asia' AND country = 'Russia';
UPDATE map_import SET country = 'European Russia' WHERE country = 'Russia';
SELECT split_country('European Russia', 'Franz Josef Land', ST_SetSRID('POLYGON((35 79,70 79,70 83,35 83,35 79))'::geometry, 4326));
--SELECT join_country('European Russia', 'Russia', 'Crimea');

-- Turkey
SELECT split_country('Turkey', 'European Turkey', ST_Collect(ST_Locator('KN20'), ST_Locator('KN31')));
UPDATE map_import SET country = 'Asiatic Turkey' WHERE country = 'Turkey';

-- Islands
SELECT split_country('American Samoa', 'Swains Island', ST_Locator('AH48'));
SELECT split_country('Antarctica', 'South Shetland Islands', ST_SetSRID('POLYGON((-63 -64,-52 -61,-54 -60,-64 -63,-63 -64))'::geometry, 4326));
SELECT split_country('Australia', 'Lord Howe Island', ST_Locator('QF98'));
SELECT split_country('Brazil', 'St. Peter & St. Paul', ST_Locator('HJ50'));
SELECT split_country('Brazil', 'Fernando de Noronha', ST_SetSRID('POLYGON((-33 -4,-32 -4,-32 -3,-33 -3,-33 -4))'::geometry, 4326));
SELECT split_country('Brazil', 'Trindade & Martim Vaz', ST_Locator('HG59'));
SELECT split_country('Canada', 'Sable Island', ST_Locator('GN03'));
SELECT split_country('Caribbean Netherlands', 'Saba & St. Eustatius', ST_Locator('FK87'));
UPDATE map_import SET country = 'Bonaire' WHERE country = 'Caribbean Netherlands';
SELECT split_country('Colombia', 'Malpelo Island', ST_Locator('EJ'));
SELECT split_country('Colombia', 'San Andres & Providencia', ST_Collect(ST_Locator('EK92'), ST_Locator('EK93')));
SELECT join_country('San Andres & Providencia', 'San Andres & Providencia', 'Serranilla Bank', 'Bajo Nuevo Bank');
SELECT split_country('Cook Islands', 'South Cook Islands', ST_SetSRID('POLYGON((-162 -17,-162 -24,-154 -24,-154 -17,-162 -17))'::geometry, 4326));
UPDATE map_import SET country = 'North Cook Islands' WHERE country = 'Cook Islands';
SELECT split_country('Costa Rica', 'Cocos Island', ST_Locator('EJ65'));
SELECT split_country('Fiji', 'Rotuma Island', ST_Locator('RH87'));
SELECT split_country('Fiji', 'Conway Reef', ST_Locator('RG78'));
SELECT split_country('French Polynesia', 'Austral Islands', ST_SetSRID('POLYGON((-141 -27,-152 -18,-157 -23,-143 -31,-141 -27))'::geometry, 4326));
SELECT split_country('French Polynesia', 'Marquesas Islands', ST_SetSRID('POLYGON((-145 -12,-130 -12,-130 -5,-145 -5,-145 -12))'::geometry, 4326));
SELECT split_country('Fr. South Antarctic Lands', 'Amsterdam & St. Paul Is.', ST_Locator('MF'));
SELECT split_country('Fr. South Antarctic Lands', 'Crozet Island', ST_Locator('LE'));
UPDATE map_import SET country = 'Kerguelen Islands' WHERE country = 'Fr. South Antarctic Lands';
SELECT split_country('Hawaii', 'Kure Island', ST_Locator('AL08'));
SELECT split_country('Isla Sala y Gomez', 'Juan Fernandez Islands', ST_Collect(ST_Locator('EF96'), ST_Locator('FF06')));
UPDATE map_import SET country = 'San Felix & San Ambrosio' WHERE country = 'Isla Sala y Gomez';
SELECT split_country('Japan', 'Minami Torishima', ST_Locator('QL64'));
SELECT split_country('Kiribati', 'Banaba Island', ST_Locator('RI49'));
SELECT split_country('Kiribati', 'Western Kiribati', ST_Collect(ST_Locator('RI'), ST_Locator('RJ')));
SELECT split_country('Kiribati', 'Central Kiribati', ST_Locator('AI'));
UPDATE map_import SET country = 'Eastern Kiribati' WHERE country = 'Kiribati';
SELECT split_country('Mauritius', 'Agalega & St. Brandon', ST_Collect(ST_Locator('LH89'), ST_Locator('LH93'))); -- St. Brandon is not present in NE
SELECT split_country('Mauritius', 'Rodriguez Island', ST_Locator('MH10'));
SELECT split_country('Mexico', 'Revillagigedo', ST_Collect(ST_Collect(ST_Locator('DK28'), ST_Locator('DK48')), ST_Locator('DK49'))); -- Roca Partida is not present in NE
SELECT split_country('Pitcairn Island', 'Ducie Island', ST_Locator('CG75'));
SELECT split_country('Scotland', 'Shetland Islands', ST_Collect(ST_Collect(ST_Locator('IO99'), ST_Locator('IP90')), ST_Locator('IP80')));
SELECT split_country('Solomon Islands', 'Temotu Province', ST_SetSRID('POLYGON((164 -13,171 -13,171 -8,164 -8,164 -13))'::geometry, 4326));
SELECT split_country('Svalbard', 'Bear Island', ST_Locator('JQ94'));
SELECT split_country('Venezuela', 'Aves Island', ST_Locator('FK85'));

/*
 * Not present in cty.csv:
 * N. Cyprus
 * Somaliland
 *
 * Not present in Natural Earth:
 * Chesterfield Islands (QH90)
 * Desecheo Island (FK68GJ)
 * Market Reef (JP90NH)
 * Mellish Reef (QH72)
 * Pratas Island
 * St. Paul Island (FN97WE)
 * Willis Island (QH43XR)
 */

INSERT INTO map_import (country, geom)
  VALUES ('Market Reef', 'POLYGON(((19.1294 60.302,19.1297 60.3008,19.1312 60.3001,19.1355 60.2999,19.1351 60.300700000000006,19.1294 60.302)))');

UPDATE country c SET geom = m.geom
  FROM map_import m
  WHERE c.country = m.country
  AND c.geom IS distinct from m.geom;

--update country set geom2 = st_simplify(geom, 0.02, true);

CLUSTER country USING country_pkey;

/* -- show entries not associated
SELECT c.country, m.*
  FROM country c FULL JOIN map_import m ON c.country = m.country
  WHERE c.country IS NULL OR m.country IS NULL
  ORDER BY COALESCE(c.country, m.country);
*/
