"""Slice the Codex UI-kit sheets (assets/ui/kit-v1/source/*-raw.png) into one
PNG per component with transparent background, plus kit.json holding each
piece's size and its 9-slice margins (the stretchable middle stays uniform).
Usage: python3 tools/build_ui_kit.py [--list]
"""
import json, sys
from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets/ui/kit-v1/source'; OUT=ROOT/'assets/ui/kit-v1'
# Names in reading order (rows top->bottom, left->right) per sheet, plus the
# 9-slice margin as a fraction of the piece's smaller side (0 = never stretched).
NAMES={
 'panels':[('panel',.16),('ribbon_blue',0),('card',.10),('ribbon_cream',0),('vine_corner',0),('leaf_small',0),('divider',0)],
 'buttons':[('pill_gold',.5),('pill_gold_pressed',.5),('pill_cream',.5),('pill_cream_pressed',.5),('pill_disabled',.5),('pill_selected',.5),('round',0),('round_pressed',0),('round_blue',0),('switch_on',0),('switch_off',0)],
 'content':[('row',.5),('row_gold',.5),('tile',.18),('check_badge',0),('field',.22),('tile_gold',.18),('tag',.5),('wallet',.5),('meter_track',.5),('meter_fill',.5)],
 'game':[('medal_done',0),('medal_ring',0),('medal_open',0),('medal_locked',0),('flag',0),('path_dot',0),('ribbon_region',0),('action',0),('action_pressed',0),('stick_base',0),('stick_knob',0),('hud_plank',.5)],
}
def key(rgb):
    a=rgb.astype(float);r,g,b=a[...,0],a[...,1],a[...,2]
    m=np.clip(((np.minimum(r,b)-g)-60)/120,0,1)
    out=a.copy()
    for c in (0,2): out[...,c]=np.where(m>0.02,np.minimum(out[...,c],g+(out[...,c]-g)*(1-m)),out[...,c])
    return np.dstack([out,(1-m)*255]).clip(0,255).astype(np.uint8)
def groups(alpha,step=4,join=5):
    """Connected pieces on a downscaled mask, joined across small gaps."""
    small=alpha[::step,::step]
    h,w=small.shape;seen=np.zeros_like(small,bool);boxes=[]
    for y in range(h):
        for x in range(w):
            if small[y,x] and not seen[y,x]:
                q=deque([(y,x)]);seen[y,x]=True;x0=x1=x;y0=y1=y;n=0
                while q:
                    cy,cx=q.popleft();n+=1;x0=min(x0,cx);x1=max(x1,cx);y0=min(y0,cy);y1=max(y1,cy)
                    for dy in range(-join,join+1):
                        for dx in range(-join,join+1):
                            ny,nx=cy+dy,cx+dx
                            if 0<=ny<h and 0<=nx<w and small[ny,nx] and not seen[ny,nx]:
                                seen[ny,nx]=True;q.append((ny,nx))
                if n>12: boxes.append((x0*step,y0*step,(x1+1)*step,(y1+1)*step))
    return boxes
def order(boxes):
    boxes=sorted(boxes,key=lambda b:b[1]);rows=[]
    for b in boxes:
        cy=(b[1]+b[3])/2
        for row in rows:
            if row[0]-0 <= cy <= row[1]: row[2].append(b);break
        else: rows.append([b[1],b[3],[b]])
    return [b for row in rows for b in sorted(row[2],key=lambda b:b[0])]
if __name__=='__main__':
    kit={}
    for sheet,names in NAMES.items():
        rgba=key(np.asarray(Image.open(SRC/f'{sheet}-raw.png').convert('RGB')))
        boxes=order(groups(rgba[...,3]>40))
        if '--list' in sys.argv: print(sheet,len(boxes),boxes);continue
        if len(boxes)!=len(names): raise SystemExit(f'{sheet}: found {len(boxes)} pieces, expected {len(names)}: {boxes}')
        for (name,margin),(x0,y0,x1,y1) in zip(names,boxes):
            piece=rgba[max(0,y0-4):y1+4,max(0,x0-4):x1+4].copy()
            ys,xs=np.where(piece[...,3]>12)
            piece=piece[ys.min():ys.max()+1,xs.min():xs.max()+1]
            img=Image.fromarray(piece)
            # Production size: halve big source pieces (still >=2x phone size).
            if max(img.size)>300: img=img.resize((round(img.width/2),round(img.height/2)),Image.LANCZOS)
            img.save(OUT/f'{name}.png')
            m=round(min(img.size)*margin) if margin else 0
            kit[name]={'size':list(img.size),'margin':m,'sheet':sheet}
    if '--list' not in sys.argv:
        (OUT/'kit.json').write_text(json.dumps(kit,indent=1)+'\n');print(len(kit),'pieces')
