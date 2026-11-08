class_name Game
extends Control
# Match screen: 3D stadium + rally state machine. Developer: Sano

signal exit(won: bool)

const SERVE_Z := 10.2

var mode := "story"
var level := 1
var opp_name := "Opponent"
var opp_str := 50.0
var target_pts := 15
var tut_mode := false

var cam: Camera3D
var world: Node3D
var ball: Node3D
var shadow: MeshInstance3D
var ring: MeshInstance3D
var marker: MeshInstance3D
var my: Array = []
var my_pl := {}
var ai_pl: Array = []
var ai_s := {}
var score := [0, 0]
var server := 0
var st := "intro"
var st_t := 0.0
var wait_t := 0.0
var wait_cb := Callable()
var fl := {}
var flying := false
var flight_cb := Callable()
var expect := ""
var win_t := 0.9
var pressed_kind := ""
var press_q := 0.0
var tut_hold := false
var tut_asked := false
var hold_wd := 0.0
var actor: Player3D = null
var ball_hold: Player3D = null
var dump_ok := false
var power := 0.0
var power_on := false
var allow_sub := false
var serve_wait := false
var ended := false
var aim_side := ""
var aim_has := false
var aim_pt := Vector3.ZERO
var aim_cb := Callable()
var aim_t := 0.0
var say_tw: Tween = null
var sub_panel: Control = null
var sub_sel := -1
var ctx := {}
var t_all := 0.0
var crowd_e := 0.3
var crowd_seats: Array = []
var crowd_ph: Array = []
var crowd_mm: Array = []
var crowd_acc := 0.0
var trail: Array = []
var trail_a: Array = []
var trail_i := 0
var trail_acc := 0.0
var refs: Array = []
var mascot: Node3D
var mascot_arms: Array = []

var lbl_score: Label
var lbl_hint: Label
var lbl_say: Label
var btn_pass: Button
var btn_set: Button
var btn_dump: Button
var btn_spike: Button
var power_bar: ProgressBar
var court_tap: TapArea
var aim_tap: TapArea
var tbar: TimingBar

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	G.play_music("bgm_match")
	G.play_amb(true)
	_build_world()
	_build_hud()
	_setup_teams()
	_hud()
	st = "intro"

func _exit_tree() -> void:
	G.play_amb(false)

# ------------------------------------------------------------------ world
func _mat(c: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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

func _torus(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	return t

func _build_world() -> void:
	world = Node3D.new()
	add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.html("#070d20")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 1.0)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-62, 30, 0)
	light.light_energy = 0.85
	light.shadow_enabled = int(G.save["gfx"]) >= 2
	world.add_child(light)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.fov = 45.0
	cam.look_at_from_position(Vector3(-8.0, 17.0, 0.4), Vector3(0, 0, 0.4), Vector3(1, 0, 0))
	cam.current = true
	_box(world, Vector3(80, 0.2, 80), Vector3(0, -0.2, 0), Color.html("#0e1630"))
	_box(world, Vector3(14.5, 0.05, 23), Vector3(0, -0.06, 0), Color.html("#2a6f97"))
	_box(world, Vector3(9, 0.06, 18), Vector3(0, -0.03, 0), Color.html("#e07b39"))
	var wc := Color(1, 1, 1)
	for z in [-9.0, 9.0]:
		_box(world, Vector3(9.1, 0.02, 0.1), Vector3(0, 0.01, z), wc)
	for x in [-4.5, 4.5]:
		_box(world, Vector3(0.1, 0.02, 18.0), Vector3(x, 0.01, 0), wc)
	for z in [-3.0, 0.0, 3.0]:
		_box(world, Vector3(9.0, 0.02, 0.08), Vector3(0, 0.01, z), wc)
	_box(world, Vector3(9.4, 0.95, 0.05), Vector3(0, 1.95, 0), Color(0.92, 0.92, 1.0, 0.5))
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
	var cols := [Color.html("#e8452f"), Color.html("#2f7bff"), Color.html("#ffc43a")]
	for k in 3:
		var z := -6.0 + float(k) * 6.0
		_box(world, Vector3(0.25, 0.9, 5.9), Vector3(5.4, 0.45, z), cols[k])
		_box(world, Vector3(0.25, 0.6, 5.9), Vector3(-5.4, 0.3, z), cols[(k + 1) % 3])
		var lb := Label3D.new()
		lb.text = "VOLLY SUPERSTARS"
		lb.font_size = 56
		lb.pixel_size = 0.0085
		lb.rotation_degrees = Vector3(0, -90, 0)
		lb.position = Vector3(5.26, 0.5, z)
		world.add_child(lb)
	_build_stands()
	_build_crowd()
	_build_refs()
	_build_mascot()
	# ball
	ball = Node3D.new()
	world.add_child(ball)
	var sm := SphereMesh.new()
	sm.radius = 0.26
	sm.height = 0.52
	var bm := MeshInstance3D.new()
	bm.mesh = sm
	bm.material_override = _mat(Color(1, 1, 0.96))
	ball.add_child(bm)
	var rcols := [Color.html("#2f7bff"), Color.html("#ffc43a"), Color.html("#2f7bff")]
	for k in 3:
		var rm := MeshInstance3D.new()
		rm.mesh = _torus(0.255, 0.285)
		rm.material_override = _mat(rcols[k])
		if k == 1:
			rm.rotation_degrees = Vector3(90, 0, 0)
		elif k == 2:
			rm.rotation_degrees = Vector3(0, 0, 90)
		ball.add_child(rm)
	ball.position = Vector3(0, 1.5, 6)
	shadow = MeshInstance3D.new()
	var shm := CylinderMesh.new()
	shm.top_radius = 0.3
	shm.bottom_radius = 0.3
	shm.height = 0.01
	shadow.mesh = shm
	shadow.material_override = _mat(Color(0, 0, 0, 0.45))
	world.add_child(shadow)
	ring = MeshInstance3D.new()
	ring.mesh = _torus(0.5, 0.62)
	ring.material_override = _mat(Color(1, 0.9, 0.2, 0.9), true)
	ring.visible = false
	world.add_child(ring)
	marker = MeshInstance3D.new()
	marker.mesh = _torus(0.3, 0.42)
	marker.material_override = _mat(Color(0.3, 1.0, 0.5, 0.9), true)
	marker.visible = false
	world.add_child(marker)
	for i in 10:
		var g := MeshInstance3D.new()
		var gs := SphereMesh.new()
		gs.radius = 0.16
		gs.height = 0.32
		g.mesh = gs
		g.material_override = _mat(Color(1, 1, 1, 0.4), true)
		g.visible = false
		world.add_child(g)
		trail.append(g)
		trail_a.append(0.0)

