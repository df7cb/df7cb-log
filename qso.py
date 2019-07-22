#!/usr/bin/python3

import datetime
import psycopg2
import psycopg2.extras
import re
import sys

conn = psycopg2.connect("service=cb")
cur = conn.cursor(cursor_factory = psycopg2.extras.DictCursor)

date = datetime.datetime.now().strftime("%Y-%m-%d")
mode = 'CW'
rsttx = '599'
rst_serial = False

contest = None
if len(sys.argv) == 2:
    contest = sys.argv[1]
    print("Contest: %s" % contest)

select = "SELECT start, call, qrg, mode, rsttx, rstrx, qsltx, qslrx, contest FROM log WHERE call = %s"
insert = "INSERT INTO log (start, call, qrg, mode, rsttx, rstrx, qsltx, qslrx, contest) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)"

print("%s %s %s" % (date, mode, rsttx))
#print("log> ", end='', flush=True)

for line in sys.stdin:
    l = line.strip()
    (time, call, qrg, rstrx) = (None, None, None, None)
    (qsltx, qslrx) = ('N', 'N')
    for tok in l.split(" "):
        if re.search('^\d{4}-\d{2}-\d{2}$', tok):
            date = tok
        elif tok.upper() in ('CW', 'SSB', 'FT8'):
            mode = tok.upper()
        elif re.search('^\d{1,2}:\d{2}$', tok):
            time = tok
        elif re.search('^\d+\.\d+$', tok):
            qrg = tok
        elif re.search('^5\d', tok):
            if rstrx is None:
                rstrx = tok
            else:
                rsttx = rstrx
                rstrx = tok
                if rsttx == '599001':
                    rst_serial = True
        elif re.search('^[nNyYrR]{1,2}$', tok):
            qsltx = tok.upper()[0]
            if len(tok) > 1:
                qslrx = tok.upper()[1]
        elif tok == "commit":
            conn.commit()
        else:
            if call:
                print("Two calls on one line?")
                continue
            call = tok.upper()

    if time and call:
        args = ("%s %s" % (date, time), call, qrg, mode, rsttx, rstrx, qsltx, qslrx, contest)
        print(insert % args)
        cur.execute(insert, args)
    elif call:
        cur.execute(select, (call,))
        for rec in cur.fetchall():
            print(rec['start'], rec['call'], rec['qrg'], rec['mode'],
                  rec['rsttx'], rec['rstrx'],
                  rec['qsltx'], rec['qslrx'])

    if rst_serial:
        rsttx = str(int(rsttx) + 1)

    print("%s %s %s" % (date, mode, rsttx))
    #print("log> ", end='', flush=True)
