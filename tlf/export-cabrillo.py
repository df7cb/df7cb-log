#!/usr/bin/python3

# usage: export-cabrillo <contest name> <filename>

import pyqso.cabrillo
import psycopg2
import psycopg2.extras
import sys

conn = psycopg2.connect("service=cb")
cur = conn.cursor(cursor_factory = psycopg2.extras.DictCursor)

contest = sys.argv[1]
filename = sys.argv[2]

cur.execute("""SELECT qrg AS "FREQ",
        mode AS "MODE",
        to_char(start, 'YYYYMMDD') AS "QSO_DATE",
        to_char(start, 'hh24mi') AS "TIME_ON",
        regexp_replace(rsttx, '^(5[1-9]9?)', '\\1 ') AS "RST_SENT",
        regexp_replace(rstrx, '^(5[1-9]9?)', '\\1 ') AS "RST_RCVD",
        call AS "CALL"
        FROM log
        WHERE start > now() - '3 days'::interval
        AND contest ~ %s
        ORDER BY start, call""",
        (contest,))

# {'CALL': 'DL3NCI', 'BAND': '80m', 'MODE': 'CW', 'QSO_DATE': '20021226', 'TIME_ON': '1050', 'RST_SENT': '', 'DARC_DOK': 'B25'}

records = cur.fetchall()
cabrillo = pyqso.cabrillo.Cabrillo()
cabrillo.write(records,
        filename,
        contest=contest,
        mycall='DF7CB')
