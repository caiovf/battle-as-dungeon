"""Gera toda a pixel art da Masmorra Relógio em res://art/.
Rode:  python3 tools/gen_art.py   (precisa de Pillow)
Cada sprite é desenhado aqui em código; mude e rode de novo para atualizar."""
import os
import random
import sys
sys.path.insert(0, os.path.dirname(__file__))
from pix import Can, grid, PAL  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), '..', 'art')
OUT = {}


def save(name, c):
    OUT[name] = c
    path = os.path.join(ROOT, name + '.png')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    c.save(path)


# =====================================================================
# TILES 20×20
# =====================================================================
# Chão do corredor: pedra clara e quente (iluminada por tochas), bem diferente das paredes frias e escuras.
FLOOR = {'mortar': (92, 64, 50), 'a': (176, 146, 108), 'b': (158, 128, 94), 'hi': (212, 184, 140), 'lo': (122, 94, 70), 'crack': (110, 82, 62)}
GUARD = {'mortar': (66, 40, 34), 'a': (110, 68, 46), 'b': (96, 58, 40), 'hi': (160, 106, 66), 'lo': (70, 44, 32), 'crack': (60, 36, 28)}


def floor_tile(seed, pal=FLOOR):
    r = random.Random(seed)
    c = Can(20, 20)
    c.auto_cel = False
    c.rect(0, 0, 20, 20, pal['mortar'])
    rows = [(0, 9), (10, 10)]
    for ri, (y, h) in enumerate(rows):
        x = -r.randint(3, 8) if ri == 1 else 0
        while x < 20:
            w = r.randint(7, 11)
            base = r.choice([pal['a'], pal['a'], pal['b']])
            c.rect(x + 1, y + 1, w - 1, h - 1, base)
            c.hl(x + 1, x + w - 2, y + 1, pal['hi'])
            c.vl(x + 1, y + 1, y + h - 2, pal['hi'])
            c.hl(x + 1, x + w - 1, y + h - 1, pal['lo'])
            if r.random() < .5:
                px, py = x + r.randint(2, max(2, w - 3)), y + r.randint(2, h - 3)
                c.px(px, py, pal['crack'])
                if r.random() < .5:
                    c.px(px + 1, py + 1, pal['crack'])
            x += w
    return c


def wall_tile(seed):
    r = random.Random(seed + 100)
    c = Can(20, 20)
    c.rect(0, 0, 20, 20, 'k')
    for row in range(4):
        y = row * 5
        off = -4 if row % 2 else 0
        x = off
        while x < 20:
            w = r.choice([7, 8, 9])
            col = r.choice(['K', 'K', 'K', 'K', 'd'])
            c.rect(x + 1, y + 1, w - 1, 4, col)
            c.hl(x + 1, x + w - 1, y + 1, 'd' if col == 'K' else 's')
            c.hl(x + 1, x + w - 1, y + 4, 'k' if col == 'K' else 'K')
            x += w
    if r.random() < .2:  # musgo
        for _ in range(r.randint(2, 4)):
            c.px(r.randint(0, 19), r.randint(12, 19), r.choice(['g', 'g', 'G']))
    if r.random() < .25:  # rachadura
        x, y = r.randint(3, 16), r.randint(2, 8)
        for i in range(r.randint(3, 6)):
            c.px(x, y + i, 'k')
            x += r.choice([-1, 0, 1])
    return c


def deco(kind):
    c = Can(20, 20)
    if kind == 'ossos':
        c.line(4, 15, 11, 12, 'w')
        c.px(3, 15, 'w'); c.px(4, 16, 'w'); c.px(11, 11, 'w'); c.px(12, 12, 'w')
        c.disc(14, 14, 2.2, 'w'); c.px(13, 14, 'k'); c.px(15, 14, 'k'); c.hl(13, 15, 16, 'S')
    elif kind == 'teia':
        for a in range(0, 9):
            c.line(0, 0, a * 2, 9 - a, 'S')
        c.line(0, 4, 4, 0, 'w'); c.line(0, 8, 8, 0, 'S')
    elif kind == 'cogumelo':
        for x, y in ((5, 15), (9, 16), (13, 14)):
            c.vl(x, y, y + 2, 'w')
            c.hl(x - 1, x + 1, y - 1, 'c'); c.px(x, y - 2, 'C')
    elif kind == 'vela':
        c.rect(9, 12, 3, 5, 'w'); c.px(10, 11, 'k'); c.px(10, 10, 'O'); c.px(10, 9, 'Y')
        c.hl(8, 12, 17, 'S')
    elif kind == 'corrente':
        for y in range(0, 14, 2):
            c.px(15, y, 'i'); c.px(15, y + 1, 'e')
        c.ring(15, 15, 1.6, 'i')
    return c.outline() if kind != 'teia' else c


