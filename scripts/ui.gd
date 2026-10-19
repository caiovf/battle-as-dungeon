extends CanvasLayer
## Interface: barra do topo, mapa, painel do que os heróis sabem, bandeja de ferramentas,
## telas de escolha, grimório e controles de toque da luta do guardião.

const D = preload("res://scripts/data.gd")
const Art = preload("res://scripts/art.gd")
const Web = preload("res://scripts/web.gd")

const C_BG := Color("#140c1c")
const C_PANEL := Color("#241a2e")
const C_LINE := Color("#4e425a")
const C_FG := Color("#ece2d2")
const C_MUTE := Color("#9a8e7f")
const C_BRASS := Color("#ffc430")
const C_EMBER := Color("#ff5a48")
const C_MOSS := Color("#96e65a")
const C_ICE := Color("#60d8f4")

var game
var root: Control
var board_holder: Control
var top: HBoxContainer
var clock_lbl: Label
var chips := {}
var hint_box: PanelContainer
var hint_lbl: Label
var hint_t := 0.0
var pause_lbl: Label
var know_panel: PanelContainer
var know_flow: HFlowContainer
var know_sig := ""
var duel_flow: HFlowContainer
var duel_box: VBoxContainer
var duel_sep: Separator
var guard_btn: Button
var gbtn_flash := 0.0
var cls_modal: Control
var cls_box: VBoxContainer
var dock: PanelContainer
var bell_btn: Button
var pause_btn: Button
var speed_btn: Button
var tab_traps: Button
var tab_mon: Button
var sel_lbl: Label
var trap_grid: GridContainer
var mon_grid: GridContainer
var dock_tab := "traps"
var bench_cost: Array = []   # [Button, Callable]
var overlay: Control
var ov_title: Label
var ov_text: Label
var ov_extra: Label
var ov_cards: HFlowContainer
var ov_btn: Button
var grim: Control
var grim_box: VBoxContainer
var grim_ess: Label
var reset_armed := false
var pad: Control
var fonts := {}
var arena_mode := false
var rotated := false       # celular em pé: o jogo está desenhado girado
var mobile := false        # celular: layout compacto, mapa grande e aviso para deitar o aparelho
var rotate_box: Control
var last_dock_h := 0.0
var poll_t := 0.0
var last_fs := false
var fs_btn: Button


func _font(n: String) -> Font:
	if fonts.has(n):
		return fonts[n]
	var p = "res://fonts/%s" % n
	var f: Font = null
	if ResourceLoader.exists(p):
		f = load(p)
	fonts[n] = f
	return f


func _sb(bg: Color, border := C_LINE, radius := 3, bw := 2, pad := 8) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	return s


func _make_theme() -> Theme:
	var th = Theme.new()
	var body = _font("AlegreyaSans-Medium.woff2")
	if body:
		th.default_font = body
	th.default_font_size = 17
	th.set_color("font_color", "Label", C_FG)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var bg = C_BG
		var br = C_LINE
		match st:
			"hover": br = C_BRASS
			"pressed": bg = Color("#2a2118"); br = C_BRASS
			"disabled": bg = Color("#141110"); br = Color("#2a241f")
			"focus":
				var f = StyleBoxFlat.new()
				f.draw_center = false
				f.border_color = Color(C_BRASS, 0.6)
				f.set_border_width_all(2)
				f.set_corner_radius_all(8)
				th.set_stylebox("focus", "Button", f)
				continue
		th.set_stylebox(st, "Button", _sb(bg, br))
	th.set_color("font_color", "Button", C_FG)
	th.set_color("font_hover_color", "Button", C_FG)
	th.set_color("font_pressed_color", "Button", C_BRASS)
	th.set_color("font_disabled_color", "Button", Color("#5a5048"))
	th.set_stylebox("panel", "PanelContainer", _sb(C_PANEL, C_LINE, 8, 1, 10))
	return th


func _label(text: String, size := 17, color := C_FG, font := "") -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font != "" and _font(font):
		l.add_theme_font_override("font", _font(font))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, cb: Callable, size := 16) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


func _swatch(c: Color) -> ImageTexture:
	var img = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)


