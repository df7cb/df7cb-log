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

(qslwidth, qslheight) = (140*mm, 90*mm)
qslmargin = 2*mm

def qsl(c, call, mycall="DF7CB"):
    # background picture
    height = 90*mm
    width = height * 1778/1000 # keep aspect ratio
    c.setFillAlpha(0.5)
    c.drawImage('traarer_muehle_r.jpg', 0*mm, 0*mm, width=width, height=height)
    c.setFillAlpha(1.0)

    # QSO table
    cur.execute("""SELECT
            mycall,
            call,
            regexp_replace(call collate "C", '0', 'Ø', 'g') AS call_formatted,
            regexp_replace(date_trunc('minute', start::timestamp)::text, ':00$', '') AS start,
            start::date AS qso_date,
            regexp_replace(date_trunc('minute', start::time)::text, ':00$', '') AS time_on,
            concat_ws(E'\n',
              round(qrg, 3),
              'via ' || qso_via) as freq,
            concat_ws('/', mode, submode) as mode,
            concat_ws(' ', rsttx, extx) as rsttx,
            concat_ws(' ', rstrx, exrx) as rstrx,
            concat_ws(E'\n',
              nullif(concat_ws(', ',
                nullif(mycall, 'DF7CB'),
                nullif(myqth, 'Krefeld'),
                nullif(upper(myloc), 'JO31HI')
              ), ''),
              nullif(concat_ws(', ',
                mytrx,
                mypwr || ' W',
                myant
              ), '')
            ) AS mystn,
            CASE WHEN qslrx = 'Y' OR lotw IS NOT NULL or qslid IS NOT NULL THEN 'TNX'
            ELSE 'PSE' END AS qsl_rcvd
            FROM log
            WHERE call = %s AND mycall = %s
            ORDER BY start, call""", (call, mycall))

    qsos = [['Confirming our QSO\nDate',
             'Freq\nMHz', 'Mode\n2-way',
             'RST\nsent', 'RST\nrcvd',
             'My Station\nTrx, Power, Ant',
             'QSL',
            ]]
    adif = "OPERATOR;QSO_DATE;TIME_ON;FREQ;MODE;RST_SENT;QSL_RCVD;"

    call_formatted = ''
    for qso in cur.fetchall():
        call_formatted = qso['call_formatted']
        qsos.append([qso['start'], qso['freq'], qso['mode'],
                     qso['rsttx'], qso['rstrx'],
                     qso['mystn'],
                     qso['qsl_rcvd'],
                    ])
        adif += "\n%s;%s;%s;%s;%s;%s;%s;" % \
                (qso['mycall'],
                qso['qso_date'], qso['time_on'],
                qso['freq'], qso['mode'],
                qso['rsttx'],
                qso['qsl_rcvd'])

    t = Table(qsos)
    t.setStyle(TableStyle([
        # global
        ('RIGHTPADDING',  (0, 0), (-1, -1), 0),
        # header
        ('SIZE',          (0, 0), (-1, 0), 6),
        ('LEADING',       (0, 0), (-1, 0), 6),
        # body
        ('TOPPADDING',    (0, 1), (-1, -1), 0),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 0),
        ('SIZE',          (0, 1), (-1, -1), 8),
        ('LEADING',       (0, 1), (-1, -1), 9),
        ('VALIGN',        (0, 1), (-1, -1), 'TOP'),
      ]))

    w, h = t.wrap(100*mm, 30*mm)
    t.drawOn(c, 0*mm, 29*mm - h)

    qrsize = 27*mm
    qrw = QrCodeWidget(adif, barBorder=0, barLevel='L')
    b = qrw.getBounds()
    (w, h) = (b[2] - b[0], b[3] - b[1])
    d = Drawing(qrsize, qrsize, transform=[qrsize/w,0,0,qrsize/h,0,0])
    d.add(qrw)
    renderPDF.draw(d, c, qslwidth - qslmargin - qrsize, qslmargin)

    # picture
    height = 60*mm
    width = height * 768/996 # keep aspect ratio
    c.drawImage('traarer_muehle.png', 10*mm, 29*mm, width=width, height=height,
            mask=[255,256, 255,256, 255,256])
    c.saveState()
    c.setFont("Helvetica", 5)
    c.rotate(90)
    c.drawString(30*mm, -3.5*mm, "Picture (C) Julia Berg")
    c.restoreState()

    # recipient
    qrsize = 11*mm
    c.rect(70*mm, 77*mm, qslwidth - 2*qslmargin - 70*mm - qrsize, 11*mm)
    c.setFont("Helvetica", 14)
    c.drawString(71.3*mm, 79*mm, "to")
    c.setFont("Helvetica", 28)
    c.drawString(77*mm, 79*mm, call_formatted)

    qrtext = "TO:%s\nVIA:%s\nFRM:%s" % (call, "", mycall)
    qrw = QrCodeWidget(qrtext, barBorder=0, barLevel='L')
    b = qrw.getBounds()
    (w, h) = (b[2] - b[0], b[3] - b[1])
    d = Drawing(qrsize, qrsize, transform=[qrsize/w,0,0,qrsize/h,0,0])
    d.add(qrw)
    renderPDF.draw(d, c, qslwidth - qslmargin - qrsize, qslheight - qslmargin - qrsize)

    # myself
    c.setFont("Helvetica", 33)
    c.drawString(69.5*mm, 66*mm, mycall)

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
        DARC DOK R10
        Rhein Ruhr DX Association
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
