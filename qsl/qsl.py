#!/usr/bin/python3

import psycopg2
import psycopg2.extras
from reportlab.lib.units import mm
from reportlab.platypus import Table, TableStyle
from reportlab.graphics.barcode.qr import QrCodeWidget
from reportlab.graphics.shapes import Drawing
from reportlab.graphics import renderPDF

conn = psycopg2.connect("service=cb")
cur = conn.cursor(cursor_factory = psycopg2.extras.DictCursor)

mycall = "DF7CB"
(qslwidth, qslheight) = (140*mm, 90*mm)
qslmargin = 3*mm

def qsl(c, call):
    # QSO table
    cur.execute("""SELECT
            regexp_replace(call, '0', 'Ø', 'g') AS call,
            regexp_replace(date_trunc('minute', start::timestamp)::text, ':00$', '') AS start,
            start::date AS qso_date,
            regexp_replace(date_trunc('minute', start::time)::text, ':00$', '') AS time_on,
            round(qrg, 3) AS freq,
            mode,
            rsttx, rstrx,
            mycall,
            mytrx || ', ' || mypwr || ' W, ' || myant AS mystn,
            CASE WHEN qslrx = 'J' THEN 'QSL rcvd, tnx!'
                 WHEN qslrx IN ('N', 'W') THEN 'Pse QSL'
                 ELSE qsltx || ' ' || qslrx
            END AS qsl,
            CASE WHEN qslrx = 'J' THEN 'TNX' ELSE 'PSE' END AS qsl_rcvd
            FROM log WHERE call = %s
            ORDER BY start, call""", (call,))

    qsos = [['Confirming our QSO\nDate',
             'Freq', 'Mode',
             'RST\nsent', 'RST\nrcvd',
             'My Trx, Power, Ant',
             'QSL',
            ]]
    adif = "OPERATOR;QSO_DATE;TIME_ON;FREQ;MODE;RST_SENT;QSL_RCVD;"

    call_formatted = ''
    for qso in cur.fetchall():
        mycall = qso['mycall']
        call_formatted = qso['call']
        qsos.append([qso['start'], qso['freq'], qso['mode'],
                     qso['rsttx'], qso['rstrx'],
                     qso['mystn'],
                     qso['qsl'],
                    ])
        adif += "\n%s;%s;%s;%s;%s;%s;%s;" % (qso['mycall'],
                qso['qso_date'], qso['time_on'],
                qso['freq'], qso['mode'],
                qso['rsttx'],
                qso['qsl_rcvd'])

    t = Table(qsos)
    t.setStyle(TableStyle([
        ('LEADING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
        ('SIZE', (0, 0), (-1, 0), 6),
        ('SIZE', (0, 1), (-1, -1), 8),
      ]))

    w, h = t.wrap(100*mm, 30*mm)
    t.drawOn(c, 0*mm, 29*mm - h)

    qrsize = 28*mm
    qrw = QrCodeWidget(adif, barBorder=0, barLevel='L')
    b = qrw.getBounds()
    (w, h) = (b[2] - b[0], b[3] - b[1])
    d = Drawing(qrsize, qrsize, transform=[qrsize/w,0,0,qrsize/h,0,0])
    d.add(qrw)
    renderPDF.draw(d, c, qslwidth - qslmargin - qrsize, qslmargin)

    # picture
    height = 60*mm
    width = height * 768/996 # keep aspect ratio
    c.drawImage('traarer_muehle.png', 10*mm, 29*mm, width=width, height=height)
    c.saveState()
    c.setFont("Helvetica", 5)
    c.rotate(90)
    c.drawString(30*mm, -3.5*mm, "Picture (c) Julia Berg")
    c.restoreState()

    # recipient
    qrsize = 11*mm
    c.rect(70*mm, 76*mm, qslwidth - 2*qslmargin - 70*mm - qrsize, 11*mm)
    c.setFont("Helvetica", 14)
    c.drawString(71.3*mm, 82.5*mm, "to")
    c.setFont("Helvetica", 33)
    c.drawString(78*mm, 77.5*mm, call_formatted)

    qrtext = "TO:%s\nVIA:%s\nFRM:%s" % (call, "", mycall)
    qrw = QrCodeWidget(qrtext, barBorder=0, barLevel='L')
    b = qrw.getBounds()
    (w, h) = (b[2] - b[0], b[3] - b[1])
    d = Drawing(qrsize, qrsize, transform=[qrsize/w,0,0,qrsize/h,0,0])
    d.add(qrw)
    renderPDF.draw(d, c, qslwidth - qslmargin - qrsize, qslheight - qslmargin - qrsize)

    # myself
    c.setFont("Helvetica", 33)
    c.drawString(69.5*mm, 65*mm, mycall)

    c.setFont("Helvetica", 14)
    c.drawString(70*mm, 60*mm, "Christoph Berg")

    c.setFont("Helvetica", 8)
    text = c.beginText()
    text.setTextOrigin(70*mm, 55*mm)
    text.textLines("""
        Born in 1977, Radio Amateur since 1994
        Debian and PostgreSQL Developer
        Open Source practitioner, Bridge player, Geocacher
        """)
    c.drawText(text)

    text = c.beginText()
    text.setTextOrigin(70*mm, 44*mm)
    text.textLines("""
        Rather Str. 76a
        47802 Krefeld-Traar
        Germany
        JO31HI
        """)
    c.drawText(text)

    text = c.beginText()
    text.setTextOrigin(100*mm, 44*mm)
    text.textLines("""
        cb@df7cb.de
        www.df7cb.de
        Twitter @df7cb
        DOK QØ2
        """)
    c.drawText(text)

if __name__ == "__main__":
    import sys
    from reportlab.pdfgen import canvas

    call = sys.argv[1]
    c = canvas.Canvas("qsl.pdf", pagesize=(qslwidth, qslheight))
    c.setTitle("%s QSL for %s" % (mycall, call))
    qsl(c, call)

    c.showPage()
    c.save()
