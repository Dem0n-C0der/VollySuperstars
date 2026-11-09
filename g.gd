extends Node
# Global data + helpers (autoload "G"). Developer: Sano

signal coins_changed

const SAVE_PATH := "user://volsu_save.json"
const KEYS := ["srv", "rec", "set", "spk", "blk"]
const KEY_NAMES := ["SRV", "REC", "SET", "SPK", "BLK"]
const POS_CYCLE := ["S", "OH", "OH", "MB", "MB", "OP", "L"]
const CYCLE := [0, 1, 2, 5, 4, 3]
const W := {
	"S": [0.15, 0.15, 0.40, 0.15, 0.15],
	"OH": [0.15, 0.25, 0.05, 0.40, 0.15],
	"MB": [0.10, 0.05, 0.05, 0.35, 0.45],
	"OP": [0.15, 0.05, 0.05, 0.55, 0.20],
	"L": [0.15, 0.60, 0.15, 0.0, 0.10],
}
const OFF := {
	"S": [0, 2, 14, -12, -8],
	"OH": [0, 6, -8, 8, -4],
	"MB": [-4, -10, -6, 4, 14],
	"OP": [4, -10, -8, 12, 2],
	"L": [2, 18, 0, -30, -20],
}

var SKIN: Array = []
var HAIR: Array = []
var RAR_COL := {}

var players: Array = []
var teams: Array = []
var save: Dictionary = {}
var targets := {}
var tut = null
var tut_active := false
var tut_i := 0

var music: AudioStreamPlayer
var amb: AudioStreamPlayer
var sfx_pool: Array = []
var sfx_i := 0
var cache := {}
var cur_music := ""
var crumbs: Array = []
var face_cache := {}

const STARS := [
	"Wilfredo Leon", "Earvin Ngapeth", "Yuki Ishikawa", "Ran Takahashi", "Yuji Nishida",
	"Bartosz Kurek", "Michal Kubiak", "Tomasz Fornal", "Aleksander Sliwka", "Jakub Kochanowski",
	"Kamil Semeniuk", "Pawel Zatorski", "Fabian Drzyzga", "Nimir Abdel-Aziz", "Gyorgy Grozer",
	"Matt Anderson", "Micah Christenson", "Aaron Russell", "Taylor Sander", "Jeffrey Jendryk",
	"Erik Shoji", "Kyle Ensing", "Torey DeFalco", "Maxwell Holt", "Bruno Rezende",
	"Wallace de Souza", "Ricardo Lucarelli", "Douglas Souza", "Lucas Saatkamp", "Yoandy Leal",
	"Alan Souza", "Simone Giannelli", "Alessandro Michieletto", "Yuri Romano", "Daniele Lavia",
	"Gianluca Galassi", "Mattia Bottolo", "Ivan Zaytsev", "Osmany Juantorena", "Matey Kaziyski",
	"Tsvetan Sokolov", "Trevor Clevenot", "Jean Patry", "Stephen Boyer", "Antoine Brizard",
	"Benjamin Toniutti", "Nicolas Le Goff", "Barthelemy Chinenyeze", "Kento Miyaura", "Masahiro Sekita",
	"Paola Egonu", "Tijana Boskovic", "Gabi Guimaraes", "Zhu Ting", "Kim Yeon-koung",
	"Mayu Ishikawa", "Nootsara Tomkom", "Pimpichaya Kokram", "Thatdao Nuekjang", "Jordan Larson",
	"Foluke Akinradewo", "Kelsey Robinson", "Jordyn Poulter", "Annie Drews", "Chiaka Ogbogu",
	"Dana Rettke", "Jordan Thompson", "Haleigh Washington", "Alisha Glass", "Lauren Carlini",
	"Micha Hancock", "Melissa Vargas", "Thaisa Menezes", "Fernanda Garay", "Natalia Pereira",
	"Tandara Caixeta", "Ana Carolina da Silva", "Rosamaria Montibeller", "Macris Carneiro", "Fabiana Claudino",
	"Sheilla Castro", "Camila Brait", "Brankica Mihajlovic", "Maja Ognjenovic", "Bianka Busa",
	"Jovana Stevanovic", "Silvija Popovic", "Alessia Orro", "Miriam Sylla", "Caterina Bosetti",
	"Anna Danesi", "Sarah Fahr", "Monica De Gennaro", "Elena Pietrini", "Ebrar Karakurt",
	"Meryem Boz", "Eda Erdem", "Hande Baladin", "Zehra Gunes", "Cansu Ozbay",
]

