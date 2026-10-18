"""A57 environment layer kits: each place is built like its concept, as
separate parallax layers in that concept's style (not a copy of the picture):
  far     full-height backdrop, seamless left-right (no ground)
  silo    far silhouettes, transparent above (magenta), seamless
  mid     middle silhouettes / big shapes, transparent above, seamless
  light   light shafts / glow on black (drawn additively)
  front   two foreground framing clumps (left, right), dark and soft
Each layer is its own 1536x1024 image: sharp at any screen.
  python3 tools/env_layers.py draw <env>    |    cut <env>"""
import subprocess, sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'assets/art/meadow-p31'
SRC=OUT/'source/layers';SRC.mkdir(parents=True,exist_ok=True)
CON=ROOT/'assets/concepts/current/paper-v1'
LOG=Path('/private/tmp/claude-154376277/-Users-sfrenkel-Petopia/00377cb5-9802-4224-8c59-a619dec42db8/scratchpad')
ENV={
 'cave':('P33-cave',{
  'far':'the deepest cavern: distant glowing blue-violet cave walls, far arches and pale haze, the light area where shafts fall, NO ground, NO platforms; fills the whole image',
  'silo':'a row of distant violet stalagmite silhouettes and rock arches with a little pool and a tiny waterfall, standing on the bottom edge; everything above them FLAT magenta',
  'mid':'nearer big dark indigo rock pillars and spires with a few glowing pale-cyan crystals at their feet, standing on the bottom edge, with gaps between them; everything else FLAT magenta',
  'ceiling':'a hanging CEILING band along the TOP edge: dark indigo stalactites with hanging vines and glowing blue bulbs, about 320 px tall; everything below FLAT magenta',
  'light':'soft diagonal light shafts falling from the top, pale blue, on a PURE BLACK background (for additive glow), nothing else',
  'front':'two separate foreground framing clumps on magenta: LEFT a dark blurred cluster of big blue crystals and leaves (about 500x600, standing on the bottom edge), RIGHT another dark blurred cluster (about 500x600)'}),
 'tower':('P34-tower',{
  'far':'the far tower hall: tall sandstone wall with arched windows showing sky and a distant castle, red banners, a staircase, warm light; NO floor; fills the whole image',
  'silo':'a row of sandstone arches and pillars with ivy, standing on the bottom edge; FLAT magenta above',
  'mid':'nearer big sandstone pillars with ivy and burning wall torches, wide gaps between; FLAT magenta elsewhere',
  'ceiling':'a top band of wooden beams and hanging ivy along the TOP edge, about 260 px tall; FLAT magenta below',
  'light':'warm sunbeams falling diagonally from the windows, golden, on a PURE BLACK background',
  'front':'two separate foreground framing clumps on magenta: LEFT dark blurred ivy leaves, RIGHT dark blurred ivy and a stone corner'}),
 'cellar':('P36-cellar',{
  'far':'the far cellar: warm stone wall with huge wooden windmill gears and beams in soft light; NO floor; fills the whole image',
  'silo':'a row of wooden support posts and big beams standing on the bottom edge; FLAT magenta above',
  'mid':'nearer flour sacks, barrels and crates in clusters along the bottom edge with gaps; FLAT magenta elsewhere',
  'ceiling':'a top band of thick wooden beams with a hanging lantern, about 260 px tall; FLAT magenta below',
  'light':'a warm lantern glow and dusty light shafts on a PURE BLACK background',
  'front':'two separate foreground framing clumps on magenta: LEFT dark blurred sacks and a crate corner, RIGHT dark blurred barrels'}),
}
H='''Use your built-in image generation tool to create ONE image, then save it (copy the generated PNG) to exactly this path:
{path}
Do not modify any other file. Do not write code. When finished, reply with the saved path only.
One PARALLAX LAYER for a 2D side-scrolling game, canvas 1536x1024, in EXACTLY the torn-paper collage style, colours and lighting mood of the attached concept (layered torn paper, soft fibrous edges, watercolour paper tones). Do NOT copy the concept picture; draw only this layer. It must TILE SEAMLESSLY left-right (left and right edges match). No characters, no creatures, no text, no HUD.
Layer: {what}'''
def draw(env):
    con,layers=ENV[env]
    for n,what in layers.items():
        p=SRC/f'{env}-{n}-prompt.txt';p.write_text(H.format(path=SRC/f'{env}-{n}.png',what=what))
        subprocess.Popen(['codex','exec','-s','danger-full-access','-i',str(CON/f'{con}.png'),'-'],stdin=open(p),stdout=open(LOG/f'codex-L-{env}-{n}.log','w'),stderr=subprocess.STDOUT,cwd=ROOT)
    print('drawing',env)
def keyed(path):
    a=np.asarray(Image.open(path).convert('RGB')).astype(int);r,g,b=a[...,0],a[...,1],a[...,2]
    bg=(r>150)&(b>150)&(g<r-80)&(g<b-80);edge=(r>110)&(b>110)&(g<r-40)&(g<b-40)&~bg
    rgb=a.copy();rgb[edge]=(rgb[edge]*0.3).astype(int)+[30,20,40]
    return np.dstack([rgb,np.where(bg,0,np.where(edge,110,255))]).astype(np.uint8)
def cut(env):
    for n in ENV[env][1]:
        src=SRC/f'{env}-{n}.png'
        if n=='far': Image.open(src).convert('RGB').save(OUT/f'L_{env}_{n}.png')
        elif n=='light':
            a=np.asarray(Image.open(src).convert('RGB')).astype(int);al=np.clip(a.max(2)*1.2,0,255)
            Image.fromarray(np.dstack([a,al]).astype(np.uint8)).save(OUT/f'L_{env}_{n}.png')
        elif n=='front':
            from build_ui_kit import groups
            a=keyed(src);bx=sorted([b for b in groups(a[...,3]>0,join=6) if (b[2]-b[0])*(b[3]-b[1])>20000],key=lambda b:b[0])[:2]
            for side,b in zip(['left','right'],bx):
                q=a[b[1]:b[3],b[0]:b[2]];Image.fromarray(q).save(OUT/f'L_{env}_front_{side}.png')
        else:
            a=keyed(src);ys=np.where(a[...,3].max(1)>0)[0]
            Image.fromarray(a[ys.min():ys.max()+1]).save(OUT/f'L_{env}_{n}.png')
    print('cut',env)
if __name__=='__main__':
    sys.path.insert(0,str(Path(__file__).parent))
    {'draw':draw,'cut':cut}[sys.argv[1]](sys.argv[2])
