#!/usr/bin/env python3
"""A60: Codex paints a room's set pieces copied from its approved concept
(assets/concepts/current/paper-v1/<concept>.png), each alone on magenta, into
assets/art/meadow-p31/source/sets/<name>-raw.png. Cut with
tools/build_set_pieces.py.

  python3 tools/draw_set_pieces.py river
"""
import subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT/'assets/art/meadow-p31/source/sets'
CON = ROOT/'assets/concepts/current/paper-v1'
H = """Use your built-in image generation tool to create ONE image (as large as the tool allows), then save it (copy the generated PNG) to exactly this path:
{p}
Do not modify any other file. Do not write code. When finished, reply with the saved path only.

A SET PIECE for a 2D side-view game level, copied EXACTLY from the attached approved PETOPIA concept (same torn-paper collage painting, same colours, same detail, same light): {what}
The piece ALONE on ONE flat pure MAGENTA background (#FF00FF), nothing cut off, at least 40 px of magenta around it. NO characters, NO animals, NO text, NO labels, NO HUD, NO buttons, NO coins, NO sky, NO distant background (no mountains, no town, no lake). Side view, straight; every walkable top is a FLAT HORIZONTAL grassy (or stone) surface, clearly readable.
"""
ROOMS = {
 'river': ('P72-river_crossing', {
  'rw_west': "the LEFT BANK of River Crossing: a wide flat grassy path along the bottom (yellow-green torn-paper grass edge on top of a leafy earth block), behind it the tall pale stone cliff covered in ivy and flowers, the wooden LADDER leaning on the cliff from the path up to the flat grassy UPPER SHELF with its wooden fence, and the big leafy tree growing on the top-left of the shelf. Wide piece, about 2 wide to 1.3 tall.",
  'rw_gorge': "the WATERFALL GORGE under the bridge: the inner rocky edges of the two banks left and right (their flat grassy tops at the same height at the top corners), the white waterfall falling from the middle down into a sparkling blue pool with mossy stepping stones, rocks, reeds, white lilies and lily pads. NO bridge, NO frogs. About 1.3 wide to 1 tall.",
  'rw_east': "the RIGHT BANK: a flat grassy ledge on top, below it the ivy rock with the dark arched CAVE MOUTH with a small glowing lantern beside it at the bottom level (the cave floor flat with the path), and on its right side the STONE STAIRS with a wooden handrail climbing from the bottom path up to the right top. About 1.4 wide to 1 tall.",
  'rw_tower': "the UPPER HILL with the little round stone TOWER with the red tiled roof and arched wooden door, the wooden SUN GATE in the wooden fence beside it, flowers and ivy, a flat grassy top, and the leafy earth and stone cliff block below it. About 1.6 wide to 1 tall.",
  'rw_rock': "a small mossy rock OUTCROP with a flat grassy top and a few flowers and reeds, like the rocks in the river of the concept, about 2 wide to 1 tall.",
 }),
}
if __name__ == '__main__':
    con, pieces = ROOMS[sys.argv[1]]
    SRC.mkdir(parents=True, exist_ok=True)
    for n, w in pieces.items():
        p = SRC/f'{n}-prompt.txt'
        p.write_text(H.format(p=str(SRC/f'{n}-raw.png'), what=w))
        subprocess.Popen(['codex', 'exec', '-s', 'danger-full-access', '-i', str(CON/f'{con}.png'), '-'], stdin=open(p), stdout=open(ROOT/f'test-results/codex/set-{n}.log', 'w'), stderr=subprocess.STDOUT, cwd=ROOT)
        print('drawing', n)