# name, position, ovr, hair color index
const LEGENDS := [
	["Shoyo Hinata", "OH", 93, 4], ["Tobio Kageyama", "S", 94, 0], ["Kei Tsukishima", "MB", 90, 3],
	["Tadashi Yamaguchi", "OH", 86, 0], ["Yu Nishinoya", "L", 92, 1], ["Ryunosuke Tanaka", "OH", 87, 0],
	["Daichi Sawamura", "OH", 88, 0], ["Koshi Sugawara", "S", 88, 7], ["Asahi Azumane", "OP", 89, 1],
	["Tooru Oikawa", "S", 95, 1], ["Hajime Iwaizumi", "OH", 91, 0], ["Wakatoshi Ushijima", "OP", 97, 1],
	["Tetsuro Kuroo", "MB", 92, 0], ["Kenma Kozume", "S", 91, 3], ["Koutarou Bokuto", "OP", 96, 7],
	["Keiji Akaashi", "S", 93, 0], ["Atsumu Miya", "S", 95, 3], ["Osamu Miya", "OH", 88, 7],
	["Kiyoomi Sakusa", "OH", 94, 0], ["Kourai Hoshiumi", "OH", 92, 3], ["Lev Haiba", "MB", 88, 7],
	["Morisuke Yaku", "L", 91, 3], ["Kentaro Kyotani", "OH", 85, 0], ["Taketora Yamamoto", "OH", 89, 0],
	["Satori Tendo", "MB", 91, 5], ["Kenjiro Shirabu", "S", 88, 1], ["Eita Semi", "S", 87, 7],
	["Shinsuke Kita", "OH", 90, 3], ["Rintaro Suna", "MB", 90, 1], ["Aran Ojiro", "OH", 91, 1],
	["Motoya Komori", "L", 89, 1], ["Hayato Futakuchi", "OH", 85, 0],
]

func _ready() -> void:
	randomize()
	SKIN = [Color.html("#f5d0b0"), Color.html("#e0ac7e"), Color.html("#c68642"), Color.html("#8d5524")]
	HAIR = [Color.html("#1b1b1b"), Color.html("#4a2c17"), Color.html("#a0522d"), Color.html("#e8c547"),
		Color.html("#ff7a1a"), Color.html("#d94a4a"), Color.html("#3b6fd9"), Color.html("#9a9a9a")]
	RAR_COL = {"Common": Color.html("#9aa3ad"), "Rare": Color.html("#3fa7ff"), "Epic": Color.html("#b05cff"),
		"Star": Color.html("#ffc43a"), "Legend": Color.html("#ff4a4a")}
	_gen_players()
	_apply_face_meta()
	_gen_teams()
	load_game()
	_setup_audio()

# ------------------------------------------------------------------ data
func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp

