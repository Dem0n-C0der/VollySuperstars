class_name TapArea
extends Control

signal pressed
signal tapped(pos: Vector2)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var gp := get_global_rect().position + e.position
		tapped.emit(gp)
		pressed.emit()
