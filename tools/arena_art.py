"""Pixel art da arena: guardiões, lendários (com quadros de animação), cenário e projéteis.
Estilo: contorno escuro grosso, cores vivas e poses exageradas (Noitu Love 2),
com cenário sombrio e luz de tocha (Risk of Rain / Moon Hunters / Starbound)."""
import math
import random
from pix import Can

# ---------------------------------------------------------------------
# GUARDIÕES
# ---------------------------------------------------------------------


def minotauro(fr):
    c = Can(40, 38)
    bob = {'idle0': 0, 'idle1': 1, 'run0': -1, 'run1': 0, 'atk': 0, 'jump': -2}[fr]
    c.ox, c.oy = 3, 2 + bob
    # pernas
    if fr == 'run0':
        legs = [(9, 25, 2), (18, 25, -1)]
    elif fr == 'run1':
        legs = [(12, 25, -1), (16, 25, 2)]
    elif fr == 'jump':
        legs = [(10, 22, 0), (17, 22, 0)]
    else:
        legs = [(10, 25, 0), (17, 25, 0)]
    for lx, ly, dx in legs:
        c.rect(lx, ly, 5, 6, 'B'); c.rect(lx + dx, ly + 6, 5, 3, 'b')
        c.rect(lx + dx, ly + 9, 5, 2, 'K')
    # tanga
    c.rect(9, 23, 15, 4, 'r'); c.hl(9, 23, 23, 'Y'); c.rect(14, 27, 5, 3, 'r')
    # tronco largo
    c.ell(16, 18, 10, 7, 'B')
    c.ell(13, 16, 4, 3, 'n'); c.ell(20, 16, 4, 3, 'n')   # peitoral
    c.ell(16, 21, 4, 2.5, 'n'); c.hl(14, 18, 21, 'B')        # abdômen
    c.ell(8, 13, 4, 3, 'b'); c.ell(24, 13, 4, 3, 'b')      # ombros peludos
    c.px(6, 11, 'B'); c.px(9, 10, 'B'); c.px(23, 10, 'B'); c.px(26, 11, 'B')
    # braço de trás
    c.rect(4, 15, 4, 8, 'B'); c.rect(4, 22, 4, 3, 'n')
    # cabeça de touro
    c.ell(23, 7, 5, 5, 'B'); c.ell(29, 10, 3.5, 3, 'n'); c.hl(27, 31, 8, 'N')
    c.rect(21, 1, 5, 2, 'b')
    c.px(30, 9, 'k'); c.px(28, 9, 'k'); c.ring(29, 12, 1.2, 'Y')
    c.px(24, 6, 'R'); c.px(25, 6, 'q'); c.px(24, 7, 'r')
    # chifres
    for d in (0, 1):
        c.line(20, 3 + d, 16, 1 + d, 'w'); c.line(16, 1 + d, 15, -2 + d, 'w')
        c.line(26, 3 + d, 30, 1 + d, 'w'); c.line(30, 1 + d, 32, -2 + d, 'w')
    c.px(15, -2, 'S'); c.px(32, -2, 'S')
    # braço da frente + machado
    if fr == 'atk':
        c.rect(25, 14, 7, 4, 'B')
        c.line(28, 17, 37, 17, 'b'); c.line(28, 18, 37, 18, 'B')
        c.ell(36, 22, 3, 5, 'i'); c.ell(36, 22, 2, 4, 'I'); c.vl(34, 18, 26, 'e')
        c.px(38, 16, 'W')
    elif fr == 'jump':
        c.rect(25, 7, 4, 8, 'B')
        c.line(27, 6, 33, -1, 'b'); c.ell(33, 0, 4, 2, 'i')
    else:
        c.rect(25, 14, 4, 9, 'B'); c.rect(25, 22, 4, 3, 'n')
        c.vl(29, 4, 30, 'b'); c.vl(30, 5, 29, 'B')
        c.ell(32, 7, 3, 5, 'i'); c.ell(32, 7, 2, 4, 'I'); c.vl(30, 3, 11, 'e')
    return c.outline()


