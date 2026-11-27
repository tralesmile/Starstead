class_name BikeView
extends CanvasLayer
## Criterium overlay at the Halden circuit (rules in BikeModel), seen from above. Hold Space to push, let go to
## recover, A/D (Left/Right) change line, S brakes. One paid race a day, after that free practice. Esc leaves.

signal closed
signal message(msg: String)
signal sound(name: String)

# course geometry on screen: must match tools/gen_bike.py
const CENTER := Vector2(320, 195)
const PX := Vector2(214, 131)
const LAT := 7.4                # screen px per metre sideways
const FRAME := Vector2(28, 20)
const COLOURS := [Color("f4c430"), Color("ce3e36"), Color("3e70ce"), Color("46a052"), Color("9c54b2")]
const COUNTDOWN := 4.0

var canvas: Control
var riders: Array = []
var who: Array = []              # rival personalities
var lane := BikeModel.START_LANE
var t := 0.0                     # race time
var anim := 0.0
var countdown := COUNTDOWN
var started := false
var finished := false
var paid := false
var why_free := ""
var rain := 0.0                  # today's rain, set before open()
var wet := 0.0
var puffs: Array = []            # {pos, vel, age, life, col, size}
var skids: Array = []            # {a, b, age}
var banner := ""
var banner_t := 0.0
var result_lines: Array = []
var auto_pilot := false          # demo helper: a sensible drafter rides for you
var _acc := 0.0
var _puff_t := 0.0
var _rng := RandomNumberGenerator.new()
var _tex: Texture2D = load("res://assets/sprites/bike_riders.png")
var _track: Texture2D = load("res://assets/sprites/bike_track.png")

func _init() -> void:
	layer = 60
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open(seed_value: int = -1) -> bool:
	_rng.seed = seed_value if seed_value >= 0 else randi()
	who = [{}]
	var bonuses: Array = [0.0]
	for i in range(1, BikeModel.RIDERS):
		who.append(BikeModel.personality(i, _rng))
		bonuses.append(who[i]["bonus"])
	riders = BikeModel.grid(bonuses, _rng)
	lane = int(riders[0]["lane"])
	t = 0.0
	anim = 0.0
	_acc = 0.0
	countdown = COUNTDOWN
	started = false
	finished = false
	puffs = []
	skids = []
	banner = ""
	banner_t = 0.0
	result_lines = []
	wet = BikeModel.wet_for(rain)
	var e := BikeModel.entry(GameState.sport_best, GameState.clock.day, GameState.money)
	paid = e["paid"]
	why_free = e["why"]
	visible = true
	canvas.queue_redraw()
	return true

func close() -> void:
	visible = false
	closed.emit()

func handle(e: InputEvent) -> bool:
	if visible and e is InputEventKey and e.pressed and not e.echo:
		var key: int = e.keycode
		if key == KEY_ESCAPE or (finished and e.is_action_pressed("interact")):
			close()
		elif e.is_action_pressed("move_left"):
			lane = maxi(lane - 1, 0)
		elif e.is_action_pressed("move_right"):
			lane = mini(lane + 1, BikeModel.LANES.size() - 1)
	return visible

func _process(d: float) -> void:
	if not visible:
		return
	canvas.size = get_viewport().get_visible_rect().size
	anim += d
	banner_t = maxf(0.0, banner_t - d)
	if not finished:
		if not started:
			countdown -= d
			if countdown <= 0.0:
				_start()
		else:
			_acc = minf(_acc + d, 0.25)
			while _acc >= BikeModel.TICK and not finished:
				_acc -= BikeModel.TICK
				_tick(_player_input())
			_emit_puffs(d)
	for p in puffs:
		p["age"] = float(p["age"]) + d
		p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * d
		p["vel"] = (p["vel"] as Vector2) * exp(-3.0 * d)
	puffs = puffs.filter(func(p): return float(p["age"]) < float(p["life"]))
	for k in skids:
		k["age"] = float(k["age"]) + d
	skids = skids.filter(func(k): return float(k["age"]) < 8.0)
	canvas.queue_redraw()

func _start() -> void:
	started = true
	countdown = 0.0
	if paid:
		var e := BikeModel.entry(GameState.sport_best, GameState.clock.day, GameState.money)
		paid = e["paid"]
		why_free = e["why"]
		if paid:   # the fee is taken, and today's paid start used up, as the flag drops
			GameState.money -= BikeModel.FEE
			GameState.sport_best[BikeModel.DAY_KEY] = GameState.clock.day
	_show("GO!", 1.0)
	sound.emit("whistle")

