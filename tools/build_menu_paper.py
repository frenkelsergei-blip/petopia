"""A55 main menu from concept P11: clean background plate (Codex edit of the
concept with every UI piece and word removed) and the UI kit copied from it
(assets/ui/menu-paper/source/*-raw.png) -> assets/ui/menu-paper/*.png.
Words are drawn live by the game."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import rows_order, split_gaps
OUT=Path(__file__).resolve().parent.parent/'assets/ui/menu-paper'
plate=Image.open(OUT/'source/plate-raw.png').convert('RGB')
plate.thumbnail((1280,1280),Image.LANCZOS);plate.save(OUT/'plate.png')
raw=np.asarray(Image.open(OUT/'source/kit-raw.png').convert('RGB')).astype(int)
r,g,b=raw[...,0],raw[...,1],raw[...,2]
alpha=np.where((r>150)&(b>150)&(g<r-80)&(g<b-80),0,255)
a=np.dstack([raw,alpha]).astype(np.uint8)
def merge(boxes):
    """Pieces whose boxes overlap (a paw's toes) are one piece."""
    out=[list(b) for b in boxes];changed=True
    while changed:
        changed=False
        for i in range(len(out)):
            for j in range(i+1,len(out)):
                p,q=out[i],out[j]
                if p[0]<q[2] and q[0]<p[2] and p[1]<q[3] and q[1]<p[3]:
                    out[i]=[min(p[0],q[0]),min(p[1],q[1]),max(p[2],q[2]),max(p[3],q[3])];del out[j];changed=True;break
            if changed: break
    return [tuple(b) for b in out]
NAMES=['logo','tagline','plank_green','plank_cream','plank_grey','plank_small','coin_plaque','ic_play','ic_paw','ic_map','ic_lock','ic_pad','ic_gear','coin']
boxes=rows_order(merge(split_gaps(a,[x for x in groups(alpha>0,join=1) if (x[2]-x[0])*(x[3]-x[1])>900],gap=3)))
assert len(boxes)==len(NAMES),len(boxes)
for (x0,y0,x1,y1),n in zip(boxes,NAMES):
    q=a[y0:y1,x0:x1];ys,xs=np.where(q[...,3]>0)
    img=Image.fromarray(q[ys.min():ys.max()+1,xs.min():xs.max()+1])
    img.thumbnail((900,900) if n=='logo' else (520,520) if n.startswith('plank') or n in('tagline','coin_plaque') else (140,140),Image.LANCZOS)
    img.save(OUT/f'{n}.png')
print('ok',plate.size)
