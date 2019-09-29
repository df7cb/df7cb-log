#!/usr/bin/python3

import datetime
import psycopg2
import psycopg2.extras
import re
import sys

from pyhamtools import LookupLib, Callinfo

conn = psycopg2.connect("service=cb")
cur = conn.cursor(cursor_factory = psycopg2.extras.DictCursor)

date = datetime.datetime.now().strftime("%Y-%m-%d")
mode = 'CW'
rsttx = '599'
auto_rst = None
mycall = 'DF7CB'

contest = None
if len(sys.argv) == 2:
    contest = sys.argv[1]
    print("Contest: %s" % contest)

select = "SELECT start, call, qrg, mode, rsttx, rstrx, qsltx, qslrx FROM log WHERE call ~ %s"

while True:
    log = {
        'mode': mode,
        'rsttx': rsttx,
    }
    if contest:
        log['contest'] = contest
    if mycall:
        log['mycall'] = mycall

    prompt = "%s %s %s %s> " % (mycall, date, mode, rsttx)
    line = input(prompt)
    for tok in line.split(" "):
        # mode
        if tok.upper() in ('CW', 'FM', 'FT8', 'SSB'):
            mode = tok.upper()
            log['mode'] = mode
            if mode == 'FM':
                log['rsttx'] = '5'
                log['rstrx'] = '5'
        # date and time
        elif re.search('^\d{4}-\d{2}-\d{2}$', tok):
            date = tok
            print("Date:", date)
        elif re.search('^\d{1,2}:\d{2}$', tok):
            log['start'] = "%s %s" % (date, tok)
        elif re.search('^(\d{1,2}:\d{2})-(\d{1,2}:\d{2})$', tok):
            match = re.search('^(\d{1,2}:\d{2})-(\d{1,2}:\d{2})$', tok)
            log['start'] = "%s %s" % (date, match.group(1))
            log['stop'] = "%s %s" % (date, match.group(2))

        # QRG
        elif tok == "db0mg":
            log['qrg'] = "145.6125"
            log['qso_via'] = "DB0MG"
            log['mode'] = 'FM'
            log['rsttx'] = '5'
            log['rstrx'] = '5'

        elif re.search('^\d+(\.\d+)?$', tok):
            log['qrg'] = tok

        # RST handling
        elif re.search('^([45]\d*)/([45]\d*)$', tok):
            match = re.search('^([45]\d*)/([45]\d*)$', tok)
            log['rsttx'] = match.group(1)
            log['rstrx'] = match.group(2)
        elif re.search('^[45]\d', tok):
            log['rstrx'] = tok.upper()
        elif tok == "+":
            rsttx = str(int(rsttx) + 1)
            log['rsttx'] = rsttx
        elif tok == "-":
            rsttx = str(int(rsttx) - 1)
            log['rsttx'] = rsttx
        elif tok in ("serial", "ituz", "cqz"):
            auto_rst = tok
            if tok == "serial":
                tsttx = "599001"
            else:
                my_lookuplib = LookupLib(lookuptype="countryfile", filename="cty.plist")
                cic = Callinfo(my_lookuplib)

        # QSL sent/received handling
        elif re.search('^[nNyYrR]{1,2}$', tok):
            log['qsltx'] = tok.upper()[0]
            if len(tok) > 1:
                log['qslrx'] = tok.upper()[1]

        # mycall
        elif re.search('^/([mMpP])$', tok):
            match = re.search('^/([mMpP])$', tok)
            mycall = 'DF7CB/' + match.group(1).upper()
            log['mycall'] = mycall

        # mypwr
        elif re.search('^(\d+)[wW]$', tok):
            match = re.search('^(\d+)[wW]$', tok)
            log['mypwr'] = int(match.group(1))

        # generic fields
        elif re.search('^(.+?):(.*)', tok):
            match = re.search('^(.+?):(.*)', tok)
            log[match.group(1)] = match.group(2).replace('_', ' ')

        else:
            log['call'] = tok.upper()

    if 'start' in log and 'call' in log:
        if auto_rst in ('ituz', 'cqz') and not rstrx:
            try:
                info = cic.get_all(call)
                rstrx = '599' + str(info[auto_rst]).zfill(2)
            except KeyError:
                pass
        if 'rstrx' not in log and log['mode'] == 'CW':
            log['rstrx'] = '599'

        insert = "INSERT INTO log (" + \
            ', '.join(log.keys()) + \
            ') VALUES (' + \
            ', '.join(['%s' for x in log]) + \
            ')'
        args = [x for x in log.values()]
        print(insert, args)
        cur.execute(insert, args)
        conn.commit()

        if auto_rst == "serial":
            rsttx = str(int(rsttx) + 1)

    elif 'call' in log:
        cur.execute(select, (log['call'],))
        for rec in cur.fetchall():
            print(rec['start'], rec['call'], rec['qrg'], rec['mode'],
                  rec['rsttx'], rec['rstrx'],
                  rec['qsltx'], rec['qslrx'])
