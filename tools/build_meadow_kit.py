"""Slice the Codex Green Meadows sprite sheets into one transparent PNG per
piece (assets/art/meadows-v2/<name>.png) plus kit.json with sizes.
Reuses the UI-kit slicer (magenta key, gap-joined pieces, reading order)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_ui_kit import key, groups, order
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets/art/meadows-v2/source';OUT=ROOT/'assets/art/meadows-v2'
NAMES={
 'ground':['ground_top','cap_left','cap_right','float_big','float_small','earth','bridge','stone'],
 'props':['sign','crate','chest','chest_open','lamp','fence','shrine','thorn_gate','cave','door','robot_head','robot_arm','robot_wheel','flower_bush','boulder'],
 'passages':['arch','tower_door','windmill','windmill_sails','lantern_unlit','lantern_lit','arrow_sign'],
 'hazards':['thorns','hedgehog_a','hedgehog_b','hedgehog_ball','log_platform','crumble','heart_pickup'],
 'puzzle':['plate_up','plate_down','lever_off','lever_on','wall_closed','wall_open','plane_propeller','star'],
 'pickups':['pickup_apple','pickup_carrot','pickup_fish','pickup_key','pickup_note','pickup_padlock'],
 'fauna':['bird_a','bird_b','bunny_sit','bunny_hop','butterfly_a','butterfly_b','squirrel','duckling'],
 'critters':['bat_a','bat_b','bat_dizzy','crab_a','crab_b','crab_dizzy','frog_a','frog_b','frog_dizzy','bee_a','bee_b','bee_dizzy'],
 'doors':['tower_arch_open','tower_arch_locked','tower_arch_unlocked','secret_closed','secret_open','secret_slab'],
 'digspot':['mound','mound_glint','dug_hole','twinkle'],
 'markers':['mark_found','mark_arrow','mark_down'],
 'gates':['gate_home','gate_meadow','gate_river'],
 'tower':['tower_wall','stone_ledge','scaffold','lantern','cave_wall','crystal_ledge','crystals','cave_vines'],
}
# left, top, right, bottom pixels removed from repeating pieces
TRIM={'ground_top':'sides','earth':'all','stone':'sides','tower_wall':'all','cave_wall':'all'}
# Terrain/structure pieces are drawn large; never downscale them.
KEEP={'wall_closed','wall_open','arch','tower_door','windmill','windmill_sails','float_big','float_small','cap_left','cap_right','bridge','stone_ledge','crystal_ledge','scaffold','thorn_gate','cave','door','stone'}
# Repeating fills: cross-fade opposite edges so repeats have no visible joint.
SEAMLESS={'earth':'both','ground_top':'x','stone':'x','tower_wall':'both','cave_wall':'both'}
def seamless(img,axes,frac=0.14):
    a=np.asarray(img.convert('RGBA')).astype(float)
    if axes in ('x','both'):
        h,w=a.shape[:2];b=int(w*frac)
        t=(np.arange(b)/b)[None,:,None]
        out=a[:,:w-b].copy();out[:,:b]=a[:,:b]*t+a[:,w-b:]*(1-t);a=out
    if axes=='both':
        h,w=a.shape[:2];b=int(h*frac)
        t=(np.arange(b)/b)[:,None,None]
        out=a[:h-b].copy();out[:b]=a[:b]*t+a[h-b:]*(1-t);a=out
    return Image.fromarray(a.clip(0,255).astype(np.uint8),'RGBA')
if __name__=='__main__':
    kit={}
    for sheet,names in NAMES.items():
        rgba=key(np.asarray(Image.open(SRC/f'{sheet}-raw.png').convert('RGB')))
        raw=groups(rgba[...,3]>40,join=1 if sheet=='props' else 5)
        # Fold tiny fragments (sparkles, leaf tips) into the nearest real piece.
        big=[b for b in raw if (b[2]-b[0])*(b[3]-b[1])>=2500]
        for b in raw:
            if b in big: continue
            cx,cy=(b[0]+b[2])/2,(b[1]+b[3])/2
            j=min(range(len(big)),key=lambda i:max(big[i][0]-cx,0,cx-big[i][2])+max(big[i][1]-cy,0,cy-big[i][3]))
            g=big[j];big[j]=(min(g[0],b[0]),min(g[1],b[1]),max(g[2],b[2]),max(g[3],b[3]))
        boxes=order(big)
        if sheet=='gates' and len(boxes)==1:
            # The gates touch on the sheet: split at the emptiest columns.
            cols=(rgba[...,3]>40).sum(0);W=rgba.shape[1]
            cuts=[int(W*a)+int(np.argmin(cols[int(W*a):int(W*b)])) for a,b in ((0.3,0.37),(0.63,0.68))]
            x0,y0,x1,y1=boxes[0];edges=[x0]+cuts+[x1]
            boxes=[(edges[i],y0,edges[i+1],y1) for i in range(3)]
        if '--list' in sys.argv: print(sheet,len(boxes),boxes);continue
        if len(boxes)!=len(names): raise SystemExit(f'{sheet}: {len(boxes)} pieces, expected {len(names)}: {boxes}')
        for name,(x0,y0,x1,y1) in zip(names,boxes):
            piece=rgba[max(0,y0-4):y1+4,max(0,x0-4):x1+4].copy()
            ys,xs=np.where(piece[...,3]>12)
            piece=piece[ys.min():ys.max()+1,xs.min():xs.max()+1]
            # Repeating pieces lose their painted outline on the joining sides,
            # otherwise every repeat shows a thin dark seam.
            if name in TRIM:
                sides=TRIM[name]
                def lum(a): return (a[...,:3].astype(float).mean(axis=-1)*(a[...,3]/255.0)).mean()
                h,w=piece.shape[:2]
                band=piece[int(h*.45):int(h*.9)]
                ref=lum(band[:,w//3:2*w//3])
                l=0;r=0;t=0;b=0
                while l<w//4 and lum(band[:,l:l+1])<ref*0.8: l+=1
                while r<w//4 and lum(band[:,w-1-r:w-r])<ref*0.8: r+=1
                if sides=='all':
                    col=piece[:,int(w*.3):int(w*.7)]
                    rv=lum(col)
                    while t<h//4 and lum(col[t:t+1])<rv*0.8: t+=1
                    while b<h//4 and lum(col[h-1-b:h-b])<rv*0.8: b+=1
                piece=piece[t:h-b-1 if b or sides=='all' else h,l+1:w-r-1]
            img=Image.fromarray(piece)
            # Props are drawn at most ~110 world px (~370 px on a 4K screen);
            # tiling walls/strips keep their resolution.
            if name in SEAMLESS: img=seamless(img,SEAMLESS[name])
            limit=110 if name.startswith(('bird','bunny','butterfly','squirrel','duck','bat_','crab_','frog_','bee_')) else 320
            if name not in TRIM and name not in KEEP and max(img.size)>limit:
                f=limit/max(img.size)
                img=img.resize((round(img.width*f),round(img.height*f)),Image.LANCZOS)
            img.save(OUT/f'{name}.png')
            piece=np.asarray(img)
            kit[name]={'size':[int(piece.shape[1]),int(piece.shape[0])],'sheet':sheet}
    if '--list' not in sys.argv:
        (OUT/'kit.json').write_text(json.dumps(kit,indent=1)+'\n');print(len(kit),'pieces')
