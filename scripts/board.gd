extends Node2D

const Art = preload("res://scripts/art.gd")
## Desenha o mapa (ou a arena) em coordenadas 720×480 e repassa os toques para o jogo.

var game
var shake_off := Vector2.ZERO


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_set_transform(shake_off)
	Art.off = shake_off
	draw_rect(Rect2(0, 0, 720, 480), Color("#14110f"))
	game.draw_board(self)
	draw_set_transform(Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if game == null or not is_visible_in_tree():
		return
	if event is InputEventMouseMotion:
		var p: Vector2 = make_input_local(event).position
		game.hover = Vector2i(int(floor(p.x / 40.0)), int(floor(p.y / 40.0)))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = make_input_local(event).position
		if p.x >= 0 and p.y >= 0 and p.x < 720 and p.y < 480:
			game.hover = Vector2i(int(floor(p.x / 40.0)), int(floor(p.y / 40.0)))
			game.board_click(p)
			get_viewport().set_input_as_handled()
