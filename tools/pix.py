"""Mini motor de pixel art: tela de pixels, formas, contorno automático e paleta.
Usado por gen_art.py para gerar todos os sprites do jogo."""
from PIL import Image
import random

# Paleta (inspirada em masmorras sombrias com acentos saturados)
PAL = {
    'k': (20, 12, 28),      # contorno
    'K': (36, 26, 46),
    'd': (52, 42, 64),      # pedra escura
    'D': (78, 66, 90),
    's': (108, 96, 118),
    'S': (150, 138, 156),
    'b': (66, 40, 34),      # madeira
    'B': (110, 68, 46),
    'n': (160, 106, 66),
    'N': (214, 160, 102),
    'y': (156, 104, 38),    # ouro
    'Y': (255, 196, 48),
    'Z': (255, 228, 138),
    'w': (236, 222, 190),   # osso / creme
    'W': (255, 255, 255),
    'r': (120, 30, 38),     # vermelho
    'R': (232, 52, 64),
    'q': (255, 120, 120),
    'o': (255, 112, 32),    # laranja/fogo
    'O': (255, 186, 60),
    'g': (34, 74, 48),      # verde
    'G': (70, 176, 72),
    'l': (150, 230, 90),
    't': (26, 64, 80),      # azul-petróleo
    'T': (36, 150, 188),
    'c': (96, 216, 244),
    'C': (200, 240, 255),
    'p': (66, 36, 98),      # roxo
    'P': (140, 72, 214),
    'v': (200, 150, 255),
    'm': (232, 180, 146),   # pele
    'M': (184, 124, 100),
    'h': (60, 36, 30),      # cabelo escuro
    'e': (84, 92, 110),     # aço
    'i': (148, 158, 176),
    'I': (210, 218, 228),
    'u': (40, 52, 80),      # azul escuro
    'U': (60, 104, 200),
    'x': (12, 8, 14),       # buraco
}

# Rampas de luz: cor -> (sombra, brilho). Usadas no sombreamento automático (luz de cima/esquerda).
RAMP = {
    'i': ('e', 'I'), 'I': ('i', 'W'), 'e': ('K', 'i'), 'Y': ('y', 'Z'), 'y': ('b', 'Y'), 'Z': ('Y', 'W'),
    'R': ('r', 'q'), 'r': ('k', 'R'), 'q': ('R', 'W'), 'o': ('r', 'O'), 'O': ('o', 'Z'),
    'G': ('g', 'l'), 'g': ('K', 'G'), 'l': ('G', 'W'), 'T': ('t', 'c'), 't': ('k', 'T'), 'c': ('T', 'C'), 'C': ('c', 'W'),
    'P': ('p', 'v'), 'p': ('k', 'P'), 'v': ('P', 'W'), 'U': ('u', 'c'), 'u': ('k', 'U'),
    'B': ('b', 'n'), 'b': ('k', 'B'), 'n': ('B', 'N'), 'N': ('n', 'Z'), 'w': ('S', 'W'), 'S': ('s', 'w'),
    's': ('D', 'S'), 'D': ('d', 's'), 'm': ('M', 'W'), 'M': ('b', 'm'),
}


