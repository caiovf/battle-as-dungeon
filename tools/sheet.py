"""Monta uma prancha de prévia com todos os sprites gerados."""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
import gen_art
gen_art.build_map_sprites()
try:
    import arena_art
    arena_art.build(gen_art.save)
except ImportError:
    pass
groups = {}
for k, c in gen_art.OUT.items():
    groups.setdefault(k.split('/')[0], []).append((k, c))
SC = int(sys.argv[2]) if len(sys.argv) > 2 else 4
bg = (24, 18, 30)
rows = []
for g, items in groups.items():
    if g == 'bg':
        continue
    x, y, rowh, W = 10, 10, 0, 1500
    pos = []
    for k, c in items:
        w, h = c.w * SC, c.h * SC
        if x + w > W - 10:
            x = 10; y += rowh + 26; rowh = 0
        pos.append((k, c, x, y)); x += w + 18; rowh = max(rowh, h)
    rows.append((g, pos, y + rowh + 30))
H = sum(r[2] + 30 for r in rows)
im = Image.new('RGBA', (1500, H), bg)
d = ImageDraw.Draw(im)
oy = 0
for g, pos, h in rows:
    d.text((10, oy + 4), g.upper(), fill=(230, 200, 140))
    for k, c, x, y in pos:
        im.alpha_composite(c.img(SC), (x, oy + 20 + y))
        d.text((x, oy + 20 + y + c.h * SC + 2), k.split('/')[-1], fill=(150, 140, 160))
    oy += h + 30
im.save(sys.argv[1])
print(im.size)