func _show(text: String, secs: float) -> void:
	banner = text
	banner_t = secs

func _player_input() -> Dictionary:
	if auto_pilot:
		var me := {"style": "sprinter", "kick": 100.0, "cruise": 0.45, "nerve": 0.99, "attack": 0.0}
		var a := BikeModel.ai_input(riders, 0, me, wet)
		lane = a["lane"]
		return a
	var brake := Input.is_action_pressed("move_down")
	return {"effort": 1.0 if Input.is_key_pressed(KEY_SPACE) else 0.0, "brake": brake, "lane": lane}

func _tick(mine: Dictionary) -> void:
	var inputs: Array = [mine]
	for i in range(1, BikeModel.RIDERS):
		inputs.append(BikeModel.ai_input(riders, i, who[i], wet))
	var events := BikeModel.step(riders, inputs, wet, t, BikeModel.TICK)
	t += BikeModel.TICK
	for e in events:
		var i: int = e["i"]
		match String(e["ev"]):
			"slide":
				_burst(i, 18)
				if i == 0:
					_show("SLIDE! Brake before the bend", 1.6)
					sound.emit("hit")
				else:
					_show("%s goes down!" % BikeModel.NAMES[i], 1.2)
			"winded":
				if i == 0:
					_show("Blown! Get your breath back", 1.6)
			"lap":
				if i == 0:
					var last := BikeModel.lap_of(float(riders[0]["s"])) == BikeModel.LAPS
					_show("LAST LAP - the bell!" if last else "Lap %d" % BikeModel.lap_of(float(riders[0]["s"])), 1.4)
					if last:
						sound.emit("whistle")
			"finish":
				if i == 0:
					_finish()

func _finish() -> void:
	finished = true
	# let the rest of the field roll in so the sheet has everyone's time
	var guard := 0
	var clock_t := t
	while guard < 60 * 60 and not riders.all(func(q): return float(q["done"]) >= 0.0):
		var inputs: Array = [{"effort": 0.0, "brake": true, "lane": lane}]
		for i in range(1, BikeModel.RIDERS):
			inputs.append(BikeModel.ai_input(riders, i, who[i], wet))
		BikeModel.step(riders, inputs, wet, clock_t, BikeModel.TICK)
		clock_t += BikeModel.TICK
		guard += 1
	var place := BikeModel.place(riders, 0)
	var mine := float(riders[0]["done"])
	var record := BikeModel.record_time(GameState.sport_best, mine)
	var pay := BikeModel.prize(place) if paid else 0
	GameState.money += pay
	GameState.bump("bike_races")
	if paid and place == 0:
		GameState.bump("bike_wins")
	var order: Array = range(BikeModel.RIDERS)
	order.sort_custom(func(a, b): return BikeModel.place(riders, a) < BikeModel.place(riders, b))
	result_lines = []
	for i in order:
		var done := float(riders[i]["done"])
		result_lines.append({"i": i, "text": "%s   %s" % [BikeModel.ordinal(BikeModel.place(riders, i)), BikeModel.NAMES[i]], "time": "%.2f s" % done if done >= 0.0 else "--"})
	var money := "Prize $%d" % pay if pay > 0 else ("No prize outside the top three" if paid else "Practice run: no prize")
	result_lines.append({"i": -1, "text": money + ("   -   new best time!" if record else ""), "time": ""})
	var tip := "A clean win!" if place == 0 else "Sit on a wheel, save your legs, sprint out of the last bend."
	result_lines.append({"i": -1, "text": tip, "time": ""})
	banner_t = 0.0
	if place < 3:
		sound.emit("crowd_cheer")
	message.emit("Criterium: %s%s" % [BikeModel.ordinal(place), " (+$%d)" % pay if pay > 0 else ""])

# ---------------------------------------------------------------- positions and particles

static func screen_at(s: float, l: float) -> Vector2:
	var th := BikeModel.theta_at(s)
	var out := Vector2(sin(th) / PX.x, cos(th) / PX.y).normalized()
	return CENTER + Vector2(PX.x * sin(th), PX.y * cos(th)) + out * l * LAT

static func heading_at(s: float) -> float:
	var th := BikeModel.theta_at(s)
	return Vector2(PX.x * cos(th), -PX.y * sin(th)).angle()

func _puff(at: Vector2, vel: Vector2, life: float, col: Color, size: float) -> void:
	puffs.append({"pos": at, "vel": vel, "age": 0.0, "life": life, "col": col, "size": size})

