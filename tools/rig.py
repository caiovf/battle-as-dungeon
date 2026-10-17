"""Rig de animação em camadas (ideia do Starbound): cada personagem é desenhado por partes
(pernas, corpo, braço de trás, cabeça, braço da frente + arma) a partir de uma POSE.
As poses seguem o GUIA-ANIMACAO.md: andar por fases, ataque em 4 tempos
(antecipação, smear, impacto, recuperação), follow-through de capa e cabelo."""
import math
from pix import Can

# ---------------------------------------------------------------------
# Poses
# ---------------------------------------------------------------------
GUARD_FRAMES = ['idle0', 'idle1', 'idle2', 'idle3', 'run0', 'run1', 'run2', 'run3', 'run4', 'run5',
                'jump', 'fall', 'atk0', 'atk1', 'atk2', 'atk3', 'cast', 'hurt']
LEG_FRAMES = ['idle0', 'idle1', 'run0', 'run1', 'run2', 'run3', 'tele', 'atk0', 'atk1', 'atk2', 'hurt']


def pose(fr):
    """Parâmetros comuns: bob (y do corpo), passo (fase das pernas), arma (ângulo em graus,
    0 = para frente, -90 = para cima), lean (inclinação), smear (arco a desenhar), cape (atraso)."""
    p = dict(bob=0, phase=None, arm=-55, lean=0, smear=None, cape=0, tuck=False, stretch=False, squash=0, cast=False, hurt=False, back=-20)
    if fr.startswith('idle'):
        i = int(fr[-1])
        p['bob'] = [0, 0, 1, 1][i % 4]
        p['arm'] = -55 + [0, 0, 3, 3][i % 4]
        p['cape'] = [0, 1, 1, 0][i % 4]
    elif fr.startswith('run'):
        i = int(fr[-1])
        n = 6 if fr in ('run4', 'run5') or True else 4
        p['phase'] = i
        p['lean'] = 1
        p['arm'] = -35
        p['cape'] = 2
    elif fr == 'jump':
        p.update(tuck=True, arm=-80, bob=-1, cape=-2, stretch=True)
    elif fr == 'fall':
        p.update(arm=-70, bob=0, cape=3)
    elif fr in ('atk0', 'tele'):        # antecipação: arma recolhida para trás
        p.update(arm=-150, lean=-2, bob=1, squash=1, cape=-1)
    elif fr == 'atk1':                  # smear
        p.update(arm=-40, lean=1, smear=(-150, 40), cape=2)
    elif fr == 'atk2':                  # impacto (segurado)
        p.update(arm=40, lean=3, bob=1, cape=3)
    elif fr == 'atk3':                  # recuperação
        p.update(arm=5, lean=1, cape=1)
    elif fr == 'cast':
        p.update(arm=-100, cast=True, bob=-1, cape=-1, back=-110)
    elif fr == 'hurt':
        p.update(arm=-20, lean=-3, hurt=True, cape=-2)
    return p


def legs_for(phase, n=6, stride=4, lift=2):
    """Pés (dx, dy) da perna da frente e da de trás para um ciclo de n quadros."""
    if phase is None:
        return (1, 0), (-1, 0)
    a = phase / n * math.tau
    f = (round(math.sin(a) * stride), -round(max(0, math.cos(a)) * lift))
    b = (round(-math.sin(a) * stride), -round(max(0, -math.cos(a)) * lift))
    return f, b


