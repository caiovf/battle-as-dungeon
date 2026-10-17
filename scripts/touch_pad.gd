extends Control
## Controle virtual da luta do guardião, no estilo dos MOBAs de celular:
## - analógico flutuante na metade esquerda (aparece onde o polegar encosta);
## - botão grande de ataque no canto direito, com pular, dash e as 3 habilidades em arco;
## - tudo semitransparente por cima da arena, com recarga girando no próprio botão.
## Funciona com vários dedos ao mesmo tempo e também com o mouse.

const D = preload("res://scripts/data.gd")
const Art = preload("res://scripts/art.gd")

const JOY_R := 70.0          # raio do analógico
const DEAD := 0.28           # zona morta horizontal
const JUMP_FLICK := 0.72     # empurrar o analógico para cima também pula
const ALPHA := 0.55          # transparência geral (0 a 1)

var game
var buttons: Array = []      # {id, action, pos, r, icon, label, skill}
var fingers := {}            # índice do dedo -> id do botão ou "joy"
var joy_home := Vector2.ZERO
var joy_base := Vector2.ZERO
var joy_knob := Vector2.ZERO
var joy_finger := -1
var joy_up_latched := false
var pressed_ids := {}
var pause_rect := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func setup() -> void:
	var vs = get_viewport_rect().size
	var u: float = clampf(minf(vs.x / 1280.0, vs.y / 720.0), 0.8, 1.6)   # escala dos controles
	var g: String = game.guardian
	var sks: Array = D.CLASSES[g][game.g_cls].skills
	var atk = Vector2(vs.x - 118 * u, vs.y - 112 * u)
	buttons = []
	buttons.append({"id": "atk", "action": "g_atk", "pos": atk, "r": 60.0 * u, "icon": "ui/atk_%s_%d" % [g, game.g_cls], "label": "", "skill": -1})
	buttons.append({"id": "jump", "action": "g_jump", "pos": atk + _polar(200, 150) * u, "r": 44.0 * u, "icon": "ui/jump", "label": "", "skill": -1})
	buttons.append({"id": "dash", "action": "g_dash", "pos": atk + _polar(155, 140) * u, "r": 34.0 * u, "icon": "ui/dash", "label": "", "skill": -1})
	for i in 3:
		var ang: float = [232.0, 262.0, 292.0][i]
		buttons.append({"id": "s%d" % i, "action": "g_s%d" % i, "pos": atk + _polar(ang, 168) * u, "r": 36.0 * u,
			"icon": "ui/sk_" + sks[i], "label": D.SKILLS[sks[i]].nome.get_slice(" ", 0), "skill": i})
	joy_home = Vector2(150 * u, vs.y - 130 * u)
	joy_base = joy_home
	joy_knob = joy_home
	pause_rect = Rect2(vs.x - 70 * u, 96, 56 * u, 40 * u)
	release_all()


static func _polar(deg: float, dist: float) -> Vector2:
	var a = deg_to_rad(deg)
	return Vector2(cos(a), sin(a)) * dist


func release_all() -> void:
	for a in ["g_left", "g_right", "g_jump", "g_atk", "g_dash", "g_s0", "g_s1", "g_s2"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)
	fingers = {}
	pressed_ids = {}
	joy_finger = -1
	joy_base = joy_home
	joy_knob = joy_home


# ===== toques =====
func _input(event: InputEvent) -> void:
	if not visible or game == null or game.paused or game.phase != "arena":
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			if pause_rect.has_point(p):
				game.ui.toggle_pause()
				get_viewport().set_input_as_handled()
				return
			var b = _hit(p)
			if b != null:
				fingers[event.index] = b.id
				pressed_ids[b.id] = true
				Input.action_press(b.action)
				get_viewport().set_input_as_handled()
			elif p.x < get_viewport_rect().size.x * 0.5 and joy_finger == -1:
				joy_finger = event.index
				fingers[event.index] = "joy"
				var vs = get_viewport_rect().size
				joy_base = Vector2(clampf(p.x, JOY_R + 10, vs.x * 0.5 - JOY_R), clampf(p.y, 120 + JOY_R, vs.y - JOY_R - 10))
				_move_joy(p)
				get_viewport().set_input_as_handled()
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		if event.index == joy_finger:
			_move_joy(event.position)
			get_viewport().set_input_as_handled()


func _hit(p: Vector2):
	var best = null
	var bd = 1e9
	for b in buttons:
		var d: float = p.distance_to(b.pos)
		if d <= b.r + 14 and d < bd:
			bd = d
			best = b
	return best


func _release(index: int) -> void:
	if not fingers.has(index):
		return
	var id: String = fingers[index]
	fingers.erase(index)
	if id == "joy":
		joy_finger = -1
		joy_base = joy_home
		joy_knob = joy_home
		joy_up_latched = false
		Input.action_release("g_left")
		Input.action_release("g_right")
		if not pressed_ids.has("jump"):
			Input.action_release("g_jump")
		return
	pressed_ids.erase(id)
	for b in buttons:
		if b.id == id:
			Input.action_release(b.action)


func _move_joy(p: Vector2) -> void:
	var v = p - joy_base
	if v.length() > JOY_R:
		v = v.normalized() * JOY_R
	joy_knob = joy_base + v
	var n = v / JOY_R
	_set_action("g_left", n.x < -DEAD)
	_set_action("g_right", n.x > DEAD)
	# empurrar para cima pula (uma vez por empurrão)
	if n.y < -JUMP_FLICK and not joy_up_latched:
		joy_up_latched = true
		Input.action_press("g_jump")
	elif n.y > -JUMP_FLICK * 0.6 and joy_up_latched:
		joy_up_latched = false
		if not pressed_ids.has("jump"):
			Input.action_release("g_jump")


