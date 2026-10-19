extends RefCounted
## Sala do guardião: luta de ação lateral contra o lendário. Você controla o guardião.
## A vida do guardião é o relógio. O lendário estuda como você luta.
## A classe do guardião (data.gd → CLASSES) muda arma, ataque básico, movimento, passiva e habilidades.
## Ataque básico em 4 tempos (docs/GUIA-ANIMACAO.md): antecipação → smear → impacto → recuperação, com hit stop.

const D = preload("res://scripts/data.gd")
const Art = preload("res://scripts/art.gd")

const W := 720.0
const H := 480.0
const FY := 436.0
const AW0 := 18.0
const AW1 := 702.0
const GRAV := 1500.0
const PLATS := [Vector3(110, 240, 330), Vector3(480, 610, 330), Vector3(300, 420, 236)]  # x1, x2, y

var game
var on := false
var key := ""
var t := 0.0
var intro := 0.0
var over := 0.0
var win := 0          # 0 lutando, 1 venceu, -1 perdeu
var clock0 := 1.0
var leg_scale := 1.0  # multiplicador do dano do lendário (relógio de entrada e ordem do lendário)
var hitstop := 0.0
var gd := {}          # guardião + classe (montado no início da luta)
var P := {}
var B := {}
var hz: Array = []    # golpes e projéteis do lendário
var shots: Array = [] # projéteis e invocações do guardião
var zones: Array = [] # áreas do guardião (nevasca, veneno, fogo)
var mins: Array = []  # esqueletos aliados
var vfx: Array = []   # rastros e faíscas (só visual)
var parts: Array = []
var wall := {}
var use := {}
var press := {}
var stats := {}       # para os testes de balanceamento


func G() -> Dictionary:
	return gd


func L() -> Dictionary:
	return D.LEG_ARENA[key]


func LFX(k: String, def = "") :
	return L().get("fx", {}).get(k, def)


## Junta os dados do guardião com os da classe escolhida.
func build_gd() -> Dictionary:
	var base: Dictionary = D.GUARDS[game.guardian]
	var c: Dictionary = D.CLASSES[game.guardian][game.g_cls]
	var o = base.duplicate(true)
	o.nome = c.nome
	o.spd = base.spd * c.spd
	o.jump = base.jump * c.jump
	o.jumps = c.jumps
	o.armor = c.armor
	o.atk = c.atk
	var lo: Array = game.loadout(game.guardian, game.g_cls)
	o.skills = lo.slice(0, 3)
	o.ult = lo[3]
	o.passive = c.passive
	o.cls = game.g_cls
	o.pw = D.CLASS_POWER[game.g_cls].dmg
	o.def = D.CLASS_POWER[game.g_cls].def
	# talentos da classe (especializados)
	var tf: Dictionary = game.talent_fx("%s_%d" % [game.guardian, game.g_cls])
	o.spd *= 1.0 + tf.get("spd", 0.0)
	o.t_atk = 1.0 + tf.get("atk_dmg", 0.0)
	o.t_atkcd = 1.0 - tf.get("atk_cd", 0.0)
	o.t_range = 1.0 + tf.get("atk_range", 0.0)
	o.t_sk = []
	o.t_skcd = []
	o.t_dur = []
	for i in 3:
		o.t_sk.append(1.0 + tf.get("sk%d_pow" % i, 0.0))
		o.t_skcd.append(1.0 - tf.get("sk%d_cd" % i, 0.0))
		o.t_dur.append(1.0 + tf.get("sk%d_dur" % i, 0.0))
	o.ult_pow = 1.0 + tf.get("ult_pow", 0.0)
	o.ult_gain = 1.0 + tf.get("ult_gain", 0.0)
	o.t_pass = 1.0 + tf.get("pass", 0.0)
	o.rage_cap = 10 + int(tf.get("rage_cap", 0.0))
	o.shot_n = int(tf.get("shot_n", 0.0))
	o.pierce = tf.get("pierce", 0.0) > 0
	o.jumps += int(tf.get("jumps", 0.0))
	o.pcap = 8 + int(tf.get("poison_cap", 0.0))
	o.skel = 1.0 + tf.get("skel", 0.0)
	o.t_leech = tf.get("leech", 0.0)
	o.def *= 1.0 - tf.get("def", 0.0)
	# upgrades básicos do guardião (valem para todas as classes)
	var gu = func(id): return game.gup_lv(game.guardian, id)
	o.pw *= 1.0 + 0.05 * gu.call("forca")
	o.def *= 1.0 - 0.04 * gu.call("resist")
	var pd = 1.0 + 0.06 * gu.call("poder")
	for i in 3:
		o.t_sk[i] *= pd
	o.ult_pow *= pd
	o.spd *= 1.0 + 0.03 * gu.call("agil")
	o.t_dash = 1.0 - 0.05 * gu.call("agil")
	o.ult_start = 6.0 * gu.call("impeto")
	o.key = "%s_%d" % [game.guardian, game.g_cls]
	if game.guardian == "dragao" and game.g_cls == 3:
		o.w = 44
		o.h = 42
	return o


static func clamp_x(x: float, w: float) -> float:
	return clampf(x, AW0 + w / 2.0, AW1 - w / 2.0)


static func overlap(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b)


func body_b() -> Rect2:
	var l = L()
	return Rect2(B.x - l.w / 2.0, B.y - l.h, l.w, l.h)


func body_p() -> Rect2:
	return Rect2(P.x - gd.w / 2.0 + 4, P.y - gd.h + 4, gd.w - 8, gd.h - 6)


func wall_rect() -> Rect2:
	return Rect2(wall.x - 12, FY - 96, 24, 96)


func sk_key(i: int) -> String:
	return gd.skills[i]


func sk_lv(i: int) -> int:
	return game.sk_level(sk_key(i)) + game.skill_perm(game.guardian, game.g_cls, sk_key(i))


func sk_pow(i: int) -> float:
	return (1.0 + 0.35 * (sk_lv(i) - 1)) * gd.t_sk[i]


func sk_dur(i: int) -> float:
	return (1.0 + 0.2 * (sk_lv(i) - 1)) * gd.t_dur[i]


func sk_cd(i: int) -> float:
	return float(game.skill_info(sk_key(i)).cd) * (1.0 - 0.12 * (sk_lv(i) - 1)) * gd.t_skcd[i]


func dmg_mul() -> float:
	return (1.0 + game.evo_pct()) * gd.pw * (1.5 if P.fury_t > 0 else 1.0) * (2.0 if P.get("king_t", 0.0) > 0 else 1.0) * (1.0 + 0.04 * gd.t_pass * P.rage)


func spawn_parts(x: float, y: float, col: Color, n: int) -> void:
	for i in n:
		parts.append({"x": x, "y": y, "vx": (randf() - 0.5) * 260, "vy": -randf() * 220, "r": 1.5 + randf() * 2.5, "col": col, "life": 0.35 + randf() * 0.3, "max": 0.65})


func add_vfx(spr: String, x: float, y: float, dur: float, flip := false, scale := 2.0, rot := 0.0) -> void:
	vfx.append({"spr": spr, "x": x, "y": y, "t": 0.0, "dur": dur, "flip": flip, "scale": scale, "rot": rot})


func move_body(o: Dictionary, w: float, dt: float, plats: bool, grav := 1.0) -> void:
	o.vy += GRAV * dt * grav
	var prev_y: float = o.y
	o.x = clamp_x(o.x + o.vx * dt, w)
	o.y += o.vy * dt
	o.ground = false
	if o.y >= FY:
		o.y = FY
		o.vy = 0.0
		o.ground = true
	elif plats and o.vy >= 0:
		for p in PLATS:
			if prev_y <= p.z + 1 and o.y >= p.z and o.x > p.x - w * 0.3 and o.x < p.y + w * 0.3:
				o.y = p.z
				o.vy = 0.0
				o.ground = true
				break


func boss_swing() -> void:
	if B.is_empty():
		return
	if B.vis_atk <= 0:
		B.atk_anim = 0.0
	B.vis_atk = 0.3


func add_hz(o: Dictionary) -> void:
	var z = {"x": 0.0, "y": 0.0, "w": 10.0, "h": 10.0, "tele": 0.0, "life": 0.0, "max_life": 0.0, "dmg": 0.0, "vx": 0.0, "vy": 0.0, "g": 0.0, "ax": 0.0,
		"once": true, "warn": false, "mark": false, "orb": false, "rock": false, "wave": false, "pillar": false, "melee": false,
		"floor_stop": false, "landed": false, "hit_done": false, "col": Color("#ffd0c0"), "spr": "", "spin": false, "anim": "",
		"on_land": "", "trap": false, "clone": false, "whip": false, "pool": false, "face": 1, "root": 0.0}
	for k in o:
		z[k] = o[k]
	z.max_life = maxf(z.life, 0.01)
	hz.append(z)
	if not z.warn and z.tele <= 0.3 and not B.is_empty():
		boss_swing()


func shockwaves(x: float) -> void:
	for dir in [-1, 1]:
		add_hz({"x": x - 13, "y": FY - 28, "w": 26.0, "h": 28.0, "life": 2.0, "vx": dir * 360.0, "dmg": L().hit * 0.8, "wave": true, "col": Color("#d6c3a5")})


# ===== início e fim =====
func start(h) -> void:
	key = h.type
	var l = L()
	gd = build_gd()
	var mx: float = l.hp * D.CFG.LEG_ARENA_HP * (1.0 + D.CFG.LEG_HP_GROWTH * game.leg_count) * (1.0 + game.fame_pct() * D.CFG.LEG_FAME_HP)
	var carry = clampf(h.hp / h.max, 0.15, 1.0)
	game.phase = "arena"
	game.combo = 0
	game.combo_t = 0.0
	game.paused = false
	game.clock += D.CFG.ARENA_BONUS
	on = true
	t = 0.0
	intro = 1.6
	over = 0.0
	win = 0
	hitstop = 0.0
	clock0 = game.clock
	leg_scale = maxf(D.CFG.LEG_DMG_MIN, pow(clock0 / D.CFG.LEG_DMG_REF, D.CFG.LEG_DMG_EXP)) * (1.0 + D.CFG.LEG_DMG_GROWTH * game.leg_count)
	P = {"x": 150.0, "y": FY, "vx": 0.0, "vy": 0.0, "face": 1, "ground": true, "jumps": 0, "dash_t": 0.0, "dash_cd": 0.0,
		"atk_ph": "", "atk_pt": 0.0, "atk_cd": 0.0, "hit_b": false, "cd": [1.2, 2.0, 3.0], "cd_max": [1.2, 2.0, 3.0],
		"fury_t": 0.0, "scale_t": 0.0, "scale_pow": 1.0, "tick2": 0.0, "breath_t": 0.0, "breath_pow": 1.0, "tick": 0.0,
		"charge_t": 0.0, "charge_hit": false, "charge_dmg": 40.0, "charge_spd": 640.0, "charge_stun": 0.0, "charge_poison": 0, "slam": 0.0,
		"dive_t": 0.0, "dive_hop": false, "dive_hit": false, "dive_pow": 1.0,
		"inv": 0.0, "flash": 0.0, "kb_t": 0.0, "kb": 0.0, "shot_vis": 0.0, "cast_vis": 0.0, "run_d": 0.0,
		"spin_t": 0.0, "spin_pow": 1.0, "spin_tick": 0.0, "leech_t": 0.0, "leech_amt": 0.5,
		"block_t": 0.0, "block_pow": 1.0, "block_tick": 0.0, "quake_n": 0, "quake_t": 0.0, "quake_pow": 1.0,
		"ice_t": 0.0, "fly_t": 0.0, "haste_t": 0.0, "wing_t": 0.0, "wing_pow": 1.0, "wing_hit": false, "wing_drop": 0.0,
		"echo_n": 0, "rage": 0, "harvest": 0, "root_t": 0.0, "lost": [],
		"ult": minf(100.0, D.ULT_CHARGE_START + gd.ult_start), "king_t": 0.0, "ult_charges": 0}
	B = {"x": W - 150.0, "y": FY, "vx": 0.0, "vy": 0.0, "face": -1, "hp": mx * carry, "max": mx, "act": {}, "idle": 1.0,
		"guard": 0.0, "inv": 0.0, "flash": 0.0, "tele": 0.0, "ground": true, "phase2": B_phase2(mx * carry, mx), "last": "",
		"stun": 0.0, "mark_t": 0.0, "mark_lv": 1, "vis_atk": 0.0, "atk_anim": 0.0, "hurt_t": 0.0, "run_d": 0.0,
		"slow_t": 0.0, "stop_t": 0.0, "vuln_t": 0.0, "poison": 0, "poison_tick": 0.5, "poison_decay": 2.0}
	hz = []
	shots = []
	zones = []
	mins = []
	vfx = []
	parts = []
	wall = {}
	use = {"dash": 0, "pulo": 0, "especial": 0, "near": 0.0, "far": 0.0, "time": 0.0}
	press = {}
	stats = {"hits": 0, "lost": 0.0}
	game.float_text(Vector2(W / 2, H / 2 - 40), D.HEROES[key].nome.to_upper(), Color("#f2d488"), 24)
	game.float_text(Vector2(W / 2, H / 2), "A sala do guardião desperta  +%ds" % int(D.CFG.ARENA_BONUS), Color("#9fd36b"), 14)
	game.hint("%s chegou ao coração. Lute como %s: cada golpe que você leva tira segundos do relógio." % [D.HEROES[key].nome, gd.nome], true, 3.5)
	game.ui.enter_arena()


static func B_phase2(hp: float, mx: float) -> bool:
	return hp <= mx * 0.5


func stop() -> void:
	on = false
	if game and game.ui:
		game.ui.leave_arena()


# ===== entrada =====
func _read_input() -> void:
	press = {}
	for a in ["g_jump", "g_dash", "g_s0", "g_s1", "g_s2", "g_ult"]:
		if Input.is_action_just_pressed(a):
			press[a] = true


# ===== guardião: habilidades =====
func busy() -> bool:
	return P.charge_t > 0 or P.dive_t > 0 or P.ice_t > 0 or P.wing_t > 0 or P.block_t > 0


