"""A55 paper HUD pieces from the Codex sheet copied from P10
(assets/ui/paper-v1/source/hud-raw.png, prompt beside it) -> assets/ui/paper-v1/<name>.png."""
import sys
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import rows_order
import numpy as np
OUT=Path(__file__).resolve().parent.parent/'assets/ui/paper-v1'
NAMES=['stick_base','stick_knob','btn_orange','btn_blue','btn_blue2','status_card','coin_pill','icon_button',
 'ic_find','ic_use','ic_jump','ic_map','ic_bag','ic_gear','coin','rope_long','rope_short','heart_full','heart_empty','bar_orange','bar_blue','bar_track']
raw=np.asarray(Image.open(OUT/'source/hud-raw.png').convert('RGB')).astype(int)
r,g,b=raw[...,0],raw[...,1],raw[...,2]
alpha=np.where((r>150)&(b>150)&(g<r-80)&(g<b-80),0,255)
a=np.dstack([raw,alpha]).astype(np.uint8)
boxes=rows_order([x for x in groups(alpha>0,join=3) if (x[2]-x[0])*(x[3]-x[1])>900])
assert len(boxes)==len(NAMES),len(boxes)
for (x0,y0,x1,y1),n in zip(boxes,NAMES):
    q=a[y0:y1,x0:x1];ys,xs=np.where(q[...,3]>0)
    img=Image.fromarray(q[ys.min():ys.max()+1,xs.min():xs.max()+1])
    img.thumbnail((240,240) if n not in('status_card','coin_pill','rope_long') else (700,700),Image.LANCZOS)
    img.save(OUT/f'{n}.png')
print('ok')
