"""Read-only alpha/component analysis. Does not edit or rasterize source artwork."""
from collections import deque
from pathlib import Path
import json, statistics
from PIL import Image
BASE=Path(__file__).resolve().parents[1]
def components(im, bounds):
 x0,y0,x1,y1=bounds; width=x1-x0; height=y1-y0
 rgba=im.crop(bounds).convert('RGBA'); pixels=list(rgba.getdata())
 mask=bytearray(1 if p[3]>190 else 0 for p in pixels); found=[]
 for index in range(len(mask)):
  if not mask[index]:continue
  mask[index]=0;q=deque([index]);xs=[];ys=[]
  while q:
   p=q.popleft();x=p%width;y=p//width;xs.append(x);ys.append(y)
   for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
    nx=x+dx;ny=y+dy
    if 0<=nx<width and 0<=ny<height:
     n=ny*width+nx
     if mask[n]:mask[n]=0;q.append(n)
  if len(xs)>500:found.append((len(xs),(min(xs)+x0,min(ys)+y0,max(xs)+x0+1,max(ys)+y0+1)))
 return sorted(found,reverse=True)
def row(im,row_index,columns,identity,source):
 y0=round(row_index*im.height/2); y1=round((row_index+1)*im.height/2)
 blobs=components(im,(0,y0,im.width,y1))[:columns]
 assert len(blobs)==columns,(identity,len(blobs))
 bboxes=sorted([b for area,b in blobs],key=lambda b:(b[0]+b[2])/2)
 baseline=max(b[3] for b in bboxes)
 body_height=baseline-statistics.median(b[1] for b in bboxes)
 frames=[]
 for b in bboxes:
  left=max(0,b[0]-5);top=max(y0,b[1]-5);right=min(im.width,b[2]+5);bottom=min(y1,max(b[3]+5,baseline+1))
  head_x=[]
  for yy in range(b[1],int(b[1]+(b[3]-b[1])*.40)):
   for xx in range(b[0],b[2]):
    r,g,blue,a=im.getpixel((xx,yy))
    if a>190 and r<125 and g<85 and blue<115:head_x.append(xx)
  if identity=='explorer':anchor=statistics.mean(head_x) if head_x else (b[0]+b[2])/2
  else:
   # Fixed center of the head, relative to the neck/body anchor, independent
   # of tail compression in gather/extended phases.
   eye=[]
   for yy in range(int(b[1]+(b[3]-b[1])*.2),int(b[1]+(b[3]-b[1])*.65)):
    for xx in range(int(b[0]+(b[2]-b[0])*.65),b[2]):
     r,g,blue,a=im.getpixel((xx,yy))
     if a>190 and max(r,g,blue)<75:eye.append(xx)
   anchor=(statistics.mean(eye) if eye else b[0]+(b[2]-b[0])*.8)-body_height*.25
  frames.append({'region':[left,top,right-left,bottom-top],'pivot':[round(anchor-left,2),baseline-top],'content_bounds':list(b)})
 return {'atlas':source,'body_height':body_height,'frames':frames,'stride_world':56 if identity=='explorer' else (44 if identity=='foxy_baby' else 54)}
child_path='assets/art/meadow-system-v4/explorer-run-v3.png';fox_path='assets/art/meadow-system-v4/foxy-run.png'
child=Image.open(BASE/child_path).convert('RGBA');fox=Image.open(BASE/fox_path).convert('RGBA')
first=row(child,0,4,'explorer',child_path);second=row(child,1,4,'explorer',child_path)
# Keep one source-space baseline scale for both chronological half-cycles.
first['frames']+=second['frames'];first['body_height']=(first['body_height']+second['body_height'])/2
output={'explorer':first,'foxy_baby':row(fox,0,6,'foxy_baby',fox_path),'foxy_child':row(fox,1,6,'foxy_child',fox_path)}
(BASE/'assets/art/meadow-system-v4/run-metadata.json').write_text(json.dumps(output,indent=2)+'\n')
print({key:{'frames':len(value['frames']),'body_height':value['body_height']} for key,value in output.items()})
