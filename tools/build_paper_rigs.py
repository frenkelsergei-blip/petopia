"""Assemble the paper puppets (explorer, foxy) from their parts by joint
rules and write <puppet>.json for the game, plus a preview PNG.
Every part: pivot = its joint in part pixels; at = where that joint sits,
relative to the feet (bottom centre). Parts listed back to front."""
import json
from pathlib import Path
from PIL import Image
DIR=Path(__file__).resolve().parent.parent/'assets/art/paper-v1'
def size(n): return Image.open(DIR/f'{n}.png').size
# The tail is drawn with its root on the left: mirror it so it trails behind.
t=Image.open(DIR/'fx_tail.png')
if not (DIR/'.tail_flipped').exists():
    t.transpose(Image.FLIP_LEFT_RIGHT).save(DIR/'fx_tail.png');(DIR/'.tail_flipped').write_text('1')

def explorer():
    lw,lh=size('ex_leg_front');tw,th=size('ex_torso');hw,hh=size('ex_head');aw,ah=size('ex_arm_front')
    hip=-lh*0.92
    neck=hip-th*0.82
    shoulder=neck+th*0.16
    parts=[
     ('ex_arm_back',(aw*0.5,aw*0.4),(10,shoulder)),
     ('ex_leg_back',(lw*0.42,lh*0.06),(-14,hip)),
     ('ex_leg_front',(lw*0.42,lh*0.06),(16,hip)),
     ('ex_torso',(tw*0.62,th*0.95),(4,hip+th*0.12)),
     ('ex_head',(hw*0.5,hh*0.9),(14,neck+hh*0.08)),
     ('ex_arm_front',(aw*0.5,aw*0.4),(26,shoulder+6)),
    ]
    return parts
def foxy():
    bw,bh=size('fx_body');fw,fh=size('fx_leg_front_near');hw,hh=size('fx_hind') if False else size('fx_leg_hind_near');Hw,Hh=size('fx_head');tw,th=size('fx_tail')
    leg=fh*0.88
    body_y=-leg-bh*0.18
    parts=[
     ('fx_tail',(tw*0.9,th*0.3),(-bw*0.42,body_y-bh*0.12)),
     ('fx_leg_front_far',(fw*0.5,fh*0.08),(bw*0.26,body_y+bh*0.2)),
     ('fx_leg_hind_far',(hw*0.5,hh*0.08),(-bw*0.3,body_y+bh*0.18)),
     ('fx_body',(bw*0.5,bh*0.5),(0,body_y)),
     ('fx_leg_hind_near',(hw*0.5,hh*0.08),(-bw*0.22,body_y+bh*0.22)),
     ('fx_leg_front_near',(fw*0.5,fh*0.08),(bw*0.34,body_y+bh*0.24)),
     ('fx_head',(Hw*0.3,Hh*0.82),(bw*0.36,body_y-bh*0.1)),
    ]
    return parts
for who,fn in (('explorer',explorer),('foxy',foxy)):
    parts=fn()
    xs=[];ys=[]
    for n,pv,at in parts:
        w,h=size(n);xs+= [at[0]-pv[0],at[0]-pv[0]+w];ys+=[at[1]-pv[1],at[1]-pv[1]+h]
    height=-min(ys)
    rig={'height':height,'parts':[{'name':n,'pivot':[round(pv[0],1),round(pv[1],1)],'at':[round(at[0],1),round(at[1],1)]} for n,pv,at in parts]}
    (DIR/f'{who}.json').write_text(json.dumps(rig,indent=1))
    W=int(max(xs)-min(xs))+20;H=int(height)+20
    img=Image.new('RGBA',(W,H),(200,220,240,255))
    for n,pv,at in parts:
        p=Image.open(DIR/f'{n}.png');img.alpha_composite(p,(int(at[0]-pv[0]-min(xs)+10),int(at[1]-pv[1]+height+10)))
    img.save(f'/private/tmp/claude-154376277/-Users-sfrenkel-Petopia/00377cb5-9802-4224-8c59-a619dec42db8/scratchpad/rig-{who}.png')
    print(who,'height',round(height))