func cast_skill(i: int) -> void:
	var l = L()
	var k = sk_key(i)
	var pw = sk_pow(i) * dmg_mul()
	var du = sk_dur(i)
	var lv = sk_lv(i)
	P.cd[i] = sk_cd(i)
	P.cd_max[i] = P.cd[i]
	P.cast_vis = 0.3
	use.especial += 1
	react_special()
	var bx: float = B.x
	var by: float = B.y - l.h / 2.0
	if D.ALT_SKILLS.has(k):
		run_mechs(D.ALT_SKILLS[k].mechs, pw, du)
		return
	match k:
		"investida", "investida_longa", "chifrada", "ferrao":
			var cfg = {"investida": [0.42, 640.0, 40.0, 0.0, 0], "investida_longa": [0.7, 720.0, 55.0, 0.0, 0],
				"chifrada": [0.2, 700.0, 24.0, 1.2, 0], "ferrao": [0.18, 760.0, 14.0, 0.0, 4]}[k]
			P.charge_t = cfg[0] * (du if k != "chifrada" and k != "ferrao" else 1.0)
			P.charge_spd = cfg[1]
			P.charge_dmg = cfg[2] * pw
			P.charge_stun = cfg[3] * du
			P.charge_poison = cfg[4] + (lv - 1) * 2 if cfg[4] > 0 else 0
			P.inv = maxf(P.inv, P.charge_t + 0.05)
			P.charge_hit = false
		"pisao":
			if P.ground:
				stomp(pw, lv)
			else:
				P.slam = pw
				P.vy = 950.0
		"terremoto":
			P.quake_n = 3
			P.quake_t = 0.0
			P.quake_pow = pw * 0.8
		"furia":
			P.fury_t = 5.0 * du
			spawn_parts(P.x, P.y - gd.h / 2.0, Color("#e0613a"), 14)
			game.float_text(Vector2(P.x, P.y - gd.h - 18), "FÚRIA", Color("#e0613a"), 14)
		"redemoinho":
			P.spin_t = 1.3 * du
			P.spin_pow = pw
			P.spin_tick = 0.0
		"sede":
			P.leech_t = 5.0 * du
			P.leech_amt = 0.5 * du
			spawn_parts(P.x, P.y - gd.h / 2.0, Color("#ff4050"), 12)
			game.float_text(Vector2(P.x, P.y - gd.h - 18), "SEDE", Color("#ff4050"), 14)
		"postura":
			P.block_t = 2.0 * du
			P.block_pow = pw
			P.block_tick = 0.0
		"arremesso":
			shots.append(_shot({"x": P.x + P.face * 20, "y": P.y - gd.h * 0.6, "vx": P.face * 780.0, "r": 9.0, "dmg": 26 * pw, "spr": "fx/spear", "pierce": true}))
		"estouro":
			for j in 3:
				var sx = AW0 + 10 if P.face > 0 else AW1 - 10
				shots.append(_shot({"x": sx, "y": FY - 24 - j * 6, "vx": P.face * 560.0, "r": 22.0, "dmg": 22 * pw, "spr": "fx/bull", "anim": true, "pierce": true, "delay": j * 0.35, "life": 2.6, "kind": "bull"}))
			game.shake(0.5, 0.004)
		"coroa":
			var sy: float = P.y - gd.h * 0.62
			var base = atan2(by - sy, bx - P.x)
			for j in range(-3, 4):
				var a = base + j * 0.15
				shots.append(_shot({"x": P.x, "y": sy, "vx": cos(a) * 540, "vy": sin(a) * 540, "r": 6.0, "dmg": 9 * pw, "spr": "fx/shard"}))
			P.inv = maxf(P.inv, 0.3)
		"muralha":
			wall = {"x": clamp_x(P.x + P.face * 48, 24), "life": 3.0 * du, "dmg": 22 * pw}
			spawn_parts(wall.x, FY - 20, Color("#e8e8e8"), 12)
		"drenar":
			B.mark_t = 4.0 * du
			B.mark_lv = lv
			spawn_parts(bx, by, Color("#b06fd8"), 14)
			game.float_text(Vector2(bx, B.y - l.h - 18), "marcado", Color("#c99af0"), 13)
		"erguer":
			for j in 2:
				summon_skel(8.0 * du, 5.0 * pw, P.x + (j * 2 - 1) * 30)
		"explosao":
			var n = 0
			for m in mins:
				n += 1
				_boom(m.x, m.y - 16, 90.0, 20.0 * pw, Color("#c08ae0"))
			mins = []
			if n == 0:
				_boom(bx, by, 60.0, 12.0 * pw, Color("#c08ae0"))
		"lanca_gelo":
			shots.append(_shot({"x": P.x + P.face * 20, "y": P.y - gd.h * 0.6, "vx": P.face * 820.0, "r": 9.0, "dmg": 18 * pw, "spr": "fx/ice_spear", "pierce": true, "slow": 2.5 * du}))
		"nevasca":
			zones.append({"x": bx, "w": 150.0, "h": 220.0, "life": 3.0 * du, "tick": 0.25, "tcd": 0.0, "dmg": 3.0 * pw, "follow": true, "kind": "snow", "slow": 0.6, "poison": 0})
		"bloco":
			P.ice_t = 1.6 * du
			P.inv = maxf(P.inv, P.ice_t)
			game.clock += 1.5 * sk_pow(i)
			game.float_text(Vector2(P.x, P.y - gd.h - 18), "+%ss" % D.fmt(1.5 * sk_pow(i)), Color("#9fd3ff"), 13)
		"parar":
			B.stop_t = 1.8 * du
			game.float_text(Vector2(bx, B.y - l.h - 18), "tempo parado", Color("#f2d488"), 13)
			spawn_parts(bx, by, Color("#f2d488"), 16)
		"rebobinar":
			var back = 0.0
			for e in P.lost:
				if t - e[0] <= 4.0:
					back += e[1]
			back = maxf(1.0, back * minf(0.9, 0.5 * sk_pow(i)))
			game.clock += back
			P.lost = []
			game.float_text(Vector2(P.x, P.y - gd.h - 18), "+%ss" % D.fmt(back), Color("#f2d488"), 15)
			spawn_parts(P.x, P.y - gd.h / 2.0, Color("#f2d488"), 16)
		"eco":
			P.echo_n = 4 + lv * 2
			game.float_text(Vector2(P.x, P.y - gd.h - 18), "eco ×%d" % P.echo_n, Color("#c08ae0"), 13)
		"baforada":
			P.breath_t = 1.1 * du
			P.tick = 0.0
			P.breath_pow = pw
		"mergulho":
			P.dive_t = 1.0
			P.dive_pow = pw
			P.dive_hit = false
			P.inv = maxf(P.inv, 0.6)
			if P.ground:
				P.vy = -460.0
				P.ground = false
				P.dive_hop = true
			else:
				P.dive_hop = false
				P.vy = 820.0
		"escamas":
			P.scale_t = 4.0 * du
			P.scale_pow = pw
			P.tick2 = 0.0
			spawn_parts(P.x, P.y - gd.h / 2.0, Color("#ff8a3d"), 14)
		"raio":
			shots.append(_shot({"kind": "bolt", "x": bx, "y": 0.0, "delay": 0.3, "dmg": 22 * pw, "stun": 0.6 * du, "track": true, "life": 0.5}))
		"tempestade":
			for j in 3:
				shots.append(_shot({"kind": "bolt", "x": bx, "y": 0.0, "delay": 0.3 + j * 0.4, "dmg": 18 * pw, "stun": 0.4, "track": true, "life": 0.5}))
		"voo":
			P.fly_t = 3.0 * du
			spawn_parts(P.x, P.y - gd.h / 2.0, Color("#60d8f4"), 12)
		"nuvem":
			zones.append({"x": bx, "w": 150.0, "h": 120.0, "life": 4.0 * du, "tick": 0.5, "tcd": 0.0, "dmg": 1.5 * pw, "follow": false, "kind": "poison", "slow": 0.0, "poison": 1})
		"muda":
			P.inv = maxf(P.inv, 1.2 * du)
			P.haste_t = 3.0 * du
			spawn_parts(P.x, P.y - gd.h / 2.0, Color("#96e65a"), 16)
		"meteoro":
			shots.append(_shot({"kind": "meteor", "x": bx - 60 * P.face, "y": -40.0, "vx": 60.0 * P.face, "vy": 720.0, "dmg": 32 * pw, "r": 70.0, "spr": "fx/meteor", "life": 3.0, "delay": 0.2, "tx": bx}))
		"rugido":
			if B.inv <= 0:
				B.stun = maxf(B.stun, 1.0 * du)
			B.vuln_t = 4.0 * du
			game.shake(0.3, 0.006)
			for r in 3:
				vfx.append({"spr": "", "ring": true, "x": P.x, "y": P.y - gd.h / 2.0, "t": -r * 0.08, "dur": 0.45, "flip": false, "scale": 1.0, "rot": 0.0})
			game.float_text(Vector2(bx, B.y - l.h - 18), "assustado", Color("#ff8a3d"), 13)
		"asas_fogo":
			P.wing_t = 0.65
			P.wing_pow = pw
			P.wing_hit = false
			P.wing_drop = 0.0
			P.inv = maxf(P.inv, 0.7)
			if P.ground:
				P.vy = -380.0


func _shot(o: Dictionary) -> Dictionary:
	var s = {"x": 0.0, "y": 0.0, "vx": 0.0, "vy": 0.0, "r": 6.0, "dmg": 0.0, "life": 1.4, "cat": "especial", "spr": "", "anim": false,
		"pierce": false, "hit": false, "delay": 0.0, "kind": "", "slow": 0.0, "poison": 0, "stun": 0.0, "ground": false, "basic": false,
		"track": false, "fired": false, "col": Color("#e8fff8"), "tx": 0.0}
	for k in o:
		s[k] = o[k]
	return s


func _boom(x: float, y: float, r: float, dmg: float, col: Color) -> void:
	if absf(B.x - x) < r and absf(B.y - L().h / 2.0 - y) < r + 20:
		hurt_boss(dmg, "especial")
	spawn_parts(x, y, col, 16)
	vfx.append({"spr": "", "ring": true, "x": x, "y": y, "t": 0.0, "dur": 0.35, "flip": false, "scale": r / 60.0, "rot": 0.0, "col": col})
	game.shake(0.1, 0.006)


func summon_skel(life: float, dmg: float, x: float) -> void:
	if mins.size() >= 4:
		mins.pop_front()
	mins.append({"x": clamp_x(x, 20), "y": FY, "face": P.face, "life": life * gd.skel, "cd": 0.4, "dmg": dmg * gd.skel, "f": 0})
	spawn_parts(x, FY - 10, Color("#c08ae0"), 10)


## Habilidade suprema: gasta a barra de poder cheia.
func cast_ult() -> void:
	var l = L()
	var pw = dmg_mul() * gd.ult_pow * (1.0 + 0.15 * game.skill_perm(game.guardian, game.g_cls, gd.ult))
	var bx: float = B.x
	var by: float = B.y - l.h / 2.0
	P.ult = 0.0
	P.cast_vis = 0.5
	use.especial += 1
	hitstop = maxf(hitstop, 0.12)
	game.shake(0.3, 0.008)
	game.float_text(Vector2(W / 2, H / 2 - 60), game.skill_info(gd.ult).nome.to_upper(), Color("#ffc430"), 24)
	for r in 3:
		vfx.append({"spr": "", "ring": true, "x": P.x, "y": P.y - gd.h / 2.0, "t": -r * 0.1, "dur": 0.5, "flip": false, "scale": 1.6, "rot": 0.0, "col": Color("#ffc430")})
	if D.ALT_ULTS.has(gd.ult):
		run_mechs(D.ALT_ULTS[gd.ult].mechs, pw, 1.0)
		return
	match gd.ult:
		"ult_rei":
			P.king_t = 6.0
		"ult_massacre":
			P.spin_t = 3.0
			P.spin_pow = 3.0 * pw
			P.leech_t = maxf(P.leech_t, 3.0)
			P.leech_amt = 0.4
		"ult_avalanche":
			for j in 6:
				shots.append(_shot({"kind": "meteor", "x": bx + (j - 2.5) * 40, "y": -40.0, "vy": 760.0, "dmg": 22 * pw, "r": 60.0, "spr": "fx/rock", "life": 3.0, "delay": j * 0.18, "tx": bx + (j - 2.5) * 40}))
			B.stun = maxf(B.stun, 1.8)
		"ult_chifres":
			P.ult_charges = 3
			P.charge_t = 0.0
		"ult_apocalipse":
			for w in 3:
				for j in 14:
					var a = j / 14.0 * TAU + w * 0.2
					shots.append(_shot({"x": P.x, "y": P.y - gd.h * 0.6, "vx": cos(a) * 520, "vy": sin(a) * 520, "r": 7.0, "dmg": 8 * pw, "spr": "fx/shard", "delay": w * 0.35, "life": 1.6}))
		"ult_exercito":
			for j in 6:
				summon_skel(10.0, 6.0 * pw, P.x + (j - 2.5) * 26)
		"ult_era_gelo":
			hurt_boss(40 * pw, "especial")
			B.stop_t = 3.0
			B.slow_t = 6.0
			spawn_parts(bx, by, Color("#c8f0ff"), 30)
		"ult_fim_tempos":
			B.stop_t = 4.0
			game.clock += 10.0
			game.float_text(Vector2(P.x, P.y - gd.h - 18), "+10s", Color("#f2d488"), 16)
		"ult_inferno":
			P.breath_t = 3.0
			P.breath_pow = 3.0 * pw
			P.tick = 0.0
			P.inv = maxf(P.inv, 3.0)
		"ult_furia_ceus":
			for j in 6:
				shots.append(_shot({"kind": "bolt", "x": bx, "delay": 0.2 + j * 0.28, "dmg": 20 * pw, "stun": 0.3, "track": true, "life": 0.5}))
		"ult_praga":
			B.poison = 8
			zones.append({"x": bx, "w": 170.0, "h": 140.0, "life": 6.0, "tick": 0.4, "tcd": 0.0, "dmg": 3.0 * pw, "follow": true, "kind": "poison", "slow": 0.0, "poison": 1})
		"ult_meteoros":
			for j in 8:
				var x = clampf(bx + randf_range(-150, 150), AW0 + 20, AW1 - 20)
				if j % 3 == 0:
					x = bx
				shots.append(_shot({"kind": "meteor", "x": x - 60, "y": -40.0, "vx": 60.0, "vy": 720.0, "dmg": 26 * pw, "r": 70.0, "spr": "fx/meteor", "life": 3.0, "delay": j * 0.25, "tx": x}))


