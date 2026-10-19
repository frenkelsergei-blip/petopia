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
 'hud2-p32':['disc_green','disc_cream','disc_gold','w_paw','w_up','w_dig','w_enter','w_open','w_pick','w_place','n_use','n_enter','n_open','n_pick','n_place','n_talk','n_find'],
 'hud-p32':['portrait','heart_full','heart_empty','track','fill_green','fill_blue','banner','coins','btn_map','btn_bag','btn_gear','stick_base','stick_knob','btn_find','btn_use','btn_jump'],
 'menu-p32':['logo','panel','start','button','games','settings','coins','ic_pad','ic_gear','pair'],
 'hud3-p32':['ic_food','ic_energy'],
 'roomui-p32':['status','portrait','track','fill_green','fill_navy','fill_blue','fill_yellow','ic_food','ic_energy','ic_clean','ic_happy','coins','menu','board','board_title','close','tile','big_feed','big_water','big_bath','big_pet','big_rest','big_play','care_plank'],
 'bag-p32':['title','ic_bag','board','side','close','tab_on','tab','slot','slot_on','count','slot_empty','blob','give','apple','fish','carrot','crate','key','blueberries','mushroom','leaf','egg','log','acorn','stone'],
 'shop-p32':['title','ic_stall','coins','close','board','tab_on','tab','ic_leaf','ic_ball','ic_house','card','card_on','price','coin','side','buy','berries','apple','fish','cookie','carrot','collar','ball','cushion'],
 'map-p32':['back','title','sprig','map','node','node_now','check','lock','side','meadows','start','world_card','beach','forest','later','cloud'],
 'details-p32':['title','board','photo','name','pill_green','pill_blue','pill_yellow','row','track','fill_green','fill_yellow','fill_blue','ic_food','ic_happy','ic_energy','ic_clean','ic_health','ic_bond','growth','stage','stage_on','fox_baby','fox_child','fox_teen','fox_adult','star','back','care'],
 'loading-p32':['logo','fox','card','track','fill','paw','play','news'],
 'collect-p32':['back','title','board','section','portrait','locked_cat','locked_pup','slot','sticker_picnic','sticker_windmill','slot_empty','plank'],
 'games-p32':['title','card','card_title','pic_ball','pic_hide','pic_dig','info','play','reward','heart','paw'],
 'areamap-p32':['board','close','map','pin','label','chest','lock','cloud','legend','robot'],
 'popup-p32':['ability','frame','pill','gotit','toast','set_title','set_card','toggle_on','arrow_l','arrow_r','slider','all','done'],
 'decor-p32':['title','tray','close','card','card_on','place','price','done','plus','sun_ball','cushion','lamp','pot','picture'],
 'menu50-p32':['title','close','board','tile','ic_details','ic_map','ic_shop','ic_games','ic_collection','ic_bag','ic_settings','ic_home'],
 'adopt-p32':['title','card','pill_green','pill_blue','field','adopt','paw','back','arrow'],
 'result-p32':['title','coins','row','total','coin','board','ic_map','ic_leaf','basket','check','mypet','paw','again'],
 'food-p32':['title','close','board','tile','tile_off','free','count','shop','heart','kibble','berries','apple','fish','cookie','carrot'],
 'ball-p32':['back','title','coins','score','paw_on','paw_off','meter','marker','hint','throw','ic_ball','ball'],
 'turn-p32':['card','phones','plank','ic_house','cloud','sun'],
 'pause-p32':['title','card','panel','close','resume','button','track','fill','knob','toggle_on','toggle_off','arrow_l','arrow_r','field','picture','ic_music','ic_sound','ic_mic','ic_pin','ic_bulb','ic_resize','ic_hand'],
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
PAD={'turn-paper':30,'pause-p32':22}
CUT={'result-paper':[1368]}
GLUE={'roomui-p32':(30,745,240,960),'turn-paper':(390,170,820,470),'result-paper':(1210,600,1510,830)}
BIT={'result-paper':5000,'turn-paper':2600}
SOFT={'confetti','cloud','band'}
def merge(boxes):
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
    # Boxes that overlap are parts of one piece (a microphone and its stand).
    boxes=rows_order(merge(boxes))
    for cx in CUT.get(kit,[]):
        nb=[]
        for b in boxes:
            if b[0]<cx<b[2]: nb+= [(b[0],b[1],cx,b[3]),(cx,b[1],b[2],b[3])]
            else: nb.append(b)
        boxes=rows_order(nb)
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
