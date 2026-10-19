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
TARGETS={'fox':300,'explorer':280}
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
def grid(path,over=0):
    """over: Codex drew some figures past the row line (the boy's boots in
    moves-raw.png row 1); look that far into the next row. key() keeps only
    the biggest figure, so a neighbour's hair tip is dropped."""
    im=Image.open(path);W,H=im.size
    for row in range(2):
        for col in range(4): yield key(im.crop((col*W//4,max(0,row*H//2-over),(col+1)*W//4,min(H,(row+1)*H//2+over))))
def main_only(a):
    """Keep only the character: Codex sheets leave bits of the neighbouring
    drawing (ear tips, a toe) at the frame edges. They showed as stray
    shapes by the feet and moved the foot pivot (the lowest pixel) off the
    real shoe. Flood-fill from the body (parts a few px apart stay joined)."""
    from PIL import ImageDraw, ImageFilter
    m=a[...,3]>30
    grown=Image.fromarray((m*255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))
    ys,xs=np.where(m);cy,cx=np.median(ys),np.median(xs)
    d=(ys-cy)**2+(xs-cx)**2;i=int(np.argmin(d))
    ImageDraw.floodfill(grown,(int(xs[i]),int(ys[i])),128,thresh=0)
    keep=np.asarray(grown)==128
    out=a.copy();out[...,3]=np.where(keep,a[...,3],0);return out
def pose(a,name):
    a=main_only(a)
    m=a[...,3]>200;ys,xs=np.where(m);top=ys.min()
    head=np.where(m[top:top+int((ys.max()-top)*0.3)])[1]
    # Where a held ball sits (both face right): the boy's hand is the
    # rightmost point of the arm band; the fox's mouth sits just under and
    # behind its nose tip (rightmost point of the head band).
    H=ys.max()-top
    lo,hi=(0.15,0.62) if name in ('hold','throw') else ((0.05,0.4) if name=='windup' else ((0.0,0.3) if name=='catch' else (0.0,0.55)))
    band=m[top+int(H*lo):top+int(H*hi)]
    by,bx=np.where(band)
    i=int(np.argmax(bx)) if name!='windup' else int(np.argmin(bx))
    nose=(float(bx[i]),float(by[i]+top+int(H*lo)))
    anchor=nose if name in ('hold','throw','windup') else (nose[0]-H*0.07,nose[1]+H*0.07)
    if name=='nibble':
        mid=m[top+int(H*0.4):top+int(H*0.48)];my,mx=np.where(mid)
        anchor=(float(np.median(mx)),float(top+H*0.44))
    return {'set':name,'img':a,'top':top,'bottom':ys.max(),'left':xs.min(),'right':xs.max(),'cx':float(np.median(head)+0.0),'anchor':anchor}
def write(who,poses):
    ground=float(np.median([p['bottom'] for p in poses if p['set'] not in AIR]))
    stand=float(np.median([p['bottom']-p['top'] for p in poses if p['set']=='idle']))
    # Full source resolution: the Codex figures are ~300 px tall, shown up to
    # ~450 px on phones; 200 px frames looked soft.
    T=TARGETS.get(who,TARGET)
    k=T/stand;data={'height':T,'sets':{}}
    for p in poses:
        foot=p['bottom'] if p['set'] not in AIR else p['bottom']+40
        x0,y0,x1,y1=p['left'],p['top'],p['right']+1,p['bottom']+1
        img=Image.fromarray(p['img'][y0:y1,x0:x1]);img=img.resize((max(1,round(img.width*k)),max(1,round(img.height*k))),Image.LANCZOS)
        n=len(data['sets'].get(p['set'],[]));f=f'{who}_{p["set"]}_{n}.png';img.save(OUT/f)
        p['anchor_px']=[(p['anchor'][0]-x0)*k,(p['anchor'][1]-y0)*k]
        data['sets'].setdefault(p['set'],[]).append({'file':f,'pivot':[(p['cx']-x0)*k,(foot-y0)*k],'anchor':[round(v,1) for v in p['anchor_px']]})
    (ROOT/f'assets/art/heroes-p31/{who}-frames.json').write_text(json.dumps(data,indent=1))
    print(who,{s:len(v) for s,v in data['sets'].items()})
moves=list(grid(SRC/'moves-raw.png',over=60))
def height(a):
    ys=np.where(a[...,3]>200)[0];return ys.max()-ys.min()
def matched(a,h):
    """Rescale a keyed figure so its height is h (run edits come back at
    another scale than the moves sheet)."""
    k=h/height(a);im=Image.fromarray(a);return np.asarray(im.resize((round(im.width*k),round(im.height*k)),Image.LANCZOS))
idle_h=height(moves[0])
def scaled(a,k):
    im=Image.fromarray(a);return np.asarray(im.resize((round(im.width*k),round(im.height*k)),Image.LANCZOS))
def hand_anchor(p):
    """The boy's front hand (rightmost point of the arm band): a ball he
    carries while running sits in it, not in front of his face."""
    m=p['img'][...,3]>200;top,bot=p['top'],p['bottom'];H=bot-top
    band=m[top+int(H*0.48):top+int(H*0.66)];by,bx=np.where(band)
    i=int(np.argmax(bx));p['anchor']=(float(bx[i])-H*0.03,float(by[i]+top+int(H*0.48)))
    return p
# A58 run cycle (source/run/cycle-raw.png, 4x2): contact, down, pass, up for
# each leg; one scale for the whole cycle so nothing grows or shrinks.
cyc=list(grid(SRC/'run/cycle-raw.png'))
kr=idle_h*0.95/float(np.median([height(a) for a in cyc]))
boy=[hand_anchor(pose(scaled(a,kr),'run')) for a in cyc]
boy+=[pose(moves[0],'idle'),pose(moves[0],'idle'),pose(moves[1],'takeoff'),pose(moves[2],'rise'),pose(moves[2],'fall'),pose(moves[3],'land'),pose(moves[3],'use'),pose(moves[2],'happy')]
# Fetch poses (source/play/play-raw.png, 4x2): one scale per row, from the
# standing pose, so the row keeps the sheet's own proportions.
play=list(grid(SRC/'play/play-raw.png'))
kb=idle_h*0.95/height(play[0])
boy+=[pose(scaled(play[0],kb),'hold'),pose(scaled(play[1],kb),'windup')]+[pose(scaled(a,kb),'throw') for a in play[2:4]]
# Care poses (source/care/care-raw.png, 4x2). The boy is drawn facing
# left there: flipped so every frame faces right like the rest.
care=list(grid(SRC/'care/care-raw.png'))
kc=idle_h*0.95/height(care[3])
for a,n in zip(care[:4],['kneel_pet','kneel_pour','kneel_water','towel']):
    boy.append(pose(scaled(np.ascontiguousarray(a[:,::-1]),kc),n))
write('explorer',boy)
# A58 upright Foxy (concept P62): moves, run cycle and care/play poses
# (source/upfox/*-raw.png, 4x2 each), one scale from the idle pose.
U=SRC/'upfox'
um=list(grid(U/'moves-raw.png'));ur=list(grid(U/'run-raw.png'));uc=list(grid(U/'care-raw.png'))
fh=height(um[0])
def ball_anchor(p):
    """Frames holding the red ball: the ball's centre is the anchor."""
    a=p['img'];r,g,b=a[...,0].astype(int),a[...,1].astype(int),a[...,2].astype(int)
    red=(r>180)&(g<90)&(b<90)&(a[...,3]>200);ys,xs=np.where(red)
    if len(xs)>30: p['anchor']=(float(xs.mean()),float(ys.mean()))
    return p
fox=[pose(a,'run') for a in ur]
fox+=[pose(um[0],'idle'),pose(um[1],'idle'),pose(um[2],'takeoff'),pose(um[3],'rise'),pose(um[4],'fall'),pose(um[5],'land'),pose(um[6],'happy'),pose(um[7],'sleep')]
for a,n in zip(uc,['eat','drink','catch','carry','petted','shake','dig','wave']):
    p=pose(a,n)
    if n in ('catch','carry'): p=ball_anchor(p)
    fox.append(p)
fox.append(pose(um[0],'sit'))
# Tamagotchi moods (source/upfox/mood-raw.png, 4x2, front view).
umo=list(grid(U/'mood-raw.png'))
km=fh/height(umo[0])
for a,n in zip(umo,['sad','tired','yuck','disappointed','nibble','excited','wake','hungry']):
    fox.append(pose(scaled(a,km),n))
# A58 eating from the bowl (source/upfox/eat-raw.png, 4x2): the same pose
# and blue bowl in every cell; only the food in the bowl changes. Last cell:
# the bowl emptied (end of the meal).
ue=list(grid(U/'eat-raw.png'))
ke=fh/height(ue[0])
for a,n in zip(ue,['kibble','berry_bowl','apple','fish_treat','honey_cookie','carrot',None,'empty']):
    if n: fox.append(pose(scaled(a,ke),'eat_'+n))
write('fox',fox)
