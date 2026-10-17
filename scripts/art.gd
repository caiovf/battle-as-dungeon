extends RefCounted
## Desenho com a pixel art de res://art (gerada por tools/gen_art.py).
## Todo sprite é desenhado em escala inteira (×2 por padrão) com filtro "nearest".

const D = preload("res://scripts/data.gd")
const PX := 2.0   # cada pixel da arte vira 2 unidades do mundo

static var _font: Font
static var _tex := {}
static var _icons := {}
static var _meta := {}
static var off := Vector2.ZERO   # deslocamento (tremida) do canvas atual


static func font() -> Font:
	if _font == null:
		if ResourceLoader.exists("res://fonts/PressStart2P.woff2"):
			_font = load("res://fonts/PressStart2P.woff2")
		else:
			_font = ThemeDB.fallback_font
	return _font


static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var p = "res://art/%s.png" % name
		_tex[name] = load(p) if ResourceLoader.exists(p) else null
	return _tex[name]


static func meta(name: String) -> Dictionary:
	if _meta.is_empty():
		var f = FileAccess.open("res://art/meta.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_meta = d
	return _meta.get(name, {"w": 16, "h": 16, "ax": 8, "ay": 16})


## Ícone para botões da interface (ampliado sem borrar).
static func icon(name: String, scale := 2) -> Texture2D:
	var k = "%s@%d" % [name, scale]
	if not _icons.has(k):
		var t = tex(name)
		if t == null:
			_icons[k] = null
		else:
			var img = t.get_image()
			if img.is_compressed():
				img.decompress()
			img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
			_icons[k] = ImageTexture.create_from_image(img)
	return _icons[k]


## Sprite com âncora nos pés (x = centro do corpo, y = chão).
static func spr(g: CanvasItem, name: String, x: float, y: float, scale := PX, flip := false, mod := Color.WHITE) -> void:
	var t = tex(name)
	if t == null:
		return
	var m = meta(name)
	g.draw_set_transform(off + Vector2(round(x), round(y)), 0.0, Vector2(-scale if flip else scale, scale))
	g.draw_texture(t, Vector2(-float(m.ax), -float(m.ay)), mod)
	g.draw_set_transform(off)


## Sprite centrado num ponto (armadilhas, projéteis), com rotação opcional.
static func spr_c(g: CanvasItem, name: String, x: float, y: float, scale := PX, rot := 0.0, mod := Color.WHITE, flip := false) -> void:
	var t = tex(name)
	if t == null:
		return
	g.draw_set_transform(off + Vector2(round(x), round(y)), rot, Vector2(-scale if flip else scale, scale))
	g.draw_texture(t, -t.get_size() / 2.0, mod)
	g.draw_set_transform(off)


## Sprite esticado num retângulo (tiles, cenário, plataformas).
static func spr_r(g: CanvasItem, name: String, r: Rect2, mod := Color.WHITE) -> void:
	var t = tex(name)
	if t:
		g.draw_texture_rect(t, r, false, mod)


static func height(name: String) -> float:
	return float(meta(name).ay)


static func text(g: CanvasItem, p: Vector2, s: String, c: Color, size := 15, outline := true) -> void:
	size = maxi(8, int(round(size * 0.62)))
	var f = font()
	var w = 600.0
	var pos = Vector2(p.x - w / 2.0, p.y + size * 0.35)
	if outline:
		g.draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_CENTER, w, size, 5, Color(0.08, 0.05, 0.11, c.a))
	g.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_CENTER, w, size, c)


static func text_left(g: CanvasItem, p: Vector2, s: String, c: Color, size := 12, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	size = maxi(8, int(round(size * 0.62)))
	var f = font()
	var w = 300.0
	var x = p.x if align == HORIZONTAL_ALIGNMENT_LEFT else p.x - w
	g.draw_string_outline(f, Vector2(x, p.y + size), s, align, w, size, 4, Color(0.08, 0.05, 0.11, c.a))
	g.draw_string(f, Vector2(x, p.y + size), s, align, w, size, c)


static func ellipse(g: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx <= 0 or ry <= 0:
		return
	var pts = PackedVector2Array()
	for i in 16:
		var a = i / 16.0 * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	g.draw_colored_polygon(pts, col)


static func tri(g: CanvasItem, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	if absf((b - a).cross(c - a)) < 0.01:
		return
	g.draw_colored_polygon(PackedVector2Array([a, b, c]), col)


## Quadradinho de pixel (partículas e efeitos).
static func dot(g: CanvasItem, p: Vector2, size: float, col: Color) -> void:
	var s = maxf(PX, round(size / PX) * PX)
	g.draw_rect(Rect2(round(p.x - s / 2), round(p.y - s / 2), s, s), col)


# ===== nomes dos sprites =====
static func trap_name(k: String, opened := false) -> String:
	if k == "fogo":
		return "traps/fogo_%d" % (int(Time.get_ticks_msec() / 180) % 2)
	if k == "alcapao" and opened:
		return "traps/alcapao_aberto"
	return "traps/" + k


static func mon_name(k: String, sprung := false) -> String:
	if k == "morcego":
		return "mon/morcego_%d" % (int(Time.get_ticks_msec() / 140) % 2)
	if k == "mimico" and sprung:
		return "mon/mimico_aberto"
	return "mon/" + k


static func icon_name(k: String) -> String:
	if D.TOOLS[k].kind == "trap":
		return "traps/fogo_0" if k == "fogo" else "traps/" + k
	return "mon/morcego_0" if k == "morcego" else "mon/" + k


# ===== compatibilidade: ícone centrado (armadilha ou monstro) =====
static func draw_icon(g: CanvasItem, k: String, cx: float, cy: float, a := 1.0, sc := 1.0) -> void:
	var mod = Color(1, 1, 1, a)
	if D.TOOLS[k].kind == "trap":
		spr_c(g, trap_name(k), cx, cy, PX, 0.0, mod)
	else:
		spr(g, mon_name(k, sc < 0), cx, cy + 14, PX * absf(sc), false, mod)


static func draw_guard(g: CanvasItem, k: String, x: float, y: float, s: float, face: int, flash: bool, frame := "idle0") -> void:
	spr(g, "arena/%s_%s" % [k, frame], x, y, PX * s, face < 0, Color(8, 8, 8) if flash else Color.WHITE)


static func draw_legend(g: CanvasItem, k: String, x: float, y: float, face: int, flash: bool, frame := "idle0") -> void:
	spr(g, "arena/%s_%s" % [k, frame], x, y, PX, face < 0, Color(8, 8, 8) if flash else Color.WHITE)
