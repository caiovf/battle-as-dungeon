extends SceneTree
## Simula a progressão de pontos: cada run vai um lendário mais longe (pior caso: quase sem repetições)
## e confere se, ao chegar no 13º, a classe e o guardião já compram tudo.
const D = preload("res://scripts/data.gd")
var main
var frame = 0


func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _process(_d: float) -> bool:
	frame += 1
	if frame < 3:
		return false
	var cls_cost = 0
	for n in D.TALENT_TREES["minotauro_0"].nodes:
		cls_cost += int(n.cost)
	for s in 4:
		cls_cost += D.CLASS_ALTS["minotauro_0"][s].size() * (D.ULT_UNLOCK_COST if s == 3 else D.SKILL_UNLOCK_COST)
		cls_cost += (1 + D.CLASS_ALTS["minotauro_0"][s].size()) * (D.SKILL_UP_COST[0] + D.SKILL_UP_COST[1])
	var g_cost = 0
	for u in D.BASIC_UPS:
		for lv in u.max:
			g_cost += main.gup_cost(lv)
	for mode in ["direto (1 run até o 13º)", "uma run a mais por lendário"]:
		main.meta.fw = []
		main.meta.tp = {}
		main.meta.gp = {}
		var reach = 13
		var runs = [12] if mode.begins_with("direto") else range(1, 13)
		for r in runs:
			for n in range(1, r + 1):
				main.leg_points("minotauro_0", "minotauro", n, true)
		print("%s: classe %d/%d  guardião %d/%d" % [mode, int(main.meta.tp.minotauro_0), cls_cost, int(main.meta.gp.minotauro), g_cost])
	print("pontos por lendário (1ª vitória): classe ", range(1, 14).map(func(n): return n + D.CLASS_FIRST_BASE), " guardião ", range(1, 14).map(func(n): return n + D.GUARD_FIRST_BASE))
	main.meta.fw = []
	main.meta.tp = {}
	main.meta.gp = {}
	main.save_meta()
	return true
