"""A55 paper shop from concept P14 (pipeline as build_bag_paper.py): clean
base (Codex edit of P14 with everything that changes and every word removed),
sheet copied from P14, layout.json measured on P14 (keys of shop-v2 + extras)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import rows_order, absorb
from build_icon_sheets import key
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/ui/shop-paper'
def hard(path):
    raw=np.asarray(Image.open(path).convert('RGB')).astype(int)
    r,g,b=raw[...,0],raw[...,1],raw[...,2]
    return raw,np.dstack([raw,np.where((r>150)&(b>150)&(g<r-80)&(g<b-80),0,255)]).astype(np.uint8)
_,base=hard(OUT/'source/base-raw.png')
ys,xs=np.where(base[...,3]>0);X0,Y0,X1,Y1=xs.min(),ys.min(),xs.max()+1,ys.max()+1
SCALE=0.8
img=Image.fromarray(base[Y0:Y1,X0:X1]);img.resize((round(img.width*SCALE),round(img.height*SCALE)),Image.LANCZOS).save(OUT/'base.png')
raw,a=hard(OUT/'source/sheet-raw.png');soft=key(raw.astype(np.uint8))
NAMES=['card','card_on','price','buy','tab_on','tab','coin','collar','cushion','ball','beach_ball','armchair','plant','lamp','toy_box','rug','divider']
boxes=rows_order(absorb([x for x in groups(a[...,3]>0,join=4) if (x[2]-x[0])*(x[3]-x[1])>400],small=3000))
assert len(boxes)==len(NAMES),len(boxes)
for (x0,y0,x1,y1),n in zip(boxes,NAMES):
    src=soft if n=='card_on' else a
    q=src[y0:y1,x0:x1];yy,xx=np.where(q[...,3]>8)
    im=Image.fromarray(q[yy.min():yy.max()+1,xx.min():xx.max()+1])
    if n not in('card','card_on','price','buy','tab_on','tab','divider'): im.thumbnail((180,180),Image.LANCZOS)
    im.save(OUT/f'{n}.png')
def P(x,y): return [(x-X0)*SCALE,(y-Y0)*SCALE]
def R(x0,y0,x1,y1): return P(x0,y0)+[(x1-x0)*SCALE,(y1-y0)*SCALE]
L={"size":[round((X1-X0)*SCALE),round((Y1-Y0)*SCALE)],
 "cards_x":[(x-X0)*SCALE for x in (314,519,721,924)],"cards_y":[(y-Y0)*SCALE for y in (299,587)],"card":[193*SCALE,277*SCALE],
 "tabs":[R(380,186,722,272),R(728,190,1057,272),R(1060,190,1404,272)],
 "detail":R(1130,300,1530,860),"buy":R(1182,766,1485,835),
 "coins":R(1360,85,1475,160),"coin_icon":R(1282,92,1352,154),"close":P(1555,122)+[48*SCALE],
 "picture":P(1328,470)+[110*SCALE],"name_y":(604-Y0)*SCALE,"text_y":(654-Y0)*SCALE,"divider":R(1210,686,1450,706),"have_y":(734-Y0)*SCALE,
 "title":R(800,45,1050,155)}
(OUT/'layout.json').write_text(json.dumps(L,indent=1))
print('ok',L['size'],(X0,Y0))
