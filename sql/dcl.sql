-- {'CALL': 'YB1BML', 'BAND': '30m', 'FREQ': '10.13828', 'MODE': 'FT8', 'QSO_DATE': '20190302', 'TIME_ON': '161500', 'QSL_RCVD': 'Y', 'DXCC': '327', 'COUNTRY': 'INDONESIA', 'IOTA': 'OC-021', 'GRIDSQUARE': 'OI33KO', 'CQZ': '28', 'ITUZ': '54'}

CREATE TABLE dcl (
    start timestamptz,
    call call,
    qrg numeric,
    mode text,
    info jsonb,
    PRIMARY KEY (start, call)
);

/*
-- DCL join:
SELECT * FROM log l RIGHT JOIN dcl d ON (date_trunc('minute', l.start), l.call) = (d.start, d.call);

-- orphaned DCL entries:
SELECT d.* FROM log l RIGHT JOIN dcl d ON (date_trunc('minute', l.start), l.call) = (d.start, d.call) WHERE l.start IS NULL;

-- DOK mismatch:
SELECT l.start, l.call, l.qrg, l.mode, l.dok, d.info->>'DARC_DOK' FROM log l JOIN dcl d ON (date_trunc('minute', l.start),l.call) = (d.start, d.call) WHERE l.dok IS DISTINCT FROM d.info->>'DARC_DOK';
*/