# ===== construção =====
func build() -> void:
	mobile = Web.is_mobile() or "--mobile" in OS.get_cmdline_user_args()
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(root)
	var bg = ColorRect.new()
	bg.color = Color("#0e0814")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# topo
	top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	var cb = PanelContainer.new()
	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 4)
	cv.add_child(_label("CORAÇÃO", 8, C_MUTE, "PressStart2P.woff2"))
	clock_lbl = _label("60.0s", 24, C_FG, "PressStart2P.woff2")
	cv.add_child(clock_lbl)
	cb.add_child(cv)
	top.add_child(cb)
	for k in [["wave", "Onda"], ["combo", "Combo"], ["event", "Evento"], ["fame", "Fama"], ["evo", "Guardião"], ["rate", "Relógio"], ["kills", "Abates"]]:
		var p = PanelContainer.new()
		var v = VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		v.add_child(_label(k[1].to_upper(), 8, C_MUTE, "PressStart2P.woff2"))
		var val = _label("–", 12, C_FG, "PressStart2P.woff2")
		v.add_child(val)
		p.add_child(v)
		top.add_child(p)
		chips[k[0]] = {"panel": p, "val": val}
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp)
	guard_btn = _button("Guardião", show_classes, 16)
	guard_btn.add_theme_color_override("font_color", C_ICE)
	guard_btn.visible = false
	top.add_child(guard_btn)
	fs_btn = _button("Tela cheia", toggle_fullscreen, 14)
	top.add_child(fs_btn)
	var gb = _button("Grimório", show_grim, 20)
	gb.name = "GrimBtn"
	if _font("PixelifySans-SemiBold.woff2"):
		gb.add_theme_font_override("font", _font("PixelifySans-SemiBold.woff2"))
	gb.add_theme_color_override("font_color", C_BRASS)
	top.add_child(gb)

	# mapa
	board_holder = Control.new()
	board_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_holder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	board_holder.clip_contents = true
	root.add_child(board_holder)
	var frame = Panel.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs = _sb(Color(0, 0, 0, 0), C_LINE, 6, 1)
	fs.draw_center = false
	frame.add_theme_stylebox_override("panel", fs)
	root.add_child(frame)

	hint_box = PanelContainer.new()
	hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_box.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.05, 0.04, 0.93), C_LINE, 8, 1, 12))
	hint_lbl = _label("", 15)
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_box.add_child(hint_lbl)
	hint_box.visible = false
	root.add_child(hint_box)
	pause_lbl = _label("Pausado", 46, C_FG, "PixelifySans-SemiBold.woff2")
	pause_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_lbl.visible = false
	root.add_child(pause_lbl)

	# o que os heróis sabem (embaixo do mapa)
	know_panel = PanelContainer.new()
	var ks = _sb(C_PANEL, C_LINE, 8, 1, 10)
	ks.border_width_left = 3
	ks.border_color = C_LINE
	know_panel.add_theme_stylebox_override("panel", ks)
	var kh = BoxContainer.new()
	kh.vertical = mobile
	kh.add_theme_constant_override("separation", 6 if mobile else 12)
	know_panel.clip_contents = true
	var kv = VBoxContainer.new()
	kv.add_theme_constant_override("separation", 4)
	kv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kv.size_flags_stretch_ratio = 1.25
	kv.add_child(_label("O que os heróis sabem da masmorra", 14 if mobile else 17, C_FG, "PixelifySans-SemiBold.woff2"))
	know_flow = HFlowContainer.new()
	know_flow.add_theme_constant_override("h_separation", 8)
	know_flow.add_theme_constant_override("v_separation", 6)
	kv.add_child(know_flow)
	kh.add_child(kv)
	duel_sep = HSeparator.new() if mobile else VSeparator.new()
	kh.add_child(duel_sep)
	duel_box = VBoxContainer.new()
	duel_box.add_theme_constant_override("separation", 4)
	duel_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duel_box.add_child(_label("O que os lendários sabem do guardião", 14 if mobile else 17, C_ICE, "PixelifySans-SemiBold.woff2"))
	duel_flow = HFlowContainer.new()
	duel_flow.add_theme_constant_override("h_separation", 8)
	duel_flow.add_theme_constant_override("v_separation", 6)
	duel_box.add_child(duel_flow)
	kh.add_child(duel_box)
	know_panel.add_child(kh)
	root.add_child(know_panel)

	# bandeja
	dock = PanelContainer.new()
	var dv = VBoxContainer.new()
	dv.add_theme_constant_override("separation", 8)
	dock.add_child(dv)
	var acts = HBoxContainer.new()
	acts.add_theme_constant_override("separation", 6)
	bell_btn = _button("Badalada", func(): game.bell())
	bell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bell_btn.add_theme_color_override("font_color", C_ICE)
	pause_btn = _button("Pausar", toggle_pause)
	speed_btn = _button("1×", func():
		game.speed = 2 if game.speed == 1 else (3 if game.speed == 2 else 1))
	for b in [bell_btn, pause_btn, speed_btn]:
		b.custom_minimum_size.y = 48
		acts.add_child(b)
	dv.add_child(acts)
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	tab_traps = _button("Armadilhas", func(): set_tab("traps"))
	tab_mon = _button("Monstros", func(): set_tab("mon"))
	for b in [tab_traps, tab_mon]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		tabs.add_child(b)
	dv.add_child(tabs)
	sel_lbl = _label("", 14, C_MUTE)
	sel_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(sel_lbl)
	trap_grid = GridContainer.new()
	trap_grid.columns = 2
	trap_grid.add_theme_constant_override("h_separation", 6)
	trap_grid.add_theme_constant_override("v_separation", 6)
	dv.add_child(trap_grid)
	mon_grid = GridContainer.new()
	mon_grid.columns = 2
	mon_grid.add_theme_constant_override("h_separation", 6)
	mon_grid.add_theme_constant_override("v_separation", 6)
	dv.add_child(mon_grid)
	root.add_child(dock)

	_build_pad()
	_build_overlay()
	_build_grim()
	_build_classes()
	_build_rotate()
	get_viewport().size_changed.connect(layout)
	set_tab("traps")


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim = ColorRect.new()
	dim.color = Color(0.043, 0.035, 0.027, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var sc = ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(sc)
	var cc = CenterContainer.new()
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_child(cc)
	var v = VBoxContainer.new()
	v.custom_minimum_size.x = 900
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(v)
	ov_title = _label("", 40, C_BRASS, "PixelifySans-SemiBold.woff2")
	ov_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ov_title)
	ov_text = _label("", 18, C_MUTE)
	ov_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ov_text)
	ov_extra = _label("", 17, C_FG)
	ov_extra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov_extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ov_extra)
	ov_cards = HFlowContainer.new()
	ov_cards.alignment = FlowContainer.ALIGNMENT_CENTER
	ov_cards.add_theme_constant_override("h_separation", 12)
	ov_cards.add_theme_constant_override("v_separation", 12)
	v.add_child(ov_cards)
	var bc = CenterContainer.new()
	ov_btn = _button("", func(): pass, 20)
	ov_btn.custom_minimum_size = Vector2(240, 54)
	bc.add_child(ov_btn)
	v.add_child(bc)
	overlay.visible = false
	root.add_child(overlay)


