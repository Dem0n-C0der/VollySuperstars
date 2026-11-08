class_name MenuBG
extends Control
# Animated stadium background for menus. Developer: Sano

var t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _ball(c: Vector2, r: float) -> void:
	draw_circle(c, r, Color(1, 1, 1, 0.9))
	draw_arc(c + Vector2(-r * 0.8, -r * 0.3), r * 1.1, -0.2, 1.3, 14, Color(0.2, 0.45, 1.0, 0.9), r * 0.1)
	draw_arc(c + Vector2(r * 0.8, r * 0.3), r * 1.1, 2.9, 4.4, 14, Color(1.0, 0.77, 0.23, 0.9), r * 0.1)

func _draw() -> void:
	var w := size.x
	var h := size.y
	var c1 := Color.html("#102f78")
	var c2 := Color.html("#0b1236")
	var c3 := Color.html("#241046")
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.6), Vector2(0, h * 0.6)]), PackedColorArray([c1, c1, c2, c2]))
	draw_polygon(PackedVector2Array([Vector2(0, h * 0.6), Vector2(w, h * 0.6), Vector2(w, h), Vector2(0, h)]), PackedColorArray([c2, c2, c3, c3]))
	# stadium lights
	for i in 4:
		var lx := w * (0.12 + 0.25 * float(i))
		var pulse := 0.5 + 0.5 * sin(t * 1.2 + float(i))
		draw_circle(Vector2(lx, h * 0.05), 120.0 + 20.0 * pulse, Color(1, 0.95, 0.75, 0.05))
		draw_circle(Vector2(lx, h * 0.05), 60.0, Color(1, 0.97, 0.85, 0.12))
		draw_circle(Vector2(lx, h * 0.05), 16.0, Color(1, 1, 0.95, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(lx - 14, h * 0.05), Vector2(lx + 14, h * 0.05), Vector2(lx + 150, h * 0.62), Vector2(lx - 150, h * 0.62)]), Color(1, 0.97, 0.8, 0.035))
	# crowd silhouettes
	for row in 3:
		var y := h * (0.5 + 0.04 * float(row))
		var n := int(w / 26.0) + 2
		var col := Color(0.05 + 0.02 * float(row), 0.07 + 0.02 * float(row), 0.18 + 0.03 * float(row))
		for k in n:
			var bob := absf(sin(t * 2.0 + float(k) * 0.9 + float(row))) * 5.0
			var x := float(k) * 26.0 + float(row) * 9.0
			draw_circle(Vector2(x, y - bob), 10.0, col)
			draw_rect(Rect2(x - 10.0, y - bob + 6.0, 20.0, 34.0), col)
	# court floor with perspective lines
	var fy := h * 0.66
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.12, fy), Vector2(w * 0.88, fy), Vector2(w * 1.05, h), Vector2(-w * 0.05, h)]), Color(0.88, 0.48, 0.2, 0.55))
	var lc := Color(1, 1, 1, 0.55)
	draw_line(Vector2(w * 0.12, fy), Vector2(w * 0.88, fy), lc, 3.0)
	draw_line(Vector2(w * 0.5, fy), Vector2(w * 0.5, h), lc, 3.0)
	draw_line(Vector2(w * 0.12, fy), Vector2(-w * 0.05, h), lc, 3.0)
	draw_line(Vector2(w * 0.88, fy), Vector2(w * 1.05, h), lc, 3.0)
	draw_line(Vector2(w * 0.28, fy), Vector2(w * 0.2, h), Color(1, 1, 1, 0.25), 2.0)
	draw_line(Vector2(w * 0.72, fy), Vector2(w * 0.8, h), Color(1, 1, 1, 0.25), 2.0)
	# net
	draw_line(Vector2(w * 0.12, fy - 70.0), Vector2(w * 0.88, fy - 70.0), Color(1, 1, 1, 0.5), 4.0)
	for i in 28:
		var nx := w * (0.12 + 0.76 * float(i) / 27.0)
		draw_line(Vector2(nx, fy - 70.0), Vector2(nx, fy), Color(1, 1, 1, 0.12), 1.0)
	# floating balls
	for i in 7:
		var ph := t * 0.5 + float(i) * 1.7
		var bx := fmod(float(i) * w * 0.17 + sin(ph) * 40.0 + t * 12.0, w + 100.0) - 50.0
		var by := h * 0.3 + sin(ph * 1.3) * h * 0.18 + float(i % 3) * 30.0
		_ball(Vector2(bx, by), 14.0 + float(i % 3) * 6.0)
	# sparkles
	for i in 26:
		var sx := fmod(float(i) * 137.5, w)
		var sy := fmod(float(i) * 83.3 + t * 18.0, h)
		var a := 0.15 + 0.35 * absf(sin(t * 1.5 + float(i)))
		draw_circle(Vector2(sx, sy), 2.0, Color(1, 0.9, 0.5, a))
