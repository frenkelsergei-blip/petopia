"""A55 screens built from their concepts (P15, P17, P21-P26): each kit has a
Codex sheet copied from its concept (assets/ui/<kit>/source/sheet-raw.png)
and, where the screen has a scene, a clean base (Codex edit of the concept
with every word and changing part removed). Slices pieces in reading order
into assets/ui/<kit>/<name>.png and writes a labelled check image."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import rows_order, absorb, split_gaps
from build_icon_sheets import key
ROOT=Path(__file__).resolve().parent.parent
CHECK='/private/tmp/claude-154376277/-Users-sfrenkel-Petopia/00377cb5-9802-4224-8c59-a619dec42db8/scratchpad/'
KITS={
 'roomui-paper':['status','meter_chip','meter_track','menu_button','care_button','close','board','board_title','tile','tile_on',
   'ic_feed','ic_water','ic_bath','ic_pet','ic_rest','ic_play','need_food','need_energy','need_clean','need_happy','ic_paw'],
 'settings-paper':['pause_panel','settings_panel','title','plank_green','plank_cream','paused_tag','track','fill','knob','toggle_on','toggle_off','stepper','controls','divider',
   'ic_music','ic_sound','ic_voice','ic_motion','ic_hint','ic_timing','ic_controls','resting'],
 'map-paper':['back_plank','nav','nav_on','coin_plaque','gear','region_title','stop','check','lock','dot','basket','start','back',
   'side_board','picture','info','fox_chip','world_card','beach','forest','footer'],
 'areamap-paper':['title','close','label','pin','chest','lock','cloud','legend','dot'],
 'adoption-paper':['card','portrait','tag','field','adopt','back','ic_paw','ic_leaf','ic_back','fox','coin_plaque','gear'],
 'result-paper':['board','tile','earned','my_pet','play_again','title','coin_plaque','coin','berries','heart','ic_paw','ic_play','confetti'],
 'ball-paper':['track','band','marker','catches','hint','back','coin_plaque','gear','throw','ic_sun','ball'],
 'turn-paper':['card','phones','plank','ic_paw','ic_house','explorer','fox','sun','cloud'],
}
SMALL={}
JOIN={}
PAD={'result-paper':60,'turn-paper':30}
GLUE={'turn-paper':(390,170,820,470)}
BIT={'result-paper':5000,'turn-paper':2600}
SOFT={'confetti','cloud','band'}
def near_merge(boxes,pad,bit=2600):
    """Bits of one piece (paw toes, stars around a moon, the heart over a
    hand): a box much smaller than a neighbour within `pad` joins it."""
    out=[list(b) for b in boxes]
    area=lambda b:(b[2]-b[0])*(b[3]-b[1])
    gap=lambda p,q:max(p[0]-q[2],q[0]-p[2],p[1]-q[3],q[1]-p[3],0)
    changed=True
    while changed:
        changed=False
        for i,b in enumerate(out):
            if area(b)>bit: continue
            cands=[o for o in out if o is not b and gap(b,o)<=pad and area(o)>2.2*area(b)]
            if cands:
                t=min(cands,key=lambda o:gap(b,o))
                t[:]=[min(t[0],b[0]),min(t[1],b[1]),max(t[2],b[2]),max(t[3],b[3])]
                del out[i];changed=True;break
    return [tuple(b) for b in out]
def hard(path):
    raw=np.asarray(Image.open(path).convert('RGB')).astype(int)
    r,g,b=raw[...,0],raw[...,1],raw[...,2]
    return raw,np.dstack([raw,np.where((r>150)&(b>150)&(g<r-80)&(g<b-80),0,255)]).astype(np.uint8)
def build(kit,names):
    out=ROOT/'assets/ui'/kit
    raw,a=hard(out/'source/sheet-raw.png');soft=key(raw.astype(np.uint8))
    boxes=rows_order(absorb(near_merge(split_gaps(a,[x for x in groups(a[...,3]>0,join=JOIN.get(kit,1)) if (x[2]-x[0])*(x[3]-x[1])>40],gap=2),PAD.get(kit,10),BIT.get(kit,2600)),small=SMALL.get(kit,500)))
    if kit in GLUE:
        x0,y0,x1,y1=GLUE[kit];inside=[b for b in boxes if b[0]>=x0 and b[1]>=y0 and b[2]<=x1 and b[3]<=y1]
        if inside:
            m=(min(b[0] for b in inside),min(b[1] for b in inside),max(b[2] for b in inside),max(b[3] for b in inside))
            boxes=rows_order([b for b in boxes if b not in inside]+[m])
    check=Image.fromarray(a).convert('RGB');d=ImageDraw.Draw(check)
    for i,(x0,y0,x1,y1) in enumerate(boxes):
        d.rectangle((x0,y0,x1,y1),outline=(0,0,0),width=2);d.text((x0+3,y0+3),str(i)+(':'+names[i] if i<len(names) else ''),fill=(0,0,0))
    check.save(CHECK+f'kit-{kit}.png')
    if len(boxes)!=len(names): print('COUNT',kit,len(boxes),len(names));return
    for (x0,y0,x1,y1),n in zip(boxes,names):
        src=soft if n in SOFT else a
        q=src[y0:y1,x0:x1];yy,xx=np.where(q[...,3]>8)
        Image.fromarray(q[yy.min():yy.max()+1,xx.min():xx.max()+1]).save(out/f'{n}.png')
    b=out/'source/base-raw.png'
    if b.exists():
        _,base=hard(b)
        im=Image.fromarray(base);
        if base[...,3].min()==255: im=im.convert('RGB')
        im.thumbnail((1280,1280),Image.LANCZOS);im.save(out/'base.png')
    print('ok',kit)
if __name__=='__main__':
    for kit,names in KITS.items():
        if len(sys.argv)<2 or kit in sys.argv[1:]: build(kit,names)
