"""Turn the Codex Green Meadows layer images into seamless runtime parallax strips.

For each layer: key magenta to transparency, crop to the painted band,
cross-fade a narrow band at the left/right edges so the strip repeats without
a seam, and save at production width. layers.json records each strip's size,
the GDD scroll factor and its draw order.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets/art/meadows-v2/source';OUT=ROOT/'assets/art/meadows-v2'
# name, scroll factor (GDD V2), opaque?
LAYERS=[('sky',0.05,True),('mountains',0.10,False),('hills',0.20,False),('town',0.35,False),('midground',0.60,False),('foreground',1.20,False)]
WIDTH=1024
def key(rgb):
    a=rgb.astype(float);r,g,b=a[...,0],a[...,1],a[...,2]
    m=np.clip(((np.minimum(r,b)-g)-60)/120,0,1)
    out=a.copy()
    for c in (0,2): out[...,c]=np.where(m>0.02,np.minimum(out[...,c],g+(out[...,c]-g)*(1-m)),out[...,c])
    return np.dstack([out,(1-m)*255]).clip(0,255)
def seamless(a,blend=10):
    """Cut where a column near the left end best matches one near the right
    end (e.g. between trees), then blend only a few pixels. A wide cross-fade
    left half-transparent ghost trees and clouds."""
    h,w=a.shape[:2]
    small=a[::4].astype(float)
    weight=np.concatenate([small[...,:3]*(small[...,3:4]/255.0),small[...,3:4]],axis=2)
    best=(1e18,0,w-1)
    for x1 in range(int(w*.02),int(w*.30),2):
        for x2 in range(int(w*.70),int(w*.98),2):
            # compare a few columns around each cut for shape continuity
            d=0.0
            for k in (-4,0,4):
                d+=np.abs(weight[:,x1+k]-weight[:,x2+k]).sum()
            if d<best[0]: best=(d,x1,x2)
    _,x1,x2=best
    out=a[:,x1:x2].copy()
    t=(np.arange(blend)/blend)[None,:,None]
    out[:,:blend]=a[:,x1:x1+blend]*t+a[:,x2:x2+blend]*(1-t)
    return out
if __name__=='__main__':
    meta={}
    for i,(name,factor,opaque) in enumerate(LAYERS):
        rgb=np.asarray(Image.open(SRC/f'{name}-raw.png').convert('RGB'))
        a=np.dstack([rgb.astype(float),np.full(rgb.shape[:2],255.0)]) if opaque else key(rgb)
        rows=np.where(a[...,3].max(axis=1)>20)[0]
        a=a[rows.min():rows.max()+1]
        a=seamless(a)
        img=Image.fromarray(a.clip(0,255).astype(np.uint8),'RGBA')
        img=img.resize((WIDTH,round(img.height*WIDTH/img.width)),Image.LANCZOS)
        img.save(OUT/f'{name}.png')
        meta[name]={'size':list(img.size),'scroll':factor,'order':i,'opaque':opaque}
    (OUT/'layers.json').write_text(json.dumps(meta,indent=1)+'\n')
    print(json.dumps(meta))