func _card(tag: String, title: String, desc: String, cb: Callable, tag_color := C_BRASS, legend := false, pic: Texture2D = null) -> Button:
	var b = Button.new()
	b.custom_minimum_size = Vector2(250, 170)
	b.focus_mode = Control.FOCUS_NONE
	if legend:
		b.add_theme_stylebox_override("normal", _sb(Color("#241b10"), C_BRASS, 8, 2))
	var m = MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 14)
	var v = VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 6)
	v.add_child(_label(tag.to_upper(), 8, tag_color, "PressStart2P.woff2"))
	if pic:
		var tr = TextureRect.new()
		tr.texture = pic
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tr.custom_minimum_size = Vector2(0, pic.get_height() + 4)
		v.add_child(tr)
	var t = _label(title, 20, C_FG)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var d = _label(desc, 15, C_MUTE)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	m.add_child(v)
	b.add_child(m)
	b.pressed.connect(cb)
	return b


func _show_overlay(title: String, text: String, extra := "", btn_text := "", btn_cb := Callable()) -> void:
	ov_title.text = title
	ov_text.text = text
	ov_text.visible = text != ""
	ov_extra.text = extra
	ov_extra.visible = extra != ""
	for c in ov_cards.get_children():
		c.queue_free()
	for con in ov_btn.pressed.get_connections():
		ov_btn.pressed.disconnect(con.callable)
	ov_btn.get_parent().visible = btn_text != ""
	if btn_text != "":
		ov_btn.text = btn_text
		ov_btn.pressed.connect(btn_cb)
	overlay.visible = true


func hide_overlays() -> void:
	overlay.visible = false
	grim.visible = false


func show_intro() -> void:
	_show_overlay("O relógio não para", "Você é a masmorra. Os heróis estudam como você joga nesta partida e mudam de estratégia para te vencer. Varie. Escolha uma armadilha na bandeja e toque no mapa; solte monstros pela aba Monstros. Todo herói derrotado tem a energia absorvida pelo coração.", "", "Começar run", func(): game.begin())


func show_draft(pick: Array, rumor: String) -> void:
	_show_overlay("Onda vencida", "Escolha uma relíquia. A masmorra muda e a próxima onda entra.", rumor)
	if rumor != "":
		ov_extra.add_theme_color_override("font_color", C_BRASS)
	for c in pick:
		var cc: Dictionary = c
		ov_cards.add_child(_card(cc.tag, cc.t, cc.d, func():
			overlay.visible = false
			game.pick_card(cc), C_BRASS, cc.get("lendaria", false)))


func show_guard_pick() -> void:
	_show_overlay("A masmorra cria a sala do guardião", "Um herói lendário está vindo. Se ele chegar ao coração, você controla o guardião numa luta de ação. A vida do guardião é o tempo do relógio.")
	for k in D.GUARD_ORDER:
		var G = D.GUARDS[k]
		var c0 = D.CLASSES[k][0]
		var lines = [G.desc]
		for i in 3:
			var sk = D.SKILLS[c0.skills[i]]
			lines.append("%d. %s: %s" % [i + 1, sk.nome, sk.desc])
		var nomes = []
		for c in D.CLASSES[k].slice(1):
			nomes.append(c.nome)
		lines.append("Evolui para: " + ", ".join(nomes) + ".")
		var kk: String = k
		var b = _card("Guardião", G.nome, "\n".join(lines), func():
			overlay.visible = false
			game.pick_guardian(kk), C_BRASS, false, Art.icon("arena/%s_0_idle0" % kk, 3))
		b.custom_minimum_size = Vector2(290, 440)
		ov_cards.add_child(b)


func show_reward(title: String, text: String, opts: Array) -> void:
	_show_overlay(title, text)
	for o in opts:
		var oo: Dictionary = o
		ov_cards.add_child(_card(oo.tag, oo.t, oo.d, func():
			overlay.visible = false
			game.arena.finish_reward(oo), C_MOSS if oo.get("green", false) else C_BRASS))


func show_over(text: String) -> void:
	_show_overlay("O coração parou", text, "Na próxima run tudo recomeça: os heróis esquecem o que aprenderam e você monta um set novo do zero.", "Nova run", func(): game.after_run())


func modal_open() -> bool:
	return grim.visible or cls_modal.visible or rotate_box.visible


## Aviso para deitar o celular (o jogo é só paisagem).
func _build_rotate() -> void:
	rotate_box = Control.new()
	rotate_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotate_box.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg = ColorRect.new()
	bg.color = Color("#0e0814")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotate_box.add_child(bg)
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotate_box.add_child(cc)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(v)
	var ic = TextureRect.new()
	ic.texture = Art.icon("tiles/heart", 6)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)
	var t = _label("Deite o celular", 44, C_BRASS, "PixelifySans-SemiBold.woff2")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var d = _label("A Masmorra Relógio é jogada na horizontal.", 22, C_MUTE)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 260
	v.add_child(d)
	rotate_box.visible = false
	root.add_child(rotate_box)


# ===== classes do guardião (estilo Grand Chase) =====
func _build_classes() -> void:
	cls_modal = Control.new()
	cls_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	cls_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.024, 0.02, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	cls_modal.add_child(dim)
	var p = PanelContainer.new()
	p.name = "Box"
	p.add_theme_stylebox_override("panel", _sb(C_PANEL, C_ICE, 10, 1, 14))
	cls_modal.add_child(p)
	cls_box = VBoxContainer.new()
	cls_box.add_theme_constant_override("separation", 10)
	p.add_child(cls_box)
	cls_modal.visible = false
	root.add_child(cls_modal)


