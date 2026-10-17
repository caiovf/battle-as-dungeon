"""Efeitos dos lendários novos e das classes do guardião (projéteis, invocações, armadilhas)."""
import math
from pix import Can


def arrow(down=False):
    c = Can(16, 5)
    c.hl(1, 11, 2, 'B'); c.tri([(11, 0), (15, 2), (11, 4)], 'I')
    c.px(0, 1, 'W'); c.px(1, 0, 'W'); c.px(0, 3, 'W'); c.px(1, 4, 'W'); c.px(2, 1, 'C'); c.px(2, 3, 'C')
    c = c.outline()
    if down:   # gira 90° (ponta para baixo)
        r = Can(c.h, c.w)
        for y in range(c.h):
            for x in range(c.w):
                r.p[x][c.h - 1 - y] = c.p[y][x]
        c = r
    return c


def shuriken():
    c = Can(11, 11)
    for a in range(4):
        ang = a * math.pi / 2
        x2, y2 = 5 + math.cos(ang) * 5, 5 + math.sin(ang) * 5
        x3, y3 = 5 + math.cos(ang + 0.7) * 2, 5 + math.sin(ang + 0.7) * 2
        c.tri([(5, 5), (x2, y2), (x3, y3)], 'I')
    c.disc(5, 5, 1.6, 'e'); c.px(5, 5, 'k')
    return c.outline()


def shield():
    c = Can(14, 14)
    c.disc(7, 7, 6.5, 'U'); c.ring(7, 7, 6, 'Y'); c.disc(7, 7, 2.5, 'Y'); c.px(6, 6, 'Z')
    return c.outline()


def crescent():
    c = Can(16, 16)
    c.disc(8, 8, 7, 'v'); c.disc(11, 6, 6, None)
    c.px(4, 6, 'W'); c.px(5, 11, 'W')
    return c.outline('p')


def orb(a, b, cc):
    c = Can(11, 11)
    c.auto_cel = False
    c.disc(5, 5, 5, a); c.disc(5, 5, 3.6, b); c.disc(4, 4, 1.5, cc)
    return c


def drop(col, light):
    c = Can(8, 11)
    c.tri([(4, 0), (1, 7), (7, 7)], col); c.disc(4, 7, 3, col); c.px(3, 6, light); c.px(3, 7, light)
    return c.outline()


def meteor():
    c = Can(16, 20)
    c.tri([(3, 0), (12, 0), (8, 12)], 'o'); c.tri([(5, 0), (10, 0), (8, 10)], 'O')
    c.disc(8, 14, 5, 'r'); c.disc(8, 14, 3.5, 'o'); c.disc(7, 13, 1.6, 'Z')
    return c.outline()


def star():
    c = Can(13, 13)
    pts = []
    for i in range(10):
        r = 6 if i % 2 == 0 else 2.6
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((6 + math.cos(a) * r, 6.5 + math.sin(a) * r))
    for i in range(10):
        c.tri([(6, 6.5), pts[i], pts[(i + 1) % 10]], 'Y')
    c.px(6, 6, 'W'); c.px(5, 5, 'Z')
    return c.outline()


def moonshard():
    c = Can(7, 12)
    c.tri([(3, 0), (0, 6), (6, 6)], 'v'); c.tri([(0, 6), (6, 6), (3, 11)], 'P'); c.vl(3, 1, 8, 'W')
    return c.outline()


def bottle():
    c = Can(9, 12)
    c.rect(3, 0, 3, 2, 'b'); c.rect(3, 2, 3, 2, 'C'); c.disc(4, 7.5, 3.6, 'C'); c.disc(4, 8.5, 2.8, 'O'); c.px(3, 6, 'W')
    return c.outline()


def skull():
    c = Can(10, 10)
    c.disc(5, 4, 4, 'w'); c.rect(3, 7, 5, 2, 'w'); c.px(3, 4, 'k'); c.px(4, 4, 'k'); c.px(6, 4, 'k'); c.px(7, 4, 'k')
    c.px(5, 6, 'k'); c.px(4, 8, 'S'); c.px(6, 8, 'S')
    return c.outline('p')


def clockhand():
    c = Can(14, 5)
    c.hl(0, 9, 2, 'Y'); c.tri([(9, 0), (13, 2), (9, 4)], 'Z'); c.disc(1.5, 2, 1.5, 'y')
    return c.outline()


