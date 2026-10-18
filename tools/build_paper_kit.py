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
 'critters':['hedgehog_a','hedgehog_b','hedgehog_ball','bat_a','bat_b','bat_dizzy','crab_a','crab_b','crab_dizzy','frog_a','frog_b','frog_dizzy','bee_a','bee_b','bee_dizzy'],
 'fauna':['bird_a','bird_b','bunny_sit','bunny_hop','butterfly_a','butterfly_b','squirrel','duckling'],
 'pickups':['coin','heart_pickup','pickup_apple','pickup_fish','pickup_carrot','pickup_key','pickup_note','pickup_padlock','mound','mound_glint','dug_hole','twinkle','mark_found','mark_arrow','mark_down','ball_red','sun_ball'],
 'doors':['tower_arch_open','tower_arch_locked','tower_arch_unlocked','cave','gate_home','gate_meadow','gate_river','secret_closed','secret_open','secret_slab','thorn_gate','shrine','shrine_empty','lever_off','lever_on','plate_up','plate_down','wall_closed','wall_open'],
 'tower':['tower_ext','tower_in','stone_ledge','scaffold','crumble','log_platform','thorns','crank_wheel','rope_post'],
 'cave':['cave_far','cave_back','cave_mid','crystal_ledge','cave_ground','crystals','cave_vines','cave_lantern'],
 'river':['river_water','cascade','bridge_up','bridge_down','meadow_tree','grass_fringe','leaf_a','leaf_b','leaf_c','firefly'],
}
JOIN={'critters':1}
def rows_order(boxes):
    """Reading order: rows split where the vertical centres jump, then left to right."""
    bs=sorted(boxes,key=lambda b:(b[1]+b[3])/2)
    rows=[[bs[0]]]
    for b in bs[1:]:
        prev=rows[-1]
        cy=sum((x[1]+x[3])/2 for x in prev)/len(prev)
        if (b[1]+b[3])/2-cy>90: rows.append([b])
        else: prev.append(b)
    return [b for r in rows for b in sorted(r,key=lambda b:b[0])]
LIMIT={'ground_top':1536,'earth':400,'water':1024,'mountains':1024,'hills':1024,'forest':1024,'midground':1024,'cave_far':1024,'cave_back':1024,'cave_mid':1024,'cave_ground':800,'river_water':1024,'grass_fringe':900,'tower_in':400,'tower_ext':360}
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
        found=[x for x in groups(a[...,3]>0,join=JOIN.get(sheet,4)) if (x[2]-x[0])*(x[3]-x[1])>900]
        boxes=order(found) if sheet in ('explorer','foxy','ground','meadow-props','meadow-layers') else rows_order(found)
        assert len(boxes)==len(names),(sheet,len(boxes))
        pieces={}
        for box,n in zip(boxes,names):
            q,org=crop(a,box);pieces[n]=(q,org)
            img=Image.fromarray(q)
            lim=LIMIT.get(n,360 if sheet in('explorer','foxy') else 300)
            if max(img.size)>lim: img.thumbnail((lim,lim),Image.LANCZOS)
            img.save(DIR/f'{n}.png')
    # Puppet rigs: tools/build_paper_rigs.py (run after this).
    print('ok')
