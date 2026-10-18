"""Derive rivet-free frame art plus one rivet sprite from the approved menu/wallet art.

Rivets painted into 9-slice corners stretched and collided with labels. The
runtime now draws rivets separately at one fixed size (PetUI.draw_rivets).
Sources stay the art of record; outputs go to assets/ui/frames-v2/.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/ui/frames-v2'

def rivet_mask(a):
    r,g,b,al=[a[...,i].astype(int) for i in range(4)]
    orange=(r>150)&(g>60)&(g<190)&(b<110)&(r-b>90)
    dark=(r+g+b<200)&(al>200)
    return orange,dark

def refine(orange,x,y,window=40):
    sub=orange[y-window:y+window,x-window:x+window]
    ys,xs=np.where(sub)
    if len(xs)<15: return x,y
    return int(round(xs.mean()))+x-window,int(round(ys.mean()))+y-window

def clean(src,dst,face_region,first,report,radius=34):
    """first: measured top-left rivet centre; the others mirror across the face."""
    im=Image.open(src).convert('RGBA');a=np.asarray(im).copy()
    x0,y0,w,h=face_region
    orange,dark=rivet_mask(a)
    fx,fy=first
    guesses=[(fx,fy),(x0+w-(fx-x0),fy),(fx,y0+h-(fy-y0)),(x0+w-(fx-x0),y0+h-(fy-y0))]
    centres=[refine(orange,gx,gy) for gx,gy in guesses]
    H,W=orange.shape
    yy,xx=np.ogrid[:H,:W]
    for cx,cy in centres:
        m=(xx-cx)**2+(yy-cy)**2<=radius**2
        # Replace with the face a little further inside, same rows (grain continues).
        shift=radius*3 if cx<W//2 else -radius*3
        a[m]=np.roll(a,-shift,axis=1)[m]
    Image.fromarray(a).save(dst)
    report[Path(dst).name]={'source':str(Path(src).relative_to(ROOT)),'rivets':centres,'radius':radius}
    return centres,radius

def rivet_sprite(src,centre,dst,radius=34):
    a=np.asarray(Image.open(src).convert('RGBA')).copy()
    cx,cy=centre
    # Face colour sampled on a ring just outside the rivet.
    yy,xx=np.ogrid[:a.shape[0],:a.shape[1]]
    d=(xx-cx)**2+(yy-cy)**2
    ring=(d>(radius+6)**2)&(d<(radius+16)**2)
    face=np.median(a[ring][:,:3],axis=0)
    r=radius
    crop=a[cy-r:cy+r,cx-r:cx+r].copy()
    dist=np.abs(crop[...,:3].astype(int)-face).sum(axis=2)
    y2,x2=np.ogrid[:2*r,:2*r]
    keep=((x2-r)**2+(y2-r)**2<=r*r)&(dist>60)
    crop[...,3]=np.where(keep,255,0)
    ys,xs=np.where(keep)
    crop=crop[ys.min():ys.max()+1,xs.min():xs.max()+1]
    Image.fromarray(crop).save(dst)

def gold_face(src,dst):
    """Primary buttons: the same clean frame with the V04 gold face."""
    a=np.asarray(Image.open(src).convert('RGBA')).astype(float)
    r,g,b=a[...,0],a[...,1],a[...,2]
    face=(r>205)&(g>185)&(b>140)&(a[...,3]>200)
    lum=(0.3*r+0.59*g+0.11*b)/235.0
    gold=np.stack([np.full_like(r,255),np.full_like(r,205),np.full_like(r,72)],axis=-1)*lum[...,None]
    out=a.copy();out[face,:3]=np.clip(gold[face],0,255)
    Image.fromarray(out.astype(np.uint8)).save(dst)

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    report={}
    spec=json.loads((ROOT/'assets/ui/menu-v2/manifest.json').read_text())['wallet']
    centres,radius=clean(ROOT/'assets/ui/menu-v2/wallet.png',OUT/'frame-cream.png',tuple(spec['region']),(200,222),report,40)
    gold_face(OUT/'frame-cream.png',OUT/'frame-gold.png')
    rivet_sprite(ROOT/'assets/ui/menu-v2/wallet.png',centres[0],OUT/'rivet.png')
    report['frame-gold.png']={'source':'frame-cream.png','face':'cream mapped to gold, luminance kept'}
    report['rivet.png']={'source':'assets/ui/menu-v2/wallet.png','centre':centres[0]}
    report['region']=spec['region'];report['source_corner']=spec['source_corner']
    (OUT/'manifest.json').write_text(json.dumps(report,indent=1)+'\n')
    print(json.dumps(report))