func _build_stands() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var sc := Color.html("#1b2542")
	for side in [-1.0, 1.0]:
		for k in 4:
			var x := float(side) * (6.9 + float(k) * 1.15)
			var hh := 0.45 + float(k) * 0.55
			_box(world, Vector3(1.15, hh, 29.0), Vector3(x, hh * 0.5 - 0.05, 0), sc)
			var zz := -13.5
			while zz <= 13.5:
				crowd_seats.append(Vector3(x, hh - 0.05, zz + rng.randf_range(-0.15, 0.15)))
				zz += 0.9
	for e in [-1.0, 1.0]:
		for k in 3:
			var z := float(e) * (10.9 + float(k) * 1.15)
			var hh2 := 0.4 + float(k) * 0.55
			_box(world, Vector3(14.0, hh2, 1.15), Vector3(0, hh2 * 0.5 - 0.05, z), sc)
			var xx := -6.0
			while xx <= 6.0:
				crowd_seats.append(Vector3(xx + rng.randf_range(-0.15, 0.15), hh2 - 0.05, z))
				xx += 0.9

func _build_crowd() -> void:
	var n := crowd_seats.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var palette := [Color.html("#2f7bff"), Color.html("#e0453a"), Color.html("#ffd23a"), Color.html("#f2f2f2"), Color.html("#3ac47a"), Color.html("#b05cff")]
	var bmesh := CapsuleMesh.new()
	bmesh.radius = 0.2
	bmesh.height = 0.75
	var hmesh := SphereMesh.new()
	hmesh.radius = 0.15
	hmesh.height = 0.3
	for part in 2:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = bmesh if part == 0 else hmesh
		mm.instance_count = n
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.9
		mi.material_override = m
		world.add_child(mi)
		crowd_mm.append(mm)
		for i in n:
			if part == 0:
				mm.set_instance_color(i, palette[rng.randi() % palette.size()])
			else:
				mm.set_instance_color(i, G.SKIN[rng.randi() % 4])
	for i in n:
		crowd_ph.append(rng.randf() * TAU)
	_crowd_update()

func _crowd_update() -> void:
	var n := crowd_seats.size()
	var sp := 3.0 + crowd_e * 4.0
	for i in n:
		var p: Vector3 = crowd_seats[i]
		var b := absf(sin(t_all * sp + float(crowd_ph[i]))) * crowd_e * 0.35
		crowd_mm[0].set_instance_transform(i, Transform3D(Basis.IDENTITY, p + Vector3(0, 0.45 + b, 0)))
		crowd_mm[1].set_instance_transform(i, Transform3D(Basis.IDENTITY, p + Vector3(0, 1.05 + b, 0)))

func _build_refs() -> void:
	for sd in [1.0, -1.0]:
		_box(world, Vector3(1.3, 1.7, 1.0), Vector3(float(sd) * 5.9, 0.85, 0), Color.html("#8a8f9c"))
		var pl := Player3D.new()
		pl.setup(Color(0.95, 0.95, 0.95), Color(0.08, 0.08, 0.1), G.SKIN[1], G.HAIR[0], 0, 1, 0.0)
		pl.position = Vector3(float(sd) * 5.9, 1.7, 0)
		world.add_child(pl)
		pl.look_at_pt(Vector3(0, 1.7, 0))
		refs.append(pl)

func _build_mascot() -> void:
	mascot = Node3D.new()
	mascot.position = Vector3(5.6, 0, -7.2)
	mascot.rotation.y = PI / 2.0
	world.add_child(mascot)
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	var bm := MeshInstance3D.new()
	bm.mesh = sm
	bm.material_override = _mat(Color(1, 1, 0.97))
	bm.position = Vector3(0, 1.15, 0)
	mascot.add_child(bm)
	for k in 2:
		var rm := MeshInstance3D.new()
		rm.mesh = _torus(0.595, 0.64)
		rm.material_override = _mat(Color.html("#2f7bff") if k == 0 else Color.html("#ffc43a"))
		rm.position = Vector3(0, 1.15, 0)
		rm.rotation_degrees = Vector3(90.0 * float(k), 0, 0 if k == 0 else 40)
		mascot.add_child(rm)
	for sd in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.09
		es.height = 0.18
		eye.mesh = es
		eye.material_override = _mat(Color(0.05, 0.05, 0.1))
		eye.position = Vector3(float(sd) * 0.22, 1.25, -0.54)
		mascot.add_child(eye)
		var piv := Node3D.new()
		piv.position = Vector3(float(sd) * 0.66, 1.1, 0)
		mascot.add_child(piv)
		var am := MeshInstance3D.new()
		var ac := CapsuleMesh.new()
		ac.radius = 0.09
		ac.height = 0.55
		am.mesh = ac
		am.material_override = _mat(Color(1, 1, 1))
		am.position = Vector3(0, -0.25, 0)
		piv.add_child(am)
		mascot_arms.append(piv)
		var leg := MeshInstance3D.new()
		var lc := CapsuleMesh.new()
		lc.radius = 0.1
		lc.height = 0.5
		leg.mesh = lc
		leg.material_override = _mat(Color.html("#e8452f"))
		leg.position = Vector3(float(sd) * 0.25, 0.25, 0)
		mascot.add_child(leg)
	var band := CylinderMesh.new()
	band.top_radius = 0.6
	band.bottom_radius = 0.6
	band.height = 0.08
	var bn := MeshInstance3D.new()
	bn.mesh = band
	bn.material_override = _mat(Color.html("#e8452f"))
	bn.position = Vector3(0, 1.5, 0)
	mascot.add_child(bn)

