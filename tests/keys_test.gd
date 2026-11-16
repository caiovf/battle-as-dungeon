extends SceneTree
## Troca de teclas: captura pela janela, tecla que sai da outra ação, teclas fixas e restauração.
var main
var frame = 0


func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _press(kc: int) -> void:
	var e = InputEventKey.new()
	e.physical_keycode = kc
	e.pressed = true
	main.ui._input(e)


func _has(a: String, kc: int) -> bool:
	for e in InputMap.action_get_events(a):
		if e is InputEventKey and e.physical_keycode == kc:
			return true
	return false


func _process(_d: float) -> bool:
	frame += 1
	if frame < 3:
		return false
	var ok = true
	main.ui.show_settings()
	main.ui.bind_wait = ["g_atk", 0]
	_press(KEY_W)                       # W era do pulo
	ok = ok and _has("g_atk", KEY_W) and not _has("g_jump", KEY_W) and not _has("g_atk", KEY_J)
	print("atacar no W: ", main.keys_of("g_atk"), " pular: ", main.keys_of("g_jump"))
	main.ui.bind_wait = ["g_s0", 0]
	_press(KEY_P)                       # fixa: não pode
	ok = ok and not _has("g_s0", KEY_P) and _has("g_s0", KEY_U)
	print("P recusada: ", main.ui.set_msg)
	main.ui.bind_wait = ["g_ult", 2]
	_press(KEY_R)                       # posição vazia: acrescenta
	ok = ok and _has("g_ult", KEY_R)
	main.ui.bind_wait = ["g_ult", 0]
	_press(KEY_BACKSPACE)               # tira a primeira tecla
	ok = ok and not _has("g_ult", KEY_Y)
	print("suprema: ", main.keys_of("g_ult"))
	var saved = FileAccess.get_file_as_string(main.CFG_PATH)
	ok = ok and saved.find("g_atk") >= 0
	main.reset_keys()
	ok = ok and _has("g_jump", KEY_W) and _has("g_atk", KEY_J)
	main.set_cfg("shake", 0.0)
	main.shake_t = 0.0
	main.shake(0.5, 0.01)
	ok = ok and main.shake_t == 0.0
	main.set_cfg("shake", 1.0)
	print("OK keys" if ok else "FALHOU keys")
	return true
