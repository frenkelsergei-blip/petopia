"""Green Meadows from concept P31 (torn-paper collage): Codex sheets copied
from P31 (assets/art/meadow-p31/source/*-raw.png) sliced into the world's
pieces under the names the meadow already uses. Layers keep full width."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import load, bands, rows_order, absorb
OUT=Path(__file__).resolve().parent.parent/'assets/art/meadow-p31'
import build_paper_kit as K
K.DIR=OUT
def save(img,name,limit):
    im=Image.fromarray(img);
    if max(im.size)>limit: im.thumbnail((limit,limit),Image.LANCZOS)
    im.save(OUT/f'{name}.png')
def crop(a,b):
    q=a[b[1]:b[3],b[0]:b[2]];ys,xs=np.where(q[...,3]>0);return q[ys.min():ys.max()+1,xs.min():xs.max()+1]
a=load('layers')
for b,n in zip(bands(a),['sky','mountains','hills','near']): save(crop(a,b),n,1280)
a=load('ground')
boxes=rows_order(absorb([x for x in groups(a[...,3]>0,join=2) if (x[2]-x[0])*(x[3]-x[1])>900],small=3000))
names=['ground_top','earth','cap_left','cap_right','float_big','bridge','river_water','stone']
assert len(boxes)==len(names),len(boxes)
for b,n in zip(boxes,names): save(crop(a,b),n,1280 if n in('ground_top','river_water') else 400)
a=load('props')
boxes=rows_order(absorb([x for x in groups(a[...,3]>0,join=3) if (x[2]-x[0])*(x[3]-x[1])>900],small=2500))
names=['sun','cloud_a','cloud_b','tree','signpost','flag','coin','bush','fern','flowers','front_leaves']
assert len(boxes)==len(names),len(boxes)
for b,n in zip(boxes,names): save(crop(a,b),n,600 if n=='tree' else 360)
print('ok')
