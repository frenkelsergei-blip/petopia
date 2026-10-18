"""A56 paper pet room from concept P20: clean plate (Codex edit of P20 with
characters, furniture, bowls, spots and insets removed) and the room props
copied from P20 (bed and tub as back/front layers so Foxy can lie/sit inside,
bowls empty/full, bag, can, streams, bubbles, foam, drop, Z, heart, duck,
curled sleeping Foxy) -> assets/ui/room-paper/."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import rows_order, absorb
from build_icon_sheets import key
OUT=Path(__file__).resolve().parent.parent/'assets/ui/room-paper'
im=Image.open(OUT/'source/plate3-raw.png').convert('RGB');im.thumbnail((1280,1280),Image.LANCZOS);im.save(OUT/'plate.png')
raw=np.asarray(Image.open(OUT/'source/props-raw.png').convert('RGB')).astype(int)
r,g,b=raw[...,0],raw[...,1],raw[...,2]
a=np.dstack([raw,np.where((r>150)&(b>150)&(g<r-80)&(g<b-80),0,255)]).astype(np.uint8)
soft=key(raw.astype(np.uint8))
NAMES=['bed_back','bed_front','tub_back','tub_front','bowl_food','bowl_food_full','bowl_water','bowl_water_full','kibble_bag','watering_can','kibble_stream','water_stream',
 'bubble','bubbles','foam','drop','zzz','heart','duck','fox_sleep']
boxes=rows_order(absorb([x for x in groups(a[...,3]>0,join=3) if (x[2]-x[0])*(x[3]-x[1])>150],small=3000))
assert len(boxes)==len(NAMES),len(boxes)
for (x0,y0,x1,y1),n in zip(boxes,NAMES):
    src=soft if n in('bubble','bubbles','water_stream','drop') else a
    q=src[y0:y1,x0:x1];yy,xx=np.where(q[...,3]>8)
    p=Image.fromarray(q[yy.min():yy.max()+1,xx.min():xx.max()+1])
    p.thumbnail((300,300),Image.LANCZOS);p.save(OUT/f'{n}.png')
print('ok',im.size)
