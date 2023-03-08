# ADIF exporter
# (C) 2023 Christoph Berg DF7CB
# License: MIT

adif_ver = '3.1.4'

def encode(key, value):
    if value == None or value == "":
        return ""

    l = len(str(value))
    return f"<{key}:{l}>{str(value)}\n"

def write(qsos, path):
    with open(path, mode="w") as f:
        f.write("Amateur radio log file\n\n")
        f.write(encode('adif_ver', adif_ver))
        f.write("<eoh>\n")

        for qso in qsos:
            f.write("\n")
            for field in qso.keys():
                f.write(encode(field, qso[field]))
            f.write("<eor>\n")

if __name__ == "__main__":
    write([{"station_callsign": "DF7CB", "call": "DA0RR", "freq": 7.150}], '/dev/stdout')
