--
-- PostgreSQL database dump
--

CREATE DOMAIN call AS text
	CONSTRAINT valid_callsign CHECK ((VALUE ~ '^[A-Z0-9]+([/-][A-Z0-9]+)*$'::text));

CREATE TABLE log (
    start timestamp with time zone NOT NULL,
    stop timestamp with time zone,
    call call NOT NULL,
    qrg real NOT NULL,
    mode text NOT NULL,
    rsttx text,
    rstrx text,
    qsltx character(1) DEFAULT 'N'::bpchar NOT NULL,
    qslrx character(1) DEFAULT 'N'::bpchar NOT NULL,
    name text,
    qth text,
    loc text,
    dok text,
    bemerkung text,
    mycall call DEFAULT 'DF7CB'::text NOT NULL,
    mytrx text,
    mypwr real,
    myqth text DEFAULT 'Krefeld'::text,
    myloc text DEFAULT 'JO31HI'::text,
    myant text,
    CONSTRAINT start_before_stop CHECK ((start <= stop)),
    CONSTRAINT valid_qrg CHECK (((qrg >= (0.1)::double precision) AND (qrg <= (2500)::double precision)))
);

COMMENT ON COLUMN log.qrg IS 'Frequency in MHz';

ALTER TABLE ONLY log
    ADD CONSTRAINT log_pkey PRIMARY KEY (start, call);

ALTER TABLE log CLUSTER ON log_pkey;

CREATE OR REPLACE FUNCTION logtrigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
  IF NEW.qrg < 30 THEN
    IF NEW.mode IS NULL THEN NEW.mode := 'CW'; END IF;
    IF NEW.mytrx IS NULL THEN NEW.mytrx := 'IC706'; END IF;
    IF NEW.myant IS NULL THEN NEW.myant := 'Windom'; END IF;
  END IF;
  RETURN NEW;
END;$$;

CREATE TRIGGER log_insert BEFORE INSERT ON log FOR EACH ROW EXECUTE PROCEDURE logtrigger();

GRANT SELECT ON TABLE log TO PUBLIC;