func _gen_players() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260607
	var id_first := ["Aditya", "Budi", "Cahya", "Dimas", "Eko", "Fajar", "Gilang", "Hendra", "Indra", "Joko",
		"Kurnia", "Lintang", "Made", "Naufal", "Oka", "Putra", "Rangga", "Surya", "Teguh", "Wahyu",
		"Yoga", "Zaki", "Bagas", "Dwi", "Reza", "Arif", "Bayu", "Rizky", "Andika", "Galih",
		"Ayu", "Dewi", "Putri", "Sari", "Rina", "Nadia", "Citra", "Maya", "Intan", "Larasati"]
	var id_last := ["Pratama", "Saputra", "Wijaya", "Kusuma", "Santoso", "Hidayat", "Nugroho", "Permana", "Setiawan", "Lesmana",
		"Ramadhan", "Firmansyah", "Susanto", "Purnomo", "Utomo", "Hartono", "Wibowo", "Siregar", "Nasution", "Lubis",
		"Harahap", "Simanjuntak", "Sitompul", "Tampubolon", "Manurung", "Gunawan", "Halim", "Kurniawan", "Maulana", "Prakoso"]
	var jp_fam := ["Sato", "Suzuki", "Takahashi", "Tanaka", "Watanabe", "Ito", "Yamamoto", "Nakamura", "Kobayashi", "Kato",
		"Yoshida", "Yamada", "Sasaki", "Yamaguchi", "Matsumoto", "Inoue", "Kimura", "Hayashi", "Shimizu", "Mori"]
	var jp_giv := ["Haruto", "Ren", "Sora", "Kaito", "Riku", "Yuto", "Sota", "Hinata", "Akira", "Daiki",
		"Kenta", "Shun", "Takumi", "Yuki", "Aoi", "Mei", "Rin", "Hana", "Sakura", "Mio"]
	var kr_fam := ["Kim", "Lee", "Park", "Choi", "Jung", "Kang", "Cho", "Yoon", "Jang", "Lim",
		"Han", "Shin", "Seo", "Kwon", "Hwang", "Ahn", "Song", "Yoo", "Hong", "Jeon"]
	var kr_giv := ["Min-jun", "Seo-jun", "Do-yun", "Ha-joon", "Ji-ho", "Joon-woo", "Hyun-woo", "Ji-hoon", "Seung-min", "Tae-yang",
		"Soo-ah", "Ji-woo", "Seo-yeon", "Ha-eun", "Yu-na", "Min-seo", "Da-eun", "Chae-won", "Ji-an", "Hye-jin"]
	var pools := {"ID": [], "JP": [], "KR": []}
	for f in id_first:
		for l in id_last:
			pools["ID"].append(f + " " + l)
	for g in jp_giv:
		for f in jp_fam:
			pools["JP"].append(g + " " + f)
	for g in kr_giv:
		for f in kr_fam:
			pools["KR"].append(g + " " + f)
	for k in pools.keys():
		_shuffle(pools[k], rng)
	var grp := ["ID", "JP", "KR"]
	for i in 1000:
		var gname: String = grp[i % 3]
		var nm: String = pools[gname][int(i / 3)]
		var pos: String = POS_CYCLE[i % 7]
		var tgt := 42 + int(pow(rng.randf(), 1.7) * 38.0)
		players.append(_mk(i, nm, gname, pos, tgt, "Normal", rng, -1))
	for j in STARS.size():
		var pos2: String = POS_CYCLE[(j * 3 + 1) % 7]
		players.append(_mk(players.size(), STARS[j], "World", pos2, 80 + rng.randi() % 14, "Star", rng, -1))
	for L in LEGENDS:
		players.append(_mk(players.size(), L[0], "Haikyuu", L[1], L[2], "Legend", rng, L[3]))

func _mk(id: int, nm: String, nat: String, pos: String, tgt: int, kind: String, rng: RandomNumberGenerator, hair: int) -> Dictionary:
	var p := {"id": id, "name": nm, "nat": nat, "pos": pos, "kind": kind}
	var o: Array = OFF[pos]
	var w: Array = W[pos]
	var st: Array = []
	var s := 0.0
	for k in 5:
		var v := clampf(float(tgt) + float(o[k]) + float(rng.randi_range(-6, 6)), 20.0, 99.0)
		st.append(v)
		s += v * float(w[k])
	var d := float(tgt) - s
	for k in 5:
		p[KEYS[k]] = int(clampf(float(st[k]) + d, 20.0, 99.0))
	var ov := 0.0
	for k in 5:
		ov += float(p[KEYS[k]]) * float(w[k])
	p["ovr"] = int(round(ov))
	if kind == "Normal":
		if p["ovr"] < 60:
			p["rar"] = "Common"
		elif p["ovr"] < 70:
			p["rar"] = "Rare"
		else:
			p["rar"] = "Epic"
	else:
		p["rar"] = kind
	p["sk"] = rng.randi() % 4
	p["hc"] = hair if hair >= 0 else rng.randi() % 8
	p["hs"] = rng.randi() % 4
	return p

