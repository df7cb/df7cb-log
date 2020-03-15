#  Copyright 2019 Andreas Krüger, DJ3EI
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# This is an ADIF parser in Python.

# It knows nothing about ADIF data types or enumerations,
# everything is a string, so it is fairly simple.

# But it does correcly handle things like:
# <notes:66>In this QSO, we discussed ADIF and in particular the <eor> marker.
# So, in that sense, this parser is somewhat sophisticated.

# Main result of parsing: List of QSOs.
# Each QSO is one Python dict.
# Keys in that dict are ADIF field names in upper case,
# value for a key is whatever was found in the ADIF, as a string.
# Order of QSOs in the list is same as in ADIF file.

from datetime import datetime, timedelta, timezone
import re

class AdifException(Exception):
    """Base exception."""
    pass

class AdifHeaderWithoutEOH(AdifException):
    """Exception for header found, not terminated with <EOH>"""
    pass

def read_from_string(adif_string):
    # The ADIF file header keys and values, if any.
    adif_headers = {}
    
    header_field_re = re.compile(r'<((eoh)|(\w+)\:(\d+)(\:[^>]+)?)>', re.IGNORECASE)
    field_re = re.compile(r'<((eor)|(\w+)\:(\d+)(\:[^>]+)?)>', re.IGNORECASE)
    
    qsos = []
    cursor = 0
    if adif_string[0] != '<':
        # Input has ADIF header. Read all header fields.
        eoh_found = False
        while(not eoh_found):
            header_field_mo = header_field_re.search(adif_string, cursor)
            if header_field_mo:
                if header_field_mo.group(2):
                    eoh_found = True
                    cursor = header_field_mo.end(0)
                else:
                    field = header_field_mo.group(3).upper()
                    value_start = header_field_mo.end(0)
                    value_end = value_start + int(header_field_mo.group(4))
                    value = adif_string[value_start:value_end]
                    adif_headers[field] = value
                    cursor = value_end
            else:
                raise AdifHeaderWithoutEOF()
                
        
    qso = {}
    field_mo = field_re.search(adif_string, cursor)
    while(field_mo):
        if field_mo.group(2):
            # <eor> found:
            qsos.append(qso)
            qso = {}
            cursor = field_mo.end(0)
        else:
            # Field found:
            field = field_mo.group(3).upper()
            value_start = field_mo.end(0)
            value_end = value_start + int(field_mo.group(4))
            value = adif_string[value_start:value_end]
            qso[field] = value
            cursor = value_end
        field_mo = field_re.search(adif_string, cursor)

    return [qsos, adif_headers]

def read_from_file(filename):
    
    with open(filename) as adif_file:
        adif_string = adif_file.read()
        return read_from_string(adif_string)

_one_day = timedelta(days=1)
    
def time_on(qso):
    date = qso['QSO_DATE']
    y = int(date[0:4])
    mo = int(date[4:6])
    d = int(date[6:8])
    time = qso['TIME_ON']
    h = int(time[0:2])
    mi = int(time[2:4])
    s = int(time[4:6]) if len(time) == 6 else 0
    return datetime(y, mo, d, h, mi, s, tzinfo = timezone.utc)

def time_off(qso):
    if "QSO_DATE_OFF" in qso:
        date = qso['QSO_DATE_OFF']
        y = int(date[0:4])
        mo = int(date[4:6])
        d = int(date[6:8])
        time = qso['TIME_OFF']
        h = int(time[0:2])
        mi = int(time[2:4])
        s = int(time[4:6]) if len(time) == 6 else 0
        return datetime(y, mo, d, h, mi, s, tzinfo = timezone.utc)
    else:
        date = qso['QSO_DATE']
        y = int(date[0:4])
        mo = int(date[4:6])
        d = int(date[6:8])
        time = qso['TIME_OFF']
        h = int(time[0:2])
        mi = int(time[2:4])
        s = int(time[4:6]) if len(time) == 6 else 0
        time_off_maybe = datetime(y, mo, d, h, mi, s, tzinfo = timezone.utc)
        if time_on(qso) < time_off_maybe:
            return time_off_maybe
        else:
            return time_off_maybe + _one_day