## Peças de efeito das habilidades alternativas (data.gd → ALT_SKILLS / ALT_ULTS).
func run_mechs(list: Array, pw: float, du: float) -> void:
	var l = L()
	var bx: float = B.x
	var by: float = B.y - l.h / 2.0
	for m in list:
		match m.m:
			"proj":
				var n: int = int(m.get("n", 1))
				var sy: float = P.y - gd.h * 0.6
				var base = atan2(by - sy, bx - P.x) if absf(bx - P.x) > 30 else (0.0 if P.face > 0 else PI)
				for j in n:
					var a = base + (j - (n - 1) / 2.0) * float(m.get("spread", 0.0))
					shots.append(_shot({"x": P.x + P.face * 14, "y": sy, "vx": cos(a) * m.spd, "vy": sin(a) * m.spd, "r": float(m.get("r", 8.0)),
						"dmg": m.dmg * pw, "spr": m.spr, "pierce": m.get("pierce", false), "slow": float(m.get("slow", 0.0)) * du,
						"poison": int(m.get("poison", 0)), "stun": float(m.get("stun", 0.0)), "life": 1.8}))
			"charge":
				P.charge_t = m.t
				P.charge_spd = m.spd
				P.charge_dmg = m.dmg * pw
				P.charge_stun = float(m.get("stun", 0.0)) * du
				P.charge_poison = int(m.get("poison", 0))
				P.charge_hit = false
				P.inv = maxf(P.inv, m.t + 0.05)
			"leap":
				P.dive_t = 1.0
				P.dive_pow = pw * m.dmg / 30.0
				P.dive_hit = false
				P.inv = maxf(P.inv, 0.6)
				P.face = 1 if bx > P.x else -1
				if P.ground:
					P.vy = -520.0
					P.ground = false
					P.dive_hop = true
				else:
					P.dive_hop = false
					P.vy = 820.0
			"stomp":
				P.quake_n = int(m.n)
				P.quake_t = 0.0
				P.quake_pow = pw * m.dmg / 18.0
			"zone":
				var zx = bx if m.get("at", "boss") == "boss" else P.x
				zones.append({"x": zx, "w": m.w, "h": m.h, "life": m.life * du, "tick": m.tick, "tcd": 0.0, "dmg": m.dmg * pw,
					"follow": m.get("follow", false), "kind": m.kind, "slow": float(m.get("slow", 0.0)), "poison": int(m.get("poison", 0))})
			"buff":
				if m.has("fury"):
					P.fury_t = maxf(P.fury_t, m.fury * du)
				if m.has("scale"):
					P.scale_t = maxf(P.scale_t, m.scale * du)
					P.scale_pow = pw
					P.tick2 = 0.0
				if m.has("haste"):
					P.haste_t = maxf(P.haste_t, m.haste * du)
				if m.has("leech"):
					P.leech_t = maxf(P.leech_t, m.leech * du)
					P.leech_amt = 0.4 * du
				if m.has("block"):
					P.block_t = m.block * du
					P.block_pow = pw
					P.block_tick = 0.0
				if m.has("inv"):
					P.inv = maxf(P.inv, m.inv)
				spawn_parts(P.x, P.y - gd.h / 2.0, Color("#ffc430"), 10)
			"bolts":
				for j in int(m.n):
					shots.append(_shot({"kind": "bolt", "x": bx, "delay": 0.2 + j * m.gap, "dmg": m.dmg * pw, "stun": float(m.get("stun", 0.0)), "track": true, "life": 0.5}))
			"meteors":
				for j in int(m.n):
					var x = clampf(bx + (randf_range(-1, 1) * m.spread if j > 0 else 0.0), AW0 + 20, AW1 - 20)
					shots.append(_shot({"kind": "meteor", "x": x - 50, "y": -40.0, "vx": 50.0, "vy": 760.0, "dmg": m.dmg * pw, "r": float(m.get("r", 60.0)),
						"spr": m.spr, "life": 3.0, "delay": j * 0.2, "tx": x}))
			"summon":
				for j in int(m.n):
					summon_skel(m.life * du, m.dmg * pw, P.x + (j - (m.n - 1) / 2.0) * 28)
			"boss":
				if m.has("dmg"):
					hurt_boss(m.dmg * pw, "especial")
				if B.inv <= 0:
					if m.has("stun"):
						B.stun = maxf(B.stun, m.stun * du)
					if m.has("stop"):
						B.stop_t = maxf(B.stop_t, m.stop * du)
				if m.has("vuln"):
					B.vuln_t = maxf(B.vuln_t, m.vuln * du)
				if m.has("slow"):
					B.slow_t = maxf(B.slow_t, m.slow * du)
				if m.has("poison"):
					B.poison = mini(gd.pcap, B.poison + int(m.poison))
				spawn_parts(bx, by, Color("#c08ae0"), 10)
			"clock":
				game.clock += m.s * du
				game.float_text(Vector2(P.x, P.y - gd.h - 18), "+%ss" % D.fmt(m.s * du), Color("#9fd36b"), 13)
			"blink":
				spawn_parts(P.x, P.y - gd.h / 2.0, D.col(gd.cor), 10)
				P.x = clamp_x(P.x + P.face * m.dist, gd.w)
				spawn_parts(P.x, P.y - gd.h / 2.0, D.col(gd.cor), 10)
			"nova":
				for w in int(m.waves):
					for j in int(m.n):
						var a = j / float(m.n) * TAU + w * 0.2
						shots.append(_shot({"x": P.x, "y": P.y - gd.h * 0.6, "vx": cos(a) * m.spd, "vy": sin(a) * m.spd, "r": 7.0, "dmg": m.dmg * pw,
							"spr": m.spr, "delay": w * 0.35, "life": 1.6}))
			"spin":
				P.spin_t = m.t * du
				P.spin_pow = pw * m.dmg / 6.0
				P.spin_tick = 0.0
			"king":
				P.king_t = maxf(P.king_t, m.t * du)
			"wall":
				wall = {"x": clamp_x(P.x + P.face * 48, 24), "life": 3.0 * du, "dmg": m.dmg * pw}
				spawn_parts(wall.x, FY - 20, Color("#a89a8a"), 12)
			"breath":
				P.breath_t = m.t * du
				P.breath_pow = pw * m.dmg
				P.tick = 0.0
			"bulls":
				for j in int(m.n):
					var sx = AW0 + 10 if j % 2 == 0 else AW1 - 10
					shots.append(_shot({"x": sx, "y": FY - 24, "vx": (560.0 if j % 2 == 0 else -560.0), "r": 22.0, "dmg": m.dmg * pw,
						"spr": "fx/bull", "anim": true, "pierce": true, "delay": j * 0.3, "life": 2.6, "kind": "bull"}))
				game.shake(0.6, 0.004)


func stomp(pw: float, lv := 1) -> void:
	for dir in [-1, 1]:
		shots.append(_shot({"x": P.x, "y": P.y - 14, "vx": dir * 420.0, "r": 13.0, "dmg": 18 * pw, "life": 1.6, "col": Color("#d6c3a5"), "ground": true}))
	game.shake(0.14, 0.008)
	spawn_parts(P.x, P.y - 4, Color("#d6c3a5"), 14)
	hitstop = maxf(hitstop, 0.05)
	if absf(B.x - P.x) < 110 and B.ground and B.inv <= 0:
		B.stun = 0.5 + 0.25 * lv
		game.float_text(Vector2(B.x, B.y - L().h - 16), "atordoado", Color("#d6c3a5"), 12)


# ===== guardião: ataque básico em 4 tempos =====
func start_basic() -> void:
	var a = gd.atk
	var sp = 0.7 if P.fury_t > 0 else 1.0
	P.atk_ph = "anti"
	P.atk_pt = a.get("anti", 0.05) * sp
	P.atk_cd = a.cd * sp * gd.t_atkcd * (0.6 if P.king_t > 0 else 1.0)
	P.hit_b = false


func basic_step(dt: float) -> void:
	if P.atk_ph == "":
		return
	var a = gd.atk
	P.atk_pt -= dt
	if P.atk_ph == "anti":
		if P.atk_pt <= 0:
			P.atk_ph = "act"
			if a.kind == "melee":
				P.atk_pt = a.t
				var flip: bool = P.face < 0
				var yy: float = P.y - a.hh * 0.6
				add_vfx("fx/slash_%s" % a.fx, P.x + P.face * a.range * gd.t_range * 0.45, yy, a.t + 0.06, flip, 2.0 * clampf(a.range * gd.t_range / 64.0, 0.85, 1.35))
			else:
				P.atk_pt = 0.08
				fire_basic(0.0)
				if P.echo_n > 0:
					P.echo_n -= 1
					fire_basic(-10.0, 0.1)
		return
	if P.atk_ph == "act":
		if a.kind == "melee" and not P.hit_b:
			var rg: float = a.range * gd.t_range
			var box = Rect2(P.x if P.face > 0 else P.x - rg, P.y - a.hh, rg, a.hh)
			if overlap(box, body_b()):
				P.hit_b = true
				var cx: float = clampf(P.x + P.face * rg * 0.7, B.x - L().w / 2.0, B.x + L().w / 2.0)
				if hurt_boss(a.dmg * dmg_mul() * gd.t_atk, "perto"):
					on_basic_hit(cx, P.y - a.hh * 0.55)
					hitstop = maxf(hitstop, clampf(0.03 + a.dmg / 500.0, 0.04, 0.08))
					game.shake(0.08, a.get("shake", 0.003))
				add_vfx("fx/spark_guard", cx, P.y - a.hh * 0.55, 0.18)
		if P.atk_pt <= 0:
			P.atk_ph = "rec"
			P.atk_pt = a.get("rec", 0.06)
		return
	if P.atk_pt <= 0:
		P.atk_ph = ""


func fire_basic(dy: float, delay := 0.0) -> void:
	var a = gd.atk
	P.shot_vis = 0.14
	for j in 1 + gd.shot_n:
		var ang = (j - gd.shot_n / 2.0) * 0.12 if gd.shot_n > 0 else 0.0
		shots.append(_shot({"x": P.x + P.face * 16, "y": P.y - gd.h * 0.62 + dy, "vx": P.face * a.spd * cos(ang), "vy": a.spd * sin(ang), "r": 6.0,
			"dmg": a.dmg * dmg_mul() * gd.t_atk, "life": 1.4, "cat": "longe", "spr": a.spr, "basic": true, "delay": delay, "col": Color("#bfeee6"), "pierce": gd.pierce}))


## Passivas da classe e efeitos ligados a cada acerto do ataque básico.
func on_basic_hit(x: float, y: float) -> void:
	game.mission_add("minotauro_1")
	match gd.passive:
		"furia_acumula":
			P.rage = mini(gd.rage_cap, P.rage + 1)
		"empurrao":
			if B.guard <= 0 and B.inv <= 0:
				B.x = clamp_x(B.x + P.face * 34 * gd.t_pass, L().w)
		"colheita":
			P.harvest += 1
			if P.harvest >= int(8 / gd.t_pass):
				P.harvest = 0
				summon_skel(7.0, 4.0 * dmg_mul(), P.x - P.face * 20)
		"congelar":
			B.slow_t = maxf(B.slow_t, 1.2 * gd.t_pass)
		"tempo_devolvido":
			game.clock += 0.15 * gd.t_pass
		"faisca":
			if randf() < 0.25 * gd.t_pass:
				shots.append(_shot({"kind": "bolt", "x": B.x, "delay": 0.05, "dmg": 6.0 * dmg_mul(), "stun": 0.0, "track": true, "life": 0.35}))
		"veneno":
			B.poison = mini(gd.pcap, B.poison + int(gd.t_pass))
	game.clock += gd.t_leech
	if P.leech_t > 0:
		game.clock += P.leech_amt