func show_classes() -> void:
	if game.guardian == "":
		return
	render_classes()
	cls_modal.visible = true
	layout()
	get_tree().create_timer(0.05).timeout.connect(layout)


func close_classes() -> void:
	cls_modal.visible = false


func flash_guard_btn() -> void:
	gbtn_flash = 6.0


func render_classes() -> void:
	for c in cls_box.get_children():
		c.queue_free()
	var g: String = game.guardian
	var head = HBoxContainer.new()
	var hv = VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(_label("Classes do %s" % D.GUARDS[g].nome, 28, C_FG, "PixelifySans-SemiBold.woff2"))
	var sub = _label("Evolução do guardião: +%s. Cada classe muda arma, ataque, movimento e habilidades.%s" % [D.pct(game.evo), " Troque fora da luta." if game.phase == "arena" else ""], 14, C_MUTE)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(sub)
	head.add_child(hv)
	var x = _button("Fechar", close_classes, 16)
	x.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	head.add_child(x)
	cls_box.add_child(head)
	var vs = root.get_viewport_rect().size
	var grid = GridContainer.new()
	grid.columns = 4 if vs.x >= 1100 else 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	cls_box.add_child(grid)
	for i in 4:
		var c = D.CLASSES[g][i]
		var open: bool = game.class_open(i)
		var cur: bool = game.g_cls == i
		var b = PanelContainer.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col = C_ICE if cur else (C_BRASS if open else C_LINE)
		b.add_theme_stylebox_override("panel", _sb(Color("#1d2430") if cur else (Color("#241b10") if open else C_BG), col, 8, 2 if cur else 1, 10))
		var v = VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 4)
		var top_h = HBoxContainer.new()
		top_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tr = TextureRect.new()
		tr.texture = Art.icon("arena/%s_%d_idle0" % [g, i], 2)
		tr.custom_minimum_size = Vector2(72, 64)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not open:
			tr.modulate = Color(0.2, 0.2, 0.25)
		top_h.add_child(tr)
		var tv = VBoxContainer.new()
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm = _label(c.nome, 17, C_FG if open else C_MUTE, "PixelifySans-SemiBold.woff2")
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.custom_minimum_size.x = 120
		tv.add_child(nm)
		var stt = "ATUAL" if cur else ("LIBERADA" if open else "+%d%% DE EVOLUÇÃO" % int(D.CLASS_UNLOCK[i]))
		tv.add_child(_label(stt, 8, col, "PressStart2P.woff2"))
		top_h.add_child(tv)
		v.add_child(top_h)
		var lines = [c.estilo]
		if c.passive != "":
			lines.append("Passiva: " + D.PASSIVES[c.passive])
		var sk = []
		for k in c.skills:
			sk.append(D.SKILLS[k].nome)
		lines.append("Habilidades: " + ", ".join(sk) + ".")
		var d = _label("\n".join(lines), 13, C_FG if open else C_MUTE)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = 200
		d.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(d)
		var pick = _button("Classe atual" if cur else ("Escolher" if open else "Bloqueada"), func(): pass, 15)
		pick.disabled = not open or cur or game.phase == "arena"
		var ii: int = i
		pick.pressed.connect(func():
			game.set_class(ii)
			render_classes())
		v.add_child(pick)
		b.add_child(v)
		grid.add_child(b)


# ===== grimório =====
func _build_grim() -> void:
	grim = Control.new()
	grim.set_anchors_preset(Control.PRESET_FULL_RECT)
	grim.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.024, 0.02, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	grim.add_child(dim)
	var p = PanelContainer.new()
	p.name = "Box"
	p.add_theme_stylebox_override("panel", _sb(C_PANEL, C_BRASS, 10, 1, 16))
	grim.add_child(p)
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	grim_box = VBoxContainer.new()
	grim_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grim_box.add_theme_constant_override("separation", 10)
	sc.add_child(grim_box)
	grim.visible = false
	root.add_child(grim)


func show_grim() -> void:
	render_grim()
	grim.visible = true
	layout()


func close_grim() -> void:
	grim.visible = false


