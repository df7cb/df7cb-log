#!/usr/bin/python3

import psycopg2
import sys

name = sys.argv[1]

conn = psycopg2.connect(f"service=cb application_name={name}")
cur = conn.cursor()

# 220111_212215  2400.040 Rx FT8      2  0.8 1136 CQ DL5AKF JO50

for line in sys.stdin:
    fields = line.strip().split(None, 7)
    if '.' in fields[0]: continue # bad format from old wsjtx version
    print(fields)
    try:
        cur.execute("insert into all_txt values(%s, %s, %s, %s, %s, %s, %s, %s) on conflict do nothing", fields)
        conn.commit()
    except Exception as e:
        print(e)
        conn.rollback()

