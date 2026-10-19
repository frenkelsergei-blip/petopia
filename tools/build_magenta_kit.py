#!/usr/bin/env python3
"""Cuts a Codex icon sheet drawn on flat magenta into pieces (no shadows).
Rows are found by centre line; inside a row the closest parts are joined
until the row holds as many icons as named (rays, sound waves and slider
lines stay with their icon). Writes <dir>/<name>.png and <dir>/kit.json,
then removes the magenta fringe (tools/clean_kit_edges.py).

  python3 tools/build_magenta_kit.py assets/ui/icons-p69 6,8,8,3 food happy ...
"""
import sys, json, subprocess
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent))
from build_ui_kit import groups

def gap(a, b):
    dx = max(0, max(a[0], b[0])-min(a[2], b[2]))
    dy = max(0, max(a[1], b[1])-min(a[3], b[3]))
    return (dx*dx+dy*dy) ** 0.5

def cut(D, counts, names):
    D = Path(D)
    raw = np.asarray(Image.open(D/'source/kit-raw.png').convert('RGB')).astype(int)
    r, g, b = raw[..., 0], raw[..., 1], raw[..., 2]
    bg = (r > 170) & (b > 170) & (g < 110) & (abs(r-b) < 90)
    boxes = [list(x) for x in groups(~bg, join=4) if (x[2]-x[0])*(x[3]-x[1]) > 60]
    boxes.sort(key=lambda x: (x[1]+x[3])/2)
    rows, row = [], []
    for x in boxes:
        if row and (x[1]+x[3])/2-np.mean([(y[1]+y[3])/2 for y in row]) > 110 and len(rows) < len(counts)-1:
            rows.append(row); row = []
        row.append(x)
    rows.append(row)
    assert len(rows) == len(counts), [len(r) for r in rows]
    out = []
    for row, n in zip(rows, counts):
        while len(row) > n:
            best = None
            for i in range(len(row)):
                for j in range(i+1, len(row)):
                    d = gap(row[i], row[j])
                    if best is None or d < best[0]: best = (d, i, j)
            _, i, j = best
            a, c = row[i], row[j]
            row[i] = [min(a[0], c[0]), min(a[1], c[1]), max(a[2], c[2]), max(a[3], c[3])]
            del row[j]
        assert len(row) == n, (len(row), n)
        out += sorted(row, key=lambda x: x[0])
    assert len(out) == len(names), (len(out), len(names))
    rgba = np.dstack([raw, np.where(bg, 0, 255)]).astype(np.uint8)
    meta = {}
    for (x0, y0, x1, y1), name in zip(out, names):
        p = 3
        sub = Image.fromarray(rgba[max(0, y0-p):y1+p, max(0, x0-p):x1+p])
        sub.save(D/f'{name}.png')
        meta[name] = {'size': list(sub.size), 'body': [0, 0, sub.size[0], sub.size[1]]}
        print(name, meta[name]['size'])
    json.dump(meta, open(D/'kit.json', 'w'), indent=1)
    subprocess.run([sys.executable, str(Path(__file__).parent/'clean_kit_edges.py')]+[str(D/f'{n}.png') for n in names], check=True)

if __name__ == '__main__':
    cut(sys.argv[1], [int(x) for x in sys.argv[2].split(',')], sys.argv[3:])