# ------------------------------------------------------------------ teams
func _slot_pos(slot: int, side: int) -> Vector3:
	var xs := [-3.0, 0.0, 3.0, -3.0, 0.0, 3.0]
	var zs := [2.6, 2.6, 2.6, 6.8, 6.8, 6.8]
	var x: float = xs[slot]
	var z: float = zs[slot]
	if side == 1:
		return Vector3(-x, 0, -z)
	return Vector3(x, 0, z)

func _new_my_player(id: int, slot: int) -> Player3D:
	var p: Dictionary = G.players[id]
	var libero: bool = p["pos"] == "L"
	var pl := Player3D.new()
	pl.setup(Color.html("#ffd23a") if libero else Color.html("#2f7bff"), Color.html("#14295e"), G.SKIN[int(p["sk"])], G.HAIR[int(p["hc"])], int(p["hs"]), (id % 30) + 1, 0.0)
	pl.position = _slot_pos(slot, 0)
	world.add_child(pl)
	return pl

func _setup_teams() -> void:
	my = G.match_lineup()
	for i in 6:
		my_pl[int(my[i])] = _new_my_player(int(my[i]), i)
	for i in 6:
		var pl := Player3D.new()
		var libero := i == 4
		pl.setup(Color.html("#ffd23a") if libero else Color.html("#d9362e"), Color.html("#6e1410"), G.SKIN[randi() % 4], G.HAIR[randi() % 8], randi() % 4, i + 1, PI)
		pl.position = _slot_pos(i, 1)
		world.add_child(pl)
		ai_pl.append(pl)
	var adj: float = [-8.0, 0.0, 8.0][int(G.save["diff"])]
	for k in G.KEYS:
		ai_s[k] = clampf(opp_str + adj + randf_range(-4.0, 4.0), 25.0, 99.0)

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
	return int(cands[0])

func _home_all() -> void:
	for i in 6:
		(my_pl[int(my[i])] as Player3D).go_to(_slot_pos(i, 0), 6.0)
		(ai_pl[i] as Player3D).go_to(_slot_pos(i, 1), 6.0)

func _tf() -> bool:
	return G.tut_active or tut_mode

func _win() -> float:
	return [1.1, 0.9, 0.7][int(G.save["diff"])]

# ------------------------------------------------------------------ hud
func _build_hud() -> void:
	court_tap = TapArea.new()
	court_tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	court_tap.anchor_right = 0.5
	court_tap.anchor_top = 0.1
	court_tap.anchor_bottom = 0.92
	add_child(court_tap)
	court_tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	court_tap.tapped.connect(_on_court_tap)
	G.targets["court"] = court_tap
	aim_tap = TapArea.new()
	aim_tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	aim_tap.anchor_top = 0.1
	add_child(aim_tap)
	aim_tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aim_tap.tapped.connect(_on_aim_tap)
	lbl_say = G.mk_label("", 64, Color.html("#ffe14a"))
	lbl_say.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_say.offset_bottom = -170
	lbl_say.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_say.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_say.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_say.add_theme_constant_override("outline_size", 10)
	lbl_say.modulate.a = 0.0
	add_child(lbl_say)
	lbl_hint = G.mk_label("", 28)
	lbl_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_hint.offset_bottom = -215
	lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	lbl_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl_hint)
	tbar = TimingBar.new()
	tbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tbar.offset_left = -230
	tbar.offset_right = 230
	tbar.offset_top = -190
	tbar.offset_bottom = -164
	tbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tbar)
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
	var sp := G.mk_panel(Color(0.04, 0.08, 0.2, 0.85), 18)
	lbl_score = G.mk_label("", 26)
	sp.add_child(lbl_score)
	top.add_child(sp)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(fill)
	var bt := G.mk_btn("Team", Color.html("#2b6cff"), Vector2(160, 62), "team", 24)
	bt.pressed.connect(_open_sub)
	top.add_child(bt)
	var bm := G.mk_btn("Menu", Color.html("#8a3a3a"), Vector2(130, 62), "", 24)
	bm.pressed.connect(_open_quit)
	top.add_child(bm)
	var mid := Control.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(mid)
	var bot := HBoxContainer.new()
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot.add_theme_constant_override("separation", 10)
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
	btn_pass = G.mk_btn("PASS", Color.html("#2b8cff"), Vector2(190, 110), "", 34)
	btn_set = G.mk_btn("SET", Color.html("#27a85a"), Vector2(170, 110), "", 34)
	btn_dump = G.mk_btn("DUMP", Color.html("#9a4bd6"), Vector2(170, 110), "", 34)
	btn_spike = G.mk_btn("SPIKE", Color.html("#e8452f"), Vector2(230, 110), "", 34)
	btn_pass.pressed.connect(_press.bind("pass"))
	btn_set.pressed.connect(_press.bind("set"))
	btn_dump.pressed.connect(_press.bind("dump"))
	btn_spike.pressed.connect(_press.bind("spike"))
	for b in [btn_dump, btn_set, btn_pass, btn_spike]:
		bot.add_child(b)
	G.targets["btn_pass"] = btn_pass
	G.targets["btn_set"] = btn_set
	G.targets["btn_spike"] = btn_spike