def guard_tile():
    c = floor_tile(77, GUARD)
    c.hl(0, 19, 0, 'y'); c.hl(0, 19, 19, 'y'); c.vl(0, 0, 19, 'y'); c.vl(19, 0, 19, 'y')
    for x, y in ((2, 2), (17, 2), (2, 17), (17, 17)):
        c.px(x, y, 'Y')
    return c


def heart_tile():
    c = Can(20, 20)
    c.disc(9.5, 9.5, 9, 'k')
    c.disc(9.5, 9.5, 8, 'y')
    c.disc(9.5, 9.5, 7, 'b')
    c.disc(9.5, 9.5, 6, 'K')
    for i in range(12):
        import math
        a = i / 12 * math.tau
        c.px(9.5 + math.cos(a) * 5, 9.5 + math.sin(a) * 5, 'Y' if i % 3 == 0 else 'y')
    # engrenagens nas laterais
    for x, y in ((1, 9), (18, 10), (9, 1), (10, 18)):
        c.px(x, y, 'Y')
    c.px(9, 9, 'Y'); c.px(10, 10, 'Y'); c.px(9, 10, 'y'); c.px(10, 9, 'y')
    return c


def entrance():
    c = Can(20, 20)
    c.rect(2, 0, 16, 20, 'x')
    c.rect(0, 0, 2, 20, 's'); c.rect(18, 0, 2, 20, 's')
    c.vl(1, 0, 19, 'S'); c.vl(18, 0, 19, 'D')
    for y in (4, 10, 16):
        c.hl(0, 1, y, 'D'); c.hl(18, 19, y, 'd')
    c.rect(2, 0, 16, 2, 'd')
    c.px(4, 6, 'R'); c.px(15, 6, 'R')  # olhos na escuridão
    return c


# =====================================================================
# ARMADILHAS 20×20
# =====================================================================
def trap_espinhos():
    c = Can(20, 20)
    c.rect(2, 13, 16, 4, 'e'); c.hl(2, 17, 13, 'i'); c.hl(2, 17, 16, 'K')
    for x in (3, 7, 11, 15):
        c.tri([(x, 13), (x + 1, 3 + (x % 4)), (x + 2, 13)], 'I')
        c.vl(x + 2, 6 + (x % 4), 12, 'i')
        c.px(x + 1, 3 + (x % 4), 'W')
    for x in (5, 9, 13):
        c.tri([(x, 13), (x + 1, 8), (x + 2, 13)], 'i')
    return c.outline()


def trap_besta():
    c = Can(20, 20)
    c.rect(3, 3, 14, 14, 'K'); c.rect(4, 4, 12, 12, 'd'); c.hl(4, 15, 4, 'D')
    for x, y in ((4, 4), (15, 4), (4, 15), (15, 15)):
        c.px(x, y, 'y')
    # arco
    c.line(4, 8, 9, 6, 'n'); c.line(10, 6, 15, 8, 'n')
    c.line(4, 8, 10, 13, 'w'); c.line(15, 8, 10, 13, 'w')
    c.vl(9, 6, 16, 'B'); c.vl(10, 6, 16, 'b')
    c.vl(9, 2, 6, 'I'); c.px(9, 1, 'W'); c.px(8, 3, 'I'); c.px(10, 3, 'I')
    return c.outline()


def trap_ampulheta():
    c = Can(20, 20)
    c.rect(4, 2, 12, 2, 'B'); c.rect(4, 16, 12, 2, 'B'); c.hl(4, 15, 2, 'n'); c.hl(4, 15, 16, 'n')
    c.vl(5, 4, 15, 'b'); c.vl(14, 4, 15, 'b')
    c.tri([(6, 4), (13, 4), (9.5, 10)], 'c')
    c.tri([(6, 15), (13, 15), (9.5, 9)], 'c')
    c.tri([(7, 5), (12, 5), (9.5, 8)], 'N')
    c.tri([(7, 15), (12, 15), (9.5, 12)], 'N')
    c.vl(9, 9, 12, 'N')
    c.px(7, 6, 'C'); c.px(7, 13, 'C')
    return c.outline()


