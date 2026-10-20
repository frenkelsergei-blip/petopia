#!/usr/bin/env python3
"""A60: cuts the painted P71a set pieces (Codex, magenta background,
assets/art/meadow-p31/source/sets/<name>-raw.png) into
assets/art/meadow-p31/set_<name>.png, cropped and scaled by SCALE; writes
sets.json {name: {raw: [w,h], crop: [x,y], scale}} so room data can keep
measuring surfaces in the raw painting's pixels.

  python3 tools/build_set_pieces.py
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent))
from world_style import key
from clean_kit_edges import clean
ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT/'assets/art/meadow-p31/source/sets'
OUT = ROOT/'assets/art/meadow-p31'
SCALE = 0.7
meta = {}
for raw in sorted(SRC.glob('*-raw.png')):
    n = raw.stem[:-4]
    a = key(raw)
    ys, xs = np.where(a[..., 3] > 0)
    x0, y0 = int(xs.min()), int(ys.min())
    q = clean(a[y0:ys.max()+1, x0:xs.max()+1])
    im = Image.fromarray(q)
    im = im.resize((round(im.width*SCALE), round(im.height*SCALE)), Image.LANCZOS)
    im.save(OUT/f'set_{n}.png')
    meta[n] = {'raw': list(Image.open(raw).size), 'crop': [x0, y0], 'scale': SCALE}
    print(n, meta[n], im.size)
json.dump(meta, open(OUT/'sets.json', 'w'), indent=1)