func _hud() -> void:
	lbl_score.text = "%s  %d : %d  %s\nServing: %s" % [String(G.save["name"]), score[0], score[1], opp_name, "YOU" if server == 0 else "OPP"]
	power_bar.value = power
	btn_spike.text = "POWER\nSMASH" if power >= 100.0 else "SPIKE"
	btn_spike.add_theme_font_size_override("font_size", 26 if power >= 100.0 else 34)

func _hint(t: String) -> void:
	lbl_hint.text = t

func say(t: String, dur := 1.2) -> void:
	if t == "":
		return
	lbl_say.text = t
	lbl_say.pivot_offset = lbl_say.size / 2.0
	lbl_say.modulate.a = 1.0
	lbl_say.scale = Vector2(1.5, 1.5)
	if say_tw != null and say_tw.is_valid():
		say_tw.kill()
	say_tw = create_tween()
	say_tw.tween_property(lbl_say, "scale", Vector2.ONE, 0.18)
	say_tw.tween_interval(dur)
	say_tw.tween_property(lbl_say, "modulate:a", 0.0, 0.35)

func _update_buttons() -> void:
	var rel := {"pass": btn_pass, "set": btn_set, "dump": btn_dump, "spike": btn_spike}
	var open := flying and expect != "" and pressed_kind == "" and float(fl["t"]) >= float(fl["dur"]) - win_t
	var pulse := 0.85 + 0.15 * sin(t_all * 10.0)
	for k in rel.keys():
		var b: Button = rel[k]
		var is_rel := (expect == k) or (expect == "set" and k == "dump" and dump_ok)
		b.visible = true
		if k == "dump" and not dump_ok and expect != "set":
			b.modulate = Color(1, 1, 1, 0.18)
		elif is_rel:
			b.modulate = Color(pulse, pulse, pulse, 1.0) if open else Color(1, 1, 1, 0.65)
		else:
			b.modulate = Color(1, 1, 1, 0.28)
		b.disabled = not (is_rel and open and pressed_kind == "")
	tbar.active = flying and expect != "" and pressed_kind == ""
	if tbar.active:
		var dur: float = fl["dur"]
		tbar.frac = (float(fl["t"]) - (dur - win_t)) / win_t
		var ideal := (win_t - 0.15) / win_t
		tbar.zlo = clampf(ideal - 0.3, 0.0, 1.0)
		tbar.zhi = clampf(ideal + 0.3, 0.0, 1.0)

# ------------------------------------------------------------------ input
func _ground(pos: Vector2) -> Vector3:
	var o := cam.project_ray_origin(pos)
	var n := cam.project_ray_normal(pos)
	if absf(n.y) < 0.001:
		return Vector3(0, 0, -4)
	var t := -o.y / n.y
	return o + n * t

func _clamp_enemy(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, -4.3, 4.3), 0, clampf(p.z, -8.8, -0.6))

func _clamp_own(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, -4.3, 4.3), 0, clampf(p.z, 0.6, 8.8))

func _on_court_tap(pos: Vector2) -> void:
	if not serve_wait:
		return
	serve_wait = false
	court_tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	allow_sub = false
	_hint("")
	_user_serve(_ground(pos))

func _on_aim_tap(pos: Vector2) -> void:
	if aim_side == "" or aim_has:
		return
	var pt := _ground(pos)
	aim_pt = _clamp_enemy(pt) if aim_side == "enemy" else _clamp_own(pt)
	aim_has = true
	_mark(aim_pt)
	if st == "aim":
		_finish_aim()

func _mark(p: Vector3) -> void:
	marker.position = Vector3(p.x, 0.05, p.z)
	marker.visible = true
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func(): marker.visible = false)

func wait_aim(side: String, cb: Callable) -> void:
	aim_cb = cb
	aim_side = side
	aim_tap.mouse_filter = Control.MOUSE_FILTER_STOP
	if aim_has:
		_finish_aim()
		return
	_hint("Touch anywhere on %s court to aim!" % ("the OPPONENT's" if side == "enemy" else "YOUR"))
	st = "aim"
	aim_t = 6.0

func _auto_aim() -> void:
	if aim_side == "enemy":
		aim_pt = _clamp_enemy(Vector3(randf_range(-3.0, 3.0), 0, -4.5))
	else:
		aim_pt = _clamp_own(Vector3(randf_range(-3.0, 3.0), 0, 3.0))
	aim_has = true
	_finish_aim()

func _finish_aim() -> void:
	_hint("")
	var cb := aim_cb
	aim_side = ""
	aim_has = false
	aim_tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st = "idle"
	cb.call(aim_pt)

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
	aim_has = false
	aim_side = "own" if kind == "set" else ("enemy" if kind == "spike" or kind == "dump" else "")
	if aim_side != "":
		aim_tap.mouse_filter = Control.MOUSE_FILTER_STOP
		_hint("Touch anywhere on %s court to aim!" % ("the OPPONENT's" if aim_side == "enemy" else "YOUR"))
	if actor != null:
		match kind:
			"pass":
				actor.play("receive", 0.6)
			"set", "dump":
				actor.play("set", 0.5)
				actor.jump(0.3, 0.45)
			"spike":
				actor.play("spike", 0.65)
				actor.jump(0.85, 0.65)
	say("PERFECT!" if q > 0.8 else ("GOOD" if q > 0.5 else "OK"), 0.35)
	G.sfx("pass" if kind == "pass" else ("set" if kind == "set" or kind == "dump" else "hit"))

# ------------------------------------------------------------------ main loop
func wait(t: float, cb: Callable) -> void:
	wait_t = t
	wait_cb = cb
	st = "wait"

func fly_to(a: Vector3, b: Vector3, dur: float, h: float, cb: Callable, ex := "", win := 0.9) -> void:
	var d := dur * (1.4 if tut_mode else 1.0)
	fl = {"a": a, "b": b, "dur": d, "h": h, "t": 0.0}
	flight_cb = cb
	expect = ex
	win_t = minf(win * (1.25 if tut_mode else 1.0), d)
	pressed_kind = ""
	press_q = 0.0
	tut_asked = false
	flying = true
	ball_hold = null
	st = "flight"
	if ex != "":
		ring.position = Vector3(b.x, 0.04, b.z)
		ring.visible = true

