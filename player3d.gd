class_name Player3D
extends Node3D
# Procedural volleyball player (no external models). Developer: Sano
# Joint order: 0 shL 1 shR 2 elL 3 elR 4 hipL 5 hipR 6 knL 7 knR 8 torso 9 bodyPitch 10 hipDrop

var body: Node3D
var hips: Node3D
var torso: Node3D
var sh_l: Node3D
var sh_r: Node3D
var el_l: Node3D
var el_r: Node3D
var hp_l: Node3D
var hp_r: Node3D
var kn_l: Node3D
var kn_r: Node3D

var has_target := false
var target := Vector3.ZERO
var speed := 7.0
var face_y := 0.0
var home_yaw := 0.0
var t := 0.0
var pose := "idle"
var pose_t := 0.0
var pose_d := 0.0
var jump_h := 0.0
var jump_t := 0.0
var jump_d := 0.0
var moving := false
var cur: Array = [35.0, 35.0, 40.0, 40.0, 18.0, 18.0, -32.0, -32.0, -8.0, 0.0, 0.05]

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m

func _mesh(parent: Node3D, mesh: Mesh, col: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(col)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	return c

func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s

func _box(sz: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = sz
	return b

func setup(shirt: Color, shorts: Color, skin: Color, hair: Color, hair_style: int, num: int, yaw := 0.0) -> Player3D:
	home_yaw = yaw
	face_y = yaw
	rotation.y = yaw
	body = Node3D.new()
	add_child(body)
	hips = Node3D.new()
	hips.position = Vector3(0, 0.95, 0)
	body.add_child(hips)
	_mesh(hips, _box(Vector3(0.36, 0.22, 0.24)), shorts, Vector3(0, -0.02, 0))
	torso = Node3D.new()
	hips.add_child(torso)
	var chest := _mesh(torso, _cap(0.19, 0.62), shirt, Vector3(0, 0.33, 0))
	chest.scale = Vector3(1.0, 1.0, 0.68)
	_mesh(torso, _cap(0.05, 0.16), skin, Vector3(0, 0.66, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.79, 0)
	torso.add_child(head)
	_mesh(head, _sph(0.115), skin)
	var hr := _mesh(head, _sph(0.123), hair, Vector3(0, 0.025, 0.012))
	hr.scale = Vector3(1.0, 0.85, 1.0)
	if hair_style == 1:
		for k in 6:
			var a := float(k) * TAU / 6.0
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.035
			cone.height = 0.12
			var sp := _mesh(head, cone, hair, Vector3(cos(a) * 0.07, 0.115, sin(a) * 0.07))
			sp.rotation = Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5)
	elif hair_style == 2:
		_mesh(head, _cap(0.09, 0.3), hair, Vector3(0, -0.07, 0.075))
	elif hair_style == 3:
		var band := CylinderMesh.new()
		band.top_radius = 0.126
		band.bottom_radius = 0.126
		band.height = 0.03
		_mesh(head, band, shirt, Vector3(0, 0.045, 0))
	for s in [-1, 1]:
		_mesh(head, _sph(0.014), Color(0.05, 0.05, 0.07), Vector3(float(s) * 0.04, 0.0, -0.107))
	var arms_l := _arm(-1.0, shirt, skin)
	sh_l = arms_l[0]
	el_l = arms_l[1]
	var arms_r := _arm(1.0, shirt, skin)
	sh_r = arms_r[0]
	el_r = arms_r[1]
	var legs_l := _leg(-1.0, skin)
	hp_l = legs_l[0]
	kn_l = legs_l[1]
	var legs_r := _leg(1.0, skin)
	hp_r = legs_r[0]
	kn_r = legs_r[1]
	var back := Label3D.new()
	back.text = str(num)
	back.font_size = 72
	back.pixel_size = 0.0045
	back.modulate = Color(1, 1, 1)
	back.outline_size = 8
	back.position = Vector3(0, 0.36, 0.135)
	torso.add_child(back)
	var tag := Label3D.new()
	tag.text = str(num)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 40
	tag.pixel_size = 0.01
	tag.no_depth_test = true
	tag.modulate = Color(1, 1, 1, 0.85)
	tag.position = Vector3(0, 2.45, 0)
	body.add_child(tag)
	return self

func _arm(side: float, shirt: Color, skin: Color) -> Array:
	var sh := Node3D.new()
	sh.position = Vector3(side * 0.27, 0.55, 0)
	torso.add_child(sh)
	_mesh(sh, _cap(0.055, 0.36), skin, Vector3(0, -0.16, 0))
	_mesh(sh, _cap(0.068, 0.17), shirt, Vector3(0, -0.07, 0))
	var el := Node3D.new()
	el.position = Vector3(0, -0.31, 0)
	sh.add_child(el)
	_mesh(el, _cap(0.045, 0.34), skin, Vector3(0, -0.15, 0))
	_mesh(el, _sph(0.052), skin, Vector3(0, -0.33, 0))
	return [sh, el]

func _leg(side: float, skin: Color) -> Array:
	var hp := Node3D.new()
	hp.position = Vector3(side * 0.1, -0.05, 0)
	hips.add_child(hp)
	_mesh(hp, _cap(0.085, 0.5), skin, Vector3(0, -0.215, 0))
	var kn := Node3D.new()
	kn.position = Vector3(0, -0.43, 0)
	hp.add_child(kn)
	_mesh(kn, _cap(0.06, 0.5), skin, Vector3(0, -0.215, 0))
	_mesh(kn, _cap(0.068, 0.26), Color(0.95, 0.95, 0.95), Vector3(0, -0.3, 0))
	_mesh(kn, _box(Vector3(0.11, 0.08, 0.27)), Color(0.12, 0.12, 0.16), Vector3(0, -0.43, -0.05))
	return [hp, kn]

# ------------------------------------------------------------------ api
func go_to(p: Vector3, spd := 7.0) -> void:
	target = Vector3(p.x, position.y, p.z)
	has_target = true
	speed = spd

func play(n: String, d := 0.6) -> void:
	pose = n
	pose_d = d
	pose_t = 0.0

func jump(h: float, d: float) -> void:
	jump_h = h
	jump_d = d
	jump_t = 0.0

func look_at_pt(p: Vector3) -> void:
	var d := p - position
	if d.length() > 0.01:
		home_yaw = atan2(-d.x, -d.z)
		face_y = home_yaw

# ------------------------------------------------------------------ pose math
func _sm(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)

func _targets() -> Array:
	var p := pose
	if p == "idle" and moving:
		p = "run"
	var u := 0.0
	if pose_d > 0.0:
		u = clampf(pose_t / pose_d, 0.0, 1.0)
	match p:
		"run":
			var s := sin(t * 13.0)
			return [25.0 - 45.0 * s, 25.0 + 45.0 * s, 60.0, 60.0, 45.0 * s, -45.0 * s,
				-maxf(0.0, -s) * 65.0 - 8.0, -maxf(0.0, s) * 65.0 - 8.0, -14.0, 0.0, 0.04 + 0.03 * absf(s)]
		"receive":
			var up := _sm((u - 0.25) / 0.2) * (1.0 - _sm((u - 0.7) / 0.3))
			var sh := 60.0 + 30.0 * up
			return [sh, sh, 0.0, 0.0, 60.0, 60.0, -95.0, -95.0, -25.0, 0.0, 0.28]
		"set":
			return [150.0, 150.0, 25.0, 25.0, 8.0, 8.0, -10.0, -10.0, 5.0, 0.0, 0.0]
		"block":
			return [172.0, 172.0, 4.0, 4.0, 5.0, 5.0, -8.0, -8.0, -3.0, 0.0, 0.0]
		"spike":
			if u < 0.4:
				var a := u / 0.4
				return [lerpf(30.0, 165.0, a), lerpf(20.0, -75.0, a), 40.0, lerpf(40.0, 110.0, a), 12.0, 12.0, -20.0, -20.0, lerpf(0.0, 14.0, a), 0.0, 0.0]
			var b := _sm((u - 0.4) / 0.3)
			return [lerpf(165.0, 60.0, b), lerpf(-75.0, 175.0, b), 40.0, lerpf(110.0, 8.0, b), 22.0, 22.0, -35.0, -35.0, lerpf(14.0, -26.0, b), 0.0, 0.0]
		"serve":
			if u < 0.4:
				var a2 := u / 0.4
				return [lerpf(35.0, 165.0, a2), lerpf(35.0, -20.0, a2), 40.0, 40.0, 14.0, 14.0, -22.0, -22.0, -4.0, 0.0, 0.05]
			if u < 0.6:
				var c := (u - 0.4) / 0.2
				return [165.0, lerpf(-20.0, -95.0, c), 20.0, lerpf(40.0, 110.0, c), 12.0, 12.0, -16.0, -16.0, lerpf(-4.0, 12.0, c), 0.0, 0.0]
			var d2 := _sm((u - 0.6) / 0.2)
			return [lerpf(165.0, 40.0, d2), lerpf(-95.0, 175.0, d2), 20.0, lerpf(110.0, 8.0, d2), 18.0, 18.0, -26.0, -26.0, lerpf(12.0, -22.0, d2), 0.0, 0.0]
		"dive":
			return [105.0, 105.0, 0.0, 0.0, 45.0, -25.0, -10.0, -45.0, -10.0, -72.0, 0.42]
		"celebrate":
			var w := sin(t * 7.0) * 12.0
			return [160.0 + w, 160.0 - w, 20.0, 20.0, 10.0, 10.0, -15.0, -15.0, 0.0, 0.0, 0.0]
		"sad":
			return [8.0, 8.0, 10.0, 10.0, 5.0, 5.0, -5.0, -5.0, -20.0, 0.0, 0.02]
		"ref_r":
			return [20.0, 175.0, 20.0, 5.0, 4.0, 4.0, -4.0, -4.0, 0.0, 0.0, 0.0]
		"ref_l":
			return [175.0, 20.0, 5.0, 20.0, 4.0, 4.0, -4.0, -4.0, 0.0, 0.0, 0.0]
	var sw := sin(t * 2.2) * 3.0
	return [35.0 + sw, 35.0 - sw, 40.0, 40.0, 18.0, 18.0, -32.0, -32.0, -8.0, 0.0, 0.05]

func _process(delta: float) -> void:
	t += delta
	moving = false
	if has_target:
		var d := target - position
		d.y = 0.0
		var dist := d.length()
		if dist > 0.06:
			var step := minf(speed * delta, dist)
			position += d / dist * step
			moving = true
			if pose == "idle":
				face_y = atan2(-d.x, -d.z)
		else:
			has_target = false
	if not moving and pose == "idle":
		face_y = home_yaw
	rotation.y = lerp_angle(rotation.y, face_y, 1.0 - exp(-12.0 * delta))
	if pose != "idle":
		pose_t += delta
		if pose_d > 0.0 and pose_t >= pose_d:
			pose = "idle"
			pose_d = 0.0
	var jy := 0.0
	if jump_d > 0.0:
		jump_t += delta
		var uj := clampf(jump_t / jump_d, 0.0, 1.0)
		jy = 4.0 * jump_h * uj * (1.0 - uj)
		if uj >= 1.0:
			jump_d = 0.0
	if pose == "celebrate":
		jy = maxf(jy, absf(sin(t * 7.0)) * 0.22)
	var tg := _targets()
	var k := 1.0 - exp(-16.0 * delta)
	for i in 11:
		cur[i] = lerpf(float(cur[i]), float(tg[i]), k)
	sh_l.rotation.x = deg_to_rad(float(cur[0]))
	sh_r.rotation.x = deg_to_rad(float(cur[1]))
	el_l.rotation.x = deg_to_rad(float(cur[2]))
	el_r.rotation.x = deg_to_rad(float(cur[3]))
	hp_l.rotation.x = deg_to_rad(float(cur[4]))
	hp_r.rotation.x = deg_to_rad(float(cur[5]))
	kn_l.rotation.x = deg_to_rad(float(cur[6]))
	kn_r.rotation.x = deg_to_rad(float(cur[7]))
	torso.rotation.x = deg_to_rad(float(cur[8]))
	body.rotation.x = deg_to_rad(float(cur[9]))
	body.position.y = jy
	hips.position.y = 0.95 - float(cur[10])
