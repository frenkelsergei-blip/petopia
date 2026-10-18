"""A55 paper UI kit: the shared pieces (panel, card, tile, planks, switches,
slider, round button, tag, rows, wallet, divider, field, vine) copied from the
paper concepts P15/P12 by Codex (source/kit-raw.png) -> assets/ui/kit-paper/,
with kit.json in the format of assets/ui/kit-v1 (same piece names, so every
screen that uses the shared kit turns paper; missing pieces fall back)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import rows_order, absorb
OUT=Path(__file__).resolve().parent.parent/'assets/ui/kit-paper'
raw=np.asarray(Image.open(OUT/'source/kit-raw.png').convert('RGB')).astype(int)
r,g,b=raw[...,0],raw[...,1],raw[...,2]
a=np.dstack([raw,np.where((r>150)&(b>150)&(g<r-80)&(g<b-80),0,255)]).astype(np.uint8)
NAMES=['panel','card','tile','tile_gold','pill_cream','pill_gold','pill_green','ribbon_cream','switch_on','switch_off','meter_track','meter_fill','knob','round','tag','row','row_gold','wallet','divider','field','vine_corner']
boxes=rows_order(absorb([x for x in groups(a[...,3]>0,join=3) if (x[2]-x[0])*(x[3]-x[1])>400],small=2500))
assert len(boxes)==len(NAMES),len(boxes)
# slice: nine (margin as fraction of the short side), three (cap as fraction of height), fixed
SLICE={'panel':('nine',0.17),'card':('nine',0.2),'tile':('nine',0.2),'tile_gold':('nine',0.2),
 'pill_cream':('three',0.62),'pill_gold':('three',0.62),'pill_green':('three',0.62),'ribbon_cream':('three',0.95),
 'meter_track':('three',0.5),'meter_fill':('three',0.5),'tag':('three',0.55),'row':('three',0.62),'row_gold':('three',0.62),
 'wallet':('three',0.55),'divider':('three',0.4),'field':('three',0.5)}
spec={}
def save(n,img):
    img.save(OUT/f'{n}.png');w,h=img.size
    kind,f=SLICE.get(n,('fixed',0))
    e={'size':[w,h],'slice':kind}
    if kind=='nine': e['margin']=round(min(w,h)*f)
    if kind=='three': e['cap']=round(h*f)
    spec[n]=e
for (x0,y0,x1,y1),n in zip(boxes,NAMES):
    q=a[y0:y1,x0:x1];yy,xx=np.where(q[...,3]>0)
    save(n,Image.fromarray(q[yy.min():yy.max()+1,xx.min():xx.max()+1]))
def derive(n,src,fn):
    SLICE.setdefault(n,SLICE.get(src,('fixed',0)))
    save(n,fn(Image.open(OUT/f'{src}.png').convert('RGBA')))
dark=lambda im:Image.merge('RGBA',(*ImageEnhance.Brightness(im.convert('RGB')).enhance(0.86).split(),im.split()[3]))
grey=lambda im:Image.merge('RGBA',(*ImageEnhance.Brightness(ImageEnhance.Color(im.convert('RGB')).enhance(0.15)).enhance(0.95).split(),im.split()[3]))
same=lambda im:im
derive('pill_gold_pressed','pill_gold',dark);derive('pill_cream_pressed','pill_cream',dark)
derive('pill_disabled','pill_cream',grey);derive('pill_selected','pill_gold',same)
derive('round_pressed','round',dark);derive('hud_plank','pill_cream',same);derive('ribbon_region','ribbon_cream',same)
derive('leaf_small','vine_corner',same)
# The fill is tinted per meter by the game: keep it a light neutral paper.
derive('meter_fill','meter_fill',lambda im:Image.merge('RGBA',(*ImageEnhance.Brightness(ImageEnhance.Color(im.convert('RGB')).enhance(0.0)).enhance(1.9).split(),im.split()[3])))
(OUT/'kit.json').write_text(json.dumps(spec,indent=1))
print('ok',len(spec))
