"""Ícones 16×16 dos botões de toque (ataque, pulo, dash e habilidades de cada guardião)."""
import math
from pix import Can


def base():
    return Can(18, 18)


def finish(c):
    return c.outline()


def atk_minotauro():
    c = base(); c.ox, c.oy = 1, 1
    c.line(3, 14, 11, 4, 'B'); c.line(4, 14, 12, 4, 'b')
    c.ell(12, 5, 3, 4, 'i'); c.ell(12, 5, 2, 3, 'I')
    return finish(c)


def atk_lich():
    c = base(); c.ox, c.oy = 1, 1
    c.line(2, 12, 12, 2, 'w'); c.line(3, 12, 13, 2, 'w')
    c.disc(2, 13, 1.5, 'w'); c.disc(13, 2, 1.5, 'C')
    return finish(c)


def atk_dragao():
    c = base(); c.ox, c.oy = 1, 1
    for i in range(3):
        c.line(3 + i * 4, 13, 7 + i * 4, 2, 'q'); c.line(4 + i * 4, 13, 8 + i * 4, 2, 'R')
    return finish(c)


def jump():
    c = base(); c.ox, c.oy = 1, 1
    c.tri([(7.5, 1), (1, 9), (14, 9)], 'Y'); c.rect(5, 9, 6, 5, 'Y')
    return finish(c)


def dash():
    c = base(); c.ox, c.oy = 1, 1
    for x in (1, 7):
        c.tri([(x, 2), (x + 7, 7.5), (x, 13)], 'C')
    return finish(c)