func _cb_end(_res: Dictionary) -> void:
	end_rally(int(ctx["w"]), String(ctx["msg"]))

func fly_end(a: Vector3, b: Vector3, dur: float, h: float, w: int, msg: String) -> void:
	ctx["w"] = w
	ctx["msg"] = msg
	fly_to(a, b, dur, h, _cb_end)

func _process(delta: float) -> void:
	t_all += delta
	_update_buttons()
	_update_visuals(delta)
	if sub_panel != null or ended:
		return
	st_t += delta
	match st:
		"intro":
			if st_t > 1.4:
				start_rally()
		"wait":
			wait_t -= delta
			if wait_t <= 0.0:
				var cb := wait_cb
				st = "idle"
				cb.call()
		"flight":
			_tick_flight(delta)
		"aim":
			aim_t -= delta
			if aim_t <= 0.0:
				_auto_aim()

func _tick_flight(delta: float) -> void:
	if not tut_hold:
		fl["t"] = float(fl["t"]) + delta
	var dur: float = fl["dur"]
	var tt: float = fl["t"]
	var s := minf(tt, dur) / dur
	var a: Vector3 = fl["a"]
	var b: Vector3 = fl["b"]
	var pos := a.lerp(b, s)
	pos.y = lerpf(a.y, b.y, s) + 4.0 * float(fl["h"]) * s * (1.0 - s)
	ball.position = pos
	ball.rotation.x += delta * 9.0
	trail_acc += delta
	if trail_acc > 0.03 and not tut_hold:
		trail_acc = 0.0
		var g: MeshInstance3D = trail[trail_i]
		g.position = pos
		g.visible = true
		trail_a[trail_i] = 1.0
		trail_i = (trail_i + 1) % trail.size()
	if G.tut_active and expect != "" and not tut_asked and tt >= dur - 0.8:
		tut_asked = true
		var nm := "btn_" + expect
		if G.tut != null and G.tut.game_request(nm):
			tut_hold = true
			hold_wd = 0.0
	if tut_hold:
		if G.tut == null or not G.tut.visible:
			hold_wd += delta
			if hold_wd > 2.0:
				tut_hold = false
		else:
			hold_wd = 0.0
	if tt >= dur + (0.12 if expect != "" else 0.0) and not tut_hold:
		flying = false
		ring.visible = false
		var res := {"kind": pressed_kind, "q": press_q}
		expect = ""
		st = "idle"
		var cb := flight_cb
		cb.call(res)

func _update_visuals(delta: float) -> void:
	if ball_hold != null and is_instance_valid(ball_hold):
		ball.position = ball_hold.position + Vector3(0, 1.35 + 0.2 * sin(t_all * 6.0), -0.1)
	shadow.position = Vector3(ball.position.x, 0.02, ball.position.z)
	var k := 1.0 / (1.0 + ball.position.y * 0.2)
	shadow.scale = Vector3(k, 1, k)
	for i in trail.size():
		var a: float = trail_a[i]
		if a > 0.0:
			a = maxf(0.0, a - delta * 2.6)
			trail_a[i] = a
			var g: MeshInstance3D = trail[i]
			var m: StandardMaterial3D = g.material_override
			m.albedo_color = Color(1, 1, 1, a * 0.4)
			g.visible = a > 0.02
	if ring.visible:
		var pp := 1.0 + 0.12 * sin(t_all * 9.0)
		ring.scale = Vector3(pp, 1, pp)
	crowd_e = lerpf(crowd_e, 0.3, delta * 0.4)
	crowd_acc += delta
	if crowd_acc > 0.066:
		crowd_acc = 0.0
		_crowd_update()
	if mascot != null:
		mascot.position.y = absf(sin(t_all * 3.2)) * 0.3
		for i in mascot_arms.size():
			var arm: Node3D = mascot_arms[i]
			arm.rotation.z = (2.3 + sin(t_all * 9.0 + float(i)) * 0.5) * (1.0 if i == 0 else -1.0)
	for r in refs:
		var rp: Player3D = r
		var d := Vector3(ball.position.x - rp.position.x, 0, ball.position.z - rp.position.z)
		rp.home_yaw = atan2(-d.x, -d.z)

func _shake() -> void:
	var base := cam.position
	var tw := create_tween()
	for i in 4:
		tw.tween_property(cam, "position", base + Vector3(randf_range(-0.25, 0.25), randf_range(-0.15, 0.15), randf_range(-0.2, 0.2)), 0.04)
	tw.tween_property(cam, "position", base, 0.05)

# ------------------------------------------------------------------ rally: serving
func start_rally() -> void:
	ctx = {}
	allow_sub = true
	G.sfx("whistle")
	if server == 0:
		actor = my_pl[int(my[5])]
		_hint("Touch the opponent's court to serve!")
		st = "serve_wait"
		serve_wait = true
		court_tap.mouse_filter = Control.MOUSE_FILTER_STOP
		if G.tut_active and G.tut != null:
			G.tut.game_request("court")
	else:
		var sn: Player3D = ai_pl[5]
		sn.go_to(Vector3(sn.position.x, 0, -SERVE_Z), 8.0)
		ball_hold = sn
		wait(1.5, _ai_serve_hit)