def wolf(f):
    c = Can(24, 15)
    c.auto_cel = False
    col, li = 'v', 'W'
    c.ell(11, 7, 7, 3.5, col)                       # corpo
    c.ell(19, 5, 3.5, 3, col); c.tri([(21, 6), (24, 7), (21, 8)], col)   # cabeça/focinho
    c.tri([(17, 3), (18, 0), (20, 3)], col)         # orelha
    c.px(20, 4, 'k')
    c.tri([(4, 6), (0, 3 + f * 2), (4, 8)], col)    # cauda
    legs = [(6, 2), (9, -1), (14, 2), (17, -1)] if f == 0 else [(6, -1), (9, 2), (14, -1), (17, 2)]
    for lx, dx in legs:
        c.line(lx, 9, lx + dx, 13, col)
    c.hl(7, 15, 5, li)
    return c.outline('p')


def bull(f):
    c = Can(32, 22)
    c.auto_cel = False
    col = 'O'
    c.ell(14, 11, 10, 5.5, col); c.ell(25, 9, 5, 4.5, col)
    c.line(23, 6, 20, 3, 'Z'); c.px(20, 2, 'Z'); c.line(27, 6, 30, 3, 'Z'); c.px(30, 2, 'Z')
    c.px(27, 8, 'r')
    legs = [(7, 3), (11, -2), (18, 3), (21, -2)] if f == 0 else [(7, -2), (11, 3), (18, -2), (21, 3)]
    for lx, dx in legs:
        c.line(lx, 15, lx + dx, 21, col); c.line(lx + 1, 15, lx + dx + 1, 21, col)
    c.hl(8, 20, 7, 'Z')
    return c.outline('o')


def skeleton(f):
    c = Can(14, 20)
    c.disc(7, 3.5, 3.2, 'w'); c.px(6, 3, 'k'); c.px(8, 3, 'k')
    c.vl(7, 7, 13, 'w')
    for y in (8, 10, 12):
        c.hl(5, 9, y, 'w')
    c.line(7, 8, 3, 12 - f, 'w'); c.line(7, 8, 11, 11 + f, 'w'); c.line(11, 11 + f, 13, 6 + f, 'i')
    c.line(7, 13, 4 + f, 19, 'w'); c.line(7, 13, 10 - f, 19, 'w')
    return c.outline('p')


def beartrap(closed):
    c = Can(18, 9)
    c.rect(1, 6, 16, 2, 'e')
    if closed:
        for x in range(3, 16, 3):
            c.tri([(x - 1, 6), (x + 1, 6), (x, 1)], 'I')
        c.hl(2, 15, 3, 'i')
    else:
        for x in range(2, 17, 3):
            c.tri([(x - 1, 6), (x + 1, 6), (x - 2, 2)], 'I'); c.tri([(x - 1, 6), (x + 1, 6), (x + 3, 2)], 'i')
    c.disc(9, 6, 1.6, 'R')
    return c.outline()


def ice_spear():
    c = Can(28, 7)
    c.tri([(0, 3), (20, 0), (20, 6)], 'c'); c.tri([(20, 0), (27, 3), (20, 6)], 'C'); c.hl(2, 24, 3, 'W')
    return c.outline('t')


def stinger():
    c = Can(14, 7)
    c.tri([(0, 1), (10, 3), (0, 5)], 'G'); c.tri([(9, 1), (13, 3), (9, 5)], 'l'); c.px(12, 3, 'W')
    return c.outline('g')


def spear_proj():
    c = Can(30, 5)
    c.hl(0, 22, 2, 'B'); c.tri([(21, 0), (29, 2), (21, 4)], 'Y'); c.px(26, 2, 'Z')
    return c.outline()


def build(save):
    import arena_art
    save('fx/wave_fire', arena_art.fx_wave('o', 'Z'))
    save('fx/arrow', arrow())
    save('fx/arrow_down', arrow(True))
    save('fx/shuriken', shuriken())
    save('fx/shield', shield())
    save('fx/crescent', crescent())
    save('fx/orb_green', orb('G', 'l', 'W'))
    save('fx/orb_fire', orb('o', 'O', 'Z'))
    save('fx/orb_ice', orb('T', 'c', 'W'))
    save('fx/orb_storm', orb('U', 'c', 'Z'))
    save('fx/drop_acid', drop('G', 'l'))
    save('fx/meteor', meteor())
    save('fx/star', star())
    save('fx/moonshard', moonshard())
    save('fx/bottle', bottle())
    save('fx/skull', skull())
    save('fx/clockhand', clockhand())
    save('fx/ice_spear', ice_spear())
    save('fx/stinger', stinger())
    save('fx/spear', spear_proj())
    for f in range(2):
        save('fx/wolf_%d' % f, wolf(f))
        save('fx/bull_%d' % f, bull(f))
        save('fx/skel_%d' % f, skeleton(f))
    save('fx/beartrap_0', beartrap(False))
    save('fx/beartrap_1', beartrap(True))
