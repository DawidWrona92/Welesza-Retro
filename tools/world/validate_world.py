#!/usr/bin/env python3
"""Static planner-model validator for Welesza. No engine, collision or streaming checks.
Usage: python3 tools/world/validate_world.py docs/world/world-layout.v0.2.json
       python3 tools/world/validate_world.py ... --json
Python 3.9+; stdlib only. Nonzero exit on any ERROR.
"""
import argparse
import collections
import json
import math
from pathlib import Path
import sys

EPS = 1e-8

def inside_bounds(point, bounds):
    x,y=point; x0,y0,w,h=bounds
    return x0-EPS<=x<=x0+w+EPS and y0-EPS<=y<=y0+h+EPS

def point_sector(point, sectors):
    """Half-open cells (right/bottom excluded); outer max included only in last row/col."""
    x,y=point
    maxx=max(s['rect'][0]+s['rect'][2] for s in sectors)
    maxy=max(s['rect'][1]+s['rect'][3] for s in sectors)
    result=[]
    for s in sectors:
        l,t,w,h=s['rect']
        if l-EPS<=x and t-EPS<=y and (x<l+w-EPS or abs(x-maxx)<=EPS and abs(l+w-maxx)<=EPS) and (y<t+h-EPS or abs(y-maxy)<=EPS and abs(t+h-maxy)<=EPS):
            result.append(s['id'])
    return result

def touched_sectors(polyline, sectors):
    """Ordered unique half-open sector ownership along a 2D polyline, including endpoints."""
    seen=[]
    def add(p):
        for s in point_sector(p,sectors):
            if s not in seen:seen.append(s)
    if not polyline:return seen
    add(polyline[0])
    lines_x=sorted(set(s['rect'][0] for s in sectors)|set(s['rect'][0]+s['rect'][2] for s in sectors))
    lines_y=sorted(set(s['rect'][1] for s in sectors)|set(s['rect'][1]+s['rect'][3] for s in sectors))
    for a,b in zip(polyline,polyline[1:]):
        dx=b[0]-a[0];dy=b[1]-a[1];ts=[0.0,1.0]
        if abs(dx)>EPS:ts += [(u-a[0])/dx for u in lines_x if EPS<(u-a[0])/dx<1-EPS]
        if abs(dy)>EPS:ts += [(u-a[1])/dy for u in lines_y if EPS<(u-a[1])/dy<1-EPS]
        ts=sorted(set(round(v,12) for v in ts))
        for aa,bb in zip(ts,ts[1:]):
            t=(aa+bb)*.5
            add([a[0]+t*dx,a[1]+t*dy])
        add(b)
    return seen

def reachable(data,flags,start='gate'):
    nbr=collections.defaultdict(set)
    for p in data['paths']:
        if p.get('requires_flag') and p['requires_flag'] not in flags:continue
        nbr[p['from_node']].add(p['to_node'])
        if p.get('bidirectional'):nbr[p['to_node']].add(p['from_node'])
    seen={start};q=collections.deque([start])
    while q:
        for v in nbr[q.popleft()]:
            if v not in seen:seen.add(v);q.append(v)
    return seen

