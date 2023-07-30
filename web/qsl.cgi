#!/usr/bin/python3

import cgi
import cgitb
from tempfile import TemporaryFile
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
import qsl
import sys

form = cgi.FieldStorage()

if not 'call' in form:
    print("Status: 500 Parameter missing")
    print()
    print(f"CGI parameter 'call' missing")
    exit(0)
call = form.getvalue('call').upper()

mycall = form.getvalue('mycall') or "DF7CB"

f = TemporaryFile()
c = canvas.Canvas(f, pagesize=(140*mm, 90*mm))
c.setTitle(f"{mycall} QSL for {call}")
qsl.qsl(c, call, mycall)

c.showPage()
c.save()

filename = f"{mycall}-{call}.pdf".replace('/', '-')
print("Content-Type: application/pdf")
print(f"Content-Disposition: inline; filename=\"{filename}\"")
print()
sys.stdout.flush()
f.seek(0)
sys.stdout.buffer.write(f.read())
