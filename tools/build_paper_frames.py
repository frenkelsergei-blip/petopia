"""A55 frame-by-frame paper animation (stop-motion look) from the Codex sheets
source/<who>-run-raw.png and <who>-moves-raw.png (4x2 grid, one pose per
cell). Each pose is cut from its cell; its pivot is the feet on the ground
(grounded poses: their own lowest paw/foot; airborne poses: the sheet's
ground line, so they keep their height) and the body's horizontal centre.
Output: assets/art/paper-v1/frames/<who>_<set>_<i>.png + <who>-frames.json."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
SRC=ROOT/'assets/art/paper-v1/source'
OUT=ROOT/'assets/art/paper-v1/frames'
OUT.mkdir(exist_ok=True)
TARGET=200   # standing height in output pixels (crisp at phone scale)
SETS={'explorer':{'run':['run']*8,'moves':['idle','idle','takeoff','rise','fall','land','use','happy']},
      'fox':{'run':['run']*8,'moves':['idle','idle','takeoff','rise','fall','land','dig','happy']}}
AIR={'rise','fall'}
def cells(path):
    raw=np.asarray(Image.open(path).convert('RGB')).astype(int)
    r,g,b=raw[...,0],raw[...,1],raw[...,2]
    bg=(r>150)&(b>150)&(g<r-80)&(g<b-80)
    edge=(r>110)&(b>110)&(g<r-40)&(g<b-40)&~bg
    rgb=raw.copy();rgb[edge]=(rgb[edge]*0.3).astype(int)+[40,25,15]
    a=np.dstack([rgb,np.where(bg,0,np.where(edge,120,255))]).astype(np.uint8)
    H,W=a.shape[:2];ch,cw=H//2,W//4
    for row in range(2):
        for col in range(4):
            yield a[row*ch:(row+1)*ch,col*cw:(col+1)*cw]
def build(who):
    poses=[]
    for sheet,names in SETS[who].items():
        for cell,name in zip(cells(SRC/f'{"fox" if who=="fox" else who}-{sheet}-raw.png'),names):
            m=cell[...,3]>200
            # drop specks: keep rows/cols with real content
            ys,xs=np.where(m)
            poses.append({'set':name,'img':cell,'top':ys.min(),'bottom':ys.max(),'left':xs.min(),'right':xs.max(),'cx':float(np.median(xs))})
    ground=float(np.median([p['bottom'] for p in poses if p['set'] not in AIR]))
    stand=float(np.median([p['bottom']-p['top'] for p in poses if p['set']=='idle']))
    k=TARGET/stand
    data={'height':TARGET,'sets':{}}
    for i,p in enumerate(poses):
        foot=p['bottom'] if p['set'] not in AIR else ground
        x0,y0,x1,y1=p['left'],p['top'],p['right']+1,p['bottom']+1
        img=Image.fromarray(p['img'][y0:y1,x0:x1])
        img=img.resize((max(1,round(img.width*k)),max(1,round(img.height*k))),Image.LANCZOS)
        n=len(data['sets'].get(p['set'],[]))
        f=f'{who}_{p["set"]}_{n}.png';img.save(OUT/f)
        data['sets'].setdefault(p['set'],[]).append({'file':f,'pivot':[(p['cx']-x0)*k,(foot-y0)*k]})
    (ROOT/f'assets/art/paper-v1/{who}-frames.json').write_text(json.dumps(data,indent=1))
    print(who,{s:len(v) for s,v in data['sets'].items()},'stand',stand)
if __name__=='__main__':
    for who in (sys.argv[1:] or ['explorer','fox']): build(who)