def lich(fr):
    c = Can(32, 38)
    bob = {'idle0': 0, 'idle1': -2, 'run0': -1, 'run1': 0, 'atk': 0, 'jump': -3}[fr]
    lean = 1 if fr.startswith('run') else 0
    c.ox, c.oy = 2, 3 + bob
    # manto em farrapos
    c.tri([(12 + lean, 9), (2, 31), (24, 31)], 'p')
    c.tri([(12 + lean, 11), (6, 31), (19, 31)], 'P')
    for x in range(3, 24, 4):
        c.tri([(x, 30), (x + 3, 30), (x + 1 + (1 if fr == 'idle1' else 0), 34)], 'p')
    c.rect(9 + lean, 13, 7, 8, 'K')
    for y in (14, 16, 18):
        c.hl(10 + lean, 14 + lean, y, 'w')
    c.vl(12 + lean, 13, 19, 'S')
    # caveira
    c.disc(12 + lean, 7, 5, 'w'); c.rect(9 + lean, 9, 7, 4, 'w')
    c.rect(9 + lean, 5, 3, 3, 'k'); c.rect(14 + lean, 5, 3, 3, 'k')
    c.px(10 + lean, 6, 'c'); c.px(15 + lean, 6, 'c'); c.px(10 + lean, 5, 'C'); c.px(15 + lean, 5, 'C')
    c.hl(10 + lean, 15 + lean, 11, 'k'); c.px(11 + lean, 12, 'w'); c.px(13 + lean, 12, 'w')
    # coroa
    for x in (8, 11, 14, 17):
        c.tri([(x + lean, 3), (x + 2 + lean, 3), (x + 1 + lean, -1)], 'Y')
    c.hl(8 + lean, 18 + lean, 3, 'y')
    c.px(13 + lean, 2, 'R')
    # mão e cajado
    if fr == 'atk':
        c.rect(17, 14, 6, 3, 'p'); c.rect(23, 14, 2, 3, 'w')
        c.disc(27, 15, 3, 'c'); c.disc(27, 15, 1.6, 'C'); c.px(27, 15, 'W')
        c.vl(20, 4, 30, 'B')
    else:
        c.rect(17 + lean, 14, 3, 6, 'p'); c.rect(19 + lean, 18, 2, 2, 'w')
        c.vl(21 + lean, 4, 31, 'B'); c.vl(22 + lean, 5, 30, 'b')
        c.disc(21 + lean, 3, 2.6, 'c'); c.disc(21 + lean, 3, 1.4, 'C')
    return c.outline('k')


def dragao(fr):
    c = Can(40, 32)
    bob = {'idle0': 0, 'idle1': 1, 'run0': -1, 'run1': 0, 'atk': 0, 'jump': -2}[fr]
    c.ox, c.oy = 2, 2 + bob
    # asa de trás
    if fr == 'jump':
        c.tri([(14, 12), (6, -2), (22, 6)], 'r'); c.line(14, 12, 6, -2, 'k')
    else:
        c.tri([(13, 12), (2, 5), (8, 16)], 'r'); c.line(13, 12, 2, 5, 'k')
    # cauda
    c.line(2, 22, 9, 18, 'R'); c.line(2, 23, 9, 19, 'R'); c.line(0, 20, 3, 23, 'R')
    c.tri([(0, 17), (2, 21), (-1, 22)], 'O')
    # corpo
    c.ell(16, 18, 9, 6, 'R')
    c.ell(17, 21, 6, 3, 'N')
    for x in (13, 16, 19):
        c.px(x, 21, 'n')
    # espinhos nas costas
    for x in (9, 12, 15, 18):
        c.tri([(x, 13), (x + 2, 13), (x + 1, 10)], 'O')
    # pernas
    if fr == 'run0':
        legs = [(9, 2), (13, -1), (19, 2), (23, -1)]
    elif fr == 'run1':
        legs = [(9, -1), (13, 2), (19, -1), (23, 2)]
    elif fr == 'jump':
        legs = [(10, -2), (14, -2), (20, -2), (23, -2)]
    else:
        legs = [(9, 0), (13, 0), (19, 0), (23, 0)]
    for lx, dx in legs:
        c.rect(lx, 22, 3, 5, 'r'); c.rect(lx + dx, 26, 3, 2, 'r'); c.px(lx + dx + 2, 27, 'w')
    # pescoço e cabeça
    c.rect(22, 9, 5, 9, 'R')
    c.rect(23, 4, 10, 7, 'R'); c.rect(31, 7, 4, 4, 'R')
    c.hl(31, 34, 10, 'N')
    c.px(29, 6, 'k'); c.px(29, 5, 'Y'); c.px(30, 5, 'Z')
    c.line(24, 4, 21, 0, 'w'); c.line(27, 4, 26, 0, 'w')
    c.px(34, 8, 'k')
    if fr == 'atk':
        c.rect(31, 11, 5, 2, 'x'); c.hl(31, 35, 13, 'R')
        c.px(32, 11, 'w'); c.px(34, 11, 'w')
        c.tri([(36, 9), (39, 6), (39, 13)], 'O'); c.px(38, 9, 'Z')
    # asa da frente
    if fr == 'jump':
        c.tri([(18, 12), (16, -3), (30, 2)], 'q'); c.line(18, 12, 16, -3, 'r'); c.line(18, 12, 23, -1, 'r')
    else:
        c.tri([(16, 12), (8, 1), (24, 4)], 'q'); c.line(16, 12, 8, 1, 'r'); c.line(16, 12, 16, 2, 'r')
    return c.outline()