func player_step(dt: float) -> void:
	var up: Dictionary = game.g_up
	P.dash_cd -= dt
	P.shot_vis -= dt
	P.cast_vis -= dt
	P.atk_cd -= dt
	P.inv -= dt
	P.flash -= dt
	P.kb_t -= dt
	P.root_t -= dt
	for i in 3:
		P.cd[i] -= dt
	for k in ["fury_t", "scale_t", "breath_t", "charge_t", "spin_t", "leech_t", "fly_t", "haste_t", "king_t"]:
		P[k] -= dt
	# suprema: Chifres do Rei faz investidas seguidas
	if P.ult_charges > 0 and P.charge_t <= 0:
		P.ult_charges -= 1
		P.face = -P.face if (P.x > W / 2 and P.face > 0) or (P.x < W / 2 and P.face < 0) else P.face
		P.charge_t = 0.9
		P.charge_spd = 760.0
		P.charge_hit = false
		P.inv = maxf(P.inv, 1.0)
	if P.ice_t > 0:
		P.ice_t -= dt
		P.vx = 0.0
		move_body(P, gd.w, dt, true)
		return
	var bz: bool = busy()
	var max_j: int = 99 if P.fly_t > 0 else gd.jumps
	if P.ground:
		P.jumps = 0
	# dash
	if press.has("g_dash") and P.dash_cd <= 0 and not bz and P.kb_t <= 0 and P.root_t <= 0:
		use.dash += 1
		P.dash_cd = gd.dash.cd * gd.t_dash
		if gd.dash.has("blink"):
			spawn_parts(P.x, P.y - gd.h / 2.0, D.col(gd.cor), 8)
			P.x = clamp_x(P.x + gd.dash.blink * (1 + 0.15 * up.agil) * P.face, gd.w)
			P.inv = maxf(P.inv, 0.25)
			spawn_parts(P.x, P.y - gd.h / 2.0, D.col(gd.cor), 8)
			dash_ended()
		else:
			P.dash_t = gd.dash.t * (1 + 0.15 * up.agil)
			P.inv = maxf(P.inv, P.dash_t * 0.85)
	# pulo
	if press.has("g_jump") and P.kb_t <= 0 and not bz and P.root_t <= 0:
		if P.ground:
			P.vy = -float(gd.jump)
			P.jumps = 1
			P.ground = false
			use.pulo += 1
			spawn_parts(P.x, P.y, Color("#d6c3a5"), 4)
		elif P.jumps < max_j:
			P.vy = -gd.jump * 0.9
			P.jumps += 1
			use.pulo += 1
			game.mission_add("dragao_1")
			spawn_parts(P.x, P.y, D.col(gd.cor), 5)
	if not Input.is_action_pressed("g_jump") and P.vy < -260 and not P.dive_hop and P.wing_t <= 0:
		P.vy = -260.0
	# suprema
	if press.has("g_ult") and P.ult >= 100.0 and P.kb_t <= 0 and not busy():
		cast_ult()
	# habilidades
	for i in 3:
		if press.has("g_s%d" % i) and P.cd[i] <= 0 and P.kb_t <= 0 and not busy():
			cast_skill(i)
	# movimento
	var mv = (1 if Input.is_action_pressed("g_right") else 0) - (1 if Input.is_action_pressed("g_left") else 0)
	var grav = 1.0
	if P.kb_t > 0:
		P.vx = P.kb
	elif P.block_t > 0:
		P.block_t -= dt
		P.vx = 0.0
	elif P.dash_t > 0:
		P.dash_t -= dt
		P.vx = P.face * gd.dash.spd * (1 + 0.15 * up.agil)
		P.vy = 0.0
		grav = 0.0
		if P.dash_t <= 0:
			P.vx = 0.0
			dash_ended()
	elif P.charge_t > 0:
		P.vx = P.face * P.charge_spd
		spawn_parts(P.x - P.face * 18, P.y - 10, Color("#d6c3a5"), 1)
	elif P.wing_t > 0:
		P.wing_t -= dt
		P.vx = P.face * 640.0
		P.vy = minf(P.vy, 40.0)
		grav = 0.15
		P.wing_drop -= dt
		if P.wing_drop <= 0:
			P.wing_drop = 0.07
			zones.append({"x": P.x, "w": 34.0, "h": 40.0, "life": 2.5, "tick": 0.3, "tcd": 0.0, "dmg": 2.0 * P.wing_pow, "follow": false, "kind": "fire", "slow": 0.0, "poison": 0})
		if not P.wing_hit and overlap(body_p(), body_b()):
			P.wing_hit = true
			hurt_boss(18 * P.wing_pow, "especial")
	elif P.dive_t > 0:
		P.dive_t -= dt
		if P.dive_hop:
			P.vx = P.face * 180.0
			if P.vy >= 0:
				P.dive_hop = false
				P.vy = 820.0
		else:
			P.vx = P.face * 520.0
			P.vy = maxf(P.vy, 820.0)
			spawn_parts(P.x, P.y - gd.h / 2.0, Color("#ff8a3d"), 2)
	else:
		if mv != 0 and P.atk_ph == "":
			P.face = mv
		var sp: float = gd.spd * (1 + 0.12 * up.agil)
		if P.breath_t > 0:
			sp *= 0.3
		if P.atk_ph != "" and gd.atk.kind == "melee":
			sp *= 0.5
		if P.fly_t > 0:
			sp *= 1.3
		if P.haste_t > 0:
			sp *= 1.4
		if P.spin_t > 0:
			sp *= 0.75
		if P.root_t > 0:
			sp = 0.0
		P.vx = mv * sp
	if P.fly_t > 0 and P.vy > 0:
		grav = 0.35
	var was_air: bool = not P.ground
	move_body(P, gd.w, dt, true, grav)
	if P.ground and absf(P.vx) > 10:
		P.run_d += absf(P.vx) * dt
	if P.dash_t > 0:
		spawn_parts(P.x - P.face * 14, P.y - gd.h / 2.0, D.col(gd.cor), 1)
	# aterrissagens
	if was_air and P.ground and P.vy == 0.0:
		spawn_parts(P.x, P.y, Color("#d6c3a5"), 3)
	if P.slam > 0 and P.ground:
		stomp(P.slam)
		P.slam = 0.0
	if P.dive_t > 0 and not P.dive_hop and P.ground and was_air:
		P.dive_t = 0.0
		P.inv = maxf(P.inv, 0.2)
		if overlap(Rect2(P.x - 64, P.y - 46, 128, 46), body_b()):
			hurt_boss(16 * P.dive_pow, "especial")
		spawn_parts(P.x, P.y - 4, Color("#ff8a3d"), 18)
		game.shake(0.12, 0.008)
	if P.dive_t > 0 and not P.dive_hop and not P.dive_hit and overlap(body_p(), body_b()):
		P.dive_hit = true
		hurt_boss(30 * P.dive_pow, "especial")
	# terremoto: três pisões seguidos
	if P.quake_n > 0:
		P.quake_t -= dt
		if P.quake_t <= 0 and P.ground:
			P.quake_n -= 1
			P.quake_t = 0.35
			stomp(P.quake_pow)
	# ataque básico (segurar repete)
	if Input.is_action_pressed("g_atk") and P.atk_cd <= 0 and P.atk_ph == "" and not busy() and P.kb_t <= 0 and P.breath_t <= 0 and P.spin_t <= 0:
		start_basic()
	basic_step(dt)
	# efeitos que duram
	if P.charge_t > 0 and not P.charge_hit and overlap(body_p(), body_b()):
		P.charge_hit = true
		if hurt_boss(P.charge_dmg, "especial"):
			if P.charge_stun > 0:
				B.stun = maxf(B.stun, P.charge_stun)
				game.float_text(Vector2(B.x, B.y - L().h - 16), "atordoado", Color("#d6c3a5"), 12)
			if P.charge_poison > 0:
				B.poison = mini(gd.pcap, B.poison + P.charge_poison)
		add_vfx("fx/spark_guard", B.x, B.y - L().h / 2.0, 0.2)
		hitstop = maxf(hitstop, 0.07)
		game.shake(0.12, 0.008)
	if P.breath_t > 0:
		P.tick -= dt
		var box = Rect2(P.x if P.face > 0 else P.x - 170, P.y - gd.h - 14, 170, gd.h + 20)
		if P.tick <= 0:
			P.tick = 0.1
			if overlap(box, body_b()):
				hurt_boss(5.5 * P.breath_pow, "especial", true)
		spawn_parts(P.x + P.face * (24 + randf() * 130), P.y - gd.h * 0.5 + (randf() - 0.5) * 26, Color("#ff8a3d") if randf() < 0.5 else Color("#f2d488"), 1)
	if P.spin_t > 0:
		P.spin_tick -= dt
		if P.spin_tick <= 0:
			P.spin_tick = 0.15
			if absf(B.x - P.x) < 70 and absf(B.y - P.y) < 70:
				if hurt_boss(6.0 * P.spin_pow, "especial", true):
					on_basic_hit(B.x, B.y - L().h / 2.0)
				add_vfx("fx/spark_guard", B.x, B.y - L().h / 2.0, 0.15)
	if P.scale_t > 0:
		P.tick2 -= dt
		if P.tick2 <= 0:
			P.tick2 = 0.2
			if absf(B.x - P.x) < 85 and absf(B.y - P.y) < 90:
				hurt_boss(2.8 * P.scale_pow, "especial", true)
		if randf() < 0.3:
			spawn_parts(P.x + (randf() - 0.5) * 50, P.y - randf() * gd.h, Color("#ff8a3d"), 1)
	if P.block_t > 0:
		P.block_tick -= dt
	if not wall.is_empty():
		wall.life -= dt
		if wall.life <= 0:
			wall = {}
	if absf(P.x - B.x) < 150:
		use.near += dt
	else:
		use.far += dt
	use.time += dt


func allies_step(dt: float) -> void:
	var l = L()
	for m in mins:
		m.life -= dt
		m.cd -= dt
		var dx: float = B.x - m.x
		m.face = 1 if dx > 0 else -1
		if absf(dx) > 30:
			m.x = clamp_x(m.x + m.face * 120.0 * dt, 20)
			m.f = int(t * 6) % 2
		elif m.cd <= 0:
			m.cd = 0.8
			hurt_boss(m.dmg, "especial", true)
			add_vfx("fx/spark_guard", B.x - m.face * l.w * 0.3, B.y - 20, 0.15)
	mins = mins.filter(func(m): return m.life > 0)
	for z in zones:
		z.life -= dt
		z.tcd -= dt
		if z.follow:
			z.x = move_toward(z.x, B.x, 200.0 * dt)
		if z.tcd <= 0:
			z.tcd = z.tick
			if absf(B.x - z.x) < z.w / 2.0 + l.w / 2.0 and B.y > FY - z.h:
				hurt_boss(z.dmg, "especial", true)
				if z.slow > 0:
					B.slow_t = maxf(B.slow_t, z.slow)
				if z.poison > 0:
					B.poison = mini(gd.pcap, B.poison + z.poison)
		if randf() < 0.4:
			var c = {"snow": Color("#e8f8ff"), "poison": Color("#96e65a"), "fire": Color("#ff8a3d"), "storm": Color("#fff0a0")}[z.kind]
			parts.append({"x": z.x + (randf() - 0.5) * z.w, "y": FY - z.h * randf(), "vx": 0.0, "vy": -30.0 if z.kind != "snow" else 60.0, "r": 1.5 + randf() * 2, "col": c, "life": 0.4, "max": 0.4})
	zones = zones.filter(func(z): return z.life > 0)


# o lendário aprende: quem abusa do dash leva um bote no fim dele
func dash_ended() -> void:
	var lv = int(game.duel.dash)
	if lv > 0 and B.act.is_empty() and randf() < 0.25 * lv:
		B.act = {"n": "lunge", "t": 0.0, "s": 0}


func react_special() -> void:
	var lv = int(game.duel.especial)
	if lv > 0 and (B.act.is_empty() or B.act.n == "guard") and randf() < 0.2 * lv:
		B.act = {"n": "evade", "t": 0.0, "s": 0}


func hurt_boss(dmg: float, cat: String, no_leech := false) -> bool:
	var l = L()
	if B.inv > 0 or win != 0:
		return false
	if B.guard > 0 and cat != "especial":
		B.flash = 0.1
		spawn_parts(B.x, B.y - l.h / 2.0, Color("#f2d488"), 6)
		if cat == "perto":
			game.float_text(Vector2(B.x, B.y - l.h - 16), "aparou!", Color("#f2d488"), 13)
			hurt_guard(3.5, true)
		else:
			game.float_text(Vector2(B.x, B.y - l.h - 16), "bloqueou", Color("#f2d488"), 12)
		return false
	var mul: float = D.CFG.KNOW_RESIST[int(game.duel.get(cat, 0))]
	if B.mark_t > 0:
		mul *= 1.25
		if not no_leech:
			game.clock += 0.25 + 0.1 * B.mark_lv
	if B.vuln_t > 0:
		mul *= 1.3
	B.hp -= dmg * mul
	P.ult = minf(100.0, P.ult + clampf(dmg * mul * 0.3, 0.4, 6.0) * gd.ult_gain)
	B.flash = 0.08
	B.hurt_t = 0.18
	if game.g_up.sangue > 0 and not no_leech:
		game.clock += 0.3 * game.g_up.sangue
	if not B.phase2 and B.hp <= B.max * 0.5 and B.hp > 0:
		B.phase2 = true
		B.act = {}
		B.idle = 0.9
		B.inv = 0.9
		hz = []
		game.float_text(Vector2(W / 2, H / 2 - 40), "FÚRIA", Color("#e0613a"), 26)
		game.shake(0.25, 0.01)
	if B.hp <= 0:
		B.hp = 0.0
		win = 1
		over = 1.6
		hz = []
		B.act = {}
		hitstop = 0.12
		game.float_text(Vector2(W / 2, H / 2 - 30), D.HEROES[key].nome.get_slice(",", 0).to_upper() + " CAIU", Color("#f2d488"), 28)
		game.shake(0.3, 0.012)
		spawn_parts(B.x, B.y - l.h / 2.0, D.col(D.HEROES[key].cor), 30)
	return true


func hurt_guard(sec: float, force := false) -> void:
	if win != 0:
		return
	if P.ice_t > 0:
		return
	if P.block_t > 0 and not force:
		# postura de pedra: bloqueia e devolve
		if P.block_tick <= 0:
			P.block_tick = 0.3
			hurt_boss(8.0 * P.block_pow, "especial", true)
			add_vfx("fx/spark_guard", P.x + P.face * gd.w * 0.5, P.y - gd.h / 2.0, 0.18)
			game.float_text(Vector2(P.x, P.y - gd.h - 14), "bloqueou", Color("#d6c3a5"), 12)
		return
	if not force and P.inv > 0:
		return
	var lost = D.r1(sec * leg_scale * gd.armor * gd.def * (0.5 if P.king_t > 0 else 1.0) * pow(0.85, game.g_up.couraca) * (1.0 + game.fame_pct() * D.CFG.LEG_FAME_DMG) * (0.7 if P.fury_t > 0 else 1.0) * (0.6 if P.scale_t > 0 else 1.0))
	game.clock -= lost
	P.ult = minf(100.0, P.ult + 12.0 * gd.ult_gain)
	P.lost.append([t, lost])
	stats.hits += 1
	stats.lost += lost
	P.rage = 0
	P.inv = 0.9
	P.flash = 0.9
	P.dash_t = 0.0
	P.charge_t = 0.0
	P.breath_t = 0.0
	P.dive_t = 0.0
	P.dive_hop = false
	P.wing_t = 0.0
	P.spin_t = 0.0
	P.slam = 0.0
	P.atk_ph = ""
	P.kb_t = 0.18
	P.kb = (-1.0 if P.x < B.x else 1.0) * 280.0
	P.vy = -280.0
	hitstop = maxf(hitstop, 0.06)
	add_vfx("fx/spark_hero", P.x, P.y - gd.h / 2.0, 0.2)
	game.float_text(Vector2(P.x, P.y - gd.h - 14), "-%ss" % D.fmt(lost), Color("#e0613a"), 16)
	game.shake(0.12, 0.006)
	spawn_parts(P.x, P.y - gd.h / 2.0, Color("#e0613a"), 8)
	if game.clock <= 0:
		game.clock = 0.0
		win = -1
		over = 1.6
		game.float_text(Vector2(W / 2, H / 2 - 30), "O GUARDIÃO CAIU", Color("#e0613a"), 28)


