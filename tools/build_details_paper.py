"""A55 paper pet details from concept P13 (pipeline as build_bag_paper.py):
clean base (Codex edit of P13, every word and changing part removed), sheet
copied from P13, room picture (P13's window without the fox), layout.json
measured on P13 with the keys of assets/ui/details-v2 plus paper extras."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import rows_order, absorb
def hard(path):
    raw=np.asarray(Image.open(path).convert('RGB')).astype(int)
    r,g,b=raw[...,0],raw[...,1],raw[...,2]
    return raw,np.dstack([raw,np.where((r>150)&(b>150)&(g<r-80)&(g<b-80),0,255)]).astype(np.uint8)
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/ui/details-paper'
_,base=hard(OUT/'source/base-raw.png')
ys,xs=np.where(base[...,3]>0);X0,Y0,X1,Y1=xs.min(),ys.min(),xs.max()+1,ys.max()+1
SCALE=0.8
img=Image.fromarray(base[Y0:Y1,X0:X1]);img.resize((round(img.width*SCALE),round(img.height*SCALE)),Image.LANCZOS).save(OUT/'base.png')
_,a=hard(OUT/'source/sheet-raw.png')
NAMES=['icon_food','icon_happy','icon_energy','icon_clean','icon_health','icon_bond','fill_food','fill_happy','fill_energy','fill_clean','fill_health','fill_bond','track','card','card_on','check','clock','berries','stage_baby','stage_child','stage_teen','stage_adult']
boxes=rows_order(absorb([x for x in groups(a[...,3]>0,join=4) if (x[2]-x[0])*(x[3]-x[1])>400],small=3000))
assert len(boxes)==len(NAMES),len(boxes)
for (x0,y0,x1,y1),n in zip(boxes,NAMES):
    q=a[y0:y1,x0:x1];yy,xx=np.where(q[...,3]>0)
    im=Image.fromarray(q[yy.min():yy.max()+1,xx.min():xx.max()+1])
    if not n.startswith(('fill','track','card')): im.thumbnail((220,220),Image.LANCZOS)
    im.save(OUT/f'{n}.png')
    if n.startswith('stage_'):
        g=ImageEnhance.Color(im).enhance(0.0);g=ImageEnhance.Brightness(g).enhance(1.25)
        al=np.asarray(im)[...,3];gg=np.asarray(g.convert('RGBA')).copy();gg[...,3]=(al*0.6).astype(np.uint8)
        Image.fromarray(gg).save(OUT/f'{n}_grey.png')
room=OUT/'source/room-raw.png'
if room.exists():
    r=Image.open(room).convert('RGB');m=int(r.width*0.035);r=r.crop((m,m,r.width-m,r.height-m));r.thumbnail((520,520),Image.LANCZOS);r.save(OUT/'portrait_room.png')
def P(x,y): return [(x-X0)*SCALE,(y-Y0)*SCALE]
def R(x0,y0,x1,y1): return P(x0,y0)+[(x1-x0)*SCALE,(y1-y0)*SCALE]
ROWS=[(143,212),(222,290),(302,370),(382,452),(465,537),(550,622)]
L={"size":[round((X1-X0)*SCALE),round((Y1-Y0)*SCALE)],
 "title":R(330,38,590,104),"back":R(256,34,330,106),"coins":R(1170,40,1320,100),"coin_icon":R(1124,44,1176,96),"gear":R(1340,28,1430,110),
 "portrait":R(262,157,730,490),"name_y":(530-Y0)*SCALE,"stage_y":(566-Y0)*SCALE,"traits_y":(592-Y0)*SCALE,"center_x":(482-X0)*SCALE,
 "favourite":R(305,610,658,648),
 "rows":[[(y0-Y0)*SCALE,(y1-y0)*SCALE] for y0,y1 in ROWS],"bar":[(1060-X0)*SCALE,282*SCALE,32*SCALE],"value_x":(1398-X0)*SCALE,
 "icon_x":(868-X0)*SCALE,"name_x":(910-X0)*SCALE,
 "cards":[R(516,674,735,766),R(768,674,958,766),R(997,674,1197,766),R(1241,674,1441,766)],
 "card_caption_y":(783-Y0)*SCALE,"progress":R(535,796,715,806),
 "growth_title":R(262,686,500,724),"growth_sub":R(262,726,500,790),
 "back_button":R(320,825,685,900),"care_button":R(1013,829,1430,898)}
(OUT/'layout.json').write_text(json.dumps(L,indent=1))
print('ok',L['size'],(X0,Y0))
