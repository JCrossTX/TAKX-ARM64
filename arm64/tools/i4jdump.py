import sys, xml.etree.ElementTree as ET
path = sys.argv[1]
root = ET.parse(path).getroot()
SIMPLE = {'string','int','boolean','long','double'}
def props(obj):
    out = {}
    for v in obj.findall('void'):
        p = v.get('property')
        if not p: continue
        kids = list(v)
        if len(kids)==1 and kids[0].tag in SIMPLE:
            out[p] = (kids[0].text or '')
        elif len(kids)==1 and kids[0].tag=='array':
            vals=[]
            for vv in kids[0].iter():
                if vv.tag in SIMPLE and vv.text: vals.append(vv.text)
            out[p] = '[' + ', '.join(vals[:12]) + (' ...' if len(vals)>12 else '') + ']'
        elif len(kids)==1 and kids[0].tag=='object':
            out[p] = '<%s>' % kids[0].get('class','')
    return out
def bean(el):
    for o in el.iter('object'):
        return o
    return None
want = sys.argv[2:] or ['screen','action','formComponent','launcher','component']
for el in root.iter():
    if el.tag not in want: continue
    o = bean(el)
    cls = o.get('class','') if o is not None else ''
    print('== %s id=%s name=%s class=%s' % (el.tag, el.get('id'), el.get('name') or el.get('beanName') or '', cls.split('.')[-1]))
    if o is not None:
        for k,v in props(o).items():
            v = v.replace('\n',' ⏎ ')
            if len(v) > 400: v = v[:400] + ' ...'
            print('     %s = %s' % (k, v))