def trap_fogo(f):
    c = Can(20, 20)
    c.rect(4, 12, 12, 3, 'e'); c.hl(4, 15, 12, 'i'); c.hl(5, 14, 15, 'K')
    c.vl(6, 15, 18, 'e'); c.vl(13, 15, 18, 'e'); c.hl(5, 14, 18, 'K')
    c.hl(5, 14, 11, 'r')
    flame = [(9.5, 1 + f), (5, 11), (14, 11)]
    c.tri(flame, 'o')
    c.tri([(9.5 + (1 if f else -1), 4 + f), (6.5, 11), (12.5, 11)], 'O')
    c.tri([(9.5, 7), (8, 11), (11, 11)], 'Y')
    c.px(9 + f, 9, 'Z')
    c.px(4 + 2 * f, 4, 'O'); c.px(14 - f, 2 + f, 'o')
    return c.outline()


def trap_ganancia():
    c = Can(20, 20)
    c.rect(3, 9, 14, 8, 'B'); c.rect(3, 6, 14, 4, 'b'); c.hl(3, 16, 6, 'n')
    c.hl(3, 16, 12, 'y'); c.vl(9, 6, 16, 'y'); c.vl(10, 6, 16, 'y')
    c.rect(9, 11, 2, 3, 'Y')
    for x, y in ((5, 5), (7, 4), (12, 5), (14, 4), (10, 3)):
        c.disc(x, y, 1.4, 'Y'); c.px(x, y - 1, 'Z')
    c.px(16, 1, 'Z'); c.px(16, 2, 'Y'); c.px(15, 2, 'Y'); c.px(17, 2, 'Y')
    return c.outline()


def trap_alcapao(open_):
    c = Can(20, 20)
    c.rect(2, 2, 16, 16, 'e'); c.rect(3, 3, 14, 14, 'x' if open_ else 'B')
    if not open_:
        for y in (3, 7, 11, 15):
            c.hl(3, 16, y, 'n')
            c.hl(3, 16, y + 3, 'b')
        c.rect(4, 6, 2, 2, 'i'); c.rect(14, 6, 2, 2, 'i'); c.rect(4, 13, 2, 2, 'i'); c.rect(14, 13, 2, 2, 'i')
        c.px(10, 10, 'Y')
    else:
        c.hl(3, 16, 3, 'K'); c.px(6, 9, 'R'); c.px(12, 9, 'R')
    c.hl(2, 17, 2, 'i')
    return c.outline()


def trap_runa():
    c = Can(20, 20)
    c.rect(3, 3, 14, 14, 'K'); c.rect(4, 4, 12, 12, 'd'); c.hl(4, 15, 4, 'D')
    c.ring(9.5, 9.5, 5, 'T')
    c.line(9, 5, 13, 9, 'c'); c.line(13, 10, 10, 14, 'c'); c.line(9, 14, 6, 10, 'c'); c.line(6, 9, 9, 5, 'c')
    c.vl(9, 6, 13, 'C'); c.vl(10, 6, 13, 'C')
    c.px(9, 4, 'W'); c.px(16, 9, 'c'); c.px(3, 10, 'c')
    return c.outline()


# =====================================================================
# MONSTROS (16×16, alguns 20×20)
# =====================================================================
def mon_esqueleto():
    c = grid([
        "................",
        ".....wwwwww.....",
        "....wwwwwwww....",
        "....wkkwwkkw....",
        "....wkRwwkRw....",
        "....wwwkkwww..I.",
        ".....wwwwww...I.",
        "......wkwk....I.",
        "....ww.ww.ww..I.",
        "...ww.wwww.wwyyy",
        "...w..w..w...wb.",
        "......wwww......",
        ".....ww..ww.....",
        ".....w....w.....",
        ".....w....w.....",
        "....ww....ww....",
    ])
    return c.outline()


def mon_ogro():
    c = Can(20, 20)
    c.ell(10, 12, 7, 6, 'G')          # corpo
    c.ell(10, 13, 5, 4, 'l')
    c.rect(5, 16, 4, 4, 'g'); c.rect(11, 16, 4, 4, 'g')
    c.ell(10, 5, 4, 3.5, 'G')         # cabeça
    c.px(8, 4, 'k'); c.px(11, 4, 'k'); c.px(8, 3, 'r'); c.px(11, 3, 'r')
    c.hl(8, 11, 7, 'g'); c.px(8, 6, 'w'); c.px(11, 6, 'w')
    c.rect(6, 10, 8, 2, 'b')          # cinto
    c.line(16, 3, 18, 13, 'B'); c.line(17, 3, 19, 12, 'n')  # clava
    c.disc(17, 3, 2, 'B'); c.px(16, 2, 'n')
    c.rect(2, 9, 2, 4, 'G')
    return c.outline()


