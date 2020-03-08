-- {'CALL': 'YB1BML', 'BAND': '30m', 'FREQ': '10.13828', 'MODE': 'FT8', 'QSO_DATE': '20190302', 'TIME_ON': '161500', 'QSL_RCVD': 'Y', 'DXCC': '327', 'COUNTRY': 'INDONESIA', 'IOTA': 'OC-021', 'GRIDSQUARE': 'OI33KO', 'CQZ': '28', 'ITUZ': '54'}

CREATE TABLE lotw (
    start timestamptz,
    call call,
    qrg numeric,
    mode text,
    country text,
    loc locator,
    info jsonb,
    PRIMARY KEY (start, call)
);

/*
Two submitted descriptions of a QSO match if

    your QSO description specifies a callsign that matches the Callsign Certificate specified by the Station Location your QSO partner used to digitally sign the QSO
    your QSO partner's QSO description specifies a callsign that matches the Callsign Certificate specified by the Station Location you used to digitally sign the QSO
    both QSO descriptions specify start times within 30 minutes of each other
    both QSO descriptions specify the same band
    both QSO descriptions specify the same mode (an exact mode match), or must specify modes belonging to the same Mode Group
    for satellite QSOs, both QSO descriptions must specify the same satellite, and a propagation mode of SAT

https://lotw.arrl.org/lotw-help/frequently-asked-questions/?lang=en#datamatch
*/

/*
-- LotW join:
SELECT * FROM log l RIGHT JOIN lotw w ON (date_trunc('minute', l.start), l.call) = (w.start, w.call);

-- orphaned LotW entries:
SELECT * FROM log l RIGHT JOIN lotw w ON (date_trunc('minute', l.start), l.call) = (w.start, w.call) WHERE l.start IS NULL;

-- locator mismatch:
SELECT l.start, l.call, l.qrg, l.mode, l.loc, w.loc FROM log l JOIN lotw w ON (date_trunc('minute', l.start),l.call) = (w.start,w.call) WHERE l.loc::varchar(4) <> w.loc::varchar(4);
SELECT l.start, l.call, l.qrg, l.mode, l.loc, w.loc FROM log l JOIN lotw w ON (date_trunc('minute', l.start),l.call) = (w.start,w.call) WHERE l.loc::varchar(4) = w.loc::varchar(4) AND l.loc <> w.loc;

-- locator import:
UPDATE log l SET loc = w.loc FROM lotw w
  WHERE (date_trunc('minute', l.start), l.call) = (w.start, w.call)
    AND l.loc::varchar(4) = w.loc::varchar(4)
    AND l.loc <> w.loc;

-- IOTA import:
UPDATE log l SET info = jsonb_set(coalesce(l.info, '{}'), '{iota}', w.info->'IOTA') FROM lotw w
  WHERE (date_trunc('minute', l.start), l.call) = (w.start, w.call)
    AND l.info->'iota' IS DISTINCT FROM w.info->'IOTA';

*/
