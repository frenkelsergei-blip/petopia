"""A57 world art pipeline. Every world piece is redrawn in the current world
style from its environment concept and cut under the name the game uses.

  python3 tools/world_style.py draw [sheet...]   # Codex draws the sheets
  python3 tools/world_style.py cut  [sheet...]   # slice into OUT
  godot -s tools/audit_world_art.gd               # nothing old may remain

Concepts: P31 meadow, P33 cave, P34 tower, P35 river/forest gate, P36 cellar.
Sheets keep their piece order; each cut writes a numbered check image."""
import subprocess, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import groups
from build_paper_kit import rows_order, absorb, bands
from build_screen_paper import near_merge
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/art/meadow-p31'
SRC=OUT/'source'
CON=ROOT/'assets/concepts/current/paper-v1'
CHECK=Path('/private/tmp/claude-154376277/-Users-sfrenkel-Petopia/00377cb5-9802-4224-8c59-a619dec42db8/scratchpad')
# sheet: (concept, [(name, description)], strips?)
SHEETS={
 'markers':('P35-river',[('chest','a closed wooden treasure chest'),('chest_open','the same chest open with gold glow'),('crate','a wooden crate'),('mound','a small mound of earth with paw prints (dig spot)'),('mound_glint','the same mound with a golden sparkle'),('dug_hole','a small dug hole with crumbs'),('twinkle','a golden four-point twinkle'),('flag_down','a small checkpoint pole with a pale grey flag hanging low'),('flag_up','the same pole with the red flag raised high and waving'),('mark_found','a round cream speech bubble with an orange exclamation mark'),('mark_arrow','a chunky golden paper arrow pointing right'),('mark_down','the same arrow pointing down'),('lantern','a small hanging paper lantern unlit'),('lantern_lit','the same lantern glowing')],False),
 'pickups':('P31-meadows',[('pickup_apple','a red apple'),('pickup_fish','a small blue fish snack'),('pickup_carrot','a golden magic carrot with sparkles'),('pickup_key','a golden key'),('pickup_note','a folded paper note'),('pickup_padlock','a golden padlock'),('heart_pickup','a red folded-paper heart'),('sky_feather','a rainbow feather'),('ball_red','a red ball'),('sun_ball','a yellow sun ball')],False),
 'structures':('P35-river',[('tower_ext','the round ivy-covered stone tower exterior with a wooden door, tall'),('cave','a dark cave mouth in a grey paper rock'),('thorn_gate','a thorny bramble gate'),('crank_wheel','a wooden crank wheel with handle'),('rope_post','a short wooden bridge post'),('windmill','a windmill tower without sails'),('windmill_sails','the windmill sails alone'),('gate_home','a white cottage picket gate under a rose arch'),('gate_meadow','a rustic flower arch gateway'),('gate_river','a timber gate with a small fish sign'),('secret_closed','a hillside stone slab door with a paw rune, closed'),('secret_open','the same doorway open with warm light inside'),('secret_slab','the stone slab alone')],False),
 'tower_doors':('P34-tower',[('tower_arch_open','a round-topped stone archway with its wooden door open'),('tower_arch_locked','the same archway closed with a big golden padlock'),('tower_arch_unlocked','the same archway open with the padlock hanging open'),('lever_off','a lever pointing left'),('lever_on','the same lever pointing right'),('plate_up','a stone pressure plate raised'),('plate_down','the same plate pressed down'),('wall_closed','a stone gate closed'),('wall_open','the same gate open'),('shrine','a glowing shrine with a feather on top'),('shrine_empty','the same shrine empty, softly glowing')],False),
 'critters':('P35-river',[('hedgehog_a','a round hedgehog walking, step A'),('hedgehog_b','the hedgehog, step B'),('hedgehog_ball','the hedgehog rolled into a ball'),('frog_a','a green frog with a lily-pad hat, sitting'),('frog_b','the frog mid-hop'),('frog_dizzy','the frog dizzy with little stars'),('bee_a','a fluffy bumblebee wings up'),('bee_b','the bee wings down'),('bee_dizzy','the bee dizzy'),('bat_a','a chubby purple bat wings up'),('bat_b','the bat wings down'),('bat_dizzy','the bat dizzy'),('crab_a','a teal crab with a blue crystal on its back'),('crab_b','the crab, other step'),('crab_dizzy','the crab dizzy'),('hedgehog_dizzy','the hedgehog dizzy')],False),
 'fauna':('P31-meadows',[('bird_a','a small blue bird wings up'),('bird_b','the bird wings down'),('bunny_sit','a white bunny sitting'),('bunny_hop','the bunny mid-hop'),('butterfly_a','an orange butterfly wings open'),('butterfly_b','the butterfly wings closed'),('squirrel','a brown squirrel holding an acorn'),('duckling','a yellow duckling')],False),
 'moss':('P31-meadows',[('moss_idle','Moss, a friendly cream-white bunny with a little green vest, standing upright, side view facing right'),('moss_wave','Moss waving one paw high'),('moss_happy','Moss jumping with both paws up')],False),
 'cave_layers':('P33-cave',[('cave_far','FAR cavern wall strip (deep indigo torn paper, distant glowing crystals), full width, seamless, 260 tall'),('cave_back','DISTANT stalagmites and arches strip with stalactites along its top, full width, seamless, 240 tall'),('cave_mid','NEAR crystal pillars strip, full width, seamless, 220 tall')],True),
 'cave_kit':('P33-cave',[('cave_ground','a cave GROUND TOP strip: dark violet patterned paper with a torn lilac top edge, seamless left-right, 1000 wide 110 tall'),('cave_fill','a square dark blue-violet patterned paper fill tile, seamless, 300x300'),('crystal_ledge','a floating crystal ledge platform'),('crystals','a cluster of glowing pale-cyan crystals'),('cave_vines','hanging vines with glowing bulbs'),('cave_lantern','a cave lantern')],False),
 'cave_back3':('P33-cave',[('cv_far','FARTHEST layer: the deep cavern back wall with the light shafts falling from above and soft glow, full width, seamless left-right, 300 tall'),('cv_mid','MIDDLE layer: the distant stalagmite pillars and rock arches in violet, with the small waterfall, full width, seamless, 260 tall'),('cv_top','CEILING strip: the hanging stalactites with vines and glowing bulbs, full width, seamless, 200 tall, flat TOP edge')],True),
 'tower_back3':('P34-tower',[('tw_far','FARTHEST layer: the big sandstone hall with tall arched windows showing sky and a castle, red banners, a staircase, full width, seamless left-right, 320 tall'),('tw_mid','MIDDLE layer: sandstone pillars and arches with ivy and wall torches, full width, seamless, 280 tall')],True),
 'cellar_back3':('P36-cellar',[('ce_far','FARTHEST layer: the warm stone cellar wall with the huge wooden windmill gears and beams, full width, seamless left-right, 320 tall'),('ce_mid','MIDDLE layer: wooden support beams, a hanging lantern, flour sacks and barrels along the bottom, full width, seamless, 260 tall'),('ce_ground','a cellar GROUND TOP strip: packed earth with a wooden plank edge, seamless, 1000 wide 100 tall'),('ce_fill','a square seamless earthy stone fill tile, 300x300')],False),
 'tower_kit':('P34-tower',[('tower_in','a square seamless sandstone tower WALL tile with one arched window showing sky and a little ivy, 360x360'),('stone_fill','a square seamless sandstone block fill tile, 300x300'),('stone','a stone ground TOP strip with a torn cream edge, seamless, 1000 wide 100 tall'),('stone_ledge','a sandstone ledge platform'),('scaffold','a wooden scaffold platform'),('crumble','a crumbling stone step'),('log_platform','a floating log raft platform'),('thorns','a strip of green paper thorns')],False),
}
H='''Use your built-in image generation tool to create ONE image, then save it (copy the generated PNG) to exactly this path:
{path}
Do not modify any other file. Do not write code. When finished, reply with the saved path only.

Copy EXACTLY the look, colours and torn-paper collage technique of the attached PETOPIA concept (layered torn paper, soft fibrous torn edges, watercolour paper tones, simple clean shapes, no brass pins, no cardboard). If an element below appears in the concept, copy it exactly as drawn there. PRODUCTION SPRITE SHEET for a 2D game engine, canvas 1536x1024: every element fully separate with at least 50 px of FLAT SOLID pure magenta (#FF00FF) around it, NO shadows on the magenta, NO text, NO numbers, NO characters except the creatures listed. Side view facing RIGHT for creatures. Arrange the elements in rows, left to right, in EXACTLY this order and count ({n} elements):
{items}'''
def draw(names):
    for s in names:
        con,items,_=SHEETS[s]
        SRC.mkdir(parents=True,exist_ok=True)
        p=SRC/f'w-{s}-prompt.txt'
        p.write_text(H.format(path=SRC/f'w-{s}-raw.png',n=len(items),items='\n'.join(f'({i+1}) {d}' for i,(_,d) in enumerate(items))))
        subprocess.Popen(['codex','exec','-s','danger-full-access','-i',str(CON/f'{con}.png'),'-'],stdin=open(p),stdout=open(CHECK/f'codex-w-{s}.log','w'),stderr=subprocess.STDOUT,cwd=ROOT)
        print('drawing',s)
