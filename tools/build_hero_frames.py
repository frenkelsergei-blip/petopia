"""A57 heroes in the P31 style (assets/art/heroes-p31/source): explorer run
from pose-guided edits (run/run_0..7.png), fox gallop sheet (fox/run-raw.png,
4x2), moves sheet (moves-raw.png, 4x2: boy idle, take-off, rise, land; fox
idle, rise, dig, happy). Pivot = feet on the ground line, body centre.
Output: assets/art/heroes-p31/frames/*.png + <who>-frames.json."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
ROOT=Path(__file__).resolve().parent.parent
SRC=ROOT/'assets/art/heroes-p31/source'
OUT=ROOT/'assets/art/heroes-p31/frames';OUT.mkdir(parents=True,exist_ok=True)
TARGET=200
AIR={'rise','fall'}
def key(img):
    raw=np.asarray(img.convert('RGB')).astype(int)
    r,g,b=raw[...,0],raw[...,1],raw[...,2]
    bg=(r>150)&(b>150)&(g<r-80)&(g<b-80)
    edge=(r>110)&(b>110)&(g<r-40)&(g<b-40)&~bg
    rgb=raw.copy();rgb[edge]=(rgb[edge]*0.3).astype(int)+[40,25,15]
    a=np.dstack([rgb,np.where(bg,0,np.where(edge,120,255))]).astype(np.uint8)
    # keep only the biggest figure (drops stray bits from neighbours)
    boxes=groups(a[...,3]>200,join=6)
    big=max(boxes,key=lambda x:(x[2]-x[0])*(x[3]-x[1]))
    m=np.zeros(a.shape[:2],bool);m[big[1]:big[3],big[0]:big[2]]=True
    a[...,3]=np.where(m,a[...,3],0)
    return a
def grid(path):
    im=Image.open(path);W,H=im.size
    for row in range(2):
        for col in range(4): yield key(im.crop((col*W//4,row*H//2,(col+1)*W//4,(row+1)*H//2)))
def pose(a,name):
    m=a[...,3]>200;ys,xs=np.where(m);top=ys.min()
    head=np.where(m[top:top+int((ys.max()-top)*0.3)])[1]
    return {'set':name,'img':a,'top':top,'bottom':ys.max(),'left':xs.min(),'right':xs.max(),'cx':float(np.median(head)+0.0)}
def write(who,poses):
    ground=float(np.median([p['bottom'] for p in poses if p['set'] not in AIR]))
    stand=float(np.median([p['bottom']-p['top'] for p in poses if p['set']=='idle']))
    k=TARGET/stand;data={'height':TARGET,'sets':{}}
    for p in poses:
        foot=p['bottom'] if p['set'] not in AIR else p['bottom']+40
        x0,y0,x1,y1=p['left'],p['top'],p['right']+1,p['bottom']+1
        img=Image.fromarray(p['img'][y0:y1,x0:x1]);img=img.resize((max(1,round(img.width*k)),max(1,round(img.height*k))),Image.LANCZOS)
        n=len(data['sets'].get(p['set'],[]));f=f'{who}_{p["set"]}_{n}.png';img.save(OUT/f)
        data['sets'].setdefault(p['set'],[]).append({'file':f,'pivot':[(p['cx']-x0)*k,(foot-y0)*k]})
    (ROOT/f'assets/art/heroes-p31/{who}-frames.json').write_text(json.dumps(data,indent=1))
    print(who,{s:len(v) for s,v in data['sets'].items()})
moves=list(grid(SRC/'moves-raw.png'))
def height(a):
    ys=np.where(a[...,3]>200)[0];return ys.max()-ys.min()
def matched(a,h):
    """Rescale a keyed figure so its height is h (run edits come back at
    another scale than the moves sheet)."""
    k=h/height(a);im=Image.fromarray(a);return np.asarray(im.resize((round(im.width*k),round(im.height*k)),Image.LANCZOS))
idle_h=height(moves[0])
boy=[pose(matched(key(Image.open(SRC/f'run/run_{i}.png')),idle_h*0.95),'run') for i in range(8)]
boy+=[pose(moves[0],'idle'),pose(moves[0],'idle'),pose(moves[1],'takeoff'),pose(moves[2],'rise'),pose(moves[2],'fall'),pose(moves[3],'land'),pose(moves[3],'use'),pose(moves[2],'happy')]
write('explorer',boy)
fox=[pose(c,'run') for c in grid(SRC/'fox/run-raw.png')]
fox+=[pose(moves[4],'idle'),pose(moves[4],'idle'),pose(moves[4],'takeoff'),pose(moves[5],'rise'),pose(moves[5],'fall'),pose(moves[4],'land'),pose(moves[6],'dig'),pose(moves[7],'happy')]
write('fox',fox)