def sk(kind):
    c = base(); c.ox, c.oy = 1, 1
    if kind == 'investida':
        c.line(2, 9, 13, 9, 'O'); c.line(2, 6, 9, 6, 'o'); c.line(2, 12, 9, 12, 'o')
        c.line(10, 4, 14, 1, 'w'); c.line(10, 14, 14, 13, 'w'); c.disc(11, 9, 3, 'B')
    elif kind == 'pisao':
        c.rect(1, 11, 14, 3, 's'); c.line(7, 11, 5, 14, 'k'); c.line(8, 11, 11, 14, 'k')
        c.tri([(1, 10), (4, 3), (6, 10)], 'N'); c.tri([(9, 10), (12, 3), (15, 10)], 'N')
    elif kind == 'furia':
        c.tri([(7.5, 0), (2, 14), (13, 14)], 'R'); c.tri([(7.5, 5), (4, 14), (11, 14)], 'O')
        c.px(6, 10, 'k'); c.px(9, 10, 'k')
    elif kind == 'coroa':
        for a in range(-3, 4):
            ang = -math.pi / 2 + a * 0.35
            c.line(7.5, 13, 7.5 + math.cos(ang) * 12, 13 + math.sin(ang) * 12, 'C')
    elif kind == 'muralha':
        for y in range(1, 15, 4):
            c.rect(4, y, 8, 3, 'w'); c.px(6, y + 1, 'k'); c.px(9, y + 1, 'k')
    elif kind == 'drenar':
        c.ring(7.5, 7.5, 6, 'v'); c.tri([(4, 3), (11, 3), (7.5, 7.5)], 'P'); c.tri([(4, 12), (11, 12), (7.5, 7.5)], 'P')
        c.px(7, 7, 'W')
    elif kind == 'baforada':
        c.tri([(1, 7.5), (14, 1), (14, 14)], 'o'); c.tri([(3, 7.5), (14, 4), (14, 11)], 'O'); c.tri([(6, 7.5), (14, 6), (14, 9)], 'Z')
    elif kind == 'mergulho':
        c.tri([(2, 2), (13, 13), (5, 13)], 'R'); c.tri([(13, 13), (13, 6), (7, 13)], 'O')
        c.line(1, 1, 8, 8, 'q')
    elif kind == 'escamas':
        c.tri([(7.5, 15), (1, 4), (14, 4)], 'R'); c.rect(1, 1, 14, 4, 'R'); c.tri([(7.5, 12), (4, 5), (11, 5)], 'O')
        c.px(7, 6, 'Z')
    elif kind == 'redemoinho':
        c.ring(7.5, 7.5, 6.5, 'R'); c.ring(7.5, 7.5, 4, 'q')
        c.line(7.5, 7.5, 13, 3, 'i'); c.line(7.5, 7.5, 2, 12, 'i'); c.disc(7.5, 7.5, 1.5, 'B')
    elif kind == 'sede':
        c.tri([(7.5, 1), (3, 9), (12, 9)], 'R'); c.disc(7.5, 10, 4.5, 'R'); c.px(6, 9, 'q'); c.px(5, 10, 'q')
    elif kind == 'postura':
        c.disc(7.5, 7.5, 6.5, 's'); c.disc(7.5, 7.5, 4.5, 'S'); c.disc(7.5, 7.5, 2, 'D'); c.line(4, 4, 6, 6, 'w')
    elif kind == 'chifrada':
        c.disc(7.5, 10, 4.5, 'B'); c.line(3, 8, 1, 1, 'w'); c.line(12, 8, 14, 1, 'w')
        c.px(6, 10, 'R'); c.px(9, 10, 'R'); c.tri([(7, 0), (9, 0), (8, 4)], 'Y')
    elif kind == 'terremoto':
        c.rect(0, 12, 16, 3, 's'); c.line(3, 12, 5, 15, 'k'); c.line(11, 12, 9, 15, 'k')
        for x in (1, 6, 11):
            c.tri([(x, 11), (x + 2, 4), (x + 4, 11)], 'N')
    elif kind == 'arremesso':
        c.line(1, 14, 12, 3, 'B'); c.tri([(10, 1), (15, 0), (14, 5)], 'Y'); c.line(1, 9, 5, 5, 'O')
    elif kind == 'investida_longa':
        for y in (4, 8, 12):
            c.line(0, y, 8, y, 'O')
        c.disc(11, 8, 3.5, 'Y'); c.line(12, 5, 15, 2, 'w'); c.line(12, 11, 15, 14, 'w')
    elif kind == 'estouro':
        for x, y in ((1, 3), (7, 8), (2, 12)):
            c.ell(x + 4, y + 1, 3.5, 2, 'O'); c.px(x + 7, y - 1, 'Z')
    elif kind == 'erguer':
        c.disc(7.5, 5, 4, 'w'); c.px(6, 5, 'k'); c.px(9, 5, 'k'); c.rect(5, 9, 6, 2, 'w')
        c.rect(1, 13, 14, 2, 'p'); c.line(2, 13, 4, 10, 'v'); c.line(13, 13, 11, 10, 'v')
    elif kind == 'explosao':
        for a in range(8):
            ang = a * math.pi / 4
            c.line(7.5, 7.5, 7.5 + math.cos(ang) * 7, 7.5 + math.sin(ang) * 7, 'v')
        c.disc(7.5, 7.5, 3, 'w'); c.px(6, 7, 'k'); c.px(9, 7, 'k')
    elif kind == 'lanca_gelo':
        c.tri([(0, 7.5), (11, 4), (11, 11)], 'c'); c.tri([(11, 4), (15, 7.5), (11, 11)], 'C'); c.hl(2, 13, 7, 'W')
    elif kind == 'nevasca':
        for x, y in ((3, 3), (11, 4), (6, 9), (12, 12), (2, 13)):
            c.line(x - 2, y, x + 2, y, 'C'); c.line(x, y - 2, x, y + 2, 'C'); c.px(x, y, 'W')
    elif kind == 'bloco':
        c.rect(2, 2, 12, 12, 'c'); c.rect(4, 4, 8, 8, 'C'); c.line(4, 4, 7, 7, 'W')
    elif kind == 'parar':
        c.disc(7.5, 7.5, 6.5, 'Y'); c.disc(7.5, 7.5, 5, 'Z'); c.rect(5, 4, 2, 7, 'k'); c.rect(9, 4, 2, 7, 'k')
    elif kind == 'rebobinar':
        c.ring(7.5, 7.5, 6, 'Y'); c.tri([(0, 6), (5, 2), (5, 9)], 'Y'); c.line(7.5, 7.5, 7.5, 4, 'Z'); c.line(7.5, 7.5, 10, 9, 'Z')
    elif kind == 'eco':
        c.disc(5, 8, 4, 'v'); c.disc(10, 8, 4, 'P'); c.ring(10, 8, 4, 'W')
    elif kind == 'raio':
        c.tri([(9, 0), (3, 9), (8, 9)], 'Z'); c.tri([(8, 7), (6, 15), (13, 6)], 'Y')
    elif kind == 'voo':
        c.tri([(7.5, 9), (0, 2), (2, 12)], 'U'); c.tri([(7.5, 9), (15, 2), (13, 12)], 'U'); c.disc(7.5, 9, 2, 'c')
    elif kind == 'tempestade':
        c.ell(7.5, 4, 7, 3.5, 'D'); c.ell(5, 3, 3, 2, 's')
        c.line(4, 7, 2, 14, 'Z'); c.line(9, 7, 7, 14, 'Y'); c.line(13, 7, 12, 13, 'Z')
    elif kind == 'nuvem':
        c.disc(5, 9, 4, 'G'); c.disc(10, 8, 4.5, 'G'); c.disc(8, 5, 3.5, 'l'); c.px(5, 9, 'p'); c.px(11, 9, 'p')
    elif kind == 'ferrao':
        c.tri([(0, 4), (11, 7.5), (0, 11)], 'G'); c.tri([(10, 5), (15, 7.5), (10, 10)], 'l'); c.px(14, 7, 'W')
    elif kind == 'muda':
        c.ell(7.5, 7.5, 6.5, 4, 'G'); c.ell(7.5, 7.5, 4.5, 2.5, 'l')
        for x in (3, 7, 11):
            c.px(x, 6, 'g'); c.px(x + 1, 9, 'g')
    elif kind == 'meteoro':
        c.tri([(0, 0), (9, 5), (5, 9)], 'o'); c.disc(10, 10, 4.5, 'r'); c.disc(10, 10, 3, 'o'); c.px(9, 9, 'Z')
    elif kind == 'rugido':
        c.tri([(0, 3), (7, 7.5), (0, 12)], 'R')
        for r in (4, 7, 10):
            c.line(4 + r, 7.5 - r * 0.6, 4 + r, 7.5 + r * 0.6, 'O')
    elif kind == 'asas_fogo':
        c.tri([(7.5, 10), (0, 1), (1, 13)], 'o'); c.tri([(7.5, 10), (15, 1), (14, 13)], 'o')
        c.tri([(7.5, 10), (3, 5), (3, 12)], 'O'); c.tri([(7.5, 10), (12, 5), (12, 12)], 'O')
    return finish(c)


