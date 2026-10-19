#!/usr/bin/env python3
"""Cuts a Codex kit drawn on flat sky blue (pieces WITH their soft shadows).
Each pixel is the plain blue (transparent), the blue darkened (shadow: black
at that strength) or the piece (opaque). Writes <dir>/<name>.png and
<dir>/kit.json {name: {size, body}} (body = the opaque paper, no shadow).

  python3 tools/build_blue_kit.py assets/ui/frame-p68 plaque close card ...
"""
import sys, json
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter, ImageDraw
sys.path.insert(0, str(Path(__file__).parent))
from build_ui_kit import groups
def cut(D, names, src='source/kit-raw.png', rows=False, join=3):
    D = Path(D)
    raw = np.asarray(Image.open(D/src).convert('RGB')).astype(float)
    B = np.median(np.concatenate([raw[:20, :20].reshape(-1, 3), raw[-20:, -20:].reshape(-1, 3)]), 0)
    f = (raw/B).mean(-1)
    err = np.abs(raw-B*f[..., None]).sum(-1)
    lum = raw.mean(-1)
    plain = (err < 22) | ((raw[..., 2]-raw[..., 0] > 55) & (lum > 95))
    f = np.where(plain, np.minimum(f, lum/B.mean()), f)
    alpha = np.where(plain, np.clip((1.0-f)*1.3, 0, 0.6), 1.0)
    alpha[plain & (f > 0.985)] = 0
    rgba = np.dstack([np.where(plain[..., None], 0.0, raw), alpha*255]).astype(np.uint8)
    boxes = [b for b in groups(~plain, join=join) if (b[2]-b[0])*(b[3]-b[1]) > 2000]
    if rows:
        # Rows by centre line (pieces of one row differ in height).
        boxes.sort(key=lambda b: (b[1]+b[3])/2)
        out, row = [], []
        for b in boxes:
            if row and (b[1]+b[3])/2-sum((r[1]+r[3])/2 for r in row)/len(row) > 90:
                out += sorted(row, key=lambda r: r[0]); row = []
            row.append(b)
        boxes = out+sorted(row, key=lambda r: r[0])
    else:
        boxes.sort(key=lambda b: (b[1]//150, b[0]))
    assert len(boxes) == len(names), (len(boxes), boxes)
    meta = {}
    for (x0, y0, x1, y1), n in zip(boxes, names):
        p = 40
        sub = Image.fromarray(rgba[max(0, y0-p):y1+p, max(0, x0-p):x1+p])
        a = np.asarray(sub)[..., 3] > 8
        m = Image.fromarray((a*255).astype(np.uint8)).filter(ImageFilter.MaxFilter(max(7, join*2+1)))
        ys, xs = np.where(np.asarray(m) > 0)
        h, w = np.asarray(m).shape
        i = int(np.argmin((ys-h//2)**2+(xs-w//2)**2))
        ImageDraw.floodfill(m, (int(xs[i]), int(ys[i])), 128)
        arr = np.array(sub); arr[..., 3] = np.where(np.asarray(m) == 128, arr[..., 3], 0)
        # Only this piece and its own shadow (a neighbour's shadow can touch it).
        ox, oy = x0-max(0, x0-p), y0-max(0, y0-p)
        keep = np.zeros(arr.shape[:2], bool)
        # ...and never past halfway to the next piece.
        L, Rt, T, Bt = x0-26, x1+26, y0-26, y1+30
        for (a0, b0, a1, b1) in boxes:
            if (a0, b0, a1, b1) == (x0, y0, x1, y1): continue
            if b0 < y1 and b1 > y0:
                if a1 <= x0: L = max(L, (a1+x0)//2)
                if a0 >= x1: Rt = min(Rt, (x1+a0)//2)
            if a0 < x1 and a1 > x0:
                if b1 <= y0: T = max(T, (b1+y0)//2)
                if b0 >= y1: Bt = min(Bt, (y1+b0)//2)
        bx0, by0 = max(0, x0-p), max(0, y0-p)
        keep[max(0, T-by0):max(0, Bt-by0), max(0, L-bx0):max(0, Rt-bx0)] = True
        arr[..., 3] = np.where(keep, arr[..., 3], 0)
        sub = Image.fromarray(arr); sub = sub.crop(sub.getbbox()); sub.save(D/f'{n}.png')
        oy, ox = np.where(np.asarray(sub)[..., 3] > 250)
        meta[n] = {'size': list(sub.size), 'body': [int(ox.min()), int(oy.min()), int(ox.max()-ox.min()+1), int(oy.max()-oy.min()+1)]}
        print(n, meta[n])
    json.dump(meta, open(D/'kit.json', 'w'), indent=1)
if __name__ == '__main__':
    a = sys.argv[1:]
    rows = '--rows' in a
    a = [x for x in a if x != '--rows']
    join = 3
    if '--join' in a:
        i = a.index('--join'); join = int(a[i+1]); del a[i:i+2]
    cut(a[0], a[1:], rows=rows, join=join)
