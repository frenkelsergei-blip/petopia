"""A55: paper-cut redraws (Codex, same composition) of the remaining full
pictures -> assets/ui/paper-pictures/<name>.png at the original's size, so
positions measured on the originals (map pins, ground lines) still hold.
ArtTexture swaps the original path for these when ArtStyle.paper is on."""
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/ui/paper-pictures'
PICS={'care-map':'assets/ui/care-v1/meadows-map.png','world-map':'assets/ui/map-v1/meadows-map.png',
 'picnic-finish':'assets/ui/care-v1/picnic-finish.png','garden':'assets/art/polish-v2/home-garden-scaled.png',
 'beach':'assets/ui/concept-v1/world-sunny-beach.png','forest':'assets/ui/concept-v1/world-mystic-forest.png',
 'phone':'assets/ui/concept-v1/rotate-phone.png'}
for name,orig in PICS.items():
    size=Image.open(ROOT/orig).size
    im=Image.open(OUT/'source'/f'{name}-raw.png').convert('RGB')
    if name=='phone':
        a=np.asarray(im).astype(int);r,g,b=a[...,0],a[...,1],a[...,2]
        al=np.where((r>150)&(b>150)&(g<r-80)&(g<b-80),0,255)
        q=np.dstack([a,al]).astype(np.uint8);ys,xs=np.where(al>0)
        im=Image.fromarray(q[ys.min():ys.max()+1,xs.min():xs.max()+1])
    else:
        # cover-crop to the original aspect
        tw,th=size;k=max(tw/im.width,th/im.height)
        im=im.resize((round(im.width*k),round(im.height*k)),Image.LANCZOS)
        x=(im.width-tw)//2;y=(im.height-th)//2;im=im.crop((x,y,x+tw,y+th))
    im.resize(size,Image.LANCZOS).save(OUT/f'{name}.png')
    print(name,size)
