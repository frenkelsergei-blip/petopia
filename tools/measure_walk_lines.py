#!/usr/bin/env python3
"""A63: walk lines measured on a painted level (play tiles with alpha).
Each surface is a window (x0, x1, ymin, ymax) in panorama pixels; per 8 px
column the top of the yellow-green grass lip inside the window is found,
smoothed, and the feet line set FEET px into the lip. Output in world units.
  python3 tools/measure_walk_lines.py meadow
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
P=ROOT/'assets/art/meadow-p31/painted'
TW=1672; S=640/1672; FEET=16
def load(prefix,n):
    tiles=[np.asarray(Image.open(P/f'{prefix}play{i}.png').convert('RGBA')).astype(int) for i in range(n)]
    return np.concatenate(tiles,1)
def grass(a):
    r,g,b,al=a[...,0],a[...,1],a[...,2],a[...,3]
    return (r>185)&(g>180)&(b<175)&(al>200)&(g>=r-25)
def measure(G,x0,x1,ymin,ymax,step=8):
    xs=[];ys=[]
    for x in range(x0,x1,step):
        band=G[ymin:ymax,max(0,x-3):x+3].mean(1)>0.5
        y=None;run=0
        for k,v in enumerate(band):
            run=run+1 if v else 0
            if run>=5: y=ymin+k-4; break
        if y is not None: xs.append(x); ys.append(y)
    ys=np.array(ys,float)
    if len(ys)>=5:
        sm=ys.copy()
        for i in range(len(ys)):
            sm[i]=np.median(ys[max(0,i-3):i+4])
        ys=sm
    return [[round(x*S,1),round((y+FEET)*S,1)] for x,y in zip(xs,ys)]
SURF={'meadow':('mf_',4,[
 # name, x0, x1, ymin, ymax, depth, one_way
 ('path',0,985,480,600,200,False),
 ('hill_a',985,1192,380,560,28,False),
 ('hill_b',1252,2190,330,700,28,False),
 ('low',2190,6688,600,760,200,False),
 ('chamber',990,1530,790,840,40,False),
 ('shelf',2484,2887,370,430,26,False),
 ('mill',2872,3864,270,380,26,False),
 ('log',3864,4524,330,390,16,False),
 ('gate',4524,5460,270,390,26,False),
 ('ledge',4034,4319,120,180,14,True),
])}
if __name__=='__main__':
    prefix,n,surfs=SURF[sys.argv[1]]
    G=grass(load(prefix,n))
    out=[]
    for name,x0,x1,ymin,ymax,depth,one in surfs:
        pts=measure(G,x0,x1,ymin,ymax)
        print(name,len(pts),pts[:2],pts[-2:])
        out.append({'name':name,'pts':pts,'depth':depth,'one_way':one})
    json.dump(out,open(ROOT/f'test-results/lines_{sys.argv[1]}.json','w'))