# ---------------------------------------------------------------------
# LENDÁRIOS
# ---------------------------------------------------------------------


def lyra(fr):
    c = Can(44, 40)
    c.ox, c.oy = 8, 3
    crouch = 2 if fr == 'tele' else 0
    bob = 1 if fr == 'idle1' else 0
    y0 = crouch + bob
    # capa esvoaçante
    if fr == 'atk':
        c.tri([(10, 9 + y0), (-6, 14 + y0), (0, 26 + y0)], 'r')
    else:
        c.tri([(10, 9 + y0), (2, 32), (12, 32)], 'r')
        c.tri([(9, 10 + y0), (4, 30), (9, 30)], 'R')
    # pernas
    if fr == 'atk':
        c.rect(8, 23, 4, 7, 'u'); c.rect(4, 30, 5, 3, 'K')
        c.rect(15, 23, 4, 6, 'u'); c.rect(18, 27, 4, 3, 'u'); c.rect(20, 30, 5, 3, 'K')
    else:
        c.rect(10, 23 + y0, 4, 8 - y0, 'u'); c.rect(16, 23 + y0, 4, 8 - y0, 'u')
        c.rect(9, 31, 5, 2, 'K'); c.rect(16, 31, 5, 2, 'K')
    # tronco com armadura
    c.rect(9, 12 + y0, 12, 11, 'i'); c.rect(10, 13 + y0, 10, 4, 'I')
    c.hl(9, 20, 21 + y0, 'R'); c.rect(13, 17 + y0, 4, 4, 'R')
    c.rect(7, 11 + y0, 5, 4, 'R'); c.rect(18, 11 + y0, 5, 4, 'R')
    # cabeça
    c.rect(12, 3 + y0, 8, 8, 'm'); c.px(18, 6 + y0, 'k'); c.px(16, 6 + y0, 'k'); c.px(19, 9 + y0, 'M')
    c.rect(11, 1 + y0, 10, 4, 'R'); c.vl(11, 1 + y0, 9 + y0, 'R')
    c.px(18, 5 + y0, 'R')
    # rabo de cavalo
    tail_dx = -6 if fr == 'atk' else -3
    c.line(11, 3 + y0, 11 + tail_dx, 8 + y0, 'R'); c.line(11, 4 + y0, 10 + tail_dx, 10 + y0, 'r')
    # braço e espada
    if fr == 'atk':
        c.rect(20, 14, 8, 3, 'i'); c.rect(27, 14, 2, 3, 'm')
        c.hl(29, 35, 14, 'y'); c.vl(30, 12, 18, 'Y')
        c.rect(31, 14, 13, 2, 'I'); c.hl(31, 43, 14, 'W')
        for i in range(3):
            c.px(34 + i * 3, 11 - i, 'q')
    elif fr == 'tele':
        c.rect(5, 14 + y0, 6, 3, 'i')
        c.line(5, 16 + y0, -6, 10 + y0, 'I'); c.line(5, 17 + y0, -6, 11 + y0, 'i')
        c.px(-6, 9 + y0, 'W'); c.px(-5, 8 + y0, 'Z')
        c.vl(6, 13 + y0, 19 + y0, 'Y')
    else:
        c.rect(20, 13 + y0, 3, 7, 'i'); c.rect(20, 19 + y0, 3, 2, 'm')
        c.line(22, 21 + y0, 32, 31, 'I'); c.line(23, 21 + y0, 33, 31, 'i'); c.hl(20, 24, 20 + y0, 'Y')
    return c.outline()


