import re, sys, collections
# Generate C JNI stubs (return 0/NULL) for every native method in a `javap -s -p` dump.
txt = open(sys.argv[1]).read()
cls = None; natives = []   # (class, name, desc, static)
for line in txt.split('\n'):
    m = re.match(r'^(?:public |final |abstract )*(?:class|interface) ([\w.$]+)', line)
    if m: cls = m.group(1); continue
    m = re.match(r'^\s+.*\bnative\b.*\b([A-Za-z_$][\w$]*)\(', line)
    if m: pending = (m.group(1), ' static ' in line + ' '); continue
    m = re.match(r'^\s+descriptor: (\(.*\).*)$', line)
    if m and 'pending' in dir() and pending:
        natives.append((cls, pending[0], m.group(1), pending[1])); pending = None
def mangle(s):
    out = []
    for ch in s:
        if ch == '/': out.append('_')
        elif ch == '_': out.append('_1')
        elif ch == ';': out.append('_2')
        elif ch == '[': out.append('_3')
        elif ch.isalnum(): out.append(ch)
        else: out.append('_0%04x' % ord(ch))
    return ''.join(out)
def ctype(d):
    return {'V':'void','Z':'jboolean','B':'jbyte','C':'jchar','S':'jshort','I':'jint','J':'jlong','F':'jfloat','D':'jdouble'}.get(d[0], 'jobject')
def params(desc):
    inner = desc[1:desc.index(')')]; out = []; i = 0
    while i < len(inner):
        j = i
        while inner[j] == '[': j += 1
        if inner[j] == 'L': k = inner.index(';', j); out.append(inner[i:k+1]); i = k+1
        else: out.append(inner[i:j+1]); i = j+1
    return out
counts = collections.Counter((c, n) for c, n, d, s in natives)
seen = set(); lines = ['#include <jni.h>', '/* Generated ARM64 null-engine stubs: every TAK kernel JNI entry point, returning 0/NULL. */']
for c, n, d, st in natives:
    jc = c.replace('.', '/')
    sym = 'Java_' + mangle(jc) + '_' + mangle(n)
    if counts[(c, n)] > 1: sym += '__' + mangle(d[1:d.index(')')])
    if sym in seen: continue
    seen.add(sym)
    ret = ctype(d[d.index(')')+1:])
    ps = ['JNIEnv *env', 'jclass clazz' if st else 'jobject self'] + ['%s a%d' % (ctype(p), i) for i, p in enumerate(params(d))]
    body = '' if ret == 'void' else ' return 0;'
    lines.append('JNIEXPORT %s JNICALL %s(%s) {%s }' % (ret, sym, ', '.join(ps), body))
open(sys.argv[2], 'w').write('\n'.join(lines) + '\n')
print("native methods parsed:", len(natives), " unique symbols:", len(seen), " overloaded names:", sum(1 for k, v in counts.items() if v > 1))
