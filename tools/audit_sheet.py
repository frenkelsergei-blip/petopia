#!/usr/bin/env python3
"""Contact sheet of the audit captures: python3 tools/audit_sheet.py 390x844 [names...]"""
import sys, glob
from PIL import Image
tag = sys.argv[1]; only = sys.argv[2:]
fs = sorted(f for f in glob.glob(f"test-results/audit/*-{tag}.png") if not only or any(o in f for o in only))
ims = [Image.open(f).convert("RGB") for f in fs]
w0, h0 = ims[0].size
cols = 6 if w0 < h0 else 4
sc = min(1.0, 1600/(cols*w0))
w, h = int(w0*sc), int(h0*sc)
rows = (len(ims)+cols-1)//cols
sheet = Image.new("RGB", (cols*(w+6), rows*(h+6)), "white")
for i, im in enumerate(ims): sheet.paste(im.resize((w, h)), ((i % cols)*(w+6), (i//cols)*(h+6)))
sheet.save(f"test-results/audit/sheet-{tag}.jpg", quality=85)
print(len(ims), sheet.size)