def mon_morcego(f):
    c = Can(16, 16)
    c.ell(8, 8, 2.5, 3, 'p')
    c.px(7, 4, 'p'); c.px(9, 4, 'p')
    if f == 0:
        c.tri([(6, 7), (0, 3), (2, 11)], 'P'); c.tri([(10, 7), (15, 3), (13, 11)], 'P')
        c.px(1, 5, 'p'); c.px(14, 5, 'p')
    else:
        c.tri([(6, 7), (0, 12), (4, 13)], 'P'); c.tri([(10, 7), (15, 12), (11, 13)], 'P')
    c.px(7, 7, 'Y'); c.px(9, 7, 'Y'); c.px(8, 10, 'w')
    return c.outline()


def mon_gosma():
    c = Can(16, 16)
    c.ell(8, 11, 6.5, 4.5, 'G')
    c.ell(8, 10, 5, 3.5, 'l')
    c.disc(8, 6, 2, 'l')
    c.px(5, 8, 'W'); c.px(6, 8, 'W'); c.px(5, 9, 'W')
    c.px(6, 11, 'k'); c.px(10, 11, 'k'); c.px(6, 10, 'g'); c.px(10, 10, 'g')
    c.hl(4, 12, 15, 'g')
    return c.outline('k')


def mon_espectro():
    c = Can(16, 16)
    c.disc(8, 6, 5, 'C')
    c.rect(3, 6, 11, 6, 'C')
    for x in (3, 6, 9, 12):
        c.tri([(x, 11), (x + 2, 11), (x + 1, 15)], 'C')
    c.ell(8, 9, 4, 3, 'c')
    c.rect(5, 5, 2, 3, 'u'); c.rect(9, 5, 2, 3, 'u'); c.px(6, 5, 'C'); c.px(10, 5, 'C')
    c.hl(7, 8, 9, 'u')
    return c.outline('t')


def mon_aranha():
    c = Can(16, 16)
    for i, y in enumerate((7, 9, 11, 13)):
        c.line(5, 8 + i, 1, y - 3 + i * 2, 'p'); c.line(1, y - 3 + i * 2, 0, y + 1, 'p')
        c.line(10, 8 + i, 14, y - 3 + i * 2, 'p'); c.line(14, y - 3 + i * 2, 15, y + 1, 'p')
    c.ell(8, 10, 4.5, 4, 'P'); c.ell(8, 10, 2.5, 2.5, 'p')
    c.px(7, 9, 'R'); c.px(8, 10, 'R'); c.px(9, 9, 'R'); c.px(8, 8, 'R')
    c.disc(8, 5, 2.6, 'P')
    c.px(7, 4, 'Y'); c.px(9, 4, 'Y'); c.px(8, 5, 'Y')
    c.px(7, 7, 'w'); c.px(9, 7, 'w')
    return c.outline()


def mon_mimico(open_):
    c = Can(16, 16)
    if not open_:
        c.rect(1, 6, 14, 9, 'B'); c.rect(1, 3, 14, 4, 'b'); c.hl(1, 14, 3, 'n')
        c.hl(1, 14, 7, 'y'); c.rect(7, 6, 2, 3, 'Y'); c.vl(1, 3, 14, 'y'); c.vl(14, 3, 14, 'y')
        c.hl(2, 13, 14, 'b')
    else:
        c.rect(1, 9, 14, 6, 'B'); c.hl(1, 14, 9, 'y')
        c.rect(1, 1, 14, 4, 'b'); c.hl(1, 14, 1, 'n')
        c.rect(2, 5, 12, 4, 'x')
        for x in range(2, 14, 2):
            c.px(x, 5, 'w'); c.px(x + 1, 8, 'w')
        c.rect(5, 7, 6, 2, 'R'); c.px(6, 6, 'Y'); c.px(9, 6, 'Y')
    return c.outline()