func _user_serve(tgt: Vector3) -> void:
	var sid := int(my[5])
	var sp: Player3D = my_pl[sid]
	actor = sp
	var tf := _tf()
	var srv := ms(sid, "srv")
	tgt.x = clampf(tgt.x, -5.0, 5.0)
	tgt.z = clampf(tgt.z, -9.6, -1.0)
	if not tf:
		var err := (100.0 - srv) / 100.0 * 2.4
		tgt.x += randf_range(-err, err)
		tgt.z += randf_range(-err, err)
	ctx["tgt"] = tgt
	ctx["net"] = (not tf) and randf() < maxf(0.0, (62.0 - srv) / 320.0)
	ctx["sx"] = sp.position.x
	sp.go_to(Vector3(sp.position.x, 0, SERVE_Z), 8.0)
	ball_hold = sp
	wait(1.2, _user_serve_hit)

func _user_serve_hit() -> void:
	actor.play("serve", 0.8)
	wait(0.5, _user_serve_fly)

func _user_serve_fly() -> void:
	G.sfx("hit")
	ball_hold = null
	var sx: float = ctx["sx"]
	var hand := Vector3(sx, 2.6, SERVE_Z)
	var tgt: Vector3 = ctx["tgt"]
	if bool(ctx["net"]):
		fly_end(hand, Vector3(sx * 0.5, 0.0, 0.5), 1.0, 2.0, 1, "NET!")
	else:
		fly_to(hand, tgt, 1.7, 4.5, _on_serve_land)

func _on_serve_land(_res: Dictionary) -> void:
	var tgt: Vector3 = ctx["tgt"]
	if absf(tgt.x) > 4.5 or tgt.z < -9.0 or tgt.z > -0.1:
		end_rally(1, "OUT!")
		return
	ai_receive(tgt, false)

func _ai_serve_hit() -> void:
	(ai_pl[5] as Player3D).play("serve", 0.8)
	wait(0.5, _ai_serve_fly)

func _ai_serve_fly() -> void:
	G.sfx("hit")
	ball_hold = null
	var sn: Player3D = ai_pl[5]
	var hand := Vector3(sn.position.x, 2.6, -SERVE_Z)
	var srv: float = ai_s["srv"]
	var err := (100.0 - srv) / 100.0 * 2.0
	var tgt := Vector3(randf_range(-3.8, 3.8) + randf_range(-err, err), 0.0, randf_range(1.8, 8.2) + randf_range(-err, err))
	if absf(tgt.x) > 4.5 or tgt.z > 9.0 or tgt.z < 0.2:
		fly_end(hand, tgt, 1.7, 4.5, 0, "Opponent serve is OUT!")
		return
	var ri := _nearest(0, tgt)
	var d := _slot_pos(ri, 0).distance_to(Vector3(tgt.x, 0, tgt.z))
	var reach := 1.6 + ms(int(my[ri]), "rec") / 100.0 * 1.2
	if d > reach:
		fly_end(hand, tgt, 1.7, 4.5, 1, "ACE against you!")
		return
	user_receive(hand, tgt, 1.7, 4.5)

# ------------------------------------------------------------------ rally: my side
func user_receive(from: Vector3, land: Vector3, dur: float, h: float) -> void:
	var ri := _nearest(0, land)
	var id := int(my[ri])
	var pl: Player3D = my_pl[id]
	actor = pl
	var gp := Vector3(land.x, 0.0, land.z)
	var dd := pl.position.distance_to(gp)
	var total := dur * (1.4 if tut_mode else 1.0)
	pl.go_to(gp, clampf(dd / (total * 0.75), 4.0, 12.0))
	_hint("Tap PASS when the marker reaches the green zone!")
	fly_to(from, Vector3(land.x, 0.6, land.z), dur, h, _on_user_receive.bind(id, land), "pass", _win())

func _on_user_receive(res: Dictionary, id: int, land: Vector3) -> void:
	_hint("")
	var tf := _tf()
	if res["kind"] != "pass":
		end_rally(1, "MISSED!")
		return
	var q: float = res["q"]
	var ok := tf or randf() < clampf(0.40 + q * 0.5 + ms(id, "rec") / 300.0, 0.15, 0.97)
	if not ok:
		end_rally(1, "Bad pass!")
		return
	power = minf(100.0, power + 8.0)
	_hud()
	if q < 0.3 and not tf:
		var tgt := Vector3(randf_range(-3.5, 3.5), 0.0, randf_range(-8.0, -2.0))
		say("Free ball!")
		fly_to(Vector3(land.x, 1.0, land.z), tgt, 1.5, 5.0, _on_free_land.bind(tgt))
		return
	user_set(Vector3(land.x, 1.0, land.z), q)

func _on_free_land(_res: Dictionary, tgt: Vector3) -> void:
	ai_receive(tgt, true)

func user_set(from: Vector3, pq: float) -> void:
	var sid := _setter_id()
	var sp: Player3D = my_pl[sid]
	actor = sp
	sp.go_to(Vector3(2.0, 0.0, 1.9), 9.0)
	dump_ok = G.players[sid]["pos"] == "S"
	_hint("Tap SET" + (" (or DUMP)" if dump_ok else "") + " in the green zone!")
	fly_to(from, Vector3(2.0, 2.3, 1.9), 1.0, 3.5, _on_user_set.bind(sid, pq), "set", _win())

func _on_user_set(res: Dictionary, sid: int, pq: float) -> void:
	_hint("")
	dump_ok = false
	var kind: String = res["kind"]
	if kind == "":
		end_rally(1, "Nobody set it!")
		return
	var q: float = res["q"]
	if kind == "dump":
		wait_aim("enemy", _on_dump_aim.bind(sid, q))
	else:
		wait_aim("own", _on_set_aim.bind(sid, q))

func _on_dump_aim(ap: Vector3, sid: int, q: float) -> void:
	var derr := 1.0 - q
	var tp := _clamp_enemy(ap + Vector3(randf_range(-derr, derr), 0.0, randf_range(-derr, derr)))
	var dd := _slot_pos(_nearest(1, tp), 1).distance_to(tp)
	var p_s := clampf((0.28 + q * 0.25 + ms(sid, "set") / 400.0 - float(ai_s["blk"]) / 500.0) * (0.6 + dd / 3.0), 0.12, 0.8)
	var ok := _tf() or randf() < p_s
	fly_to(Vector3(2.0, 2.6, 1.5), tp, 0.55, 0.6, _on_dump_land.bind(tp, ok))