# ===== lendário =====
func choose_act() -> String:
	var l = L()
	var du: Dictionary = game.duel
	var w: Dictionary = (l.moves2 if B.phase2 else l.moves).duplicate()
	var d = absf(P.x - B.x)
	var air: bool = not P.ground or P.y < FY - 20
	if du.pulo > 0 and air:
		w["rise"] = du.pulo * 3
	if du.perto > 0 and d < 170:
		w["guard"] = du.perto * 2.5
	if du.longe > 0 and d > 260:
		w["gap"] = du.longe * 3
	if B.last != "" and w.has(B.last) and w.size() > 1:
		w[B.last] = w[B.last] * 0.35
	var tot = 0.0
	for k in w:
		tot += w[k]
	var r = randf() * tot
	for k in w:
		r -= w[k]
		if r <= 0:
			return k
	return w.keys()[0]


func act(a: Dictionary, dt: float) -> bool:
	var l = L()
	match a.n:
		"dash", "charge":
			# estocada / investida de parede a parede: pule por cima
			var hot_spd = (1050.0 if B.phase2 else 880.0) if a.n == "dash" else (760.0 if B.phase2 else 620.0)
			var tele = 0.55 if a.n == "dash" else 0.7
			if a.s == 0:
				B.face = -1 if P.x < B.x else 1
				a["dir"] = B.face
				B.vx = 0.0
				B.tele = tele
				a.s = 1
				var x1: float = B.x if a.dir > 0 else AW0
				var x2: float = AW1 if a.dir > 0 else B.x
				var hh: float = 30.0 if a.n == "dash" else float(l.h)
				add_hz({"x": x1, "y": FY - hh, "w": x2 - x1, "h": hh, "tele": tele, "warn": true})
				return false
			if a.s == 1:
				B.vx = 0.0
				B.tele -= dt
				if B.tele <= 0:
					a.s = 2
					a["hot"] = true
				return false
			if a.s == 2:
				B.vx = a.dir * hot_spd
				boss_swing()
				spawn_parts(B.x - a.dir * 20, FY - 4, Color("#e0413a") if a.n == "dash" else Color("#d6c3a5"), 1)
				if (a.dir > 0 and B.x >= AW1 - l.w / 2.0 - 2) or (a.dir < 0 and B.x <= AW0 + l.w / 2.0 + 2):
					a.hot = false
					B.vx = 0.0
					a.s = 3
					a["w"] = 0.3 if a.n == "dash" else 0.7
					if a.n == "charge":
						game.shake(0.2, 0.012)
						if B.phase2:
							for i in 3:
								var x = AW0 + 60 + randf() * (AW1 - AW0 - 120)
								add_hz({"x": x - 18, "y": -40.0, "w": 36.0, "h": 36.0, "tele": 0.6 + i * 0.15, "life": 2.0, "vy": 520.0, "dmg": l.hit, "floor_stop": true, "rock": true, "mark": true, "col": Color("#8d7b6a"), "spr": LFX("rain", "fx/rock"), "spin": true})
				return false
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"leap", "gap":
			# salta até onde o guardião está e cai com um golpe
			if a.s == 0:
				a["tx"] = clamp_x(P.x, 80)
				a.s = 1
				B.tele = 0.45
				B.vx = 0.0
				add_hz({"x": a.tx - 65, "y": FY - 8, "w": 130.0, "h": 8.0, "tele": 1.0, "warn": true, "mark": true})
				return false
			if a.s == 1:
				B.vx = 0.0
				B.tele -= dt
				if B.tele <= 0:
					a.s = 2
					var tt = 0.55
					B.vy = -GRAV * tt / 2.0
					B.vx = (a.tx - B.x) / tt
					B.ground = false
					a["air"] = 0.0
				return false
			if a.s == 2:
				a.air += dt
				if a.air > 0.1 and B.ground:
					B.vx = 0.0
					a.s = 3
					a["w"] = 0.4
					add_hz({"x": B.x - 65, "y": FY - 42, "w": 130.0, "h": 42.0, "life": 0.14, "dmg": l.hit, "melee": true, "face": B.face})
					spawn_parts(B.x, FY - 4, Color("#d6c3a5"), 12)
					game.shake(0.1, 0.006)
					if l.get("heavy", false) or B.phase2:
						shockwaves(B.x)
				return false
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"combo":
			# corre até o guardião e solta três cortes
			if a.s == 0:
				a.s = 1
				a["run"] = 0.0
			if a.s == 1:
				a.run += dt
				B.face = -1 if P.x < B.x else 1
				B.vx = B.face * l.spd * 1.7
				if absf(P.x - B.x) < 72 or a.run > 0.9:
					B.vx = 0.0
					a.s = 2
					a["k"] = 0
					a["w"] = 0.0
				return false
			B.vx *= 0.85
			a.w -= dt
			if a.w <= 0:
				if a.k >= 3:
					return true
				a.k += 1
				B.face = -1 if P.x < B.x else 1
				add_hz({"x": B.x if B.face > 0 else B.x - 76, "y": B.y - 58, "w": 76.0, "h": 58.0, "tele": 0.18 if B.phase2 else 0.26, "life": 0.12, "dmg": l.hit, "melee": true, "face": B.face})
				a.w = 0.34 if B.phase2 else 0.46
				B.vx = B.face * 70.0
			return false
		"waves":
			if a.s == 0:
				a.s = 1
				a["k"] = 0
				a["w"] = 0.0
			B.vx = 0.0
			a.w -= dt
			if a.w <= 0:
				if a.k >= 3:
					return true
				a.k += 1
				B.face = -1 if P.x < B.x else 1
				add_hz({"x": B.x - 14, "y": FY - 30, "w": 28.0, "h": 30.0, "tele": 0.3, "life": 2.2, "vx": B.face * 430.0, "dmg": l.hit * 0.8, "wave": true, "col": Color("#e0413a"), "face": B.face})
				a.w = 0.6
			return false
		"rise":
			# contra quem pula demais: corte vertical sob o guardião
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				a["w"] = 0.85
				B.face = -1 if P.x < B.x else 1
				B.x = clamp_x(B.x + (P.x - B.x) * 0.6, l.w)
				boss_swing()
				spawn_parts(B.x, B.y - 20, Color("#f2d488"), 6)
				add_hz({"x": B.x - 42, "y": B.y - 220, "w": 84.0, "h": 220.0, "tele": 0.3, "life": 0.2, "dmg": l.hit, "pillar": true, "col": Color("#f2d488")})
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"lunge", "lunge2", "bash":
			# pune o fim do dash
			if a.s == 0:
				a.s = 1
				a["tx"] = P.x
				B.tele = {"lunge": 0.22, "lunge2": 0.32, "bash": 0.42}[a.n]
				B.vx = 0.0
				B.face = -1 if a.tx < B.x else 1
				return false
			if a.s == 1:
				B.vx = 0.0
				B.tele -= dt
				if B.tele <= 0:
					a.s = 2
					a["hot"] = true
					a["w"] = 0.24
				return false
			if a.s == 2:
				a.w -= dt
				B.vx = B.face * (700.0 if a.n == "bash" else 900.0)
				boss_swing()
				if a.w <= 0 or absf(B.x - a.tx) < 16:
					B.vx = 0.0
					a.hot = false
					a.s = 3
					a.w = 0.35
				return false
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"guard":
			if a.s == 0:
				a.s = 1
				B.guard = 1.0
				a["w"] = 1.0
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"evade":
			if a.s == 0:
				a.s = 1
				B.inv = 0.45
				B.guard = 0.0
				var dir = 1.0 if P.x < B.x else -1.0
				spawn_parts(B.x, B.y - 30, Color.WHITE, 8)
				B.x = clamp_x(B.x + dir * 190, l.w * 2)
				spawn_parts(B.x, B.y - 30, Color.WHITE, 8)
				a["w"] = 0.3
				game.float_text(Vector2(B.x, B.y - l.h - 14), "esquivou", Color("#ece2d2"), 12)
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"slam":
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.5
				return false
			if a.s == 1:
				B.vx = 0.0
				B.tele -= dt
				if B.tele <= 0:
					a.s = 2
					B.vy = -640.0
					B.ground = false
					a["air"] = 0.0
					B.vx = (P.x - B.x) * 0.7
				return false
			if a.s == 2:
				a.air += dt
				if a.air > 0.1 and B.ground:
					B.vx = 0.0
					a.s = 3
					a["w"] = 0.6
					add_hz({"x": B.x - 72, "y": FY - 42, "w": 144.0, "h": 42.0, "life": 0.14, "dmg": l.hit, "col": Color("#d6c3a5"), "melee": true, "face": B.face})
					shockwaves(B.x)
					spawn_parts(B.x, FY - 4, Color("#d6c3a5"), 14)
					game.shake(0.16, 0.01)
				return false
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"rock":
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.45
				a["cnt"] = 3 if B.phase2 else 2
				a["k"] = 0
				a["w"] = 0.0
				return false
			B.vx = 0.0
			if B.tele > 0:
				B.tele -= dt
				return false
			a.w -= dt
			if a.w <= 0:
				if a.k >= a.cnt:
					return true
				a.k += 1
				B.face = -1 if P.x < B.x else 1
				var sx: float = B.x
				var sy: float = B.y - l.h
				var tt = 0.85
				var vx: float = (P.x - sx) / tt
				var vy: float = (FY - 18 - sy - 0.5 * GRAV * tt * tt) / tt
				add_hz({"x": sx - 16, "y": sy - 16, "w": 32.0, "h": 32.0, "life": 2.5, "vx": vx, "vy": vy, "g": 1.0, "dmg": l.hit, "floor_stop": true, "rock": true, "col": Color("#8d7b6a"), "spr": LFX("rock", "fx/rock"), "spin": true, "on_land": "pool" if L().fx.has("pool") else ""})
				a.w = 0.55
			return false
		"quake":
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				a["w"] = 1.6
				game.shake(0.6, 0.004)
				var xs = [P.x]
				for i in 4:
					xs.append(AW0 + 40 + randf() * (AW1 - AW0 - 80))
				for i in xs.size():
					add_hz({"x": xs[i] - 20, "y": -40.0, "w": 40.0, "h": 40.0, "tele": 0.75 + i * 0.14, "life": 2.0, "vy": 540.0, "dmg": l.hit, "floor_stop": true, "rock": true, "mark": true, "col": Color("#8d7b6a"), "spr": LFX("rain", "fx/rock"), "spin": true})
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"volley":
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.4
				a["k"] = 0
				a["w"] = 0.0
				a["cnt"] = 5 if B.phase2 else 3
				return false
			B.vx = 0.0
			if B.tele > 0:
				B.tele -= dt
				return false
			a.w -= dt
			if a.w <= 0:
				if a.k >= a.cnt:
					return true
				a.k += 1
				var sx: float = B.x
				var sy: float = B.y - l.h * 0.7
				var ang = atan2(P.y - G().h / 2.0 - sy, P.x - sx)
				add_hz({"x": sx - 9, "y": sy - 9, "w": 18.0, "h": 18.0, "life": 3.0, "vx": cos(ang) * 300, "vy": sin(ang) * 300, "dmg": l.hit, "orb": true, "col": Color("#f2e6a0"), "spr": LFX("orb", "fx/orb"), "spin": true})
				a.w = 0.2
			return false
		"pillar":
			if a.s == 0:
				a.s = 1
				a["k"] = 0
				a["w"] = 0.0
				a["cnt"] = 4 if B.phase2 else 3
			B.vx = 0.0
			a.w -= dt
			if a.w <= 0:
				if a.k >= a.cnt:
					return a.w < -0.5
				a.k += 1
				add_hz({"x": P.x - 28, "y": 0.0, "w": 56.0, "h": FY, "tele": 0.6, "life": 0.3, "dmg": l.hit, "pillar": true, "col": D.col(LFX("pillar", 0xfff3c4))})
				a.w = 0.45
			return false
		"blink":
			if a.s == 0:
				a.s = 1
				spawn_parts(B.x, B.y - 30, Color("#f2e6a0"), 10)
				B.x = AW1 - 60 if P.x < W / 2 else AW0 + 60
				B.inv = 0.3
				spawn_parts(B.x, B.y - 30, Color("#f2e6a0"), 10)
				a["w"] = 0.25
			B.vx = 0.0
			if a.s == 1:
				a.w -= dt
				if a.w <= 0:
					a.s = 2
					a["sub"] = {"n": "volley", "t": 0.0, "s": 0}
				return false
			return act(a.sub, dt)
		"nova":
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.6
				a["k"] = 0
				a["w"] = 0.0
				return false
			B.vx = 0.0
			if B.tele > 0:
				B.tele -= dt
				return false
			a.w -= dt
			if a.w <= 0:
				if a.k >= 2:
					return true
				a.k += 1
				var sx: float = B.x
				var sy: float = B.y - l.h * 0.6
				for i in 12:
					var g = a.k * 0.26 + i / 12.0 * TAU
					add_hz({"x": sx - 8, "y": sy - 8, "w": 16.0, "h": 16.0, "life": 2.5, "vx": cos(g) * 260, "vy": sin(g) * 260, "dmg": l.hit * 0.8, "orb": true, "col": Color("#fff3c4"), "spr": LFX("orb", "fx/orb"), "spin": true})
				a.w = 0.6
			return false
		"arrows":
			# flechas retas na altura do peito: pule ou abaixe com o dash
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.4
				a["k"] = 0
				a["w"] = 0.0
				a["cnt"] = 5 if B.phase2 else 3
				return false
			B.vx = 0.0
			if B.tele > 0:
				B.tele -= dt
				return false
			a.w -= dt
			if a.w <= 0:
				if a.k >= a.cnt:
					return true
				a.k += 1
				B.face = -1 if P.x < B.x else 1
				var ay: float = P.y - gd.h * 0.5 - (18.0 if a.k % 2 == 0 else 0.0)
				add_hz({"x": B.x - 11, "y": ay - 4, "w": 22.0, "h": 8.0, "life": 2.5, "vx": B.face * 560.0, "dmg": l.hit * 0.8, "orb": true, "spr": LFX("arrow", "fx/arrow"), "face": B.face})
				a.w = 0.24
			return false
		"evade_back":
			# salta para trás e atira em diagonal
			if a.s == 0:
				a.s = 1
				var dir = 1.0 if P.x < B.x else -1.0
				B.vy = -560.0
				B.vx = dir * 260.0
				B.ground = false
				a["air"] = 0.0
				return false
			if a.s == 1:
				a.air += dt
				if B.vy > -60:
					a.s = 2
					B.face = -1 if P.x < B.x else 1
					var sy: float = B.y - l.h * 0.6
					var ang = atan2(P.y - gd.h / 2.0 - sy, P.x - B.x)
					for j in [-0.12, 0.0, 0.12]:
						add_hz({"x": B.x - 11, "y": sy - 4, "w": 20.0, "h": 8.0, "life": 2.5, "vx": cos(ang + j) * 520, "vy": sin(ang + j) * 520, "dmg": l.hit * 0.8, "orb": true, "spr": LFX("arrow", "fx/arrow"), "face": 1})
				return false
			if a.s == 2:
				if B.ground:
					B.vx = 0.0
					a.s = 3
					a["w"] = 0.25
				return false
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"rain", "starfall":
			# chuva do alto com a marca no chão: saia das colunas
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.45
				a["w"] = 1.7
				var xs = [P.x]
				if a.n == "starfall":
					var dir = 1 if randf() < 0.5 else -1
					var n = 8 if B.phase2 else 6
					for i in n:
						var fx_ = AW0 + 50 + (AW1 - AW0 - 100) * (float(i) / (n - 1))
						xs.append(fx_ if dir > 0 else AW1 + AW0 - fx_)
				else:
					for i in (5 if B.phase2 else 4):
						xs.append(AW0 + 40 + randf() * (AW1 - AW0 - 80))
				for i in xs.size():
					add_hz({"x": xs[i] - 14, "y": -40.0, "w": 28.0, "h": 30.0, "tele": 0.7 + i * (0.16 if a.n == "starfall" else 0.12), "life": 2.0, "vy": 600.0,
						"dmg": l.hit, "floor_stop": true, "mark": true, "rock": true, "spr": LFX("rain", "fx/rock"), "spin": a.n == "starfall", "col": D.col(D.HEROES[key].cor)})
				boss_swing()
			B.vx = 0.0
			if B.tele > 0:
				B.tele -= dt
			a.w -= dt
			return a.w <= 0
		"trap":
			# arma uma armadilha de urso onde o guardião está
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.35
				a["tx"] = clamp_x(P.x, 40)
				return false
			if a.s == 1:
				B.tele -= dt
				if B.tele <= 0:
					var traps = hz.filter(func(z): return z.trap)
					if traps.size() >= 3:
						traps[0].life = 0.0
					add_hz({"x": a.tx - 18, "y": FY - 14, "w": 36.0, "h": 14.0, "life": 8.0, "dmg": l.hit, "trap": true, "spr": "fx/beartrap_0", "root": 0.9})
					spawn_parts(a.tx, FY - 6, Color("#94a0b0"), 6)
					a.s = 2
					a["w"] = 0.3
				return false
			a.w -= dt
			return a.w <= 0
		"clones":
			# some e manda duas sombras correndo dos dois lados
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.3
				return false
			if a.s == 1:
				B.tele -= dt
				if B.tele <= 0:
					a.s = 2
					a["w"] = 1.1
					spawn_parts(B.x, B.y - 30, Color("#c8f0ff"), 10)
					B.x = AW1 - 50 if P.x < W / 2 else AW0 + 50
					B.inv = 0.4
					for dir in [-1, 1]:
						var cx = clamp_x(P.x - dir * 230, 30)
						add_hz({"x": cx - 13, "y": FY - 50, "w": 26.0, "h": 50.0, "tele": 0.55, "life": 1.3, "vx": dir * 720.0, "dmg": l.hit, "clone": true, "face": dir})
				return false
			a.w -= dt
			return a.w <= 0
		"shuriken":
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.32
				a["k"] = 0
				a["w"] = 0.0
				a["cnt"] = 2 if B.phase2 else 1
				return false
			B.vx = 0.0
			if B.tele > 0:
				B.tele -= dt
				return false
			a.w -= dt
			if a.w <= 0:
				if a.k >= a.cnt:
					return true
				a.k += 1
				var sy: float = B.y - l.h * 0.6
				var ang = atan2(P.y - gd.h / 2.0 - sy, P.x - B.x)
				for j in [-0.2, 0.0, 0.2]:
					add_hz({"x": B.x - 8, "y": sy - 8, "w": 16.0, "h": 16.0, "life": 2.5, "vx": cos(ang + j) * 430, "vy": sin(ang + j) * 430, "dmg": l.hit * 0.7, "orb": true, "spr": LFX("shuriken", "fx/shuriken"), "spin": true})
				a.w = 0.45
			return false
		"boomerang":
			# arremessa e o objeto volta: cuidado nas duas passagens
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.4
				return false
			if a.s == 1:
				B.tele -= dt
				if B.tele <= 0:
					a.s = 2
					a["w"] = 0.9
					B.face = -1 if P.x < B.x else 1
					var hs = [0.6, 0.25] if B.phase2 else [0.55]
					for hh in hs:
						add_hz({"x": B.x - 12, "y": B.y - l.h * hh - 12, "w": 24.0, "h": 24.0, "life": 2.6, "vx": B.face * 620.0, "ax": -B.face * 560.0, "dmg": l.hit * 0.8, "spr": LFX("boomer", "fx/shield"), "spin": true})
				return false
			a.w -= dt
			return a.w <= 0
		"pools":
			# frascos em arco que deixam poças no chão
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.4
				a["k"] = 0
				a["w"] = 0.0
				a["cnt"] = 3 if B.phase2 else 2
				return false
			B.vx = 0.0
			if B.tele > 0:
				B.tele -= dt
				return false
			a.w -= dt
			if a.w <= 0:
				if a.k >= a.cnt:
					return true
				a.k += 1
				B.face = -1 if P.x < B.x else 1
				var sx: float = B.x
				var sy: float = B.y - l.h
				var tt = 0.8
				var tx: float = P.x + (a.k - 1) * 70.0 * -B.face
				var vy: float = (FY - 12 - sy - 0.5 * GRAV * tt * tt) / tt
				add_hz({"x": sx - 9, "y": sy - 9, "w": 18.0, "h": 18.0, "life": 2.5, "vx": (tx - sx) / tt, "vy": vy, "g": 1.0, "dmg": l.hit * 0.7, "floor_stop": true, "rock": true,
					"spr": LFX("rock", "fx/bottle"), "spin": true, "on_land": "pool"})
				a.w = 0.4
			return false
		"whip":
			# chicotada de média distância na altura do peito
			if a.s == 0:
				a.s = 1
				a["k"] = 0
				a["w"] = 0.0
			B.vx = 0.0
			a.w -= dt
			if a.w <= 0:
				if a.k >= (3 if B.phase2 else 2):
					return true
				a.k += 1
				B.face = -1 if P.x < B.x else 1
				add_hz({"x": B.x if B.face > 0 else B.x - 170, "y": B.y - l.h * 0.62 - 10, "w": 170.0, "h": 20.0, "tele": 0.34, "life": 0.14, "dmg": l.hit, "whip": true, "melee": true, "face": B.face})
				a.w = 0.6
			return false
		"beast":
			# chama um lobo que atravessa a arena
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.45
				return false
			if a.s == 1:
				B.tele -= dt
				if B.tele <= 0:
					a.s = 2
					a["w"] = 0.8
					B.face = -1 if P.x < B.x else 1
					add_hz({"x": B.x - 20, "y": FY - 26, "w": 40.0, "h": 26.0, "life": 3.0, "vx": B.face * 480.0, "dmg": l.hit, "spr": LFX("beast", "fx/wolf"), "anim": "wolf", "face": B.face})
					if B.phase2:
						var sx = AW1 - 30 if B.face > 0 else AW0 + 30
						add_hz({"x": sx - 20, "y": FY - 26, "w": 40.0, "h": 26.0, "tele": 0.7, "life": 3.0, "vx": -B.face * 480.0, "dmg": l.hit, "spr": LFX("beast", "fx/wolf"), "anim": "wolf", "face": -B.face})
					game.float_text(Vector2(B.x, B.y - l.h - 14), "AUUU!", Color("#c08ae0"), 13)
				return false
			a.w -= dt
			return a.w <= 0
		"spin":
			# redemoinho do viking: vem girando atrás do guardião
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				B.tele = 0.35
				return false
			if a.s == 1:
				B.tele -= dt
				if B.tele <= 0:
					a.s = 2
					a["hot"] = true
					a["w"] = 1.6 if B.phase2 else 1.3
				return false
			if a.s == 2:
				a.w -= dt
				B.face = -1 if P.x < B.x else 1
				B.vx = B.face * l.spd * 1.15
				boss_swing()
				if randf() < 0.4:
					spawn_parts(B.x, FY - 6, Color("#d6c3a5"), 1)
				if a.w <= 0:
					a.hot = false
					a.s = 3
					a.w = 0.45
				return false
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
		"sweep":
			# onda de luz rasteira de parede a parede: suba numa plataforma ou pule
			if a.s == 0:
				a.s = 1
				B.vx = 0.0
				a["w"] = 1.0
				var dir = 1 if B.x < W / 2 else -1
				var x0 = AW0 if dir > 0 else AW1 - 46
				add_hz({"x": x0, "y": FY - 88, "w": 46.0, "h": 88.0, "tele": 0.7, "life": 3.0, "vx": dir * 330.0, "dmg": l.hit, "pillar": true, "col": D.col(LFX("pillar", 0xfff3c4))})
				boss_swing()
			B.vx = 0.0
			a.w -= dt
			return a.w <= 0
	return true