func _set_action(a: String, on: bool) -> void:
	if on and not Input.is_action_pressed(a):
		Input.action_press(a)
	elif not on and Input.is_action_pressed(a):
		Input.action_release(a)


# ===== desenho =====
func _process(_d: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if game == null or buttons.is_empty():
		return
	var f = Art.font()
	var white = Color(1, 1, 1, ALPHA)
	# analógico
	var active = joy_finger != -1
	draw_circle(joy_base, JOY_R + 14, Color(0.08, 0.05, 0.11, 0.28 if active else 0.16))
	draw_arc(joy_base, JOY_R + 14, 0, TAU, 48, Color(1, 1, 1, 0.45 if active else 0.22), 3)
	for i in 4:
		var a = i * PI / 2
		var tip = joy_base + Vector2(cos(a), sin(a)) * (JOY_R + 4)
		draw_circle(tip, 3, Color(1, 1, 1, 0.3))
	draw_circle(joy_knob, 34, Color(1, 1, 1, 0.35 if active else 0.2))
	draw_arc(joy_knob, 34, 0, TAU, 32, Color(1, 1, 1, 0.7 if active else 0.35), 3)
	if not active:
		draw_string(f, joy_base + Vector2(-60, JOY_R + 34), "ANDAR / PULAR", HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color(1, 1, 1, 0.35))
	# botões
	for b in buttons:
		var on: bool = pressed_ids.has(b.id)
		var r: float = b.r * (0.92 if on else 1.0)
		var ready = 1.0
		var secs = 0.0
		if b.skill >= 0:
			ready = game.arena.cd_ratio(b.skill)
			secs = maxf(0.0, game.arena.P.cd[b.skill]) if not game.arena.P.is_empty() else 0.0
		elif b.id == "dash" and not game.arena.P.is_empty():
			var cdv: float = game.arena.P.dash_cd
			var mx: float = D.GUARDS[game.guardian].dash.cd
			ready = 1.0 - clampf(cdv / mx, 0.0, 1.0) if cdv > 0 else 1.0
		draw_circle(b.pos, r, Color(0.08, 0.05, 0.11, 0.42 if on else 0.3))
		var ring = Color(1, 0.77, 0.19, 0.85) if b.id == "atk" else (Color(0.38, 0.85, 0.96, 0.75) if b.skill >= 0 else Color(1, 1, 1, 0.55))
		if on:
			ring = Color(1, 1, 1, 0.95)
		draw_arc(b.pos, r, 0, TAU, 40, ring, 4 if b.id == "atk" else 3)
		var t = Art.tex(b.icon)
		if t:
			var isz = r * (1.05 if b.id == "atk" else 1.15)
			var mod = Color(1, 1, 1, 0.9 if ready >= 1 else 0.4)
			draw_texture_rect(t, Rect2(b.pos - Vector2(isz, isz) / 2.0, Vector2(isz, isz)), false, mod)
		# recarga: fatia escura que diminui girando, com os segundos no meio
		if ready < 1.0:
			var pts = PackedVector2Array([b.pos])
			var start = -PI / 2 + TAU * ready
			var steps = 24
			for i in steps + 1:
				var a = start + (TAU * (1.0 - ready)) * i / steps
				pts.append(b.pos + Vector2(cos(a), sin(a)) * (r - 2))
			if pts.size() >= 3:
				draw_colored_polygon(pts, Color(0.05, 0.03, 0.08, 0.6))
			if secs > 0.05:
				var txt = str(int(ceil(secs)))
				draw_string_outline(f, b.pos + Vector2(-30, 6), txt, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, 5, Color(0.05, 0.03, 0.08, 0.9))
				draw_string(f, b.pos + Vector2(-30, 6), txt, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, Color.WHITE)
		if b.skill >= 0:
			# nível da habilidade: pontinhos na borda de baixo
			var lv: int = game.sk_level(D.CLASSES[game.guardian][game.g_cls].skills[b.skill])
			for k in lv:
				var px = b.pos + Vector2((k - (lv - 1) / 2.0) * 9, r - 6)
				draw_rect(Rect2(px - Vector2(3, 3), Vector2(6, 6)), Color(1, 0.77, 0.19, 0.95))
	# pausa
	draw_rect(pause_rect, Color(0.08, 0.05, 0.11, 0.35))
	draw_rect(pause_rect, white, false, 2)
	var c = pause_rect.get_center()
	draw_rect(Rect2(c.x - 9, c.y - 9, 6, 18), white)
	draw_rect(Rect2(c.x + 3, c.y - 9, 6, 18), white)
	# dica de teclado em computador
	if not DisplayServer.is_touchscreen_available():
		draw_string_outline(f, Vector2(0, size.y - 14), "Teclado: A/D andar · W pular · J atacar · K dash · U I O habilidades · P pausa", HORIZONTAL_ALIGNMENT_CENTER, size.x, 8, 4, Color(0.05, 0.03, 0.08, 0.8))
		draw_string(f, Vector2(0, size.y - 14), "Teclado: A/D andar · W pular · J atacar · K dash · U I O habilidades · P pausa", HORIZONTAL_ALIGNMENT_CENTER, size.x, 8, Color(1, 1, 1, 0.5))