func _gen_teams() -> void:
	var city := ["Tokyo", "Osaka", "Seoul", "Busan", "Jakarta", "Bandung", "Surabaya", "Bali", "Kyoto", "Incheon", "Medan", "Nagoya", "Daegu"]
	var suf := ["Thunders", "Falcons", "Dragons", "Tigers", "Storm", "Comets", "Titans", "Wolves", "Phoenix", "Blazers"]
	for i in 130:
		teams.append({"name": city[i % 13] + " " + suf[int(i / 13)], "str": 42.0 + float(i) * 0.38,
			"col": Color.from_hsv(fmod(float(i) * 0.0618, 1.0), 0.65, 0.85)})

func make_ai(strength: float) -> Array:
	var poss := ["OH", "MB", "OP", "OH", "L", "S"]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var out: Array = []
	for i in 6:
		var base: Dictionary = players[rng.randi() % 1000]
		out.append(_mk(-1, base["name"], base["nat"], poss[i], int(clampf(strength + float(rng.randi_range(-5, 5)), 30.0, 99.0)), "Normal", rng, -1))
	return out

# ------------------------------------------------------------------ player math
func lv(id: int) -> int:
	return int(save["lv"].get(str(id), 0))

func stat(p: Dictionary, k: String) -> int:
	return mini(99, int(p[k]) + lv(int(p["id"])) * 2)

func ovr(p: Dictionary) -> int:
	var w: Array = W[p["pos"]]
	var s := 0.0
	for i in 5:
		s += float(stat(p, KEYS[i])) * float(w[i])
	return int(round(s))

func price(p: Dictionary) -> int:
	return int(pow(float(ovr(p)), 2.6) / 30.0)

func lineup_ids() -> Array:
	return save["lineup"]

func cbonus(p: Dictionary, ids: Array) -> int:
	var nat: String = p["nat"]
	if nat == "World" or nat == "Haikyuu":
		return 0
	var c := 0
	for i in ids:
		if players[int(i)]["nat"] == nat:
			c += 1
	if c >= 5:
		return 4
	if c >= 3:
		return 2
	return 0

func team_avg(ids: Array) -> float:
	var s := 0.0
	for i in ids:
		var p: Dictionary = players[int(i)]
		s += float(ovr(p) + cbonus(p, ids))
	return s / maxf(1.0, float(ids.size()))

func team_rating() -> float:
	return clampf((team_avg(save["lineup"]) - 40.0) / 55.0 * 9.0 + 1.0, 1.0, 10.0)

func bench_ids() -> Array:
	var out: Array = []
	for i in save["owned"]:
		if not save["lineup"].has(i):
			out.append(i)
	out.sort_custom(func(a, b): return ovr(players[a]) > ovr(players[b]))
	return out

func rot(arr: Array) -> Array:
	var out: Array = arr.duplicate()
	for k in 6:
		out[CYCLE[(k + 1) % 6]] = arr[CYCLE[k]]
	return out

func match_lineup() -> Array:
	var l: Array = save["lineup"].duplicate()
	var f := int(save["first"])
	if f >= 0 and l.has(f):
		var guard := 0
		while int(l[5]) != f and guard < 6:
			l = rot(l)
			guard += 1
	return l

func auto_lineup() -> void:
	var owned: Array = save["owned"].duplicate()
	owned.sort_custom(func(a, b): return ovr(players[a]) > ovr(players[b]))
	var need := ["OH", "MB", "OP", "OH", "L", "S"]
	var out: Array = [-1, -1, -1, -1, -1, -1]
	var used: Array = []
	for i in 6:
		for id in owned:
			if players[id]["pos"] == need[i] and not used.has(id):
				out[i] = id
				used.append(id)
				break
	for i in 6:
		if out[i] == -1:
			for id in owned:
				if not used.has(id):
					out[i] = id
					used.append(id)
					break
	save["lineup"] = out
	write()

func plevel() -> int:
	return 1 + int(int(save["xp"]) / 100)

# ------------------------------------------------------------------ save
func default_save() -> Dictionary:
	return {"name": "", "coins": 1000, "xp": 0, "owned": [], "lineup": [], "lv": {}, "story": 0, "tut": false,
		"mus": 0.7, "sfx": 0.9, "gfx": 2, "diff": 1, "day": 0, "streak": 0, "first": -1, "seed": 1, "hold": {},
		"mis": {"day": 0, "win": 0, "score": 0, "spike": 0, "claim": []},
		"ach": {"wins": 0, "claim": []}, "tour": {"active": false}}