def atk_class(g, i):
    c = base(); c.ox, c.oy = 1, 1
    if g == 'minotauro':
        if i == 1:
            c.line(1, 14, 7, 4, 'B'); c.ell(7, 4, 2.5, 3, 'R')
            c.line(14, 14, 8, 4, 'B'); c.ell(9, 4, 2.5, 3, 'R')
        elif i == 2:
            c.line(3, 14, 10, 6, 'B'); c.disc(11, 4, 3.5, 's'); c.px(11, 0, 'S'); c.px(15, 4, 'S'); c.px(8, 2, 'S')
        else:
            c.line(1, 14, 12, 3, 'B'); c.tri([(10, 1), (15, 0), (14, 5)], 'Y')
    elif g == 'lich':
        if i == 1:
            c.disc(8, 7, 5, 'w'); c.px(6, 7, 'k'); c.px(10, 7, 'k'); c.rect(6, 11, 5, 2, 'w'); c.line(0, 12, 3, 9, 'G')
        elif i == 2:
            c.tri([(1, 14), (12, 2), (14, 5)], 'c'); c.line(2, 13, 12, 3, 'C')
        else:
            c.ring(7.5, 7.5, 6, 'Y'); c.line(7.5, 7.5, 7.5, 3, 'Z'); c.line(7.5, 7.5, 11, 9, 'Z')
    else:
        if i == 1:
            for k in range(3):
                c.line(3 + k * 4, 13, 7 + k * 4, 2, 'Z'); c.line(4 + k * 4, 13, 8 + k * 4, 2, 'U')
        elif i == 2:
            c.line(1, 2, 8, 10, 'G'); c.line(2, 2, 9, 10, 'G'); c.tri([(8, 8), (14, 14), (12, 7)], 'l')
        else:
            for k in range(3):
                c.line(2 + k * 5, 14, 6 + k * 5, 1, 'O'); c.line(3 + k * 5, 14, 7 + k * 5, 1, 'R'); c.line(4 + k * 5, 14, 8 + k * 5, 1, 'R')
    return finish(c)


def build(save):
    save('ui/atk_minotauro', atk_minotauro())
    save('ui/atk_lich', atk_lich())
    save('ui/atk_dragao', atk_dragao())
    save('ui/jump', jump())
    save('ui/dash', dash())
    for k in ('investida', 'pisao', 'furia', 'coroa', 'muralha', 'drenar', 'baforada', 'mergulho', 'escamas',
              'redemoinho', 'sede', 'postura', 'chifrada', 'terremoto', 'arremesso', 'investida_longa', 'estouro',
              'erguer', 'explosao', 'lanca_gelo', 'nevasca', 'bloco', 'parar', 'rebobinar', 'eco',
              'raio', 'voo', 'tempestade', 'nuvem', 'ferrao', 'muda', 'meteoro', 'rugido', 'asas_fogo'):
        save('ui/sk_' + k, sk(k))
    for g in ('minotauro', 'lich', 'dragao'):
        save('ui/atk_%s_0' % g, {'minotauro': atk_minotauro, 'lich': atk_lich, 'dragao': atk_dragao}[g]())
        for i in (1, 2, 3):
            save('ui/atk_%s_%d' % (g, i), atk_class(g, i))
