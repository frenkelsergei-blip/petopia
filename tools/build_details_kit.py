"""Pet details screen from its approved concept (V06-pet-details-v1.png), the
same way as the bag (see tools/build_bag_kit.py and AGENTS.md):
- base.png: the concept panel (frame, leaves, title plaque with back arrow,
  coin box, gear, stat rows with icons and labels, growth box, Back button)
  with the changing parts cleared.
- pieces from the Codex asset sheet copied from V06 (source/details-assets-raw.png).
- layout.json: measured concept rectangles, in base coordinates.
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups, order
ROOT=Path(__file__).resolve().parent.parent
SRC=np.asarray(Image.open(ROOT/'assets/concepts/current/screens/V06-pet-details-v1.png').convert('RGBA')).astype(float)
OUT=ROOT/'assets/ui/details-v2'
X0,Y0,X1,Y1=165,15,1510,930
ROWS=[(137,205),(215,285),(295,367),(377,450),(460,532),(543,618)]
CARDS=[(463,668,674,758),(716,670,918,758),(963,670,1166,758),(1212,670,1416,758)]
def save(a,p): Image.fromarray(np.clip(a,0,255).astype(np.uint8)).save(p)
def med(x0,y0,x1,y1): return np.median(SRC[y0:y1,x0:x1].reshape(-1,4),axis=0)
def dilate(m,r):
    out=m.copy()
    for dy in range(-r,r+1):
        for dx in range(-r,r+1): out|=np.roll(np.roll(m,dy,0),dx,1)
    return out

base=SRC.copy()
cream=med(740,300,755,320)
plaque=med(345,95,360,105)
base[45:105,360:560]=plaque                         # title (pet name)
base[38:96,1190:1300]=med(1240,36,1250,40)         # coin number
base[150:478,268:706]=cream                         # portrait (drawn by the game)
base[493:650,290:690]=cream                         # name, age, traits, favourite chip
rowfill=med(950,145,955,150)
for y0,y1 in ROWS: base[y0+10:y1-10,1052:1408]=rowfill   # bar and value
box=med(300,790,310,800)
base[660:812,452:1430]=box                          # growth cards
for y0,y1 in ROWS: base[y0+12:y1-12,945:1050]=rowfill    # stat names (drawn live)
base[680:775,245:450]=box                               # Growth Journey text (live)
bl,br=SRC[832:892,330:372].copy(),SRC[832:892,594:636].copy()
base[832:892,330:636]=np.concatenate([bl,np.repeat(SRC[832:892,380:381],306-84,axis=1),br],axis=1)  # Back button, no label
btn_l,btn_r=SRC[828:896,962:1002].copy(),SRC[828:896,1305:1346].copy()
mid=np.repeat(SRC[828:896,1010:1011],303,axis=1)
base[828:896,962:1346]=np.concatenate([btn_l,mid,btn_r],axis=1)   # Care button, no label
h,w=base.shape[:2];yy,xx=np.mgrid[0:h,0:w]
keep=(xx>=186)&(xx<1492)&(yy>=88)&(yy<918)
keep|=(xx>=245)&(xx<576)&(yy>=30)&(yy<120)
keep|=(xx>=1100)&(xx<1313)&(yy>=24)&(yy<110)
keep|=(xx>=1330)&(xx<1417)&(yy>=24)&(yy<112)
r,g,b=SRC[...,0],SRC[...,1],SRC[...,2]
leaf=(g>120)&(g>r+25)&(g>b+35)
outline=(r+g+b)<150
cand=dilate(leaf,2)&(leaf|outline|dilate(leaf,1))
for _ in range(60): keep=dilate(keep,1)&(keep|cand)
base[...,3]=np.where(keep,255,0)
save(base[Y0:Y1,X0:X1],OUT/'base.png')
bimg=Image.open(OUT/'base.png');bimg.resize((round(bimg.width*0.85),round(bimg.height*0.85)),Image.LANCZOS).save(OUT/'base.png')

sheet=np.asarray(Image.open(OUT/'source'/'details-assets-raw.png').convert('RGB')).astype(int)
sr,sg,sb=sheet[...,0],sheet[...,1],sheet[...,2]
alpha=np.where((sr>150)&(sb>150)&(sg<sr-80)&(sg<sb-80),0,255)
hard=np.dstack([sheet,alpha]).astype(np.uint8)
boxes=order([x for x in groups(alpha>0,join=5) if (x[2]-x[0])*(x[3]-x[1])>400])
names=['portrait_room','track','fill_food','fill_happy','fill_energy','fill_clean','fill_health','fill_bond',
 'icon_food','icon_happy','icon_energy','icon_clean','icon_health','icon_bond','card','card_on','check','clock',
 'stage_baby','stage_baby_grey','stage_child','stage_child_grey','stage_teen+grey','stage_adult+grey']
def cut(x0,y0,x1,y1,name,limit=420):
    q=hard[y0:y1,x0:x1];ys,xs=np.where(q[...,3]>0)
    img=Image.fromarray(q[ys.min():ys.max()+1,xs.min():xs.max()+1]);img.thumbnail((limit,limit),Image.LANCZOS);img.save(OUT/f'{name}.png')
for (x0,y0,x1,y1),n in zip(boxes,names):
    if '+grey' in n:
        stem=n.split('+')[0]
        cut(x0,y0,x1,848,stem,200);cut(x0,848,x1,y1,stem+'_grey',200)
    else: cut(x0,y0,x1,y1,n,600 if n=='portrait_room' else 240)

S=lambda x,y:[x-X0,y-Y0]
layout={"size":[X1-X0,Y1-Y0],"title":[360-X0,45-Y0,200,60],"coins":[1190-X0,38-Y0,110,58],
 "back":[245-X0,30-Y0,120,90],"gear":[1330-X0,24-Y0,87,88],
 "portrait":[258-X0,140-Y0,457,348],"name_y":515-Y0,"stage_y":548-Y0,"traits_y":577-Y0,"center_x":487-X0,
 "favourite":[318-X0,597-Y0,332,45],
 "rows":[[y0-Y0,y1-y0] for y0,y1 in ROWS],"bar":[1060-X0,1318-1060,36],"value_x":1366-X0,
 "cards":[[a-X0,b-Y0,c-a,d-b] for a,b,c,d in CARDS],"card_caption_y":777-Y0,"progress":[470-X0,797-Y0,195,14],
 "back_button":[330-X0,830-Y0,306,62],"care_button":[962-X0,828-Y0,384,68]}
(OUT/'layout.json').write_text(json.dumps(layout,indent=1))
print('ok',layout['size'])
