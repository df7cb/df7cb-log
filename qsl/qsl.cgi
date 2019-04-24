#!/usr/bin/python3

import os
from tempfile import TemporaryFile
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
import qsl

call = os.getenv('QUERY_STRING')
f = TemporaryFile()
c = canvas.Canvas(f, pagesize=(140*mm, 90*mm))
c.setTitle("DF7CB QSL for %s" % call)
qsl.qsl(c, call)

c.showPage()
c.save()

print("Content-Type: application/pdf\n")
f.seek(0)
for line in f:
    print(line.decode('latin1'), end='')
