-- {'CALL': 'YB1BML', 'BAND': '30m', 'FREQ': '10.13828', 'MODE': 'FT8', 'QSO_DATE': '20190302', 'TIME_ON': '161500', 'QSL_RCVD': 'Y', 'DXCC': '327', 'COUNTRY': 'INDONESIA', 'IOTA': 'OC-021', 'GRIDSQUARE': 'OI33KO', 'CQZ': '28', 'ITUZ': '54'}

CREATE TABLE lotw (
    start timestamptz,
    call call,
    qrg numeric,
    mode text,
    country text,
    iota text,
    loc locator,
    cqz int,
    ituz int
);

/*
select * from log l join lotw w on (date_trunc('minute', l.start),l.call) = (w.start,w.call);

-- locator mismatch:
select * from log l join lotw w on (date_trunc('minute', l.start),l.call) = (w.start,w.call) where l.loc::varchar(4) <> w.loc::varchar(4);

*/
