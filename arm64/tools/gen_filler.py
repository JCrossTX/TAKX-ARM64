import re, sys, collections, subprocess
# Usage: gen_filler.py <kernel-javap.txt> <real-jni-lib.so> <out.c>
# Emits C stubs only for the JNI symbols TAKX's kernel jars require that the real library does not export.
javap_txt, lib, out = sys.argv[1], sys.argv[2], sys.argv[3]
exported = set()
for line in subprocess.run(['nm', '-D', '--defined-only', lib], capture_output=True, text=True).stdout.splitlines():
    parts = line.split()
    if len(parts) >= 3 and parts[1] in ('T', 'W'): exported.add(parts[2])

cls = None; natives = []; pending = None
for line in open(javap_txt).read().split('\n'):
    m = re.match(r'^(?:public |final |abstract )*(?:class|interface) ([\w.$]+)', line)
    if m: cls = m.group(1); continue
    m = re.match(r'^\s+.*\bnative\b.*\b([A-Za-z_$][\w$]*)\(', line)
    if m: pending = (m.group(1), ' static ' in line + ' '); continue
    m = re.match(r'^\s+descriptor: (\(.*\).*)$', line)
    if m and pending:
        natives.append((cls, pending[0], m.group(1), pending[1])); pending = None

def mangle(s):
    o = []
    for ch in s:
        if ch == '/': o.append('_')
        elif ch == '_': o.append('_1')
        elif ch == ';': o.append('_2')
        elif ch == '[': o.append('_3')
        elif ch.isalnum(): o.append(ch)
        else: o.append('_0%04x' % ord(ch))
    return ''.join(o)
def ctype(d): return {'V':'void','Z':'jboolean','B':'jbyte','C':'jchar','S':'jshort','I':'jint','J':'jlong','F':'jfloat','D':'jdouble'}.get(d[0], 'jobject')
def params(desc):
    inner = desc[1:desc.index(')')]; o = []; i = 0
    while i < len(inner):
        j = i
        while inner[j] == '[': j += 1
        if inner[j] == 'L': k = inner.index(';', j); o.append(inner[i:k+1]); i = k+1
        else: o.append(inner[i:j+1]); i = j+1
    return o
counts = collections.Counter((c, n) for c, n, d, s in natives)
lines = ['#include <jni.h>', '/* Filler stubs: TAKX 9.11.5 kernel natives absent from the ARM64 engine build (return 0/NULL). */']
missing = []; seen = set()
for c, n, d, st in natives:
    jc = c.replace('.', '/'); shortsym = 'Java_' + mangle(jc) + '_' + mangle(n)
    longsym = shortsym + '__' + mangle(d[1:d.index(')')])
    # JVM resolves short name first, then long; it is satisfied if either is exported
    if shortsym in exported or longsym in exported: continue
    sym = longsym if counts[(c, n)] > 1 else shortsym
    if sym in seen: continue
    seen.add(sym); missing.append(sym)
    ret = ctype(d[d.index(')')+1:])
    ps = ['JNIEnv *env', 'jclass clazz' if st else 'jobject self'] + ['%s a%d' % (ctype(p), i) for i, p in enumerate(params(d))]
    lines.append('JNIEXPORT %s JNICALL %s(%s) {%s }' % (ret, sym, ', '.join(ps), '' if ret == 'void' else ' return 0;'))
open(out, 'w').write('\n'.join(lines) + '\n')
byc = collections.Counter(re.sub(r'_[^_]+$', '', s.split('__')[0]) for s in missing)
print("required:", len(natives), " exported by real lib:", len(exported), " fillers:", len(missing))
for c, k in byc.most_common(15): print("%5d  %s" % (k, c))
