"""Rebuild the concept icon sheets so each icon is isolated and padded.

Codex sheets place icons close together; cropping a cell picked up slivers of
neighbouring icons, and linear filtering bled across cell edges. For each
cell this keeps only the connected shapes that belong to the centred icon,
then centres it in a 128 px cell with an 8 px transparent gutter.
Sources: the keyed full-resolution sheets in assets/ui/concept-v1/source/.
"""
import json, sys
from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
DIR=ROOT/'assets/ui/concept-v1'
SHEETS={'hud-icons':['heart','heart_empty','left','right','up','hand','sense','music','speaker','voice','motion','hint','timer','controller','basket','check'],
        'glyphs':['gear','menu','close','back','home','world','star','paw_blue','plus','minus','pencil','shop_stall','trophy','mute','lock','help']}
CELL=128; PAD=8

def key(rgb):
    a=rgb.astype(float);r,g,b=a[...,0],a[...,1],a[...,2]
    m=np.clip(((np.minimum(r,b)-g)-60)/120,0,1)
    out=a.copy()
    for c in (0,2): out[...,c]=np.where(m>0.02,np.minimum(out[...,c],g+(out[...,c]-g)*(1-m)),out[...,c])
    return np.dstack([out,(1-m)*255]).clip(0,255).astype(np.uint8)

def components(mask):
    h,w=mask.shape;label=np.zeros((h,w),int);n=0;sizes={};boxes={}
    for y in range(h):
        for x in range(w):
            if mask[y,x] and not label[y,x]:
                n+=1;q=deque([(y,x)]);label[y,x]=n;cnt=0;y0=y1=y;x0=x1=x
                while q:
                    cy,cx=q.popleft();cnt+=1;y0=min(y0,cy);y1=max(y1,cy);x0=min(x0,cx);x1=max(x1,cx)
                    for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
                        ny,nx=cy+dy,cx+dx
                        if 0<=ny<h and 0<=nx<w and mask[ny,nx] and not label[ny,nx]:
                            label[ny,nx]=n;q.append((ny,nx))
                sizes[n]=cnt;boxes[n]=(x0,y0,x1,y1)
    return label,sizes,boxes

def build(name,names):
    raw=np.asarray(Image.open(DIR/'source'/f'{name}-raw.png').convert('RGB'))
    rgba=key(raw);H,W=rgba.shape[:2];cw,ch=W/4,H/4
    sheet=Image.new('RGBA',(CELL*4,CELL*4),(0,0,0,0));bounds={}
    for i,n in enumerate(names):
        x0,y0=int((i%4)*cw),int((i//4)*ch);x1,y1=int(x0+cw),int(y0+ch)
        cell=rgba[y0:y1,x0:x1].copy()
        small=np.asarray(Image.fromarray(cell).resize((96,96),Image.NEAREST))[...,3]>60
        label,sizes,boxes=components(small)
        if not sizes: continue
        main=max(sizes,key=sizes.get);mx0,my0,mx1,my1=boxes[main]
        # Grow the icon from its largest shape: anything close to what is already
        # kept joins (bars of a menu, sparkles, sound waves); slivers of
        # neighbouring icons touch the cell edge and are dropped.
        kept={main};changed=True
        while changed:
            changed=False
            for k in sizes:
                if k in kept: continue
                bx0,by0,bx1,by1=boxes[k]
                if bx0==0 or by0==0 or bx1==95 or by1==95: continue
                if bx1>=mx0-12 and bx0<=mx1+12 and by1>=my0-12 and by0<=my1+12:
                    kept.add(k);changed=True
                    mx0,my0,mx1,my1=min(mx0,bx0),min(my0,by0),max(mx1,bx1),max(my1,by1)
        keep=np.isin(label,list(kept))
        grown=np.asarray(Image.fromarray((keep*255).astype(np.uint8)).resize((x1-x0,y1-y0),Image.NEAREST).filter(__import__('PIL.ImageFilter',fromlist=['MaxFilter']).MaxFilter(9)))>0
        cell[...,3]=np.where(grown,cell[...,3],0)
        ys,xs=np.where(cell[...,3]>20)
        crop=Image.fromarray(cell[ys.min():ys.max()+1,xs.min():xs.max()+1])
        scale=(CELL-2*PAD)/max(crop.size)
        crop=crop.resize((max(1,round(crop.width*scale)),max(1,round(crop.height*scale))),Image.LANCZOS)
        ox=(i%4)*CELL+(CELL-crop.width)//2;oy=(i//4)*CELL+(CELL-crop.height)//2
        sheet.alpha_composite(crop,(ox,oy))
        bounds[n]=[ox,oy,crop.width,crop.height]
    sheet.save(DIR/f'{name}.png')
    return bounds

if __name__=='__main__':
    allb={}
    for name,names in SHEETS.items(): allb.update(build(name,names))
    (DIR/'icon-bounds.json').write_text(json.dumps(allb,indent=1)+'\n')
    print(len(allb),'icons')
