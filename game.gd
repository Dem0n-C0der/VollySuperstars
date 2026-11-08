class_name Game
extends Control
# Match screen: 3D court + rally logic. Developer: Sano

signal exit(won: bool)
signal flight_done
signal court_tapped(p: Vector3)
signal aim_done

var mode := "story"
var level := 1
var opp_name := "Opponent"
var opp_str := 50.0
var target_pts := 15
var tut_mode := false

var cam: Camera3D
var world: Node3D
var ball: MeshInstance3D
var shadow: MeshInstance3D
var my: Array = []
var my_nodes := {}
var ai_nodes: Array = []
var ai_s := {}
var score := [0, 0]
var server := 0
var fl := {}
var flying := false
var expect := ""
var win_t := 0.8
var pressed_kind := ""
var press_q := 0.0
var tut_hold := false
var tut_asked := false
var actor_node: Node3D = null
var dump_ok := false
var power := 0.0
var power_on := false
var allow_sub := false
var ended := false
var serve_wait := false
var say_tw: Tween = null
var sub_panel: Control = null
var sub_sel := -1
var aim_side := ""
var aim_has := false
var aim_pt := Vector3.ZERO
var aim_tap: TapArea
var marker: MeshInstance3D

var lbl_score: Label
var lbl_hint: Label
var lbl_say: Label
var btn_pass: Button
var btn_set: Button
var btn_dump: Button
var btn_spike: Button
var power_bar: ProgressBar
var court_tap: TapArea

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	G.play_music("bgm_match")
	_build_world()
	_build_hud()
	_setup_teams()
	_hud()
	_run()

# ------------------------------------------------------------------ world
func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _box(parent: Node, sz: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _build_world() -> void:
	world = Node3D.new()
	add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.html("#0b1630")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.95)
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, 25, 0)
	light.light_energy = 0.9
	light.shadow_enabled = int(G.save["gfx"]) >= 2
	world.add_child(light)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.fov = 48.0
	cam.look_at_from_position(Vector3(0, 14.5, 13.5), Vector3(0, 0, 0.8), Vector3.UP)
	cam.current = true
	_box(world, Vector3(70, 0.2, 70), Vector3(0, -0.2, 0), Color.html("#101a33"))
	_box(world, Vector3(14, 0.05, 23), Vector3(0, -0.06, 0), Color.html("#2a6f97"))
	_box(world, Vector3(9, 0.06, 18), Vector3(0, -0.03, 0), Color.html("#e07b39"))
	var wc := Color(1, 1, 1)
	for z in [-9.0, 9.0]:
		_box(world, Vector3(9.1, 0.02, 0.1), Vector3(0, 0.01, z), wc)
	for x in [-4.5, 4.5]:
		_box(world, Vector3(0.1, 0.02, 18.0), Vector3(x, 0.01, 0), wc)
	for z in [-3.0, 0.0, 3.0]:
		_box(world, Vector3(9.0, 0.02, 0.08), Vector3(0, 0.01, z), wc)
	_box(world, Vector3(9.4, 0.95, 0.05), Vector3(0, 1.95, 0), Color(0.92, 0.92, 1.0, 0.55))
	_box(world, Vector3(9.4, 0.09, 0.07), Vector3(0, 2.43, 0), Color(1, 1, 1))
	for x in [-4.75, 4.75]:
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06
		cm.bottom_radius = 0.06
		cm.height = 2.6
		post.mesh = cm
		post.material_override = _mat(Color(0.8, 0.8, 0.85))
		post.position = Vector3(x, 1.3, 0)
		world.add_child(post)
	ball = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	ball.mesh = sm
	ball.material_override = _mat(Color(1, 1, 0.95))
	ball.position = Vector3(0, 1.5, 6)
	world.add_child(ball)
	marker = MeshInstance3D.new()
	var mk := CylinderMesh.new()
	mk.top_radius = 0.55
	mk.bottom_radius = 0.55
	mk.height = 0.02
	marker.mesh = mk
	marker.material_override = _mat(Color(1, 0.9, 0.2, 0.7))
	marker.visible = false
	world.add_child(marker)
	shadow = MeshInstance3D.new()
	var shm := CylinderMesh.new()
	shm.top_radius = 0.3
	shm.bottom_radius = 0.3
	shm.height = 0.01
	shadow.mesh = shm
	shadow.material_override = _mat(Color(0, 0, 0, 0.45))
	world.add_child(shadow)

