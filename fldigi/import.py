#!/usr/bin/python3

import adif
from sys import argv
import psycopg2

contest = argv[1]

adifreader = adif.ADIF()
adiflog = adifreader.read(argv[2])

# {'FREQ': '14.069245', 'CALL': 'R3WA', 'MODE': 'PSK63', 'QSO_DATE': '20200315', 'TIME_OFF': '114608', 'TIME_ON': '114500', 'RST_RCVD': '238', 'RST_SENT': '238', 'BAND': '20m', 'COUNTRY': 'European Russia', 'CQZ': '16', 'SRX': '239', 'STX': '000'}

log = []

for qso in adiflog:
    rec = {}
    rec['start'] = "%s %s" % (qso['QSO_DATE'], qso['TIME_ON'])
    rec['stop'] = "%s %s" % (qso['QSO_DATE'], qso['TIME_OFF'])
    rec['call'] = qso['CALL']
    rec['mode'] = qso['MODE']
    rec['qrg'] = qso['FREQ']
    rec['rsttx'] = "%s%s" % (qso['RST_SENT'], qso['STX'])
    rec['rstrx'] = "%s%s" % ("599", qso['SRX'])
    rec['contest'] = contest

    log.append(rec)
    print(rec)

input('Ok to upload?')

conn = psycopg2.connect("service=cb")
cur = conn.cursor()

for rec in log:
    insert = "INSERT INTO log (" + \
        ', '.join(rec.keys()) + \
        ') VALUES (' + \
        ', '.join(['%s' for x in rec]) + \
        ')'
    args = [x for x in rec.values()]
    cur.execute(insert, args)

conn.commit()
