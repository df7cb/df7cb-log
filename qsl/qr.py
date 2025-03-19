#!/usr/bin/python3

import psycopg
from psycopg.rows import namedtuple_row
import re

conn = psycopg.connect("service=cb")
cur = conn.cursor(row_factory=namedtuple_row)

# QR-Code:From: DB0DH To: DF7CB
# Date: 30.05.21 Time: 12:18 Band: 10m Mode: CW RST: 599 QSL: PSE
# Date: 13.01.22 Time: 11:05 Band: 13cm Mode: FT8 Prop_Mode: SAT RST: -04 QSL: PSE SAT_NAME: QO-100

while True:
    l = input()
    print(l)

    if m := re.match(r"QR-Code:From: (.+) To: (.+)", l):
        call = m.group(1)
        mycall = m.group(2)
        print(call, mycall)
    elif m := re.match(r"Date: (?P<date>[\d.]+) Time: (?P<time>[\d:]+) Band: (?P<band>\S+) Mode: (?P<mode>\S+) (?:Prop_Mode: (?P<prop_mode>\S+) )?RST: \S+ QSL: (?P<qsl>\S+)", l):
        time = m.group('date') + ' ' + m.group('time')
        print(m.groups())

        cur.execute("""select * from log where
                        mycall = %s and call = %s and
                        start between (%s::timestamptz - '20min'::interval) and (%s::timestamptz + '20min'::interval) and
                        qrg::band = %s and
                        mode = %s""", [mycall, call, time, time, m.group('band'), m.group('mode')])

        if cur.rowcount == 0:
            print("not found")
        elif cur.rowcount > 1:
            print("found multiple")
            for row in cur.fetchall():
                print(row)
        else:
            row = cur.fetchone()
            print(row)
            print("update log set qslrx = 'Y' where call = %s and start = %s" % (call, row.start))
            cur.execute("update log set qslrx = 'Y' where call = %s and start = %s", [call, row.start])
            if m.group('qsl') == 'TNX':
                print("TNX QSL")
            elif m.group('qsl') == 'PSE':
                print("PSE QSL")
                if row.qsltx != 'Y':
                    print("update log set qsltx = 'R' where call = %s and start = %s" % (call, row.start))
                    cur.execute("update log set qsltx = 'R' where call = %s and start = %s", [call, row.start])
            else: assert(0)
            conn.commit()


