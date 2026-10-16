"""Run Godot suites and reject engine errors even when Godot exits with status zero."""
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ENGINE = Path('/Applications/Godot.app/Contents/MacOS/Godot')
if not ENGINE.exists():
    import shutil
    ENGINE = shutil.which('godot') or shutil.which('godot4')
    if not ENGINE:
        raise SystemExit('Godot 4.7.2 is required. Set up the engine before running checks.')

names = sys.argv[1:] or ['systems', 'scenes', 'graybox', 'cooperation', 'smoothness', 'trail_tools', 'mobile', 'art_polish', 'main_menu', 'adoption', 'home_growth', 'web']
out = ROOT / 'test-results'
out.mkdir(exist_ok=True)
failed = False
for name in names:
    result = subprocess.run([str(ENGINE), '--headless', '--resolution', '1280x720', '--fixed-fps', '60', '--path', str(ROOT), '--script', f'res://tests/test_{name}.gd'], capture_output=True, text=True, timeout=60)
    log = result.stdout + result.stderr
    (out / f'{name}.log').write_text(log)
    errors = [line for line in log.splitlines() if 'SCRIPT ERROR:' in line or line.startswith('ERROR:') or 'leaked at exit' in line or 'RIDs of type' in line]
    okay = result.returncode == 0 and not errors
    print(f'{name}: {"PASS" if okay else "FAIL"}')
    for line in log.splitlines():
        if 'PETOPIA ' in line or line in errors: print('  ' + line)
    failed |= not okay
sys.exit(1 if failed else 0)
