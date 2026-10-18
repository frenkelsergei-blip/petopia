"""Cut the Codex Foxy animation candidates (assets/art/pet-v2/source/<set>-raw.png)
into clean frames and write the review page (docs/animation-review.html).

Frames are found at the empty columns between drawings, not at fixed quarters,
so a tail reaching past its quarter stays whole and no neighbour slivers creep
in. Every frame of every set shares one scale and one ground line, so Foxy
keeps the same size between frames. Output: assets/art/pet-v2/<set>.png
(four CELL-wide cells in a row) plus frames.json with each frame's bounds.
"""
import base64, io, json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent))
from build_icon_sheets import key

ROOT = Path(__file__).resolve().parent.parent
DIR = ROOT/'assets/art/pet-v2'
SETS = ['eat', 'bathe', 'sleep', 'carry']
CELL = 256      # output cell (square); the tallest frame fills 90% of it
MIN_GAP = 6     # empty columns that separate two drawings
MIN_WIDTH = 40  # pieces narrower than this are specks, not frames
# Codex drew some sets bigger. Factor that brings each set's fox to the eat
# set's size, measured on a standing frame (ear tip to paws).
SET_SCALE = {'eat': 1.0, 'bathe': 0.76, 'sleep': 1.0, 'carry': 1.0}
# Game scale: the child is 42 world px tall, Foxy 16/22/27/31 by stage.
CHILD_H, FOXY_H = 42, {'baby': 16, 'child': 22, 'teen': 27, 'adult': 31}

def segments(alpha):
    cols = (alpha > 24).sum(0) > 2
    runs, start, gap = [], None, 0
    for x, on in enumerate(cols):
        if on:
            if start is None: start = x
            gap = 0
        elif start is not None:
            gap += 1
            if gap >= MIN_GAP: runs.append((start, x-gap+1)); start, gap = None, 0
    if start is not None: runs.append((start, len(cols)))
    runs = [r for r in runs if r[1]-r[0] >= MIN_WIDTH]
    # Merge the closest neighbours until four frames remain (a detached tail
    # or prop joins the drawing it belongs to).
    while len(runs) > 4:
        i = min(range(len(runs)-1), key=lambda k: runs[k+1][0]-runs[k][1])
        runs[i:i+2] = [(runs[i][0], runs[i+1][1])]
    return runs

def cut(name):
    rgba = key(np.asarray(Image.open(DIR/'source'/f'{name}-raw.png').convert('RGB')))
    frames = []
    for x0, x1 in segments(rgba[..., 3]):
        part = rgba[:, x0:x1]
        ys = np.where((part[..., 3] > 24).any(1))[0]
        xs = np.where((part[..., 3] > 24).any(0))[0]
        frames.append(part[ys.min():ys.max()+1, xs.min():xs.max()+1])
    assert len(frames) == 4, f'{name}: found {len(frames)} frames'
    return frames

