#!/bin/sh

# DJ8KZ	7	CW	599Q02	599K07	20001226 0933	K07	Blieskastel

psql -c 'TRUNCATE log2' service=cb
./dcl_import | psql -c "COPY log2 (call, qrg, mode, rsttx, rstrx, start, dok, myqth) FROM STDIN" service=cb