class Can:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.ox, self.oy = 0, 0
        self.p = [[None] * w for _ in range(h)]

    def px(self, x, y, c):
        x, y = int(round(x)) + self.ox, int(round(y)) + self.oy
        if 0 <= x < self.w and 0 <= y < self.h:
            self.p[y][x] = c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.p[y][x]
        return None

    def rect(self, x, y, w, h, c):
        for j in range(int(y), int(y + h)):
            for i in range(int(x), int(x + w)):
                self.px(i, j, c)

    def hl(self, x0, x1, y, c):
        for i in range(int(x0), int(x1) + 1):
            self.px(i, y, c)

    def vl(self, x, y0, y1, c):
        for j in range(int(y0), int(y1) + 1):
            self.px(x, j, c)

    def line(self, x0, y0, x1, y1, c):
        x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.px(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def disc(self, cx, cy, r, c):
        for j in range(int(cy - r - 1), int(cy + r + 2)):
            for i in range(int(cx - r - 1), int(cx + r + 2)):
                if (i - cx) ** 2 + (j - cy) ** 2 <= r * r + 0.3:
                    self.px(i, j, c)

    def ell(self, cx, cy, rx, ry, c):
        for j in range(int(cy - ry - 1), int(cy + ry + 2)):
            for i in range(int(cx - rx - 1), int(cx + rx + 2)):
                if ((i - cx) / max(rx, .5)) ** 2 + ((j - cy) / max(ry, .5)) ** 2 <= 1.05:
                    self.px(i, j, c)

    def ring(self, cx, cy, r, c):
        for j in range(int(cy - r - 1), int(cy + r + 2)):
            for i in range(int(cx - r - 1), int(cx + r + 2)):
                d = ((i - cx) ** 2 + (j - cy) ** 2) ** .5
                if abs(d - r) < 0.55:
                    self.px(i, j, c)

    def tri(self, pts, c):
        (x0, y0), (x1, y1), (x2, y2) = pts
        minx, maxx = int(min(x0, x1, x2)), int(max(x0, x1, x2))
        miny, maxy = int(min(y0, y1, y2)), int(max(y0, y1, y2))

        def s(ax, ay, bx, by, px_, py_):
            return (bx - ax) * (py_ - ay) - (by - ay) * (px_ - ax)
        for j in range(miny, maxy + 1):
            for i in range(minx, maxx + 1):
                a = s(x0, y0, x1, y1, i, j)
                b = s(x1, y1, x2, y2, i, j)
                cc = s(x2, y2, x0, y0, i, j)
                if (a >= 0 and b >= 0 and cc >= 0) or (a <= 0 and b <= 0 and cc <= 0):
                    self.px(i, j, c)

    def outline(self, c='k', skip=('x',)):
        """Contorno de 1px em volta de tudo que não é transparente (com sombreamento cel antes)."""
        if getattr(self, 'auto_cel', True):
            self.cel()
        self.ox, self.oy = 0, 0
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.p[y][x] is None:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        n = self.get(x + dx, y + dy)
                        if n is not None and n not in skip and n != c:
                            add.append((x, y))
                            break
        for x, y in add:
            self.p[y][x] = c
        return self

    def cel(self, light=True, dark=True):
        """Sombreamento estilo cel: brilho na borda de cima/esquerda, sombra na de baixo/direita."""
        self.ox, self.oy = 0, 0
        new = [row[:] for row in self.p]
        for y in range(self.h):
            for x in range(self.w):
                v = self.p[y][x]
                if v not in RAMP:
                    continue
                up, lf = self.get(x, y - 1), self.get(x - 1, y)
                dn, rt = self.get(x, y + 1), self.get(x + 1, y)
                if dark and (dn is None or rt is None):
                    new[y][x] = RAMP[v][0]
                elif light and (up is None or lf is None):
                    new[y][x] = RAMP[v][1]
        self.p = new
        return self

    def shade_bottom(self, light, dark, rows=2):
        """Escurece as últimas linhas de cada coluna de uma cor."""
        for x in range(self.w):
            cnt = 0
            for y in range(self.h - 1, -1, -1):
                if self.p[y][x] == light:
                    if cnt < rows:
                        self.p[y][x] = dark
                    cnt += 1
                elif self.p[y][x] is not None:
                    cnt = 0
        return self

    def flip(self):
        c = Can(self.w, self.h)
        c.p = [row[::-1] for row in self.p]
        return c

    def paste(self, o, ox, oy):
        ox -= self.ox
        oy -= self.oy
        for y in range(o.h):
            for x in range(o.w):
                if o.p[y][x] is not None:
                    self.px(ox + x, oy + y, o.p[y][x])
        return self

    def copy(self):
        c = Can(self.w, self.h)
        c.p = [row[:] for row in self.p]
        return c

    def recolor(self, m):
        for y in range(self.h):
            for x in range(self.w):
                v = self.p[y][x]
                if v in m:
                    self.p[y][x] = m[v]
        return self

    def img(self, scale=1):
        im = Image.new('RGBA', (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                v = self.p[y][x]
                if v is None:
                    continue
                if isinstance(v, tuple):
                    im.putpixel((x, y), v if len(v) == 4 else v + (255,))
                else:
                    im.putpixel((x, y), PAL[v] + (255,))
        if scale != 1:
            im = im.resize((self.w * scale, self.h * scale), Image.NEAREST)
        return im

    def save(self, path):
        self.img().save(path)


def grid(rows, extra=None):
    """Cria uma tela a partir de linhas de texto (cada char é uma cor da paleta, '.' = vazio)."""
    h = len(rows)
    w = max(len(r) for r in rows)
    c = Can(w, h)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != '.' and ch != ' ':
                c.p[y][x] = (extra or {}).get(ch, ch)
    return c
