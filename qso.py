#!/usr/bin/python3

import datetime
import psycopg2
import psycopg2.extras
import re
import sys

from pyhamtools import LookupLib, Callinfo
my_lookuplib = LookupLib(lookuptype="countryfile", filename="cty.plist")
cic = Callinfo(my_lookuplib)

conn = psycopg2.connect("service=cb")
cur = conn.cursor(cursor_factory = psycopg2.extras.DictCursor)

date = datetime.datetime.now().strftime("%Y-%m-%d")
mode = 'CW'
rsttx = '599'
auto_rst = None

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
            print("Date:", date)
        elif tok.upper() in ('CW', 'SSB', 'FT8'):
            mode = tok.upper()
            print("Mode:", mode)
        elif re.search('^\d{1,2}:\d{2}$', tok):
            time = tok
        elif re.search('^\d+\.\d+$', tok):
            qrg = tok

        # RST handling
        elif re.search('^5\d', tok):
            if time is None: # no time seen, probably a new default RST to send
                rsttx = tok.upper()
                if rsttx == '59914':
                    auto_rst = 'cqz'
                elif rsttx == '59928':
                    auto_rst = 'ituz'
                print("RST sent:", rsttx)
            elif rstrx is None: # else store as received RST
                rstrx = tok.upper()
            else: # if rstrx was already seen, move rstrx to tx, and store new as rx
                rsttx = rstrx
                rstrx = tok.upper()
            if rsttx == '599001': # enable automatic serial mode
                auto_rst = "serial"
        elif tok == "itumult":
            auto_rst = "ituz"
        elif tok == "cqmult":
            auto_rst = "cqz"

        # QSL sent/received handling
        elif re.search('^[nNyYrR]{1,2}$', tok):
            qsltx = tok.upper()[0]
            if len(tok) > 1:
                qslrx = tok.upper()[1]

        else:
            if call:
                print("Two calls on one line?")
                continue
            call = tok.upper()

    if time and call:
        if auto_rst in ('ituz', 'cqz') and not rstrx:
            try:
                info = cic.get_all(call)
                rstrx = '599' + str(info[auto_rst]).zfill(2)
            except KeyError:
                pass
        args = ("%s %s" % (date, time), call, qrg, mode, rsttx, rstrx, qsltx, qslrx, contest)
        print(args)
        cur.execute(insert, args)
        conn.commit()

        if auto_rst == "serial":
            rsttx = str(int(rsttx) + 1)

    elif call:
        cur.execute(select, (call,))
        for rec in cur.fetchall():
            print(rec['start'], rec['call'], rec['qrg'], rec['mode'],
                  rec['rsttx'], rec['rstrx'],
                  rec['qsltx'], rec['qslrx'])


    if auto_rst == "serial":
        print("%s %s %s" % (date, mode, rsttx))
    #print("log> ", end='', flush=True)