func render_grim() -> void:
	for c in grim_box.get_children():
		c.queue_free()
	var head = HBoxContainer.new()
	var hv = VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(_label("Grimório da masmorra", 30, C_FG, "PixelifySans-SemiBold.woff2"))
	var sub = _label("Ganhe 1 essência por onda vencida. Tudo aqui vale só para esta run%s." % ((" · %d ganha%s até agora" % [game.ess_run, "s" if game.ess_run > 1 else ""]) if game.ess_run > 0 else ""), 14, C_MUTE)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(sub)
	head.add_child(hv)
	grim_ess = _label("%d essência" % game.ess, 14, C_BRASS, "PressStart2P.woff2")
	head.add_child(grim_ess)
	head.add_child(_button("Fechar", close_grim))
	grim_box.add_child(head)
	var locked: bool = not game.in_run()
	if locked:
		grim_box.add_child(_label("Comece uma run para gastar essência. O jogo fica pausado enquanto o grimório está aberto.", 14, C_EMBER))
	grim_box.add_child(_label("Melhorias da masmorra", 20, C_FG, "PixelifySans-SemiBold.woff2"))
	var gp = GridContainer.new()
	gp.columns = 3
	gp.add_theme_constant_override("h_separation", 8)
	gp.add_theme_constant_override("v_separation", 8)
	var hidden = 0
	for p in D.PERKS:
		if not game.perk_visible(p):
			hidden += 1
			continue
		var lv: int = game.perk(p.id)
		var mx: bool = lv >= p.max
		var c: int = game.perk_cost(p)
		var pid: String = p.id
		gp.add_child(_gitem(p.nome, "%d/%d" % [lv, p.max], p.desc, "Completo" if mx else "Comprar · %d" % c, mx or locked or game.ess < c, func(): game.buy_perk(pid)))
	grim_box.add_child(gp)
	if hidden > 0:
		grim_box.add_child(_label("%d melhoria%s ainda escondida%s. Elas aparecem conforme a run avança." % [hidden, "s" if hidden > 1 else "", "s" if hidden > 1 else ""], 13, C_MUTE))
	for sec in [["Armadilhas", "trap", "Depois de liberadas, passam a aparecer como cartas de relíquia nesta run."], ["Monstros", "monster", "Depois de liberados, ficam à venda por tempo nesta run, a partir da onda indicada."]]:
		grim_box.add_child(_label(sec[0], 20, C_FG, "PixelifySans-SemiBold.woff2"))
		grim_box.add_child(_label(sec[2], 13, C_MUTE))
		var g = GridContainer.new()
		g.columns = 3
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 8)
		for k in D.TRAP_ORDER + D.MON_ORDER:
			var d = D.TOOLS[k]
			if d.kind != sec[1]:
				continue
			var free: bool = D.BASE_TOOLS.has(k) or D.FREE_POOL.has(k)
			var ok: bool = free or game.unlock.has(k)
			var extra = ""
			if d.kind == "monster":
				extra = (" Disponível a partir da onda %d por %ds." % [D.MON_UNLOCK[k].onda, D.MON_UNLOCK[k].tempo]) if D.MON_UNLOCK.has(k) else " Começa liberado."
			var desc = "%s.%s Contra: %s." % [d.desc, extra, D.HEROES[D.COUNTER[k]].nome]
			var kk: String = k
			var cst: int = D.UNLOCK_COST.get(k, 0)
			var btxt = "" if free else ("Liberado" if ok else "Liberar · %d" % cst)
			g.add_child(_gitem(d.nome, "inicial" if free else ("liberado" if ok else "bloqueado"), desc, btxt, ok or locked or game.ess < cst, func(): game.buy_unlock(kk)))
		grim_box.add_child(g)
	var rb = _button("Clique de novo para zerar" if reset_armed else "Zerar recorde e fama", _reset_meta, 14)
	grim_box.add_child(rb)


func _gitem(nome: String, lvl: String, desc: String, btn: String, disabled: bool, cb: Callable) -> Control:
	var p = PanelContainer.new()
	p.custom_minimum_size.x = 250
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v = VBoxContainer.new()
	var h = HBoxContainer.new()
	var n = _label(nome, 16, C_FG)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	h.add_child(_label(lvl, 8, C_BRASS, "PressStart2P.woff2"))
	v.add_child(h)
	var d = _label(desc, 13, C_MUTE)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 220
	v.add_child(d)
	if btn != "":
		var b = _button(btn, cb, 14)
		b.disabled = disabled
		v.add_child(b)
	p.add_child(v)
	return p


func _reset_meta() -> void:
	if not reset_armed:
		reset_armed = true
		render_grim()
		get_tree().create_timer(4.0).timeout.connect(func():
			reset_armed = false
			if grim.visible:
				render_grim())
		return
	reset_armed = false
	game.meta = {"runs": 0, "best": 0}
	game.save_meta()
	render_grim()


func refresh_all() -> void:
	if grim.visible:
		render_grim()
	render_know()
	build_bench()
	sync()


# ===== bandeja =====
func set_tab(t: String) -> void:
	dock_tab = t
	trap_grid.visible = t == "traps"
	mon_grid.visible = t == "mon"
	tab_traps.add_theme_color_override("font_color", C_BRASS if t == "traps" else C_MUTE)
	tab_mon.add_theme_color_override("font_color", C_BRASS if t == "mon" else C_MUTE)
	_sel_text()
	if mobile and root:
		layout.call_deferred()


func _sel_text() -> void:
	var st = D.TOOLS.get(game.tool) if game else null
	if dock_tab == "traps":
		if st and game.unlocked.has(game.tool):
			sel_lbl.text = "%s · toque num bloco %s. Toque numa armadilha colocada para vender." % [st.nome, "do corredor" if st.on_path else "de parede"]
		else:
			sel_lbl.text = "Escolha uma armadilha e toque no mapa."
	else:
		sel_lbl.text = "Toque num monstro para soltá-lo do coração. Evoluir vale para a run inteira."