def run_bob(phase, n=6):
    if phase is None:
        return 0
    return -1 if phase % (n // 2) == (n // 4) else (1 if phase % (n // 2) == 0 else 0)


def polar(x, y, ang, dist):
    a = math.radians(ang)
    return x + math.cos(a) * dist, y + math.sin(a) * dist


def smear(c, cx, cy, r0, r1, a0, a1, col_out, col_in):
    """Meia-lua do golpe (smear frame) entre os ângulos a0 e a1."""
    steps = max(8, int(abs(a1 - a0) / 4))
    for s in range(steps + 1):
        a = a0 + (a1 - a0) * s / steps
        w = math.sin(s / steps * math.pi)  # mais grossa no meio
        for r in range(int(r0), int(r0 + (r1 - r0) * (0.4 + 0.6 * w)) + 1):
            x, y = polar(cx, cy, a, r)
            c.px(x, y, col_in if r > r0 + 2 else col_out)


# ---------------------------------------------------------------------
# Armas (desenhadas a partir da mão, no ângulo dado)
# ---------------------------------------------------------------------
def weapon(c, kind, hx, hy, ang, pal):
    if kind == 'axe':
        ex, ey = polar(hx, hy, ang, 15); bx, by = polar(hx, hy, ang + 180, 4)
        c.line(bx, by, ex, ey, 'b'); c.line(*polar(bx, by, ang + 90, 1), *polar(ex, ey, ang + 90, 1), 'B')
        # lâmina larga em leque, perpendicular ao cabo
        top, bot = polar(ex, ey, ang, 2), polar(ex, ey, ang + 180, 5)
        far_t = polar(*polar(ex, ey, ang, 5), ang - 90, 8)
        far_b = polar(*polar(ex, ey, ang + 180, 7), ang - 90, 8)
        c.tri([top, bot, far_t], 'i'); c.tri([bot, far_t, far_b], 'i')
        c.line(*far_t, *far_b, 'W'); c.line(*polar(far_t[0], far_t[1], ang + 90, 1), *polar(far_b[0], far_b[1], ang + 90, 1), 'I')
    elif kind == 'axes':
        for off, ln in ((0, 12), (-35, 10)):
            ex, ey = polar(hx, hy, ang + off, ln)
            c.line(hx, hy, ex, ey, 'b')
            px, py = polar(ex, ey, ang + off + 90, 2)
            c.ell(px, py, 3, 3, 'i'); c.px(px, py, 'I')
    elif kind == 'mace':
        ex, ey = polar(hx, hy, ang, 12)
        c.line(hx, hy, ex, ey, 'b'); c.disc(ex, ey, 3.5, 'e'); c.disc(ex - 1, ey - 1, 2, 'i')
        for a in range(0, 360, 90):
            c.px(*polar(ex, ey, a + ang, 5), 'I')
    elif kind == 'spear':
        ex, ey = polar(hx, hy, ang, 26); bx, by = polar(hx, hy, ang + 180, 8)
        c.line(bx, by, ex, ey, 'B')
        tx, ty = polar(ex, ey, ang, 5)
        c.tri([polar(ex, ey, ang + 90, 2.5), polar(ex, ey, ang - 90, 2.5), (tx, ty)], 'I')
        c.px(*polar(ex, ey, ang + 180, 2), pal.get('accent', 'R'))
    elif kind == 'sword':
        ex, ey = polar(hx, hy, ang, 20)
        c.line(hx, hy, ex, ey, 'I'); c.line(*polar(hx, hy, ang + 90, 1), *polar(ex, ey, ang + 90, 1), 'i')
        g1, g2 = polar(hx, hy, ang + 90, 3), polar(hx, hy, ang - 90, 3)
        c.line(*g1, *g2, 'Y'); c.px(*polar(ex, ey, ang, 1), 'W')
    elif kind == 'hammer':
        ex, ey = polar(hx, hy, ang, 20); bx, by = polar(hx, hy, ang + 180, 4)
        c.line(bx, by, ex, ey, 'B'); c.line(bx + 1, by, ex + 1, ey, 'b')
        for t in range(-6, 7):
            for s in range(-4, 5):
                x, y = polar(*polar(ex, ey, ang + 90, t), ang, s)
                c.px(x, y, 'I' if s < -1 else 'i')
    elif kind in ('staff', 'ice', 'clock', 'lantern', 'moon', 'sun', 'fire'):
        ex, ey = polar(hx, hy, ang, 22); bx, by = polar(hx, hy, ang + 180, 8)
        c.line(bx, by, ex, ey, 'y' if kind in ('clock', 'sun') else 'B')
        gem = {'staff': ('c', 'C'), 'ice': ('C', 'W'), 'clock': ('Y', 'Z'), 'lantern': ('l', 'W'), 'moon': ('v', 'W'),
               'sun': ('Z', 'W'), 'fire': ('o', 'Z')}[kind]
        if kind == 'clock':
            c.ring(ex, ey, 3.5, 'Y'); c.px(ex, ey, 'k'); c.line(ex, ey, ex, ey - 2, 'k'); c.line(ex, ey, ex + 2, ey, 'k')
        elif kind == 'moon':
            c.disc(ex, ey, 3.5, 'v'); c.disc(ex + 1.5, ey - 1, 3, None if False else 'k'); c.disc(ex + 1.5, ey - 1, 2.4, None)
        elif kind == 'ice':
            c.tri([(ex - 3, ey + 2), (ex + 3, ey + 2), (ex, ey - 6)], 'C'); c.px(ex, ey - 2, 'W')
        elif kind == 'lantern':
            c.rect(ex - 2, ey - 2, 5, 5, 'e'); c.rect(ex - 1, ey - 1, 3, 3, 'l'); c.px(ex, ey, 'W')
        else:
            c.disc(ex, ey, 3, gem[0]); c.disc(ex, ey, 1.6, gem[1])
    elif kind == 'bow':
        a = math.radians(ang)
        for t in range(-9, 10):
            k = abs(t) / 9
            x, y = polar(*polar(hx, hy, ang, 3 - k * k * 4), ang + 90, t)
            c.px(x, y, 'n')
        c.line(*polar(*polar(hx, hy, ang, -1), ang + 90, 9), *polar(*polar(hx, hy, ang, -1), ang - 90, 9), 'w')
    elif kind == 'shield_sword':
        weapon(c, 'sword', hx, hy, ang, pal)
    elif kind == 'blades':
        for off in (0, 30):
            ex, ey = polar(hx, hy, ang + off, 11)
            c.line(hx, hy, ex, ey, 'I'); c.px(ex, ey, 'W')
    elif kind == 'whip':
        pts = [(hx, hy)]
        for i in range(1, 9):
            x, y = polar(hx, hy, ang + math.sin(i * 0.9) * 12, i * 3.2)
            pts.append((x, y))
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            c.line(x0, y0, x1, y1, 'B')
        c.px(*pts[-1], 'R')
    elif kind == 'lance':
        ex, ey = polar(hx, hy, ang, 30); bx, by = polar(hx, hy, ang + 180, 6)
        c.line(bx, by, ex, ey, 'i'); c.line(*polar(bx, by, ang + 90, 1), *polar(ex, ey, ang + 90, 1), 'I')
        c.tri([polar(hx, hy, ang + 90, 4), polar(hx, hy, ang - 90, 4), polar(hx, hy, ang, 8)], 'Y')
        c.px(*polar(ex, ey, ang, 1), 'W')
    elif kind == 'bottle':
        ex, ey = polar(hx, hy, ang, 4)
        c.disc(ex, ey, 3, 'l'); c.rect(ex - 1, ey - 5, 2, 3, 'w'); c.px(ex - 1, ey - 1, 'W')


# ---------------------------------------------------------------------
# GUARDIÕES (12 classes: espécie × classe)
# ---------------------------------------------------------------------
GPAL = {
    'minotauro_0': dict(fur='B', dark='b', skin='n', cloth='r', trim='Y', weapon='axe', horn='w', eye='R'),
    'minotauro_1': dict(fur='r', dark='k', skin='q', cloth='K', trim='R', weapon='axes', horn='S', eye='Y', paint=True),
    'minotauro_2': dict(fur='D', dark='d', skin='s', cloth='U', trim='i', weapon='mace', horn='w', eye='c', shield=True),
    'minotauro_3': dict(fur='N', dark='n', skin='Z', cloth='P', trim='Y', weapon='spear', horn='Y', eye='R', accent='P'),
    'lich_0': dict(robe='p', robe2='P', bone='w', eye='c', crown='Y', weapon='staff'),
    'lich_1': dict(robe='K', robe2='g', bone='w', eye='l', crown='S', weapon='lantern'),
    'lich_2': dict(robe='t', robe2='T', bone='C', eye='W', crown='C', weapon='ice'),
    'lich_3': dict(robe='y', robe2='Y', bone='w', eye='Z', crown='Z', weapon='clock'),
    'dragao_0': dict(body='R', belly='N', wing='r', wing2='q', spike='O', eye='Y', horn='w'),
    'dragao_1': dict(body='U', belly='C', wing='u', wing2='c', spike='Y', eye='Z', horn='Y'),
    'dragao_2': dict(body='G', belly='v', wing='p', wing2='P', spike='l', eye='R', horn='S'),
    'dragao_3': dict(body='K', belly='y', wing='k', wing2='d', spike='Y', eye='O', horn='Y', big=True),
}


def guard(key, fr):
    sp = key.split('_')[0]
    return {'minotauro': _minotauro, 'lich': _lich, 'dragao': _dragao}[sp](GPAL[key], fr)


def _minotauro(P, fr):
    p = pose(fr)
    c = Can(48, 42)
    run = p['phase']
    bob = p['bob'] + run_bob(run)
    c.ox, c.oy = 8 + p['lean'] // 2, 4 + bob
    f, b = legs_for(run)
    if p['tuck']:
        f, b = (2, -4), (-2, -3)
    # pernas (de trás primeiro)
    for (dx, dy), col in ((b, P['dark']), (f, P['fur'])):
        lx = 13 + dx
        c.rect(lx - 2, 25 + dy, 5, 6, col); c.rect(lx - 2, 31 + dy, 5, 3, P['dark']); c.rect(lx - 2, 34 + dy, 5, 2, 'K')
    # tanga
    c.rect(8, 23, 15, 4, P['cloth']); c.hl(8, 22, 23, P['trim']); c.rect(13 - p['cape'] // 2, 27, 5, 3, P['cloth'])
    # escudo nas costas/frente (classe pedra)
    lean = p['lean']
    # braço de trás
    bx, by = polar(6 + lean, 14, 90 + p['back'] + 40, 1)
    c.rect(3 + lean, 14, 4, 9, P['fur']); c.rect(3 + lean, 22, 4, 3, P['skin'])
    if P['weapon'] == 'axes':
        weapon(c, 'axe', 5 + lean, 24, p['arm'] + 150, P)
    # tronco
    c.ell(16 + lean, 18, 10, 7, P['fur'])
    c.ell(13 + lean, 16, 4, 3, P['skin']); c.ell(20 + lean, 16, 4, 3, P['skin'])
    c.ell(16 + lean, 21, 4, 2.5, P['skin']); c.hl(14 + lean, 18 + lean, 21, P['fur'])
    if P.get('paint'):
        c.line(11 + lean, 14, 15 + lean, 22, 'Y'); c.line(20 + lean, 14, 17 + lean, 22, 'Y')
    c.ell(8 + lean, 13, 4, 3, P['dark']); c.ell(24 + lean, 13, 4, 3, P['dark'])
    # cabeça
    hx, hy = 23 + lean + max(0, lean), 7 + (1 if p['hurt'] else 0)
    c.ell(hx, hy, 5, 5, P['fur']); c.ell(hx + 6, hy + 3, 3.5, 3, P['skin']); c.hl(hx + 4, hy + 8, hy + 1, 'N')
    c.px(hx + 7, hy + 2, 'k'); c.px(hx + 5, hy + 2, 'k'); c.ring(hx + 6, hy + 5, 1.2, 'Y')
    c.px(hx + 1, hy - 1, 'W' if p['hurt'] else P['eye']); c.px(hx + 2, hy - 1, 'W' if p['hurt'] else P['eye'])
    c.rect(hx - 2, hy - 6, 5, 2, P['dark'])
    for d in (0, 1):
        c.line(hx - 3, hy - 4 + d, hx - 7, hy - 6 + d, P['horn']); c.line(hx - 7, hy - 6 + d, hx - 8, hy - 9 + d, P['horn'])
        c.line(hx + 3, hy - 4 + d, hx + 7, hy - 6 + d, P['horn']); c.line(hx + 7, hy - 6 + d, hx + 9, hy - 9 + d, P['horn'])
    # escudo (Guardião de Pedra)
    if P.get('shield'):
        sx = 26 + lean + (3 if fr == 'atk2' else 0)
        c.rect(sx, 12, 7, 14, 'e'); c.rect(sx + 1, 13, 5, 12, 'i'); c.vl(sx + 3, 14, 23, 'c'); c.hl(sx + 1, sx + 5, 18, 'c')
    # braço da frente + arma
    shx, shy = 24 + lean, 15
    hx2, hy2 = polar(shx, shy, p['arm'] + 25, 7)
    c.line(shx, shy, hx2, hy2, P['fur']); c.line(shx + 1, shy, hx2 + 1, hy2, P['fur']); c.line(shx, shy + 1, hx2, hy2 + 1, P['fur'])
    if p['smear']:
        a0, a1 = p['smear']
        ro = 28 if P['weapon'] == 'spear' else 24
        smear(c, shx, shy, ro - 7, ro, a0, a1, 'o', 'O')
    weapon(c, 'axe' if P['weapon'] == 'axes' else P['weapon'], hx2, hy2, p['arm'], P)
    c.disc(hx2, hy2, 1.5, P['skin'])
    if p['cast']:
        c.ring(16, 18, 13, P['trim'])
    return c.outline()


def _lich(P, fr):
    p = pose(fr)
    c = Can(40, 44)
    run = p['phase']
    float_y = {'idle0': 0, 'idle1': -1, 'idle2': -2, 'idle3': -1}.get(fr, -1)
    c.ox, c.oy = 6, 6 + float_y
    lean = 1 if run is not None else (p['lean'] // 2)
    flut = (run or 0) % 2
    # manto
    c.tri([(13 + lean, 9), (2 - (2 if run is not None else 0), 32), (25, 32)], P['robe'])
    c.tri([(13 + lean, 11), (7, 32), (20, 32)], P['robe2'])
    for i, x in enumerate(range(2, 26, 4)):
        c.tri([(x, 31), (x + 3, 31), (x + 1 + ((i + flut) % 2), 35 + ((i + flut) % 2))], P['robe'])
    c.rect(9 + lean, 13, 8, 8, 'K')
    for y in (14, 16, 18):
        c.hl(10 + lean, 15 + lean, y, P['bone'])
    # caveira
    sx = 13 + lean
    c.disc(sx, 7, 5, P['bone']); c.rect(sx - 3, 9, 7, 4, P['bone'])
    c.rect(sx - 3, 5, 3, 3, 'k'); c.rect(sx + 1, 5, 3, 3, 'k')
    ey = 'W' if p['hurt'] else P['eye']
    c.px(sx - 2, 6, ey); c.px(sx + 2, 6, ey)
    c.hl(sx - 2, sx + 3, 11, 'k'); c.px(sx - 1, 12, P['bone']); c.px(sx + 1, 12, P['bone'])
    for x in (sx - 5, sx - 2, sx + 1, sx + 4):
        c.tri([(x, 3), (x + 2, 3), (x + 1, -1)], P['crown'])
    c.hl(sx - 5, sx + 5, 3, P['crown'])
    # braço + arma
    shx, shy = 18 + lean, 14
    hx, hy = polar(shx, shy, p['arm'] + 30, 6)
    c.line(shx, shy, hx, hy, P['robe']); c.line(shx, shy + 1, hx, hy + 1, P['robe'])
    if p['smear']:
        smear(c, shx, shy, 10, 15, p['smear'][0], p['smear'][1], P['eye'], P['eye'])
    weapon(c, P['weapon'], hx, hy, p['arm'] - 10 if fr not in ('atk1', 'atk2') else p['arm'] - 60, P)
    c.disc(hx, hy, 1.4, P['bone'])
    if p['cast']:
        c.ring(13, 18, 14, P['eye'])
    return c.outline('k')


def _dragao(P, fr):
    p = pose(fr)
    big = P.get('big')
    c = Can(48, 38)
    run = p['phase']
    bob = p['bob'] + run_bob(run)
    c.ox, c.oy = 4, 5 + bob
    flap = {'jump': 1, 'fall': 2, 'cast': 1}.get(fr, (run or 0) % 3 if run is not None else (int(fr[-1]) % 2 if fr.startswith('idle') else 0))
    # asa de trás
    tips = [(2, 4), (4, -2), (8, 10)]
    tx, ty = tips[flap % 3]
    c.tri([(13, 12), (tx, ty), (9, 16)], P['wing'])
    # cauda (follow-through: balança com cape)
    cy = 22 + p['cape'] // 2
    c.line(1, cy, 9, 18, P['body']); c.line(1, cy + 1, 9, 19, P['body'])
    c.tri([(-1, cy - 3), (2, cy + 1), (-2, cy + 2)], P['spike'])
    # corpo
    rx = 10 if big else 9
    c.ell(16, 18, rx, 6, P['body']); c.ell(17, 21, 6, 3, P['belly'])
    for x in (9, 12, 15, 18):
        c.tri([(x, 13), (x + 2, 13), (x + 1, 10 - (1 if big else 0))], P['spike'])
    # pernas (galope)
    if run is not None:
        a = run / 6 * math.tau
        offs = [math.sin(a) * 3, math.sin(a + 1.5) * 3, math.sin(a + 3.1) * 3, math.sin(a + 4.6) * 3]
    elif p['tuck']:
        offs = [-2, -2, -2, -2]
    else:
        offs = [0, 0, 0, 0]
    for lx, o in zip((9, 13, 19, 23), offs):
        lift = -2 if o > 1.5 else 0
        c.rect(lx, 22, 3, 4 + lift, P['body']); c.rect(lx + round(o), 26 + lift, 3, 2, P['body']); c.px(lx + round(o) + 2, 27 + lift, 'w')
    # pescoço e cabeça
    hx = 23 + (2 if fr in ('atk1', 'atk2') else (-2 if fr == 'atk0' else 0))
    hy = 4 + (2 if fr == 'atk2' else 0)
    c.rect(hx - 1, hy + 5, 5, 9, P['body'])
    c.rect(hx, hy, 10, 7, P['body']); c.rect(hx + 8, hy + 3, 4, 4, P['body']); c.hl(hx + 8, hx + 11, hy + 6, P['belly'])
    c.px(hx + 6, hy + 2, 'k'); c.px(hx + 6, hy + 1, 'W' if p['hurt'] else P['eye'])
    c.line(hx + 1, hy, hx - 2, hy - 4, P['horn']); c.line(hx + 4, hy, hx + 3, hy - 4, P['horn'])
    if big:
        c.line(hx - 2, hy - 4, hx - 4, hy - 6, P['horn']); c.line(hx + 3, hy - 4, hx + 5, hy - 7, P['horn'])
    if fr in ('atk1', 'atk2', 'cast'):
        c.rect(hx + 8, hy + 7, 5, 2, 'x'); c.px(hx + 9, hy + 7, 'w'); c.px(hx + 11, hy + 7, 'w')
    # garra da frente (golpe)
    if fr in ('atk0', 'atk1', 'atk2'):
        ang = {'atk0': -120, 'atk1': -40, 'atk2': 30}[fr]
        shx, shy = 24, 17
        ex, ey = polar(shx, shy, ang, 8)
        c.line(shx, shy, ex, ey, P['body']); c.line(shx + 1, shy, ex + 1, ey, P['body'])
        for k in (-1, 0, 1):
            c.line(ex, ey, *polar(ex, ey, ang + k * 25, 4), 'w')
        if fr == 'atk1':
            for k in (0, 3, 6):
                smear(c, shx, shy, 8 + k, 9 + k, -120, 40, P['wing2'], P['wing2'])
    # asa da frente
    fx_, fy_ = [(8, 1), (14, -4), (10, 8)][flap % 3]
    c.tri([(16, 12), (fx_, fy_), (24, 4 if flap != 2 else 10)], P['wing2'])
    c.line(16, 12, fx_, fy_, P['wing'])
    return c.outline()


# ---------------------------------------------------------------------
# LENDÁRIOS (rig humanoide com parâmetros)
# ---------------------------------------------------------------------
LEGENDS = {
    'lyra': dict(skin='m', hair='R', hair_style='pony', armor='i', armor2='R', pants='u', cape='r', weapon='sword', style='swing', trail=('C', 'W')),
    'borin': dict(skin='m', hair='B', hair_style='beard', armor='S', armor2='s', pants='e', helmet='horned', weapon='hammer', style='heavy', wide=True, trail=('I', 'W')),
    'seraphine': dict(skin='m', hair='Y', hair_style='long', armor='w', armor2='Y', dress=True, wings=True, halo=True, weapon='sun', style='cast', trail=('Z', 'W')),
    'kael': dict(skin='M', hair='h', hair_style='short', armor='G', armor2='g', pants='b', hood='G', cape='g', weapon='bow', style='shoot', trail=('l', 'W')),
    'yuki': dict(skin='m', hair='w', hair_style='pony', armor='C', armor2='U', pants='u', mask=True, scarf='R', weapon='blades', style='swing', trail=('C', 'W')),
    'garrick': dict(skin='M', hair='h', hair_style='short', armor='U', armor2='i', pants='u', helmet='helm', tower=True, weapon='shield_sword', style='swing', trail=('C', 'W'), wide=True),
    'morgana': dict(skin='l', hair='P', hair_style='long', armor='p', armor2='g', dress=True, hat='witch', weapon='bottle', style='throw', trail=('l', 'G')),
    'thorne': dict(skin='M', hair='B', hair_style='wild', armor='B', armor2='n', pants='b', fur=True, weapon='whip', style='swing', trail=('N', 'W')),
    'ignis': dict(skin='m', hair='o', hair_style='short', armor='o', armor2='r', dress=True, crown=True, weapon='fire', style='cast', trail=('O', 'Z')),
    'bram': dict(skin='m', hair='S', hair_style='wild', armor='n', armor2='B', pants='b', goggles=True, weapon='bottle', style='throw', trail=('l', 'W')),
    'astra': dict(skin='m', hair='Y', hair_style='short', armor='Y', armor2='U', pants='u', helmet='plume', cape='U', weapon='lance', style='thrust', trail=('Z', 'W')),
    'ragnar': dict(skin='m', hair='R', hair_style='beard', armor='B', armor2='S', pants='b', helmet='horned', weapon='axes', style='heavy', wide=True, fur=True, trail=('I', 'W')),
    'nyx': dict(skin='w', hair='S', hair_style='long', armor='u', armor2='v', dress=True, hood='u', weapon='moon', style='cast', trail=('v', 'W')),
}


def legend(key, fr):
    L = LEGENDS[key]
    p = pose(fr)
    wide = L.get('wide')
    c = Can(64, 56)
    run = p['phase']
    bob = p['bob'] + run_bob(run, 4)
    c.ox, c.oy = 20, 10 + bob
    lean = p['lean']
    style = L['style']
    # ângulo da arma por estilo de ataque
    arm = p['arm']
    if style == 'thrust':
        arm = {'atk0': 180, 'tele': 180, 'atk1': 0, 'atk2': 0, 'atk3': 10}.get(fr, 20)
    elif style in ('shoot',):
        arm = {'atk0': 0, 'tele': 0, 'atk1': 0, 'atk2': 0}.get(fr, 30)
    elif style in ('cast', 'throw'):
        arm = {'atk0': -120, 'tele': -100, 'atk1': -40, 'atk2': -10, 'atk3': 20}.get(fr, -70)
    elif style == 'heavy':
        arm = {'atk0': -130, 'tele': -100, 'atk1': -20, 'atk2': 60}.get(fr, -60)
    if fr == 'tele':
        lean = -2
    # asas
    if L.get('wings'):
        span = 4 if fr in ('tele', 'atk1', 'atk2') else 0
        c.tri([(9, 14), (-4 - span, 4), (2, 22)], 'C'); c.tri([(9, 15), (-1 - span, 8), (4, 20)], 'W')
    # capa (follow-through)
    if L.get('cape'):
        cl = p['cape']
        c.tri([(9 + lean, 11), (2 - cl, 31 - max(0, cl)), (12, 31)], L['cape'])
    if L.get('scarf'):
        cl = p['cape']
        c.line(10, 9, 3 - cl, 10 + cl // 2, L['scarf']); c.line(10, 10, 2 - cl, 12 + cl // 2, L['scarf'])
    # pernas
    f, b = legs_for(run, 4, 3, 2)
    if p['tuck']:
        f, b = (1, -3), (-1, -2)
    w0 = 3 if wide else 0
    if L.get('dress'):
        c.tri([(14, 12), (3 - w0, 33), (25 + w0, 33)], L['armor'])
        c.tri([(14, 16), (8, 33), (20, 33)], L['armor2'])
        c.hl(4, 24, 33, L['armor2'])
        if run is not None:
            c.px(10 + f[0], 34, 'K'); c.px(17 + b[0], 34, 'K')
    else:
        for (dx, dy), col in ((b, L.get('pants', 'u')), (f, L.get('pants', 'u'))):
            lx = 13 + dx
            c.rect(lx - 2 - w0 // 2, 23 + dy, 4 + w0 // 2, 8, col); c.rect(lx - 2 - w0 // 2, 31 + dy, 5 + w0 // 2, 2, 'K')
    # tronco
    tw = 12 + w0 * 2
    c.rect(14 - tw // 2 + lean, 12, tw, 11, L['armor']); c.rect(15 - tw // 2 + lean, 13, tw - 2, 3, L['armor2'])
    c.hl(14 - tw // 2 + lean, 13 + tw // 2 + lean, 21, L['armor2'])
    if L.get('fur'):
        c.rect(12 - tw // 2 + lean, 10, tw + 4, 3, 'N'); c.hl(12 - tw // 2 + lean, 15 + tw // 2 + lean, 12, 'n')
    else:
        c.rect(11 - w0 + lean, 11, 5, 4, L['armor2']); c.rect(18 + w0 + lean, 11, 5, 4, L['armor2'])
    # braço de trás
    c.rect(9 - w0 + lean, 13, 3, 7, L['armor'])
    # cabeça
    hx, hy = 12 + lean, 2 + (1 if p['hurt'] else 0)
    c.rect(hx, hy, 8, 8, L['skin'])
    eye = 'W' if p['hurt'] else 'k'
    c.px(hx + 6, hy + 3, eye); c.px(hx + 4, hy + 3, eye)
    if L.get('mask'):
        c.rect(hx, hy + 5, 8, 3, 'u')
    if L.get('goggles'):
        c.hl(hx, hx + 7, hy + 3, 'o'); c.px(hx + 6, hy + 3, 'C'); c.px(hx + 4, hy + 3, 'C')
    hs = L.get('hair_style')
    hcol = L['hair']
    c.rect(hx - 1, hy - 2, 10, 4, hcol); c.vl(hx - 1, hy - 2, hy + 6, hcol)
    tail = -p['cape']
    if hs == 'pony':
        c.line(hx - 1, hy, hx - 6 + tail, hy + 5, hcol); c.line(hx - 1, hy + 1, hx - 7 + tail, hy + 7, hcol)
    elif hs == 'long':
        c.rect(hx - 2, hy, 3, 12, hcol); c.vl(hx + 8, hy, hy + 5, hcol)
    elif hs == 'beard':
        c.tri([(hx - 1, hy + 5), (hx + 9, hy + 5), (hx + 4, hy + 15)], hcol); c.rect(hx + 4, hy + 6, 3, 1, 'r')
    elif hs == 'wild':
        for x in range(hx - 1, hx + 9, 2):
            c.px(x, hy - 3, hcol)
    if L.get('hood'):
        c.rect(hx - 2, hy - 3, 11, 3, L['hood']); c.vl(hx - 2, hy - 3, hy + 8, L['hood']); c.vl(hx - 1, hy, hy + 7, L['hood'])
    if L.get('helmet') in ('helm', 'horned', 'plume'):
        c.rect(hx - 1, hy - 3, 10, 5, 'i'); c.hl(hx - 1, hx + 8, hy - 3, 'I'); c.hl(hx - 1, hx + 8, hy + 1, 'e')
        if L['helmet'] == 'horned':
            for d in (0, 1):
                c.line(hx - 1, hy - 1 + d, hx - 5, hy - 5 + d, 'w'); c.line(hx + 8, hy - 1 + d, hx + 12, hy - 5 + d, 'w')
        if L['helmet'] == 'plume':
            c.line(hx + 3, hy - 3, hx - 1 - p['cape'], hy - 8, 'R'); c.line(hx + 4, hy - 3, hx - p['cape'], hy - 8, 'R')
    if L.get('hat') == 'witch':
        c.rect(hx - 4, hy - 2, 16, 2, 'p'); c.tri([(hx, hy - 2), (hx + 8, hy - 2), (hx - 3 - p['cape'], hy - 12)], 'p'); c.hl(hx, hx + 7, hy - 3, 'l')
    if L.get('crown'):
        for x in (hx, hx + 3, hx + 6):
            c.tri([(x, hy - 2), (x + 2, hy - 2), (x + 1, hy - 6)], 'Y')
    if L.get('halo'):
        c.ell(hx + 4, hy - 6, 5, 1.5, 'Z')
    # escudo-torre (Garrick) na frente
    if L.get('tower'):
        sx = 21 + lean + (3 if fr in ('atk1', 'atk2') else 0)
        c.rect(sx, 10, 8, 18, 'U'); c.rect(sx + 1, 11, 6, 16, 'i'); c.vl(sx + 4, 12, 25, 'Y'); c.hl(sx + 1, sx + 6, 17, 'Y')
    # braço da frente + arma
    shx, shy = 19 + w0 + lean, 14
    hx2, hy2 = polar(shx, shy, arm + 25 if style != 'thrust' else arm, 6)
    c.line(shx, shy, hx2, hy2, L['armor']); c.line(shx, shy + 1, hx2, hy2 + 1, L['armor'])
    if p['smear'] and style in ('swing', 'heavy'):
        a0, a1 = (-130, 60) if style == 'heavy' else (-150, 40)
        ro = 26 if L['weapon'] in ('hammer', 'lance') else 23
        smear(c, shx, shy, ro - 6, ro, a0, a1, L['trail'][0], L['trail'][1])
    if fr == 'atk1' and style == 'thrust':
        for k in range(4):
            c.hl(hx2 + 8, hx2 + 30 - k * 3, hy2 - 2 + k, L['trail'][k % 2])
    if style == 'shoot' and fr in ('atk1',):
        c.hl(hx2 + 2, hx2 + 22, hy2, L['trail'][1])
    weapon(c, L['weapon'], hx2, hy2, arm, {'accent': L['armor2']})
    c.disc(hx2, hy2, 1.4, L['skin'])
    if p['cast'] or (style == 'cast' and fr == 'tele'):
        c.ring(14, 18, 12, L['trail'][0])
    return c.outline()


# Lendário no mapa (21×27): pose parada do rig reduzida a meia altura não fica boa,
# então o mapa usa um desenho próprio simplificado com as mesmas cores e acessórios.
def legend_map(key):
    L = LEGENDS[key]
    c = Can(21, 27)
    c.oy = 7
    wide = L.get('wide')
    if L.get('wings'):
        c.tri([(6, 9), (0, 3), (3, 15)], 'C'); c.tri([(14, 9), (20, 3), (17, 15)], 'C')
    if L.get('cape'):
        c.rect(4, 8, 4, 10, L['cape'])
    if L.get('dress'):
        c.tri([(10, 8), (3, 20), (17, 20)], L['armor']); c.hl(4, 16, 19, L['armor2'])
    else:
        p = L.get('pants', 'u')
        c.rect(6, 15, 3, 4, p); c.rect(11, 15, 3, 4, p); c.rect(6, 19, 3, 1, 'b'); c.rect(11, 19, 4, 1, 'b')
    w0 = 1 if wide else 0
    c.rect(5 - w0, 8, 10 + 2 * w0, 7, L['armor']); c.hl(5 - w0, 14 + w0, 9, L['armor2']); c.hl(5, 14, 13, L['armor2'])
    c.rect(3 - w0, 9, 2, 4, L['armor']); c.rect(15 + w0, 9, 2, 4, L['armor'])
    c.rect(6, 2, 8, 6, L['skin']); c.px(12, 4, 'k'); c.px(9, 4, 'k')
    c.rect(6, 1, 8, 2, L['hair']); c.vl(6, 1, 5, L['hair'])
    hs = L.get('hair_style')
    if hs == 'beard':
        c.tri([(6, 6), (14, 6), (10, 12)], L['hair'])
    if hs == 'pony':
        c.line(6, 2, 3, 7, L['hair'])
    if hs == 'long':
        c.vl(5, 2, 9, L['hair'])
    if L.get('hood'):
        c.rect(5, 0, 10, 2, L['hood']); c.vl(5, 0, 7, L['hood'])
    if L.get('helmet') in ('helm', 'horned', 'plume'):
        c.rect(5, 0, 10, 3, 'i')
        if L['helmet'] == 'horned':
            c.line(5, 1, 2, -2, 'w'); c.line(14, 1, 17, -2, 'w')
        if L['helmet'] == 'plume':
            c.line(9, 0, 6, -3, 'R')
    if L.get('hat') == 'witch':
        c.rect(3, 1, 14, 1, 'p'); c.tri([(6, 1), (14, 1), (8, -6)], 'p')
    if L.get('crown'):
        for x in (6, 9, 12):
            c.tri([(x, 1), (x + 2, 1), (x + 1, -2)], 'Y')
    if L.get('halo'):
        c.ring(10, -1, 3, 'Z')
    if L.get('mask'):
        c.rect(6, 5, 8, 2, 'u')
    if L.get('scarf'):
        c.line(6, 8, 2, 10, L['scarf'])
    if L.get('tower'):
        c.rect(15, 7, 5, 9, 'U'); c.vl(17, 8, 14, 'Y')
    wpn = L['weapon']
    if wpn in ('sword', 'shield_sword', 'blades'):
        c.line(16, 13, 19, 3, 'I')
    elif wpn in ('hammer',):
        c.vl(17, 3, 18, 'B'); c.rect(15, 1, 5, 4, 'i')
    elif wpn in ('axes',):
        c.vl(17, 5, 15, 'B'); c.ell(18, 5, 2, 3, 'i'); c.vl(2, 8, 15, 'B'); c.ell(1, 8, 2, 3, 'i')
    elif wpn == 'bow':
        c.line(16, 3, 18, 8, 'n'); c.line(18, 9, 16, 15, 'n'); c.vl(16, 4, 14, 'w')
    elif wpn == 'lance':
        c.line(15, 16, 19, -2, 'i'); c.tri([(14, 13), (18, 13), (16, 10)], 'Y')
    elif wpn == 'whip':
        c.line(16, 12, 19, 16, 'B'); c.line(19, 16, 17, 19, 'B')
    elif wpn == 'bottle':
        c.disc(17, 11, 2, 'l'); c.vl(17, 8, 9, 'w')
    else:  # cajados
        gem = {'fire': 'o', 'moon': 'v', 'sun': 'Z'}.get(wpn, 'c')
        c.vl(17, 2, 19, 'y'); c.disc(17, 2, 1.6, gem)
    return c.outline()


# ---------------------------------------------------------------------
# Efeitos de golpe (rastro do ataque): guardiões quentes, heróis frios
# ---------------------------------------------------------------------
def slash_fx(kind, f):
    """Rastro do ataque normal, 3 quadros."""
    c = Can(40, 40)
    c.auto_cel = False
    if kind == 'axe':       # meia-lua grossa laranja (guardião pesado)
        smear(c, 8, 20, 10 + f * 2, 22 + f * 2, -100 + f * 40, 40 + f * 30, 'o', 'O' if f < 2 else 'r')
    elif kind == 'claw':    # três riscos vermelhos (garras)
        for k in range(3):
            y0 = 8 + k * 9
            c.line(4 + f * 4, y0, 30 + f * 3, y0 + 14, 'R' if f < 2 else 'r'); c.line(5 + f * 4, y0, 31 + f * 3, y0 + 14, 'q' if f == 0 else 'R')
    elif kind == 'necro':   # rastro roxo
        smear(c, 8, 20, 12, 20, -70 + f * 30, 40 + f * 20, 'P', 'v')
    elif kind == 'spear':   # estocada laranja longa
        for k in range(3):
            c.hl(2 + f * 6, 38 - f * 2, 18 + k, 'O' if k == 1 else 'o')
    elif kind == 'hero':    # corte fino branco-azulado (heróis)
        smear(c, 10, 20, 16 + f, 19 + f, -80 + f * 30, 50 + f * 20, 'c', 'W')
    elif kind == 'hero_heavy':
        smear(c, 10, 20, 14 + f, 20 + f, -90 + f * 30, 60 + f * 20, 'I', 'W')
    return c


def spark_fx(kind, f):
    """Faísca de impacto: cruz fria (herói acerta) ou poeira quente (guardião acerta)."""
    c = Can(20, 20)
    c.auto_cel = False
    if kind == 'hero':
        r = 3 + f * 3
        col = ['W', 'C', 'c'][f]
        c.hl(10 - r, 10 + r, 10, col); c.vl(10, 10 - r, 10 + r, col)
        c.line(10 - r // 2, 10 - r // 2, 10 + r // 2, 10 + r // 2, col); c.line(10 - r // 2, 10 + r // 2, 10 + r // 2, 10 - r // 2, col)
    else:
        for a in range(0, 360, 45):
            x, y = polar(10, 10, a, 3 + f * 3)
            c.disc(x, y, 2 - f * 0.5, ['Z', 'O', 'n'][f])
    return c


def build(save):
    for key in GPAL:
        for fr in GUARD_FRAMES:
            save('arena/%s_%s' % (key, fr), guard(key, fr))
    for key in LEGENDS:
        for fr in LEG_FRAMES:
            save('arena/%s_%s' % (key, fr), legend(key, fr))
        save('heroes/' + key, legend_map(key))
    for k in ('axe', 'claw', 'necro', 'spear', 'hero', 'hero_heavy'):
        for f in range(3):
            save('fx/slash_%s_%d' % (k, f), slash_fx(k, f))
    for k in ('hero', 'guard'):
        for f in range(3):
            save('fx/spark_%s_%d' % (k, f), spark_fx(k, f))