func load_game() -> void:
	save = default_save()
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(data) == TYPE_DICTIONARY:
			for k in data.keys():
				save[k] = data[k]
	var o: Array = []
	for i in save["owned"]:
		o.append(int(i))
	save["owned"] = o
	var l: Array = []
	for i in save["lineup"]:
		l.append(int(i))
	save["lineup"] = l
	save["first"] = int(save["first"])
	if save["owned"].is_empty() or save["lineup"].size() != 6:
		_starter()

func write() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(save))
	f.close()

func reset_all() -> void:
	save = default_save()
	_starter()
	write()

func _pick(pos: String, used: Array) -> int:
	for lo_hi in [[50, 58], [45, 62], [0, 99]]:
		for p in players:
			if p["pos"] == pos and p["rar"] == "Common" and p["ovr"] >= lo_hi[0] and p["ovr"] <= lo_hi[1] and not used.has(p["id"]):
				used.append(p["id"])
				return int(p["id"])
	return 0

func _starter() -> void:
	var used: Array = []
	var lineup: Array = []
	for pos in ["OH", "MB", "OP", "OH", "L", "S"]:
		lineup.append(_pick(pos, used))
	var bench: Array = []
	for pos in ["S", "MB", "OH", "L"]:
		bench.append(_pick(pos, used))
	save["lineup"] = lineup
	save["owned"] = lineup + bench

func add_coins(n: int) -> void:
	save["coins"] = int(save["coins"]) + n
	write()
	coins_changed.emit()

func today() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)

func mis(key: String, n := 1) -> void:
	var m: Dictionary = save["mis"]
	if int(m["day"]) != today():
		m["day"] = today()
		m["win"] = 0
		m["score"] = 0
		m["spike"] = 0
		m["claim"] = []
	m[key] = int(m[key]) + n

# ------------------------------------------------------------------ market
func market() -> Array:
	var out: Array = []
	for k in save["hold"].keys():
		out.append(int(k))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(save["seed"])
	var guard := 0
	while out.size() < 12 and guard < 600:
		guard += 1
		var id := rng.randi() % 1000
		if players[id]["ovr"] <= 62 and not save["owned"].has(id) and not out.has(id):
			out.append(id)
	return out

func search(pos: String, min_ovr: int) -> Array:
	var c: Array = []
	for p in players:
		if (pos == "ALL" or p["pos"] == pos) and p["ovr"] >= min_ovr and not save["owned"].has(p["id"]):
			c.append(int(p["id"]))
	c.shuffle()
	return c.slice(0, 12)

func buy(id: int, cost: int) -> bool:
	if int(save["coins"]) < cost or save["owned"].has(id):
		return false
	save["owned"].append(id)
	save["hold"].erase(str(id))
	add_coins(-cost)
	return true

func sell(id: int) -> bool:
	if save["lineup"].has(id) or not save["owned"].has(id):
		return false
	save["owned"].erase(id)
	save["lv"].erase(str(id))
	add_coins(int(price(players[id]) / 2))
	return true

func after_match() -> void:
	for k in save["hold"].keys():
		save["hold"][k] = int(save["hold"][k]) - 1
		if int(save["hold"][k]) <= 0:
			save["hold"].erase(k)
	save["seed"] = randi() % 100000 + 1
	write()

func finish_match(mode: String, level: int, won: bool, mp: int, op: int) -> Dictionary:
	var coins := 60
	var xp := 12
	if won:
		coins = 250 + level * 8 if mode == "story" else 200
		xp = 40
		save["ach"]["wins"] = int(save["ach"]["wins"]) + 1
		mis("win", 1)
		if mode == "story" and level > int(save["story"]):
			save["story"] = level
	save["xp"] = int(save["xp"]) + xp
	after_match()
	add_coins(coins)
	return {"coins": coins, "xp": xp}

# ------------------------------------------------------------------ audio
func _setup_audio() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	music.finished.connect(func(): music.play())
	amb = AudioStreamPlayer.new()
	add_child(amb)
	amb.finished.connect(func(): amb.play())
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_pool.append(p)

