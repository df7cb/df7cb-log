#!/usr/bin/python3

import cgi
import cgitb
import psycopg2
import sys

conn = psycopg2.connect("dbname=cb")
cur = conn.cursor()

form = cgi.FieldStorage()

if 'qslid' in form:
    qslid = form.getvalue('qslid')
    cur.execute("select image from qslimage where qslid = %s", (qslid,))
    data = cur.fetchone()

    if data:
        print("Content-Type: image/jpeg")
        print()
        sys.stdout.flush()
        imgdata = bytes(data[0])
        sys.stdout.buffer.write(imgdata)

    else:
        print("Status: 404 Not found")
        print()
        print(f"QSL {qslid} not found.")

else:
    print("Status: 500 Parameter missing")
    print()
    print("Parameter qslid= missing.")