def main():
    cut_sets = {n: cut(n) for n in SETS}
    tallest = max(max(f.shape[0], f.shape[1]) for fs in cut_sets.values() for f in fs)
    scale = CELL*0.9/tallest
    meta, pages = {'cell': CELL, 'scale': round(scale, 4), 'sets': {}}, {}
    for name, fs in cut_sets.items():
        sheet = Image.new('RGBA', (CELL*4, CELL), (0, 0, 0, 0))
        meta['sets'][name] = []
        pages[name] = []
        for i, f in enumerate(fs):
            s = scale*SET_SCALE[name]
            img = Image.fromarray(f).resize((max(1, round(f.shape[1]*s)), max(1, round(f.shape[0]*s))), Image.LANCZOS)
            # Centred across, feet on a shared ground line 4% above the cell bottom.
            x = (CELL-img.width)//2; y = round(CELL*0.96)-img.height
            sheet.alpha_composite(img, (i*CELL+x, y))
            pages.setdefault('_img', {})[(name, i)] = img
            meta['sets'][name].append({'region': [i*CELL, 0, CELL, CELL], 'content': [i*CELL+x, y, img.width, img.height], 'pivot': [i*CELL+CELL//2, round(CELL*0.96)]})
            cell = sheet.crop((i*CELL, 0, (i+1)*CELL, CELL))
            buf = io.BytesIO(); cell.save(buf, 'PNG', optimize=True)
            pages[name].append('data:image/png;base64,'+base64.b64encode(buf.getvalue()).decode())
        sheet.save(DIR/f'{name}.png', optimize=True)
    (DIR/'frames.json').write_text(json.dumps(meta, indent=1))
    return pages

def uri(img):
    buf = io.BytesIO(); img.save(buf, 'PNG', optimize=True)
    return 'data:image/png;base64,'+base64.b64encode(buf.getvalue()).decode()

def sprite(meta_key, frame=0):
    m = json.loads((ROOT/'assets/art/meadow-system-v4/run-metadata.json').read_text())[meta_key]
    x, y, w, h = m['frames'][frame]['region']
    return Image.open(ROOT/m['atlas']).convert('RGBA').crop((x, y, x+w, y+h)), m['body_height']

def lineup(imgs, stage='child'):
    """The child, today's in-game Foxy and the candidates on one ground line,
    sized by the game's own heights (child 42 px, Foxy by growth stage)."""
    child, child_body = sprite('explorer')
    foxy, foxy_body = sprite('foxy_child')
    px = 240/CHILD_H                      # page pixels per world pixel
    stand = imgs[('eat', 1)].height       # candidate standing height in cells
    out = [child.resize((round(child.width*CHILD_H*px/child_body), round(child.height*CHILD_H*px/child_body)), Image.LANCZOS),
           foxy.resize((round(foxy.width*FOXY_H[stage]*px/foxy_body), round(foxy.height*FOXY_H[stage]*px/foxy_body)), Image.LANCZOS)]
    for k in [('eat', 1), ('carry', 0), ('bathe', 3), ('sleep', 1)]:
        f = imgs[k]; s = FOXY_H[stage]*px/stand
        out.append(f.resize((round(f.width*s), round(f.height*s)), Image.LANCZOS))
    W = sum(o.width for o in out)+24*(len(out)+1); H = max(o.height for o in out)+40
    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0)); x = 24
    for o in out:
        canvas.alpha_composite(o, (x, H-20-o.height)); x += o.width+24
    return canvas

NOTES = {
    'eat': 'Eat: head in the bowl, chew, lick, happy heart.',
    'bathe': 'Bath: in the tub with bubbles, bubbles on the head, wet, shake dry.',
    'sleep': 'Sleep: lie down, curl up with the tail, breathe, wake and stretch.',
    'carry': 'Fetch: run back with the ball in the mouth (two strides), drop it, sit proudly.',
}

def page(pages):
    old = (ROOT/'docs/animation-review.html').read_text()
    head = old[:old.index('<div class="wrap">')]
    head = head.replace('</style>', '.line{background:var(--stage);border-radius:12px;padding:8px;overflow-x:auto}.line img{display:block;max-width:none;height:auto}\n</style>')
    imgs = pages.pop('_img')
    cards = ''.join(f'<section class="anim"><div class="stage"><img id="p_{n}" src="{pages[n][0]}" alt="{n} loop"></div><div class="info"><h2>{n.capitalize()}</h2><p class="muted">{NOTES[n]}</p><div class="strip">'+''.join(f'<img src="{u}" alt="{n} frame {i+1}">' for i, u in enumerate(pages[n]))+'</div></div></section>' for n in SETS)
    foxy, _ = sprite('foxy_child')
    body = f"""<div class="wrap">
<div><p class="muted">PETOPIA · P1C My Pet · for your review</p><h1>Foxy Animation Review</h1></div>
<p>Codex drew four animation candidates from our Foxy. None of them are in the game yet. Each set is now cut at the real gaps between drawings, so no neighbouring frame shows and no tail is cut off. Every frame shares one size and one ground line, and the bath set was scaled down to match the others.</p>
{cards}
<section class="ref"><h2>Next to the child, at game size</h2><p class="muted">From left: the child (42 px in the world), today's in-game Foxy at the child stage (22 px), then the candidates at that same Foxy size: eat, fetch with the ball in the mouth, bath shake, sleep. The candidates are softer and fluffier than the in-game Foxy, so the sizes match but the style still needs matching before use.</p><div class="line"><img src="{uri(lineup(imgs))}" alt="Child, in-game Foxy and candidates on one ground line"></div></section>
</div>
<script>
const anims={json.dumps(pages)};
const reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;
if(!reduce){{let k=0;setInterval(()=>{{k=(k+1)%4;for(const n in anims)document.getElementById('p_'+n).src=anims[n][k];}},420);}}
</script>
"""
    (ROOT/'docs/animation-review.html').write_text(head+body)

if __name__ == '__main__':
    page(main())