func _on_dump_land(_res: Dictionary, tp: Vector3, ok: bool) -> void:
	if ok:
		G.sfx("cheer", 0.6)
		end_rally(0, "DUMP!")
	else:
		ai_receive(tp, true)

func _on_set_aim(ap: Vector3, sid: int, q: float) -> void:
	var hid := _pick_hitter(sid, ap.x)
	var hx := _slot_pos(my.find(hid), 0).x * 0.8
	var hp: Player3D = my_pl[hid]
	actor = hp
	hp.go_to(Vector3(hx, 0.0, 2.7), 10.0)
	_hint("Tap SPIKE in the green zone!")
	fly_to(Vector3(2.0, 2.3, 1.9), Vector3(hx, 2.9, 1.6), 1.0, 4.0, _on_user_spike.bind(hid, hx, q), "spike", _win())

func _on_user_spike(res: Dictionary, hid: int, hx: float, sqset: float) -> void:
	_hint("")
	if res["kind"] != "spike":
		end_rally(1, "No spike!")
		return
	var sq: float = res["q"]
	G.mis("spike", 1)
	if sq < 0.12 and not _tf():
		end_rally(1, "Hit the net!")
		return
	G.sfx("spike")
	wait_aim("enemy", _on_spike_aim.bind(hid, hx, sqset, sq))

func _on_spike_aim(ap: Vector3, hid: int, hx: float, sqset: float, sq: float) -> void:
	var tf := _tf()
	var big := power_on
	power_on = false
	var pw := ms(hid, "spk") * 0.6 + sqset * 12.0 + sq * 28.0 + (45.0 if big else 0.0)
	var from := Vector3(hx, 2.9, 1.6)
	var pb := clampf(0.10 + (float(ai_s["blk"]) - pw * 0.65) / 220.0, 0.02, 0.35)
	var pd := clampf(0.38 + (float(ai_s["rec"]) - pw * 0.7) / 160.0, 0.06, 0.6)
	if big:
		pb *= 0.3
		pd *= 0.4
	var aerr := ((1.0 - sq) * 0.9 + (100.0 - ms(hid, "spk")) / 100.0 * 1.2) * 0.5
	var aimed := ap + Vector3(randf_range(-aerr, aerr), 0.0, randf_range(-aerr, aerr))
	if not tf and (absf(aimed.x) > 4.5 or aimed.z < -9.0 or aimed.z > -0.1):
		fly_end(from, aimed, 0.6, 0.4, 1, "OUT!")
		return
	var adist := _slot_pos(_nearest(1, aimed), 1).distance_to(aimed)
	pd = clampf(pd * (1.5 - adist / 2.5), 0.03, 0.7)
	var r := randf()
	if tf:
		r = 0.99
	if r < pb:
		fly_to(from, Vector3(hx, 2.4, -0.4), 0.3, 0.1, _on_blocked.bind(hx))
	elif r < pb + pd:
		fly_to(from, aimed, 0.6, 0.5, _on_ai_dug.bind(aimed))
	else:
		ctx["shake"] = true
		fly_end(from, aimed, 0.4 if big else 0.55, 0.4, 0, "POWER SMASH!" if big else "SMASH!")

func _on_blocked(_res: Dictionary, hx: float) -> void:
	say("BLOCKED!")
	G.sfx("hit")
	for i in 3:
		var bp: Player3D = ai_pl[i]
		bp.play("block", 0.5)
		bp.jump(0.55, 0.5)
	if randf() < 0.4:
		user_receive(Vector3(hx, 2.4, -0.4), Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(4.0, 8.0)), 1.3, 4.0)
	else:
		fly_end(Vector3(hx, 2.4, -0.4), Vector3(hx, 0.0, 1.0), 0.3, 0.1, 1, "")

func _on_ai_dug(_res: Dictionary, land: Vector3) -> void:
	say("Dug!", 0.6)
	var rn: Player3D = ai_pl[_nearest(1, land)]
	rn.go_to(Vector3(land.x, 0, land.z), 11.0)
	rn.play("dive", 0.6)
	G.sfx("pass")
	ai_chain(land)

# ------------------------------------------------------------------ rally: opponent side
func ai_receive(land: Vector3, free: bool) -> void:
	var ri := _nearest(1, land)
	var rn: Player3D = ai_pl[ri]
	rn.go_to(Vector3(land.x, 0, land.z), 10.0)
	var d := _slot_pos(ri, 1).distance_to(Vector3(land.x, 0, land.z))
	var reach := 1.6 + float(ai_s["rec"]) / 100.0 * 1.2
	var tf := _tf()
	if not free and not tf and d > reach:
		G.sfx("cheer", 0.8)
		wait(0.6, end_rally.bind(0, "ACE!"))
		return
	var p_ok := 0.92 if free else clampf(0.55 + (float(ai_s["rec"]) - my_avg("srv")) / 200.0, 0.3, 0.9)
	if tf:
		p_ok = 1.0
	if randf() > p_ok:
		wait(0.6, end_rally.bind(0, "Receive error!"))
		return
	rn.play("receive", 0.6)
	G.sfx("pass")
	wait(0.55, ai_chain.bind(land))

func ai_chain(land: Vector3) -> void:
	var setter: Player3D = ai_pl[5]
	setter.go_to(Vector3(-2.0, 0, -2.0), 9.0)
	var hslot := randi() % 3
	var hx := _slot_pos(hslot, 1).x * 0.8
	ctx["hslot"] = hslot
	ctx["hx"] = hx
	(ai_pl[hslot] as Player3D).go_to(Vector3(hx, 0, -2.8), 9.0)
	fly_to(Vector3(land.x, 1.0, land.z), Vector3(-2.0, 2.3, -2.0), 0.95, 3.5, _cb_ai_set)

