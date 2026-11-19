import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
def leaf(o):
    # java.io.File / Enum / ScriptProperty / ExternalFile -> readable
    c = o.get('class','')
    if c in ('java.io.File','java.lang.Enum'):
        s = o.find('string'); 
        return (s.text if s is not None else '?')
    if c.endswith('ScriptProperty'):
        for v in o.findall('void'):
            if v.get('property')=='value':
                s=v.find('string'); return 'SCRIPT{ ' + (s.text or '').strip() + ' }'
    if c.endswith('ExternalFile'):
        s=o.find('string'); return 'EXT:'+(s.text if s is not None else '?')
    return '<%s>' % c
for a in root.iter('action'):
    o = None
    for oo in a.iter('object'):
        o = oo; break
    if o is None: continue
    cls = o.get('class','').split('.')[-1]
    cond = a.get('conditionClass','')
    print('== action id=%s %s%s' % (a.get('id'), cls, ' [conditional]' if cond else ''))
    for v in o.findall('void'):
        p = v.get('property'); kids=list(v)
        if not p or len(kids)!=1: continue
        k = kids[0]
        if k.tag == 'object': val = leaf(k)
        elif k.tag == 'array':
            vals=[]
            for vv in k.iter():
                if vv.tag=='string' and vv.text: vals.append(vv.text)
            val = '[' + ', '.join(vals) + ']'
        else: val = k.text or ''
        if p in ('script','fileFilter','directoryFilter','file','executable','workingDirectory','destinationFile','destinationDirectory','zipFile','archiveFile','arguments','files','variableName','text','linuxPrivilegeRequirement','unixIconFile','startIn','name','vmOptions','searchValue','replaceValue','returnCodeVariable','timeout'):
            val = val.replace('\n', '\n          ')
            print('   %s = %s' % (p, val[:3000]))
