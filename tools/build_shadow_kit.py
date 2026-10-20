#!/usr/bin/env python3
"""Cuts a Codex ground-shadow sheet (soft ovals on white) into shadow pieces.
Each pixel's darkening of the white becomes alpha over one shadow colour, so
on white the piece looks exactly like the sheet (as light as the concept).

  python3 tools/build_shadow_kit.py assets/ui/shadow-p70 asset idle walk run large air
  python3 tools/build_shadow_kit.py              # the P69 pair (boy, fox)
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
INK = np.array([62.0, 70.0, 48.0])   # the concept's grey-green shadow

def cut(D, names, gain=1.0):
    D = ROOT/D
    raw = np.asarray(Image.open(D/'source/kit-raw.png').convert('RGB')).astype(float)
    white = np.median(raw[:30, :30].reshape(-1, 3), 0)
    a = np.clip(((white-raw)/(white-INK)).mean(-1), 0, 1)
    a[a < 0.02] = 0
    # On the meadow's mid-tone ground the white-sheet strength reads paler.
    a = np.clip(a*gain, 0, 0.82)
    cols = np.where(a.max(0) > 0.05)[0]
    runs, start = [], cols[0]
    for i in range(1, len(cols)):
        if cols[i]-cols[i-1] > 12: runs.append((start, cols[i-1])); start = cols[i]
    runs.append((start, cols[-1]))
    assert len(runs) == len(names), (len(runs), runs)
    meta = {}
    for name, (x0, x1) in zip(names, runs):
        sub = a[:, max(0, x0-6):x1+7]
        ys = np.where(sub.max(1) > 0.02)[0]
        sub = sub[max(0, ys.min()-4):ys.max()+5]
        rgba = np.zeros(sub.shape+(4,), np.uint8)
        rgba[..., :3] = INK.astype(np.uint8)
        rgba[..., 3] = (sub*255).astype(np.uint8)
        Image.fromarray(rgba).save(D/f'{name}.png')
        meta[name] = {'size': [sub.shape[1], sub.shape[0]], 'body': [0, 0, sub.shape[1], sub.shape[0]], 'peak': round(float(sub.max()), 3)}
        print(name, meta[name])
    json.dump(meta, open(D/'kit.json', 'w'), indent=1)

if __name__ == '__main__':
    if len(sys.argv) > 2: cut(sys.argv[1], sys.argv[2:], 1.45 if 'p70' in sys.argv[1] else 1.0)
    else: cut('assets/ui/shadow-p69', ['boy', 'fox'])
