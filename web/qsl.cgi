#!/usr/bin/python3

from tempfile import TemporaryFile
import os
import sys
import urllib

import qsl

form = {k: v for k, v in urllib.parse.parse_qsl(os.environ['QUERY_STRING'])}

if not 'call' in form:
    print("Status: 500 Parameter missing")
    print()
    print(f"CGI parameter 'call' missing")
    exit(0)
call = form['call'].upper()

mycall = form['mycall'] if 'mycall' in form else "DF7CB"

f = TemporaryFile()
qsos = qsl.qsl(f, call, mycall)

if not qsos:
    print("Status: 404 No QSOs found")
    print()
    print(f"Sorry, no QSOs between {call} and {mycall} found")
    exit(0)

filename = f"{mycall}-{call}.pdf".replace('/', '-')
print("Content-Type: application/pdf")
print(f"Content-Disposition: inline; filename=\"{filename}\"")
print()
sys.stdout.flush()
f.seek(0)
sys.stdout.buffer.write(f.read())
