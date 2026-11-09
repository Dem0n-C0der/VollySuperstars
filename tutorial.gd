class_name Tutorial
extends Control
# Standalone interactive tutorial (20 steps, every step needs a touch). Developer: Sano

signal finished

const STEPS := [
	{"k": "info", "t": "Welcome!", "d": "Welcome to Volly Superstars! This short tutorial teaches you everything. Every step needs a touch."},
	{"k": "info", "t": "Coins", "d": "Win matches to earn coins. Use coins to buy players and open card packs."},
	{"k": "btn", "t": "Main Menu: Team", "d": "Touch TEAM to manage your players.", "b": "Team", "c": "#2b6cff", "i": "team"},
	{"k": "card", "t": "Your Lineup", "d": "These are your starting players. Touch one to select it."},
	{"k": "card", "t": "Substitutes", "d": "Now touch a substitute to swap them into the lineup."},
	{"k": "btn", "t": "Auto Lineup", "d": "Touch AUTO LINEUP to let the game pick your best six players.", "b": "Auto Lineup", "c": "#27a85a", "i": ""},
	{"k": "btn", "t": "Back", "d": "Touch BACK to return to the main menu.", "b": "Back", "c": "#4a5a8a", "i": "back"},
	{"k": "btn", "t": "Transfer", "d": "Touch TRANSFER to buy and sell players.", "b": "Transfer", "c": "#e8872f", "i": "transfer"},
	{"k": "btn", "t": "Buy", "d": "Touch BUY to see players you can sign.", "b": "BUY", "c": "#27a85a", "i": ""},
	{"k": "btn", "t": "Available", "d": "AVAILABLE lists cheap players. The list changes after every match.", "b": "Available", "c": "#2b6cff", "i": ""},
	{"k": "btn", "t": "Shop", "d": "Touch SHOP to open card packs.", "b": "Shop", "c": "#9a4bd6", "i": "shop"},
	{"k": "btn", "t": "Story Mode", "d": "Touch STORY MODE to play levels 1 to 100.", "b": "Story Mode", "c": "#2b8cff", "i": "story"},
	{"k": "btn", "t": "Level 1", "d": "Touch LEVEL 1 to start your first match.", "b": "1", "c": "#2b6cff", "i": ""},
	{"k": "court", "t": "Serve", "d": "Touch anywhere on the OPPONENT's court (the glowing left side) to serve the ball there.", "side": "enemy"},
	{"k": "timing", "t": "Pass", "d": "The ball is coming! Touch PASS when the marker is inside the green zone.", "b": "PASS", "c": "#2b8cff"},
	{"k": "timing", "t": "Set", "d": "Touch SET in the green zone to set the ball for your hitter.", "b": "SET", "c": "#27a85a"},
	{"k": "court", "t": "Choose the hitter", "d": "Touch anywhere on YOUR court (the glowing right side) to choose who gets the set.", "side": "own"},
	{"k": "timing", "t": "Spike", "d": "Touch SPIKE in the green zone to jump and smash the ball!", "b": "SPIKE", "c": "#e8452f"},
	{"k": "court", "t": "Aim your smash", "d": "Touch anywhere on the OPPONENT's court (left side) to aim your smash.", "side": "enemy"},
	{"k": "info", "t": "You are ready!", "d": "Tutorial complete! You get 1000 coins. Good luck, coach!"},
]

class MockCourt extends Control:
	signal tapped(side: String)
	var target := "enemy"
	var t := 0.0
	var rp := Vector2(-1, -1)
	var rt := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(760, 300)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(d: float) -> void:
		t += d
		rt = maxf(0.0, rt - d)
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			rp = e.position
			rt = 0.5
			tapped.emit("enemy" if e.position.x < size.x * 0.5 else "own")

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color.html("#173d66"))
		draw_rect(Rect2(w * 0.04, h * 0.06, w * 0.46, h * 0.88), Color.html("#d9783a"))
		draw_rect(Rect2(w * 0.5, h * 0.06, w * 0.46, h * 0.88), Color.html("#c9622d"))
		draw_rect(Rect2(w * 0.04, h * 0.06, w * 0.92, h * 0.88), Color.WHITE, false, 4.0)
		draw_line(Vector2(w * 0.5, h * 0.0), Vector2(w * 0.5, h), Color.WHITE, 8.0)
		var pulse := 0.5 + 0.5 * sin(t * 6.0)
		var gx := w * 0.04 if target == "enemy" else w * 0.5
		draw_rect(Rect2(gx, h * 0.06, w * 0.46, h * 0.88), Color(1, 0.9, 0.2, 0.18 + 0.18 * pulse))
		draw_rect(Rect2(gx, h * 0.06, w * 0.46, h * 0.88), Color(1, 0.9, 0.2, 1.0), false, 4.0 + 3.0 * pulse)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(w * 0.04, h * 0.5), "OPPONENT", HORIZONTAL_ALIGNMENT_CENTER, w * 0.46, 34, Color(1, 1, 1, 0.8))
		draw_string(font, Vector2(w * 0.5, h * 0.5), "YOU", HORIZONTAL_ALIGNMENT_CENTER, w * 0.46, 34, Color(1, 1, 1, 0.8))
		for i in 6:
			var px := w * (0.12 + 0.12 * float(i % 3)) if i < 3 else w * (0.62 + 0.12 * float(i % 3))
			var py := h * (0.25 if i % 2 == 0 else 0.75)
			draw_circle(Vector2(px, py), 14.0, Color(0.9, 0.3, 0.25) if i < 3 else Color(0.2, 0.5, 1.0))
		if rt > 0.0:
			draw_arc(rp, 70.0 * (1.0 - rt / 0.5) + 10.0, 0.0, TAU, 32, Color(1, 1, 1, rt / 0.5), 5.0)

