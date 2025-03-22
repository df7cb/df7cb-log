#!/usr/bin/python3

import psycopg
from psycopg.rows import namedtuple_row
import re

conn = psycopg.connect("service=cb")
cur = conn.cursor(row_factory=namedtuple_row)

# QR-Code:From: DB0DH To: DF7CB
# Date: 30.05.21 Time: 12:18 Band: 10m Mode: CW RST: 599 QSL: PSE
# Date: 13.01.22 Time: 11:05 Band: 13cm Mode: FT8 Prop_Mode: SAT RST: -04 QSL: PSE SAT_NAME: QO-100

field_re = r"^(\S+): (?:([^ ]*[^: ])(?: |$))*" # key: words-not-ending-in-colon*

while True:
    l = input()
    print(l)

    if m := re.match(r"QR-Code:From: (.+) To: (.+)", l):
        call = m.group(1).upper()
        mycall = m.group(2).upper()
        print(call, mycall)
    elif l:
        qsl = {}
        while m := re.match(field_re, l):
            qsl[m.group(1).lower()] = m.group(2).strip()
            l = re.sub(field_re, '', l)
        print(qsl)

        if 'date' not in qsl: continue

        start = qsl['date'] + ' ' + qsl['time']
        cur.execute("""select * from log where
                        mycall = %s and call = %s and
                        start between (%s::timestamptz - '20min'::interval) and (%s::timestamptz + '20min'::interval) and
                        qrg::band = %s and
                        mode = %s""", [mycall, call, start, start, qsl['band'], qsl['mode']])

        if cur.rowcount == 0:
            print("not found")

        elif cur.rowcount > 1:
            print("found multiple")
            for row in cur.fetchall():
                print(f"QSO: {row.mycall} {row.start} {row.call} {row.qrg} {row.mode} {row.contest} {row.qsltx} {row.qslrx}")
            assert(0)

        else:
            row = cur.fetchone()
            print(f"QSO: {row.mycall} {row.start} {row.call} {row.qrg} {row.mode} {row.contest} {row.qsltx} {row.qslrx}")

            print("update log set qslrx = 'Y' where call = %s and start = %s" % (call, row.start))
            cur.execute("update log set qslrx = 'Y' where call = %s and start = %s", [call, row.start])
            if qsl['qsl'] == 'TNX':
                print("TNX QSL")
            elif qsl['qsl'] in ['PSE', '-I-']:
                print("PSE QSL")
                if row.qsltx != 'Y':
                    print("update log set qsltx = 'R' where call = %s and start = %s" % (call, row.start))
                    cur.execute("update log set qsltx = 'R' where call = %s and start = %s", [call, row.start])
            else: assert(0)
            conn.commit()