def borin(fr):
    c = Can(48, 48)
    c.ox, c.oy = 6, 8
    y0 = 1 if fr == 'idle1' else 0
    # pernas curtas e largas
    c.rect(8, 28, 7, 8, 'e'); c.rect(19, 28, 7, 8, 'e')
    c.rect(7, 35, 9, 3, 'b'); c.rect(18, 35, 10, 3, 'b')
    # corpo
    c.ell(17, 21 + y0, 13, 10, 'S')
    c.rect(6, 25 + y0, 22, 4, 'B'); c.hl(6, 27, 25 + y0, 'n'); c.rect(15, 25 + y0, 4, 4, 'Y')
    for x, y in ((9, 16), (25, 16), (9, 22), (25, 22)):
        c.px(x, y + y0, 'I')
    # braço de trás
    c.rect(2, 17 + y0, 5, 9, 'S'); c.rect(2, 25 + y0, 5, 3, 'm')
    # cabeça + barba
    c.rect(13, 6 + y0, 11, 9, 'm'); c.px(21, 9 + y0, 'k'); c.px(18, 9 + y0, 'k')
    c.hl(17, 22, 8 + y0, 'b')
    c.tri([(11, 11 + y0), (26, 11 + y0), (18, 26 + y0)], 'B')
    c.tri([(14, 13 + y0), (23, 13 + y0), (18, 22 + y0)], 'n')
    c.rect(17, 12 + y0, 4, 2, 'r')
    # elmo com chifres
    c.rect(12, 2 + y0, 13, 6, 'i'); c.hl(12, 24, 2 + y0, 'I'); c.hl(12, 24, 7 + y0, 'e')
    c.line(12, 5 + y0, 7, 0 + y0, 'w'); c.line(7, 0 + y0, 6, -4 + y0, 'w')
    c.line(25, 5 + y0, 30, 0 + y0, 'w'); c.line(30, 0 + y0, 31, -4 + y0, 'w')
    # braço da frente + martelo
    if fr == 'tele':
        c.rect(25, 4, 5, 13, 'S')
        c.vl(28, -8, 6, 'B'); c.vl(29, -8, 6, 'b')
        c.rect(21, -8, 16, 9, 'i'); c.rect(22, -7, 14, 7, 'I'); c.hl(21, 36, 0, 'e')
        c.px(36, -8, 'W')
    elif fr == 'atk':
        c.rect(25, 18, 9, 5, 'S')
        c.line(32, 22, 38, 30, 'B'); c.line(33, 22, 39, 30, 'b')
        c.rect(32, 29, 12, 9, 'i'); c.rect(33, 30, 10, 7, 'I'); c.hl(32, 43, 37, 'e')
        for x in (29, 34, 40):
            c.px(x, 39, 'S'); c.px(x + 1, 38, 's')
    else:
        c.rect(26, 15 + y0, 5, 10, 'S'); c.rect(26, 24 + y0, 5, 3, 'm')
        c.line(30, 26 + y0, 37, 4, 'B'); c.line(31, 26 + y0, 38, 4, 'b')
        c.rect(32, -2, 12, 8, 'i'); c.rect(33, -1, 10, 6, 'I'); c.hl(32, 43, 5, 'e')
    return c.outline()