func crumb(s: String) -> void:
	crumbs.append(s)

func _apply_face_meta() -> void:
	var path := "res://data/faces.json"
	var data = null
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		data = JSON.parse_string(f.get_as_text())
		f.close()
	elif ResourceLoader.exists(path):
		var res = load(path)
		if res != null:
			data = res.data
	if typeof(data) != TYPE_ARRAY:
		return
	for i in mini(data.size(), players.size()):
		var d: Dictionary = data[i]
		players[i]["sk"] = int(d["sk"])
		players[i]["hs"] = int(d["hs"])
		if players[i]["kind"] != "Legend":
			players[i]["hc"] = int(d["hc"])

func face(id: int):
	if id < 0:
		return null
	if not face_cache.has(id):
		var path := "res://faces/f_%d.png" % id
		face_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return face_cache[id]

func _snd(n: String):
	if not cache.has(n):
		var found = null
		for ext in ["mp3", "ogg", "wav"]:
			var path := "res://audio/%s.%s" % [n, ext]
			if ResourceLoader.exists(path):
				found = load(path)
				break
		cache[n] = found
	return cache[n]

func play_music(n: String) -> void:
	if cur_music == n and music.playing:
		return
	cur_music = n
	music.stop()
	music.stream = _snd(n)
	apply_volume()
	if music.stream != null:
		music.play()

func play_amb(on: bool) -> void:
	if on:
		amb.stream = _snd("crowd")
		amb.volume_db = linear_to_db(maxf(float(save["sfx"]) * 0.35, 0.001))
		if amb.stream != null:
			amb.play()
	else:
		amb.stop()

func apply_volume() -> void:
	music.volume_db = linear_to_db(maxf(float(save["mus"]), 0.001))

func sfx(n: String, vol := 1.0) -> void:
	var s = _snd(n)
	if s == null:
		return
	var p: AudioStreamPlayer = sfx_pool[sfx_i]
	sfx_i = (sfx_i + 1) % sfx_pool.size()
	p.stream = s
	p.volume_db = linear_to_db(maxf(float(save["sfx"]) * vol, 0.001))
	p.play()

func apply_gfx(vp: Viewport) -> void:
	vp.msaa_3d = Viewport.MSAA_2X if int(save["gfx"]) >= 2 else Viewport.MSAA_DISABLED

# ------------------------------------------------------------------ ui helpers
func mk_label(text: String, size := 24, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 4)
	return l

func mk_box(col: Color, radius := 16, border := Color(1, 1, 1, 0.15), shadow := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 7
		sb.shadow_offset = Vector2(0, 4)
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func mk_panel(col := Color(0.08, 0.13, 0.28, 0.95), radius := 18) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", mk_box(col, radius))
	return p

func mk_btn(text: String, col := Color.html("#2b6cff"), size := Vector2(200, 64), icon_name := "", fs := 24) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	b.add_theme_stylebox_override("normal", mk_box(col, 26, col.lightened(0.45), true))
	b.add_theme_stylebox_override("hover", mk_box(col.lightened(0.1), 26, col.lightened(0.55), true))
	b.add_theme_stylebox_override("pressed", mk_box(col.darkened(0.2), 26, col.lightened(0.3)))
	b.add_theme_stylebox_override("disabled", mk_box(col.darkened(0.55), 26, Color(1, 1, 1, 0.05)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if icon_name != "":
		b.icon = load("res://icons/%s.png" % icon_name)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("icon_max_width", int(size.y * 0.72))
	b.resized.connect(func(): b.pivot_offset = b.size / 2.0)
	b.button_down.connect(func(): _pop(b, 0.93))
	b.button_up.connect(func(): _pop(b, 1.0))
	b.pressed.connect(func(): sfx("click", 0.8))
	return b

func _pop(b: Control, s: float) -> void:
	if not is_instance_valid(b):
		return
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(s, s), 0.08)

func mk_bg() -> TextureRect:
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color.html("#0f2a6b"), Color.html("#0a1236"), Color.html("#1b0f3a")])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0.3, 1)
	gt.width = 64
	gt.height = 64
	var t := TextureRect.new()
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
