"""Add the current style kits to the web export list (export_presets.cfg).
Source sheets (any /source/ folder) are never shipped (web image budget)."""
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
KITS=['assets/art/meadow-p31','assets/art/heroes-p31/frames','assets/ui/hud-p32','assets/ui/hud2-p32','assets/ui/hud3-p32','assets/ui/menu-p32','assets/ui/pause-p32','assets/ui/roomui-p32','assets/ui/bag-p32','assets/ui/shop-p32','assets/ui/map-p32','assets/ui/details-p32','assets/ui/room-p43','assets/ui/food-p32','assets/ui/menu50-p32','assets/ui/adopt-p32','assets/ui/result-p32','assets/ui/ball-p32','assets/ui/turn-p32','assets/ui/collect-p32','assets/ui/games-p32','assets/ui/areamap-p32','assets/ui/popup-p32','assets/ui/decor-p32']
cfg=ROOT/'export_presets.cfg'
text=cfg.read_text()
m=re.search(r'export_files=PackedStringArray\((.*?)\)\n',text)
have=re.findall(r'"([^"]+)"',m.group(1))
add=[]
for kit in KITS:
    for f in sorted((ROOT/kit).rglob('*')):
        if f.suffix not in ('.png','.json') or '/source/' in str(f): continue
        # Superseded layer attempts (the env kits replaced them; never drawn).
        if f.parent.name=='meadow-p31' and f.name.startswith(('L_','cv_','ce_','tw_')): continue
        r='res://'+str(f.relative_to(ROOT))
        if r not in have: add.append(r)
have=[h for h in have if '/source/' not in h]
new='export_files=PackedStringArray('+', '.join(f'"{h}"' for h in have+add)+')\n'
cfg.write_text(text[:m.start()]+new+text[m.end():])
print('added',len(add))
for a in add: print(' ',a)
