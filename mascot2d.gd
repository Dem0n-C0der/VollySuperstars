class_name Mascot2D
extends Control
# "Voly" the volleyball mascot. Layered art + spring animation. Developer: Sano

var t := 0.0
var tb: Texture2D
var ta: Texture2D
var tl: Texture2D
var tk: Texture2D
var ar := 0.0
var al := 0.0
var jt := -1.0
var nj := 3.0

func _ld(p: String) -> Texture2D:
	if ResourceLoader.exists(p):
		return load(p)
	return null

func _ready() -> void:
	custom_minimum_size = Vector2(320, 380)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tb = _ld("res://mascot/body.png")
	ta = _ld("res://mascot/arm.png")
	tl = _ld("res://mascot/leg.png")
	tk = _ld("res://mascot/blink.png")

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		jt = 0.0
		G.sfx("click")

func _process(delta: float) -> void:
	t += delta
	nj -= delta
	if nj <= 0.0:
		jt = 0.0
		nj = randf_range(3.5, 6.0)
	if jt >= 0.0:
		jt += delta
		if jt > 0.8:
			jt = -1.0
	var ta_r := -(2.15 + sin(t * 7.0) * 0.35)
	var ta_l := 0.45 + sin(t * 2.2) * 0.12
	if jt >= 0.0:
		ta_r = -2.9
		ta_l = 2.9
	ar += (ta_r - ar) * (1.0 - exp(-11.0 * delta))
	al += (ta_l - al) * (1.0 - exp(-11.0 * delta))
	queue_redraw()

func _draw() -> void:
	if tb == null:
		return
	var w := size.x
	var h := size.y
	var sc := minf(w / 320.0, h / 380.0)
	var hop := 0.0
	var sx := 1.0
	var sy := 1.0
	if jt >= 0.0:
		var u := jt / 0.8
		hop = 4.0 * 70.0 * u * (1.0 - u) * sc
		sy = 1.0 + 0.1 * sin(u * PI * 2.0)
		sx = 1.0 - 0.07 * sin(u * PI * 2.0)
	else:
		hop = absf(sin(t * 2.6)) * 8.0 * sc
		sy = 1.0 + 0.035 * sin(t * 5.2)
		sx = 1.0 - 0.025 * sin(t * 5.2)
	var c := Vector2(w * 0.5, h * 0.46 - hop)
	var s := 0.5 * sc
	var rot := sin(t * 1.7) * 0.05
	# shadow
	draw_set_transform(Vector2(w * 0.5, h * 0.93), 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, 105.0 * sc * (1.0 - hop / (500.0 * sc)), Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# legs
	for sd in [-1.0, 1.0]:
		var swing := sin(t * 5.2 + (0.0 if sd < 0.0 else PI)) * 0.2
		if jt >= 0.0:
			swing = 0.35 * float(sd)
		draw_set_transform(c + Vector2(float(sd) * 48.0 * sc, 118.0 * sc), swing, Vector2(s, s))
		draw_texture(tl, Vector2(-75.0, -10.0))
	# arms
	draw_set_transform(c + Vector2(128.0 * sc * sx, 8.0 * sc), ar, Vector2(s, s))
	draw_texture(ta, Vector2(-110.0, -60.0))
	draw_set_transform(c + Vector2(-128.0 * sc * sx, 8.0 * sc), al, Vector2(-s, s))
	draw_texture(ta, Vector2(-110.0, -60.0))
	# body
	draw_set_transform(c, rot, Vector2(s * sx, s * sy))
	draw_texture(tb, Vector2(-320.0, -340.0))
	if fmod(t, 3.4) < 0.13 and tk != null:
		draw_texture(tk, Vector2(-320.0, -340.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