func boss_step(dt0: float) -> void:
	var l = L()
	B.inv -= dt0
	B.flash -= dt0
	B.hurt_t -= dt0
	B.mark_t -= dt0
	B.vuln_t -= dt0
	B.slow_t -= dt0
	# veneno: dano contínuo que vai sumindo
	if B.poison > 0:
		B.poison_tick -= dt0
		B.poison_decay -= dt0
		if B.poison_tick <= 0:
			B.poison_tick = 0.5
			hurt_boss(0.7 * B.poison * (1.0 + game.evo_pct()), "especial", true)
		if B.poison_decay <= 0:
			B.poison_decay = 2.0
			B.poison -= 1
	if B.stop_t > 0:
		B.stop_t -= dt0
		return
	var dt: float = dt0 * (0.6 if B.slow_t > 0 else 1.0)
	B.guard -= dt
	B.vis_atk -= dt
	B.atk_anim += dt
	if B.stun > 0:
		B.stun -= dt
		B.vx = 0.0
		B.tele = 0.0
		move_body(B, l.w, dt, false)
		return
	if not B.act.is_empty():
		var done = act(B.act, dt)
		if not B.act.is_empty():
			B.act.t += dt
		if done:
			B.last = B.act.n
			B.act = {}
			B.tele = 0.0
			B.idle = (0.45 if B.phase2 else 0.8) * (0.8 + randf() * 0.4)
	else:
		B.idle -= dt
		B.face = -1 if P.x < B.x else 1
		B.vx = B.face * l.spd * 0.45 if absf(P.x - B.x) > 130 else 0.0
		if B.idle <= 0:
			B.act = {"n": choose_act(), "t": 0.0, "s": 0}
	move_body(B, l.w, dt, false)
	if B.ground and absf(B.vx) > 10:
		B.run_d += absf(B.vx) * dt
	if not wall.is_empty() and overlap(wall_rect(), body_b()):
		hurt_boss(wall.dmg, "especial")
		spawn_parts(wall.x, FY - 48, Color("#e8e8e8"), 16)
		if not B.act.is_empty() and B.act.get("hot", false):
			B.act.hot = false
			B.act.s = 3
			B.act["w"] = 0.6
			B.vx = 0.0
			game.float_text(Vector2(B.x, B.y - l.h - 16), "barrado!", Color("#e8e8e8"), 13)
		wall = {}
	if overlap(body_p(), body_b()) and not (P.charge_t > 0) and not (P.dive_t > 0) and not (P.wing_t > 0):
		var hot: bool = not B.act.is_empty() and B.act.get("hot", false)
		hurt_guard(l.hit if hot else l.hit * 0.5)


