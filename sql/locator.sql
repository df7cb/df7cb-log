CREATE DOMAIN locator AS text
	CONSTRAINT valid_locator CHECK (VALUE ~ '^[A-Z][A-Z](?:[0-9][0-9](?:[A-Za-z][A-Za-z](?:[0-9][0-9](?:[A-Za-z][A-Za-z])?)?)?)?$');

CREATE OR REPLACE FUNCTION locator_as_linestring (loc locator) RETURNS text
LANGUAGE plpgsql
AS $$DECLARE
    a1 int := ascii(substr(loc, 1, 1)) - 65;
    a2 int := ascii(substr(loc, 2, 1)) - 65;
    b1 int := ascii(substr(loc, 3, 1)) - 48;
    b2 int := ascii(substr(loc, 4, 1)) - 48;
    c1 int := ascii(substr(loc, 5, 1)) - 65;
    c2 int := ascii(substr(loc, 6, 1)) - 65;
    d1 int := ascii(substr(loc, 7, 1)) - 48;
    d2 int := ascii(substr(loc, 8, 1)) - 48;
    e1 int := ascii(substr(loc, 9, 1)) - 65;
    e2 int := ascii(substr(loc, 10, 1)) - 65;
    lon double precision;
    lat double precision;
    lon_d double precision;
    lat_d double precision;
BEGIN
    lon := 20 * a1 - 180;
    lat := 10 * a2 - 90;
    lon_d = 20;
    lat_d = 10;
RETURN format('LINESTRING(%s %s,%s %s,%s %s,%s %s,%s %s)',
		lon, lat,
		lon + lon_d, lat,
		lon + lon_d, lat + lat_d,
		lon, lat + lat_d,
		lon, lat);
END$$;

CREATE OR REPLACE FUNCTION ST_Locator(loc locator) RETURNS geometry(POLYGON, 4326)
LANGUAGE SQL
AS $$SELECT ST_Polygon(ST_GeomFromText(locator_as_linestring(loc)), 4326)$$;

CREATE OR REPLACE VIEW geolog AS
    SELECT call, loc, ST_Locator(loc) FROM log WHERE loc IS NOT NULL;
