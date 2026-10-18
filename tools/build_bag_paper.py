"""A55 paper bag from concept P12 (same pipeline as build_bag_kit.py):
base = Codex edit of P12 with everything that changes and every word removed
(source/base-raw.png, geometry kept), pieces = Codex sheet copied from P12
(source/sheet-raw.png). layout.json: rectangles measured on P12, same keys
as assets/ui/bag-v1 so the bag screen code is shared."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import rows_order, absorb
from build_icon_sheets import key
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/ui/bag-paper'
(OUT/'items').mkdir(exist_ok=True)
def hard(path):
    raw=np.asarray(Image.open(path).convert('RGB')).astype(int)
    r,g,b=raw[...,0],raw[...,1],raw[...,2]
    return raw,np.dstack([raw,np.where((r>150)&(b>150)&(g<r-80)&(g<b-80),0,255)]).astype(np.uint8)
# ---- base (crop to the panel incl. ropes, then 0.85 like the other kits)
_,base=hard(OUT/'source/base-raw.png')
ys,xs=np.where(base[...,3]>0);X0,Y0,X1,Y1=xs.min(),ys.min(),xs.max()+1,ys.max()+1
SCALE=0.85
img=Image.fromarray(base[Y0:Y1,X0:X1]);img.resize((round(img.width*SCALE),round(img.height*SCALE)),Image.LANCZOS).save(OUT/'base.png')
# ---- pieces
raw,a=hard(OUT/'source/sheet-raw.png')
soft=key(raw.astype(np.uint8))
NAMES=['slot','slot_on','tab_on','button_gold','badge','glow','apple','fish','cookie','berries','carrot','crate','magic_carrot','feather','backpack','key','scroll','robot_head','basket','pill']
boxes=rows_order(absorb([x for x in groups(a[...,3]>0,join=4) if (x[2]-x[0])*(x[3]-x[1])>200],small=4000))
assert len(boxes)==len(NAMES),len(boxes)
for (x0,y0,x1,y1),n in zip(boxes,NAMES):
    src=soft if n in('glow','slot_on') else a
    q=src[y0:y1,x0:x1];yy,xx=np.where(q[...,3]>8)
    im=Image.fromarray(q[yy.min():yy.max()+1,xx.min():xx.max()+1])
    if n in('slot','slot_on','tab_on','button_gold','badge','glow','pill'): im.save(OUT/f'{n}.png')
    else:
        im.thumbnail((180,180),Image.LANCZOS);im.save(OUT/'items'/f'{n}.png')
# Glow: the soft key leaves a pink rim on the magenta; turn it gold and fade it.
g=np.asarray(Image.open(OUT/'glow.png')).astype(float).copy()
pink=(g[...,0]>g[...,1]+30)&(g[...,2]>g[...,1]-20)
g[...,1]=np.where(pink,np.maximum(g[...,1],200),g[...,1]);g[...,2]=np.where(pink,110,g[...,2]);g[...,3]=np.where(pink,g[...,3]*0.4,g[...,3])
Image.fromarray(np.clip(g,0,255).astype(np.uint8)).save(OUT/'glow.png')
for i in range(4): Image.open(OUT/'tab_on.png').save(OUT/f'tab_on_{i}.png')
for n,src in [('tab_snacks','apple'),('tab_tools','crate'),('tab_treasures','key'),('tab_quests','scroll'),('apple_big','apple')]:
    Image.open(OUT/'items'/f'{src}.png').save(OUT/'items'/f'{n}.png')
# ---- layout measured on P12 (concept px), into base px
def P(x,y): return [(x-X0)*SCALE,(y-Y0)*SCALE]
def R(x0,y0,x1,y1): return P(x0,y0)+[(x1-x0)*SCALE,(y1-y0)*SCALE]
SX=[334,485,636,786,938];SY=[354,514,672]
L={"size":[round((X1-X0)*SCALE),round((Y1-Y0)*SCALE)],
 "slots_x":[(x-X0)*SCALE for x in SX],"slots_y":[(y-Y0)*SCALE for y in SY],"slot":[140*SCALE,141*SCALE],"pitch":[151*SCALE,159*SCALE],
 "grid":R(322,342,1082,830),
 "tabs":[R(323,215,613,318),R(623,215,885,318),R(896,215,1173,318),R(1184,215,1480,318)],
 "card":R(1133,337,1500,850),"button":R(1150,748,1484,828),
 "close":P(1505,180)+[57*SCALE],"picture":P(1312,477)+[105*SCALE],
 "name_y":(625-Y0)*SCALE,"text_y":(672-Y0)*SCALE,"count":R(1252,693,1380,735),
 "title":R(855,90,1060,185)}
(OUT/'layout.json').write_text(json.dumps(L,indent=1))
print('ok',L['size'],(X0,Y0))
