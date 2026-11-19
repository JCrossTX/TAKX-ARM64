import sys, zipfile, struct
def parse(data):
    off = 8; cp_count = struct.unpack('>H', data[off:off+2])[0]; off += 2
    cp = [None]*cp_count; i = 1
    while i < cp_count:
        tag = data[off]
        if tag == 1:
            ln = struct.unpack('>H', data[off+1:off+3])[0]; cp[i] = data[off+3:off+3+ln].decode('utf-8','replace'); off += 3+ln
        elif tag in (3,4): off += 5
        elif tag in (5,6): off += 9; i += 1
        elif tag in (7,8,16,19,20): off += 3
        elif tag in (9,10,11,12,17,18): off += 5
        elif tag == 15: off += 4
        else: raise ValueError(tag)
        i += 1
    off += 2; off += 4
    ifc = struct.unpack('>H', data[off:off+2])[0]; off += 2 + 2*ifc
    fields = struct.unpack('>H', data[off:off+2])[0]; off += 2
    for _ in range(fields):
        off += 6; ac = struct.unpack('>H', data[off:off+2])[0]; off += 2
        for _ in range(ac): off += 2; al = struct.unpack('>I', data[off:off+4])[0]; off += 4+al
    methods = struct.unpack('>H', data[off:off+2])[0]; off += 2
    out = []
    for _ in range(methods):
        acc, ni, di = struct.unpack('>HHH', data[off:off+6]); off += 6
        if acc & 0x0100: out.append(cp[ni])
        ac = struct.unpack('>H', data[off:off+2])[0]; off += 2
        for _ in range(ac): off += 2; al = struct.unpack('>I', data[off:off+4])[0]; off += 4+al
    return out
for jar in sys.argv[1:]:
    z = zipfile.ZipFile(jar)
    for n in z.namelist():
        if n.endswith('.class'):
            for m in parse(z.read(n)): print(n[:-6] + '\t' + m)
