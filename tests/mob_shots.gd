extends SceneTree
var main
var frame := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func snap(n):
	root.get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
func _process(_d: float) -> bool:
	frame += 1
	match frame:
		10:
			main.begin()
			main.clock = 300
		40:
			main.kl["espinhos"] = 2
			main.guardian = "lich"
			main.duel["perto"] = 2
			main.ui.render_know()
			main.ui.layout()
		80: snap("m1_mapa")
		82: main.ui.set_tab("mon")
		84: main.ui.show_settings()
		88: snap("m1b_config")
		89: main.ui.close_settings()
		90: snap("m2_monstros")
		92:
			var h = main.Hero.new()
			h.type = "kael"
			h.hp = 100
			h.max = 100
			main.arena.start(h)
		150: snap("m3_arena")
		152: pass
		170: snap("m4_retrato")
		172: return true
	return false
