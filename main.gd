extends Node
# Menus + game flow. Developer: Sano

const POSS := ["ALL", "S", "OH", "MB", "OP", "L"]
const DIFFS := ["Easy", "Normal", "Hard"]
const GFX := ["Low", "Medium", "High"]
const ROUNDS := ["Quarterfinal", "Semifinal", "Final"]
const PACKS := [
	{"n": "Bronze Pack", "price": 800, "lo": 42, "hi": 62, "star": 0.04, "leg": 0.0, "col": "#b87333"},
	{"n": "Silver Pack", "price": 2000, "lo": 58, "hi": 76, "star": 0.10, "leg": 0.0, "col": "#8d98a6"},
	{"n": "Gold Pack", "price": 5000, "lo": 70, "hi": 90, "star": 0.35, "leg": 0.12, "col": "#d9a521"},
]

var ui: CanvasLayer
var cur: Control = null
var tut: Tut
var popup: Control = null
var sel = null
var tr_tab := ""
var tr_cat := ""
var tr_items: Array = []
var tr_pos := "ALL"
var tr_min := 60
var tr_box: VBoxContainer
var team_left: VBoxContainer
var team_center: VBoxContainer
var team_bench: VBoxContainer

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.html("#0b1630"))
	ui = CanvasLayer.new()
	add_child(ui)
	var tl := CanvasLayer.new()
	tl.layer = 20
	add_child(tl)
	tut = Tut.new()
	tl.add_child(tut)
	G.apply_gfx(get_viewport())
	go("create" if String(G.save["name"]) == "" else "menu")

# ------------------------------------------------------------------ helpers
func go(n: String) -> void:
	G.targets.clear()
	close_popup()
	if cur != null:
		cur.queue_free()
	cur = Control.new()
	cur.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(cur)
	cur.add_child(MenuBG.new() if (n == "menu" or n == "create") else G.mk_bg())
	G.play_amb(false)
	G.play_music("bgm_menu")
	call("_s_" + n)

func close_popup() -> void:
	if popup != null and is_instance_valid(popup):
		popup.queue_free()
	popup = null

func _modal(content: Control) -> void:
	close_popup()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	var pan := G.mk_panel(Color(0.07, 0.11, 0.25, 0.99), 20)
	pan.add_child(content)
	c.add_child(pan)
	cur.add_child(dim)
	popup = dim

