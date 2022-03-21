#!/bin/sh

set -eu

name="${1:-ALL.TXT}"

tail -n 100 -f $name | ./all_txt.py $name