func _mk_player(team_col: Color, skin: Color, hair: Color, num: int, face_ai: bool) -> Node3D:
	var n := Node3D.new()
	var b := Node3D.new()
	b.name = "b"
	n.add_child(b)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.32
	cm.height = 1.25
	body.mesh = cm
	body.material_override = _mat(team_col)
	body.position = Vector3(0, 0.95, 0)
	b.add_child(body)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.23
	hm.height = 0.46
	head.mesh = hm
	head.material_override = _mat(skin)
	head.position = Vector3(0, 1.85, 0)
	b.add_child(head)
	var hr := MeshInstance3D.new()
	var hrm := SphereMesh.new()
	hrm.radius = 0.25
	hrm.height = 0.3
	hr.mesh = hrm
	hr.material_override = _mat(hair)
	hr.position = Vector3(0, 1.97, 0)
	b.add_child(hr)
	for side in [-1, 1]:
		var piv := Node3D.new()
		piv.name = "aL" if side < 0 else "aR"
		piv.position = Vector3(float(side) * 0.42, 1.5, 0)
		var am := MeshInstance3D.new()
		var acm := CapsuleMesh.new()
		acm.radius = 0.09
		acm.height = 0.65
		am.mesh = acm
		am.material_override = _mat(skin)
		am.position = Vector3(0, -0.3, 0)
		piv.add_child(am)
		b.add_child(piv)
	var lb := Label3D.new()
	lb.text = str(num)
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.font_size = 64
	lb.pixel_size = 0.008
	lb.no_depth_test = true
	lb.position = Vector3(0, 2.45, 0)
	b.add_child(lb)
	if face_ai:
		n.rotation.y = PI
	return n

func _slot_pos(slot: int, side: int) -> Vector3:
	var xs := [-3.0, 0.0, 3.0, -3.0, 0.0, 3.0]
	var zs := [2.6, 2.6, 2.6, 6.8, 6.8, 6.8]
	var x: float = xs[slot]
	var z: float = zs[slot]
	if side == 1:
		return Vector3(-x, 0, -z)
	return Vector3(x, 0, z)

func _new_my_node(id: int, slot: int) -> Node3D:
	var p: Dictionary = G.players[id]
	var n := _mk_player(Color.html("#2f7bff"), G.SKIN[int(p["sk"])], G.HAIR[int(p["hc"])], (id % 30) + 1, false)
	n.position = _slot_pos(slot, 0)
	world.add_child(n)
	return n

func _setup_teams() -> void:
	my = G.match_lineup()
	for i in 6:
		my_nodes[int(my[i])] = _new_my_node(int(my[i]), i)
	for i in 6:
		var n := _mk_player(Color.html("#e0453a"), G.SKIN[randi() % 4], G.HAIR[randi() % 8], i + 1, true)
		n.position = _slot_pos(i, 1)
		world.add_child(n)
		ai_nodes.append(n)
	var adj: float = [-8.0, 0.0, 8.0][int(G.save["diff"])]
	for k in G.KEYS:
		ai_s[k] = clampf(opp_str + adj + randf_range(-4.0, 4.0), 25.0, 99.0)

# ------------------------------------------------------------------ hud
func _build_hud() -> void:
	court_tap = TapArea.new()
	court_tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	court_tap.anchor_top = 0.12
	court_tap.anchor_bottom = 0.58
	court_tap.offset_top = 0
	court_tap.offset_bottom = 0
	add_child(court_tap)
	court_tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	court_tap.tapped.connect(_on_court_tap)
	G.targets["court"] = court_tap
	aim_tap = TapArea.new()
	aim_tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	aim_tap.anchor_top = 0.1
	aim_tap.offset_top = 0
	add_child(aim_tap)
	aim_tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aim_tap.tapped.connect(_on_aim_tap)
	lbl_say = G.mk_label("", 64, Color.html("#ffe14a"))
	lbl_say.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_say.offset_bottom = -170
	lbl_say.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_say.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_say.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_say.modulate.a = 0.0
	add_child(lbl_say)
	lbl_hint = G.mk_label("", 28)
	lbl_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_hint.offset_bottom = -150
	lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	lbl_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl_hint)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 14)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var sp := G.mk_panel(Color(0.04, 0.08, 0.2, 0.85), 14)
	lbl_score = G.mk_label("", 26)
	sp.add_child(lbl_score)
	top.add_child(sp)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(fill)
	var bt := G.mk_btn("Team", Color.html("#2b6cff"), Vector2(150, 60), "team", 24)
	bt.pressed.connect(_open_sub)
	top.add_child(bt)
	var bm := G.mk_btn("Menu", Color.html("#8a3a3a"), Vector2(130, 60), "", 24)
	bm.pressed.connect(_open_quit)
	top.add_child(bm)
	var mid := Control.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(mid)
	var bot := HBoxContainer.new()
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bot)
	var pv := VBoxContainer.new()
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.alignment = BoxContainer.ALIGNMENT_END
	pv.add_child(G.mk_label("POWER", 20, Color.html("#ffc43a")))
	power_bar = ProgressBar.new()
	power_bar.custom_minimum_size = Vector2(260, 26)
	power_bar.max_value = 100.0
	power_bar.show_percentage = false
	pv.add_child(power_bar)
	bot.add_child(pv)
	var f2 := Control.new()
	f2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot.add_child(f2)
	btn_pass = G.mk_btn("PASS", Color.html("#2b8cff"), Vector2(200, 110), "", 34)
	btn_set = G.mk_btn("SET", Color.html("#27a85a"), Vector2(200, 110), "", 34)
	btn_dump = G.mk_btn("DUMP", Color.html("#9a4bd6"), Vector2(200, 110), "", 34)
	btn_spike = G.mk_btn("SPIKE", Color.html("#e8452f"), Vector2(230, 110), "", 34)
	btn_pass.pressed.connect(_press.bind("pass"))
	btn_set.pressed.connect(_press.bind("set"))
	btn_dump.pressed.connect(_press.bind("dump"))
	btn_spike.pressed.connect(_press.bind("spike"))
	for b in [btn_dump, btn_set, btn_pass, btn_spike]:
		b.visible = false
		bot.add_child(b)
	G.targets["btn_pass"] = btn_pass
	G.targets["btn_set"] = btn_set
	G.targets["btn_spike"] = btn_spike

