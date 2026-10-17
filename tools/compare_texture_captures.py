"""Compare plain captures before and after runtime image copies.

Usage: python3 tools/compare_texture_captures.py BEFORE_DIR AFTER_DIR
Writes test-results/texture-scale/compare.json and side-by-side crops of the
most changed area of the worst screens to test-results/texture-scale/compare/.
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'test-results/texture-scale'

def psnr(a, b):
    mse = np.mean((a.astype(np.float32) - b.astype(np.float32)) ** 2)
    return 99.0 if mse == 0 else float(10 * np.log10(255 ** 2 / mse))

def worst_block(a, b, size=256):
    diff = np.abs(a.astype(np.int16) - b.astype(np.int16)).sum(axis=2).astype(np.float64)
    h, w = diff.shape
    best, at = -1, (0, 0)
    for y in range(0, max(1, h - size), size // 2):
        for x in range(0, max(1, w - size), size // 2):
            score = diff[y:y + size, x:x + size].mean()
            if score > best: best, at = score, (x, y)
    return at, best / 3

def main(before, after):
    rows = []
    crops = OUT / 'compare'; crops.mkdir(parents=True, exist_ok=True)
    for shot in sorted(Path(before).glob('*.png')):
        other = Path(after) / shot.name
        if not other.exists(): continue
        a = np.asarray(Image.open(shot).convert('RGB')); b = np.asarray(Image.open(other).convert('RGB'))
        if a.shape != b.shape: continue
        (x, y), block = worst_block(a, b)
        rows.append({'shot': shot.stem, 'psnr_db': round(psnr(a, b), 2), 'worst_block_mean_diff': round(block, 2), 'worst_block': [x, y]})
    rows.sort(key=lambda r: r['psnr_db'])
    for row in rows[:12]:
        x, y = row['worst_block']
        a = Image.open(Path(before) / (row['shot'] + '.png')).convert('RGB').crop((x, y, x + 256, y + 256))
        b = Image.open(Path(after) / (row['shot'] + '.png')).convert('RGB').crop((x, y, x + 256, y + 256))
        pair = Image.new('RGB', (520, 256), 'white'); pair.paste(a, (0, 0)); pair.paste(b, (264, 0))
        pair.save(crops / (row['shot'] + '.png'))
    (OUT / 'compare.json').write_text(json.dumps(rows, indent=1))
    for row in rows[:15]: print(row)
    print('screens', len(rows), 'min PSNR', rows[0]['psnr_db'] if rows else None, 'median PSNR', rows[len(rows) // 2]['psnr_db'] if rows else None)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
