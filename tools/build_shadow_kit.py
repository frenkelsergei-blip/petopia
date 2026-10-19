#!/usr/bin/env python3
"""Cuts the P69 ground shadows (Codex, soft grey ovals on white,
assets/ui/shadow-p69/source/kit-raw.png) into shadow pieces: the darkness of
each pixel becomes alpha over a deep meadow green, so they lay on any ground
like the shadows under the boy and Foxy in P69e.

  python3 tools/build_shadow_kit.py
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image
D = Path(__file__).resolve().parents[1]/'assets/ui/shadow-p69'
raw = np.asarray(Image.open(D/'source/kit-raw.png').convert('L')).astype(float)
a = np.clip((250.0-raw)/190.0, 0, 1)
a[a < 0.03] = 0
cols = np.where(a.max(0) > 0.08)[0]
# two ovals, split at the widest empty column gap
gaps = np.diff(cols)
cut = cols[int(np.argmax(gaps))]+gaps.max()//2
meta = {}
for name, (x0, x1) in zip(['boy', 'fox'], [(0, cut), (cut, raw.shape[1])]):
    sub = a[:, x0:x1]
    ys, xs = np.where(sub > 0.03)
    sub = sub[ys.min():ys.max()+1, xs.min():xs.max()+1]
    rgba = np.zeros(sub.shape+(4,), np.uint8)
    rgba[..., :3] = [22, 30, 10]
    rgba[..., 3] = (sub*255).astype(np.uint8)
    Image.fromarray(rgba).save(D/f'{name}.png')
    meta[name] = {'size': [sub.shape[1], sub.shape[0]], 'body': [0, 0, sub.shape[1], sub.shape[0]]}
    print(name, meta[name], round(sub.max(), 2))
json.dump(meta, open(D/'kit.json', 'w'), indent=1)