func build_bench() -> void:
	if not game:
		return
	bench_cost = []
	for c in trap_grid.get_children():
		c.queue_free()
	for c in mon_grid.get_children():
		c.queue_free()
	for k in D.TRAP_ORDER:
		if not game.available(k):
			continue
		var d = D.TOOLS[k]
		var lock: bool = not game.unlocked.has(k)
		var kk: String = k
		var txt = "%s\n%s" % [d.nome, "ganhe numa relíquia" if lock else "%ss · %s" % [D.fmt(game.cost(k)), "corredor" if d.on_path else "parede"]]
		var b = _button(txt, func():
			game.tool = kk
			build_bench(), 14)
		b.icon = Art.icon(Art.icon_name(k), 2)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 58)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = lock
		if game.tool == k and not lock:
			b.add_theme_stylebox_override("normal", _sb(Color("#2a2118"), C_BRASS, 8, 2))
		trap_grid.add_child(b)
		if not lock:
			bench_cost.append([b, func(): return game.cost(kk)])
	for k in D.MON_ORDER:
		if not game.available(k):
			continue
		var d = D.TOOLS[k]
		var lock: bool = not game.unlocked.has(k)
		var mu = D.MON_UNLOCK.get(k)
		var early: bool = lock and mu != null and game.wave < mu.onda
		var kk: String = k
		var v = VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 4)
		if not lock:
			var b = _button("%s  nv %d\nsoltar %ss" % [d.nome, game.mon_lvl[k], D.fmt(game.cost(k))], func(): game.summon(kk), 14)
			b.icon = Art.icon(Art.icon_name(k), 2)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size.y = 52
			b.tooltip_text = d.desc
			v.add_child(b)
			var u = _button("Evoluir · %ss" % D.fmt(game.up_cost(k)), func(): game.upgrade_mon(kk), 13)
			v.add_child(u)
			bench_cost.append([b, func(): return game.cost(kk)])
			bench_cost.append([u, func(): return game.up_cost(kk)])
		elif early:
			var b = _button("%s\nna onda %d" % [d.nome, mu.onda], func(): pass, 14)
			b.icon = Art.icon(Art.icon_name(k), 2)
			b.modulate = Color(1, 1, 1, 0.5)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = true
			b.custom_minimum_size.y = 52
			v.add_child(b)
		else:
			var b = _button("%s\n%s" % [d.nome, "bloqueado"], func(): pass, 14)
			b.icon = Art.icon(Art.icon_name(k), 2)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = true
			b.custom_minimum_size.y = 52
			b.tooltip_text = d.desc
			v.add_child(b)
			var u = _button("Liberar · %ss" % D.fmt(game.unlock_cost(k)), func(): game.buy_mon(kk), 13)
			v.add_child(u)
			bench_cost.append([u, func(): return game.unlock_cost(kk)])
		mon_grid.add_child(v)
	_sel_text()


# ===== painel do que os heróis sabem =====
	if mobile and root:
		layout.call_deferred()


func render_know() -> void:
	if not game:
		return
	var items = []
	var duel_items = []
	if game.phase in ["prep", "wave", "draft", "arena", "reward"]:
		var ks = []
		for k in D.TRAP_ORDER + D.MON_ORDER:
			if int(game.kl.get(k, 0)) > 0:
				ks.append(k)
		ks.sort_custom(func(a, b): return game.kl[a] > game.kl[b])
		for k in ks:
			items.append([D.TOOLS[k].nome, int(game.kl[k]), Art.icon_name(k)])
		if game.guardian != "":
			for k in D.DUEL_KEYS:
				if game.duel[k] > 0:
					duel_items.append([D.DUEL_NAMES[k], int(game.duel[k]), ""])
	var sig = str(items) + str(duel_items) + game.guardian
	if sig == know_sig:
		return
	know_sig = sig
	for c in know_flow.get_children() + duel_flow.get_children():
		c.queue_free()
	duel_box.visible = game.guardian != ""
	duel_sep.visible = duel_box.visible
	if items.is_empty():
		know_flow.add_child(_label("Ainda observando a sua masmorra.", 15, C_MUTE))
	if duel_items.is_empty():
		duel_flow.add_child(_label("Nenhum lendário voltou para contar.", 15, C_MUTE))
	for it in items:
		know_flow.add_child(_know_chip(it))
	for it in duel_items:
		duel_flow.add_child(_know_chip(it, true))


func _know_chip(it: Array, compact := false) -> Control:
	if true:
		var lv: int = it[1]
		var col = C_MUTE if lv <= 1 else (C_BRASS if lv <= 3 else C_EMBER)
		var p = PanelContainer.new()
		p.add_theme_stylebox_override("panel", _sb(C_BG, col if lv >= 3 else C_LINE, 6, 1, 8))
		var h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		if it[2] != "":
			var tr = TextureRect.new()
			tr.texture = Art.icon(it[2], 1)
			tr.custom_minimum_size = Vector2(20, 20)
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(tr)
		else:
			var sw = ColorRect.new()
			sw.color = C_ICE
			sw.custom_minimum_size = Vector2(10, 10)
			sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(sw)
		h.add_child(_label(it[0], 14, C_FG))
		var pips = HBoxContainer.new()
		pips.add_theme_constant_override("separation", 3)
		pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for i in range(1, 5):
			var pp = ColorRect.new()
			pp.custom_minimum_size = Vector2(8, 8)
			pp.color = col if i <= lv else Color(col, 0.2)
			pips.add_child(pp)
		h.add_child(pips)
		if not compact:
			h.add_child(_label(D.KNOW_NAMES[lv], 13, col))
		p.add_child(h)
		return p
	return null


# ===== avisos =====
func hint(msg: String, warn := false, secs := 5.0) -> void:
	hint_lbl.text = msg
	hint_lbl.add_theme_color_override("font_color", C_EMBER if warn else C_FG)
	hint_box.visible = msg != ""
	hint_t = secs
	layout_hint()


func _process(delta: float) -> void:
	if mobile and root:
		# a altura da bandeja só se acerta depois que os textos quebram linha; e a tela cheia muda sem aviso
		poll_t -= delta
		var relayout = not arena_mode and absf(dock.get_combined_minimum_size().y - last_dock_h) > 1.0
		if poll_t <= 0:
			poll_t = 0.5
			var fs = Web.is_fullscreen()
			if fs != last_fs:
				last_fs = fs
				relayout = true
		if relayout:
			layout()
	if gbtn_flash > 0:
		gbtn_flash -= delta
		guard_btn.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.4, 0.6), 0.5 + 0.5 * sin(gbtn_flash * 8.0)) if gbtn_flash > 0 else Color.WHITE
	if hint_t > 0:
		hint_t -= delta
		if hint_t <= 0:
			hint_box.visible = false