def mon_vampiro():
    c = Can(16, 16)
    c.tri([(8, 4), (1, 15), (15, 15)], 'r')
    c.tri([(8, 6), (4, 15), (12, 15)], 'k')
    c.rect(6, 7, 4, 7, 'K'); c.vl(8, 8, 13, 'R')
    c.disc(8, 4, 2.6, 'w')
    c.tri([(5, 3), (11, 3), (8, 0)], 'k'); c.hl(5, 11, 2, 'k')
    c.px(7, 4, 'R'); c.px(9, 4, 'R'); c.px(8, 6, 'W')
    c.tri([(2, 5), (5, 3), (5, 7)], 'r'); c.tri([(14, 5), (11, 3), (11, 7)], 'r')
    return c.outline()


def mon_golem():
    c = Can(20, 20)
    c.rect(4, 6, 12, 10, 's'); c.rect(5, 7, 10, 8, 'S')
    c.rect(4, 6, 12, 1, 'S'); c.hl(4, 15, 15, 'D')
    c.rect(6, 1, 8, 6, 's'); c.hl(6, 13, 1, 'S')
    c.px(8, 3, 'O'); c.px(11, 3, 'O'); c.px(8, 4, 'o'); c.px(11, 4, 'o')
    c.rect(1, 7, 3, 8, 'D'); c.rect(16, 7, 3, 8, 'D'); c.rect(1, 14, 3, 3, 's'); c.rect(16, 14, 3, 3, 's')
    c.rect(5, 16, 4, 4, 'D'); c.rect(11, 16, 4, 4, 'D')
    c.line(7, 8, 10, 11, 'd'); c.line(10, 11, 9, 14, 'd')
    c.px(13, 9, 'g'); c.px(14, 9, 'G'); c.px(6, 12, 'g')
    c.disc(10, 10, 1, 'O')
    return c.outline()


# =====================================================================
# HERÓIS (16×16) — corpo base + roupas e itens por classe
# =====================================================================
def hero(armor, shade, cloth, skin='m', hair='h', pants='u', head=None, item=None, back=None, cape=None, fr='walk0'):
    c = Can(19, 20)
    c.oy = 3
    c.ox = 1
    # pose: andar em 4 tempos (contato, descida, passagem, subida) e ataque em 2 (preparo, golpe)
    legs = {'walk0': (-1, 1, 0), 'walk1': (0, 0, 1), 'walk2': (1, -1, 0), 'walk3': (0, 0, -1), 'atk0': (0, 0, 0), 'atk1': (1, 0, 0)}[fr]
    bob = legs[2] if fr.startswith('walk') else 0
    c.oy += bob
    if cape:
        c.rect(4 - (1 if fr.startswith('walk') and legs[0] else 0), 7, 3, 7, cape)
    if back:
        back(c)
    # pernas (deslocam no passo)
    c.rect(5 + legs[0], 12, 2, 3 - bob, pants); c.rect(9 + legs[1], 12, 2, 3 - bob, pants)
    c.rect(5 + legs[0], 15 - bob, 2, 1, 'b'); c.rect(9 + legs[1], 15 - bob, 3, 1, 'b')
    # tronco
    c.rect(4, 7, 8, 5, armor); c.vl(11, 7, 11, shade); c.hl(4, 11, 11, shade)
    c.hl(4, 11, 10, 'b')
    c.rect(3, 8, 1, 3, cloth); c.rect(12, 8, 1, 3, cloth)
    c.px(3, 11, skin); c.px(12, 11, skin)
    # cabeça (de lado, olhando para a direita)
    c.rect(5, 2, 6, 5, skin); c.px(10, 6, 'M' if skin == 'm' else skin)
    c.px(9, 4, 'k'); c.px(7, 4, 'k')
    c.rect(5, 1, 6, 2, hair); c.vl(5, 1, 4, hair)
    if head:
        head(c)
    if item:
        # preparo: item recolhido; golpe: item à frente com rastro frio (herói)
        dx, dy = {'atk0': (-2, -1), 'atk1': (2, 1)}.get(fr, (0, 0))
        c.ox += dx; c.oy += dy
        item(c)
        c.ox -= dx; c.oy -= dy
        if fr == 'atk1':
            for k in range(4):
                c.px(16 - k, 3 + k * 3, 'C')
    return c.outline()


def h_helmet(col='i', plume=None):
    def f(c):
        c.rect(4, 0, 8, 3, col); c.hl(4, 11, 0, 'I' if col == 'i' else col); c.vl(5, 3, 4, col)
        c.px(11, 3, col)
        if plume:
            c.vl(7, -1, 0, plume); c.px(8, 0, plume)
    return f