func _cb_ai_set(_res: Dictionary) -> void:
	var setter: Player3D = ai_pl[5]
	setter.play("set", 0.5)
	setter.jump(0.25, 0.45)
	G.sfx("set")
	var hx: float = ctx["hx"]
	fly_to(Vector3(-2.0, 2.3, -2.0), Vector3(hx, 2.9, -1.6), 0.95, 4.0, _cb_ai_spike)

func _cb_ai_spike(_res: Dictionary) -> void:
	var hslot: int = ctx["hslot"]
	var hx: float = ctx["hx"]
	var hp: Player3D = ai_pl[hslot]
	hp.play("spike", 0.6)
	hp.jump(0.8, 0.6)
	G.sfx("spike")
	var hit := Vector3(hx, 2.9, -1.6)
	var aspk: float = ai_s["spk"]
	var diff := int(G.save["diff"])
	var mdef := my_avg("blk") * 0.4 + my_avg("rec") * 0.6
	var pe: float = 0.07 + [0.06, 0.0, -0.03][diff]
	var pk := clampf(0.10 + (aspk - mdef) / 230.0 + [-0.05, 0.0, 0.06][diff], 0.04, 0.36)
	var pb := clampf(0.08 + (my_avg("blk") - aspk) / 260.0, 0.02, 0.25)
	var r := randf()
	if _tf():
		r = 0.99
		pe = 0.0
		pk = 0.0
		pb = 0.0
	if r < pe:
		fly_end(hit, Vector3(hx, 0.0, -0.3), 0.5, 0.2, 0, "Opponent error!")
	elif r < pe + pb:
		fly_to(hit, Vector3(hx, 2.4, -0.2), 0.3, 0.1, _on_my_block.bind(hx))
	elif r < pe + pb + pk:
		ctx["shake"] = true
		fly_end(hit, Vector3(randf_range(-4.2, 4.2), 0.0, 4.7), 0.6, 0.4, 1, "Spiked!")
	else:
		var ti := randi() % 6
		var tp := _slot_pos(ti, 0) + Vector3(randf_range(-0.6, 0.6), 0.0, randf_range(-0.6, 0.6))
		user_receive(hit, tp, 1.1, 0.8)

func _on_my_block(_res: Dictionary, hx: float) -> void:
	say("BLOCK!")
	G.sfx("hit")
	for i in 3:
		var bp: Player3D = my_pl[int(my[i])]
		bp.play("block", 0.5)
		bp.jump(0.55, 0.5)
	if randf() < 0.6:
		fly_end(Vector3(hx, 2.4, -0.2), Vector3(hx, 0.0, -1.0), 0.3, 0.1, 0, "")
	else:
		var land := Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-8.0, -3.5))
		fly_to(Vector3(hx, 2.4, -0.2), land, 1.2, 4.0, _on_ai_dug.bind(land))

# ------------------------------------------------------------------ points + flow
func end_rally(w: int, msg: String) -> void:
	st = "point"
	flying = false
	ring.visible = false
	say(msg, 1.4)
	score[w] += 1
	for r in refs:
		(r as Player3D).play("ref_l" if w == 0 else "ref_r", 1.6)
	if w == 0:
		power = minf(100.0, power + 20.0)
		G.mis("score", 1)
		G.sfx("point")
		crowd_e = 1.0
		if server == 1:
			my = G.rot(my)
			server = 0
		for id in my:
			(my_pl[int(id)] as Player3D).play("celebrate", 1.6)
		for p in ai_pl:
			(p as Player3D).play("sad", 1.6)
	else:
		G.sfx("lose")
		crowd_e = 0.6
		server = 1
		for p in ai_pl:
			(p as Player3D).play("celebrate", 1.6)
		for id in my:
			(my_pl[int(id)] as Player3D).play("sad", 1.6)
	_hud()
	if bool(ctx.get("shake", false)):
		_shake()
	wait(2.0, _after_point)

func _after_point() -> void:
	if _is_over():
		_finish()
		return
	_home_all()
	allow_sub = true
	wait(1.0, start_rally)

func _is_over() -> bool:
	var a: int = score[0]
	var b: int = score[1]
	if (a >= target_pts or b >= target_pts) and absi(a - b) >= 2:
		return true
	return a >= target_pts + 4 or b >= target_pts + 4

func _finish() -> void:
	ended = true
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
	for id in my:
		(my_pl[int(id)] as Player3D).play("celebrate" if won else "sad", 8.0)

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
		cv.pressed.connect(_sub_pick.bind(i))
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
		bc.pressed.connect(_sub_swap.bind(int(id)))
		hb.add_child(bc)
	var cl := G.mk_btn("Close", Color.html("#2b6cff"), Vector2(220, 60), "", 26)
	cl.pressed.connect(_sub_close)
	v.add_child(cl)

func _sub_pick(i: int) -> void:
	sub_sel = i
	_sub_refresh()

func _sub_close() -> void:
	if sub_panel != null:
		sub_panel.queue_free()
		sub_panel = null

func _sub_swap(new_id: int) -> void:
	if sub_sel < 0:
		_hint("Select a lineup player first.")
		return
	var old_id := int(my[sub_sel])
	var old_pl: Player3D = my_pl[old_id]
	old_pl.queue_free()
	my_pl.erase(old_id)
	my[sub_sel] = new_id
	my_pl[new_id] = _new_my_player(new_id, sub_sel)
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
	y.pressed.connect(_quit_now)
	h.add_child(y)
	var n := G.mk_btn("Keep Playing", Color.html("#27a85a"), Vector2(240, 64))
	n.pressed.connect(_sub_close)
	h.add_child(n)

func _quit_now() -> void:
	ended = true
	exit.emit(false)