func _burst(i: int, n: int) -> void:
	var r: Dictionary = riders[i]
	var at := screen_at(float(r["s"]), float(r["l"]))
	var col := Color(0.82, 0.9, 1.0, 0.85) if wet > 0.0 else Color(0.84, 0.74, 0.54, 0.85)
	for k in n:
		_puff(at, Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(12.0, 60.0), _rng.randf_range(0.35, 0.9), col, _rng.randf_range(1.5, 3.5))

func _emit_puffs(d: float) -> void:
	_puff_t -= d
	if _puff_t > 0.0:
		return
	_puff_t = 0.05
	for r in riders:
		var h := heading_at(float(r["s"]))
		var fwd := Vector2.from_angle(h)
		var rear := screen_at(float(r["s"]), float(r["l"])) - fwd * 11.0
		var v := float(r["v"])
		var side := fwd.orthogonal() * _rng.randf_range(-12.0, 12.0)
		if float(r["slide"]) > 0.0 or float(r["wobble"]) > 0.0:
			var c := Color(0.82, 0.9, 1.0, 0.7) if wet > 0.0 else Color(0.84, 0.74, 0.54, 0.75)
			_puff(rear, side * 2.0 - fwd * 10.0, 0.6, c, 2.5)
			skids.append({"a": rear, "b": rear + fwd * 5.0 + side * 0.12, "age": 0.0})
		elif wet > 0.0 and v > 6.0:   # rooster tail off the back wheel
			for k in 2:
				_puff(rear, -fwd * _rng.randf_range(8.0, 30.0) + side, 0.32, Color(0.84, 0.92, 1.0, 0.7), 1.5)
		elif float(r["effort"]) > 0.82 and v > 7.0:   # a sprint kicks up grit
			_puff(rear, -fwd * 14.0 + side, 0.4, Color(0.86, 0.8, 0.66, 0.6), 2.0)

# ---------------------------------------------------------------- drawing

func _text(at: Vector2, s: String, size: int = 11, col: Color = Color.WHITE, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_string_outline(font, at, s, align, width, size, 4, Color(0.1, 0.06, 0.03))
	canvas.draw_string(font, at, s, align, width, size, col)

func _mid(y: float, s: String, size: int = 11, col: Color = Color.WHITE) -> void:
	_text(Vector2(0, y), s, size, col, 640, HORIZONTAL_ALIGNMENT_CENTER)

func _panel(r: Rect2) -> void:
	canvas.draw_rect(r.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(r.grow(1), Color(0.65, 0.44, 0.25))
	canvas.draw_rect(r, Color(0.2, 0.13, 0.09, 0.94))

func _bar(r: Rect2, k: float, col: Color) -> void:
	canvas.draw_rect(r.grow(1), Color(0.1, 0.07, 0.04))
	canvas.draw_rect(r, Color(0.2, 0.2, 0.2, 0.85))
	canvas.draw_rect(Rect2(r.position, Vector2(floorf(r.size.x * clampf(k, 0.0, 1.0)), r.size.y)), col)
	canvas.draw_rect(Rect2(r.position, Vector2(floorf(r.size.x * clampf(k, 0.0, 1.0)), 2)), col.lightened(0.35))

func _draw_all() -> void:
	canvas.draw_texture(_track, Vector2.ZERO)
	if riders.is_empty():
		return
	if wet > 0.0:   # dark glossy road and a grey sky
		canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0.08, 0.14, 0.3, 0.24 * wet))
		for i in 46:
			var a := float(i) * 2.399
			var p := screen_at(float(i) * BikeModel.lap_length() / 46.0, sin(a * 3.0) * 3.3)
			canvas.draw_rect(Rect2((p - Vector2(5, 1)).floor(), Vector2(10, 2)), Color(0.7, 0.82, 1.0, 0.22 + 0.1 * sin(anim * 3.0 + a)))
	for k in skids:
		canvas.draw_line(k["a"], k["b"], Color(0.08, 0.07, 0.08, 0.55 * (1.0 - float(k["age"]) / 8.0)), 2.0)
	_draw_draft_streaks()
	_draw_riders()
	for p in puffs:
		var u := float(p["age"]) / float(p["life"])
		var col: Color = p["col"]
		canvas.draw_circle(p["pos"], float(p["size"]) * (0.6 + u), Color(col, col.a * (1.0 - u)))
	if wet > 0.0:
		for i in int(120 * wet):
			var q := WeatherMath.drop_pos(i, anim, 330.0, 0.18) * Vector2(1.8, 1.3)
			canvas.draw_line(q, q + Vector2(-2, 8), Color(0.78, 0.87, 1.0, 0.5), 1.0)
	_draw_hud()

