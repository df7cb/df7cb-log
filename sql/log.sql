CREATE TYPE band AS ENUM (
    '2190m', '630m', '560m',
    '160m', '80m', '60m', '40m', '30m', '20m', '17m', '15m', '12m', '10m',
    '6m', '4m', '2m', '1.25m',
    '70cm', '33cm', '23cm', '13cm', '9cm', '6cm', '3cm', '1.25cm',
    '6mm', '4mm', '2.5mm', '2mm', '1mm');

CREATE OR REPLACE FUNCTION band(qrg numeric) RETURNS band
    LANGUAGE SQL AS
$$SELECT CASE
    WHEN qrg BETWEEN 0.136 AND 0.137       THEN '2190m'::band
    WHEN qrg BETWEEN 0.472 AND 0.479       THEN '630m'
    WHEN qrg BETWEEN 0.501 AND 0.504       THEN '560m'
    WHEN qrg BETWEEN 1.8 AND 2.0           THEN '160m'
    WHEN qrg BETWEEN 3.5 AND 4.0           THEN '80m'
    WHEN qrg BETWEEN 5.102 AND 5.4065      THEN '60m'
    WHEN qrg BETWEEN 7.0 AND 7.3           THEN '40m'
    WHEN qrg BETWEEN 10.1 AND 10.15        THEN '30m'
    WHEN qrg BETWEEN 14.0 AND 14.35        THEN '20m'
    WHEN qrg BETWEEN 18.068 AND 18.168     THEN '17m'
    WHEN qrg BETWEEN 21.0 AND 21.45        THEN '15m'
    WHEN qrg BETWEEN 24.89 AND 24.99       THEN '12m'
    WHEN qrg BETWEEN 28.0 AND 29.7         THEN '10m'
    WHEN qrg BETWEEN 50.0 AND 54.0         THEN '6m'
    WHEN qrg BETWEEN 70.0 AND 71.0         THEN '4m'
    WHEN qrg BETWEEN 144.0 AND 148.0       THEN '2m'
    WHEN qrg BETWEEN 222.0 AND 225.0       THEN '1.25m'
    WHEN qrg BETWEEN 420.0 AND 450.0       THEN '70cm'
    WHEN qrg BETWEEN 902.0 AND 928.0       THEN '33cm'
    WHEN qrg BETWEEN 1240.0 AND 1300.0     THEN '23cm'
    WHEN qrg BETWEEN 2300.0 AND 2450.0     THEN '13cm'
    WHEN qrg BETWEEN 3300.0 AND 3500.0     THEN '9cm'
    WHEN qrg BETWEEN 5650.0 AND 5925.0     THEN '6cm'
    WHEN qrg BETWEEN 10000.0 AND 10500.0   THEN '3cm'
    WHEN qrg BETWEEN 24000.0 AND 24250.0   THEN '1.25cm'
    WHEN qrg BETWEEN 47000.0 AND 47200.0   THEN '6mm'
    WHEN qrg BETWEEN 75500.0 AND 81000.0   THEN '4mm'
    WHEN qrg BETWEEN 119980.0 AND 120020.0 THEN '2.5mm'
    WHEN qrg BETWEEN 142000.0 AND 149000.0 THEN '2mm'
    WHEN qrg BETWEEN 241000.0 AND 250000.0 THEN '1mm'
END$$;

CREATE CAST (numeric AS band) WITH FUNCTION band AS ASSIGNMENT;

CREATE DOMAIN qsl AS char(1)
    CONSTRAINT valid_qsl_request CHECK (VALUE IN ('Y', 'N', 'R'));

CREATE TABLE log (
    start timestamptz(0) NOT NULL,
    stop timestamptz(0),
    call call NOT NULL,
    cty cty REFERENCES country(cty),
    qrg numeric NOT NULL,
    qso_via call,
    mode text NOT NULL,
    rsttx text,
    rstrx text,
    qsltx character(1) CHECK (qsltx IN ('N', 'R', 'Y')),
    qslrx character(1) CHECK (qslrx IN ('N', 'R', 'Y')),
    qsl_via call,
    name text,
    qth text,
    loc locator,
    dok text,
    contest text,
    comment text,
    mycall call DEFAULT 'DF7CB'::text NOT NULL,
    mytrx text,
    mypwr numeric,
    myqth text,
    myloc text,
    myant text,
    info jsonb,
    last_update timestamptz(0) DEFAULT now(),
    PRIMARY KEY (start, call),
    CONSTRAINT start_before_stop CHECK (start <= stop),
    -- so far, all QSOs over an hour have been 1995 only
    CONSTRAINT qso_length CHECK (stop <= start + '1h'::interval OR start < '1996-01-01'),
    CONSTRAINT valid_band CHECK (band(qrg) IS NOT NULL)
);

COMMENT ON COLUMN log.qrg IS 'Frequency in MHz';

ALTER TABLE log CLUSTER ON log_pkey;
CREATE INDEX ON log (call);

\i logtrigger.sql

CREATE TRIGGER log_insert BEFORE INSERT ON log FOR EACH ROW EXECUTE PROCEDURE logtrigger();

CREATE OR REPLACE FUNCTION last_update() RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    NEW.last_update := now();
    RETURN NEW;
END;$$;

CREATE TRIGGER log_update BEFORE UPDATE ON log FOR EACH ROW EXECUTE PROCEDURE last_update();

GRANT SELECT ON TABLE log TO PUBLIC;

CREATE OR REPLACE VIEW logview AS
    SELECT start, stop::time, call, cty, band(qrg), qrg, mode, rsttx, rstrx, qsltx ||'/'|| qslrx AS qsl, name, qth, loc, dok, contest, comment, mycall, mytrx, mypwr, myqth, myloc, myant FROM log;

GRANT SELECT ON TABLE logview TO PUBLIC;

CREATE TABLE log2 (LIKE log INCLUDING ALL);
CREATE TRIGGER log_insert BEFORE INSERT ON log2 FOR EACH ROW EXECUTE PROCEDURE logtrigger();
GRANT SELECT ON TABLE log2 TO PUBLIC;

CREATE TABLE livelog (LIKE log INCLUDING ALL);
CREATE TRIGGER log_insert BEFORE INSERT ON livelog FOR EACH ROW EXECUTE PROCEDURE logtrigger();
GRANT SELECT ON TABLE livelog TO PUBLIC;

CREATE VIEW alllog AS SELECT * FROM log UNION ALL SELECT * FROM livelog;
GRANT SELECT ON alllog TO PUBLIC;
