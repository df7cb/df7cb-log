CREATE DOMAIN locator AS text
	CONSTRAINT valid_locator CHECK (VALUE ~ '^[A-Z][A-Z](?:[0-9][0-9](?:[A-Za-z][A-Za-z](?:[0-9][0-9](?:[A-Za-z][A-Za-z])?)?)?)?$');

CREATE OR REPLACE FUNCTION ST_Locator(loc locator) RETURNS geometry
LANGUAGE SQL
AS $$WITH matches(l)
    AS (SELECT regexp_matches(loc, '^([A-Z])([A-Z])(?:([0-9])([0-9])(?:([A-Za-z])([A-Za-z])(?:([0-9])([0-9])(?:([A-Za-z])([A-Za-z]))?)?)?)?$')),
coords AS (SELECT
    20 * (ascii(l[1]) - 65) - 180 AS lon1,
    20 * (ascii(l[1]) - 64) - 180 AS lon2,
    10 * (ascii(l[1]) - 65) - 90 AS lat1,
    10 * (ascii(l[1]) - 64) - 90 AS lat2
    FROM matches)
SELECT ST_Polygon(ST_GeomFromText(format(
		'LINESTRING(%s %s,%s %s,%s %s,%s %s,%s %s)',
		lon1, lat1, lon2, lat1, lon2, lat2, lon1, lat2, lon1, lat1)), 4326)
FROM coords$$;
