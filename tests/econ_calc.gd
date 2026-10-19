extends SceneTree
## Pontos de classe do guardião: ganha do lendário 1 ao 12, gasta tudo no Lich,
## devolve e gasta tudo no Necromante. Confere que a conta fecha.
const D = preload("res://scripts/data.gd")
var main
var frame = 0


func spend_all(g: String, ci: int) -> void:
	var ck = "%s_%d" % [g, ci]
	for t in main.tal_tree(ck):
		main.tal_buy(ck, t.id)
	for s in 4:
		for k in main.slot_pool(g, ci, s):
			main.skill_unlock(g, ci, s, k)
			main.equip(g, ci, s, k)
			main.skill_upgrade(g, ci, k)
			main.skill_upgrade(g, ci, k)


func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _process(_d: float) -> bool:
	frame += 1
	if frame < 3:
		return false
	var bak = main.meta.duplicate(true)
	for key in ["fw", "sku"]:
		main.meta[key] = []
	for key in ["tp", "gp", "tal", "spent", "skp", "load", "gup"]:
		main.meta[key] = {}
	for n in range(1, 13):
		main.leg_points("lich", n, true)
	for n in range(1, 8):
		main.leg_points("lich", n, true)   # repetidas não dão nada
	print("pontos de classe do lich: ", main.tal_points("lich"), "  de guardião: ", main.gp_points("lich"))
	spend_all("lich", 0)
	print("depois de gastar tudo no Lich: livres ", main.tal_points("lich"), "  gastos no lich_0 ", main.class_spent("lich_0"), "  talentos ", main.tal_owned("lich_0").size(), "  upgrades ", main.meta.skp.size())
	main.class_refund("lich_0")
	print("devolvido: livres ", main.tal_points("lich"), "  gastos no lich_0 ", main.class_spent("lich_0"), "  loadout ", main.loadout("lich", 0))
	spend_all("lich", 1)
	print("gasto no Necromante: livres ", main.tal_points("necromante_x".replace("necromante_x", "lich")), "  gastos no lich_1 ", main.class_spent("lich_1"))
	main.meta = bak
	main.save_meta()
	print("OK econ")
	return true
