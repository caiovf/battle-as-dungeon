extends SceneTree
## Teste de balanceamento da arena: cada lendário contra o guardião base, com relógios e ordens diferentes.
## Mostra: venceu?, tempo de luta, golpes levados, segundos perdidos e % do relógio perdido.
## Rode: godot --headless --fixed-fps 60 -s res://tests/balance.gd

const D = preload("res://scripts/data.gd")
var main
var frame := 0
var fights := []
var cur := {}
var rows := []


func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	var legs = ["lyra", "borin", "seraphine", "kael", "yuki", "garrick", "morgana", "thorne", "ignis", "bram", "astra", "ragnar", "nyx"]
	var g = OS.get_environment("BAL_G")
	if g == "":
		g = "minotauro"
	for clk in [100.0, 220.0]:
		for n in [1, 2, 4, 8]:
			for l in legs:
				fights.append({"g": g, "l": l, "clock": clk, "n": n})


func bot() -> void:
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


func _process(_d: float) -> bool:
	frame += 1
	if frame < 3:
		return false
	if cur.is_empty() or main.phase != "arena":
		if not cur.is_empty():
			var A = main.arena
			var won = main.phase == "reward"
			rows.append("%-10s %-9s relógio %3d  lendário nº%d  %-7s %5.1fs  golpes %2d  perdeu %5.1fs (%3d%%)  por golpe %4.1fs" % [cur.g, cur.l, int(cur.clock), cur.n, "VENCEU" if won else "PERDEU", cur.t, A.stats.hits, A.stats.lost, int(100.0 * A.stats.lost / A.clock0), A.stats.lost / maxf(1, A.stats.hits)])
			if won:
				main.ui.overlay.visible = false
				main.arena.stop()
		if fights.is_empty():
			for r in rows:
				print(r)
			print("OK")
			return true
		cur = fights.pop_front()
		main.fresh_state()
		main.set_path(main.gen_path())
		main.guardian = cur.g
		main.g_cls = 0
		main.leg_count = cur.n - 1
		main.fame = 15.0 * cur.n
		main.evo = 15.0 * (cur.n - 1) + 4.0
		main.clock = cur.clock - 10.0
		# a cada lendário vencido o jogador costuma melhorar algo no guardião
		main.g_up.couraca = int((cur.n - 1) / 2)
		for k in D.CLASSES[cur.g][0].skills.slice(0, cur.n - 1):
			main.g_skl[k] = 2
		main.phase = "wave"
		var h = main.Hero.new()
		h.type = cur.l
		h.hp = 1.0
		h.max = 1.0
		main.arena.start(h)
		cur.t = 0.0
	bot()
	main.step(1.0 / 60.0)
	cur.t += 1.0 / 60.0
	if cur.t > 90:
		main.phase = "timeout"
	return false
