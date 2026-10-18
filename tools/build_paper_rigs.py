"""Paper puppet rigs from the EXPLODED-VIEW sheets (source/<who>-exploded-raw.png):
left = the assembled puppet, right = the same parts pulled apart at the same
size and angle. Each part is placed by sliding it over the assembled figure
(translation only, so proportions are exact); its joint is its brass pin.
Near/far limbs: the one matching the visible pixels better is in front.
Writes assets/art/paper-v1/<explorer|foxy>.json, part PNGs and a check image."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from build_paper_kit import load
from build_ui_kit import groups
DIR=Path(__file__).resolve().parent.parent/'assets/art/paper-v1'
CHECK='/private/tmp/claude-154376277/-Users-sfrenkel-Petopia/00377cb5-9802-4224-8c59-a619dec42db8/scratchpad/'
SCALE=0.5
def place(full,part):
    F=full[::2,::2].astype(float);P=part[::2,::2].astype(float);pm=P[...,3]>200
    best=(1e18,0,0,0)
    for y in range(0,F.shape[0]-P.shape[0]+1):
        for x in range(0,F.shape[1]-P.shape[1]+1):
            Wn=F[y:y+P.shape[0],x:x+P.shape[1]];m=pm&(Wn[...,3]>200)
            cover=m.sum()/max(pm.sum(),1)
            if cover<0.3: continue
            d=np.abs(Wn[...,:3][m]-P[...,:3][m]).mean()
            s=d+50*(1-cover)
            if s<best[0]: best=(s,x*2,y*2,d)
    return best
def pin(part):
    r,g,b=[part[...,i].astype(int) for i in range(3)]
    brass=(r>150)&(g>110)&(b<90)&(r-b>90)&(part[...,3]>200)&(np.abs(r-g)<70)
    ys,xs=np.where(brass)
    if len(ys)==0: return None
    sel=ys<ys.min()+part.shape[0]*0.25
    return float(xs[sel].mean()),float(ys[sel].mean())
def build(sheet,who,roles):
    a=load(sheet)
    boxes=[x for x in groups(a[...,3]>0,join=2) if (x[2]-x[0])*(x[3]-x[1])>900]
    fb=min(boxes,key=lambda b:b[0]);full=a[fb[1]:fb[3],fb[0]:fb[2]]
    found=[]
    for b in boxes:
        if b==fb: continue
        q=a[b[1]:b[3],b[0]:b[2]];s,x,y,d=place(full,q)
        found.append({'box':b,'img':q,'x':x,'y':y,'err':d})
    named=roles(found)
    fh,fw=full.shape[:2];parts=[]
    rebuilt=Image.new('RGBA',(fw,fh),(0,0,0,0))
    for name,p,pv in named:
        img=Image.fromarray(p['img']);w,h=img.size
        img.resize((max(1,round(w*SCALE)),max(1,round(h*SCALE))),Image.LANCZOS).save(DIR/f'{name}.png')
        parts.append({'name':name,'scale':1.0,'pivot':[pv[0]*SCALE,pv[1]*SCALE],'at':[(p['x']+pv[0]-fw/2)*SCALE,(p['y']+pv[1]-fh)*SCALE]})
        rebuilt.alpha_composite(img,(p['x'],p['y']))
        print(who,name,(p['x'],p['y']),'err',round(p['err'],1),'pivot',[round(v) for v in pv])
    (DIR/f'{who}.json').write_text(json.dumps({'height':fh*SCALE,'parts':parts},indent=1))
    c=Image.new('RGBA',(fw*2+30,fh),(220,230,240,255));c.alpha_composite(Image.fromarray(full),(0,0));c.alpha_composite(rebuilt,(fw+30,0));c.save(CHECK+f'rig-{who}.png')
def near(pair): return sorted(pair,key=lambda p:p['err'])
def fox_roles(found):
    head=min(found,key=lambda p:p['box'][1])
    tail=min(found,key=lambda p:p['box'][0])
    rest=[p for p in found if p is not head and p is not tail]
    body=max(rest,key=lambda p:p['box'][2]-p['box'][0])
    legs=sorted([p for p in rest if p is not body],key=lambda p:p['x'])
    hn,hf=near(legs[:2]);fn,ff=near(legs[2:])
    def pv(p,k):
        q=p['img'];h,w=q.shape[:2]
        if k=='leg': return pin(q) or (w*0.5,h*0.12)
        return {'tail':(w*0.92,h*0.45),'head':(w*0.35,h*0.8),'body':(w*0.5,h*0.5)}[k]
    return [('fx_tail',tail,pv(tail,'tail')),('fx_leg_hind_far',hf,pv(hf,'leg')),('fx_leg_front_far',ff,pv(ff,'leg')),('fx_body',body,pv(body,'body')),
            ('fx_leg_hind_near',hn,pv(hn,'leg')),('fx_leg_front_near',fn,pv(fn,'leg')),('fx_head',head,pv(head,'head'))]
def explorer_roles(found):
    head=min(found,key=lambda p:p['box'][1])
    rest=[p for p in found if p is not head]
    upper=[p for p in rest if p['box'][1]<500];legs=[p for p in rest if p['box'][1]>=500]
    torso=max(upper,key=lambda p:p['box'][2]-p['box'][0])
    arms=[p for p in upper if p is not torso]
    af,ab=near(arms);lf,lb=near(legs)
    def pv(p,k):
        q=p['img'];h,w=q.shape[:2]
        if k=='limb': return pin(q) or (w*0.5,h*0.08)
        return (w*0.5,h*0.9)
    return [('ex_arm_back',ab,pv(ab,'limb')),('ex_leg_back',lb,pv(lb,'limb')),('ex_leg_front',lf,pv(lf,'limb')),('ex_torso',torso,pv(torso,'x')),('ex_head',head,pv(head,'x')),('ex_arm_front',af,pv(af,'limb'))]
if __name__=='__main__':
    build('fox-exploded','foxy',fox_roles)
    build('explorer-exploded','explorer',explorer_roles)
