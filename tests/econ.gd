extends SceneTree
## Teste automático: joga uma run inteira com um robô simples e lutas de guardião.
## Rode: godot --headless --fixed-fps 60 -s res://tests/sim.gd

var main
var frame := 0
var mode := "run"
var fights := []
var cur_fight := {}
var results := []
var waited := 0
var log_waves := {}
var arenas := 0
var rewards := 0
var max_frames := 60 * 60 * 60
var last_leg := 0


func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	# cada classe de cada guardião contra um lendário diferente (rodízio), mais todos os lendários uma vez
	var legs = ["lyra", "borin", "seraphine", "kael", "yuki", "garrick", "morgana", "thorne", "ignis", "bram", "astra", "ragnar", "nyx"]
	var n = 0
	for g in ["minotauro", "lich", "dragao"]:
		for c in 4:
			fights.append([g, c, legs[n % legs.size()]])
			n += 1
	fights.append(["dragao", 0, "ragnar"])


func bot_arena() -> void:
	var A = main.arena
	for a in ["g_left", "g_right", "g_jump", "g_dash", "g_s0", "g_s1", "g_s2", "g_atk"]:
		Input.action_release(a)
	if A.intro > 0 or A.win != 0:
		return
	var P = A.P
	var B = A.B
	var d: float = B.x - P.x
	var danger = false
	for z in A.hz:
		if not z.warn and z.tele <= 0.15 and absf(z.x + z.w / 2 - P.x) < 120 and z.y + z.h > 396:
			danger = true
	if not B.act.is_empty() and B.act.get("hot", false):
		danger = true
	if danger and P.ground and frame % 2 == 0:
		Input.action_press("g_jump")
	var want = 260.0 if main.guardian == "lich" else 50.0
	if absf(d) > want + 20:
		Input.action_press("g_right" if d > 0 else "g_left")
	elif absf(d) < want - 20:
		Input.action_press("g_left" if d > 0 else "g_right")
	P.face = 1 if d > 0 else -1
	Input.action_press("g_atk")
	if randf() < 0.02:
		Input.action_press("g_s%d" % (randi() % 3))
	if randf() < 0.01:
		Input.action_press("g_dash")


func bot_dungeon() -> void:
	if main.phase != "wave" or frame % 300 != 0:
		return
	for n in 3:
		var p = main.route[3 + randi() % (main.route.size() - 6)]
		for k in ["espinhos", "fogo", "alcapao"]:
			main.tool = k
			if main.can_place(k, p.x, p.y):
				main.board_click(Vector2(p.x * 40 + 5, p.y * 40 + 5))
				break
		var k2 = ["besta", "ampulheta", "runa", "ganancia"][randi() % 4]
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if main.can_place(k2, p.x + dd.x, p.y + dd.y):
				main.tool = k2
				main.board_click(Vector2((p.x + dd.x) * 40 + 5, (p.y + dd.y) * 40 + 5))
				break
	for k in ["esqueleto", "ogro"]:
		if main.unlocked.has(k):
			main.summon(k)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 3:
		main.set_process(false)
		main.ui.show_grim()
		main.ui.close_grim()
		main.begin()
		main.clock = 3000.0
		main.unlock["alcapao"] = true
		main.unlock["runa"] = true
		main.unlocked["fogo"] = true
		main.unlocked["alcapao"] = true
		main.unlocked["runa"] = true
		main.unlocked["ampulheta"] = true
		main.unlocked["ganancia"] = true
		main.unlocked["ogro"] = true
	if frame < 3:
		return false
	if mode == "run":
		if main.phase == "arena":
			arenas += 1
			if main.arena.win == 0 and main.arena.intro <= 0:
				main.arena.hurt_boss(99999, "especial")   # teste de economia: o guardião sempre vence
			bot_arena()
		else:
			bot_dungeon()
		main.clock = maxf(main.clock, 2000.0)   # teste de economia: relógio infinito
		main.step(1.0 / 60.0)
		main.ui.sync()
		if main.leg_count != last_leg:
			last_leg = main.leg_count
			print("LENDARIO ", main.leg_count, " na onda ", main.wave)
		if main.wave not in log_waves:
			log_waves[main.wave] = true
			print("onda ", main.wave, " clock ", snapped(main.clock, 0.1), " fama ", snapped(main.fame, 0.1), "% evo ", snapped(main.evo, 0.1), "% heróis no mapa ", main.heroes.size(), " kl ", main.kl)
		if main.ui.overlay.visible and main.phase != "over" and main.phase != "intro":
			waited += 1
			if waited > 2 and main.ui.ov_cards.get_child_count() > 0:
				waited = 0
				if main.phase == "reward":
					rewards += 1
				var kids = main.ui.ov_cards.get_children().filter(func(c): return not c.is_queued_for_deletion())
				if kids.size() > 0:
					kids[0].pressed.emit()
		if main.phase == "over" or main.wave >= 31 or frame > max_frames:
			print("FIM DA RUN: onda ", main.wave, " fase ", main.phase, " lendários ", main.leg_count, " frames de arena ", arenas, " recompensas ", rewards, " guardião ", main.guardian, " duel ", main.duel, " abates ", main.kills)
			return true
			main.fresh_state()
			main.set_path(main.gen_path())
		return false
	if mode == "fights":
		if cur_fight.is_empty() or main.phase != "arena":
			if not cur_fight.is_empty():
				results.append("%s x %s: %s em %.1fs, relógio %.1f" % [cur_fight.g, cur_fight.l, "VENCEU" if main.phase == "reward" else "perdeu", cur_fight.t, main.clock])
				if main.phase == "reward":
					main.ui.overlay.visible = false
					main.arena.stop()
			if fights.is_empty():
				for r in results:
					print(r)
				print("OK")
				return true
			var f = fights.pop_front()
			main.fresh_state()
			main.set_path(main.gen_path())
			main.guardian = f[0]
			main.g_cls = f[1]
			main.clock = 50.0
			main.phase = "wave"
			var h = main.Hero.new()
			h.type = f[2]
			h.hp = 1.0
			h.max = 1.0
			main.arena.start(h)
			cur_fight = {"g": "%s_%d" % [f[0], f[1]], "l": f[2], "t": 0.0}
		bot_arena()
		main.step(1.0 / 60.0)
		main.ui.sync()
		cur_fight.t += 1.0 / 60.0
		if cur_fight.t > 120:
			main.phase = "timeout"
	return false
