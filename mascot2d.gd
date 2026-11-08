class_name Mascot2D
extends Control
# "Voly" the volleyball mascot (2D, animated). Developer: Sano

var t := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(300, 320)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var s := minf(w / 300.0, h / 320.0)
	var bounce := absf(sin(t * 3.0)) * 16.0 * s
	var c := Vector2(w * 0.5, h * 0.52 - bounce)
	var r := 92.0 * s
	# shadow
	draw_set_transform(Vector2(w * 0.5, h * 0.93), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, r * (0.9 - bounce / (400.0 * s)), Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# legs + shoes
	var step := sin(t * 6.0) * 6.0 * s
	for sd in [-1.0, 1.0]:
		var lx := c.x + float(sd) * r * 0.38
		draw_line(Vector2(lx, c.y + r * 0.85), Vector2(lx, c.y + r * 1.25 + step * float(sd)), Color.html("#f2c6a0"), 12.0 * s)
		draw_circle(Vector2(lx + float(sd) * 6.0 * s, c.y + r * 1.3 + step * float(sd)), 17.0 * s, Color.html("#e8452f"))
	# arms (right arm waves)
	var wave := sin(t * 7.0) * 0.4
	draw_line(c + Vector2(-r * 0.95, r * 0.1), c + Vector2(-r * 1.3, r * 0.55), Color.html("#f2c6a0"), 13.0 * s)
	draw_circle(c + Vector2(-r * 1.32, r * 0.58), 14.0 * s, Color.WHITE)
	var hand := c + Vector2(r * 0.95, -r * 0.1) + Vector2(cos(-1.1 + wave), sin(-1.1 + wave)) * r * 0.75
	draw_line(c + Vector2(r * 0.95, r * 0.0), hand, Color.html("#f2c6a0"), 13.0 * s)
	draw_circle(hand, 14.0 * s, Color.WHITE)
	# body (ball)
	draw_circle(c, r + 4.0 * s, Color(0.1, 0.15, 0.35))
	draw_circle(c, r, Color.html("#fbfbff"))
	var blue := Color.html("#2f7bff")
	var yel := Color.html("#ffc43a")
	var lw := 7.0 * s
	draw_arc(c + Vector2(-r * 0.9, -r * 0.4), r * 1.15, -0.2, 1.3, 24, blue, lw)
	draw_arc(c + Vector2(r * 0.9, r * 0.35), r * 1.15, 2.9, 4.4, 24, yel, lw)
	draw_arc(c + Vector2(0, r * 1.15), r * 0.95, 3.6, 5.8, 24, blue, lw)
	# headband
	draw_rect(Rect2(c.x - r * 0.86, c.y - r * 0.5, r * 1.72, 14.0 * s), Color.html("#e8452f"))
	# face
	var blink := 1.0 if fmod(t, 3.2) > 0.15 else 0.1
	for sd2 in [-1.0, 1.0]:
		var ex := c.x + float(sd2) * r * 0.32
		draw_set_transform(Vector2(ex, c.y - r * 0.05), 0.0, Vector2(1.0, blink))
		draw_circle(Vector2.ZERO, 15.0 * s, Color(0.08, 0.08, 0.14))
		draw_circle(Vector2(-4.0 * s, -5.0 * s), 5.0 * s, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(Vector2(c.x + float(sd2) * r * 0.58, c.y + r * 0.22), 11.0 * s, Color(1.0, 0.55, 0.6, 0.55))
	draw_arc(c + Vector2(0, r * 0.18), r * 0.3, 0.25, PI - 0.25, 16, Color(0.55, 0.12, 0.15), 5.0 * s)
