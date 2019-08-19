CREATE TABLE swl (
    start timestamp with time zone NOT NULL,
    stop timestamp with time zone,
    call text NOT NULL,
    cty cty REFERENCES country(cty),
    qrg numeric NOT NULL,
    mode text NOT NULL,
    rsttx text,
    rstrx text,
    qsltx character(1) DEFAULT 'N'::bpchar NOT NULL,
    qslrx character(1) DEFAULT 'N'::bpchar NOT NULL,
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
    PRIMARY KEY (start, call),
    CONSTRAINT start_before_stop CHECK (start <= stop),
    CONSTRAINT valid_band CHECK (band(qrg) IS NOT NULL)
);

COMMENT ON COLUMN swl.qrg IS 'Frequency in MHz';
