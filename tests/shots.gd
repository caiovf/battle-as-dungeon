extends SceneTree
## Tira capturas de tela de cada modo (precisa de janela; rode com xvfb no servidor).

var main
var frame := 0
var out := "/tmp/shots"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func snap(n: String) -> void:
	var img = root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, n])
	print("shot ", n, " ", img.get_size())


func _process(_d: float) -> bool:
	frame += 1
	match frame:
		10: snap("01_intro")
		12:
			main.begin()
			main.clock = 300
			for k in ["fogo", "ampulheta", "ogro", "ganancia"]:
				main.unlocked[k] = true
			main.ui.build_bench()
		14:
			for i in [4, 8, 12, 16]:
				var p = main.route[i]
				main.tool = "espinhos"
				main.board_click(Vector2(p.x * 40 + 5, p.y * 40 + 5))
			for i in [6, 10]:
				var p = main.route[i]
				for dd in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0)]:
					if main.can_place("besta", p.x + dd.x, p.y + dd.y):
						main.tool = "besta"
						main.board_click(Vector2((p.x + dd.x) * 40 + 5, (p.y + dd.y) * 40 + 5))
						break
			main.summon("esqueleto")
			main.kl["espinhos"] = 2
			main.kl["besta"] = 3
		60: snap("01b_contagem")
		200: snap("02_mapa")
		202:
			main.ui.set_tab("mon")
		204: snap("03_monstros")
		206:
			main.ui.set_tab("traps")
			main.ui.show_grim()
		210: snap("04_grimorio")
		212:
			main.ui.close_grim()
			main.legend_next = "lyra"
			main.ui.show_guard_pick()
		216: snap("05_guardiao")
		218:
			main.ui.overlay.visible = false
			main.guardian = "dragao"
			main.fame = 22
			main.evo = 18
			main.g_skl = {"baforada": 2}
			var h = main.Hero.new()
			h.type = "lyra"
			h.hp = 70
			h.max = 100
			main.arena.start(h)
		340:
			var e = InputEventScreenTouch.new()
			e.index = 0
			e.position = Vector2(200, 600)
			e.pressed = true
			Input.parse_input_event(e)
		342:
			var d = InputEventScreenDrag.new()
			d.index = 0
			d.position = Vector2(262, 590)
			Input.parse_input_event(d)
		360:
			var b = main.ui.pad.buttons[3]
			var e2 = InputEventScreenTouch.new()
			e2.index = 1
			e2.position = b.pos * (Vector2(DisplayServer.window_get_size()) / main.ui.root.get_viewport_rect().size)
			e2.pressed = true
			Input.parse_input_event(e2)
		366:
			var b = main.ui.pad.buttons[3]
			var e3 = InputEventScreenTouch.new()
			e3.index = 1
			e3.position = b.pos * (Vector2(DisplayServer.window_get_size()) / main.ui.root.get_viewport_rect().size)
			e3.pressed = false
			Input.parse_input_event(e3)
		370: snap("06_arena")
		372:
			print("pos guardião depois do analógico: ", main.arena.P.x, " cd s0: ", main.arena.P.cd[0])
			var e4 = InputEventScreenTouch.new()
			e4.index = 0
			e4.position = Vector2(262, 590)
			e4.pressed = false
			Input.parse_input_event(e4)
			main.arena.B.hp = 1
			main.arena.hurt_boss(50, "perto")
		480: snap("07_recompensa")
		482:
			main.ui.ov_cards.get_child(0).pressed.emit()
		486:
			main.duel = {"dash": 2, "pulo": 1, "perto": 3, "longe": 0, "especial": 1}
			main.kl["espinhos"] = 2
			main.evo = 70
			main.meta.cls = ["dragao_1", "dragao_3"]
			main.meta.miss = {"dragao_1": 120, "dragao_3": 0}
			main.ui.render_know()
		494: snap("08_volta_ao_mapa")
		496:
			main.ui.show_classes()
		500: snap("09_classes")
		501:
			main.meta.tp["dragao_0"] = 7
			main.meta.tal["dragao_0"] = ["a1", "b1"]
			main.ui.tal_cls = 0
			main.ui.render_classes()
		504: snap("09b_talentos")
		505:
			main.ui.tal_cls = -1
			main.meta.tp["dragao_0"] = 12
			main.ui.sk_cls = 0
			main.ui.render_classes()
		507: snap("09c_habilidades")
		508:
			main.ui.sk_cls = -1
			main.meta.gp["dragao"] = 9
			main.ui.gup_open = true
			main.ui.render_classes()
		510: snap("09d_upgrades")
		511:
			main.ui.close_classes()
			_fight("minotauro", 1, "kael")
		540: Input.action_press("g_atk")
		590:
			main.arena.P.ult = 100.0
			Input.action_press("g_ult")
		592: Input.action_release("g_ult")
		600: snap("10_berserker_kael")
		602:
			Input.action_release("g_atk")
			_fight("lich", 3, "nyx")
		640: Input.action_press("g_atk")
		700: snap("11_arauto_nyx")
		702:
			Input.action_release("g_atk")
			_fight("dragao", 3, "ragnar")
		740: Input.action_press("g_atk")
		800: snap("12_anciao_ragnar")
		802:
			Input.action_release("g_atk")
			_fight("minotauro", 2, "thorne")
		840: Input.action_press("g_s2")
		842: Input.action_release("g_s2")
		900: snap("13_pedra_thorne")
		902:
			main.arena.stop()
			main.game_over()
		906: snap("14_fim")
		908: return true
	return false


func _fight(g: String, c: int, l: String) -> void:
	main.arena.stop()
	main.ui.overlay.visible = false
	main.phase = "wave"
	main.guardian = g
	main.g_cls = c
	main.clock = 80
	var h = main.Hero.new()
	h.type = l
	h.hp = 100
	h.max = 100
	main.arena.start(h)
