CREATE DOMAIN locator AS text
	CONSTRAINT valid_locator CHECK (VALUE ~ '^[A-R][A-R](?:[0-9][0-9](?:[A-Xa-x][A-Xa-x](?:[0-9][0-9](?:[A-Xa-x][A-Xa-x])?)?)?)?$');

CREATE OR REPLACE FUNCTION locator_as_linestring (loc locator) RETURNS text
STRICT LANGUAGE plpgsql
AS $$DECLARE
    a1 int := ascii(substr(loc, 1, 1)) - 65; -- field
    a2 int := ascii(substr(loc, 2, 1)) - 65;
    b1 int := ascii(substr(loc, 3, 1)) - 48; -- square
    b2 int := ascii(substr(loc, 4, 1)) - 48;
    c1 int := ascii(upper(substr(loc, 5, 1))) - 65; -- subsquare
    c2 int := ascii(upper(substr(loc, 6, 1))) - 65;
    d1 int := ascii(substr(loc, 7, 1)) - 48;
    d2 int := ascii(substr(loc, 8, 1)) - 48;
    e1 int := ascii(upper(substr(loc, 9, 1))) - 65;
    e2 int := ascii(upper(substr(loc, 10, 1))) - 65;
    lon_d double precision := 20;
    lat_d double precision := 10;
    lon double precision;
    lat double precision;
BEGIN
    lon := -180 + lon_d * a1;
    lat := -90 + lat_d * a2;
    IF b1 >= 0 THEN
        lon_d = 2;
        lat_d = 1;
        lon := lon + lon_d * b1;
        lat := lat + lat_d * b2;
        IF c1 >= 0 THEN
            lon_d = 2.0/24;
            lat_d = 1.0/24;
            lon := lon + lon_d * c1;
            lat := lat + lat_d * c2;
            IF d1 >= 0 THEN
                lon_d = .2/24;
                lat_d = .1/24;
                lon := lon + lon_d * d1;
                lat := lat + lat_d * d2;
                IF e1 >= 0 THEN
                    lon_d = .2/24/24;
                    lat_d = .1/24/24;
                    lon := lon + lon_d * e1;
                    lat := lat + lat_d * e2;
                END IF;
            END IF;
        END IF;
    END IF;
RETURN format('LINESTRING(%s %s,%s %s,%s %s,%s %s,%s %s)',
    lon, lat,
    lon + lon_d, lat,
    lon + lon_d, lat + lat_d,
    lon, lat + lat_d,
    lon, lat);
END$$;

CREATE OR REPLACE FUNCTION ST_Locator(loc locator) RETURNS geometry(POLYGON, 4326)
STRICT LANGUAGE SQL
AS $$SELECT ST_Polygon(ST_GeomFromText(locator_as_linestring(loc)), 4326)$$;

CREATE OR REPLACE VIEW geolog AS
    SELECT call, band(qrg), loc, ST_Locator(loc) FROM log WHERE loc IS NOT NULL;