def seraphine(fr):
    c = Can(40, 46)
    bob = {'idle0': 0, 'idle1': -2, 'tele': -1, 'atk': 0}[fr]
    c.ox, c.oy = 6, 6 + bob
    # asas
    span = 4 if fr in ('tele', 'atk') else 0
    c.tri([(10, 14), (-4 - span, 4), (2, 22)], 'C'); c.tri([(10, 15), (-1 - span, 8), (4, 20)], 'W')
    c.tri([(18, 14), (30 + span, 6), (24, 22)], 'C'); c.tri([(18, 15), (27 + span, 9), (22, 20)], 'W')
    # vestido longo
    c.tri([(14, 10), (2, 38), (26, 38)], 'w')
    c.tri([(14, 14), (8, 38), (20, 38)], 'W')
    c.hl(4, 24, 37, 'Y'); c.hl(5, 23, 36, 'y')
    c.rect(10, 12, 8, 8, 'w'); c.hl(10, 17, 19, 'Y')
    # cabeça + cabelo dourado
    c.rect(10, 3, 8, 8, 'm'); c.px(16, 6, 'k'); c.px(14, 6, 'k'); c.px(15, 8, 'q')
    c.rect(9, 1, 10, 4, 'Y'); c.vl(9, 1, 13, 'Y'); c.vl(10, 4, 11, 'y'); c.vl(18, 3, 7, 'Y')
    # auréola
    c.ell(14, -2, 6, 1.6, 'Z'); c.ell(14, -2, 4, 0.6, None if False else 'Z')
    # cajado do sol
    if fr == 'tele':
        c.rect(18, 4, 3, 8, 'w')
        c.vl(20, -10, 22, 'y'); c.disc(20, -10, 4, 'Z'); c.disc(20, -10, 2, 'W')
        for a in range(8):
            ang = a / 8 * math.tau
            c.px(20 + math.cos(ang) * 6, -10 + math.sin(ang) * 6, 'Y')
    elif fr == 'atk':
        c.rect(18, 13, 8, 3, 'w'); c.rect(26, 13, 2, 3, 'm')
        c.disc(31, 14, 3, 'Z'); c.disc(31, 14, 1.5, 'W')
        c.vl(6, 6, 38, 'y'); c.disc(6, 5, 2, 'Z')
    else:
        c.rect(18, 13, 3, 7, 'w'); c.rect(18, 19, 3, 2, 'm')
        c.vl(22, 0, 38, 'y'); c.disc(22, -1, 3, 'Z'); c.disc(22, -1, 1.4, 'W')
    return c.outline()


# ---------------------------------------------------------------------
# CENÁRIO DA ARENA (360×240, desenhado ×2 no jogo)
# ---------------------------------------------------------------------