func _hud() -> void:
	lbl_score.text = "%s  %d : %d  %s\nServing: %s" % [String(G.save["name"]), score[0], score[1], opp_name, "YOU" if server == 0 else "OPP"]
	power_bar.value = power
	btn_spike.text = "POWER SMASH" if power >= 100.0 else "SPIKE"
	btn_spike.add_theme_font_size_override("font_size", 26 if power >= 100.0 else 34)

func _hint(t: String) -> void:
	lbl_hint.text = t

func _say(t: String, dur := 1.0) -> void:
	lbl_say.text = t
	lbl_say.modulate.a = 1.0
	if say_tw != null and say_tw.is_valid():
		say_tw.kill()
	say_tw = create_tween()
	say_tw.tween_interval(dur)
	say_tw.tween_property(lbl_say, "modulate:a", 0.0, 0.35)

func _win() -> float:
	return [1.0, 0.8, 0.65][int(G.save["diff"])]

# ------------------------------------------------------------------ input
func _ground(pos: Vector2) -> Vector3:
	var o := cam.project_ray_origin(pos)
	var n := cam.project_ray_normal(pos)
	if absf(n.y) < 0.001:
		return Vector3(0, 0, -4)
	var t := -o.y / n.y
	return o + n * t

func _on_court_tap(pos: Vector2) -> void:
	if not serve_wait:
		return
	serve_wait = false
	court_tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	court_tapped.emit(_ground(pos))

func _press(kind: String) -> void:
	if not flying or expect == "" or pressed_kind != "":
		return
	if not (kind == expect or (expect == "set" and kind == "dump")):
		return
	var dur: float = fl["dur"]
	var t: float = fl["t"]
	if t < dur - win_t and not tut_hold:
		return
	var q := 1.0 - clampf(absf(t - (dur - 0.15)) / win_t, 0.0, 1.0)
	if tut_hold:
		q = 1.0
		tut_hold = false
	pressed_kind = kind
	press_q = q
	if kind == "spike" and power >= 100.0:
		power_on = true
		power = 0.0
		_hud()
	_do_anim(kind)
	aim_has = false
	aim_side = "own" if kind == "set" else ("enemy" if kind == "spike" or kind == "dump" else "")
	if aim_side != "":
		aim_tap.mouse_filter = Control.MOUSE_FILTER_STOP
	_say("PERFECT!" if q > 0.8 else ("GOOD" if q > 0.5 else "OK"), 0.45)
	G.sfx("pass" if kind == "pass" else ("set" if kind == "set" or kind == "dump" else "hit"))

func _clamp_enemy(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, -4.3, 4.3), 0, clampf(p.z, -8.8, -0.6))

func _clamp_own(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, -4.3, 4.3), 0, clampf(p.z, 0.6, 8.8))

func _on_aim_tap(pos: Vector2) -> void:
	if aim_side == "" or aim_has:
		return
	var pt := _ground(pos)
	aim_pt = _clamp_enemy(pt) if aim_side == "enemy" else _clamp_own(pt)
	aim_has = true
	_mark(aim_pt)
	aim_done.emit()

func _mark(p: Vector3) -> void:
	marker.position = Vector3(p.x, 0.04, p.z)
	marker.visible = true
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(func(): marker.visible = false)

func _aim(side: String) -> Vector3:
	if not aim_has:
		_hint("Touch anywhere on %s court to aim!" % ("the OPPONENT's" if side == "enemy" else "YOUR"))
		aim_side = side
		aim_tap.mouse_filter = Control.MOUSE_FILTER_STOP
		var tm := get_tree().create_timer(5.0)
		tm.timeout.connect(func():
			if aim_side != "" and not aim_has:
				aim_pt = _clamp_enemy(Vector3(randf_range(-3.0, 3.0), 0, -4.5)) if side == "enemy" else _clamp_own(Vector3(randf_range(-3.0, 3.0), 0, 3.0))
				aim_has = true
				aim_done.emit())
		await aim_done
	_hint("")
	aim_side = ""
	aim_tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return aim_pt

# ------------------------------------------------------------------ animation
func _arms(n: Node3D, deg: float, t := 0.12) -> void:
	for k in ["aL", "aR"]:
		var a: Node3D = n.get_node("b/" + k)
		var tw := create_tween()
		tw.tween_property(a, "rotation_degrees:x", deg, t)
		tw.tween_interval(0.15)
		tw.tween_property(a, "rotation_degrees:x", 0.0, 0.3)

