import sys, re, os, collections
req_file, src_root = sys.argv[1], sys.argv[2]
required = set()
for line in open(req_file):
    cls, m = line.rstrip('\n').split('\t')
    if cls.startswith('org/gdal') or cls.startswith('jassimp'): continue   # from takthirdparty, not takkernel
    required.add((cls.split('$')[0], m))
avail = set()
pat = re.compile(r'\bnative\b[^;{]*?\b([A-Za-z_]\w*)\s*\(', re.S)
for root, _, files in os.walk(src_root):
    for f in files:
        if not f.endswith('.java'): continue
        p = os.path.join(root, f); txt = open(p, encoding='utf-8', errors='replace').read()
        pk = re.search(r'^\s*package\s+([\w.]+)\s*;', txt, re.M)
        outer = (pk.group(1).replace('.', '/') + '/' if pk else '') + f[:-5]
        for m in pat.finditer(txt): avail.add((outer, m.group(1)))
missing = required - avail
print("TAKX 9.11.5 kernel native methods (excluding GDAL/jassimp):", len(required))
print("provided by public source with same class+name:           ", len(required & avail))
print("MISSING in public source:                                  ", len(missing))
print("public natives not needed by TAKX:                         ", len(avail - required))
byc = collections.Counter(c for c, m in missing)
print("\nmissing, by class (top 25):")
for c, k in byc.most_common(25): print("%5d  %s" % (k, c))