def arena_bg():
    r = random.Random(7)
    c = Can(360, 240)
    c.auto_cel = False
    FY = 218
    c.rect(0, 0, 360, 240, 'k')
    # parede de tijolos com variação
    for row in range(0, FY // 7 + 1):
        y = row * 7
        x = -(row % 2) * 6
        while x < 360:
            w = r.choice([11, 12, 13])
            col = r.choice(['K', 'K', 'K', 'd'])
            c.rect(x + 1, y + 1, w - 1, 6, col)
            c.hl(x + 1, x + w - 1, y + 1, 'd' if col == 'K' else 'D')
            if r.random() < .06:
                c.px(x + r.randint(2, w - 2), y + r.randint(2, 5), 'g')
            x += w
    # pilares
    for px in (88, 262):
        c.rect(px, 0, 10, FY, 'D'); c.vl(px, 0, FY, 's'); c.vl(px + 9, 0, FY, 'd')
        for y in range(0, FY, 18):
            c.hl(px, px + 9, y, 'd')
        c.rect(px - 2, FY - 8, 14, 8, 's'); c.hl(px - 2, px + 11, FY - 8, 'S')
        c.rect(px - 2, 0, 14, 6, 's')
    # estandartes
    for bx, col, sh in ((60, 'r', 'R'), (292, 'p', 'P')):
        c.rect(bx, 20, 14, 40, col); c.vl(bx + 1, 20, 59, sh)
        c.tri([(bx, 60), (bx + 14, 60), (bx + 7, 68)], col)
        c.ring(bx + 7, 36, 4, 'Y'); c.px(bx + 7, 34, 'Y'); c.px(bx + 8, 36, 'Y')
        c.hl(bx - 2, bx + 15, 19, 'B')
    # relógio gigante (a vida do guardião)
    cx, cy = 180, 70
    c.disc(cx, cy, 49, 'k'); c.disc(cx, cy, 47, 'y'); c.disc(cx, cy, 45, 'b'); c.disc(cx, cy, 42, (34, 24, 30))
    for i in range(60):
        a = i / 60 * math.tau
        rr = 38 if i % 5 else 34
        for t in range(rr, 41):
            c.px(cx + math.cos(a) * t, cy + math.sin(a) * t, 'Y' if i % 15 == 0 else ('y' if i % 5 == 0 else 'b'))
    for i in range(8):
        a = i / 8 * math.tau
        c.disc(cx + math.cos(a) * 47, cy + math.sin(a) * 47, 2.5, 'y')
    c.disc(cx, cy, 4, 'Y')
    # suportes das tochas
    for tx in (43, 317):
        c.rect(tx - 3, 98, 7, 3, 'e'); c.vl(tx, 101, 108, 'e'); c.rect(tx - 4, 94, 9, 4, 'i')
    # chão
    c.rect(0, FY, 360, 22, 'K')
    x = 0
    while x < 360:
        w = r.choice([18, 20, 22])
        c.rect(x + 1, FY + 1, w - 1, 9, 'd'); c.hl(x + 1, x + w - 1, FY + 1, 'D')
        c.rect(x + 1 + w // 2, FY + 11, w - 1, 10, 'd'); c.hl(x + 1 + w // 2, x + w + w // 2 - 1, FY + 11, 'D')
        x += w
    c.hl(0, 359, FY, 'y'); c.hl(0, 359, FY - 1, 'b')
    # paredes laterais
    c.rect(0, 0, 9, 240, 'x'); c.rect(351, 0, 9, 240, 'x')
    c.vl(9, 0, 239, 'd'); c.vl(350, 0, 239, 'd')
    # ossos no chão
    for bx in (40, 140, 230, 330):
        c.line(bx, FY + 5, bx + 5, FY + 3, 'S')
    return c


def plat():
    c = Can(66, 7)
    c.auto_cel = False
    c.rect(0, 0, 66, 7, 'k'); c.rect(1, 1, 64, 5, 'D'); c.hl(1, 64, 1, 'S'); c.hl(1, 64, 5, 'd')
    for x in range(8, 64, 14):
        c.vl(x, 1, 5, 'd')
    c.px(3, 6, 'k'); c.px(62, 6, 'k')
    return c


def flame(f):
    c = Can(10, 14)
    c.auto_cel = False
    sway = [0, 1, -1][f]
    c.tri([(5 + sway, 0), (1, 11), (9, 11)], 'o')
    c.tri([(5 - sway, 3), (2, 11), (8, 11)], 'O')
    c.tri([(5, 6), (3, 11), (7, 11)], 'Y')
    c.ell(5, 11, 3, 2, 'O'); c.px(5, 10, 'Z')
    return c


# ---------------------------------------------------------------------
# PROJÉTEIS E EFEITOS
# ---------------------------------------------------------------------


def fx_bone():
    c = Can(10, 5)
    c.hl(2, 7, 2, 'w'); c.px(1, 1, 'w'); c.px(1, 3, 'w'); c.px(8, 1, 'w'); c.px(8, 3, 'w'); c.px(9, 2, 'C')
    return c.outline()


def fx_orb():
    c = Can(11, 11)
    c.auto_cel = False
    c.disc(5, 5, 5, 'Y'); c.disc(5, 5, 3.6, 'Z'); c.disc(4, 4, 1.5, 'W')
    return c


def fx_rock():
    c = Can(18, 18)
    c.disc(9, 9, 7.5, 's'); c.disc(8, 8, 5, 'S'); c.px(11, 11, 'D'); c.px(6, 12, 'D'); c.line(7, 5, 10, 8, 'D')
    return c.outline()


def fx_wave(col, light):
    c = Can(16, 16)
    c.tri([(0, 15), (15, 15), (9, 0)], col)
    c.tri([(4, 15), (13, 15), (9, 4)], light)
    return c.outline()


def fx_bonewall():
    c = Can(14, 50)
    c.auto_cel = False
    for y in range(0, 50, 7):
        c.rect(1, y, 12, 6, 'w'); c.hl(1, 12, y, 'W'); c.hl(1, 12, y + 5, 'S')
        c.px(4, y + 2, 'k'); c.px(9, y + 2, 'k')
    for y in range(0, 50, 2):
        c.px(0, y, 'k'); c.px(13, y, 'k')
    return c


def fx_shard():
    c = Can(8, 8)
    c.line(0, 4, 6, 4, 'C'); c.line(1, 3, 6, 3, 'w'); c.px(7, 4, 'W')
    return c.outline('t')


def build(save):
    save('bg/arena', arena_bg())
    save('arena/plat', plat())
    for i in range(3):
        save('arena/flame_%d' % i, flame(i))
    save('fx/bone', fx_bone())
    save('fx/shard', fx_shard())
    save('fx/orb', fx_orb())
    save('fx/rock', fx_rock())
    save('fx/wave_red', fx_wave('R', 'q'))
    save('fx/wave_dust', fx_wave('n', 'N'))
    save('fx/bonewall', fx_bonewall())
