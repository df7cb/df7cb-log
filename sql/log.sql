CREATE DOMAIN qsl AS char(1)
    CONSTRAINT valid_qsl_request CHECK (VALUE IN ('Y', 'N', 'R'));

CREATE TABLE log (
    start timestamptz(0) NOT NULL,
    stop timestamptz(0),
    call call NOT NULL,
    cty cty REFERENCES country(cty),
    qrg qrg NOT NULL,
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
    cq smallint,
    itu smallint,
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

CREATE OR REPLACE VIEW alllog AS SELECT * FROM log UNION ALL SELECT * FROM livelog;
GRANT SELECT ON alllog TO PUBLIC;