def validate(data):
    errors=[];warnings=[];checks={}
    def err(m):errors.append(m)
    def warn(m):warnings.append(m)
    def unique(items,label):
        a=[x.get('id') for x in items]
        if len(a)!=len(set(a)):err('Duplicate '+label+' IDs: '+str([k for k,v in collections.Counter(a).items() if v>1]))
        if None in a:err('Missing '+label+' ID')
    try:
        sectors=data['sectors'];nodes=data['nodes'];paths=data['paths'];bounds=data['bounds'];flags=data['persistent_flags']
        unique(sectors,'sector');unique(nodes,'node');unique(paths,'path')
        ss={s['id']:s for s in sectors};nn={n['id']:n for n in nodes};
        if len(bounds)!=4 or any(not isinstance(x,(int,float)) or not math.isfinite(x) for x in bounds) or bounds[2]<=0 or bounds[3]<=0:err('Invalid world bounds')
        # Unique exhaustive grid partition, tested at cell centres.
        cols,rows=data['cells']['cols'],data['cells']['rows']
        if int(cols)!=cols or int(rows)!=rows or cols<=0 or rows<=0:err('Invalid discrete planner grid')
        else:
            for i in range(int(cols)):
                for j in range(int(rows)):
                    p=[bounds[0]+(i+.5)*bounds[2]/cols,bounds[1]+(j+.5)*bounds[3]/rows]
                    owners=point_sector(p,sectors)
                    if len(owners)!=1:err(f'Partition problem at {p}: {owners}')
        checks['sector_grid_cells']=int(cols)*int(rows)
        for s in sectors:
            r=s['rect'];
            if len(r)!=4 or r[2]<=0 or r[3]<=0 or not inside_bounds(r[:2],bounds) or not inside_bounds([r[0]+r[2],r[1]+r[3]],bounds):err('Sector out of bounds '+str(s['id']))
        for n in nodes:
            p=n['grid'];owners=point_sector(p,sectors)
            if not inside_bounds(p,bounds):err('Node outside bounds: '+n['id'])
            if len(owners)!=1:err('Ambiguous sector for node '+n['id']+': '+str(owners))
            elif n.get('owner_sector') != owners[0]:err(f"Wrong owner for node {n['id']}: saved {n.get('owner_sector')} actual {owners[0]}")
            if n.get('owner_sector') not in ss:err('Unknown owner sector '+n['id'])
        crossing=[]
        for p in paths:
            pid=p['id'];a=p['from_node'];b=p['to_node']
            if a not in nn or b not in nn:err('Unknown endpoint '+pid);continue
            seg=p.get('polyline') or []
            if len(seg)<2:err('Polyline <2 points '+pid);continue
            if math.dist(seg[0],nn[a]['grid'])>EPS or math.dist(seg[-1],nn[b]['grid'])>EPS:err('Endpoint geometry mismatch: '+pid)
            if any(not inside_bounds(v,bounds) for v in seg):err('Polyline vertex outside map '+pid)
            if len({tuple(x) for x in seg})<2:err('Degenerate path '+pid)
            if p.get('requires_flag') and p['requires_flag'] not in flags:err('Unknown flag in '+pid)
            traced=touched_sectors(seg,sectors)
            if len(traced)>1:crossing.append(pid)
            if p.get('sectors_crossed')!=traced:err(f"Wrong sector coverage {pid}: stored {p.get('sectors_crossed')} traced {traced}")
            if p.get('owner_sector')!=nn[a].get('owner_sector'):err('Wrong path owner '+pid)
        # A flag may be story-only, and is not necessarily an edge gate.
        mandatory={'dzwigacz_defeated','village_lamp_lit','guardian_defeated','camp_shortcut_open'}
        if not mandatory.issubset(flags):err('Missing required gate flags '+str(mandatory-set(flags)))
        gates={p.get('requires_flag') for p in paths if p.get('requires_flag')}
        if not mandatory.issubset(gates):err('Missing required gated path '+str(mandatory-gates))
        def expectation(title,active,must,notyet):
            have=reachable(data,set(active))
            for v in must:
                if v not in have:err(f'Reachability {title}: expected {v} OPEN')
            for v in notyet:
                if v in have:err(f'Reachability {title}: expected {v} CLOSED')
            checks[title+'_reachable']=len(have)
        expectation('initial',[],['wagon','bridge','stones','camp','ruins','snares','collector'],['chamber','old_road','guardian','dry_road'])
        expectation('dzwigacz', ['dzwigacz_defeated'],['chamber'],['old_road','guardian','dry_road'])
        expectation('lamp',['dzwigacz_defeated','village_lamp_lit'],['chamber','old_road','guardian'],['dry_road'])
        expectation('all',['dzwigacz_defeated','village_lamp_lit','guardian_defeated','camp_shortcut_open','road_found'],list(nn),[])
        if len(nn)!=28:warn('Node count differs from baseline 28')
        if len(paths)!=30:warn('Route count differs from baseline 30')
        # Render authoring sectors can be empty; explicit boundary role helps avoid false deliverables.
        empty=[s['id'] for s in sectors if not any(n.get('owner_sector')==s['id'] for n in nodes)]
        checks.update({'nodes':len(nodes),'paths':len(paths),'sectors':len(sectors),'cross_sector_paths':len(crossing),'empty_sectors':empty})
        if any(s['scope']=='playable' and s['id'] in empty for s in sectors):warn('Playable sectors without owned nodes: '+str([s['id'] for s in sectors if s['scope']=='playable' and s['id'] in empty]))
    except (KeyError,TypeError,ValueError,IndexError) as ex:err('Schema/structure error: '+str(ex))
    return {'ok':not errors,'checks':checks,'errors':errors,'warnings':warnings}

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('file',type=Path)
    ap.add_argument('--json',action='store_true')
    a=ap.parse_args()
    try:d=json.loads(a.file.read_text(encoding='utf-8'))
    except (ValueError,OSError) as e:
        print('ERROR: invalid JSON or inaccessible file: '+str(e),file=sys.stderr);return 2
    r=validate(d)
    if a.json:print(json.dumps(r,ensure_ascii=False,indent=2))
    else:
        print(('PASS' if r['ok'] else 'FAIL'),a.file)
        for k,v in r['checks'].items():print(f'  {k}: {v}')
        for e in r['warnings']:print('  WARN:',e)
        for e in r['errors']:print('  ERROR:',e)
    return 0 if r['ok'] else 1

if __name__=='__main__':raise SystemExit(main())
