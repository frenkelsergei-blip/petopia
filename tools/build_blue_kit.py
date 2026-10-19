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
def cut(D, names, src='source/kit-raw.png'):
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
    boxes = [b for b in groups(~plain, join=3) if (b[2]-b[0])*(b[3]-b[1]) > 2000]
    boxes.sort(key=lambda b: (b[1]//150, b[0]))
    assert len(boxes) == len(names), (len(boxes), boxes)
    meta = {}
    for (x0, y0, x1, y1), n in zip(boxes, names):
        p = 40
        sub = Image.fromarray(rgba[max(0, y0-p):y1+p, max(0, x0-p):x1+p])
        a = np.asarray(sub)[..., 3] > 8
        m = Image.fromarray((a*255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7))
        ys, xs = np.where(np.asarray(m) > 0)
        h, w = np.asarray(m).shape
        i = int(np.argmin((ys-h//2)**2+(xs-w//2)**2))
        ImageDraw.floodfill(m, (int(xs[i]), int(ys[i])), 128)
        arr = np.array(sub); arr[..., 3] = np.where(np.asarray(m) == 128, arr[..., 3], 0)
        sub = Image.fromarray(arr); sub = sub.crop(sub.getbbox()); sub.save(D/f'{n}.png')
        oy, ox = np.where(np.asarray(sub)[..., 3] > 250)
        meta[n] = {'size': list(sub.size), 'body': [int(ox.min()), int(oy.min()), int(ox.max()-ox.min()+1), int(oy.max()-oy.min()+1)]}
        print(n, meta[n])
    json.dump(meta, open(D/'kit.json', 'w'), indent=1)
if __name__ == '__main__':
    cut(sys.argv[1], sys.argv[2:])
