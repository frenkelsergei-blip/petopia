"""Build the bag UI from the approved concept itself
(assets/concepts/current/screens/V10-bag-v1.png) so the game matches it.

- base.png: the whole bag panel (frame, leaves, title plaque with backpack and
  "Bag", close button, divider, scroll bar) with the parts that change cleared:
  tabs become plain tabs, the slot area and the details card are emptied.
- Pieces at the concept's own resolution: empty slot, selected slot, gold tab
  for each tab position, gold action button, count badge.
- items/*.png: the concept's item and tab icons cut off their tiles.
- layout.json: every rectangle in base coordinates for the game to place
  things exactly where the concept has them.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
SRC=np.asarray(Image.open(ROOT/'assets/concepts/current/screens/V10-bag-v1.png').convert('RGBA')).astype(float)
OUT=ROOT/'assets/ui/bag-v1'
(OUT/'items').mkdir(parents=True,exist_ok=True)
ORIGIN=(200,55,1520,885)          # base crop in the concept
SLOT_X=[286,437,586,736,886]; SLOT_W=139
SLOT_Y=[328,489,651]; SLOT_H=148
TABS=[(285,204,560,297),(572,204,833,297),(845,204,1117,297),(1128,204,1412,297)]
GRID=(270,318,1034,812)
CARD=(1077,316,1434,838)
BUTTON=(1094,729,1421,811)
CLOSE=(1437,147,46)

def crop(x0,y0,x1,y1): return SRC[y0:y1,x0:x1].copy()
def median(x0,y0,x1,y1): return np.median(SRC[y0:y1,x0:x1].reshape(-1,4),axis=0)
def save(a,path): Image.fromarray(np.clip(a,0,255).astype(np.uint8)).save(path)
def stretch_to(a,width,left,right,col):
    """Keep the left/right caps, fill the middle with one clean column."""
    mid=np.repeat(a[:,col:col+1],width-left-right,axis=1)
    return np.concatenate([a[:,:left],mid,a[:,-right:]],axis=1)
def dilate(m,r):
    out=m.copy()
    for dy in range(-r,r+1):
        for dx in range(-r,r+1): out|=np.roll(np.roll(m,dy,0),dx,1)
    return out

# ---------------------------------------------------------------- base
base=SRC.copy()
cream=median(428,478,434,486)
# Clear the slot area (slots are drawn by the game, so they can scroll).
base[GRID[1]:GRID[3],GRID[0]:GRID[2]]=cream
# Plain tabs everywhere (the selected one is drawn on top by the game).
tools_tab=crop(*TABS[1])
for x0,y0,x1,y1 in TABS:
    base[y0-6:y1+6,x0-6:x1+6]=median(570,190,600,198) if False else base[y0-6:y1+6,x0-6:x1+6]
    # erase the gold glow around the concept's selected tab first
    pad=base[y0-6:y1+6,x0-6:x1+6]
    pad[:]=cream
    base[y0:y1,x0:x1]=stretch_to(tools_tab,x1-x0,40,40,228)
base[96:170,800:995]=np.repeat(SRC[96:170,1000:1001],195,axis=1)   # "Bag" (drawn live)
# Empty details card (frame kept).
cardfill=median(1100,340,1110,350)
base[CARD[1]+12:CARD[3]-12,CARD[0]+10:CARD[2]-10]=cardfill
# Outside the panel: transparent, except the leaves, plaque and close button.
h,w=base.shape[:2];yy,xx=np.mgrid[0:h,0:w]
keep=(xx>=228)&(xx<1485)&(yy>=128)&(yy<865)
keep|=(xx>=617)&(xx<1056)&(yy>=75)&(yy<193)
keep|=(xx-CLOSE[0])**2+(yy-CLOSE[1])**2<=(CLOSE[2]+2)**2
r,g,b=SRC[...,0],SRC[...,1],SRC[...,2]
green=(g>120)&(g>r+25)&(g>b+35)
outline=(r+g+b)<150
boxes=[(200,95,330,245),(545,55,630,185),(1045,55,1125,185),(1360,80,1525,245),(205,800,330,885),(1390,790,1500,885)]
leafbox=np.zeros((h,w),bool)
for x0,y0,x1,y1 in boxes: leafbox[y0:y1,x0:x1]=True
leaf=green&leafbox
leaf=dilate(leaf,2)&(green|outline|dilate(leaf,1))
cand=leaf&leafbox
# Only leaves that grow out of the bag (connected to it), not background foliage.
grown=keep.copy()
for _ in range(60): grown=dilate(grown,1)&(keep|cand)
keep=grown
base[...,3]=np.where(keep,255,0)
X0,Y0,X1,Y1=ORIGIN
save(base[Y0:Y1,X0:X1],OUT/'base.png')
_b=Image.open(OUT/'base.png');_b.resize((round(_b.width*0.85),round(_b.height*0.85)),Image.LANCZOS).save(OUT/'base.png')

# ---------------------------------------------------------------- pieces
save(crop(SLOT_X[0],SLOT_Y[2],SLOT_X[0]+SLOT_W,SLOT_Y[2]+SLOT_H),OUT/'slot.png')
# Selected slot: the concept's apple slot, rebuilt from its clean top-left
# corner so the apple and badge are gone.
sel=crop(276,320,437,484);sh,sw=sel.shape[:2];m=40
c=sel[:m,:m];f=np.zeros_like(sel);f[:]=sel[60,30]
f[:m,:m]=c;f[:m,-m:]=c[:,::-1];f[-m:,:m]=c[::-1];f[-m:,-m:]=c[::-1,::-1]
f[:m,m:-m]=np.repeat(c[:,-1:],sw-2*m,axis=1);f[-m:,m:-m]=np.repeat(c[::-1,-1:],sw-2*m,axis=1)
f[m:-m,:m]=np.repeat(c[-1:,:],sh-2*m,axis=0);f[m:-m,-m:]=np.repeat(c[-1:,::-1],sh-2*m,axis=0)
save(f,OUT/'slot_on.png')
gold=crop(282,200,563,300)
for i,(x0,y0,x1,y1) in enumerate(TABS):
    save(stretch_to(gold,x1-x0+6,40,40,252),OUT/f'tab_on_{i}.png')
save(stretch_to(crop(*BUTTON),BUTTON[2]-BUTTON[0],40,40,268),OUT/'button_gold.png')
# ---------------------------------------------------------------- icons
# Items, badge and glow come from the Codex asset sheet copied from the
# concept (source/bag-assets-raw.png, prompt next to it), cut on magenta.
import sys
sys.path.insert(0,str(Path(__file__).parent))
from build_icon_sheets import key
sheet=np.asarray(Image.open(OUT/'source'/'bag-assets-raw.png').convert('RGB')).astype(int)
sr,sg,sb=sheet[...,0],sheet[...,1],sheet[...,2]
hard=np.dstack([sheet,np.where((sr>150)&(sb>150)&(sg<sr-80)&(sg<sb-80),0,255)]).astype(np.uint8)
soft=key(sheet.astype(np.uint8))
def piece(src,x0,y0,x1,y1,name,limit=180):
    q=src[y0:y1,x0:x1];ys,xs=np.where(q[...,3]>8)
    img=Image.fromarray(q[ys.min():ys.max()+1,xs.min():xs.max()+1]);img.thumbnail((limit,limit),Image.LANCZOS)
    img.save(OUT/name)
cw=1536/5
for ri,(y0,y1,row) in enumerate([(60,360,['apple','fish','cookie','berries','carrot']),(390,680,['crate','magic_carrot','feather','key','scroll'])]):
    for ci,n in enumerate(row): piece(hard,int(ci*cw),y0,int((ci+1)*cw),y1,f'items/{n}.png')
for n,src in [('tab_snacks','apple'),('tab_tools','crate'),('tab_treasures','key'),('tab_quests','scroll'),('apple_big','apple')]:
    Image.open(OUT/'items'/f'{src}.png').save(OUT/'items'/f'{n}.png')
piece(hard,230,750,410,930,'badge.png')
piece(soft,560,680,960,960,'glow.png',260)
g=np.asarray(Image.open(OUT/'glow.png')).astype(float).copy()
pink=(g[...,2]>g[...,1]-20)&(g[...,0]>g[...,1]+30)
g[...,1]=np.where(pink,np.maximum(g[...,1],200),g[...,1]);g[...,2]=np.where(pink,120,g[...,2]);g[...,3]=np.where(pink,g[...,3]*0.5,g[...,3])
save(g,OUT/'glow.png')

S=lambda x,y:[x-X0,y-Y0]
layout={"size":[X1-X0,Y1-Y0],
 "slots_x":[x-X0 for x in SLOT_X],"slots_y":[y-Y0 for y in SLOT_Y],"slot":[SLOT_W,SLOT_H],
 "pitch":[150,162],"grid":[GRID[0]-X0,GRID[1]-Y0,GRID[2]-GRID[0],GRID[3]-GRID[1]],
 "tabs":[[x0-X0,y0-Y0,x1-x0,y1-y0] for x0,y0,x1,y1 in TABS],
 "card":[CARD[0]-X0,CARD[1]-Y0,CARD[2]-CARD[0],CARD[3]-CARD[1]],
 "button":[BUTTON[0]-X0,BUTTON[1]-Y0,BUTTON[2]-BUTTON[0],BUTTON[3]-BUTTON[1]],
 "close":[CLOSE[0]-X0,CLOSE[1]-Y0,CLOSE[2]],
 "picture":[1255-X0,452-Y0,92],"name_y":605-Y0,"text_y":655-Y0,"count":[1195-X0,680-Y0,120,38]}
(OUT/'layout.json').write_text(json.dumps(layout,indent=1))
print('ok',layout['size'])
