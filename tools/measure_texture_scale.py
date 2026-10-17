"""Measure how large every exported source image is actually drawn.

Each image is replaced by a probe whose red/green channels encode the source
texel column (x pass) or row (y pass) and whose blue channel identifies the
image. tools/capture_texture_scale.gd visits every public screen at the
largest supported displays; this script reads the captures and reports the
smallest uniform scale that still gives at least one texel per screen pixel.
"""
import json, os, re, shutil, subprocess, sys
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / 'test-results/texture-scale'

def sources():
    text = (ROOT / 'export_presets.cfg').read_text()
    files = re.search(r'export_files=PackedStringArray\((.*?)\)\n', text).group(1)
    paths = [p for p in re.findall(r'"(res://[^"]+\.png)"', files)]
    plan = json.loads((ROOT / 'assets/runtime/manifest.json').read_text())['textures'] if (ROOT / 'assets/runtime/manifest.json').exists() else {}
    # Measure source images, including those already replaced by runtime copies.
    runtime = {v['runtime']: k for k, v in plan.items()}
    return sorted({runtime.get(p, p) for p in paths})

def make_probes(paths, axis):
    folder = WORK / ('probe-' + axis)
    shutil.rmtree(folder, ignore_errors=True); folder.mkdir(parents=True)
    plan = {}
    for index, path in enumerate(paths):
        source = np.asarray(Image.open(ROOT / path[6:]).convert('RGBA'))
        h, w = source.shape[:2]
        coord = np.arange(w if axis == 'x' else h, dtype=np.uint16)
        grid = np.broadcast_to(coord[None, :], (h, w)) if axis == 'x' else np.broadcast_to(coord[:, None], (h, w))
        probe = np.zeros((h, w, 4), np.uint8)
        probe[..., 0] = grid >> 8
        probe[..., 1] = grid & 255
        probe[..., 2] = 6 * index + 3
        probe[..., 3] = np.where(source[..., 3] >= 128, 255, 0)
        name = f'{index:02d}.png'
        Image.fromarray(probe, 'RGBA').save(folder / name)
        plan[path] = name
    (folder / 'probes.json').write_text(json.dumps(plan))
    return folder

def capture(folder, out):
    shutil.rmtree(out, ignore_errors=True)
    engine = os.environ.get('GODOT_BIN') or shutil.which('godot') or '/Applications/Godot.app/Contents/MacOS/Godot'
    command = [engine, '--path', str(ROOT), '--script', 'res://tools/capture_texture_scale.gd', '--', str(out)]
    if folder: command += ['--probe', str(folder)]
    if sys.platform.startswith('linux') and not os.environ.get('DISPLAY'):
        command = ['xvfb-run', '-a', '-s', '-screen 0 4000x3000x24'] + command
    result = subprocess.run(command, capture_output=True, text=True)
    if 'TEXTURE SCALE CAPTURES' not in result.stdout: raise SystemExit(result.stdout[-3000:] + result.stderr[-3000:])

def runs(values, ids, min_length=12):
    """Yield (image index, texels per screen pixel) for each probe run in a line."""
    blue = values[:, 2].astype(np.int32)
    decoded = values[:, 0].astype(np.int32) * 256 + values[:, 1]
    edges = np.flatnonzero(np.diff(blue)) + 1
    starts = np.concatenate(([0], edges)); ends = np.concatenate((edges, [len(blue)]))
    for start, end in zip(starts, ends):
        length = end - start
        if length < min_length: continue
        index = ids.get(int(blue[start]))
        if index is None: continue
        v = decoded[start:end]
        if v.max() - v.min() < 2: continue
        k = max(6, length // 2)
        yield index, float(np.median(np.abs(v[k:] - v[:-k]) / k))

def analyse(out, paths, axis, sizes):
    ids = {6 * i + 3: i for i in range(len(paths))}
    found = {}
    for shot in sorted(out.glob('*.png')):
        pixels = np.asarray(Image.open(shot).convert('RGB'))
        lines = pixels if axis == 'x' else pixels.transpose(1, 0, 2)
        per = {}
        for line in lines[::3]:
            for index, texels in runs(line, ids):
                if texels > 0: per.setdefault(index, []).append(texels)
        for index, values in per.items():
            if len(values) < 4: continue
            # Low percentile = the most magnified place this image appears on the shot.
            texels = float(np.percentile(values, 10))
            found.setdefault(paths[index], []).append((shot.stem, texels))
    return found

def main():
    paths = sources()
    sizes = {p: Image.open(ROOT / p[6:]).size for p in paths}
    report = {}
    for axis in ['x', 'y']:
        out = WORK / ('shots-' + axis)
        if '--reuse' not in sys.argv or not out.exists():  # --reuse: analyse existing captures
            capture(make_probes(paths, axis), out)
        for path, entries in analyse(out, paths, axis, sizes).items():
            for shot, texels in entries:
                report.setdefault(path, {'source': list(sizes[path]), 'needed': 0.0, 'shot': None, 'seen': []})
                needed = 1.0 / texels  # source scale giving one texel per screen pixel
                item = report[path]
                item['seen'].append(shot)
                if needed > item['needed']: item['needed'], item['shot'] = round(needed, 4), shot + '/' + axis
    for path in paths:
        report.setdefault(path, {'source': list(sizes[path]), 'needed': None, 'shot': None, 'seen': []})
        report[path]['seen'] = sorted(set(report[path]['seen']))
    (WORK / 'report.json').write_text(json.dumps(report, indent=1))
    for path, item in sorted(report.items(), key=lambda kv: -(kv[1]['needed'] or 9)):
        print(f"{item['needed'] if item['needed'] is not None else 'unseen':>8} {item['shot'] or '':40} {path}")

if __name__ == '__main__':
    main()
