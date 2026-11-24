class_name DerbyView
extends CanvasLayer
## Animal derby overlay (rules in DerbyModel): 4 runners, hold Space to gallop, release to trot and breathe. Esc leaves.

signal closed
signal message(msg: String)

var canvas: Control
var runners: Array = []
var skills: Array = [0.0, 0.35, 0.6, 0.85]
var tints: Array = [Color(1, 1, 1), Color(0.75, 0.85, 1.0), Color(1.0, 0.85, 0.6), Color(0.8, 1.0, 0.8)]
var times: Array = [-1.0, -1.0, -1.0, -1.0]
var t := 0.0
var countdown := 2.4
var finished := false
var mount_name := "Stable pony"
var last_text := ""
var racer_tex: Texture2D
var post_tex: Texture2D
var dust: Array = []     # {lane, x, age}
var dust_t := 0.0
var spawn_dust := false
var force_gallop := false     # demo helper
const BOX := Rect2(50, 60, 540, 240)

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false
	racer_tex = load("res://assets/sprites/derby_racer.png")
	post_tex = load("res://assets/sprites/derby_finish.png")

func open() -> bool:
	if GameState.money < DerbyModel.FEE:
		message.emit("The derby entry fee is $%d" % DerbyModel.FEE)
		return false
	GameState.money -= DerbyModel.FEE
	var bonus := 0.0
	mount_name = "Stable pony"
	var am := AnimalModel.new(DataDB.load_json("animals"))
	var best := -1.0
	for st in GameState.animals:
		var def: Dictionary = am.animals.get(st["id"], {})
		if bool(def.get("rideable", false)):
			var b := DerbyModel.bonus_for(am.bond(st), am.gear_total(st, "speed") * 0.25)
			if b > best:
				best = b
				bonus = b
				mount_name = String(def.get("name", "Mount"))
	runners = []
	for i in 4:
		runners.append(DerbyModel.runner(bonus if i == 0 else 0.04 * skills[i]))
	times = [-1.0, -1.0, -1.0, -1.0]
	t = 0.0
	countdown = 2.4
	finished = false
	last_text = "%s at the gate. Hold Space to gallop, release to rest" % mount_name
	visible = true
	return true

func close() -> void:
	visible = false
	closed.emit()

func handle(e: InputEvent) -> bool:
	if visible and e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE or (finished and (e.keycode == KEY_E or e.keycode == KEY_SPACE)):
			close()
		return true
	return visible

func _process(d: float) -> void:
	if not visible:
		return
	canvas.size = get_viewport().get_visible_rect().size
	if not finished:
		if countdown > 0.0:
			countdown -= d
		else:
			dust_t -= d
			spawn_dust = dust_t <= 0.0
			if spawn_dust:
				dust_t = 0.07
			for p in dust:
				p["age"] = float(p["age"]) + d
			dust = dust.filter(func(p): return float(p["age"]) < 0.6)
			t += d
			for i in 4:
				var r: Dictionary = runners[i]
				if DerbyModel.finished(r):
					continue
				var g: bool = (Input.is_key_pressed(KEY_SPACE) or force_gallop) if i == 0 else DerbyModel.rival_gallops(r, skills[i])
				var poss: Array = []
				for q in runners:
					poss.append(q["pos"])
				DerbyModel.step(r, g, d * DerbyModel.draft_mult(DerbyModel.nearest_ahead_gap(poss, i)))
				if g and spawn_dust:
					dust.append({"lane": i, "x": float(r["pos"]), "age": 0.0})
				if DerbyModel.finished(r):
					times[i] = t
			if DerbyModel.finished(runners[0]):
				_finish()
	canvas.queue_redraw()

func _finish() -> void:
	finished = true
	var poss: Array = []
	for r in runners:
		poss.append(r["pos"])
	# keep the others running to the line in rank order: rank the rest by position
	var pl := DerbyModel.place(poss, times, 0)
	var pay := DerbyModel.prize(pl)
	GameState.money += pay
	GameState.bump("derbies_run")
	if pl == 0:
		GameState.bump("derbies_won")
	var key := "derby_best"
	var ms := int(t * 100.0)
	if pl == 0 and (not GameState.sport_best.has(key) or ms < int(GameState.sport_best[key])):
		GameState.sport_best[key] = ms
	last_text = "%s place%s. %s   (Space: leave)" % [["1st", "2nd", "3rd", "4th"][pl], " - prize $%d" % pay if pay > 0 else "", "A clean run!" if pl == 0 else "Pace your gallop: rest when the bar runs low."]
	message.emit("Derby: %s" % ["1st", "2nd", "3rd", "4th"][pl])

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_rect(BOX.grow(2), Color(0.1, 0.14, 0.08))
	canvas.draw_rect(BOX, Color(0.28, 0.42, 0.22, 0.97))
	var o := BOX.position + Vector2(16, 22)
	canvas.draw_string(font, o, "Animal derby    Esc: leave", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.95, 0.7))
	var x0 := BOX.position.x + 20.0
	var w := BOX.size.x - 90.0
	for i in 4:
		var y := BOX.position.y + 40.0 + i * 36.0
		canvas.draw_rect(Rect2(x0, y + 28, w + 40, 2), Color(1, 1, 1, 0.25))
		if i < runners.size():
			var r: Dictionary = runners[i]
			var px := x0 + w * clampf(float(r["pos"]) / DerbyModel.TRACK, 0.0, 1.0)
			for p in dust:
				if int(p["lane"]) == i:
					var a: float = float(p["age"]) / 0.6
					var dx := x0 + w * clampf(float(p["x"]) / DerbyModel.TRACK, 0.0, 1.0)
					canvas.draw_circle(Vector2(dx + 4, y + 27 - a * 9.0), 2.0 + a * 4.0, Color(0.78, 0.68, 0.48, 0.5 * (1.0 - a)))
			var fr := int(float(r["pos"]) / 6.0) % 4 if not r["winded"] else 0
			var bob := sin(float(r["pos"]) * 0.5) * 1.5
			canvas.draw_texture_rect_region(racer_tex, Rect2(px, y - 2 + bob, 48, 32), Rect2(fr * 48, 0, 48, 32), tints[i] if i > 0 else Color(1, 0.95, 0.8))
			if i == 0:
				canvas.draw_string(font, Vector2(px + 10, y - 6), "YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 0.5))
	canvas.draw_texture_rect(post_tex, Rect2(x0 + w + 48, BOX.position.y + 36, 12, 144), false)
	if not runners.is_empty():
		var s := float(runners[0]["stamina"])
		var by := BOX.position.y + BOX.size.y - 34.0
		canvas.draw_rect(Rect2(o.x, by, 200, 10), Color(0.1, 0.1, 0.1))
		canvas.draw_rect(Rect2(o.x, by, 200.0 * s, 10), Color(0.9, 0.35, 0.25) if runners[0]["winded"] else Color(0.4, 0.85, 0.4))
		canvas.draw_string(font, Vector2(o.x + 210, by + 9), "WINDED" if runners[0]["winded"] else "stamina", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	if countdown > 0.0 and not finished:
		canvas.draw_string(font, BOX.position + Vector2(230, 120), str(ceili(countdown)), HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1, 0.9, 0.3))
	canvas.draw_string(font, Vector2(o.x, BOX.position.y + BOX.size.y - 8), last_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 0.7))