func hazards_step(dt: float) -> void:
	var pb = body_p()
	var frozen: bool = not B.is_empty() and B.stop_t > 0
	if not frozen:
		var add_pools = []
		for z in hz:
			if z.tele > 0:
				z.tele -= dt
				if z.tele <= 0 and z.melee:
					boss_swing()
				continue
			z.life -= dt
			if z.g > 0:
				z.vy += GRAV * dt
			if z.ax != 0.0:
				var before: float = z.vx
				z.vx += z.ax * dt
				if signf(before) != signf(z.vx):
					z.hit_done = false
			z.x += z.vx * dt
			z.y += z.vy * dt
			if z.floor_stop and z.y + z.h >= FY:
				z.y = FY - z.h
				if not z.landed:
					z.landed = true
					z.life = minf(z.life, 0.1)
					spawn_parts(z.x + z.w / 2.0, FY - 2, z.col, 8)
					if z.on_land == "pool":
						add_pools.append(z.x + z.w / 2.0)
			if z.orb and (z.y > FY or z.y < -30):
				z.life = 0.0
			var zr = Rect2(z.x, z.y, z.w, z.h)
			if not wall.is_empty() and (z.orb or z.rock or z.wave or z.ax != 0.0) and overlap(zr, wall_rect()):
				z.life = 0.0
				spawn_parts(z.x + z.w / 2.0, z.y + z.h / 2.0, Color("#e8e8e8"), 5)
				continue
			if z.x + z.w < AW0 - 40 or z.x > AW1 + 40:
				z.life = 0.0
			if not z.warn and not z.hit_done and z.life > 0 and overlap(pb, zr):
				if z.trap:
					if P.inv > 0 and P.block_t <= 0:
						continue
					z.spr = "fx/beartrap_1"
					z.life = minf(z.life, 0.6)
					P.root_t = z.root
					game.float_text(Vector2(P.x, P.y - gd.h - 30), "preso!", Color("#94a0b0"), 12)
				hurt_guard(z.dmg)
				if z.once:
					z.hit_done = true
		for x in add_pools:
			add_hz({"x": x - 36, "y": FY - 10, "w": 72.0, "h": 10.0, "life": 3.5, "dmg": L().hit * 0.6, "pool": true, "once": false, "col": D.col(LFX("pool", 0x8ce65a))})
		hz = hz.filter(func(z): return z.tele > 0 or z.life > 0)
	var bb = body_b()
	for s in shots:
		if s.delay > 0:
			s.delay -= dt
			if s.track:
				s.x = B.x
			continue
		s.life -= dt
		if s.kind == "bolt":
			if not s.fired:
				s.fired = true
				s.life = 0.22
				if absf(B.x - s.x) < 36 and win == 0:
					if hurt_boss(s.dmg, "especial") and s.stun > 0 and B.inv <= 0:
						B.stun = maxf(B.stun, s.stun)
					add_vfx("fx/spark_guard", B.x, B.y - L().h / 2.0, 0.2)
				spawn_parts(s.x, FY - 4, Color("#fff0a0"), 10)
				game.shake(0.08, 0.004)
			continue
		s.x += s.vx * dt
		s.y += s.vy * dt
		if s.kind == "meteor":
			if s.y >= FY - 16:
				s.life = 0.0
				_boom(s.x, FY - 20, s.r, s.dmg, Color("#ff8a3d"))
			continue
		if s.x < AW0 - 20 or s.x > AW1 + 20 or s.y > FY or s.y < -60:
			s.life = 0.0
		if s.life > 0 and win == 0 and not s.hit and overlap(Rect2(s.x - s.r, s.y - s.r, s.r * 2, s.r * 2), bb):
			if s.pierce:
				s.hit = true
			else:
				s.life = 0.0
			if hurt_boss(s.dmg, s.cat):
				if s.slow > 0:
					B.slow_t = maxf(B.slow_t, s.slow)
				if s.poison > 0:
					B.poison = mini(gd.pcap, B.poison + s.poison)
				if s.basic:
					on_basic_hit(s.x, s.y)
					hitstop = maxf(hitstop, 0.03)
			add_vfx("fx/spark_guard", s.x, s.y, 0.16, false, 1.4)
			spawn_parts(s.x, s.y, s.col, 3)
	shots = shots.filter(func(s): return s.life > 0 or s.delay > 0)
	fx_step(dt)


func fx_step(dt: float) -> void:
	for p in parts:
		p.life -= dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 500 * dt
	parts = parts.filter(func(p): return p.life > 0)
	for v in vfx:
		v.t += dt
	vfx = vfx.filter(func(v): return v.t < v.dur)


func update(dt: float) -> void:
	if not on:
		return
	_read_input()
	if hitstop > 0:
		# hit stop: tudo congela por um instante para o golpe "pesar"
		hitstop -= dt
		fx_step(dt * 0.25)
		return
	t += dt
	if intro > 0:
		intro -= dt
		if intro <= 0:
			game.float_text(Vector2(W / 2, H / 2 - 20), "LUTE!", Color("#ece2d2"), 30)
		hazards_step(dt)
		return
	if win != 0:
		over -= dt
		P.vx = 0.0
		move_body(P, gd.w, dt, true)
		hazards_step(dt)
		if over <= 0:
			if win > 0:
				reward()
			else:
				learn_duel()
				game.lost_to = key
				game.game_over()
		return
	player_step(dt)
	allies_step(dt)
	boss_step(dt)
	hazards_step(dt)


# depois da luta, o lendário conta aos outros como você luta
func learn_duel() -> void:
	var du: Dictionary = game.duel
	var tot = maxf(1.0, use.time)
	var near: float = use.near / tot
	var far: float = use.far / tot
	var g = {"dash": 2 if use.dash >= 12 else (1 if use.dash >= 5 else 0),
		"pulo": 2 if use.pulo >= 18 else (1 if use.pulo >= 8 else 0),
		"especial": 2 if use.especial >= 8 else (1 if use.especial >= 4 else 0),
		"perto": 2 if near >= 0.8 else (1 if near >= 0.6 else 0),
		"longe": 2 if far >= 0.8 else (1 if far >= 0.6 else 0)}
	var low = {"dash": use.dash <= 1, "pulo": use.pulo <= 2, "especial": use.especial <= 0, "perto": near < 0.3, "longe": far < 0.3}
	for k in D.DUEL_KEYS:
		if g[k] > 0:
			du[k] = mini(4, int(du[k]) + g[k])
		elif low[k] and du[k] > 0:
			du[k] -= 1


func reward() -> void:
	learn_duel()
	game.mission_add("minotauro_3")
	var pts: Array = game.leg_points(game.guardian, game.leg_count + 1, true)
	if stats.lost < clock0 * 0.3:
		game.mission_add("minotauro_2")
	if use.dash == 0:
		game.mission_add("dragao_2")
	var soul = D.r1(D.CFG.SOUL_BASE * D.CFG.SOUL_LEG * (1.0 + game.fame_pct()))
	var e: int = game.legend_fell(key, true)
	game.clock += soul
	game.kills += 1
	game.phase = "reward"
	var nome: String = D.HEROES[key].nome.get_slice(",", 0)
	var title = "%s foi %s" % [nome, "derrotada" if D.HEROES[key].get("fem", false) else "derrotado"]
	var txt = "O %s defendeu o coração. Energia absorvida: +%ss. +%d de essência. O guardião evoluiu para +%s de dano. +%d pontos de classe e +%d pontos de guardião%s. Melhore o guardião ou a masmorra; o próximo lendário virá mais forte." % [gd.nome, D.fmt(soul), e, D.pct(game.evo), pts[0], pts[1], " (1ª vitória contra este lendário)" if pts[2] else ""]
	# opções: pelo menos uma habilidade da classe atual, mais uma do guardião e duas da masmorra
	var sk = []
	for i in 3:
		if sk_lv(i) < 3:
			sk.append(i)
	sk.shuffle()
	var gens = []
	for u in D.GUP:
		if game.g_up[u.id] < u.max:
			gens.append(u)
	var rest = []
	for i in sk.slice(1):
		rest.append({"sk": i})
	for u in gens:
		rest.append({"u": u})
	rest.shuffle()
	var gp = []
	if sk.size() > 0:
		gp.append({"sk": sk[0]})
	gp.append_array(rest)
	gp = gp.slice(0, 2)
	var opts = []
	for o in gp:
		if o.has("sk"):
			var k: String = sk_key(o.sk)
			var s = game.skill_info(k)
			opts.append({"tag": "Habilidade · " + gd.nome, "t": "%s nv %d" % [s.nome, sk_lv(o.sk) + 1],
				"d": "+35% de poder, recarga 12% menor e efeito 20% mais longo.", "f": func(): game.g_skl[k] = game.sk_level(k) + 1, "green": true})
		else:
			var u = o.u
			opts.append({"tag": "Guardião · " + D.GUARDS[game.guardian].nome, "t": u.t, "d": u.d, "f": func(): game.g_up[u.id] += 1, "green": true})
	var pool = []
	for c in game.cards:
		if c.ok.call() and not c.get("lendaria", false):
			pool.append(c)
	pool.shuffle()
	for c in pool.slice(0, 2):
		opts.append({"tag": "Masmorra · " + c.tag, "t": c.t, "d": c.d, "f": c.f})
	game.ui.show_reward(title, txt, opts)


func finish_reward(o: Dictionary) -> void:
	o.f.call()
	stop()
	game.phase = "wave"


# ===== desenho =====
func _guard_frame() -> String:
	var a = gd.atk
	if P.flash > 0.6:
		return "hurt"
	if P.atk_ph == "anti":
		return "atk0"
	if P.atk_ph == "act":
		if a.kind == "melee":
			return "atk1" if P.atk_pt > a.t * 0.5 else "atk2"
		return "atk2"
	if P.atk_ph == "rec":
		return "atk3"
	if P.spin_t > 0:
		return "atk%d" % (1 + int(t * 14) % 2)
	if P.shot_vis > 0:
		return "atk2"
	if P.charge_t > 0:
		return "atk2"
	if P.cast_vis > 0 or P.breath_t > 0 or P.block_t > 0 or P.ice_t > 0:
		return "cast"
	if P.dash_t > 0 or P.wing_t > 0:
		return "run2"
	if not P.ground or P.dive_t > 0:
		return "jump" if P.vy < 0 else "fall"
	if absf(P.vx) > 10:
		return "run%d" % (int(P.run_d / 14.0) % 6)
	return "idle%d" % (int(t * 4) % 4)


func _legend_frame() -> String:
	var hot: bool = not B.act.is_empty() and B.act.get("hot", false)
	if B.stun > 0 or (B.hurt_t > 0 and B.act.is_empty()):
		return "hurt"
	if hot or B.vis_atk > 0:
		if B.atk_anim < 0.06:
			return "atk0"
		return "atk1" if B.atk_anim < 0.16 else "atk2"
	if B.tele > 0:
		return "tele"
	for z in hz:
		if z.warn and z.tele > 0:
			return "tele"
	if absf(B.vx) > 10 and B.ground:
		return "run%d" % (int(B.run_d / 16.0) % 4)
	return "idle%d" % (int(t * 2.5) % 2)


func _zag(g: CanvasItem, x: float, y0: float, y1: float, col: Color, w: float) -> void:
	var pts = PackedVector2Array()
	var n = 8
	for i in n + 1:
		var yy = lerpf(y0, y1, float(i) / n)
		pts.append(Vector2(x + (0.0 if i == 0 or i == n else randf_range(-12, 12)), yy))
	g.draw_polyline(pts, col, w)


