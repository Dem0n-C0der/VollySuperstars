class_name CardView
extends Control

signal pressed

var p: Dictionary = {}
var selected := false
var press_pos := Vector2.ZERO

func setup(player: Dictionary, sz := Vector2(150, 210)) -> CardView:
	p = player
	custom_minimum_size = sz
	size = sz
	mouse_filter = Control.MOUSE_FILTER_PASS
	queue_redraw()
	return self

func set_selected(v: bool) -> void:
	selected = v
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			press_pos = e.position
		elif e.position.distance_to(press_pos) < 24.0:
			pressed.emit()

func _draw() -> void:
	if p.is_empty():
		return
	var w := size.x
	var h := size.y
	var font := ThemeDB.fallback_font
	var col: Color = G.RAR_COL[p["rar"]]
	var sb := StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.6)
	sb.border_color = Color.WHITE if selected else col.lightened(0.15)
	sb.set_border_width_all(6 if selected else 3)
	sb.set_corner_radius_all(int(w * 0.08))
	sb.draw(get_canvas_item(), Rect2(0, 0, w, h))
	# glow band
	draw_rect(Rect2(w * 0.06, h * 0.05, w * 0.88, h * 0.5), col.darkened(0.25))
	# face
	var c := Vector2(w * 0.58, h * 0.33)
	var r := w * 0.2
	var skin: Color = G.SKIN[int(p["sk"])]
	var hair: Color = G.HAIR[int(p["hc"])]
	var hs := int(p["hs"])
	# shoulders
	draw_circle(c + Vector2(0, r * 2.1), r * 1.5, col.lightened(0.1))
	if hs == 2:
		draw_rect(Rect2(c.x - r * 1.1, c.y - r * 0.6, r * 2.2, r * 2.3), hair)
	draw_circle(c + Vector2(0, -r * 0.25), r * 1.08, hair)
	if hs == 1:
		for k in 5:
			var bx := c.x - r + float(k) * r * 0.5
			draw_colored_polygon(PackedVector2Array([Vector2(bx - r * 0.25, c.y - r * 0.8), Vector2(bx, c.y - r * 1.75), Vector2(bx + r * 0.25, c.y - r * 0.8)]), hair)
	draw_circle(c, r, skin)
	if hs == 3:
		draw_rect(Rect2(c.x - r * 1.05, c.y - r * 0.95, r * 2.1, r * 0.45), col.lightened(0.3))
	draw_circle(c + Vector2(-r * 0.38, r * 0.05), r * 0.11, Color(0.1, 0.1, 0.15))
	draw_circle(c + Vector2(r * 0.38, r * 0.05), r * 0.11, Color(0.1, 0.1, 0.15))
	draw_arc(c + Vector2(0, r * 0.35), r * 0.3, 0.2, PI - 0.2, 10, Color(0.45, 0.15, 0.15), 2.0)
	# ovr / pos
	var ov := G.ovr(p)
	draw_string(font, Vector2(w * 0.07, h * 0.2), str(ov), HORIZONTAL_ALIGNMENT_LEFT, -1, int(h * 0.17), Color.WHITE)
	draw_string(font, Vector2(w * 0.08, h * 0.31), String(p["pos"]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(h * 0.075), col.lightened(0.5))
	var lvl := G.lv(int(p["id"]))
	if lvl > 0:
		draw_string(font, Vector2(w * 0.08, h * 0.41), "+%d" % lvl, HORIZONTAL_ALIGNMENT_LEFT, -1, int(h * 0.07), Color.html("#7dff9a"))
	# rarity tag
	draw_string(font, Vector2(w * 0.08, h * 0.5), String(p["rar"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, w * 0.84, int(h * 0.045), col.lightened(0.6))
	# name
	var fs := int(maxf(9.0, h * 0.065))
	draw_string(font, Vector2(4, h * 0.6), String(p["name"]), HORIZONTAL_ALIGNMENT_CENTER, w - 8, fs, Color.WHITE)
	# stats
	var sfs := int(maxf(9.0, h * 0.062))
	for i in 5:
		var col_i := i % 3
		var row_i := int(i / 3)
		var x := w * 0.06 + float(col_i) * w * 0.31
		var y := h * 0.72 + float(row_i) * h * 0.13
		draw_string(font, Vector2(x, y), "%s %d" % [G.KEY_NAMES[i], G.stat(p, G.KEYS[i])], HORIZONTAL_ALIGNMENT_LEFT, w * 0.32, sfs, Color(1, 1, 1, 0.92))