# ===== atualização por quadro =====
func sync() -> void:
	if not game:
		return
	var v = maxf(0.0, game.clock)
	clock_lbl.text = "%.1fs" % v
	clock_lbl.add_theme_color_override("font_color", C_EMBER if (v < 10 and game.phase in ["wave", "arena"]) else (C_MUTE if game.phase in ["draft", "intro"] else C_FG))
	chips.wave.val.text = str(game.wave)
	chips.kills.val.text = str(game.kills)
	var fb: Label = chips.fame.val
	if game.phase == "arena":
		fb.text = D.pct(game.fame) + " · duelo"
	elif game.legend_next != "":
		fb.text = D.pct(game.fame) + " · lendário!"
	else:
		fb.text = "%s / %d%%" % [D.fmt(game.fame), int(round(game.fame_next))]
	fb.add_theme_color_override("font_color", C_MOSS if (game.legend_next != "" or game.phase == "arena") else C_FG)
	chips.evo.val.text = ("+" + D.pct(game.evo)) if game.guardian != "" else "–"
	guard_btn.visible = game.guardian != "" and game.phase != "arena"
	chips.rate.val.text = D.fmt(game.clock_rate()) + "×"
	var on: bool = game.ev.id != "" and game.phase == "wave"
	chips.event.val.text = game.ev.nome if on else "–"
	chips.event.val.add_theme_color_override("font_color", (C_EMBER if game.ev.ruim else C_MOSS) if on else C_FG)
	var mult = minf(D.CFG.COMBO_MAX, 1.0 + D.CFG.COMBO_STEP * (game.combo - 1))
	chips.combo.val.text = ("×%s (%d)" % [D.fmt(mult), game.combo]) if game.combo >= 2 else "–"
	chips.combo.val.add_theme_color_override("font_color", C_BRASS if game.combo >= 2 else C_FG)
	for bc in bench_cost:
		if is_instance_valid(bc[0]):
			bc[0].modulate.a = 0.45 if game.clock <= bc[1].call() + 1 else 1.0
	pause_btn.disabled = not (game.phase in ["wave", "prep", "arena"])
	pause_btn.text = "Continuar" if game.paused else "Pausar"
	pause_lbl.visible = game.paused
	bell_btn.disabled = game.phase != "wave" or game.bell_cd > 0
	bell_btn.text = ("Badalada %.1fs" % game.bell_cd) if game.bell_cd > 0 else "Badalada −%ds" % game.bell_cost()
	speed_btn.text = "%d×" % game.speed
	if mobile:
		var ev_v: bool = on
		var co_v: bool = game.combo >= 2
		var gv_v: bool = game.guardian != ""
		if chips.event.panel.visible != ev_v or chips.combo.panel.visible != co_v or chips.evo.panel.visible != gv_v:
			chips.event.panel.visible = ev_v
			chips.combo.panel.visible = co_v
			chips.evo.panel.visible = gv_v


func toggle_pause() -> void:
	if not (game.phase in ["wave", "prep", "arena"]):
		return
	game.paused = not game.paused


func toggle_fullscreen() -> void:
	if Web.on():
		if Web.is_fullscreen():
			Web.leave_fullscreen()
		elif Web.can_fullscreen():
			Web.request_fullscreen()
		elif Web.is_ios():
			hint("No iPhone o Safari não deixa sites em tela cheia. Toque em Compartilhar e depois em Adicionar à Tela de Início: aberto pelo ícone, o jogo ocupa a tela toda.", false, 9.0)
		else:
			hint("Este navegador não permite tela cheia. Tente pelo Chrome.", false, 5.0)
		return
	var m = DisplayServer.window_get_mode()
	if m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# ===== teclado no modo masmorra =====
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var kc: int = event.physical_keycode
	if grim.visible:
		if kc == KEY_ESCAPE or kc == KEY_G:
			close_grim()
		return
	if cls_modal.visible:
		if kc == KEY_ESCAPE or kc == KEY_C:
			close_classes()
		return
	if kc == KEY_F:
		toggle_fullscreen()
		return
	if kc == KEY_P:
		toggle_pause()
		return
	if arena_mode or overlay.visible:
		return
	if kc == KEY_SPACE:
		toggle_pause()
		return
	if kc == KEY_B:
		game.bell()
		return
	if kc == KEY_G:
		show_grim()
		return
	if kc == KEY_C:
		show_classes()
		return
	if kc >= KEY_1 and kc <= KEY_7:
		var k: String = D.TRAP_ORDER[kc - KEY_1]
		if game.unlocked.has(k):
			game.tool = k
			set_tab("traps")
			build_bench()
		return
	var mk = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T, KEY_Y, KEY_U, KEY_I, KEY_O]
	var i = mk.find(kc)
	if i >= 0 and game.unlocked.has(D.MON_ORDER[i]):
		game.summon(D.MON_ORDER[i])


# ===== controles de toque da luta =====
func _build_pad() -> void:
	pad = preload("res://scripts/touch_pad.gd").new()
	pad.game = game
	pad.visible = false
	root.add_child(pad)


func enter_arena() -> void:
	arena_mode = true
	layout()
	pad.setup()
	render_know()


func leave_arena() -> void:
	arena_mode = false
	pad.release_all()
	layout()
	render_know()


# ===== layout (mapa sempre deitado; ajusta à tela) =====
## Pixel art nítida: cada pixel da arte (2 unidades) vira um número inteiro de pixels na tela, se não perder muito tamanho.
func _snap(s: float) -> float:
	var px = 2.0 * s
	var f = floor(px)
	if f >= 2 and f / px >= 0.85:
		return f / 2.0
	return s