def key(path):
    raw=np.asarray(Image.open(path).convert('RGB')).astype(int)
    r,g,b=raw[...,0],raw[...,1],raw[...,2]
    bg=(r>150)&(b>150)&(g<r-80)&(g<b-80)
    edge=(r>110)&(b>110)&(g<r-40)&(g<b-40)&~bg
    rgb=raw.copy();rgb[edge]=(rgb[edge]*0.3).astype(int)+[40,25,15]
    return np.dstack([rgb,np.where(bg,0,np.where(edge,120,255))]).astype(np.uint8)
def cut(names):
    ok=True
    for s in names:
        _,items,strips=SHEETS[s]
        a=key(SRC/f'w-{s}-raw.png')
        boxes=bands(a) if strips else rows_order(near_merge(absorb([x for x in groups(a[...,3]>0,join=3) if (x[2]-x[0])*(x[3]-x[1])>300],small=2500),30,9000))
        c=Image.fromarray(a).convert('RGB');d=ImageDraw.Draw(c)
        for i,b in enumerate(boxes): d.rectangle(b,outline=(0,0,0),width=2);d.text((b[0]+3,b[1]+3),f'{i}:{items[i][0] if i<len(items) else "?"}',fill=(0,0,0))
        c.save(CHECK/f'w-{s}.png')
        if len(boxes)!=len(items): print('COUNT',s,len(boxes),'want',len(items));ok=False;continue
        for b,(n,_) in zip(boxes,items):
            q=a[b[1]:b[3],b[0]:b[2]];ys,xs=np.where(q[...,3]>0)
            im=Image.fromarray(q[ys.min():ys.max()+1,xs.min():xs.max()+1])
            lim=1280 if strips or n in('cave_ground','stone') else (600 if n in('tower_ext',) else 360)
            if max(im.size)>lim: im.thumbnail((lim,lim),Image.LANCZOS)
            im.save(OUT/f'{n}.png')
        print('cut',s)
    return ok
if __name__=='__main__':
    cmd=sys.argv[1];names=sys.argv[2:] or list(SHEETS)
    {'draw':draw,'cut':cut}[cmd](names)
