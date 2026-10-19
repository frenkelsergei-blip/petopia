#!/usr/bin/env python3
"""Remove the magenta fringe left on cut-out kit pieces.

Pieces are cut from Codex sheets drawn on magenta. Their outline pixels are a
mix of the paper colour and the magenta background, so a hard key leaves a
pink rim that shows once the piece is scaled. For every pixel near the
transparent area this takes the colour of the nearest solid inside pixel,
works out how much of the pixel was magenta, and turns that share into
transparency (soft edge, no pink).

  python3 tools/clean_kit_edges.py                 # every assets/ui/*-p32 kit
  python3 tools/clean_kit_edges.py assets/ui/menu50-p32/tile.png ...
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MAGENTA = np.array([255.0, 0.0, 255.0])
BAND = 4


def shift(a, dy, dx):
    out = np.zeros_like(a)
    h, w = a.shape[:2]
    ys, yd = (slice(dy, h), slice(0, h - dy)) if dy >= 0 else (slice(0, h + dy), slice(-dy, h))
    xs, xd = (slice(dx, w), slice(0, w - dx)) if dx >= 0 else (slice(0, w + dx), slice(-dx, w))
    out[ys, xs] = a[yd, xd]
    return out


def clean(rgba: np.ndarray) -> np.ndarray:
    rgb = rgba[..., :3].astype(float)
    alpha = rgba[..., 3].astype(float)
    empty = alpha < 8
    # Distance (in steps) from the empty area, up to BAND.
    near = empty.copy()
    band = np.zeros(empty.shape, bool)
    for _ in range(BAND):
        grown = near.copy()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            grown |= shift(near, dy, dx)
        band |= grown & ~empty
        near = grown
    inside = ~empty & ~band
    # Carry the inside colour outwards into the band (and a little beyond, so
    # filtering never samples magenta from empty pixels).
    colour = np.where(inside[..., None], rgb, 0.0)
    known = inside.copy()
    for _ in range(BAND + 3):
        if known.all():
            break
        acc = np.zeros_like(colour)
        cnt = np.zeros(known.shape)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            k = shift(known, dy, dx)
            acc += np.where(k[..., None], shift(colour, dy, dx), 0)
            cnt += k
        fill = ~known & (cnt > 0)
        colour[fill] = acc[fill] / cnt[fill][:, None]
        known |= fill
    # Pieces too thin to have an inside keep their own colour.
    colour[~known] = rgb[~known]
    # How much of each band pixel is the piece (t) versus magenta (1 - t).
    d = colour - MAGENTA
    denom = (d * d).sum(-1)
    t = np.where(denom > 1, ((rgb - MAGENTA) * d).sum(-1) / np.maximum(denom, 1), 1.0)
    t = np.clip(t, 0.0, 1.0)
    pinkish = (rgb[..., 0] - rgb[..., 1] > 20) & (rgb[..., 2] - rgb[..., 1] > 10)
    # Only band pixels tinted towards magenta lose opacity; true colours stay.
    tinted = band & pinkish & ((colour[..., 0] - colour[..., 1] <= 20) | (colour[..., 2] - colour[..., 1] <= 10))
    new_alpha = np.where(tinted, alpha * t, alpha)
    out_rgb = np.where((band | empty)[..., None] & known[..., None], np.where(tinted[..., None] | empty[..., None], colour, rgb), rgb)
    out = np.dstack([np.clip(out_rgb, 0, 255), np.clip(new_alpha, 0, 255)]).astype(np.uint8)
    return out


def clean_file(path: Path) -> None:
    im = Image.open(path)
    if im.mode != 'RGBA':
        return
    a = np.asarray(im)
    if a[..., 3].min() == 255:
        return
    Image.fromarray(clean(a)).save(path)


if __name__ == '__main__':
    files = [Path(p) for p in sys.argv[1:]] or [p for p in sorted((ROOT / 'assets/ui').glob('*-p32/*.png'))]
    for f in files:
        clean_file(f)
    print('cleaned', len(files))
