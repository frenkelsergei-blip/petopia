#!/usr/bin/env python3
"""A58 main menu kit: Codex copies the concept's pieces WITH their soft
shadows onto flat sky blue (source/kit-raw.png). Each pixel is either the
plain blue (transparent), the blue darkened (its shadow: black at that
strength) or the paper itself (opaque). Writes assets/ui/menu41-p32/
m_<piece>.png in sheet order."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter, ImageDraw
import json
sys.path.insert(0, str(Path(__file__).parent))
from build_ui_kit import groups
D = Path(__file__).resolve().parent.parent/'assets/ui/menu41-p32'
NAMES = ['logo', 'start', 'plank', 'pill', 'coin_pill', 'coin', 'ic_games', 'ic_settings']
raw = np.asarray(Image.open(D/'source/kit-raw.png').convert('RGB')).astype(float)
B = np.median(np.concatenate([raw[:20, :20].reshape(-1, 3), raw[-20:, -20:].reshape(-1, 3)]), 0)
f = (raw/B).mean(-1)
err = np.abs(raw-B*f[..., None]).sum(-1)
# The blue and its shadow keep the sky's hue (blue well above red);
# paper, leaves, coin and the navy icons do not (navy is far darker).
lum = raw.mean(-1)
plain = (err < 22) | ((raw[..., 2]-raw[..., 0] > 55) & (lum > 95))
f = np.where(plain, np.minimum(f, lum/B.mean()), f)
alpha = np.where(plain, np.clip((1.0-f)*1.3, 0, 0.6), 1.0)
alpha[plain & (f > 0.985)] = 0
rgb = np.where(plain[..., None], 0.0, raw)
rgba = np.dstack([rgb, alpha*255]).astype(np.uint8)
boxes = [b for b in groups(~plain, join=3) if (b[2]-b[0])*(b[3]-b[1]) > 2000]
boxes.sort(key=lambda b: (b[1]//200, b[0]))
assert len(boxes) == len(NAMES), boxes
meta = {}
for (x0, y0, x1, y1), n in zip(boxes, NAMES):
    p = 40
    sub = Image.fromarray(rgba[max(0, y0-p):y1+p, max(0, x0-p):x1+p])
    # Keep only the piece and its shadow (drop stray specks of the sheet).
    a = np.asarray(sub)[..., 3] > 8
    m = Image.fromarray((a*255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7))
    ys, xs = np.where(np.asarray(m) > 0)
    cy, cx = np.asarray(m).shape[0]//2, np.asarray(m).shape[1]//2
    i = int(np.argmin((ys-cy)**2+(xs-cx)**2))
    ImageDraw.floodfill(m, (int(xs[i]), int(ys[i])), 128)
    keep = np.asarray(m) == 128
    arr = np.array(sub); arr[..., 3] = np.where(keep, arr[..., 3], 0)
    sub = Image.fromarray(arr); sub = sub.crop(sub.getbbox())
    sub.save(D/f'm_{n}.png')
    op = np.asarray(sub)[..., 3] > 250
    ys, xs = np.where(op)
    meta[n] = {'size': list(sub.size), 'body': [int(xs.min()), int(ys.min()), int(xs.max()-xs.min()+1), int(ys.max()-ys.min()+1)]}
    print(n, sub.size, meta[n]['body'])
L = json.load(open(D/'layout.json')); L['m'] = meta
json.dump(L, open(D/'layout.json', 'w'), indent=1)
