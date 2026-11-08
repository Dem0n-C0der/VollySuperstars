class_name StarBar
extends Control

var value := 5.0

func setup(v: float, h := 28.0) -> StarBar:
	value = v
	custom_minimum_size = Vector2(h * 10.0, h)
	queue_redraw()
	return self

func _star(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var rr := r if k % 2 == 0 else r * 0.45
		var a := -PI / 2.0 + float(k) * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return pts

func _draw() -> void:
	var h := size.y
	for i in 10:
		var c := Vector2(h * 0.5 + float(i) * h, h * 0.5)
		draw_colored_polygon(_star(c, h * 0.48), Color(1, 1, 1, 0.15))
		var fill := clampf(value - float(i), 0.0, 1.0)
		if fill > 0.0:
			var col := Color.html("#ffc43a")
			if fill < 1.0:
				col = col.darkened(0.35)
			draw_colored_polygon(_star(c, h * 0.48 * (0.55 + 0.45 * fill)), col)