def h_hood(col, sh):
    def f(c):
        c.rect(4, 0, 8, 2, col); c.vl(4, 1, 6, col); c.vl(5, 2, 5, sh); c.px(11, 2, col)
        c.hl(5, 10, 2, sh)
    return f


def h_hat(col, band='y', wide=True):
    def f(c):
        c.rect(3 if wide else 4, 1, 10 if wide else 8, 1, col); c.rect(5, -1, 6, 2, col); c.hl(5, 10, 0, band)
    return f


def i_sword(c):
    c.vl(13, 3, 10, 'I'); c.vl(14, 4, 9, 'i'); c.hl(12, 15, 10, 'y'); c.px(13, 11, 'b')


def i_dagger(c):
    c.vl(13, 7, 10, 'I'); c.px(13, 11, 'b'); c.vl(2, 8, 10, 'I')


def i_shield(col, mark):
    def f(c):
        c.rect(11, 6, 5, 7, col); c.vl(15, 7, 11, 'k'); c.px(13, 8, mark); c.vl(13, 8, 11, mark); c.hl(12, 14, 9, mark)
    return f


def i_staff(col, gem):
    def f(c):
        c.vl(13, 2, 15, col); c.disc(13, 2, 1.2, gem); c.px(13, 1, 'W')
    return f


def i_bow(c):
    c.line(13, 3, 15, 7, 'n'); c.line(15, 8, 13, 13, 'n'); c.vl(13, 4, 12, 'w'); c.line(10, 9, 15, 9, 'I')


def i_torch(c):
    c.vl(13, 5, 12, 'B'); c.disc(13, 4, 1.5, 'o'); c.px(13, 2, 'Y'); c.px(13, 3, 'O')


def i_flask(c):
    c.disc(13, 10, 2, 'P'); c.px(13, 7, 'w'); c.vl(13, 7, 8, 'w'); c.px(12, 9, 'v')


def i_pick(c):
    c.vl(13, 4, 14, 'B'); c.line(10, 4, 15, 3, 'i'); c.px(10, 5, 'e'); c.px(15, 4, 'e')


def i_spear(c):
    c.vl(13, 1, 15, 'B'); c.tri([(12, 3), (14, 3), (13, 0)], 'I')


def i_lantern(c):
    c.vl(13, 6, 8, 'e'); c.rect(12, 9, 3, 3, 'Y'); c.px(13, 10, 'Z'); c.hl(12, 14, 12, 'e')


def i_book(c):
    c.rect(11, 8, 4, 4, 'r'); c.vl(11, 8, 11, 'y'); c.px(13, 9, 'Y')


def i_fireball(c):
    c.disc(13, 7, 2, 'o'); c.px(13, 6, 'Y'); c.px(14, 5, 'O')


def i_censer(c):
    c.vl(13, 5, 9, 'i'); c.disc(13, 11, 1.6, 'Y'); c.px(14, 13, 'C'); c.px(15, 12, 'C')


def i_stake(c):
    c.line(11, 11, 15, 5, 'B'); c.px(15, 4, 'w')


def i_map(c):
    c.rect(11, 8, 4, 3, 'N'); c.px(12, 9, 'R'); c.px(13, 9, 'b')


def i_tools(c):
    c.vl(13, 6, 11, 'i'); c.px(12, 6, 'i'); c.px(14, 6, 'i'); c.vl(2, 9, 11, 'e')


def b_pack(c):
    c.rect(1, 6, 4, 7, 'n'); c.hl(1, 4, 6, 'N'); c.px(2, 9, 'y')


