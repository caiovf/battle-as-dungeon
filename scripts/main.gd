extends Node
## Masmorra Relógio — lógica da masmorra (tower defense invertido + adaptação dos heróis).
## A interface fica em ui.gd, a luta de ação em arena.gd e os desenhos em art.gd.

const D = preload("res://scripts/data.gd")
const Art = preload("res://scripts/art.gd")
const UI = preload("res://scripts/ui.gd")
const ArenaScript = preload("res://scripts/arena.gd")
const BoardScript = preload("res://scripts/board.gd")

const T := 40
const COLS := 18
const ROWS := 12
const W := 720
const H := 480
const META_PATH := "user://meta.json"


class Hero:
	var type: String
	var hp: float
	var max: float
	var dmg: float = 1.0
	var spd: float = 1.0
	var steal: float = 0.0
	var dist: float = 0.0
	var pos: Vector2
	var slow: float = 0.0
	var stun: float = 0.0
	var block = null
	var cd: float = 1.5
	var shot: float = 0.0
	var disarm: Dictionary = {}
	var dodged: Dictionary = {}
	var hp0: float = -1.0
	var face: int = 1


class Mon:
	var type: String
	var paid: float = 0.0
	var lvl: int = 1
	var hp: float
	var max: float
	var dps: float
	var vel: float
	var dist: float
	var dir: int = -1
	var pos: Vector2
	var blocked: Array = []
	var mini: bool = false
	var life: float = INF
	var cd: float = 0.0
	var sprung: bool = false
	var face: int = -1


class Trap:
	var type: String
	var cd: float = 0.0
	var paid: float = 0.0
	var off: bool = false
	var off_t: float = 0.0
	var prog: float = 0.0
	var by = null


# ===== estado da run =====
var meta := {"runs": 0, "best": 0}
var heart := Vector2i(COLS - 1, 5)
var clock: float = 60.0
var wave: int = 1
var ess: int = 0
var ess_run: int = 0
var perks := {}
var unlock := {}
var phase := "intro"   # intro, prep, wave, draft, arena, reward, over
var kills: int = 0
var speed: int = 1
var paused := false
var unlocked := {}
var mods := {}
var ev: Dictionary = D.NO_EVENT
var kl := {}
var wave_use := {}
var wave_cov := {}
var streak := {}
var last_use := {}
var mon_lvl := {}
var traps := {}        # Vector2i -> Trap
var monsters: Array = []
var heroes: Array = []
var queue: Array = []
var spawn_t: float = 0.0
var fx: Array = []
var texts: Array = []
var route: Array = []
var side := "left"
var path_set := {}
var entr := Vector2i.ZERO
var seg: Array = []
var path_len: float = 0.0
var map_seed: int = 0
var combo: int = 0
var combo_t: float = 0.0
var freeze: float = 0.0
var bell_cd: float = 0.0
var fame: float = 0.0
var fame_next: float = 15.0
var fame_step: float = 25.0
var legend_next := ""
var leg_count: int = 0
var leg_order: Array = []
var guardian := ""
var evo: float = 0.0
var g_cls: int = 0          # classe atual do guardião (0 a 3)
var g_cls_seen: int = 0     # maior classe já anunciada
var g_skl := {}             # nível de cada habilidade (chave da habilidade -> nível)
var g_up := {"couraca": 0, "agil": 0, "sangue": 0}
var duel := {"dash": 0, "pulo": 0, "perto": 0, "longe": 0, "especial": 0}
var lost_to := ""
var tool := "espinhos"
var hover := Vector2i(-1, -1)
var shake_t: float = 0.0
var shake_amp: float = 0.0

var board: Node2D
var ui
var arena
var cards: Array = []


func _ready() -> void:
	randomize()
	_setup_input()
	_load_meta()
	board = BoardScript.new()
	board.game = self
	ui = UI.new()
	ui.game = self
	add_child(ui)
	ui.build()
	ui.board_holder.add_child(board)
	arena = ArenaScript.new()
	arena.game = self
	_build_cards()
	new_idle_state()
	ui.layout()
	ui.show_intro()


func _setup_input() -> void:
	var keys = {
		"g_left": [KEY_LEFT, KEY_A], "g_right": [KEY_RIGHT, KEY_D], "g_jump": [KEY_UP, KEY_W, KEY_SPACE],
		"g_atk": [KEY_J, KEY_X], "g_dash": [KEY_K, KEY_SHIFT, KEY_C], "g_s0": [KEY_U, KEY_1], "g_s1": [KEY_I, KEY_2], "g_s2": [KEY_O, KEY_3, KEY_L],
	}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for k in keys[a]:
			var e = InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)


