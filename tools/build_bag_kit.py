"""Cut the bag UI pieces straight out of the approved concept
(assets/concepts/current/screens/V10-bag-v1.png) so the game matches it:
corners, studs and edges come from the concept; insides are cleared to the
concept's own cream so pieces stretch as nine-slices. Scale SCALE matches the
concept to the game's 1280-wide layout."""
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
SRC=np.asarray(Image.open(ROOT/'assets/concepts/current/screens/V10-bag-v1.png').convert('RGBA')).copy()
OUT=ROOT/'assets/ui/bag-v1'
SCALE=0.62

def crop(x0,y0,x1,y1): return SRC[y0:y1,x0:x1].copy()
def fill_inside(a,inset,sample):
    c=np.median(a[sample[1]:sample[3],sample[0]:sample[2]].reshape(-1,4),axis=0)
    a[inset:-inset,inset:-inset]=c
    return a
def stretch(a,col,left,right):
    """Remove the middle (text, icons): keep left/right caps, join with one clean column."""
    mid=np.repeat(a[:,col:col+1],40,axis=1)
    return np.concatenate([a[:,:left],mid,a[:,-right:]],axis=1)
def save(a,name,alpha_bg=None):
    img=Image.fromarray(a.astype(np.uint8))
    img=img.resize((max(1,round(img.width*SCALE)),max(1,round(img.height*SCALE))),Image.LANCZOS)
    img.save(OUT/f'{name}.png');print(name,img.size)
def key_out(a,bg_test):
    a[...,3]=np.where(bg_test(a),0,a[...,3]);return a

def mirror_frame(x0,y0,m,fill_at,size=None,edge_at=None,unify=False):
    """A square nine-slice frame from one clean top-left corner (m px) of the
    concept, mirrored to the other corners; edges continue the corner's own
    edge pixels; the inside is the concept's fill colour."""
    c=crop(x0,y0,x0+m,y0+m)
    fillc=SRC[fill_at[1],fill_at[0]].astype(float)
    n=2*m+40
    f=np.zeros((n,n,4));f[:]=fillc
    f[:m,:m]=c;f[:m,-m:]=c[:,::-1];f[-m:,:m]=c[::-1];f[-m:,-m:]=c[::-1,::-1]
    top=c[:,-1:];lef=c[-1:,:]
    if edge_at:  # real edge pixels away from the corner plate
        ex,ey=edge_at
        top=SRC[y0:y0+m,ex:ex+1].astype(float);lef=SRC[ey:ey+1,x0:x0+m].astype(float)
    f[:m,m:-m]=np.repeat(top,n-2*m,axis=1);f[-m:,m:-m]=np.repeat(top[::-1],n-2*m,axis=1)
    f[m:-m,:m]=np.repeat(lef,n-2*m,axis=0);f[m:-m,-m:]=np.repeat(lef[:,::-1],n-2*m,axis=0)
    if unify:
        cream=(f[...,0]>235)&(f[...,1]>195)&(f[...,2]>140)
        f[cream]=fillc
    return f
def chamfer(a,k):
    h,w=a.shape[:2];yy,xx=np.mgrid[0:h,0:w]
    for cx,cy in ((0,0),(w-1,0),(0,h-1),(w-1,h-1)):
        a[...,3]=np.where(np.abs(xx-cx)+np.abs(yy-cy)<k,0,a[...,3])
    return a
# Slots: corners from the clean bottom-left empty slot and the selected slot.
save(chamfer(mirror_frame(284,649,34,(330,700),76),5),'slot')
save(mirror_frame(278,321,40,(300,345),88),'slot_on')
# Tabs: caps keep the studs; one clean column joins them.
save(chamfer(stretch(crop(571,204,833,297),228,34,34),6),'tab')
save(stretch(crop(282,201,562,299),252,36,36),'tab_on')
# Title plaque: cap and backpack on the left, cap on the right.
save(chamfer(stretch(crop(617,75,1056,193),383,175,32),8),'plaque')
# Details card: top-left corner mirrored (the button sits on its bottom).
save(mirror_frame(1076,317,26,(1150,345),60),'card')
# Gold action button.
save(chamfer(stretch(crop(1094,729,1421,811),268,40,40),6),"button_gold")
# Main frame from its top-left corner.
save(mirror_frame(226,126,56,(450,178),120,(450,520),True),'frame')
# Close button: the round gold X, cut as a circle.
cb=crop(1388,103,1492,207);cy,cx=52,52
yy,xx=np.mgrid[0:104,0:104];cb[...,3]=np.where((yy-cy)**2+(xx-cx)**2<=50**2,255,0)
save(cb,'close')
# Count badge: the round "2" badge with its digit cleared.
bd=crop(371,424,421,474);yy,xx=np.mgrid[0:50,0:50];r=np.sqrt((yy-25)**2+(xx-25)**2)
inner=np.median(bd[22:28,8:12].reshape(-1,4),axis=0)
bd[r<15]=inner;bd[...,3]=np.where(r<=24,255,0)
save(bd,'badge')