func _jump(n: Node3D, h: float, t: float) -> void:
	var b: Node3D = n.get_node("b")
	var tw := create_tween()
	tw.tween_property(b, "position:y", h, t * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "position:y", 0.0, t * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _dive(n: Node3D) -> void:
	var b: Node3D = n.get_node("b")
	var tw := create_tween()
	tw.tween_property(b, "rotation_degrees:x", 40.0, 0.15)
	tw.tween_interval(0.2)
	tw.tween_property(b, "rotation_degrees:x", 0.0, 0.3)
	_arms(n, -40.0, 0.12)

func _move(n: Node3D, p: Vector3, t := 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(n, "position", Vector3(p.x, 0, p.z), maxf(t, 0.05))

func _home_all(t: float) -> void:
	for i in 6:
		_move(my_nodes[int(my[i])], _slot_pos(i, 0), t)
		_move(ai_nodes[i], _slot_pos(i, 1), t)

func _do_anim(kind: String) -> void:
	if actor_node == null or not is_instance_valid(actor_node):
		return
	match kind:
		"pass":
			_dive(actor_node)
		"set", "dump":
			_jump(actor_node, 0.35, 0.4)
			_arms(actor_node, -150.0, 0.1)
		"spike":
			_jump(actor_node, 1.1, 0.5)
			_arms(actor_node, -170.0, 0.1)

func _shake() -> void:
	var base := cam.position
	var tw := create_tween()
	for i in 4:
		tw.tween_property(cam, "position", base + Vector3(randf_range(-0.25, 0.25), randf_range(-0.15, 0.15), 0), 0.04)
	tw.tween_property(cam, "position", base, 0.05)

# ------------------------------------------------------------------ ball
func _process(delta: float) -> void:
	var open := flying and expect != "" and pressed_kind == "" and float(fl["t"]) >= float(fl["dur"]) - win_t
	btn_pass.visible = expect == "pass"
	btn_set.visible = expect == "set"
	btn_dump.visible = expect == "set" and dump_ok
	btn_spike.visible = expect == "spike"
	for b in [btn_pass, btn_set, btn_dump, btn_spike]:
		b.disabled = not open
	if flying:
		if not tut_hold:
			fl["t"] = float(fl["t"]) + delta
		var dur: float = fl["dur"]
		var s := minf(float(fl["t"]), dur) / dur
		var a: Vector3 = fl["a"]
		var b: Vector3 = fl["b"]
		var pos := a.lerp(b, s)
		pos.y = lerpf(a.y, b.y, s) + 4.0 * float(fl["h"]) * s * (1.0 - s)
		ball.position = pos
		ball.rotation.x += delta * 9.0
		var k := 1.0 / (1.0 + pos.y * 0.2)
		shadow.position = Vector3(pos.x, 0.02, pos.z)
		shadow.scale = Vector3(k, 1, k)
		if G.tut_active and expect != "" and not tut_asked and float(fl["t"]) >= dur - 0.75:
			tut_asked = true
			var nm := "btn_" + ("spike" if expect == "spike" else expect)
			if G.tut != null and G.tut.game_request(nm):
				tut_hold = true
		if float(fl["t"]) >= dur + (0.1 if expect != "" else 0.0) and not tut_hold:
			flying = false
			flight_done.emit()

func _fly(a: Vector3, b: Vector3, dur: float, h: float, exp := "", win := 0.8) -> Dictionary:
	var d := dur * (1.5 if tut_mode else 1.0)
	fl = {"a": a, "b": b, "dur": d, "h": h, "t": 0.0}
	expect = exp
	win_t = minf(win * (1.3 if tut_mode else 1.0), d)
	pressed_kind = ""
	press_q = 0.0
	tut_asked = false
	flying = true
	await flight_done
	var res := {"kind": pressed_kind, "q": press_q}
	expect = ""
	return res

# ------------------------------------------------------------------ team stats
func ms(id: int, k: String) -> float:
	var p: Dictionary = G.players[id]
	return float(G.stat(p, k) + G.cbonus(p, my))

func my_avg(k: String) -> float:
	var s := 0.0
	for id in my:
		s += ms(int(id), k)
	return s / 6.0

func _nearest(side: int, p: Vector3) -> int:
	var best := 0
	var bd := 9999.0
	for i in 6:
		var d := _slot_pos(i, side).distance_to(Vector3(p.x, 0, p.z))
		if d < bd:
			bd = d
			best = i
	return best

func _setter_id() -> int:
	for id in my:
		if G.players[int(id)]["pos"] == "S":
			return int(id)
	var best := int(my[0])
	for id in my:
		if G.players[int(id)]["pos"] != "L" and ms(int(id), "set") > ms(best, "set"):
			best = int(id)
	return best

func _pick_hitter(sid: int, aimx := 999.0) -> int:
	var cands: Array = []
	for i in 3:
		var id := int(my[i])
		if id != sid and G.players[id]["pos"] != "L":
			cands.append(id)
	if cands.is_empty():
		for i in 6:
			var id2 := int(my[i])
			if id2 != sid and G.players[id2]["pos"] != "L":
				cands.append(id2)
	if cands.is_empty():
		return sid
	if aimx < 900.0:
		var bestc := int(cands[0])
		var bd := 999.0
		for id in cands:
			var dx := absf(_slot_pos(my.find(int(id)), 0).x - aimx)
			if dx < bd:
				bd = dx
				bestc = int(id)
		return bestc
	var tot := 0.0
	for id in cands:
		tot += ms(int(id), "spk")
	var r := randf() * tot
	for id in cands:
		r -= ms(int(id), "spk")
		if r <= 0.0:
			return int(id)
	return int(cands[0])

# ------------------------------------------------------------------ rally
func _rally() -> int:
	var st := "serve_user" if server == 0 else "serve_ai"
	var info := {}
	while true:
		match st:
			"serve_user":
				st = await _st_serve_user(info)
			"serve_ai":
				st = await _st_serve_ai(info)
			"user_receive":
				st = await _st_user_receive(info)
			"user_set":
				st = await _st_user_set(info)
			"user_spike":
				st = await _st_user_spike(info)
			"ai_receive":
				st = await _st_ai_receive(info)
			"ai_chain":
				st = await _st_ai_chain(info)
			"W0":
				return 0
			"W1":
				return 1
			_:
				return 1
	return 0

func _st_serve_user(info: Dictionary) -> String:
	var sid := int(my[5])
	var node: Node3D = my_nodes[sid]
	actor_node = node
	_hint("Touch the opponent's court to serve!")
	allow_sub = true
	serve_wait = true
	court_tap.mouse_filter = Control.MOUSE_FILTER_STOP
	if G.tut_active and G.tut != null:
		G.tut.game_request("court")
	var tgt: Vector3 = await court_tapped
	allow_sub = false
	_hint("")
	var srv := ms(sid, "srv")
	var tf := G.tut_active
	tgt.x = clampf(tgt.x, -5.0, 5.0)
	tgt.z = clampf(tgt.z, -9.6, -1.0)
	if not tf:
		var err := (100.0 - srv) / 100.0 * 2.4
		tgt.x += randf_range(-err, err)
		tgt.z += randf_range(-err, err)
	var sx := node.position.x
	_move(node, Vector3(sx, 0, 9.8), 0.45)
	ball.position = Vector3(sx, 1.2, 9.6)
	await get_tree().create_timer(0.55).timeout
	_jump(node, 0.9, 0.45)
	_arms(node, -170.0, 0.1)
	await get_tree().create_timer(0.22).timeout
	G.sfx("hit")
	var hand := Vector3(sx, 2.5, 9.6)
	if not tf and randf() < maxf(0.0, (62.0 - srv) / 320.0):
		await _fly(hand, Vector3(sx * 0.5, 0.0, 0.5), 1.0, 2.0)
		_say("NET!")
		return "W1"
	await _fly(hand, tgt, 1.6, 4.5)
	if absf(tgt.x) > 4.5 or tgt.z < -9.0 or tgt.z > -0.1:
		_say("OUT!")
		return "W1"
	info["land"] = tgt
	return "ai_receive"

func _st_serve_ai(info: Dictionary) -> String:
	var sn: Node3D = ai_nodes[5]
	var sx := sn.position.x
	_move(sn, Vector3(sx, 0, -9.8), 0.45)
	ball.position = Vector3(sx, 1.2, -9.6)
	await get_tree().create_timer(0.9).timeout
	_jump(sn, 0.9, 0.45)
	_arms(sn, -170.0, 0.1)
	await get_tree().create_timer(0.22).timeout
	G.sfx("hit")
	var hand := Vector3(sx, 2.5, -9.6)
	var srv: float = ai_s["srv"]
	var err := (100.0 - srv) / 100.0 * 2.0
	var tgt := Vector3(randf_range(-3.8, 3.8) + randf_range(-err, err), 0, randf_range(1.8, 8.2) + randf_range(-err, err))
	if absf(tgt.x) > 4.5 or tgt.z > 9.0 or tgt.z < 0.2:
		await _fly(hand, tgt, 1.6, 4.5)
		_say("Opponent serve is OUT!")
		return "W0"
	var ri := _nearest(0, tgt)
	var d := _slot_pos(ri, 0).distance_to(Vector3(tgt.x, 0, tgt.z))
	var reach := 1.6 + ms(int(my[ri]), "rec") / 100.0 * 1.2
	if d > reach:
		await _fly(hand, tgt, 1.6, 4.5)
		_say("ACE against you!")
		return "W1"
	info["from"] = hand
	info["land"] = tgt
	info["dur"] = 1.6
	info["h"] = 4.5
	return "user_receive"

func _st_user_receive(info: Dictionary) -> String:
	var land: Vector3 = info["land"]
	var ri := _nearest(0, land)
	var id := int(my[ri])
	var node: Node3D = my_nodes[id]
	actor_node = node
	var dur: float = info["dur"]
	_move(node, land, dur * (1.5 if tut_mode else 1.0) * 0.85)
	_hint("Tap PASS just before the ball lands!")
	var res: Dictionary = await _fly(info["from"], Vector3(land.x, 0.5, land.z), dur, float(info["h"]), "pass", _win())
	_hint("")
	var tf := G.tut_active or tut_mode
	if res["kind"] != "pass":
		_say("MISSED!")
		return "W1"
	var q: float = res["q"]
	var ok := tf or randf() < clampf(0.40 + q * 0.5 + ms(id, "rec") / 300.0, 0.15, 0.97)
	if not ok:
		_say("Bad pass!")
		return "W1"
	power = minf(100.0, power + 8.0)
	_hud()
	if q < 0.3 and not tf:
		var tgt := Vector3(randf_range(-3.5, 3.5), 0, randf_range(-8.0, -2.0))
		await _fly(Vector3(land.x, 1.0, land.z), tgt, 1.5, 5.0)
		info["land"] = tgt
		info["free"] = true
		_say("Free ball!")
		return "ai_receive"
	info["from"] = Vector3(land.x, 1.0, land.z)
	return "user_set"

func _st_user_set(info: Dictionary) -> String:
	var sid := _setter_id()
	var snode: Node3D = my_nodes[sid]
	actor_node = snode
	var sp := Vector3(2.0, 0, 1.9)
	_move(snode, sp, 0.5)
	dump_ok = G.players[sid]["pos"] == "S"
	_hint("Tap SET" + (" (or DUMP)" if dump_ok else ""))
	var res: Dictionary = await _fly(info["from"], Vector3(sp.x, 2.3, sp.z), 1.0, 3.5, "set", _win())
	_hint("")
	dump_ok = false
	if res["kind"] == "":
		_say("Nobody set it!")
		return "W1"
	var q: float = res["q"]
	if res["kind"] == "dump":
		var ap: Vector3 = await _aim("enemy")
		var derr := (1.0 - q) * 1.0
		var tp := _clamp_enemy(ap + Vector3(randf_range(-derr, derr), 0, randf_range(-derr, derr)))
		var dd := _slot_pos(_nearest(1, tp), 1).distance_to(tp)
		var p_s := clampf((0.28 + q * 0.25 + ms(sid, "set") / 400.0 - float(ai_s["blk"]) / 500.0) * (0.6 + dd / 3.0), 0.12, 0.8)
		await _fly(Vector3(sp.x, 2.6, 1.4), tp, 0.55, 0.6)
		if randf() < p_s:
			_say("DUMP!")
			G.sfx("cheer", 0.6)
			return "W0"
		info["land"] = tp
		info["free"] = true
		return "ai_receive"
	var sap: Vector3 = await _aim("own")
	var hid := _pick_hitter(sid, sap.x)
	var hx := _slot_pos(my.find(hid), 0).x * 0.8
	_move(my_nodes[hid], Vector3(hx, 0, 2.0), 0.7)
	actor_node = my_nodes[hid]
	info["from"] = Vector3(sp.x, 2.3, sp.z)
	info["sq"] = q
	info["hid"] = hid
	info["hx"] = hx
	return "user_spike"

func _st_user_spike(info: Dictionary) -> String:
	var hid: int = info["hid"]
	var hx: float = info["hx"]
	actor_node = my_nodes[hid]
	_hint("Tap SPIKE at the right moment!")
	var res: Dictionary = await _fly(info["from"], Vector3(hx, 2.8, 1.5), 1.0, 4.0, "spike", _win())
	_hint("")
	var tf := G.tut_active or tut_mode
	if res["kind"] != "spike":
		_say("No spike!")
		return "W1"
	var sq: float = res["q"]
	G.mis("spike", 1)
	if sq < 0.12 and not tf:
		_say("Hit the net!")
		return "W1"
	G.sfx("spike")
	var ap: Vector3 = await _aim("enemy")
	var big := power_on
	power_on = false
	var P := ms(hid, "spk") * 0.6 + float(info["sq"]) * 12.0 + sq * 28.0 + (45.0 if big else 0.0)
	var from := Vector3(hx, 2.8, 1.5)
	var pb := clampf(0.10 + (float(ai_s["blk"]) - P * 0.65) / 220.0, 0.02, 0.35)
	var pd := clampf(0.38 + (float(ai_s["rec"]) - P * 0.7) / 160.0, 0.06, 0.6)
	var aerr := ((1.0 - sq) * 0.9 + (100.0 - ms(hid, "spk")) / 100.0 * 1.2) * 0.5
	var aimed := ap + Vector3(randf_range(-aerr, aerr), 0, randf_range(-aerr, aerr))
	if not tf and (absf(aimed.x) > 4.5 or aimed.z < -9.0 or aimed.z > -0.1):
		await _fly(from, aimed, 0.55, 0.4)
		_say("OUT!")
		return "W1"
	var adist := _slot_pos(_nearest(1, aimed), 1).distance_to(aimed)
	pd = clampf(pd * (1.5 - adist / 2.5), 0.03, 0.7)
	if big:
		pb *= 0.3
		pd *= 0.4
	var r := randf()
	if tf:
		r = 0.99
	if r < pb:
		await _fly(from, Vector3(hx, 2.4, -0.4), 0.3, 0.1)
		_say("BLOCKED!")
		if randf() < 0.4:
			info["from"] = Vector3(hx, 2.4, -0.4)
			info["land"] = Vector3(randf_range(-3.0, 3.0), 0, randf_range(4.0, 8.0))
			info["dur"] = 1.3
			info["h"] = 4.0
			return "user_receive"
		await _fly(Vector3(hx, 2.4, -0.4), Vector3(hx, 0, 1.0), 0.3, 0.1)
		return "W1"
	if r < pb + pd:
		await _fly(from, aimed, 0.6, 0.5)
		_say("Dug!", 0.6)
		info["land"] = aimed
		return "ai_chain"
	await _fly(from, aimed, 0.55 if not big else 0.4, 0.4)
	_shake()
	if big:
		_say("POWER SMASH!")
		G.sfx("cheer", 0.8)
	else:
		_say("SMASH!")
	return "W0"

func _st_ai_receive(info: Dictionary) -> String:
	var land: Vector3 = info["land"]
	var ri := _nearest(1, land)
	var rn: Node3D = ai_nodes[ri]
	_move(rn, land, 0.4)
	var d := _slot_pos(ri, 1).distance_to(Vector3(land.x, 0, land.z))
	var reach := 1.6 + float(ai_s["rec"]) / 100.0 * 1.2
	var free := bool(info.get("free", false))
	var tf := G.tut_active or tut_mode
	if not free and not tf and d > reach:
		_say("ACE!")
		G.sfx("cheer", 0.8)
		return "W0"
	var p_ok := 0.92 if free else clampf(0.55 + (float(ai_s["rec"]) - my_avg("srv")) / 200.0, 0.3, 0.9)
	if tf:
		p_ok = 1.0
	if randf() > p_ok:
		_say("Receive error!")
		return "W0"
	_dive(rn)
	G.sfx("pass")
	return "ai_chain"

func _st_ai_chain(info: Dictionary) -> String:
	var land: Vector3 = info["land"]
	var ri := _nearest(1, land)
	var rn: Node3D = ai_nodes[ri]
	_move(rn, land, 0.2)
	var tf := G.tut_active or tut_mode
	var setter: Node3D = ai_nodes[5]
	_move(setter, Vector3(-2.0, 0, -1.9), 0.6)
	var hslot := randi() % 3
	var hx := _slot_pos(hslot, 1).x * 0.8
	_move(ai_nodes[hslot], Vector3(hx, 0, -2.0), 0.7)
	await _fly(Vector3(land.x, 1.0, land.z), Vector3(-2.0, 2.3, -1.9), 0.9, 3.5)
	G.sfx("set")
	_jump(setter, 0.3, 0.3)
	await _fly(Vector3(-2.0, 2.3, -1.9), Vector3(hx, 2.8, -1.5), 0.9, 4.0)
	_jump(ai_nodes[hslot], 1.1, 0.5)
	_arms(ai_nodes[hslot], -170.0, 0.1)
	G.sfx("spike")
	var hit := Vector3(hx, 2.8, -1.5)
	var aspk: float = ai_s["spk"]
	var diff := int(G.save["diff"])
	var mdef := my_avg("blk") * 0.4 + my_avg("rec") * 0.6
	var pe: float = 0.07 + [0.06, 0.0, -0.03][diff]
	var pk := clampf(0.10 + (aspk - mdef) / 230.0 + [-0.05, 0.0, 0.06][diff], 0.04, 0.36)
	var pb := clampf(0.08 + (my_avg("blk") - aspk) / 260.0, 0.02, 0.25)
	var r := randf()
	if tf:
		r = 0.99
		pe = 0.0
		pk = 0.0
		pb = 0.0
	if r < pe:
		await _fly(hit, Vector3(hx, 0, -0.2), 0.5, 0.2)
		_say("Opponent error!")
		return "W0"
	if r < pe + pb:
		await _fly(hit, Vector3(hx, 2.4, -0.2), 0.3, 0.1)
		_say("BLOCK!")
		G.sfx("hit")
		if randf() < 0.6:
			await _fly(Vector3(hx, 2.4, -0.2), Vector3(hx, 0, -1.0), 0.3, 0.1)
			return "W0"
		info["land"] = Vector3(randf_range(-3.0, 3.0), 0, randf_range(-8.0, -3.5))
		await _fly(Vector3(hx, 2.4, -0.2), info["land"], 1.2, 4.0)
		return "ai_chain"
	if r < pe + pb + pk:
		var kt := Vector3(randf_range(-4.2, 4.2), 0, 4.7)
		await _fly(hit, kt, 0.6, 0.4)
		_say("Spiked!")
		_shake()
		return "W1"
	var ti := randi() % 6
	var tp := _slot_pos(ti, 0) + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
	info["from"] = hit
	info["land"] = tp
	info["dur"] = 1.1
	info["h"] = 0.8
	return "user_receive"

# ------------------------------------------------------------------ flow
func _is_over() -> bool:
	var a: int = score[0]
	var b: int = score[1]
	if (a >= target_pts or b >= target_pts) and absi(a - b) >= 2:
		return true
	return a >= target_pts + 4 or b >= target_pts + 4

func _point(w: int) -> void:
	score[w] += 1
	if w == 0:
		power = minf(100.0, power + 20.0)
		G.mis("score", 1)
		G.sfx("point")
		if server == 1:
			my = G.rot(my)
			server = 0
	else:
		G.sfx("lose")
		server = 1
	_hud()

func _run() -> void:
	await get_tree().create_timer(0.8).timeout
	while not ended:
		while sub_panel != null:
			await get_tree().create_timer(0.2).timeout
		G.sfx("whistle")
		var w: int = await _rally()
		if ended:
			return
		_point(w)
		allow_sub = true
		await get_tree().create_timer(1.7).timeout
		if _is_over():
			ended = true
			break
		_home_all(0.6)
		await get_tree().create_timer(0.8).timeout
	_finish()

func _finish() -> void:
	var won: bool = score[0] > score[1]
	G.sfx("win" if won else "lose")
	if won:
		G.sfx("cheer")
	var info := G.finish_match(mode, level, won, score[0], score[1])
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	var pan := G.mk_panel(Color(0.06, 0.1, 0.24, 0.98), 22)
	c.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pan.add_child(v)
	var t := G.mk_label("VICTORY!" if won else "DEFEAT", 56, Color.html("#7dff9a") if won else Color.html("#ff6a5a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := G.mk_label("%d : %d" % [score[0], score[1]], 44)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var rw := G.mk_label("+%d coins   +%d XP" % [info["coins"], info["xp"]], 30, Color.html("#ffc43a"))
	rw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(rw)
	var b := G.mk_btn("Continue", Color.html("#27a85a"), Vector2(320, 76), "", 32)
	b.pressed.connect(func(): exit.emit(won))
	v.add_child(b)

# ------------------------------------------------------------------ substitution / quit
func _open_sub() -> void:
	if not allow_sub:
		_hint("You can substitute between points.")
		return
	if sub_panel != null:
		return
	sub_sel = -1
	sub_panel = ColorRect.new()
	(sub_panel as ColorRect).color = Color(0, 0, 0, 0.88)
	sub_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sub_panel)
	_sub_refresh()

func _sub_refresh() -> void:
	for c in sub_panel.get_children():
		c.queue_free()
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	sub_panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)
	v.add_child(G.mk_label("Substitution: tap a lineup player, then a bench player", 26))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	for i in 6:
		var cv := CardView.new().setup(G.players[int(my[i])], Vector2(120, 168))
		cv.selected = (sub_sel == i)
		cv.pressed.connect(func():
			sub_sel = i
			_sub_refresh())
		row.add_child(cv)
	v.add_child(G.mk_label("Bench", 24, Color.html("#ffc43a")))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 190)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	sc.add_child(hb)
	for id in G.bench_ids():
		var bc := CardView.new().setup(G.players[int(id)], Vector2(120, 168))
		var bid := int(id)
		bc.pressed.connect(func(): _sub_swap(bid))
		hb.add_child(bc)
	var cl := G.mk_btn("Close", Color.html("#2b6cff"), Vector2(220, 60), "", 26)
	cl.pressed.connect(func():
		sub_panel.queue_free()
		sub_panel = null)
	v.add_child(cl)

func _sub_swap(new_id: int) -> void:
	if sub_sel < 0:
		_hint("Select a lineup player first.")
		return
	var old_id := int(my[sub_sel])
	var old_node: Node3D = my_nodes[old_id]
	old_node.queue_free()
	my_nodes.erase(old_id)
	my[sub_sel] = new_id
	my_nodes[new_id] = _new_my_node(new_id, sub_sel)
	var li: int = G.save["lineup"].find(old_id)
	if li >= 0:
		G.save["lineup"][li] = new_id
		G.write()
	sub_sel = -1
	G.sfx("card")
	_sub_refresh()

func _open_quit() -> void:
	if sub_panel != null:
		return
	sub_panel = ColorRect.new()
	(sub_panel as ColorRect).color = Color(0, 0, 0, 0.8)
	sub_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sub_panel)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_panel.add_child(c)
	var pan := G.mk_panel()
	c.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pan.add_child(v)
	v.add_child(G.mk_label("Quit this match?\nYou will not get any reward.", 30))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var y := G.mk_btn("Quit", Color.html("#c0392b"), Vector2(200, 64))
	y.pressed.connect(func():
		ended = true
		exit.emit(false))
	h.add_child(y)
	var n := G.mk_btn("Keep Playing", Color.html("#27a85a"), Vector2(240, 64))
	n.pressed.connect(func():
		sub_panel.queue_free()
		sub_panel = null)
	h.add_child(n)
