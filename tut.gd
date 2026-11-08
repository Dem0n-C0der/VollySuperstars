class_name Tut
extends Control

const STEPS := [
	["Welcome to Volly Superstars! Let's learn the basics. Tap anywhere to continue.", ""],
	["This is your COIN balance. Win matches to earn more coins.", "coin"],
	["This is your team profile: team name and level.", "profile"],
	["Tap TEAM to manage your players.", "btn_team"],
	["Tap a player in your lineup to select them.", "slot0"],
	["Now tap a substitute on the right to swap them in.", "bench0"],
	["Tap AUTO LINEUP to let the game pick your best players.", "autolineup"],
	["Tap BACK to return to the main menu.", "back"],
	["Tap TRANSFER to buy and sell players.", "btn_transfer"],
	["Tap BUY to see players you can sign.", "tab_buy"],
	["Tap AVAILABLE to see cheap players on the market.", "avail"],
	["Tap BACK to return.", "back"],
	["Tap SHOP to open card packs.", "btn_shop"],
	["Tap BACK to return.", "back"],
	["Tap STORY MODE to play levels 1-100.", "btn_story"],
	["Tap LEVEL 1 to start your first match.", "lvl1"],
	["Serving! Touch anywhere on the opponent's court to send the ball there.", "court"],
	["The ball is coming! Tap PASS just before it lands to receive it.", "btn_pass"],
	["Tap SET, then touch anywhere on YOUR court to choose who gets the ball.", "btn_set"],
	["Tap SPIKE at the right moment, then touch anywhere on the OPPONENT's court to aim your smash!", "btn_spike"],
]

var target = null
var hole := Rect2()
var msg := ""
var label: Label
var panel: PanelContainer
var t := 0.0
var finishing := false
var any_tap := false
var wrong := 0
var flash := 0.0
var base_msg := ""

func _ready() -> void:
	G.tut = self
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	panel = G.mk_panel(Color(0.05, 0.09, 0.22, 0.97), 18)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	label = G.mk_label("", 26)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(620, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)

func start() -> void:
	G.tut_active = true
	G.tut_i = 0
	_step()

func _step() -> void:
	if G.tut_i >= STEPS.size():
		_finish()
		return
	if G.tut_i >= 16:
		visible = false
		return
	var s: Array = STEPS[G.tut_i]
	_show(s[0], s[1])

func game_request(tname: String) -> bool:
	if not G.tut_active or G.tut_i < 16 or G.tut_i >= STEPS.size():
		return false
	var s: Array = STEPS[G.tut_i]
	if s[1] != tname:
		return false
	_show(s[0], s[1])
	return true

func _show(text: String, tname: String) -> void:
	visible = false
	var tries := 0
	if tname != "":
		while tries < 40 and (not G.targets.has(tname) or not is_instance_valid(G.targets[tname]) or not G.targets[tname].is_visible_in_tree()):
			await get_tree().create_timer(0.1).timeout
			tries += 1
	await get_tree().process_frame
	msg = text
	base_msg = text
	label.text = text
	any_tap = (tname == "court")
	wrong = 0
	target = G.targets.get(tname) if tname != "" and G.targets.has(tname) and is_instance_valid(G.targets[tname]) else null
	if target != null:
		hole = target.get_global_rect().grow(8.0)
	var vs := get_viewport_rect().size
	panel.reset_size()
	await get_tree().process_frame
	var ps := panel.size
	var y := vs.y * 0.08
	if target != null and hole.get_center().y < vs.y * 0.5:
		y = vs.y - ps.y - vs.y * 0.08
	panel.position = Vector2((vs.x - ps.x) * 0.5, y)
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if visible:
		t += delta
		flash = maxf(0.0, flash - delta)
		queue_redraw()

func _draw() -> void:
	var vs := size
	var dim := Color(0, 0, 0, 0.74)
	if target == null:
		draw_rect(Rect2(Vector2.ZERO, vs), dim)
		return
	draw_rect(Rect2(0, 0, vs.x, hole.position.y), dim)
	draw_rect(Rect2(0, hole.end.y, vs.x, vs.y - hole.end.y), dim)
	draw_rect(Rect2(0, hole.position.y, hole.position.x, hole.size.y), dim)
	draw_rect(Rect2(hole.end.x, hole.position.y, vs.x - hole.end.x, hole.size.y), dim)
	var pulse := 0.5 + 0.5 * sin(t * 6.0)
	draw_rect(hole, Color(1, 0.85, 0.2, 0.6 + 0.4 * pulse) if flash <= 0.0 else Color(1, 0.3, 0.2, 1.0), false, 4.0 + 3.0 * pulse + flash * 10.0)

func _forward(tg: Control, pos: Vector2) -> void:
	visible = false
	target = null
	if tg.has_signal("tapped"):
		tg.emit_signal("tapped", pos)
	elif tg.has_signal("pressed"):
		tg.emit_signal("pressed")
	_advance()

func _gui_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if finishing:
		visible = false
		finishing = false
		return
	if target == null:
		_advance()
		return
	var tg = target
	if any_tap:
		_forward(tg, e.position)
	elif hole.has_point(e.position):
		_forward(tg, tg.get_global_rect().get_center())
	else:
		wrong += 1
		flash = 0.5
		label.text = base_msg + "\n(Touch the glowing area)"
		if wrong >= 4:
			_forward(tg, tg.get_global_rect().get_center())

func _advance() -> void:
	G.tut_i += 1
	_step()

func _finish() -> void:
	G.tut_active = false
	G.save["tut"] = true
	G.add_coins(1000)
	G.sfx("coin")
	target = null
	finishing = true
	label.text = "Tutorial complete! You received 1000 coins. Good luck, coach!"
	panel.reset_size()
	var vs := get_viewport_rect().size
	panel.position = Vector2((vs.x - 660.0) * 0.5, vs.y * 0.4)
	visible = true
	queue_redraw()
