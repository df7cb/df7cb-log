#!/usr/bin/python3

import cgi
import cgitb
import psycopg2
import re

conn = psycopg2.connect("dbname=cb")
cur = conn.cursor()

form = cgi.FieldStorage()

print("Content-Type: application/json")
print()

cur.execute("SELECT info::text FROM log_info")
print(cur.fetchone()[0])
