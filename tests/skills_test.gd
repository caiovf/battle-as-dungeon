extends SceneTree
## Usa as habilidades alternativas e as supremas de todas as classes, procurando erros.
const D = preload("res://scripts/data.gd")
var main
var frame = 0
var queue = []
var cur = {}
var tt = 0.0


func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	for g in ["minotauro", "lich", "dragao"]:
		for c in 4:
			for o in 3:
				queue.append([g, c, o])


func _process(_d: float) -> bool:
	frame += 1
	if frame < 3:
		return false
	if cur.is_empty() or tt > 6.0 or main.phase != "arena":
		if queue.is_empty():
			print("OK skills")
			return true
		var q = queue.pop_front()
		cur = {"g": q[0], "c": q[1], "opt": q[2]}
		main.arena.stop()
		main.fresh_state()
		main.set_path(main.gen_path())
		main.guardian = q[0]
		main.g_cls = q[1]
		var ck = "%s_%d" % [q[0], q[1]]
		for s in 4:
			var pool = main.slot_pool(q[0], q[1], s)
			for x in pool:
				if not main.meta.sku.has(ck + ":" + x):
					main.meta.sku.append(ck + ":" + x)
			main.equip(q[0], q[1], s, pool[q[2]])
		# todos os talentos e upgrades básicos, para testar os efeitos
		main.meta.tp[ck] = 99
		for t in main.tal_tree(ck):
			main.tal_buy(ck, t.id)
		main.meta.gp[q[0]] = 999
		for u in D.BASIC_UPS:
			for i in u.max:
				main.gup_buy(q[0], u.id)
		main.clock = 500.0
		main.phase = "wave"
		var h = main.Hero.new()
		h.type = "garrick"
		h.hp = 100.0
		h.max = 100.0
		main.arena.start(h)
		main.arena.intro = 0.0
		tt = 0.0
		print("testando ", ck, " opção ", q[2], " ", main.loadout(q[0], q[1]), " talentos ", main.tal_owned(ck).size())
	for a in ["g_s0", "g_s1", "g_s2", "g_ult", "g_atk"]:
		Input.action_release(a)
	var k = int(tt * 60) % 40
	if k == 1:
		main.arena.P.cd = [0.0, 0.0, 0.0]
		Input.action_press(["g_s0", "g_s1", "g_s2"][int(tt) % 3])
	if k == 20:
		main.arena.P.ult = 100.0
		Input.action_press("g_ult")
	if k > 25:
		Input.action_press("g_atk")
	main.arena.B.hp = maxf(main.arena.B.hp, main.arena.B.max * 0.6)
	main.step(1.0 / 60.0)
	tt += 1.0 / 60.0
	return false
