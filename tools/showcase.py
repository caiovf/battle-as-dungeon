"""Prancha de apresentação da arte (gera uma imagem PNG)."""
import glob, os, sys
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, os.path.dirname(__file__))
import gen_art, arena_art, rig, fx_art
gen_art.build_map_sprites(); arena_art.build(gen_art.save); rig.build(gen_art.save); fx_art.build(gen_art.save)
O = gen_art.OUT
FONT = glob.glob('/tmp/claude-0/*/*/scratchpad/fonts/x_fontsource-press-start-2p-*/package/files/press-start-2p-latin-400-normal.woff') + glob.glob(os.path.expanduser('~/*.woff'))
f_t = ImageFont.truetype(FONT[0], 20); f_s = ImageFont.truetype(FONT[0], 10); f_h = ImageFont.truetype(FONT[0], 28)
W = 1600
BG = (20, 12, 28); PANEL = (36, 26, 46); GOLD = (255, 196, 48); MUTE = (160, 150, 176)
sections = [
    ('MASMORRA', [k for k in O if k.startswith('tiles/')], 3),
    ('ARMADILHAS', [k for k in O if k.startswith('traps/')], 4),
    ('MONSTROS', [k for k in O if k.startswith('mon/')], 4),
    ('HERÓIS (ANDAR 4 + ATACAR 2)', [k for k in O if k.startswith('heroes/') and any(k.endswith(x) for x in ('_walk0', '_walk1', '_walk2', '_walk3', '_atk0', '_atk1')) and k.split('/')[1].split('_')[0] in ('guerreiro', 'arqueiro', 'paladino', 'piromante')], 3),
    ('LENDÁRIOS NO MAPA', [k for k in O if k.startswith('heroes/') and k.split('/')[1] in rig.LEGENDS], 3),
    ('CLASSES DO GUARDIÃO (PARADO · SMEAR · IMPACTO)', [k for k in sorted(O) if k.startswith('arena/') and k.split('/')[1].split('_')[0] in ('minotauro', 'lich', 'dragao') and k.split('_')[-1] in ('idle0', 'atk1', 'atk2')], 2),
    ('LENDÁRIOS NA ARENA (PARADO · AVISO · GOLPE)', [k for k in O if k.startswith('arena/') and k.split('/')[1].split('_')[0] in rig.LEGENDS and k.split('_')[-1] in ('idle0', 'tele', 'atk1')], 2),
    ('EFEITOS', [k for k in O if k.startswith('fx/') or 'flame' in k or 'plat' in k], 2),
]
blocks = []
for title, keys, sc in sections:
    x, y, rowh, items = 24, 54, 0, []
    for k in keys:
        c = O[k]; w, h = max(c.w * sc, len(k.split('/')[-1]) * 10 + 4), c.h * sc
        if x + w > W - 48:
            x = 24; y += rowh + 34; rowh = 0
        items.append((k, x, y)); x += w + 26; rowh = max(rowh, h)
    blocks.append((title, items, sc, y + rowh + 44))
bg = O['bg/arena'].img(2)
H = 120 + sum(b[3] + 20 for b in blocks) + bg.height + 90
im = Image.new('RGBA', (W, H), BG); d = ImageDraw.Draw(im)
d.text((24, 30), 'MASMORRA RELÓGIO · PIXEL ART', font=f_h, fill=GOLD)
d.text((24, 76), 'Risk of Rain · Moon Hunters · Starbound · Noitu Love 2', font=f_s, fill=MUTE)
oy = 120
for title, items, sc, h in blocks:
    d.rectangle((12, oy, W - 12, oy + h), fill=PANEL, outline=(78, 66, 90), width=3)
    d.text((28, oy + 18), title, font=f_t, fill=GOLD)
    for k, x, y in items:
        c = O[k]
        im.alpha_composite(c.img(sc), (x + 12, oy + y))
        d.text((x + 12, oy + y + c.h * sc + 6), k.split('/')[-1], font=f_s, fill=MUTE)
    oy += h + 20
d.text((28, oy + 10), 'ARENA DO GUARDIÃO (360×240, AMPLIADA 2×)', font=f_t, fill=GOLD)
im.alpha_composite(bg, ((W - bg.width) // 2, oy + 50))
for k, x in (('arena/minotauro_1_atk1', 230), ('arena/kael_tele', 500)):
    sp = O[k].img(2)
    m = __import__('json').load(open(os.path.join(gen_art.ROOT, 'meta.json')))[k]
    im.alpha_composite(sp, ((W - bg.width) // 2 + x - int(m['ax'] * 2), oy + 50 + 436 - m['ay'] * 2))
im.save(sys.argv[1]); print(im.size)
