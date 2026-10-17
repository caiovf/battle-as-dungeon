import sys
from PIL import Image, ImageDraw
import rig
rows = []
keys = sys.argv[2].split(',')
for k in keys:
    if k in rig.GPAL:
        rows.append([(k, fr, rig.guard(k, fr)) for fr in rig.GUARD_FRAMES])
    else:
        rows.append([(k, fr, rig.legend(k, fr)) for fr in rig.LEG_FRAMES])
S = 3
W = max(sum(c.w * S + 6 for _, _, c in r) for r in rows) + 10
H = sum(max(c.h for _, _, c in r) * S + 18 for r in rows) + 10
im = Image.new('RGBA', (W, H), (36, 26, 46, 255)); d = ImageDraw.Draw(im)
y = 5
for r in rows:
    x = 5; h = max(c.h for _, _, c in r) * S
    for k, fr, c in r:
        im.alpha_composite(c.img(S), (x, y)); d.text((x, y + h + 2), fr, fill=(180, 170, 190)); x += c.w * S + 6
    y += h + 18
im.save(sys.argv[1])