func layout() -> void:
	if root == null:
		return
	var vs = root.get_viewport_rect().size
	var m = 8.0
	# margens seguras (notch do iPhone deitado)
	var ins = Web.safe_insets(vs.x) if (mobile and not rotated) else [0.0, 0.0, 0.0]
	var ml: float = maxf(m, ins[0])
	var mr: float = maxf(m, ins[1])
	rotate_box.visible = mobile and vs.x < vs.y
	if fs_btn:
		fs_btn.visible = not (mobile and last_fs)
	top.position = Vector2(ml, m)
	# chips extras somem em telas estreitas (no celular fica só o essencial)
	chips.rate.panel.visible = vs.x >= 1150 and not mobile
	chips.kills.panel.visible = vs.x >= 1250 and not mobile
	chips.event.panel.visible = not mobile or game.ev.id != ""
	chips.combo.panel.visible = not mobile or game.combo >= 2
	chips.evo.panel.visible = vs.x >= 1050 or (mobile and game.guardian != "")
	top.size = Vector2(vs.x - ml - mr, 0)
	top.reset_size()
	top.size.x = vs.x - ml - mr
	var y0 = top.position.y + maxf(top.size.y, 50.0) + m
	var board: Node2D = board_holder.get_child(0) if board_holder.get_child_count() > 0 else null
	var frame: Panel = root.get_node("Frame")
	if arena_mode:
		# arena ocupa a tela toda; os controles ficam por cima, semitransparentes
		var s = minf((vs.x - ml - mr) / 720.0, (vs.y - y0 - m) / 480.0)
		s = _snap(s)
		var bw = 720.0 * s
		var bh = 480.0 * s
		var bx = ml + (vs.x - ml - mr - bw) / 2.0
		board_holder.position = Vector2(bx, y0)
		if board:
			board.scale = Vector2(s, s)
		frame.position = board_holder.position
		frame.size = Vector2(bw, bh)
		board_holder.size = Vector2(bw, bh)
		pad.visible = true
		pad.position = Vector2.ZERO
		pad.size = vs
		pad.setup()
		know_panel.visible = false
		dock.visible = false
	elif mobile:
		# celular: o mapa usa a altura toda; bandeja e "o que sabem" dividem a coluna da direita
		pad.visible = false
		know_panel.visible = true
		dock.visible = true
		var s = minf((vs.y - y0 - m) / 480.0, (vs.x - ml - mr - 320 - m) / 720.0)
		s = _snap(s)
		var bw = 720.0 * s
		var bh = 480.0 * s
		board_holder.position = Vector2(ml, y0)
		if board:
			board.scale = Vector2(s, s)
		frame.position = board_holder.position
		frame.size = Vector2(bw, bh)
		board_holder.size = Vector2(bw, bh)
		var cx = ml + bw + m
		var cw = vs.x - cx - mr
		dock.position = Vector2(cx, y0)
		dock.size.x = cw
		var dh: float = dock.get_combined_minimum_size().y
		dock.size = Vector2(cw, dh)
		last_dock_h = dh
		know_panel.position = Vector2(cx, y0 + dh + m)
		know_panel.size = Vector2(cw, maxf(60.0, vs.y - (y0 + dh + m) - m))
		know_panel.visible = vs.y - (y0 + dh + m) - m > 50
	else:
		pad.visible = false
		know_panel.visible = true
		dock.visible = true
		var dock_w = clampf(vs.x * 0.32, 340, 460)
		var know_h = 92.0
		var s = minf((vs.x - dock_w - 3 * m) / 720.0, (vs.y - y0 - know_h - 2 * m) / 480.0)
		s = _snap(s)
		var bw = 720.0 * s
		var bh = 480.0 * s
		board_holder.position = Vector2(m, y0)
		if board:
			board.scale = Vector2(s, s)
		frame.position = board_holder.position
		frame.size = Vector2(bw, bh)
		board_holder.size = Vector2(bw, bh)
		know_panel.position = Vector2(m, y0 + bh + m)
		know_panel.size = Vector2(bw, vs.y - (y0 + bh + m) - m)
		dock.position = Vector2(m + bw + m, y0)
		dock.size = Vector2(vs.x - bw - 3 * m, vs.y - y0 - m)
	pause_lbl.position = board_holder.position
	pause_lbl.size = frame.size
	layout_hint()
	var cbx: Control = cls_modal.get_node("Box")
	var cw = minf(vs.x - 32, 1180)
	cbx.position = Vector2((vs.x - cw) / 2.0, 24)
	cbx.size = Vector2(cw, 0)
	cbx.reset_size()
	cbx.size.x = cw
	cbx.position.y = maxf(16.0, (vs.y - cbx.size.y) / 2.0)
	var gb: Control = grim.get_node("Box")
	var gw = minf(vs.x - 32, 980)
	var gh = vs.y - 48
	gb.position = Vector2((vs.x - gw) / 2.0, 24)
	gb.size = Vector2(gw, gh)
	ov_cards.custom_minimum_size.x = 0
	var ovv: Control = ov_title.get_parent()
	ovv.custom_minimum_size.x = minf(vs.x - 48, 1100)


func layout_hint() -> void:
	var frame: Panel = root.get_node("Frame")
	var w = minf(frame.size.x - 24, 700)
	hint_lbl.custom_minimum_size = Vector2(w - 24, 0)
	hint_box.custom_minimum_size = Vector2(w, 0)
	hint_box.reset_size()
	hint_box.size = Vector2(w, hint_box.get_combined_minimum_size().y)
	hint_box.position = Vector2(frame.position.x + (frame.size.x - w) / 2.0, frame.position.y + (70.0 if arena_mode else 10.0))