func draw(g: CanvasItem) -> void:
	if P.is_empty():
		return
	var now = Time.get_ticks_msec()
	var l = L()
	Art.spr_r(g, "bg/arena", Rect2(0, 0, W, H))
	# ponteiro do relógio gigante = vida do guardião
	var cc = Vector2(360, 140)
	var ang = -PI / 2 + fmod(maxf(game.clock, 0.0), 60.0) / 60.0 * TAU
	g.draw_line(cc, cc + Vector2(cos(ang), sin(ang)) * 68, Color("#140c1c"), 8)
	g.draw_line(cc, cc + Vector2(cos(ang), sin(ang)) * 66, Color("#ff4050") if game.clock < 10 else Color("#ffc430"), 4)
	# tochas (luz quente que tremula)
	for tx in [86.0, W - 86]:
		var fl = 1.0 + sin(now / 90.0 + tx) * 0.06
		for k2 in [[90.0, 0.05], [60.0, 0.06], [34.0, 0.08]]:
			g.draw_circle(Vector2(tx, 178), k2[0] * fl, Color(1, 0.5, 0.2, k2[1]))
		Art.spr(g, "arena/flame_%d" % (int(now / 110 + tx) % 3), tx, 190, 2.0)
	for p in PLATS:
		Art.spr_r(g, "arena/plat", Rect2(p.x, p.z, p.y - p.x, 14))
	# áreas do guardião
	for z in zones:
		var k: float = clampf(z.life / 0.5, 0.0, 1.0)
		match z.kind:
			"snow":
				g.draw_rect(Rect2(z.x - z.w / 2.0, FY - z.h, z.w, z.h), Color(0.8, 0.95, 1.0, 0.12 * k))
				for i in 10:
					var fx_ = z.x + fmod(i * 37.0 + now / 20.0, z.w) - z.w / 2.0
					var fy_ = FY - z.h + fmod(i * 53.0 + now / 6.0, z.h)
					Art.dot(g, Vector2(fx_, fy_), 4, Color(1, 1, 1, 0.8 * k))
			"poison":
				for i in 5:
					Art.ellipse(g, Vector2(z.x + (i - 2) * z.w * 0.18, FY - 26 - sin(now / 300.0 + i) * 8), 30, 20, Color(0.45, 0.85, 0.3, 0.16 * k))
			"fire":
				Art.spr(g, "arena/flame_%d" % (int(now / 90 + z.x) % 3), z.x, FY, 1.4, false, Color(1, 1, 1, k))
			"storm":
				g.draw_rect(Rect2(z.x - z.w / 2.0, FY - z.h, z.w, z.h), Color(1.0, 0.95, 0.5, 0.1 * k))
				if randf() < 0.3:
					_zag(g, z.x + randf_range(-z.w / 2.0, z.w / 2.0), FY - z.h, FY, Color(1, 1, 0.7, 0.7 * k), 2)
	# perigos do lendário: vermelho piscando é aviso
	var blink = 0.22 + 0.18 * sin(now / 55.0)
	for z in hz:
		var zr = Rect2(z.x, z.y, z.w, z.h)
		var ctr = zr.get_center()
		if z.tele > 0 or z.warn:
			if z.mark:
				g.draw_rect(Rect2(z.x, FY - 6, z.w, 6), Color(1, 0.3, 0.25, blink + 0.3))
				for yy in range(0, int(FY), 16):
					g.draw_rect(Rect2(z.x + z.w / 2 - 1, yy, 2, 8), Color(1, 0.3, 0.25, 0.3))
			elif z.clone:
				Art.spr(g, "arena/%s_tele" % key, ctr.x, z.y + z.h, 2.0, z.face < 0, Color(0.6, 0.8, 1.0, 0.35 + blink * 0.5))
			elif z.whip:
				g.draw_rect(Rect2(z.x, ctr.y - 1, z.w, 2), Color(1, 0.3, 0.25, blink + 0.3))
			elif z.spr != "":
				_draw_hz_spr(g, z, ctr, now, Color(1, 1, 1, 0.45))
			elif z.orb or z.wave:
				Art.spr_c(g, LFX("orb", "fx/orb") if z.orb else LFX("wave", "fx/wave_dust"), ctr.x, ctr.y, 2.0, 0.0, Color(1, 1, 1, 0.5))
			else:
				g.draw_rect(zr, Color(1, 0.3, 0.25, blink))
				g.draw_rect(zr, Color(1, 0.3, 0.25, 0.8), false, 2)
			continue
		var zc: Color = z.col
		if z.pillar:
			g.draw_rect(zr, Color(zc.r, zc.g, zc.b, 0.7))
			g.draw_rect(Rect2(z.x + z.w * 0.3, z.y, z.w * 0.4, z.h), Color(1, 1, 1, 0.9))
			for i in 6:
				Art.dot(g, Vector2(z.x + randf() * z.w, z.y + randf() * z.h), 4, Color(1, 1, 0.8))
		elif z.pool:
			var k3 = clampf(z.life / 0.6, 0.0, 1.0)
			Art.ellipse(g, Vector2(ctr.x, FY - 3), z.w / 2.0, 6, Color(zc.r, zc.g, zc.b, 0.55 * k3))
			Art.ellipse(g, Vector2(ctr.x - 8, FY - 4), z.w / 4.0, 3, Color(1, 1, 1, 0.3 * k3))
			if randf() < 0.1:
				spawn_parts(z.x + randf() * z.w, FY - 4, zc, 1)
		elif z.clone:
			Art.spr(g, "arena/%s_atk1" % key, ctr.x, z.y + z.h, 2.0, z.face < 0, Color(0.6, 0.85, 1.0, 0.7))
		elif z.whip:
			var pts = PackedVector2Array()
			var x0: float = B.x + B.face * 14
			for i in 13:
				var k4 = i / 12.0
				var xx = lerpf(x0, z.x + (z.w if z.face > 0 else 0.0), k4)
				pts.append(Vector2(xx, ctr.y + sin(k4 * 9.0 + now / 30.0) * 5 * (1.0 - k4)))
			g.draw_polyline(pts, Color("#3a2416"), 5)
			g.draw_polyline(pts, Color("#a06a42"), 3)
			Art.spr_c(g, "fx/slash_hero_1", z.x + (z.w if z.face > 0 else 0.0), ctr.y, 1.2, 0.0, Color.WHITE, z.face < 0)
		elif z.melee:
			# golpe de herói: corte fino e frio
			var fr = clampi(int((1.0 - z.life / z.max_life) * 3), 0, 2)
			var sc2 = clampf(z.w / 40.0, 1.6, 3.6)
			Art.spr_c(g, "fx/slash_%s_%d" % ["hero_heavy" if l.get("heavy", false) else "hero", fr], ctr.x, ctr.y, sc2, 0.0, Color.WHITE, z.face < 0)
		elif z.spr != "":
			_draw_hz_spr(g, z, ctr, now, Color.WHITE)
		elif z.wave:
			Art.spr(g, LFX("wave", "fx/wave_dust"), ctr.x, z.y + z.h, 2.0, z.vx < 0)
		else:
			g.draw_rect(zr, Color(1, 0.95, 0.85, 0.35))
			g.draw_rect(zr, Color(1, 1, 1, 0.8), false, 2)
	# projéteis e invocações do guardião
	for s in shots:
		if s.kind == "bolt":
			if s.delay > 0:
				g.draw_rect(Rect2(s.x - 2, 0, 4, FY), Color(1, 0.95, 0.5, 0.25 + blink * 0.5))
			else:
				_zag(g, s.x, 0, FY, Color(1, 1, 0.7, 0.9), 6)
				_zag(g, s.x, 0, FY, Color.WHITE, 2)
			continue
		if s.delay > 0:
			continue
		if s.kind == "meteor":
			Art.ellipse(g, Vector2(s.tx, FY - 2), 30, 6, Color(0, 0, 0, 0.35))
			Art.spr_c(g, s.spr, s.x, s.y, 2.0, atan2(s.vy, s.vx) - PI / 2)
			continue
		if s.kind == "bull":
			Art.spr(g, "fx/bull_%d" % (int(now / 90) % 2), s.x, FY, 2.0, s.vx < 0, Color(1, 1, 1, 0.75))
			continue
		var a = atan2(s.vy, s.vx)
		if s.ground:
			Art.spr(g, "fx/wave_dust", s.x, s.y + 14, 2.0, s.vx < 0)
		elif s.spr != "":
			Art.spr_c(g, s.spr, s.x, s.y, 2.0, a)
		else:
			Art.spr_c(g, "fx/bone", s.x, s.y, 2.0, a)
	for m in mins:
		Art.spr(g, "fx/skel_%d" % m.f, m.x, m.y, 2.0, m.face < 0, Color(1, 1, 1, clampf(m.life, 0.3, 1.0)))
	if not wall.is_empty():
		var wr = wall_rect()
		Art.spr_r(g, "fx/bonewall", Rect2(wr.position.x - 2, wr.position.y - 4, 28, 100))
	# lendário
	if win != 1:
		var mod = Color.WHITE
		if B.flash > 0:
			mod = Color(8, 8, 8)
		elif B.stop_t > 0:
			mod = Color(0.75, 0.7, 0.45)
		elif B.slow_t > 0:
			mod = Color(0.7, 0.9, 1.2)
		elif B.poison > 0:
			mod = Color(0.8, 1.1, 0.7)
		Art.spr(g, "arena/%s_%s" % [key, _legend_frame()], B.x, B.y, 2.0, B.face < 0, mod)
		var hot: bool = not B.act.is_empty() and B.act.get("hot", false)
		if hot and B.act.n == "spin":
			var ra = now / 40.0
			g.draw_arc(Vector2(B.x, B.y - l.h * 0.5), 44, ra, ra + 2.4, 12, Color(0.85, 0.92, 1.0, 0.85), 5)
			g.draw_arc(Vector2(B.x, B.y - l.h * 0.5), 44, ra + PI, ra + PI + 2.4, 12, Color(0.85, 0.92, 1.0, 0.85), 5)
		elif hot:
			Art.spr_c(g, "fx/slash_%s_%d" % ["hero_heavy" if l.get("heavy", false) else "hero", int(now / 60) % 3], B.x + B.face * l.w * 0.6, B.y - l.h * 0.5, 2.0, 0.0, Color(1, 1, 1, 0.8), B.face < 0)
		if B.guard > 0:
			g.draw_arc(Vector2(B.x, B.y - l.h / 2.0), l.h * 0.7, 0, TAU, 24, Color(1, 0.85, 0.3, 0.9), 4)
		if B.tele > 0:
			g.draw_rect(Rect2(B.x - 3, B.y - l.h - 52, 6, 16), Color("#ff4050"))
			g.draw_rect(Rect2(B.x - 3, B.y - l.h - 32, 6, 6), Color("#ff4050"))
		if B.mark_t > 0:
			for i in 6:
				var aa = now / 300.0 + i * TAU / 6
				Art.dot(g, Vector2(B.x + cos(aa) * l.w, B.y - l.h / 2.0 + sin(aa) * l.h * 0.6), 6, Color("#c08ae0"))
		if B.stun > 0:
			for i in 3:
				var aa = now / 200.0 + i * 2.1
				Art.dot(g, Vector2(B.x + cos(aa) * 16, B.y - l.h - 12 + sin(aa) * 4), 6, Color("#ffc430"))
		if B.poison > 0:
			for i in B.poison:
				Art.dot(g, Vector2(B.x - B.poison * 4 + i * 8 + 4, B.y - l.h - 24), 5, Color("#96e65a"))
		if B.vuln_t > 0:
			g.draw_arc(Vector2(B.x, B.y - l.h / 2.0), l.h * 0.62, 0, TAU, 20, Color(1, 0.35, 0.2, 0.5), 2)
	# guardião
	if P.king_t > 0:
		g.draw_arc(Vector2(P.x, P.y - gd.h / 2.0), gd.h * 0.8, 0, TAU, 28, Color(1, 0.77, 0.19, 0.6), 4)
	if P.fury_t > 0 or P.rage >= 5:
		for i in 4:
			Art.dot(g, Vector2(P.x + randf_range(-24, 24), P.y - randf() * gd.h), 4, Color("#ff4050"))
	if P.leech_t > 0 and randf() < 0.5:
		Art.dot(g, Vector2(P.x + randf_range(-20, 20), P.y - randf() * gd.h), 4, Color("#ff7080"))
	if P.scale_t > 0:
		g.draw_arc(Vector2(P.x, P.y - gd.h / 2.0), 80, 0, TAU, 32, Color(1, 0.55, 0.15, 0.35), 4)
	if P.breath_t > 0:
		Art.tri(g, Vector2(P.x + P.face * 22, P.y - gd.h * 0.7), Vector2(P.x + P.face * 190, P.y - gd.h - 16), Vector2(P.x + P.face * 190, P.y + 4), Color(1, 0.55, 0.15, 0.25))
	var hide: bool = P.inv > 0 and P.flash > 0 and (now / 70) % 2 == 0
	if not hide and win != -1:
		var gm = Color.WHITE
		if P.flash > 0.78:
			gm = Color(8, 8, 8)
		elif P.haste_t > 0 and P.inv > 0:
			gm = Color(1, 1, 1, 0.55)
		Art.spr(g, "arena/%s_%s" % [gd.key, _guard_frame()], P.x, P.y, 2.0, P.face < 0, gm)
		if P.ice_t > 0:
			g.draw_rect(Rect2(P.x - gd.w / 2.0 - 8, P.y - gd.h - 12, gd.w + 16, gd.h + 12), Color(0.6, 0.9, 1.0, 0.45))
			g.draw_rect(Rect2(P.x - gd.w / 2.0 - 8, P.y - gd.h - 12, gd.w + 16, gd.h + 12), Color(0.85, 1, 1, 0.9), false, 2)
		if P.block_t > 0:
			g.draw_arc(Vector2(P.x + P.face * 10, P.y - gd.h / 2.0), gd.h * 0.7, -PI / 2.5 if P.face > 0 else PI - PI / 2.5, PI / 2.5 if P.face > 0 else PI + PI / 2.5, 14, Color("#d6c3a5"), 6)
		if P.spin_t > 0:
			var ra = now / 35.0
			for k5 in 2:
				g.draw_arc(Vector2(P.x, P.y - gd.h * 0.5), 58, ra + k5 * PI, ra + k5 * PI + 2.2, 12, Color(1, 0.45, 0.2, 0.85), 7)
		if P.fly_t > 0:
			Art.dot(g, Vector2(P.x - P.face * 16, P.y - gd.h * 0.6), 6, Color(0.4, 0.85, 1.0, 0.6))
	if P.root_t > 0:
		Art.spr_c(g, "fx/beartrap_1", P.x, FY - 6, 2.0)
	# rastros e faíscas
	for v in vfx:
		if v.t < 0:
			continue
		if v.get("ring", false):
			var k6 = v.t / v.dur
			var vc: Color = v.get("col", Color("#ff8a3d"))
			g.draw_arc(Vector2(v.x, v.y), (20 + k6 * 70) * v.scale, 0, TAU, 28, Color(vc.r, vc.g, vc.b, 1.0 - k6), 4)
			continue
		var fr = mini(2, int(v.t / v.dur * 3))
		Art.spr_c(g, "%s_%d" % [v.spr, fr], v.x, v.y, v.scale, v.rot, Color.WHITE, v.flip)
	for p in parts:
		var pc: Color = p.col
		Art.dot(g, Vector2(p.x, p.y), p.r * 1.6, Color(pc.r, pc.g, pc.b, clampf(p.life / p.max * 1.5, 0, 1)))
	# barras: guardião (tempo) e lendário
	var gp = clampf(game.clock / maxf(1.0, clock0), 0.0, 1.0)
	g.draw_rect(Rect2(14, 30, 224, 12), Color("#140c1c"))
	g.draw_rect(Rect2(16, 32, 220 * gp, 8), Color("#ff4050") if game.clock < 10 else Color("#ffc430"))
	for i in 3:
		var rd: float = 1.0 - P.cd[i] / P.cd_max[i] if P.cd[i] > 0 else 1.0
		g.draw_rect(Rect2(14 + i * 58, 46, 54, 8), Color("#140c1c"))
		g.draw_rect(Rect2(16 + i * 58, 48, 50 * rd, 4), Color("#60d8f4") if rd >= 1 else Color("#24607a"))
	# barra de poder da suprema
	var ur = P.ult / 100.0
	g.draw_rect(Rect2(186, 46, 54, 8), Color("#140c1c"))
	g.draw_rect(Rect2(188, 48, 50 * ur, 4), Color("#ffc430") if ur >= 1 else Color("#8a6a20"))
	if gd.passive == "furia_acumula" and P.rage > 0:
		for i in P.rage:
			g.draw_rect(Rect2(16 + i * 9, 58, 6, 6), Color("#ff4050"))
	var bp = maxf(0.0, B.hp / B.max)
	g.draw_rect(Rect2(W - 238, 30, 224, 12), Color("#140c1c"))
	g.draw_rect(Rect2(W - 236 + 220 * (1 - bp), 32, 220 * bp, 8), D.col(D.HEROES[key].cor))
	g.draw_rect(Rect2(W - 236 + 109, 30, 2, 12), Color("#140c1c"))
	Art.text_left(g, Vector2(16, 10), "%s +%s  %ss" % [gd.nome, D.pct(game.evo), D.fmt(maxf(0.0, game.clock))], Color("#fff0d8"), 14)
	Art.text_left(g, Vector2(W - 16, 10), D.HEROES[key].nome.get_slice(",", 0) + (" · fúria" if B.phase2 else ""), Color("#fff0d8"), 14, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_hz_spr(g: CanvasItem, z: Dictionary, ctr: Vector2, now: int, mod: Color) -> void:
	if z.anim == "wolf":
		Art.spr(g, "%s_%d" % [z.spr, int(now / 80) % 2], ctr.x, z.y + z.h, 2.0, z.vx < 0 or (z.vx == 0 and z.face < 0), mod)
	elif z.trap:
		Art.spr_c(g, z.spr, ctr.x, ctr.y, 2.0, 0.0, mod)
	elif z.spin:
		Art.spr_c(g, z.spr, ctr.x, ctr.y, 2.0, now / 70.0, mod)
	else:
		var a = atan2(z.vy, z.vx) if (z.vx != 0 or z.vy != 0) else (0.0 if z.face > 0 else PI)
		Art.spr_c(g, z.spr, ctr.x, ctr.y, 2.0, a, mod)


func ult_ratio() -> float:
	return 0.0 if P.is_empty() else P.ult / 100.0


func cd_ratio(i: int) -> float:
	if P.is_empty() or P.cd[i] <= 0:
		return 1.0
	return 1.0 - P.cd[i] / P.cd_max[i]