class MockTiming extends Control:
	var t := 0.0
	var frac := 0.0
	var zlo := 0.56
	var zhi := 0.86

	func _ready() -> void:
		custom_minimum_size = Vector2(560, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(d: float) -> void:
		t += d
		frac = fposmod(t * 0.55, 1.0)
		queue_redraw()

	func in_zone() -> bool:
		return frac >= zlo and frac <= zhi

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.6)
		bg.set_corner_radius_all(int(h * 0.5))
		bg.border_color = Color(1, 1, 1, 0.4)
		bg.set_border_width_all(2)
		bg.draw(get_canvas_item(), Rect2(0, 0, w, h))
		var z := StyleBoxFlat.new()
		z.bg_color = Color(0.2, 0.9, 0.4, 0.9)
		z.set_corner_radius_all(int(h * 0.5))
		z.draw(get_canvas_item(), Rect2(w * zlo, 4, w * (zhi - zlo), h - 8))
		var x := w * frac
		draw_rect(Rect2(x - 6, -8, 12, h + 16), Color.WHITE)

var step := 0
var count_l: Label
var prog: ProgressBar
var title_l: Label
var desc_l: Label
var body: VBoxContainer
var msg_l: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 28)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	count_l = G.mk_label("", 26, Color.html("#ffc43a"))
	v.add_child(count_l)
	prog = ProgressBar.new()
	prog.max_value = float(STEPS.size())
	prog.show_percentage = false
	prog.custom_minimum_size = Vector2(0, 18)
	v.add_child(prog)
	var pan := G.mk_panel(Color(0.06, 0.1, 0.24, 0.92), 20)
	v.add_child(pan)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pan.add_child(pv)
	title_l = G.mk_label("", 40, Color.WHITE)
	pv.add_child(title_l)
	desc_l = G.mk_label("", 26, Color(1, 1, 1, 0.92))
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_l.custom_minimum_size = Vector2(900, 0)
	pv.add_child(desc_l)
	var cc := CenterContainer.new()
	cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cc)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(body)
	msg_l = G.mk_label("", 26, Color.html("#ff8a6a"))
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(msg_l)
	_show_step()

func _pulse(c: Control) -> void:
	var tw := c.create_tween()
	tw.set_loops()
	tw.tween_property(c, "modulate", Color(1.3, 1.3, 1.3), 0.5)
	tw.tween_property(c, "modulate", Color.WHITE, 0.5)

func _show_step() -> void:
	for c in body.get_children():
		c.queue_free()
	var s: Dictionary = STEPS[step]
	count_l.text = "Tutorial  %d / %d" % [step + 1, STEPS.size()]
	prog.value = float(step)
	title_l.text = String(s["t"])
	desc_l.text = String(s["d"])
	msg_l.text = ""
	var k: String = s["k"]
	if k == "info":
		var last := step == STEPS.size() - 1
		var b := G.mk_btn("START PLAYING" if last else "NEXT", Color.html("#27a85a"), Vector2(360, 100), "", 36)
		b.pressed.connect(_next)
		body.add_child(b)
		_pulse(b)
	elif k == "btn":
		var ic := String(s["i"])
		var b2 := G.mk_btn(String(s["b"]), Color.html(String(s["c"])), Vector2(380, 110), ic, 38)
		b2.pressed.connect(_next)
		body.add_child(b2)
		_pulse(b2)
		body.add_child(G.mk_label("Touch the glowing button", 22, Color(1, 1, 1, 0.7)))
	elif k == "card":
		var ids: Array = G.save["lineup"].slice(0, 3)
		if step != 3:
			var bn: Array = G.bench_ids()
			ids = (bn if not bn.is_empty() else G.save["lineup"]).slice(0, 3)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		body.add_child(row)
		for id in ids:
			var cv := CardView.new().setup(G.players[int(id)], Vector2(170, 238))
			cv.pressed.connect(_next)
			row.add_child(cv)
			_pulse(cv)
		body.add_child(G.mk_label("Touch a glowing card", 22, Color(1, 1, 1, 0.7)))
	elif k == "court":
		var mc := MockCourt.new()
		mc.target = String(s["side"])
		mc.tapped.connect(_on_court.bind(String(s["side"])))
		body.add_child(mc)
	elif k == "timing":
		var mt := MockTiming.new()
		body.add_child(mt)
		var b3 := G.mk_btn(String(s["b"]), Color.html(String(s["c"])), Vector2(300, 100), "", 38)
		b3.pressed.connect(_on_timing.bind(mt))
		body.add_child(b3)

func _on_court(side: String, want: String) -> void:
	if side == want:
		G.sfx("hit")
		msg_l.text = "Great!"
		get_tree().create_timer(0.35).timeout.connect(_next)
	else:
		msg_l.text = "Touch the glowing half!"

func _on_timing(mt: MockTiming) -> void:
	if mt.in_zone():
		G.sfx("pass")
		msg_l.text = "PERFECT!"
		get_tree().create_timer(0.3).timeout.connect(_next)
	elif mt.frac < mt.zlo:
		msg_l.text = "Too early! Wait for the green zone."
	else:
		msg_l.text = "Too late! Try again."

func _next() -> void:
	if not is_inside_tree():
		return
	step += 1
	if step >= STEPS.size():
		G.save["tut"] = true
		G.add_coins(1000)
		G.sfx("coin")
		finished.emit()
	else:
		_show_step()
