class_name TimingBar
extends Control

var active := false
var frac := 0.0
var zlo := 0.5
var zhi := 1.0

func _process(_d: float) -> void:
	if active or visible:
		queue_redraw()

func _draw() -> void:
	if not active:
		return
	var w := size.x
	var h := size.y
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(int(h * 0.5))
	bg.border_color = Color(1, 1, 1, 0.35)
	bg.set_border_width_all(2)
	bg.draw(get_canvas_item(), Rect2(0, 0, w, h))
	var zone := StyleBoxFlat.new()
	zone.bg_color = Color(0.2, 0.9, 0.4, 0.9)
	zone.set_corner_radius_all(int(h * 0.5))
	zone.draw(get_canvas_item(), Rect2(w * zlo, 3, w * (zhi - zlo), h - 6))
	var x := w * clampf(frac, 0.0, 1.0)
	draw_rect(Rect2(x - 5, -7, 10, h + 14), Color.WHITE)
	draw_rect(Rect2(x - 5, -7, 10, h + 14), Color(0, 0, 0, 0.5), false, 2.0)