func _draw_draft_streaks() -> void:
	## White wind lines round your wheel while you sit in a slipstream.
	if not started or finished or float(riders[0]["draft"]) < 0.15:
		return
	var k := float(riders[0]["draft"])
	var s := float(riders[0]["s"])
	var l := float(riders[0]["l"])
	for side in [-1.1, 1.1]:
		for n in 3:
			var off := fposmod(anim * 9.0 + n * 2.2, 6.6)
			canvas.draw_line(screen_at(s + 5.0 - off, l + side), screen_at(s + 3.8 - off, l + side), Color(0.75, 0.97, 1.0, 0.9 * k), 2.0)

func _draw_riders() -> void:
	var order: Array = range(riders.size())
	order.sort_custom(func(a, b): return screen_at(float(riders[a]["s"]), float(riders[a]["l"])).y < screen_at(float(riders[b]["s"]), float(riders[b]["l"])).y)
	for i in order:
		var r: Dictionary = riders[i]
		var at := screen_at(float(r["s"]), float(r["l"])).round()
		var ang := heading_at(float(r["s"]))
		canvas.draw_set_transform(at + Vector2(2, 4), ang, Vector2(1.0, 0.45))
		canvas.draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.26))
		canvas.draw_set_transform(Vector2.ZERO)
		if i == 0:
			canvas.draw_arc(at, 14.0, 0.0, TAU, 28, Color(1.0, 0.95, 0.3, 0.95), 1.0)
		var col := 0
		if float(r["slide"]) > 0.0:
			col = 12
			ang += minf(float(r["slide"]), 1.0) * 1.4
		else:
			var load_k := pow(float(r["v"]) / BikeModel.corner_limit(float(r["s"]), float(r["l"]), wet), 2.0)
			var lean := 2 if load_k > 0.72 else (1 if load_k > 0.4 else 0)
			col = lean * 4 + int(float(r["pedal"])) % 4
			if float(r["wobble"]) > 0.0:
				ang += sin(anim * 34.0) * 0.22
		canvas.draw_set_transform(at, ang)
		canvas.draw_texture_rect_region(_tex, Rect2(-FRAME * 0.5, FRAME), Rect2(col * FRAME.x, i * FRAME.y, FRAME.x, FRAME.y))
		canvas.draw_set_transform(Vector2.ZERO)
	if not finished:   # your tag sits on the infield side, clear of the rider ahead
		var me := screen_at(float(riders[0]["s"]), float(riders[0]["l"]))
		var inward := (screen_at(float(riders[0]["s"]), float(riders[0]["l"]) - 1.0) - me).normalized()
		var tag := (me + inward * (24.0 + sin(anim * 5.0) * 1.5)).round()
		canvas.draw_line(me + inward * 15.0, me + inward * 19.0, Color(1.0, 0.95, 0.3), 2.0)
		_text(tag + Vector2(-20, 3), "YOU", 9, Color(1, 0.97, 0.55), 40, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_hud() -> void:
	var me: Dictionary = riders[0]
	var kind := "paid race  (entry $%d)" % BikeModel.FEE if paid else "free practice"
	_text(Vector2(8, 15), "Halden Criterium  -  %s" % kind, 12, Color(1, 0.95, 0.7))
	_text(Vector2(440, 15), "Esc: leave", 11, Color(0.92, 0.94, 0.88), 192, HORIZONTAL_ALIGNMENT_RIGHT)
	# standings, top left
	_panel(Rect2(7, 24, 82, 72))
	var order: Array = range(riders.size())
	order.sort_custom(func(a, b): return BikeModel.place(riders, a) < BikeModel.place(riders, b))
	for k in order.size():
		var i: int = order[k]
		var y := 36.0 + k * 13.0
		canvas.draw_rect(Rect2(21, y - 7, 6, 7), COLOURS[i])
		_text(Vector2(11, y), str(k + 1), 10, Color(0.9, 0.86, 0.7))
		_text(Vector2(31, y), BikeModel.NAMES[i], 10, Color(1, 0.95, 0.45) if i == 0 else Color.WHITE)
	# clock, top right
	_panel(Rect2(543, 24, 90, 59))
	_text(Vector2(550, 37), "time  %.1f s" % t, 10)
	var best := int(GameState.sport_best.get(BikeModel.BEST_KEY, 0))
	_text(Vector2(550, 50), "best  %.2f s" % (best / 100.0) if best > 0 else "best  --", 10, Color(0.85, 0.9, 1.0))
	_text(Vector2(550, 63), "%d km/h" % int(round(float(me["v"]) * 3.6)), 10)
	_text(Vector2(550, 76), "wet road" if wet > 0.0 else "dry road", 10, Color(0.65, 0.82, 1.0) if wet > 0.0 else Color(0.95, 0.88, 0.62))
	if finished:
		_draw_results()
		return
	# infield: lap, place, legs, wheel, line, bend warning
	var place := BikeModel.place(riders, 0)
	_mid(129, "LAP %d/%d" % [BikeModel.lap_of(float(me["s"])), BikeModel.LAPS], 14, Color(1, 0.96, 0.8))
	_mid(153, BikeModel.ordinal(place), 22, Color(1, 0.88, 0.3) if place == 0 else Color.WHITE)
	var stamina := float(me["stamina"])
	var stam_col := Color(0.9, 0.32, 0.24) if me["winded"] else (Color(0.95, 0.74, 0.22) if stamina < 0.3 else Color(0.42, 0.86, 0.38))
	_text(Vector2(238, 170), "WINDED" if me["winded"] else "legs", 10, Color(1, 0.55, 0.45) if me["winded"] else Color.WHITE)
	_bar(Rect2(280, 162, 122, 9), stamina, stam_col)
	var draft := float(me["draft"])
	_text(Vector2(238, 185), "draft", 10, Color(0.7, 0.96, 1.0) if draft > 0.15 else Color(0.78, 0.8, 0.74))
	_bar(Rect2(280, 178, 122, 7), draft, Color(0.4, 0.82, 0.95))
	_text(Vector2(238, 201), "line", 10)
	for k in BikeModel.LANES.size():
		var box := Rect2(280 + k * 42, 192, 38, 11)
		canvas.draw_rect(box.grow(1), Color(0.1, 0.07, 0.04))
		canvas.draw_rect(box, Color(0.95, 0.76, 0.24) if k == lane else Color(0.24, 0.3, 0.2))
		var label: String = ["in", "mid", "out"][k]
		canvas.draw_string(ThemeDB.fallback_font, box.position + Vector2(0, 9), label, HORIZONTAL_ALIGNMENT_CENTER, 38, 9, Color(0.14, 0.09, 0.04) if k == lane else Color(0.86, 0.9, 0.8))
	var warn := ""
	var warn_col := Color(1, 0.8, 0.25)
	if started:
		var v := float(me["v"])
		if me["blocked"]:
			warn = "BOXED IN - change line"
		elif v > BikeModel.safe_speed(float(me["s"]), float(me["l"]), wet):
			warn = "BEND! ease off / brake"
			warn_col = Color(1, 0.45, 0.3)
		elif draft > 0.5:
			warn = "on a wheel: easy riding"
			warn_col = Color(0.7, 0.97, 1.0)
	if warn != "":
		_mid(219, warn, 12, warn_col)
	if banner_t > 0.0:
		_mid(242, banner, 15, Color(1, 0.9, 0.35))
	if not started:
		_panel(Rect2(204, 208, 232, 74))
		var offer := "Prizes: $%d / $%d / $%d" % [BikeModel.PRIZES[0], BikeModel.PRIZES[1], BikeModel.PRIZES[2]]
		if not paid:
			offer = "Today's paid race is done" if why_free == "done" else "Can't cover the $%d entry" % BikeModel.FEE
		_mid(236, str(ceili(countdown)), 30, Color(1, 0.9, 0.3))
		_mid(250, offer, 11, Color(1, 0.95, 0.65))
		_mid(264, "Hold Space: push    let go: recover", 10)
		_mid(277, "A: move in    D: move out    S: brake", 10)
	else:
		_mid(272, "Space push   A/D line   S brake", 9, Color(0.93, 0.96, 0.88, 0.8))

func _draw_results() -> void:
	_panel(Rect2(180, 108, 280, 164))
	_mid(127, "FINISH", 16, Color(1, 0.9, 0.35))
	var y := 147.0
	for line in result_lines:
		var i: int = line["i"]
		if i >= 0:
			canvas.draw_rect(Rect2(226, y - 8, 7, 8), COLOURS[i])
			_text(Vector2(240, y), line["text"], 11, Color(1, 0.95, 0.45) if i == 0 else Color.WHITE)
			_text(Vector2(340, y), line["time"], 11, Color(0.88, 0.92, 1.0), 74, HORIZONTAL_ALIGNMENT_RIGHT)
			y += 15.0
		else:
			y += 4.0
			_mid(y, line["text"], 10, Color(1, 1, 0.75))
			y += 10.0
	_mid(267, "Space: leave", 10, Color(0.85, 0.88, 0.8))