HEROES = {
    'guerreiro': dict(armor='i', shade='e', cloth='u', head=h_helmet('i'), item=i_sword),
    'ladino': dict(armor='p', shade='K', cloth='p', pants='K', head=h_hood('P', 'p'), item=i_dagger),
    'paladino': dict(armor='Y', shade='y', cloth='w', head=h_helmet('Y', 'R'), item=i_shield('w', 'R')),
    'mercador': dict(armor='y', shade='b', cloth='B', head=h_hat('B', 'R'), back=b_pack, item=i_map),
    'acrobata': dict(armor='q', shade='r', cloth='q', hair='R', pants='r'),
    'escudeiro': dict(armor='U', shade='u', cloth='i', head=h_helmet('e'), item=i_shield('U', 'I')),
    'andarilho': dict(armor='T', shade='t', cloth='T', head=h_hood('T', 't'), item=i_staff('B', 'c'), cape='t'),
    'desarmador': dict(armor='B', shade='b', cloth='n', head=lambda c: (c.hl(5, 10, 3, 'o'), c.px(9, 3, 'C'), c.px(7, 3, 'C')), item=i_tools),
    'inquisidor': dict(armor='w', shade='S', cloth='w', head=lambda c: (c.rect(5, -2, 6, 4, 'w'), c.vl(8, -2, 1, 'R'), c.hl(7, 9, -1, 'R')), item=i_book, cape='R'),
    'batedor': dict(armor='n', shade='B', cloth='B', head=h_hood('B', 'b'), item=i_lantern),
    'piromante': dict(armor='o', shade='r', cloth='o', hair='R', head=h_hood('r', 'o'), item=i_fireball),
    'sacerdote': dict(armor='w', shade='N', cloth='w', hair='Y', head=lambda c: (c.ring(8, 0, 2.5, 'Y')), item=i_book),
    'cacador': dict(armor='r', shade='b', cloth='B', hair='B', head=h_hood('B', 'b'), item=i_spear, cape='b'),
    'arqueiro': dict(armor='G', shade='g', cloth='G', head=h_hood('G', 'g'), item=i_bow),
    'alquimista': dict(armor='P', shade='p', cloth='v', head=h_hat('p', 'v', False), item=i_flask),
    'exorcista': dict(armor='c', shade='T', cloth='C', hair='w', head=h_hood('C', 'c'), item=i_censer),
    'mineiro': dict(armor='n', shade='B', cloth='b', head=lambda c: (c.rect(4, 0, 8, 2, 'Y'), c.px(10, 1, 'Z'), c.px(11, 1, 'W')), item=i_pick),
    'tocheiro': dict(armor='O', shade='o', cloth='b', head=h_helmet('e'), item=i_torch),
    'cacatesouro': dict(armor='N', shade='n', cloth='B', head=h_hat('B', 'Y'), item=i_map, back=b_pack),
    'cacavampiro': dict(armor='e', shade='K', cloth='K', head=h_hat('K', 'R'), item=i_stake, cape='K'),
}


# Chefes e lendários no mapa (20×20)
def big_hero(armor, shade, cloth, skin='m', hair='h', pants='u', extra=None, cape=None, fr='walk0'):
    import rig
    c = Can(21, 27)
    _, _, bob, lean = rig.MAP_FR[fr]
    c.ox, c.oy = lean, 7 + bob
    if cape:
        c.rect(4, 8, 4, 10, cape)
    rig.map_legs(c, fr, pants)
    c.rect(5, 8, 10, 7, armor); c.vl(14, 8, 14, shade); c.hl(5, 14, 14, shade); c.hl(5, 14, 13, 'b')
    c.rect(3, 9, 2, 4, cloth); c.rect(15, 9, 2, 4, cloth)
    c.rect(6, 2, 8, 6, skin); c.px(12, 4, 'k'); c.px(9, 4, 'k'); c.px(13, 7, 'M')
    c.rect(6, 1, 8, 2, hair); c.vl(6, 1, 5, hair)
    if extra:
        extra(c)
    return c.outline()


BIG = {
    'campeao': dict(armor='R', shade='r', cloth='i', extra=lambda c: (c.rect(5, 0, 10, 3, 'i'), c.hl(5, 14, 0, 'I'), c.vl(9, -1, 0, 'R'), c.vl(17, 2, 15, 'I'), c.vl(18, 3, 14, 'i'), c.hl(16, 19, 13, 'y'))),
    'arquimago': dict(armor='P', shade='p', cloth='v', hair='w', extra=lambda c: (c.tri([(5, 3), (15, 3), (9, -6)], 'p'), c.hl(5, 15, 2, 'v'), c.rect(8, 7, 4, 3, 'w'), c.vl(17, 1, 19, 'B'), c.disc(17, 1, 1.6, 'v'))),
    'rei': dict(armor='Y', shade='y', cloth='R', extra=lambda c: (c.rect(6, -1, 8, 2, 'Y'), c.px(6, -2, 'Y'), c.px(9, -2, 'Y'), c.px(13, -2, 'Y'), c.px(9, -1, 'R'), c.rect(15, 7, 5, 8, 'w'), c.vl(17, 8, 13, 'R'), c.hl(16, 18, 10, 'R')), cape='R'),
    'lyra': dict(armor='R', shade='r', cloth='R', hair='R', extra=lambda c: (c.vl(6, 1, 9, 'R'), c.vl(5, 3, 10, 'R'), c.line(15, 13, 19, 2, 'I'), c.line(16, 13, 19, 4, 'i'), c.hl(14, 17, 12, 'Y')), cape='r'),
    'borin': dict(armor='S', shade='s', cloth='e', hair='B', extra=lambda c: (c.rect(7, 6, 6, 4, 'B'), c.hl(8, 11, 9, 'n'), c.vl(17, 4, 19, 'B'), c.rect(15, 1, 5, 4, 'i'), c.hl(15, 19, 1, 'I'))),
    'seraphine': dict(armor='w', shade='N', cloth='w', hair='Y', extra=lambda c: (c.ring(10, 0, 3, 'Y'), c.tri([(4, 19), (16, 19), (10, 9)], 'w'), c.vl(17, 2, 19, 'y'), c.disc(17, 2, 1.6, 'Z'))),
}