# ===== meta (recorde e runs) =====
func _load_meta() -> void:
	if FileAccess.file_exists(META_PATH):
		var f = FileAccess.open(META_PATH, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				meta["runs"] = int(d.get("runs", 0))
				meta["best"] = int(d.get("best", 0))


func save_meta() -> void:
	var f = FileAccess.open(META_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(meta))


# ===== helpers =====
static func center(x: int, y: int) -> Vector2:
	return Vector2(x * T + T / 2.0, y * T + T / 2.0)


func perk(id: String) -> int:
	return int(perks.get(id, 0))


func meta_fame() -> float:
	return minf(D.CFG.FAME_MAX, meta.runs * D.CFG.FAME_PER_RUN)


func fame_pct() -> float:
	return fame / 100.0


func evo_pct() -> float:
	return evo / 100.0


func available(k: String) -> bool:
	return D.BASE_TOOLS.has(k) or D.FREE_POOL.has(k) or unlock.has(k)


func in_run() -> bool:
	return phase in ["prep", "wave", "draft", "arena", "reward"]


func cost_f() -> float:
	return mods.costMul * (1.0 - 0.06 * perk("custo"))


func cost(k: String) -> float:
	return D.r1(D.TOOLS[k].custo * cost_f() * (ev.costMul if phase == "wave" else 1.0))


func bell_cost() -> int:
	return maxi(1, D.CFG.BELL_COST - perk("sino"))


func clock_rate() -> float:
	var r = minf(D.CFG.DRAIN_MAX, D.CFG.DRAIN_BASE + D.CFG.DRAIN_GROWTH * (wave - 1))
	return r * (ev.drainMul if phase == "wave" else 1.0)


func hero_scale(n: int) -> Dictionary:
	return {
		"hp": pow(1.0 + D.CFG.HERO_HP_GROWTH, n - 1) * (1.0 + meta_fame()) * (1.0 + fame_pct() * D.CFG.FAME_HP),
		"dps": pow(1.0 + D.CFG.HERO_DMG_GROWTH, n - 1) * (1.0 + fame_pct() * D.CFG.FAME_DMG),
		"vel": minf(1.4, 1.0 + D.CFG.HERO_SPD_GROWTH * (n - 1)),
		"steal": 1.0 + D.CFG.HERO_STEAL_GROWTH * (n - 1),
	}


func res(k: String) -> float:
	return D.CFG.KNOW_RESIST[int(kl.get(k, 0))]


func power(k: String) -> float:
	return D.CFG.KNOW_POWER[int(kl.get(k, 0))]


func near_hero(p: Vector2, type: String, r: float) -> bool:
	for o in heroes:
		if o.type == type and o.hp > 0 and o.pos.distance_to(p) <= r:
			return true
	return false


static func hpow(t: String) -> String:
	return D.HEROES[t].get("power", "")


static func cc_imm(t: String) -> bool:
	return t == "campeao" or hpow(t) == "cc"


static func is_mage(t: String) -> bool:
	return t == "arquimago" or hpow(t) == "mage"


static func is_king(t: String) -> bool:
	return t == "rei" or hpow(t) == "king"


# ===== classes do guardião =====
func cls_list() -> Array:
	return D.CLASSES[guardian] if guardian != "" else []


func cls() -> Dictionary:
	return D.CLASSES[guardian][g_cls]


func class_open(i: int) -> bool:
	return evo >= D.CLASS_UNLOCK[i]


func guard_key() -> String:
	return "%s_%d" % [guardian, g_cls]


func sk_level(k: String) -> int:
	return int(g_skl.get(k, 1))


func set_class(i: int) -> void:
	if guardian == "" or not class_open(i):
		return
	g_cls = i
	if ui:
		ui.sync()


func check_class_unlock() -> void:
	if guardian == "":
		return
	var newest = -1
	for i in range(1, 4):
		if class_open(i) and i > g_cls_seen:
			newest = i
	if newest > 0:
		g_cls_seen = newest
		if true:
			var c = D.CLASSES[guardian][newest]
			float_text(Vector2(W / 2.0, H / 2.0 + 30), "NOVA CLASSE: " + c.nome.to_upper(), Color("#f2d488"), 18)
			hint("O %s pode virar %s. Toque em Guardião (na barra de cima) para trocar de classe." % [D.GUARDS[guardian].nome, c.nome], false, 7.0)
			if ui:
				ui.flash_guard_btn()


func hint(msg: String, warn := false, secs := 5.0) -> void:
	if ui:
		ui.hint(msg, warn, secs)


func float_text(p: Vector2, s: String, c: Color, size := 15) -> void:
	texts.append({"pos": p, "s": s, "c": c, "size": size, "life": 1.3 if size > 15 else 0.95, "max": 1.3 if size > 15 else 0.95})


func shake(secs: float, amp: float) -> void:
	shake_t = maxf(shake_t, secs)
	shake_amp = maxf(shake_amp, amp)


# ===== estado =====
func fresh_state() -> void:
	heart = Vector2i(COLS - 1, 1 + randi() % (ROWS - 2))
	clock = D.CFG.START
	wave = 1
	ess = 0
	ess_run = 0
	perks = {}
	unlock = {}
	phase = "intro"
	kills = 0
	speed = 1
	paused = false
	unlocked = {}
	for k in D.BASE_TOOLS:
		unlocked[k] = true
	mods = {"esp": 1.0, "besta": 1.0, "fogo": 1.0, "slow": 0.0, "killBonus": 0.0, "costMul": 1.0, "stealMul": 1.0,
		"bellCdMul": 1.0, "bellFreeze": 0.0, "monHp": 1.0, "monDmg": 1.0}
	ev = D.NO_EVENT
	kl = {}
	wave_use = {}
	wave_cov = {}
	streak = {}
	last_use = {}
	mon_lvl = {}
	for k in D.MON_ORDER:
		mon_lvl[k] = 1
	traps = {}
	monsters = []
	heroes = []
	queue = []
	spawn_t = 0.0
	fx = []
	texts = []
	combo = 0
	combo_t = 0.0
	freeze = 0.0
	bell_cd = 0.0
	fame = 0.0
	fame_next = D.CFG.LEG_FAME_FIRST
	fame_step = D.CFG.LEG_FAME_STEP
	legend_next = ""
	leg_count = 0
	leg_order = D.LEGENDS.duplicate()
	leg_order.shuffle()
	guardian = ""
	evo = 0.0
	g_cls = 0
	g_cls_seen = 0
	g_skl = {}
	g_up = {"couraca": 0, "agil": 0, "sangue": 0}
	duel = {"dash": 0, "pulo": 0, "perto": 0, "longe": 0, "especial": 0}
	lost_to = ""
	tool = "espinhos"


func new_idle_state() -> void:
	fresh_state()
	set_path(gen_path())
	if ui:
		ui.build_bench()
		ui.render_know()
		ui.sync()


# ===== caminho aleatório =====
func _random_entrance() -> Dictionary:
	var s = ["left", "top", "bottom"][randi() % 3]
	if s == "left":
		return {"x": 0, "y": 1 + randi() % (ROWS - 2), "side": s}
	var x = 1 + randi() % (COLS - 5)
	return {"x": x, "y": 0 if s == "top" else ROWS - 1, "side": s}


func _l_tiles(a: Vector2i, b: Vector2i, h_first: bool) -> Array:
	var out = []
	var x = a.x
	var y = a.y
	if h_first:
		while x != b.x:
			x += signi(b.x - x)
			out.append(Vector2i(x, y))
		while y != b.y:
			y += signi(b.y - y)
			out.append(Vector2i(x, y))
	else:
		while y != b.y:
			y += signi(b.y - y)
			out.append(Vector2i(x, y))
		while x != b.x:
			x += signi(b.x - x)
			out.append(Vector2i(x, y))
	return out


func _fits(tiles: Array, rt: Array, used: Dictionary) -> bool:
	var r = rt.duplicate()
	var u = used.duplicate()
	for t in tiles:
		if t.x < 1 or t.y < 1 or t.x > COLS - 2 or t.y > ROWS - 2:
			return false
		if u.has(t):
			return false
		var recent = {}
		for p in r.slice(maxi(0, r.size() - 2)):
			recent[p] = true
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var n = Vector2i(t.x + dx, t.y + dy)
				if u.has(n) and not recent.has(n):
					return false
		r.append(t)
		u[t] = true
	return true


func gen_path() -> Dictionary:
	var pre = Vector2i(COLS - 2, heart.y)
	for _tries in 4000:
		var e = _random_entrance()
		var en = Vector2i(e.x, e.y)
		var first: Vector2i
		match e.side:
			"left": first = Vector2i(1, e.y)
			"top": first = Vector2i(e.x, 1)
			_: first = Vector2i(e.x, ROWS - 2)
		var nb = D.CFG.BENDS[0] + randi() % (D.CFG.BENDS[1] - D.CFG.BENDS[0] + 1)
		var pts = [first]
		for i in nb:
			pts.append(Vector2i(2 + randi() % (COLS - 5), 1 + randi() % (ROWS - 2)))
		pts.append(pre)
		var rt = [en, first]
		var used = {en: true, first: true}
		var fail = false
		for i in pts.size() - 1:
			var order = [true, false] if randf() < 0.5 else [false, true]
			var sg = null
			for hf in order:
				var t = _l_tiles(pts[i], pts[i + 1], hf)
				if _fits(t, rt, used):
					sg = t
					break
			if sg == null:
				fail = true
				break
			for t in sg:
				rt.append(t)
				used[t] = true
		if fail:
			continue
		rt.append(heart)
		if rt.size() < D.PATH_LEN[0] or rt.size() > D.PATH_LEN[1]:
			continue
		return {"route": rt, "side": e.side}
	var fb = []
	for x in COLS:
		fb.append(Vector2i(x, heart.y))
	return {"route": fb, "side": "left"}


func set_path(p: Dictionary) -> void:
	route = p.route
	side = p.side
	map_seed = randi()
	entr = route[0]
	path_set = {}
	for t in route:
		path_set[t] = true
	seg = []
	path_len = 0.0
	var c0 = center(entr.x, entr.y)
	var off: Vector2
	match side:
		"left": off = Vector2(-T / 2.0, c0.y)
		"top": off = Vector2(c0.x, -T / 2.0)
		_: off = Vector2(c0.x, H + T / 2.0)
	var pts = [off]
	for t in route:
		pts.append(center(t.x, t.y))
	for i in pts.size() - 1:
		var l: float = pts[i].distance_to(pts[i + 1])
		seg.append({"a": pts[i], "b": pts[i + 1], "l": l, "start": path_len})
		path_len += l


func pos_at(d: float) -> Vector2:
	for s in seg:
		if d <= s.start + s.l:
			return s.a.lerp(s.b, (d - s.start) / s.l)
	return center(heart.x, heart.y)


func on_path(x: int, y: int) -> bool:
	return path_set.has(Vector2i(x, y))


func is_heart(x: int, y: int) -> bool:
	return x == heart.x and y == heart.y


func is_entr(x: int, y: int) -> bool:
	return x == entr.x and y == entr.y


# ===== ondas, eventos e contras =====
func build_wave(n: int) -> Dictionary:
	var q = []
	var count = D.CFG.HERO_COUNT[0] + D.CFG.HERO_COUNT[1] * n
	var specials = _specials()
	for i in count:
		var r = randf()
		var t = "guerreiro"
		if n >= 2 and r < 0.35:
			t = "ladino"
		if n >= 3 and r > 0.8:
			t = "paladino"
		if n >= D.CFG.SPECIAL_FROM and randf() < D.CFG.SPECIAL_CHANCE:
			t = specials[randi() % specials.size()]
		q.append(t)
	# contras escondidos: quanto mais os heróis conhecem algo, mais especialistas vêm. Sem aviso.
	for k in D.TRAP_ORDER + D.MON_ORDER:
		var lv = int(kl.get(k, 0))
		var num: int = D.CFG.COUNTER_COUNT[lv]
		if num == 0 or randf() >= D.CFG.COUNTER_CHANCE[lv]:
			continue
		var c = D.COUNTER[k]
		for i in range(num - 1, 0, -1):
			q.insert(int(q.size() * i / float(num)), c)
		q.insert(0, c)
	var boss = ""
	if legend_next != "":
		boss = legend_next
		var esc = ["paladino", "guerreiro", "guerreiro"]
		if leg_count >= 1:
			esc.append(specials[randi() % specials.size()])
		if leg_count >= 2:
			esc.append(D.BOSSES[randi() % D.BOSSES.size()])
		q.append_array(esc)
		q.append(boss)
	ev = D.NO_EVENT
	if boss == "" and n >= D.CFG.EVENT_FROM and randf() < D.CFG.EVENT_CHANCE:
		var pool = []
		for e in D.EVENTS:
			for i in e.peso:
				pool.append(e)
		var e = pool[randi() % pool.size()]
		var nev: Dictionary = D.NO_EVENT.duplicate()
		for k in e.efeito:
			nev[k] = e.efeito[k]
		nev["id"] = e.id
		nev["nome"] = e.nome
		nev["desc"] = e.desc
		nev["ruim"] = e.ruim
		ev = nev
		match e.id:
			"incursao":
				var extra = int(ceil(q.size() * 0.6))
				for i in extra:
					q.append("guerreiro" if randf() < 0.5 else "paladino")
				for i in 3 + n / 4:
					q.insert(randi() % (q.size() + 1), specials[randi() % specials.size()])
			"enxame":
				for i in 6 + n:
					q.insert(randi() % (q.size() + 1), "ladino")
			"mercador":
				for i in 3:
					q.insert(randi() % (q.size() + 1), "mercador")
	return {"q": q, "boss": boss}


func _specials() -> Array:
	var out = []
	for k in D.HEROES:
		if D.HEROES[k].get("special", false):
			out.append(k)
	return out


func start_wave() -> void:
	if phase != "prep":
		return
	var total_use = 0
	for k in wave_use:
		total_use += wave_use[k]
	for k in D.TRAP_ORDER + D.MON_ORDER:
		var lv = int(kl.get(k, 0))
		var used = int(wave_use.get(k, 0))
		var share = float(used) / total_use if total_use > 0 else 0.0
		var cov = float(wave_cov.get(k, 0.0))
		var tier = 0
		var hv = D.CFG.ABUSE_HEAVY
		var ex = D.CFG.ABUSE_EXTREME
		if used >= D.CFG.ABUSE_MIN:
			tier = 1
			if share >= hv.share and (cov >= hv.cover or used >= hv.uses):
				tier = 2
			if share >= ex.share and (cov >= ex.cover or used >= ex.uses):
				tier = 3
		var gain = 0
		if tier == 3:
			gain = 2
			streak[k] = 0
		elif tier == 2:
			gain = 1
			streak[k] = 0
		elif tier == 1:
			streak[k] = int(streak.get(k, 0)) + 1
			if streak[k] >= D.CFG.LEARN_WAVES:
				gain = 1
				streak[k] = 0
		else:
			streak[k] = 0
		if gain > 0 and lv < 4:
			lv = mini(4, lv + gain)
		# sem usar por FORGET_WAVES ondas: o conhecimento cai 1 nível
		if lv > 0 and wave - int(last_use.get(k, 0)) > D.CFG.FORGET_WAVES:
			lv -= 1
			last_use[k] = wave - 1
		kl[k] = lv
	wave_use = {}
	wave_cov = {}
	var bw = build_wave(wave)
	queue = bw.q
	spawn_t = D.CFG.FIRST_DELAY
	phase = "wave"
	var hs = hero_scale(wave)
	var parts = ["Onda %d: %d heróis, vida ×%s, relógio a %s×." % [wave, queue.size(), D.fmt(hs.hp), D.fmt(clock_rate())]]
	if bw.boss != "":
		parts.push_front("%s invadiu a masmorra com escolta. Se chegar ao coração, o %s luta na sala do guardião." % [D.HEROES[bw.boss].nome, D.GUARDS[guardian].nome])
	var novos = []
	for k in D.MON_ORDER:
		if available(k) and D.MON_UNLOCK.has(k) and D.MON_UNLOCK[k].onda == wave:
			novos.append(D.TOOLS[k].nome)
	if novos.size() > 0:
		parts.append("Novo monstro à venda: %s." % ", ".join(novos))
	if ev.id != "":
		parts.push_front("%s! %s" % [ev.nome, ev.desc])
		float_text(Vector2(W / 2.0, H / 2.0 - 20), ev.nome.to_upper(), Color("#e0613a") if ev.ruim else Color("#9fd36b"), 30)
	float_text(Vector2(W / 2.0, H / 2.0 + 18), "ONDA %d" % wave, Color("#ece2d2"), 24)
	hint(" ".join(parts), bw.boss != "" or (ev.id != "" and ev.ruim), 7.0)
	if ui:
		ui.build_bench()
		ui.sync()
		ui.render_know()


func shift_dungeon() -> void:
	var back = 0.0
	var n = 0
	var rate = D.CFG.RESET_REFUND + 0.1 * perk("refund")
	for t in traps.values():
		back += t.paid * rate
		n += 1
	for m in monsters:
		if not m.mini:
			back += m.paid * rate
			n += 1
	back = D.r1(back)
	traps.clear()
	monsters = []
	clock += back
	set_path(gen_path())
	if n > 0:
		float_text(center(heart.x, heart.y) + Vector2(0, -30), "+%ss" % D.fmt(back), Color("#d0a245"))


func next_wave() -> void:
	phase = "prep"
	shift_dungeon()
	start_wave()


# ===== badalada =====
func bell() -> void:
	if phase != "wave":
		hint("A badalada só funciona com heróis na masmorra.")
		return
	if bell_cd > 0:
		hint("A badalada ainda está recarregando.", true)
		return
	var bc = bell_cost()
	if clock <= bc + 0.5:
		hint("Sem tempo para a badalada.", true)
		return
	clock -= bc
	freeze = D.CFG.BELL_FREEZE + mods.bellFreeze
	bell_cd = D.CFG.BELL_CD * mods.bellCdMul
	var c = center(heart.x, heart.y)
	fx.append({"kind": "ring", "pos": c, "life": 0.6, "max_life": 0.6, "col": Color("#7fb8c9"), "max": W * 0.6})
	float_text(c + Vector2(0, -30), "-%ds" % bc, Color("#7fb8c9"))


# ===== relíquias =====
func _build_cards() -> void:
	cards = []
	for k in D.TRAP_ORDER:
		if D.BASE_TOOLS.has(k):
			continue
		var kk: String = k
		cards.append({"id": "u_" + kk, "tag": "Nova armadilha", "t": D.TOOLS[kk].nome, "d": D.TOOLS[kk].desc + ".",
			"ok": func(): return available(kk) and not unlocked.has(kk), "f": func(): unlocked[kk] = true})
	cards.append({"id": "esp", "tag": "Melhoria", "t": "Lâminas afiadas", "d": "Espinhos causam +50% de dano.", "ok": func(): return true, "f": func(): mods.esp *= 1.5})
	cards.append({"id": "besta", "tag": "Melhoria", "t": "Virotes de ferro", "d": "Bestas causam +40% de dano.", "ok": func(): return true, "f": func(): mods.besta *= 1.4})
	cards.append({"id": "fogo", "tag": "Melhoria", "t": "Pólvora", "d": "Fogueiras causam +50% de dano.", "ok": func(): return unlocked.has("fogo"), "f": func(): mods.fogo *= 1.5})
	cards.append({"id": "slow", "tag": "Melhoria", "t": "Areia fina", "d": "Ampulhetas deixam 15% mais lento.", "ok": func(): return unlocked.has("ampulheta") and mods.slow < 0.3, "f": func(): mods.slow += 0.15})
	cards.append({"id": "monhp", "tag": "Melhoria", "t": "Ossos de ferro", "d": "Monstros têm +50% de vida.", "ok": func(): return true, "f": func(): mods.monHp *= 1.5})
	cards.append({"id": "mondmg", "tag": "Melhoria", "t": "Fúria da cripta", "d": "Monstros causam +40% de dano.", "ok": func(): return true, "f": func(): mods.monDmg *= 1.4})
	cards.append({"id": "forget", "tag": "Relíquia lendária", "lendaria": true, "t": "Névoa do esquecimento", "d": "Os heróis esquecem tudo o que estudaram nesta run.",
		"ok": Callable(self, "_forget_ok"), "f": Callable(self, "_forget_apply")})
	cards.append({"id": "kill", "tag": "Relíquia", "t": "Coração voraz", "d": "Todo abate dá +1s extra, antes do combo.", "ok": func(): return true, "f": func(): mods.killBonus += 1.0})
	cards.append({"id": "cheap", "tag": "Relíquia", "t": "Pedreiro barato", "d": "Tudo custa 20% menos tempo.", "ok": func(): return mods.costMul > 0.5, "f": func(): mods.costMul *= 0.8})
	cards.append({"id": "steal", "tag": "Relíquia", "t": "Fechadura dupla", "d": "Heróis que chegam roubam 30% menos.", "ok": func(): return mods.stealMul > 0.4, "f": func(): mods.stealMul *= 0.7})
	cards.append({"id": "bellcd", "tag": "Relíquia", "t": "Sino afinado", "d": "A badalada recarrega 40% mais rápido.", "ok": func(): return mods.bellCdMul > 0.4, "f": func(): mods.bellCdMul *= 0.6})
	cards.append({"id": "bellfz", "tag": "Relíquia", "t": "Eco longo", "d": "A badalada congela 1s a mais.", "ok": func(): return mods.bellFreeze < 2, "f": func(): mods.bellFreeze += 1.0})
	cards.append({"id": "gear", "tag": "Imediato", "t": "Engrenagem extra", "d": "+15s no relógio agora.", "ok": func(): return true, "f": func(): clock += 15.0})


func _forget_ok() -> bool:
	for v in kl.values():
		if v >= 2:
			return true
	return false


func _forget_apply() -> void:
	kl = {}
	streak = {}
	float_text(Vector2(W / 2.0, H / 2.0 - 50), "OS HERÓIS ESQUECERAM TUDO", Color("#f2d488"), 22)


func coverage(k: String) -> float:
	var d = D.TOOLS[k]
	if d.kind != "trap" or route.is_empty():
		return 0.0
	var tiles = {}
	for key in traps:
		if traps[key].type != k:
			continue
		if d.on_path:
			tiles[key] = true
			continue
		var c = center(key.x, key.y)
		for p in route:
			if center(p.x, p.y).distance_to(c) <= d.alcance * T:
				tiles[p] = true
	return tiles.size() / float(route.size())


func show_draft() -> void:
	phase = "draft"
	combo = 0
	for k in D.TRAP_ORDER:
		var c = coverage(k)
		if c > 0:
			wave_cov[k] = maxf(float(wave_cov.get(k, 0.0)), c)
	fame += D.CFG.FAME_WAVE
	var rumor = ""
	if legend_next == "" and fame >= fame_next:
		legend_next = leg_order[leg_count % leg_order.size()]
		rumor = "Rumor: %s ouviu falar da sua masmorra e vem na próxima onda." % D.HEROES[legend_next].nome
	var ess_gain = 1 + int(ev.essBonus)
	ess += ess_gain
	ess_run += ess_gain
	float_text(Vector2(W / 2.0, H / 2.0 + 48), "+%d ESSÊNCIA" % ess_gain, Color("#f2d488"), 18)
	var pool = []
	for c in cards:
		if c.ok.call():
			pool.append(c)
	var pick = []
	var n = 3 + perk("cartas")
	while pick.size() < n and pool.size() > 0:
		var total = 0.0
		for c in pool:
			total += D.CFG.LEGENDARY_WEIGHT if c.get("lendaria", false) else 10.0
		var r = randf() * total
		var i = 0
		while i < pool.size() - 1:
			var wgt: float = D.CFG.LEGENDARY_WEIGHT if pool[i].get("lendaria", false) else 10.0
			if r < wgt:
				break
			r -= wgt
			i += 1
		pick.append(pool[i])
		pool.remove_at(i)
	if ui:
		ui.render_know()
		ui.show_draft(pick, rumor)
		ui.sync()


func pick_card(c: Dictionary) -> void:
	c.f.call()
	wave += 1
	if legend_next != "" and guardian == "":
		phase = "draft"
		ui.show_guard_pick()
	else:
		next_wave()


func pick_guardian(k: String) -> void:
	guardian = k
	g_cls = 0
	g_cls_seen = 0
	check_class_unlock()
	next_wave()


# ===== início e fim de run =====
func begin() -> void:
	arena.stop()
	fresh_state()
	phase = "prep"
	set_path(gen_path())
	ui.hide_overlays()
	start_wave()


func game_over() -> void:
	clock = 0.0
	phase = "over"
	arena.stop()
	meta.runs += 1
	meta.best = maxi(meta.best, wave)
	save_meta()
	var txt = ""
	if lost_to != "":
		txt = "%s derrotou o guardião e conquistou a masmorra. " % D.HEROES[lost_to].nome
	txt += "Você resistiu até a onda %d e derrubou %d heróis. Recorde: onda %d." % [wave, kills, meta.best]
	ui.show_over(txt)
	ui.sync()
	ui.render_know()


func after_run() -> void:
	new_idle_state()
	ui.show_intro()


# ===== grimório =====
func perk_cost(p: Dictionary) -> int:
	if p.get("fixo", false):
		return int(p.base)
	return int(p.base) + perk(p.id)


func perk_visible(p: Dictionary) -> bool:
	return wave >= int(p.revela)


func buy_perk(id: String) -> void:
	for p in D.PERKS:
		if p.id != id:
			continue
		var lv = perk(id)
		var c = perk_cost(p)
		if not in_run() or lv >= p.max or not perk_visible(p) or ess < c:
			return
		ess -= c
		perks[id] = lv + 1
		match id:
			"inicio":
				clock += 12.0
			"cripta":
				for k in D.MON_ORDER:
					mon_lvl[k] += 1
					var st = mon_stats(k)
					for m in monsters:
						if m.type == k and not m.mini:
							var ratio: float = m.hp / m.max
							m.lvl = mon_lvl[k]
							m.max = st.hp
							m.hp = st.hp * ratio
							m.dps = st.dps
							m.vel = st.vel
		hint("%s %d/%d." % [p.nome, lv + 1, p.max])
		ui.refresh_all()


func buy_unlock(k: String) -> void:
	var c: int = D.UNLOCK_COST[k]
	if not in_run() or available(k) or ess < c:
		return
	ess -= c
	unlock[k] = true
	hint("%s liberado nesta run." % D.TOOLS[k].nome)
	ui.refresh_all()


# ===== monstros =====
func mon_stats(k: String) -> Dictionary:
	var d = D.TOOLS[k]
	var m = 1.0 + D.CFG.MON_LVL_GAIN * (mon_lvl[k] - 1)
	return {"hp": d.hp * mods.monHp * m, "dps": d.dps * mods.monDmg * m, "vel": d.vel * (1.0 + 0.04 * (mon_lvl[k] - 1))}


func up_cost(k: String) -> float:
	return D.r1(D.TOOLS[k].custo * D.CFG.MON_UP_COST * mon_lvl[k] * cost_f())


func unlock_cost(k: String) -> float:
	return D.r1(D.MON_UNLOCK[k].tempo * cost_f())


func upgrade_mon(k: String) -> void:
	if phase != "prep" and phase != "wave":
		return
	var c = up_cost(k)
	if clock <= c + 1:
		hint("Sem tempo para evoluir o %s." % D.TOOLS[k].nome, true)
		return
	clock -= c
	mon_lvl[k] += 1
	var st = mon_stats(k)
	for m in monsters:
		if m.type == k and not m.mini:
			var ratio: float = m.hp / m.max
			m.lvl = mon_lvl[k]
			m.max = st.hp
			m.hp = st.hp * ratio
			m.dps = st.dps
			m.vel = st.vel
	hint("%s evoluiu para o nível %d." % [D.TOOLS[k].nome, mon_lvl[k]])
	float_text(center(heart.x, heart.y) + Vector2(0, -30), "-%ss" % D.fmt(c), Color("#e0613a"))
	ui.build_bench()


func buy_mon(k: String) -> void:
	if phase != "prep" and phase != "wave":
		return
	if not D.MON_UNLOCK.has(k) or wave < D.MON_UNLOCK[k].onda or unlocked.has(k):
		return
	var c = unlock_cost(k)
	if clock <= c + 1:
		hint("Sem tempo para liberar o %s." % D.TOOLS[k].nome, true)
		return
	clock -= c
	unlocked[k] = true
	float_text(center(heart.x, heart.y) + Vector2(0, -30), "-%ss" % D.fmt(c), Color("#e0613a"))
	float_text(Vector2(W / 2.0, H / 2.0 - 40), D.TOOLS[k].nome.to_upper() + " LIBERADO", Color("#d9cfa8"), 20)
	ui.build_bench()


func spawn_monster(k: String, dist_at: float, paid: float, mini := false) -> void:
	var st = mon_stats(k)
	var sc = 0.3 if mini else 1.0
	var m = Mon.new()
	m.type = k
	m.paid = paid
	m.lvl = mon_lvl[k]
	m.hp = st.hp * sc
	m.max = m.hp
	m.dps = st.dps * (0.5 if mini else 1.0)
	m.vel = st.vel
	m.dist = dist_at
	m.pos = pos_at(dist_at)
	m.mini = mini
	m.life = 25.0 if k == "espectro" else INF
	monsters.append(m)


func summon(k: String) -> void:
	if phase != "prep" and phase != "wave":
		return
	if not unlocked.has(k):
		return
	var paid = cost(k)
	if clock <= paid + 1:
		hint("Sem tempo para soltar um %s." % D.TOOLS[k].nome, true)
		return
	clock -= paid
	spawn_monster(k, path_len - T * 0.5, paid)
	_mark_use(k)
	var c = center(heart.x, heart.y)
	fx.append({"kind": "ring", "pos": c, "life": 0.5, "max_life": 0.5, "col": D.col(D.TOOLS[k].cor), "max": float(T)})
	float_text(c + Vector2(0, -30), "-%ss" % D.fmt(paid), Color("#e0613a"))


func _mark_use(k: String) -> void:
	wave_use[k] = int(wave_use.get(k, 0)) + 1
	last_use[k] = wave


# ===== armadilhas =====
func can_place(k: String, x: int, y: int) -> bool:
	if not unlocked.has(k) or D.TOOLS[k].kind != "trap" or x < 0 or y < 0 or x >= COLS or y >= ROWS:
		return false
	if traps.has(Vector2i(x, y)) or is_entr(x, y) or is_heart(x, y):
		return false
	if D.TOOLS[k].on_path != on_path(x, y):
		return false
	return clock > cost(k) + 1


func board_click(p: Vector2) -> void:
	if phase != "prep" and phase != "wave":
		return
	var x = int(floor(p.x / T))
	var y = int(floor(p.y / T))
	if x < 0 or y < 0 or x >= COLS or y >= ROWS:
		return
	var key = Vector2i(x, y)
	var c = center(x, y)
	if is_heart(x, y):
		bell()
		return
	if traps.has(key):
		var back = D.r1(traps[key].paid * D.CFG.SELL)
		traps.erase(key)
		clock += back
		float_text(c, "+%ss" % D.fmt(back), Color("#d0a245"))
		return
	if not unlocked.has(tool) or D.TOOLS[tool].kind != "trap":
		return
	var d = D.TOOLS[tool]
	if d.on_path and not on_path(x, y):
		float_text(c, "só no corredor", Color("#9a8e7f"))
		return
	if not d.on_path and on_path(x, y):
		float_text(c, "só na parede", Color("#9a8e7f"))
		return
	if clock <= cost(tool) + 1:
		float_text(c, "sem tempo", Color("#e0613a"))
		return
	if not can_place(tool, x, y):
		return
	var paid = cost(tool)
	clock -= paid
	var t = Trap.new()
	t.type = tool
	t.paid = paid
	traps[key] = t
	_mark_use(tool)
	float_text(c, "-%ss" % D.fmt(paid), Color("#e0613a"))


func active(t: Trap) -> bool:
	return not t.off and t.off_t <= 0


# ===== especialistas desarmando =====
func finish_disarm(key: Vector2i, t: Trap) -> void:
	var c = center(key.x, key.y)
	var d = D.DISARM[t.type]
	if t.type == "ganancia":
		traps.erase(key)
	else:
		t.off = true
		t.prog = 0.0
		t.by = null
	float_text(c + Vector2(0, -10), d.txt, d.cor, 12)
	fx.append({"kind": "ring", "pos": c, "life": 0.5, "max_life": 0.5, "col": Color("#9a8e7f"), "max": T * 0.6})


func release_disarm(h: Hero) -> void:
	if h.disarm.is_empty():
		return
	var t = traps.get(h.disarm.key)
	if t and t.by == h:
		t.by = null
		t.prog = 0.0
	h.disarm = {}


func work_disarm(h: Hero, dt: float) -> void:
	var type: String = D.DISARMERS[h.type]
	if not h.disarm.is_empty():
		var t = traps.get(h.disarm.key)
		if t == null or t.off or t.by != h:
			h.disarm = {}
			return
		h.disarm.t += dt
		t.prog = h.disarm.t / h.disarm.total
		if h.disarm.t >= h.disarm.total:
			var key: Vector2i = h.disarm.key
			h.disarm = {}
			finish_disarm(key, t)
		return
	var d = D.DISARM[type]
	var best = null
	var bk = Vector2i.ZERO
	var bd = 1e9
	for key in traps:
		var t: Trap = traps[key]
		if t.type != type or t.off:
			continue
		if t.by != null and t.by != h and heroes.has(t.by) and t.by.hp > 0:
			continue
		var dd = h.pos.distance_to(center(key.x, key.y))
		if dd <= d.raio * T and dd < bd:
			bd = dd
			best = t
			bk = key
	if best == null:
		return
	var total: float = d.tempo * D.CFG.DISARM_MUL[int(kl.get(type, 0))]
	if total <= 0:
		finish_disarm(bk, best)
		return
	best.by = h
	best.prog = 0.0
	h.disarm = {"key": bk, "t": 0.0, "total": total}


func hero_vs_mon(h: Hero, m: Mon) -> float:
	var c: String = D.COUNTER[m.type]
	if h.type == c:
		return 5.0
	return 2.0 if near_hero(h.pos, c, D.CFG.AURA * T) else 1.0


func mon_vs_hero(m: Mon, h: Hero) -> float:
	var c: String = D.COUNTER[m.type]
	if h.type == c:
		return 0.2
	return 0.5 if near_hero(h.pos, c, D.CFG.AURA * T) else 1.0


# ===== abate: tempo, combo, fama, evolução e energia absorvida =====
func kill_hero(h: Hero) -> void:
	var d = D.HEROES[h.type]
	if h.block:
		h.block.blocked.erase(h)
		h.block = null
	release_disarm(h)
	var greedy = false
	for key in traps:
		var t: Trap = traps[key]
		if t.type == "ganancia" and active(t) and h.pos.distance_to(center(key.x, key.y)) <= D.TOOLS.ganancia.alcance * T * ev.rangeMul:
			greedy = true
			break
	combo = combo + 1 if combo_t > 0 else 1
	combo_t = D.CFG.COMBO_WINDOW
	var mult = minf(D.CFG.COMBO_MAX, 1.0 + D.CFG.COMBO_STEP * (combo - 1))
	var is_leg: bool = d.get("legend", false)
	var soul = D.r1(D.CFG.SOUL_BASE * (D.CFG.SOUL_LEG if is_leg else 1.0) * (1.0 + fame_pct()))
	var gain = D.r1((d.da * (D.CFG.GREED_MUL if greedy else 1.0) + mods.killBonus) * mult * ev.killMul + soul)
	clock += gain
	kills += 1
	fame += D.CFG.FAME_KILL + (D.CFG.FAME_COMBO if combo >= 4 else 0.0)
	evo += D.CFG.EVO_KILL
	check_class_unlock()
	fx.append({"kind": "soul", "from": h.pos, "to": center(heart.x, heart.y), "life": 0.6, "max_life": 0.6, "col": Color("#f2d488") if is_leg else Color("#9fd3ff"), "big": is_leg})
	if is_leg:
		legend_fell(h.type, false, soul)
		return
	float_text(h.pos + Vector2(0, -10), "+%ss" % D.fmt(gain), Color("#9fd36b") if greedy else Color("#ece2d2"), 22 if d.get("boss", false) else 15)
	if d.get("boss", false):
		float_text(Vector2(W / 2.0, H / 2.0), d.nome + " caiu", Color("#d0a245"), 26)
	if combo >= 2:
		float_text(h.pos + Vector2(0, -30), "COMBO ×%s" % D.fmt(mult), Color("#d0a245"), 13 + int(mini(combo, 8) * 1.5))


func legend_fell(key: String, in_arena: bool, soul := 0.0) -> int:
	var nome: String = D.HEROES[key].nome
	var e = 3 if in_arena else 2
	leg_count += 1
	legend_next = ""
	fame += D.CFG.FAME_LEG
	evo += D.CFG.EVO_LEG
	check_class_unlock()
	fame_step *= D.CFG.LEG_FAME_GROW
	fame_next = maxf(fame_next + fame_step, fame + 5.0)
	ess += e
	ess_run += e
	if not in_arena:
		float_text(Vector2(W / 2.0, H / 2.0 - 30), nome.get_slice(",", 0).to_upper() + " CAIU NO CORREDOR", Color("#f2d488"), 20)
		float_text(Vector2(W / 2.0, H / 2.0 + 4), "+%d essência" % e, Color("#f2d488"), 16)
		hint("%s caiu antes de chegar à sala do guardião. Energia absorvida: +%ss. +%d de essência, mais fama e o guardião evoluiu." % [nome, D.fmt(soul), e], false, 6.0)
	if ui:
		ui.render_know()
	return e


# ===== loop =====
func _process(delta: float) -> void:
	# textos e tremida
	for t in texts:
		t.life -= delta
		t.pos.y -= 30.0 * delta / t.max
	texts = texts.filter(func(t): return t.life > 0)
	if shake_t > 0:
		shake_t -= delta
		board.shake_off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amp * 400.0
		if shake_t <= 0:
			shake_amp = 0.0
			board.shake_off = Vector2.ZERO
	if paused or (ui and ui.modal_open()):
		return
	step(delta)
	if ui:
		ui.sync()


func step(delta: float) -> void:
	if phase == "arena":
		arena.update(minf(delta, 0.05))
		return
	if phase == "reward":
		return
	var dt = minf(delta, 0.05) * speed
	for f in fx:
		f.life -= dt
	fx = fx.filter(func(f): return f.life > 0)
	var live = phase == "prep" or phase == "wave"
	if live:
		clock -= dt * clock_rate()
		if bell_cd > 0:
			bell_cd = maxf(0.0, bell_cd - dt)
		if combo_t > 0:
			combo_t -= dt
			if combo_t <= 0:
				combo = 0
	if phase == "wave":
		_wave_step(dt)
	if (phase == "prep" or phase == "wave") and clock <= 0:
		game_over()


func _wave_step(dt: float) -> void:
	var greed = 0
	for t in traps.values():
		if t.type == "ganancia" and active(t):
			greed += 1
	clock -= 0.25 * greed * dt
	for t in traps.values():
		if t.off_t > 0:
			t.off_t -= dt
	for h in heroes:
		if D.HEROES[h.type].get("legend", false):
			h.hp0 = h.hp

	# entrada de heróis
	spawn_t -= dt
	if queue.size() > 0 and spawn_t <= 0 and freeze <= 0:
		var type: String = queue.pop_front()
		var d = D.HEROES[type]
		var sc = hero_scale(wave)
		var hp: float = d.hp * sc.hp * ((1.0 + D.CFG.LEG_HP_GROWTH * leg_count) if d.get("legend", false) else 1.0)
		var h = Hero.new()
		h.type = type
		h.hp = hp
		h.max = hp
		h.dmg = sc.dps
		h.spd = sc.vel
		h.steal = d.rouba * sc.steal
		h.pos = pos_at(0)
		heroes.append(h)
		spawn_t = maxf(0.35, 1.0 - 0.04 * wave) * ev.spawnMul
		var e = center(entr.x, entr.y)
		if d.get("legend", false):
			float_text(Vector2(W / 2.0, H / 2.0), d.nome.to_upper(), Color("#f2d488"), 22)
		elif d.get("boss", false):
			float_text(Vector2(W / 2.0, H / 2.0), "CHEFE: " + d.nome, Color("#d0a245"), 26)
		elif d.get("special", false):
			float_text(e + Vector2(0, -16), d.nome, Color("#d0a245"), 13)

	# movimento
	var frozen_all = freeze > 0
	if frozen_all:
		freeze -= dt
	for h in heroes:
		var d = D.HEROES[h.type]
		h.slow = 0.0
		if not cc_imm(h.type) and not near_hero(h.pos, "andarilho", D.CFG.AURA * T):
			for key in traps:
				var t: Trap = traps[key]
				if t.type == "ampulheta" and active(t) and h.pos.distance_to(center(key.x, key.y)) <= D.TOOLS.ampulheta.alcance * T * ev.rangeMul:
					h.slow = minf(0.8, 0.45 + mods.slow) * res("ampulheta")
		if h.stun > 0:
			h.stun -= dt
		var frozen = (frozen_all and not cc_imm(h.type)) or h.stun > 0
		if not frozen and h.block == null and h.disarm.is_empty():
			h.dist += d.vel * h.spd * ev.heroSpd * (1.0 - h.slow) * dt
			if ev.regen > 0:
				h.hp = minf(h.max, h.hp + h.max * ev.regen * dt)
			var np = pos_at(h.dist)
			if absf(np.x - h.pos.x) > 0.01:
				h.face = 1 if np.x > h.pos.x else -1
			h.pos = np

	# habilidades dos heróis
	for h in heroes:
		if D.DISARMERS.has(h.type):
			work_disarm(h, dt)
		if h.type == "arqueiro":
			h.shot -= dt
			if h.shot <= 0:
				var tgt = null
				var bd = 1e9
				for m in monsters:
					if m.type == "espectro":
						continue
					var dd: float = h.pos.distance_to(m.pos)
					if dd < 2.6 * T and dd < bd:
						bd = dd
						tgt = m
				if tgt:
					tgt.hp -= 14 * h.dmg * (5.0 if tgt.type == "morcego" else 1.0) * power(tgt.type)
					fx.append({"kind": "bolt", "a": h.pos, "b": tgt.pos, "life": 0.12, "max_life": 0.12, "col": Color("#9fd36b")})
					h.shot = 0.7
		if h.type == "exorcista":
			for m in monsters:
				if m.type == "espectro" and m.life > 0 and h.pos.distance_to(m.pos) <= D.CFG.AURA * T:
					m.life = 0
					float_text(m.pos + Vector2(0, -10), "banido", Color("#a8e6ff"), 12)
		if is_mage(h.type):
			h.cd -= dt
			if h.cd <= 0:
				var tk = null
				var bd = 1e9
				for key in traps:
					if not active(traps[key]):
						continue
					var dd = h.pos.distance_to(center(key.x, key.y))
					if dd < 3.5 * T and dd < bd:
						bd = dd
						tk = key
				if tk != null:
					traps[tk].off_t = 4.0
					var c = center(tk.x, tk.y)
					fx.append({"kind": "bolt", "a": h.pos, "b": c, "life": 0.35, "max_life": 0.35, "col": Color("#6b5be0")})
					float_text(c + Vector2(0, -10), "apagada", Color("#9d8ff0"), 12)
				h.cd = 3.0
		if hpow(h.type) == "burn":
			h.shot -= dt
			if h.shot <= 0:
				h.shot = 2.0
				var hit_any = false
				for m in monsters:
					if m.type != "espectro" and h.pos.distance_to(m.pos) <= 1.6 * T:
						m.hp -= 22 * h.dmg * power(m.type)
						hit_any = true
				if hit_any:
					fx.append({"kind": "boom", "pos": h.pos, "r": 1.6 * T, "life": 0.35, "max_life": 0.35, "col": Color("#ff7020")})
		if hpow(h.type) == "summon":
			h.shot -= dt
			if h.shot <= 0:
				h.shot = 9.0
				var sc = hero_scale(wave)
				var w = Hero.new()
				w.type = "cacador"
				w.hp = D.HEROES.cacador.hp * sc.hp * 0.6
				w.max = w.hp
				w.dmg = sc.dps
				w.spd = sc.vel
				w.steal = D.HEROES.cacador.rouba * sc.steal
				w.dist = maxf(0.0, h.dist - T * 0.6)
				w.pos = pos_at(w.dist)
				heroes.append(w)
				float_text(h.pos + Vector2(0, -24), "chamou ajuda", Color("#c9a26e"), 12)
		if is_king(h.type):
			h.cd -= dt
			if h.cd <= 0:
				for o in heroes:
					if o.pos.distance_to(h.pos) <= 3 * T:
						o.hp = minf(o.max, o.hp + o.max * 0.15)
				fx.append({"kind": "ring", "pos": h.pos, "life": 0.6, "max_life": 0.6, "col": Color("#f2c94c"), "max": 3.0 * T})
				h.cd = 2.5

	# armadilhas
	for key in traps:
		var t: Trap = traps[key]
		if not active(t):
			continue
		var d = D.TOOLS[t.type]
		var cp = center(key.x, key.y)
		t.cd -= dt
		match t.type:
			"espinhos":
				for h in heroes:
					if h.type != "acrobata" and int(floor(h.pos.x / T)) == key.x and int(floor(h.pos.y / T)) == key.y:
						h.hp -= 14 * mods.esp * dt * res("espinhos")
			"besta":
				if t.cd <= 0:
					var tgt = null
					for h in heroes:
						if h.pos.distance_to(cp) <= d.alcance * T * ev.rangeMul and (tgt == null or h.dist > tgt.dist):
							tgt = h
					if tgt:
						var shielded = near_hero(tgt.pos, "escudeiro", D.CFG.AURA * T)
						tgt.hp -= 8 * mods.besta * (0.08 if shielded else 1.0) * res("besta")
						t.cd = 0.8
						fx.append({"kind": "bolt", "a": cp, "b": tgt.pos, "life": 0.1, "max_life": 0.1, "col": Color("#8aa0b8") if shielded else Color("#f2d488")})
			"fogo":
				if t.cd <= 0:
					var r: float = d.alcance * T
					var any = false
					for h in heroes:
						if h.pos.distance_to(cp) <= r:
							any = true
							if h.type != "desarmador":
								h.hp -= 18 * mods.fogo * res("fogo")
					if any:
						t.cd = 1.6
						fx.append({"kind": "boom", "pos": cp, "r": r, "life": 0.3, "max_life": 0.3, "col": Color("#e0613a")})
			"alcapao":
				if t.cd <= 0:
					var v = null
					for h in heroes:
						if h.hp <= 0 or D.HEROES[h.type].get("boss", false) or h.type == "batedor":
							continue
						if int(floor(h.pos.x / T)) != key.x or int(floor(h.pos.y / T)) != key.y:
							continue
						if not h.dodged.has(key):
							h.dodged[key] = randf() < D.CFG.KNOW_DODGE[int(kl.get("alcapao", 0))]
							if h.dodged[key]:
								float_text(h.pos + Vector2(0, -14), "pulou!", Color("#9a8e7f"), 12)
						if not h.dodged[key]:
							v = h
							break
					if v:
						v.hp = 0
						t.cd = 6.0
						fx.append({"kind": "boom", "pos": cp, "r": T * 0.6, "life": 0.3, "max_life": 0.3, "col": Color("#050403")})
						float_text(cp + Vector2(0, -14), "engolido", Color("#c9a26e"), 12)
			"runa":
				if t.cd <= 0:
					var tgt = null
					for h in heroes:
						if h.type == "piromante" or cc_imm(h.type) or h.stun > 0:
							continue
						if h.pos.distance_to(cp) <= d.alcance * T * ev.rangeMul and (tgt == null or h.dist > tgt.dist):
							tgt = h
					if tgt:
						tgt.stun = 1.5 * res("runa")
						tgt.hp -= 10 * res("runa")
						t.cd = 3.5
						fx.append({"kind": "bolt", "a": cp, "b": tgt.pos, "life": 0.2, "max_life": 0.2, "col": Color("#9fd3ff")})

	# combate em grupo: todo herói ao alcance para e luta; vários batem no mesmo alvo
	var fighters = monsters.filter(func(m): return m.type != "espectro")
	for m in fighters:
		m.blocked = heroes.filter(func(h): return h.hp > 0 and absf(h.dist - m.dist) < T * 0.7)
	for h in heroes:
		var tgt = null
		for m in fighters:
			if m.blocked.has(h) and (tgt == null or m.hp < tgt.hp):
				tgt = m
		h.block = tgt
	for m in monsters:
		var d = D.TOOLS[m.type]
		if m.type == "espectro":
			m.life -= dt
			for h in heroes:
				if h.pos.distance_to(m.pos) <= T * 0.9:
					h.hp -= m.dps * ev.monMul * mon_vs_hero(m, h) * dt * res("espectro")
		if m.type == "aranha":
			m.cd -= dt
			var near = heroes.filter(func(h): return h.pos.distance_to(m.pos) <= T * 1.2)
			if m.cd <= 0 and near.size() > 0:
				for h in near:
					if not cc_imm(h.type) and h.type != "tocheiro" and not near_hero(h.pos, "tocheiro", D.CFG.AURA * T):
						h.stun = maxf(h.stun, 1.8 * res("aranha"))
				m.cd = 4.0
				fx.append({"kind": "ring", "pos": m.pos, "life": 0.5, "max_life": 0.5, "col": Color("#e8e8e8"), "max": T * 0.8})
		if m.type == "mimico" and not m.sprung and m.blocked.size() > 0:
			var v = m.blocked[0]
			m.sprung = true
			if v.type != "cacatesouro" and not near_hero(v.pos, "cacatesouro", D.CFG.AURA * T):
				v.hp -= 60 * res("mimico") * mods.monDmg * (1.0 + D.CFG.MON_LVL_GAIN * (m.lvl - 1))
				float_text(m.pos + Vector2(0, -14), "NHAC!", Color("#e0613a"), 14)
			else:
				float_text(m.pos + Vector2(0, -14), "desmascarado", Color("#d8b45a"), 12)
		if m.blocked.size() > 0:
			var alvos: Array = m.blocked.duplicate()
			alvos.sort_custom(func(a, b): return a.hp < b.hp)
			alvos = alvos.slice(0, maxi(1, d.cap))
			var total = 0.0
			for tgt in alvos:
				var dealt: float = m.dps * ev.monMul * mon_vs_hero(m, tgt) * dt * res(m.type)
				tgt.hp -= dealt
				total += dealt
			if m.type == "vampiro" and not near_hero(m.pos, "cacavampiro", D.CFG.AURA * T):
				m.hp = minf(m.max, m.hp + total * 0.5)
		else:
			m.dist += m.dir * m.vel * dt
			if m.dist <= T * 0.5:
				m.dist = T * 0.5
				m.dir = 1
			if m.dist >= path_len - T * 0.5:
				m.dist = path_len - T * 0.5
				m.dir = -1
			var np = pos_at(m.dist)
			if absf(np.x - m.pos.x) > 0.01:
				m.face = 1 if np.x > m.pos.x else -1
			m.pos = np
	for h in heroes:
		var m = h.block
		if m == null or m.hp <= 0:
			continue
		m.hp -= D.HEROES[h.type].dps * h.dmg * hero_vs_mon(h, m) * dt * power(m.type)
	var split = []
	var keep = []
	for m in monsters:
		if m.type == "espectro":
			if m.life > 0:
				keep.append(m)
			continue
		if m.hp > 0:
			keep.append(m)
			continue
		for h in m.blocked:
			h.block = null
		if m.type == "gosma" and not m.mini and not near_hero(m.pos, "alquimista", D.CFG.AURA * T):
			split.append(m)
			float_text(m.pos + Vector2(0, -12), "dividiu!", Color("#7fcf6a"), 12)
		else:
			float_text(m.pos + Vector2(0, -12), D.TOOLS[m.type].nome + " caiu", Color("#9a8e7f"), 12)
	monsters = keep
	for m in split:
		spawn_monster("gosma", m.dist, 0, true)
		spawn_monster("gosma", minf(path_len - T * 0.5, m.dist + T * 0.7), 0, true)

	# mortes e chegadas
	for h in heroes:
		if h.hp0 >= 0 and h.hp < h.hp0:
			h.hp = h.hp0 - (h.hp0 - h.hp) * D.CFG.LEG_RES * (0.6 if hpow(h.type) == "shield" else 1.0)
	var alive = []
	var duelist = null
	for h in heroes:
		if h.hp <= 0:
			kill_hero(h)
			continue
		if h.dist >= path_len and D.HEROES[h.type].get("legend", false):
			if h.block:
				h.block.blocked.erase(h)
				h.block = null
			release_disarm(h)
			duelist = h
			continue
		if h.dist >= path_len:
			var lost = D.r1(h.steal * mods.stealMul * ev.stealMul)
			var c = center(heart.x, heart.y)
			clock -= lost
			combo = 0
			combo_t = 0.0
			if h.block:
				h.block.blocked.erase(h)
				h.block = null
			release_disarm(h)
			float_text(c + Vector2(-6, -30), "-%ss" % D.fmt(lost), Color("#e0613a"))
			fx.append({"kind": "hit", "life": 0.4, "max_life": 0.4})
			shake(0.14, 0.006)
			continue
		alive.append(h)
	heroes = alive
	if duelist and clock > 0:
		arena.start(duelist)
	elif phase == "wave" and clock > 0 and queue.is_empty() and heroes.is_empty():
		show_draft()


# ===== desenho do mapa (chamado pelo board) =====
func draw_board(c: CanvasItem) -> void:
	if phase == "arena" or phase == "reward":
		arena.draw(c)
		_draw_texts(c)
		return
	_draw_static(c)
	_draw_traps(c)
	_draw_dyn(c)
	_draw_texts(c)


func _cell_hash(x: int, y: int) -> int:
	return absi(hash(Vector3i(x, y, map_seed)))


func _draw_static(g: CanvasItem) -> void:
	var decos = ["ossos", "teia", "cogumelo", "vela", "corrente"]
	for y in ROWS:
		for x in COLS:
			var r = Rect2(x * T, y * T, T, T)
			var hs = _cell_hash(x, y)
			if on_path(x, y):
				Art.spr_r(g, "tiles/floor_%d" % (hs % 3), r)
			else:
				Art.spr_r(g, "tiles/wall_%d" % (hs % 3), r)
				if hs % 11 == 0:
					Art.spr_r(g, "tiles/deco_" + decos[(hs / 11) % decos.size()], r)
	_draw_path_readability(g)
	# sala do guardião
	if guardian != "":
		var hx = heart.x
		var hy = heart.y
		for y in range(hy - 1, hy + 2):
			for x in range(hx - 1, hx + 1):
				if y < 0 or y >= ROWS or on_path(x, y):
					continue
				Art.spr_r(g, "tiles/guard_floor", Rect2(x * T, y * T, T, T))
		for sp in [Vector2i(hx - 1, hy - 1), Vector2i(hx - 1, hy + 1), Vector2i(hx, hy - 1), Vector2i(hx, hy + 1)]:
			if sp.y >= 0 and sp.y < ROWS and not on_path(sp.x, sp.y):
				var cc = center(sp.x, sp.y)
				Art.draw_guard(g, guard_key(), cc.x, cc.y + 18, 0.5, 1, false, "idle%d" % (int(Time.get_ticks_msec() / 250) % 4))
				break
	# entrada
	var ec = center(entr.x, entr.y)
	var rot = 0.0
	match side:
		"left": rot = -PI / 2
		"bottom": rot = PI
	Art.spr_c(g, "tiles/entrance", ec.x, ec.y, 2.0, rot)


## Deixa o corredor impossível de confundir com o fundo:
## paredes escurecidas, parede com face frontal (altura), sombra e borda no chão e setas de fluxo até o coração.
func _draw_path_readability(g: CanvasItem) -> void:
	var dim = Color(0.03, 0.02, 0.07, 0.38)
	var face = Color8(62, 50, 76)
	var face_hi = Color8(96, 82, 112)
	var face_lo = Color8(34, 26, 44)
	var edge = Color8(20, 12, 28)
	for y in ROWS:
		for x in COLS:
			if on_path(x, y):
				continue
			g.draw_rect(Rect2(x * T, y * T, T, T), dim)
			# parede logo acima do corredor: mostra a face da parede (dá altura)
			if y + 1 < ROWS and on_path(x, y + 1):
				var fy = y * T + T - 12
				g.draw_rect(Rect2(x * T, fy, T, 12), face)
				g.draw_rect(Rect2(x * T, fy, T, 2), face_hi)
				g.draw_rect(Rect2(x * T, fy + 10, T, 2), face_lo)
				for bx in [8, 22, 34]:
					g.draw_rect(Rect2(x * T + bx, fy + 2, 2, 8), face_lo)
	for t in route:
		var px = t.x * T
		var py = t.y * T
		var up_wall = t.y - 1 >= 0 and not on_path(t.x, t.y - 1)
		var dn_wall = t.y + 1 < ROWS and not on_path(t.x, t.y + 1)
		var lf_wall = t.x - 1 >= 0 and not on_path(t.x - 1, t.y)
		var rt_wall = t.x + 1 < COLS and not on_path(t.x + 1, t.y)
		# sombra projetada pela parede de cima e pelas laterais
		if up_wall:
			g.draw_rect(Rect2(px, py, T, 8), Color(0, 0, 0, 0.32))
			g.draw_rect(Rect2(px, py + 8, T, 4), Color(0, 0, 0, 0.14))
		if lf_wall:
			g.draw_rect(Rect2(px, py, 4, T), Color(0, 0, 0, 0.22))
		if rt_wall:
			g.draw_rect(Rect2(px + T - 4, py, 4, T), Color(0, 0, 0, 0.22))
		# borda escura nítida entre chão e parede
		if up_wall:
			g.draw_rect(Rect2(px, py, T, 2), edge)
		if dn_wall:
			g.draw_rect(Rect2(px, py + T - 2, T, 2), edge)
		if lf_wall:
			g.draw_rect(Rect2(px, py, 2, T), edge)
		if rt_wall:
			g.draw_rect(Rect2(px + T - 2, py, 2, T), edge)
	# setas de fluxo: mostram para onde os heróis andam (onda suave até o coração)
	var tm = Time.get_ticks_msec() / 1000.0
	for i in range(1, route.size() - 1, 2):
		var a: Vector2i = route[i]
		var b: Vector2i = route[i + 1]
		var dir = Vector2(b - a)
		var c = center(a.x, a.y)
		var k = 0.1 + 0.22 * maxf(0.0, sin(tm * 3.0 - i * 0.45))
		var col = Color(0.36, 0.22, 0.14, k * 1.6)
		var side = Vector2(-dir.y, dir.x)
		var tip = c + dir * 6
		for o in [0.0, -6.0]:
			var tp: Vector2 = tip + dir * o
			g.draw_line(tp, tp - dir * 6 + side * 6, col, 3)
			g.draw_line(tp, tp - dir * 6 - side * 6, col, 3)


func _draw_traps(g: CanvasItem) -> void:
	for key in traps:
		var t: Trap = traps[key]
		var c = center(key.x, key.y)
		var mod = Color(0.45, 0.42, 0.5, 0.7) if t.off else (Color(0.6, 0.55, 1.0) if t.off_t > 0 else Color.WHITE)
		Art.spr_c(g, Art.trap_name(t.type, t.type == "alcapao" and t.cd > 0 and not t.off), c.x, c.y, 2.0, 0.0, mod)
		if t.off:
			var gc = Color(0.6, 0.56, 0.5, 0.9)
			g.draw_line(c + Vector2(-10, -10), c + Vector2(10, 10), gc, 4)
			g.draw_line(c + Vector2(10, -10), c + Vector2(-10, 10), gc, 4)
		if t.prog > 0 and not t.off:
			g.draw_arc(c, 17, 0, TAU, 24, Color(0.04, 0.035, 0.03, 0.8), 6)
			g.draw_arc(c, 17, -PI / 2, -PI / 2 + TAU * minf(1.0, t.prog), 24, Color("#ff7040"), 4)
		var d = D.TOOLS[t.type]
		if d.has("alcance") and not d.on_path and t.type != "besta" and not t.off:
			g.draw_circle(c, d.alcance * T, D.col(d.cor, 0.06))


func _draw_dyn(g: CanvasItem) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	for m in monsters:
		var sc = 1.2 if m.mini else 2.0
		var feet = m.pos + Vector2(0, 14)
		Art.ellipse(g, feet, 11 * sc / 2.0, 4, Color(0, 0, 0, 0.35))
		var a = clampf(m.life / 4.0, 0.2, 1.0) * 0.8 if m.type == "espectro" else 1.0
		var hop = -absf(sin(now * 8 + m.dist * 0.05)) * 2 if m.blocked.is_empty() else 0.0
		if m.type in ["espectro", "morcego"]:
			hop = sin(now * 4 + m.dist * 0.05) * 3 - 6
		var nm = Art.mon_name(m.type, m.sprung)
		Art.spr(g, nm, feet.x, feet.y + hop, sc, m.face < 0, Color(1, 1, 1, a))
		var top = feet.y - Art.height(nm) * sc - 4
		if m.blocked.size() > 0 and m.type != "espectro":
			# golpe de monstro: garra quente e grossa, com poeira no impacto
			var ph = fmod(now + m.dist * 0.013, 0.6)
			if ph > 0.4:
				var fr = mini(2, int((ph - 0.4) / 0.07))
				var tg: Vector2 = m.blocked[0].pos
				Art.spr_c(g, "fx/slash_claw_%d" % fr, lerpf(m.pos.x, tg.x, 0.6), tg.y, 0.6, 0.0, Color.WHITE, tg.x < m.pos.x)
				Art.spr_c(g, "fx/spark_guard_%d" % fr, tg.x, tg.y + 4, 0.9)
		if m.type != "espectro":
			var pc = maxf(0.0, m.hp / m.max)
			g.draw_rect(Rect2(m.pos.x - 13, top, 26, 4), Color("#140c1c"))
			g.draw_rect(Rect2(m.pos.x - 13, top, 26 * pc, 4), Color("#ffc430"))
		if not m.mini:
			var n = mini(m.lvl, 6)
			for i in n:
				g.draw_rect(Rect2(m.pos.x - n * 2.5 + i * 5, feet.y + 3, 3, 3), Color("#ffc430"))
		if m.blocked.size() > 0 and int(now * 6) % 2 == 0:
			Art.dot(g, Vector2(m.pos.x + 12, top + 2), 4, Color("#ff7040"))
	if hover.x >= 0 and (phase == "prep" or phase == "wave") and hover.x < COLS and hover.y >= 0 and hover.y < ROWS:
		var c = center(hover.x, hover.y)
		var rr = Rect2(hover.x * T + 2, hover.y * T + 2, T - 4, T - 4)
		if is_heart(hover.x, hover.y):
			g.draw_rect(rr.grow(4), Color("#7fd1e0"), false, 2)
		elif traps.has(hover):
			g.draw_rect(rr, Color("#ff7040"), false, 2)
		else:
			var ok = can_place(tool, hover.x, hover.y)
			g.draw_rect(rr, Color("#ffc430") if ok else Color("#6b3a30"), false, 2)
			if ok:
				Art.draw_icon(g, tool, c.x, c.y, 0.5)
				if D.TOOLS[tool].has("alcance"):
					g.draw_arc(c, D.TOOLS[tool].alcance * T, 0, TAU, 48, D.col(D.TOOLS[tool].cor, 0.5), 2)
	for f in fx:
		var k: float = f.life / f.max_life
		match f.kind:
			"bolt":
				var bc: Color = f.col
				bc.a = minf(1.0, f.life / 0.1)
				g.draw_line(f.a, f.b, bc, 2)
				Art.dot(g, f.b, 4, bc)
			"boom":
				var bc: Color = f.col
				for i in 10:
					var an = i / 10.0 * TAU
					var rad: float = f.r * (0.3 + 0.7 * (1.0 - k))
					Art.dot(g, f.pos + Vector2(cos(an), sin(an)) * rad, 6 * k + 2, Color(bc.r, bc.g, bc.b, k))
			"hit":
				g.draw_circle(center(heart.x, heart.y), 30, Color(0.9, 0.2, 0.25, k * 0.35))
			"ring":
				var rc: Color = f.col
				rc.a = k
				g.draw_arc(f.pos, 20 + (1.0 - k) * f.max, 0, TAU, 32, rc, 3)
			"soul":
				var p = 1.0 - k
				var pos: Vector2 = f.from.lerp(f.to, p * p) + Vector2(0, -sin(p * PI) * 30)
				var sc: Color = f.col
				Art.dot(g, pos, 12 if f.big else 8, Color(sc.r, sc.g, sc.b, 0.3))
				Art.dot(g, pos, 6 if f.big else 4, sc)
				Art.dot(g, pos.lerp(f.from, 0.08), 2, sc)
	var boss = null
	var sorted = heroes.duplicate()
	sorted.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	for h in sorted:
		var d = D.HEROES[h.type]
		if d.get("boss", false):
			boss = h
		if d.get("aura", false):
			g.draw_circle(h.pos, D.CFG.AURA * T, D.col(d.cor, 0.06))
			g.draw_arc(h.pos, D.CFG.AURA * T, 0, TAU, 40, D.col(d.cor, 0.3), 2)
		var feet: Vector2 = h.pos + Vector2(0, 14)
		Art.ellipse(g, feet, 10 if not d.get("boss", false) else 14, 4, Color(0, 0, 0, 0.35))
		var frozen = (freeze > 0 or h.stun > 0) and not cc_imm(h.type)
		var walking: bool = not frozen and h.block == null and h.disarm.is_empty()
		var hop = -absf(sin(now * 10 + h.dist * 0.08)) * 3 if walking else 0.0
		var mod = Color(0.6, 0.85, 1.0) if frozen else Color.WHITE
		var nm = "heroes/" + h.type
		var fighting: bool = h.block != null and not frozen
		if Art.tex(nm + "_walk0") != null:
			# andar: quadro pela distância andada (os pés não deslizam); lutar: preparo e golpe
			if fighting:
				var ph = fmod(now + h.dist * 0.01, 0.5)
				nm += "_atk1" if ph > 0.32 else "_atk0"
			elif walking:
				nm += "_walk%d" % (int(h.dist / 6.0) % 4)
			else:
				nm += "_walk0"
			hop = 0.0
		Art.spr(g, nm, feet.x, feet.y + hop, 2.0, h.face < 0, mod)
		if fighting:
			# golpe de herói: corte fino e frio, com faísca em cruz no alvo
			var ph2 = fmod(now + h.dist * 0.01, 0.5)
			if ph2 > 0.32:
				var fr = mini(2, int((ph2 - 0.32) / 0.06))
				var tgt: Vector2 = h.block.pos
				Art.spr_c(g, "fx/slash_hero_%d" % fr, lerpf(h.pos.x, tgt.x, 0.6), h.pos.y + 2, 0.7, 0.0, Color.WHITE, h.face < 0)
				Art.spr_c(g, "fx/spark_hero_%d" % fr, tgt.x, tgt.y + 2, 1.0)
		var top = feet.y - Art.height(nm) * 2.0 - 2
		if d.get("special", false):
			Art.dot(g, Vector2(h.pos.x, top - 6 + hop), 6, Color("#ffc430"))
			Art.dot(g, Vector2(h.pos.x, top - 6 + hop), 2, Color("#140c1c"))
		if not h.disarm.is_empty():
			var k2: Vector2i = h.disarm.key
			g.draw_line(h.pos, center(k2.x, k2.y), Color(1, 0.44, 0.25, 0.7), 2)
		if h.slow > 0 and not frozen:
			Art.dot(g, Vector2(h.pos.x - 10, top + 6), 4, Color("#7fd1e0"))
		if not d.get("boss", false):
			var w = 26.0
			var pc = maxf(0.0, h.hp / h.max)
			g.draw_rect(Rect2(h.pos.x - w / 2, top, w, 4), Color("#140c1c"))
			g.draw_rect(Rect2(h.pos.x - w / 2, top, w * pc, 4), Color("#96e65a") if pc > 0.4 else Color("#ff4050"))
	if freeze > 0:
		g.draw_rect(Rect2(0, 0, W, H), Color(0.5, 0.82, 0.95, 0.07))
	if boss:
		var pc = maxf(0.0, boss.hp / boss.max)
		g.draw_rect(Rect2(W * 0.2, 8, W * 0.6, 14), Color(0.08, 0.05, 0.11, 0.9))
		g.draw_rect(Rect2(W * 0.2 + 2, 10, (W * 0.6 - 4) * pc, 10), D.col(D.HEROES[boss.type].cor))
		Art.text(g, Vector2(W / 2.0, 32), D.HEROES[boss.type].nome, Color("#ece2d2"), 13)
	# coração-relógio
	var hc = center(heart.x, heart.y)
	Art.spr_c(g, "tiles/heart", hc.x, hc.y, 2.0, 0.0, Color(0.7, 0.6, 0.5) if bell_cd > 0 else Color.WHITE)
	var ang = -PI / 2 + fmod(maxf(clock, 0.0), 60.0) / 60.0 * TAU
	g.draw_line(hc, hc + Vector2(cos(ang), sin(ang)) * 11, Color("#ff4050") if clock < 10 else Color("#fff0c0"), 3)
	Art.dot(g, hc, 4, Color("#ffc430"))


func _draw_texts(g: CanvasItem) -> void:
	for t in texts:
		var c: Color = t.c
		c.a = clampf(t.life / t.max * 1.5, 0.0, 1.0)
		Art.text(g, t.pos, t.s, c, t.size)