func _popup(title: String, body: String, btn := "OK") -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	var t := G.mk_label(title, 36, Color.html("#ffc43a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b := G.mk_label(body, 26)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	var ok := G.mk_btn(btn, Color.html("#27a85a"), Vector2(260, 64))
	ok.pressed.connect(close_popup)
	v.add_child(ok)
	_modal(v)

func _full(margin := 20) -> MarginContainer:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, margin)
	cur.add_child(m)
	return m

func _coin_box() -> PanelContainer:
	var pan := G.mk_panel(Color(0.05, 0.09, 0.2, 0.9), 14)
	var h := HBoxContainer.new()
	pan.add_child(h)
	var ic := TextureRect.new()
	ic.texture = load("res://icons/coin.png")
	ic.custom_minimum_size = Vector2(40, 40)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(ic)
	var l := G.mk_label(str(int(G.save["coins"])), 30, Color.html("#ffd84a"))
	h.add_child(l)
	G.coins_changed.connect(func():
		if is_instance_valid(l):
			l.text = str(int(G.save["coins"])))
	G.targets["coin"] = pan
	return pan

func _screen(title: String, back_to: String) -> VBoxContainer:
	var m := _full(18)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var b := G.mk_btn("Back", Color.html("#4a5a8a"), Vector2(150, 60), "back", 24)
	b.pressed.connect(func(): go(back_to))
	h.add_child(b)
	G.targets["back"] = b
	var tp := G.mk_panel(Color(0.06, 0.1, 0.24, 0.9), 14)
	tp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := G.mk_label(title, 36, Color.html("#ffc43a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tp.add_child(t)
	h.add_child(tp)
	h.add_child(_coin_box())
	return v

func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s

func _clear(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()

# ------------------------------------------------------------------ create team
func _s_create() -> void:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	cur.add_child(c)
	var pan := G.mk_panel(Color(0.07, 0.11, 0.25, 0.97), 22)
	c.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.custom_minimum_size = Vector2(560, 0)
	pan.add_child(v)
	var logo := TextureRect.new()
	logo.texture = load("res://icons/logo.png")
	logo.custom_minimum_size = Vector2(150, 150)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(logo)
	var t := G.mk_label("Create A Team", 44, Color.html("#ffc43a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(G.mk_label("Team Name :", 28))
	var le := LineEdit.new()
	le.placeholder_text = "Enter team name"
	le.max_length = 16
	le.custom_minimum_size = Vector2(0, 70)
	le.add_theme_font_size_override("font_size", 30)
	v.add_child(le)
	var err := G.mk_label("", 22, Color.html("#ff6a5a"))
	v.add_child(err)
	var b := G.mk_btn("Continue", Color.html("#27a85a"), Vector2(0, 76), "", 32)
	b.pressed.connect(func():
		var nm := le.text.strip_edges()
		if nm.length() < 3:
			err.text = "Team name must be 3-16 characters."
			return
		G.save["name"] = nm
		G.write()
		go("menu"))
	v.add_child(b)

# ------------------------------------------------------------------ main menu
func _s_menu() -> void:
	var m := _full(22)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var pp := G.mk_panel(Color(0.05, 0.09, 0.2, 0.9), 14)
	pp.add_child(G.mk_label("%s  |  Lv %d" % [String(G.save["name"]), G.plevel()], 30))
	top.add_child(pp)
	G.targets["profile"] = pp
	top.add_child(_spacer())
	top.add_child(_coin_box())
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 20)
	v.add_child(mid)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 14)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(left)
	var bt := G.mk_btn("Transfer", Color.html("#e8872f"), Vector2(290, 84), "transfer", 30)
	bt.pressed.connect(func(): go("transfer"))
	left.add_child(bt)
	G.targets["btn_transfer"] = bt
	var bs := G.mk_btn("Setting", Color.html("#5a6a9a"), Vector2(290, 84), "setting", 30)
	bs.pressed.connect(func(): go("setting"))
	left.add_child(bs)
	var btm := G.mk_btn("Team", Color.html("#2b6cff"), Vector2(290, 84), "team", 30)
	btm.pressed.connect(func(): go("team"))
	left.add_child(btm)
	G.targets["btn_team"] = btm
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(center)
	var mascot := Mascot2D.new()
	mascot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(mascot)
	var tt := G.mk_label("VOLLY SUPERSTARS", 54, Color.html("#ffc43a"))
	tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(tt)
	var by := G.mk_label("Developer: Sano", 22, Color(1, 1, 1, 0.7))
	by.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(by)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(right)
	var sh := G.mk_btn("Shop", Color.html("#9a4bd6"), Vector2(250, 84), "shop", 28)
	sh.pressed.connect(func(): go("shop"))
	right.add_child(sh)
	G.targets["btn_shop"] = sh
	var ms := G.mk_btn("Missions", Color.html("#27a85a"), Vector2(250, 84), "mission", 28)
	ms.pressed.connect(func(): go("mission"))
	right.add_child(ms)
	var dl := G.mk_btn("Daily", Color.html("#d6456a"), Vector2(250, 84), "daily", 28)
	dl.pressed.connect(_daily_info)
	right.add_child(dl)
	var bot := HBoxContainer.new()
	bot.alignment = BoxContainer.ALIGNMENT_CENTER
	bot.add_theme_constant_override("separation", 30)
	v.add_child(bot)
	var st := G.mk_btn("Story Mode", Color.html("#2b8cff"), Vector2(400, 100), "story", 36)
	st.pressed.connect(func(): go("story"))
	bot.add_child(st)
	G.targets["btn_story"] = st
	var tb := G.mk_btn("Tournament", Color.html("#e8452f"), Vector2(400, 100), "tournament", 36)
	tb.pressed.connect(func(): go("tour"))
	bot.add_child(tb)
	call_deferred("_after_menu")

func _after_menu() -> void:
	if not bool(G.save["tut"]):
		if not G.tut_active:
			tut.start()
	elif popup == null:
		_check_daily()

func _check_daily() -> void:
	var t := G.today()
	if int(G.save["day"]) == t:
		return
	var streak := 1
	if int(G.save["day"]) == t - 1:
		streak = int(G.save["streak"]) + 1
	G.save["streak"] = streak
	G.save["day"] = t
	var reward := 200 + 100 * mini(streak, 7)
	G.add_coins(reward)
	G.sfx("coin")
	_popup("Daily Reward", "Login streak: %d day(s)\n+%d coins" % [streak, reward], "Claim")

func _daily_info() -> void:
	_popup("Daily Reward", "Log in every day for bigger rewards!\nCurrent streak: %d day(s)\nMax bonus at 7 days." % int(G.save["streak"]))

# ------------------------------------------------------------------ settings
func _s_setting() -> void:
	var v := _screen("Setting", "menu")
	var pan := G.mk_panel()
	pan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(pan)
	var g := VBoxContainer.new()
	g.add_theme_constant_override("separation", 16)
	pan.add_child(g)
	g.add_child(G.mk_label("Music Volume", 26))
	var s1 := HSlider.new()
	s1.min_value = 0.0
	s1.max_value = 1.0
	s1.step = 0.05
	s1.value = float(G.save["mus"])
	s1.custom_minimum_size = Vector2(0, 40)
	s1.value_changed.connect(func(x: float):
		G.save["mus"] = x
		G.apply_volume()
		G.write())
	g.add_child(s1)
	g.add_child(G.mk_label("Effects Volume", 26))
	var s2 := HSlider.new()
	s2.min_value = 0.0
	s2.max_value = 1.0
	s2.step = 0.05
	s2.value = float(G.save["sfx"])
	s2.custom_minimum_size = Vector2(0, 40)
	s2.value_changed.connect(func(x: float):
		G.save["sfx"] = x
		G.write())
	g.add_child(s2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	g.add_child(row)
	var bg := G.mk_btn("Graphics: " + GFX[int(G.save["gfx"])], Color.html("#2b6cff"), Vector2(300, 64))
	bg.pressed.connect(func():
		G.save["gfx"] = (int(G.save["gfx"]) + 1) % 3
		G.write()
		G.apply_gfx(get_viewport())
		bg.text = "Graphics: " + GFX[int(G.save["gfx"])])
	row.add_child(bg)
	var bd := G.mk_btn("Difficulty: " + DIFFS[int(G.save["diff"])], Color.html("#e8872f"), Vector2(320, 64))
	bd.pressed.connect(func():
		G.save["diff"] = (int(G.save["diff"]) + 1) % 3
		G.write()
		bd.text = "Difficulty: " + DIFFS[int(G.save["diff"])])
	row.add_child(bd)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 14)
	g.add_child(row2)
	var bt := G.mk_btn("Replay Tutorial", Color.html("#27a85a"), Vector2(300, 64))
	bt.pressed.connect(func():
		G.save["tut"] = false
		G.write()
		go("menu"))
	row2.add_child(bt)
	var br := G.mk_btn("Reset All Data", Color.html("#c0392b"), Vector2(320, 64))
	br.pressed.connect(_confirm_reset)
	row2.add_child(br)
	g.add_child(G.mk_label("Volly Superstars  |  Developer: Sano  |  Offline game", 22, Color(1, 1, 1, 0.6)))

func _confirm_reset() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.add_child(G.mk_label("Delete ALL progress?\nThis cannot be undone.", 30))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var y := G.mk_btn("Delete", Color.html("#c0392b"), Vector2(200, 64))
	y.pressed.connect(func():
		G.reset_all()
		go("create"))
	h.add_child(y)
	var n := G.mk_btn("Cancel", Color.html("#4a5a8a"), Vector2(200, 64))
	n.pressed.connect(close_popup)
	h.add_child(n)
	_modal(v)

# ------------------------------------------------------------------ team
func _s_team() -> void:
	sel = null
	var v := _screen("%s's Teams" % String(G.save["name"]), "menu")
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	v.add_child(body)
	var lp := G.mk_panel()
	lp.custom_minimum_size = Vector2(290, 0)
	body.add_child(lp)
	team_left = VBoxContainer.new()
	team_left.add_theme_constant_override("separation", 10)
	lp.add_child(team_left)
	var cc := CenterContainer.new()
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(cc)
	team_center = VBoxContainer.new()
	cc.add_child(team_center)
	var rp := G.mk_panel()
	rp.custom_minimum_size = Vector2(200, 0)
	body.add_child(rp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rp.add_child(sc)
	team_bench = VBoxContainer.new()
	team_bench.add_theme_constant_override("separation", 8)
	sc.add_child(team_bench)
	_team_refresh()

func _sel_id() -> int:
	if sel == null:
		return -1
	if sel["t"] == "line":
		return int(G.save["lineup"][int(sel["i"])])
	return int(sel["id"])

func _team_refresh() -> void:
	_clear(team_left)
	_clear(team_center)
	_clear(team_bench)
	var rating := G.team_rating()
	var tl := G.mk_label("Teams", 34, Color.html("#ffc43a"))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_left.add_child(tl)
	team_left.add_child(G.mk_label("Team Rating", 22))
	var sb := StarBar.new().setup(rating, 24.0)
	sb.custom_minimum_size = Vector2(240, 24)
	team_left.add_child(sb)
	team_left.add_child(G.mk_label("%.1f / 10" % rating, 24, Color.html("#ffd84a")))
	var chem := 0
	for id in G.save["lineup"]:
		chem += G.cbonus(G.players[int(id)], G.save["lineup"])
	team_left.add_child(G.mk_label("Chemistry: " + ("ACTIVE" if chem > 0 else "none (3+ same country)"), 18, Color.html("#7dff9a") if chem > 0 else Color(1, 1, 1, 0.6)))
	var first := int(G.save["first"])
	var fname := "Auto"
	if first >= 0 and G.save["lineup"].has(first):
		fname = String(G.players[first]["name"])
	var bf := G.mk_btn("First Server:\n" + fname, Color.html("#2b6cff"), Vector2(0, 84), "", 20)
	bf.pressed.connect(_pick_server)
	team_left.add_child(bf)
	var ba := G.mk_btn("Auto Lineup", Color.html("#27a85a"), Vector2(0, 64), "", 24)
	ba.pressed.connect(func():
		G.auto_lineup()
		sel = null
		G.sfx("card")
		_team_refresh())
	team_left.add_child(ba)
	G.targets["autolineup"] = ba
	var bu := G.mk_btn("Upgrade Player", Color.html("#e8872f"), Vector2(0, 64), "", 24)
	bu.disabled = sel == null
	bu.pressed.connect(_upgrade_popup)
	team_left.add_child(bu)
	team_left.add_child(G.mk_label("Tap a player, then tap another to swap.", 16, Color(1, 1, 1, 0.6)))
	# court
	var cp := G.mk_panel(Color.html("#b5651f"), 14)
	team_center.add_child(cp)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	cp.add_child(cv)
	var net := ColorRect.new()
	net.custom_minimum_size = Vector2(380, 12)
	net.color = Color(1, 1, 1, 0.92)
	cv.add_child(net)
	var nl := G.mk_label("N E T", 16, Color(1, 1, 1, 0.8))
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(nl)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	cv.add_child(grid)
	for i in 6:
		var cd := CardView.new().setup(G.players[int(G.save["lineup"][i])], Vector2(120, 168))
		cd.selected = sel != null and sel["t"] == "line" and int(sel["i"]) == i
		cd.pressed.connect(_tap_line.bind(i))
		grid.add_child(cd)
		if i == 0:
			G.targets["slot0"] = cd
	var bl := G.mk_label("Substitutes", 24, Color.html("#ffc43a"))
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_bench.add_child(bl)
	var k := 0
	for id in G.bench_ids():
		var bc := CardView.new().setup(G.players[int(id)], Vector2(120, 168))
		bc.selected = sel != null and sel["t"] == "bench" and int(sel["id"]) == int(id)
		bc.pressed.connect(_tap_bench.bind(int(id)))
		team_bench.add_child(bc)
		if k == 0:
			G.targets["bench0"] = bc
		k += 1

func _tap_line(i: int) -> void:
	var l: Array = G.save["lineup"]
	if sel == null:
		sel = {"t": "line", "i": i}
	elif sel["t"] == "line":
		var a := int(sel["i"])
		if a != i:
			var tmp = l[a]
			l[a] = l[i]
			l[i] = tmp
			G.write()
		sel = null
	else:
		l[i] = int(sel["id"])
		sel = null
		G.write()
	G.sfx("card")
	_team_refresh()

func _tap_bench(id: int) -> void:
	var l: Array = G.save["lineup"]
	if sel != null and sel["t"] == "line":
		l[int(sel["i"])] = id
		sel = null
		G.write()
	else:
		sel = {"t": "bench", "id": id}
	G.sfx("card")
	_team_refresh()

func _pick_server() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(G.mk_label("Who serves first?", 32, Color.html("#ffc43a")))
	for id in G.save["lineup"]:
		var p: Dictionary = G.players[int(id)]
		var pid := int(id)
		var b := G.mk_btn("%s  (%s)  SRV %d" % [String(p["name"]), String(p["pos"]), G.stat(p, "srv")], Color.html("#2b6cff"), Vector2(480, 56), "", 22)
		b.pressed.connect(func():
			G.save["first"] = pid
			G.write()
			close_popup()
			_team_refresh())
		v.add_child(b)
	var au := G.mk_btn("Auto", Color.html("#4a5a8a"), Vector2(480, 56), "", 22)
	au.pressed.connect(func():
		G.save["first"] = -1
		G.write()
		close_popup()
		_team_refresh())
	v.add_child(au)
	_modal(v)

func _upgrade_popup() -> void:
	var id := _sel_id()
	if id < 0:
		return
	var p: Dictionary = G.players[id]
	var lv := G.lv(id)
	var cost := int(100.0 * float(lv + 1) * float(p["ovr"]) / 50.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	h.add_child(CardView.new().setup(p, Vector2(170, 238)))
	var info := VBoxContainer.new()
	h.add_child(info)
	info.add_child(G.mk_label(String(p["name"]), 28, Color.html("#ffc43a")))
	info.add_child(G.mk_label("Upgrade level: %d / 10" % lv, 24))
	info.add_child(G.mk_label("Each level: +2 to all stats", 20, Color(1, 1, 1, 0.7)))
	var msg := G.mk_label("", 22, Color.html("#ff6a5a"))
	var bu := G.mk_btn("Upgrade (%d coins)" % cost if lv < 10 else "MAX LEVEL", Color.html("#e8872f"), Vector2(330, 64), "", 24)
	bu.disabled = lv >= 10
	bu.pressed.connect(func():
		if int(G.save["coins"]) < cost:
			msg.text = "Not enough coins!"
			return
		G.add_coins(-cost)
		G.save["lv"][str(id)] = lv + 1
		G.write()
		G.sfx("coin")
		close_popup()
		_team_refresh())
	info.add_child(bu)
	info.add_child(msg)
	var cl := G.mk_btn("Close", Color.html("#4a5a8a"), Vector2(330, 56), "", 24)
	cl.pressed.connect(close_popup)
	info.add_child(cl)
	_modal(v)

# ------------------------------------------------------------------ transfer
func _s_transfer() -> void:
	tr_tab = ""
	tr_cat = ""
	tr_items = []
	var v := _screen("Transfer", "menu")
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 30)
	v.add_child(tabs)
	var bb := G.mk_btn("BUY", Color.html("#27a85a"), Vector2(280, 70), "", 32)
	bb.pressed.connect(func():
		tr_tab = "buy"
		tr_cat = ""
		_tr_render())
	tabs.add_child(bb)
	G.targets["tab_buy"] = bb
	var bs := G.mk_btn("SELL", Color.html("#e8452f"), Vector2(280, 70), "", 32)
	bs.pressed.connect(func():
		tr_tab = "sell"
		_tr_render())
	tabs.add_child(bs)
	tr_box = VBoxContainer.new()
	tr_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tr_box.add_theme_constant_override("separation", 10)
	v.add_child(tr_box)
	_tr_render()

func _tr_render() -> void:
	_clear(tr_box)
	if tr_tab == "":
		var l := G.mk_label("Choose BUY or SELL", 30, Color(1, 1, 1, 0.7))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tr_box.add_child(l)
		return
	var cat := G.mk_label("Category : " + ("Buy" if tr_tab == "buy" else "Sell"), 28, Color.html("#ffc43a"))
	tr_box.add_child(cat)
	if tr_tab == "sell":
		_tr_list(G.bench_ids(), "sell")
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	tr_box.add_child(row)
	var ba := G.mk_btn("Available", Color.html("#2b6cff"), Vector2(300, 64), "", 28)
	ba.pressed.connect(func():
		tr_cat = "avail"
		_tr_render())
	row.add_child(ba)
	G.targets["avail"] = ba
	var bsr := G.mk_btn("Search (coins)", Color.html("#9a4bd6"), Vector2(340, 64), "", 28)
	bsr.pressed.connect(func():
		tr_cat = "search"
		tr_items = []
		_tr_render())
	row.add_child(bsr)
	if tr_cat == "avail":
		tr_box.add_child(G.mk_label("Cheap players on the market. The list changes after every match. Use Save to keep a player.", 18, Color(1, 1, 1, 0.65)))
		_tr_list(G.market(), "avail")
	elif tr_cat == "search":
		var cost := 100 + tr_min * 4
		var sr := HBoxContainer.new()
		sr.add_theme_constant_override("separation", 10)
		tr_box.add_child(sr)
		var bp := G.mk_btn("Pos: " + tr_pos, Color.html("#4a5a8a"), Vector2(170, 56), "", 22)
		bp.pressed.connect(func():
			tr_pos = POSS[(POSS.find(tr_pos) + 1) % POSS.size()]
			_tr_render())
		sr.add_child(bp)
		var bm := G.mk_btn("-", Color.html("#4a5a8a"), Vector2(60, 56), "", 28)
		bm.pressed.connect(func():
			tr_min = maxi(40, tr_min - 5)
			_tr_render())
		sr.add_child(bm)
		sr.add_child(G.mk_label("Min OVR %d" % tr_min, 24))
		var bpl := G.mk_btn("+", Color.html("#4a5a8a"), Vector2(60, 56), "", 28)
		bpl.pressed.connect(func():
			tr_min = mini(95, tr_min + 5)
			_tr_render())
		sr.add_child(bpl)
		var bg := G.mk_btn("Search  (%d coins)" % cost, Color.html("#e8872f"), Vector2(300, 56), "", 22)
		bg.pressed.connect(func():
			if int(G.save["coins"]) < cost:
				_popup("Not enough coins", "You need %d coins to search." % cost)
				return
			G.add_coins(-cost)
			tr_items = G.search(tr_pos, tr_min)
			G.sfx("card")
			_tr_render())
		sr.add_child(bg)
		if tr_items.is_empty():
			tr_box.add_child(G.mk_label("Press Search to find players.", 22, Color(1, 1, 1, 0.6)))
		else:
			_tr_list(tr_items, "buy")

func _tr_list(ids: Array, mode: String) -> void:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tr_box.add_child(sc)
	var fl := HFlowContainer.new()
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fl.add_theme_constant_override("h_separation", 14)
	fl.add_theme_constant_override("v_separation", 14)
	sc.add_child(fl)
	if ids.is_empty():
		fl.add_child(G.mk_label("No players here.", 24, Color(1, 1, 1, 0.6)))
	for id in ids:
		fl.add_child(_tr_item(int(id), mode))

func _tr_item(id: int, mode: String) -> Control:
	var p: Dictionary = G.players[id]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(CardView.new().setup(p, Vector2(140, 196)))
	var price := G.price(p)
	if mode == "sell":
		price = int(price / 2)
	v.add_child(G.mk_label("%d coins" % price, 22, Color.html("#ffd84a")))
	if mode == "sell":
		var b := G.mk_btn("Sell", Color.html("#e8452f"), Vector2(140, 48), "", 22)
		b.pressed.connect(func():
			G.sell(id)
			G.sfx("coin")
			_tr_render())
		v.add_child(b)
		return v
	var b2 := G.mk_btn("Buy", Color.html("#27a85a"), Vector2(140, 48), "", 22)
	b2.pressed.connect(func():
		if G.buy(id, price):
			G.sfx("coin")
			_tr_render()
		else:
			_popup("Not enough coins", "You need %d coins." % price))
	v.add_child(b2)
	if mode == "avail":
		if G.save["hold"].has(str(id)):
			v.add_child(G.mk_label("Saved: %d match" % int(G.save["hold"][str(id)]), 18, Color.html("#7dff9a")))
		else:
			var bsv := G.mk_btn("Save", Color.html("#2b6cff"), Vector2(140, 44), "", 20)
			bsv.pressed.connect(func(): _save_popup(id))
			v.add_child(bsv)
	return v

func _save_popup(id: int) -> void:
	var p: Dictionary = G.players[id]
	var base := G.price(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(G.mk_label("Keep %s on the market\n(otherwise he leaves after the next match)" % String(p["name"]), 24))
	var ns := [1, 3, 5, 10]
	var fs := [0.08, 0.2, 0.3, 0.5]
	for k in 4:
		var n: int = ns[k]
		var cost := int(float(base) * float(fs[k]))
		var b := G.mk_btn("%d match%s  -  %d coins" % [n, "" if n == 1 else "es", cost], Color.html("#2b6cff"), Vector2(420, 56), "", 24)
		b.pressed.connect(func():
			if int(G.save["coins"]) < cost:
				_popup("Not enough coins", "You need %d coins." % cost)
				return
			G.add_coins(-cost)
			G.save["hold"][str(id)] = n
			G.write()
			close_popup()
			_tr_render())
		v.add_child(b)
	var c := G.mk_btn("Cancel", Color.html("#4a5a8a"), Vector2(420, 52), "", 22)
	c.pressed.connect(close_popup)
	v.add_child(c)
	_modal(v)

# ------------------------------------------------------------------ shop
func _s_shop() -> void:
	var v := _screen("Shop", "menu")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	v.add_child(row)
	for k in PACKS.size():
		var pk: Dictionary = PACKS[k]
		var pan := G.mk_panel(Color(pk["col"]).darkened(0.5), 20)
		row.add_child(pan)
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 12)
		c.custom_minimum_size = Vector2(330, 0)
		c.alignment = BoxContainer.ALIGNMENT_CENTER
		pan.add_child(c)
		var ic := TextureRect.new()
		ic.texture = load("res://icons/shop.png")
		ic.custom_minimum_size = Vector2(130, 130)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c.add_child(ic)
		var t := G.mk_label(String(pk["n"]), 34, Color(pk["col"]).lightened(0.4))
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(t)
		var d := G.mk_label("3 random players\nOVR %d - %d%s%s" % [pk["lo"], pk["hi"], "\nChance: Star" if float(pk["star"]) > 0.0 else "", " + Legend" if float(pk["leg"]) > 0.0 else ""], 22)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(d)
		var b := G.mk_btn("Open  (%d coins)" % int(pk["price"]), Color(pk["col"]), Vector2(0, 70), "", 26)
		b.pressed.connect(_open_pack.bind(k))
		c.add_child(b)

func _open_pack(k: int) -> void:
	var pk: Dictionary = PACKS[k]
	var price := int(pk["price"])
	if int(G.save["coins"]) < price:
		_popup("Not enough coins", "You need %d coins." % price)
		return
	G.add_coins(-price)
	var got: Array = []
	var star_n: int = G.STARS.size()
	for i in 3:
		var r := randf()
		var cand: Array = []
		if r < float(pk["leg"]):
			for id in range(1000 + star_n, G.players.size()):
				if not G.save["owned"].has(id) and not got.has(id):
					cand.append(id)
		elif r < float(pk["leg"]) + float(pk["star"]):
			for id in range(1000, 1000 + star_n):
				if not G.save["owned"].has(id) and not got.has(id):
					cand.append(id)
		if cand.is_empty():
			for id in 1000:
				var ov: int = G.players[id]["ovr"]
				if ov >= int(pk["lo"]) and ov <= int(pk["hi"]) and not G.save["owned"].has(id) and not got.has(id):
					cand.append(id)
		if cand.is_empty():
			continue
		got.append(int(cand[randi() % cand.size()]))
	for id in got:
		G.save["owned"].append(int(id))
	G.write()
	G.sfx("card")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	var t := G.mk_label("You got:" if not got.is_empty() else "No new players available.", 34, Color.html("#ffc43a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	for id in got:
		h.add_child(CardView.new().setup(G.players[int(id)], Vector2(180, 252)))
	var ok := G.mk_btn("OK", Color.html("#27a85a"), Vector2(260, 64))
	ok.pressed.connect(close_popup)
	v.add_child(ok)
	_modal(v)
	if got.is_empty():
		G.add_coins(int(price / 2))

# ------------------------------------------------------------------ missions
func _s_mission() -> void:
	G.mis("win", 0)
	var v := _screen("Missions", "menu")
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_theme_constant_override("separation", 10)
	sc.add_child(c)
	c.add_child(G.mk_label("Daily Missions (reset every day)", 28, Color.html("#ffc43a")))
	var m: Dictionary = G.save["mis"]
	_task(c, "Win 1 match", int(m["win"]), 1, 300, m["claim"], "win")
	_task(c, "Score 30 points", int(m["score"]), 30, 200, m["claim"], "score")
	_task(c, "Spike 15 times", int(m["spike"]), 15, 250, m["claim"], "spike")
	c.add_child(G.mk_label("Achievements", 28, Color.html("#ffc43a")))
	var a: Dictionary = G.save["ach"]
	_task(c, "Win 10 matches", int(a["wins"]), 10, 1500, a["claim"], "w10")
	_task(c, "Own 20 players", G.save["owned"].size(), 20, 1000, a["claim"], "own20")
	_task(c, "Clear Story level 10", int(G.save["story"]), 10, 1500, a["claim"], "st10")

func _task(parent: Control, text: String, cur_v: int, goal: int, reward: int, claim: Array, key: String) -> void:
	var pan := G.mk_panel(Color(0.07, 0.12, 0.27, 0.95), 14)
	parent.add_child(pan)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	pan.add_child(h)
	var l := G.mk_label("%s   (%d / %d)" % [text, mini(cur_v, goal), goal], 26)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var done := claim.has(key)
	var can_claim := cur_v >= goal and not done
	var b := G.mk_btn("Claimed" if done else "Claim +%d" % reward, Color.html("#27a85a"), Vector2(220, 56), "", 22)
	b.disabled = not can_claim
	b.pressed.connect(func():
		claim.append(key)
		G.add_coins(reward)
		G.sfx("coin")
		go("mission"))
	h.add_child(b)

# ------------------------------------------------------------------ story
func _s_story() -> void:
	var v := _screen("Story Mode", "menu")
	v.add_child(G.mk_label("Levels 1 - 100   (difficulty: %s)" % DIFFS[int(G.save["diff"])], 24, Color(1, 1, 1, 0.8)))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 10
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	var cleared := int(G.save["story"])
	for n in range(1, 101):
		var col := Color.html("#2b6cff")
		if n <= cleared:
			col = Color.html("#27a85a")
		elif n > cleared + 1:
			col = Color.html("#3a4260")
		var b := G.mk_btn(str(n), col, Vector2(100, 84), "", 30)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = n > cleared + 1
		b.pressed.connect(start_match.bind("story", n))
		grid.add_child(b)
		if n == 1:
			G.targets["lvl1"] = b

# ------------------------------------------------------------------ tournament
func _s_tour() -> void:
	var v := _screen("Tournament", "menu")
	var c := CenterContainer.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(c)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	c.add_child(box)
	var nb := G.mk_btn("New Game", Color.html("#e8452f"), Vector2(420, 96), "tournament", 36)
	nb.pressed.connect(_tour_new)
	box.add_child(nb)
	var active := bool(G.save["tour"].get("active", false))
	var cb := G.mk_btn("Continue", Color.html("#2b6cff"), Vector2(420, 96), "", 36)
	cb.disabled = not active
	cb.pressed.connect(func(): go("tourmap"))
	box.add_child(cb)
	var l := G.mk_label("Auto save is ON. Win 3 matches to become the champion (+5000 coins)." if active else "Win 3 matches to become the champion (+5000 coins).", 20, Color(1, 1, 1, 0.7))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)

func _tour_new() -> void:
	var base := G.team_avg(G.save["lineup"])
	var opps: Array = []
	var adds := [-8.0, -3.0, 3.0]
	for i in 3:
		var s: float = base + float(adds[i])
		var idx := clampi(int((s - 42.0) / 0.38) + randi_range(-3, 3), 0, 129)
		var t: Dictionary = G.teams[idx]
		opps.append({"name": t["name"], "str": s})
	G.save["tour"] = {"active": true, "round": 0, "opps": opps}
	G.write()
	go("tourmap")

func _s_tourmap() -> void:
	var v := _screen("Tournament", "tour")
	var tour: Dictionary = G.save["tour"]
	var rnd := int(tour.get("round", 0))
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 14)
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(c)
	for i in 3:
		var o: Dictionary = tour["opps"][i]
		var state := "Locked"
		var col := Color(0.1, 0.15, 0.3, 0.95)
		if i < rnd:
			state = "WON"
			col = Color(0.1, 0.35, 0.2, 0.95)
		elif i == rnd:
			state = "NEXT"
			col = Color(0.2, 0.3, 0.6, 0.95)
		var pan := G.mk_panel(col, 16)
		c.add_child(pan)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 20)
		pan.add_child(h)
		var l := G.mk_label("%s:  vs  %s" % [ROUNDS[i], String(o["name"])], 30)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(G.mk_label(state, 30, Color.html("#ffd84a")))
	var b := G.mk_btn("Play Next Match", Color.html("#27a85a"), Vector2(420, 90), "", 34)
	b.pressed.connect(start_match.bind("tour", rnd))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(b)
	c.add_child(hb)

# ------------------------------------------------------------------ match
func start_match(m: String, idx: int) -> void:
	var g := Game.new()
	g.mode = m
	g.level = idx
	if m == "story":
		var t: Dictionary = G.teams[idx - 1]
		g.opp_name = String(t["name"])
		g.opp_str = float(t["str"])
	else:
		var o: Dictionary = G.save["tour"]["opps"][idx]
		g.opp_name = String(o["name"])
		g.opp_str = float(o["str"])
	g.tut_mode = G.tut_active
	G.targets.clear()
	close_popup()
	if cur != null:
		cur.queue_free()
	cur = g
	ui.add_child(g)
	g.exit.connect(_on_game_exit.bind(m, idx))

func _on_game_exit(won: bool, m: String, idx: int) -> void:
	if m == "story":
		go("story")
		return
	var tour: Dictionary = G.save["tour"]
	if won:
		tour["round"] = idx + 1
		if idx + 1 >= 3:
			tour["active"] = false
			G.write()
			go("tour")
			G.add_coins(5000)
			G.sfx("win")
			_popup("CHAMPION!", "You won the tournament!\n+5000 coins")
			return
		G.write()
		go("tourmap")
	else:
		tour["active"] = false
		G.write()
		go("tour")
		_popup("Eliminated", "You were knocked out.\nStart a New Game to try again!")
