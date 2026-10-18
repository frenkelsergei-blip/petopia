"""A55 paper-theater kit: slice the Codex sheets copied from the style bible
(assets/art/paper-v1/source/<sheet>-raw.png, prompts beside them) into pieces,
and build the puppet rigs (explorer, foxy): each part is matched against the
assembled figure on the same sheet to find where it sits; pivots are the
joints. Output: assets/art/paper-v1/<piece>.png and <puppet>.json."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups, order
ROOT=Path(__file__).resolve().parent.parent
DIR=ROOT/'assets/art/paper-v1'
SHEETS={
 'explorer':['explorer_full','ex_head','ex_torso','ex_arm_front','ex_arm_back','ex_leg_front','ex_leg_back'],
 'foxy':['foxy_full','fx_head','fx_body','fx_leg_front_near','fx_leg_front_far','fx_leg_hind_near','fx_leg_hind_far','fx_tail'],
 'ground':['ground_top','earth','cap_left','cap_right','waterfall','float_small','float_big','water'],
 'meadow-props':['cloud_a','cloud_b','cloud_c','sun','tree_round','pine','bush','flowers','windmill','windmill_sails','signpost','crate','chest','chest_open','lantern','lantern_lit','fence','stone','bridge'],
 'meadow-layers':['mountains','hills','forest','midground'],
}
LIMIT={'ground_top':1536,'earth':400,'water':1024,'mountains':1024,'hills':1024,'forest':1024,'midground':1024}
def load(sheet):
    raw=np.asarray(Image.open(DIR/'source'/f'{sheet}-raw.png').convert('RGB')).astype(int)
    r,g,b=raw[...,0],raw[...,1],raw[...,2]
    bg=(r>150)&(b>150)&(g<r-80)&(g<b-80)
    edge=(r>110)&(b>110)&(g<r-40)&(g<b-40)&~bg
    rgb=raw.copy();rgb[edge]=(rgb[edge]*0.3).astype(int)+[40,25,15]
    return np.dstack([rgb,np.where(bg,0,np.where(edge,140,255))]).astype(np.uint8)
def crop(a,box):
    x0,y0,x1,y1=box;q=a[y0:y1,x0:x1];ys,xs=np.where(q[...,3]>0)
    return q[ys.min():ys.max()+1,xs.min():xs.max()+1],(x0+xs.min(),y0+ys.min())
def register(full,part):
    """Offset of `part` inside `full` (same scale), by colour match on opaque pixels."""
    F=full[::2,::2].astype(float);P=part[::2,::2].astype(float)
    pm=P[...,3]>200;best=(1e18,0,0)
    for y in range(0,F.shape[0]-P.shape[0]+1):
        for x in range(0,F.shape[1]-P.shape[1]+1):
            win=F[y:y+P.shape[0],x:x+P.shape[1]]
            m=pm&(win[...,3]>200)
            if m.sum()<pm.sum()*0.35: continue
            d=np.abs(win[...,:3][m]-P[...,:3][m]).mean()+40*(1-m.sum()/pm.sum())
            if d<best[0]: best=(d,x,y)
    return best[1]*2,best[2]*2,best[0]
# Joint (pivot) of each part, as fractions of the part's own size.
PIVOT={'ex_head':(0.55,0.9),'ex_torso':(0.6,0.95),'ex_arm_front':(0.5,0.08),'ex_arm_back':(0.5,0.08),'ex_leg_front':(0.5,0.05),'ex_leg_back':(0.5,0.05),
 'fx_head':(0.3,0.8),'fx_body':(0.5,0.5),'fx_leg_front_near':(0.5,0.1),'fx_leg_front_far':(0.5,0.1),'fx_leg_hind_near':(0.5,0.1),'fx_leg_hind_far':(0.5,0.1),'fx_tail':(0.12,0.35)}
# Draw order back to front.
ZORDER={'explorer':['ex_arm_back','ex_leg_back','ex_leg_front','ex_torso','ex_head','ex_arm_front'],
 'foxy':['fx_tail','fx_leg_front_far','fx_leg_hind_far','fx_body','fx_leg_hind_near','fx_leg_front_near','fx_head']}
if __name__=='__main__':
    for sheet,names in SHEETS.items():
        a=load(sheet)
        boxes=order([x for x in groups(a[...,3]>0,join=4) if (x[2]-x[0])*(x[3]-x[1])>900])
        assert len(boxes)==len(names),(sheet,len(boxes))
        pieces={}
        for box,n in zip(boxes,names):
            q,org=crop(a,box);pieces[n]=(q,org)
            img=Image.fromarray(q)
            lim=LIMIT.get(n,360 if sheet in('explorer','foxy') else 300)
            if max(img.size)>lim: img.thumbnail((lim,lim),Image.LANCZOS)
            img.save(DIR/f'{n}.png')
        if sheet in ('explorer','foxy'):
            full,_=pieces[names[0]]
            fh,fw=full.shape[:2]
            rig={'height':fh,'parts':[]}
            for n in ZORDER[sheet]:
                q,_=pieces[n]
                x,y,score=register(full,q)
                h,w=q.shape[:2];px,py=PIVOT[n]
                scale=min(1.0,360/max(w,h))
                # Positions relative to the feet (bottom centre of the assembled figure).
                rig['parts'].append({'name':n,'size':[w,h],'scale':scale,'pivot':[px*w,py*h],'at':[x+px*w-fw/2,y+py*h-fh],'fit':round(score,1)})
                print(sheet,n,(x,y),'fit',round(score,1))
            (DIR/f'{sheet}.json').write_text(json.dumps(rig,indent=1))
    print('ok')