def build_map_sprites():
    for i in range(3):
        save('tiles/floor_%d' % i, floor_tile(i))
        save('tiles/wall_%d' % i, wall_tile(i))
    for k in ('ossos', 'teia', 'cogumelo', 'vela', 'corrente'):
        save('tiles/deco_' + k, deco(k))
    save('tiles/guard_floor', guard_tile())
    save('tiles/heart', heart_tile())
    save('tiles/entrance', entrance())
    save('traps/espinhos', trap_espinhos())
    save('traps/besta', trap_besta())
    save('traps/ampulheta', trap_ampulheta())
    save('traps/fogo_0', trap_fogo(0))
    save('traps/fogo_1', trap_fogo(1))
    save('traps/ganancia', trap_ganancia())
    save('traps/alcapao', trap_alcapao(False))
    save('traps/alcapao_aberto', trap_alcapao(True))
    save('traps/runa', trap_runa())
    save('mon/esqueleto', mon_esqueleto())
    save('mon/ogro', mon_ogro())
    save('mon/morcego_0', mon_morcego(0))
    save('mon/morcego_1', mon_morcego(1))
    save('mon/gosma', mon_gosma())
    save('mon/espectro', mon_espectro())
    save('mon/aranha', mon_aranha())
    save('mon/mimico', mon_mimico(False))
    save('mon/mimico_aberto', mon_mimico(True))
    save('mon/vampiro', mon_vampiro())
    save('mon/golem', mon_golem())
    for k, kw in HEROES.items():
        save('heroes/' + k, hero(**kw))
        for fr in ('walk0', 'walk1', 'walk2', 'walk3', 'atk0', 'atk1'):
            save('heroes/%s_%s' % (k, fr), hero(fr=fr, **kw))
    for k, kw in BIG.items():
        if k in ('lyra', 'borin', 'seraphine'):
            continue
        save('heroes/' + k, big_hero(**kw))
        for fr in ('walk0', 'walk1', 'walk2', 'walk3', 'atk0', 'atk1'):
            save('heroes/%s_%s' % (k, fr), big_hero(fr=fr, **kw))


# âncora x (centro do corpo) dos sprites da arena, em pixels do sprite
ANCHOR_X = {'minotauro': 24, 'lich': 19, 'dragao': 21}   # guardiões; lendários usam 34 (rig humanoide)


def write_meta():
    import json
    meta = {}
    for k, c in OUT.items():
        bottom = 0
        xs = []
        for y in range(c.h):
            for x in range(c.w):
                if c.p[y][x] is not None:
                    bottom = max(bottom, y + 1)
        base = k.split('/')[-1].split('_')[0]
        ax = c.w / 2.0
        if k.startswith('arena/'):
            ax = ANCHOR_X.get(base, 34 if c.w == 64 else c.w / 2.0)
        meta[k] = {'w': c.w, 'h': c.h, 'ax': ax, 'ay': bottom}
    with open(os.path.join(ROOT, 'meta.json'), 'w') as f:
        json.dump(meta, f, indent=0, sort_keys=True)


if __name__ == '__main__':
    build_map_sprites()
    import arena_art
    arena_art.build(save)
    import rig
    rig.build(save)
    import fx_art
    fx_art.build(save)
    import ui_icons
    ui_icons.build(save)
    write_meta()
    print(len(OUT), 'sprites')
