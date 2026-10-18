"""Shop screen from its approved concept (V11-shop-v1.png), same pipeline as
the bag and details (AGENTS.md): concept base with the changing parts cleared,
pieces from the Codex asset sheet copied from V11, layout.json in base coords."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups, order
ROOT=Path(__file__).resolve().parent.parent
SRC=np.asarray(Image.open(ROOT/'assets/concepts/current/screens/V11-shop-v1.png').convert('RGBA')).astype(float)
OUT=ROOT/'assets/ui/shop-v2'
X0,Y0,X1,Y1=140,15,1590,920
CARD_X=[230,442,648,852]; CARD_Y=[284,584]; CARD_W,CARD_H=196,284
TABS=[(312,170,660,258),(668,172,1006,256),(1018,172,1356,256)]
DETAIL=(1062,284,1494,866)
BUY=(1108,762,1446,842)
COINS=(1236,64,1446,146)
CLOSE=(1527,117,50)
def save(a,p): Image.fromarray(np.clip(a,0,255).astype(np.uint8)).save(p)
def med(x0,y0,x1,y1): return np.median(SRC[y0:y1,x0:x1].reshape(-1,4),axis=0)
def dilate(m,r):
    out=m.copy()
    for dy in range(-r,r+1):
        for dx in range(-r,r+1): out|=np.roll(np.roll(m,dy,0),dx,1)
    return out

base=SRC.copy()
cream=med(640,265,660,275)
base[160:268,300:1370]=med(1380,200,1395,215)       # tabs row (tabs drawn by the game)
strip=SRC[236:272,1440:1441].copy()                 # divider under the tabs, rebuilt
base[236:272,222:1500]=np.repeat(strip,1278,axis=1)
base[274:870,218:1052]=cream                        # item cards
inner=med(1090,320,1100,330)
base[DETAIL[1]+14:DETAIL[3]-14,DETAIL[0]+14:DETAIL[2]-14]=inner
base[52:135,790:985]=np.repeat(SRC[52:135,784:785],195,axis=1)   # "Shop" (drawn live)
base[78:132,1320:1430]=med(1300,78,1310,84)        # coin number
h,w=base.shape[:2];yy,xx=np.mgrid[0:h,0:w]
keep=(xx>=168)&(xx<1515)&(yy>=88)&(yy<905)
keep|=(xx>=596)&(xx<1072)&(yy>=22)&(yy<165)
keep|=(xx>=1232)&(xx<1450)&(yy>=60)&(yy<150)
keep|=(xx-CLOSE[0])**2+(yy-CLOSE[1])**2<=(CLOSE[2]+2)**2
r,g,b=SRC[...,0],SRC[...,1],SRC[...,2]
leaf=(g>120)&(g>r+25)&(g>b+35)
petal=(r>225)&(g>225)&(b>205)
outline=(r+g+b)<150
cand=dilate(leaf|petal,2)&(leaf|petal|outline|dilate(leaf,1))
for _ in range(50): keep=dilate(keep,1)&(keep|cand)
base[...,3]=np.where(keep,255,0)
save(base[Y0:Y1,X0:X1],OUT/'base.png')
bimg=Image.open(OUT/'base.png');bimg.resize((round(bimg.width*0.85),round(bimg.height*0.85)),Image.LANCZOS).save(OUT/'base.png')

sheet=np.asarray(Image.open(OUT/'source'/'shop-assets-raw.png').convert('RGB')).astype(int)
sr,sg,sb=sheet[...,0],sheet[...,1],sheet[...,2]
alpha=np.where((sr>150)&(sb>150)&(sg<sr-80)&(sg<sb-80),0,255)
hard=np.dstack([sheet,alpha]).astype(np.uint8)
boxes=order([x for x in groups(alpha>0,join=5) if (x[2]-x[0])*(x[3]-x[1])>400])
names=['card','card_on','price','buy','tab_on','tab','coin','collar','cushion','beach_ball','armchair','plant','lamp','toy_box','rug']
assert len(boxes)==len(names),(len(boxes),boxes)
for (x0,y0,x1,y1),n in zip(boxes,names):
    q=hard[y0:y1,x0:x1];ys,xs=np.where(q[...,3]>0)
    img=Image.fromarray(q[ys.min():ys.max()+1,xs.min():xs.max()+1])
    if n not in ('card','card_on','price','buy','tab','tab_on'): img.thumbnail((180,180),Image.LANCZOS)
    img.save(OUT/f'{n}.png')

layout={"size":[X1-X0,Y1-Y0],"cards_x":[x-X0 for x in CARD_X],"cards_y":[y-Y0 for y in CARD_Y],"card":[CARD_W,CARD_H],
 "tabs":[[a-X0,b-Y0,c-a,d-b] for a,b,c,d in TABS],"detail":[DETAIL[0]-X0,DETAIL[1]-Y0,DETAIL[2]-DETAIL[0],DETAIL[3]-DETAIL[1]],
 "buy":[BUY[0]-X0,BUY[1]-Y0,BUY[2]-BUY[0],BUY[3]-BUY[1]],"coins":[1320-X0,70-Y0,120,66],"close":[CLOSE[0]-X0,CLOSE[1]-Y0,CLOSE[2]],
 "picture":[1278-X0,462-Y0,112],"name_y":604-Y0,"text_y":656-Y0,"have_y":735-Y0}
(OUT/'layout.json').write_text(json.dumps(layout,indent=1))
print('ok',layout['size'])
