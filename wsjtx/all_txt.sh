#!/bin/sh

set -eu

tail -n 100 -f ALL.TXT | ./all_txt.py
