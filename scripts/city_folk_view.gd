class_name CityFolkView
extends Node2D
## Port Halden street life (E9): pedestrians in villager outfits stroll the sidewalks, cross at zebras,
## idle at shop doors, sit a while on benches, and thin out at night; one or two cops walk a beat.
## Rules live in CityFolk (pure, tested). Visual only: no collision, they step aside for the player.

var world: Node2D
var player: Node2D
var rng := RandomNumberGenerator.new()
var grid: AStarGrid2D
var blocked: Dictionary
var spots: Array = []
var walkers: Array = []   # {node, sprite, outfit, cop, path: Array[Vector2i], lane, wait, kind, face, t, leaving}
var spawn_cd := 0.0
signal message(text: String)
var combat: CombatView   # knocked-out walkers lie still until they get up

func targets() -> Array:
	## [node, sprite] pairs for CombatView (club swings and car hits).
	var out: Array = []
	for w in walkers:
		out.append([w["node"], w["sprite"]])
	return out

func _down(w: Dictionary) -> bool:
	return combat != null and combat.is_down(w["node"])
var _serial := 0

func setup(w: Node2D, p: Node2D) -> void:
	world = w
	player = p
	rng.seed = 4242

func _ensure_grid() -> void:
	if grid == null:
		blocked = CityFolk.blocked_cells()
		grid = CityFolk.build_grid(blocked)
		spots = CityFolk.spots()

func count(cops: bool = false) -> int:
	var n := 0
	for w in walkers:
		if bool(w["cop"]) == cops:
			n += 1
	return n

func _process(delta: float) -> void:
	if player == null:
		return
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	if not CityFolk.active(pc):
		if not walkers.is_empty():
			clear()
		return
	_ensure_grid()
	var h := NpcSchedule.hour_of(GameState.clock.minutes)
	var first := walkers.is_empty()
	_balance(CityFolk.density(h), false, first)
	_balance(CityFolk.cop_count(h), true, first)
	for w in walkers.duplicate():
		_step(w, delta)

func clear() -> void:
	for w in walkers:
		(w["node"] as Node2D).queue_free()
	walkers.clear()

func witnessed(pos: Vector2) -> bool:
	## PoliceView asks this when a crime happens: anyone on the street close enough saw it.
	var ps: Array = []
	for w in walkers:
		ps.append((w["node"] as Node2D).position)
	return CityFolk.witnesses(ps, pos) > 0

func on_crime(_kind: String, pos: Vector2) -> void:

	## Everyone nearby screams and runs for the nearest safe door (and goes inside); beat cops come to look.
	if walkers.is_empty():
		return
	_ensure_grid()
	var doors: Array = spots.filter(func(s): return s["kind"] == "door")
	var crime_cell := Vector2i(floori(pos.x / 32.0), floori(pos.y / 32.0))
	var ps: Array = []
	for w in walkers:
		ps.append((w["node"] as Node2D).position)
	var n := CityFolk.witnesses(ps, pos)
	for w in walkers:
		var body: Node2D = w["node"]
		if _down(w) or not CityFolk.panics(body.position, pos):
			continue
		var here := Vector2i(floori(body.position.x / 32.0), floori(body.position.y / 32.0))
		if grid.is_point_solid(here):
			here = _nearest_walkable(here)
		if bool(w["cop"]):
			var r := CityFolk.route(grid, here, _nearest_walkable(crime_cell) if grid.is_point_solid(crime_cell) else crime_cell)
			if r.size() > 1:
				w["path"] = r
				w["wait"] = 0.0
				w["kind"] = "plaza"
				w["panic"] = CityFolk.SCREAM_SECS
			continue
		var r2 := CityFolk.route(grid, here, CityFolk.flee_spot(doors, here, crime_cell))
		if r2.size() > 1:
			w["path"] = r2
			w["kind"] = "door"
			w["leaving"] = true
			w["wait"] = 0.0
			w["panic"] = CityFolk.SCREAM_SECS
			(w["alarm"] as Label).visible = true
	if n > 0:
		message.emit("%d witness%s saw that!" % [n, "" if n == 1 else "es"])

func _balance(target: int, cops: bool, instant: bool) -> void:
	var have := 0
	for w in walkers:
		if bool(w["cop"]) == cops and not bool(w["leaving"]):
			have += 1
	if have > target:
		for w in walkers:   # the extra ones head home: next door they reach, they go inside
			if bool(w["cop"]) == cops and not bool(w["leaving"]):
				w["leaving"] = true
				have -= 1
				if have <= target:
					break
	elif have < target:
		spawn_cd -= get_process_delta_time()
		while have < target and (instant or spawn_cd <= 0.0):
			_spawn(cops, instant)
			have += 1
			spawn_cd = 1.2
			if not instant:
				break

func _spawn(cop: bool, anywhere: bool) -> void:
	## On arrival in the city people are already spread out; later ones step out of a door.
	var doors: Array = spots.filter(func(s): return s["kind"] == "door")
	var from: Dictionary = (spots if anywhere else doors)[rng.randi() % (spots.size() if anywhere else doors.size())]
	_serial += 1
	var outfit := NpcLook.POLICE if cop else NpcLook.outfit_of("walker_%d" % _serial)
	var body := Node2D.new()
	var s := NpcLook.make_sprite(outfit)
	body.add_child(s)
	var sh := World.make_shadow(20)
	sh.scale = Vector2(0.6, 0.7)
	body.add_child(sh)
	var alarm := Label.new()
	alarm.text = "!"
	alarm.add_theme_font_size_override("font_size", 14)
	alarm.add_theme_color_override("font_color", Color(1, 0.3, 0.2))
	alarm.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	alarm.add_theme_constant_override("font_outline_size", 3)
	alarm.position = Vector2(-3, -62)
	alarm.visible = false
	body.add_child(alarm)
	var lane := rng.randf_range(-1.0, 1.0)
	body.position = CityFolk.cell_px(from["cell"], lane)
	world.add_child(body)
	var w := {"node": body, "sprite": s, "outfit": outfit, "cop": cop, "path": [] as Array[Vector2i], "lane": lane,
		"wait": rng.randf_range(0.0, 2.0), "kind": "", "face": 0, "t": 0.0, "leaving": false, "panic": 0.0, "alarm": alarm}
	walkers.append(w)
	_next_goal(w)

func _next_goal(w: Dictionary) -> void:
	var body: Node2D = w["node"]
	var here := Vector2i(floori(body.position.x / 32.0), floori(body.position.y / 32.0))
	if grid.is_point_solid(here) or not grid.is_in_boundsv(here):
		here = _nearest_walkable(here)
	var pool: Array = spots
	if bool(w["leaving"]):
		pool = spots.filter(func(s): return s["kind"] == "door")
	for _try in 4:
		var goal: Dictionary = pool[rng.randi() % pool.size()]
		if goal["cell"] == here:
			continue
		var r := CityFolk.route(grid, here, goal["cell"])
		if r.size() > 1:
			w["path"] = r
			w["kind"] = goal["kind"]
			return
	w["wait"] = 1.0   # boxed in for a moment; try again shortly

func _nearest_walkable(c: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if grid.is_in_boundsv(n) and not grid.is_point_solid(n):
					return n
	return CityFolk.CENTER

func _step(w: Dictionary, delta: float) -> void:
	var body: Node2D = w["node"]
	if _down(w):
		w["path"] = [] as Array[Vector2i]   # after getting up: limp home through the nearest door
		w["leaving"] = true
		w["wait"] = 1.0
		return
	var spr: Sprite2D = w["sprite"]
	var before := body.position
	if float(w["wait"]) > 0.0:
		w["wait"] = float(w["wait"]) - delta
		w["t"] = 0.0
		spr.frame = NpcLook.frame(w["outfit"], w["face"], 0)
		if float(w["wait"]) <= 0.0 and (w["path"] as Array).is_empty():
			_next_goal(w)
		return
	var path: Array = w["path"]
	if path.is_empty():
		_arrive(w)
		return
	# give way: pause when the player stands right in front
	if float(w["panic"]) <= 0.0 and player.position.distance_to(body.position) < 18.0 and (player.position - body.position).dot(CityFolk.cell_px(path[0], w["lane"]) - body.position) > 0.0:
		w["wait"] = 0.4
		return
	var target := CityFolk.cell_px(path[0], w["lane"])
	var speed := CityFolk.COP_SPEED if bool(w["cop"]) else CityFolk.SPEED
	var panic := float(w["panic"])
	if panic > 0.0:
		w["panic"] = panic - delta
		speed *= CityFolk.PANIC_SPEED
		if float(w["panic"]) <= 0.0:
			(w["alarm"] as Label).visible = false
	body.position = body.position.move_toward(target, speed * delta)
	var others: Array = []
	for o in walkers:
		if o != w and not _down(o):
			var op: Vector2 = (o["node"] as Node2D).position
			if op.distance_squared_to(body.position) < 400.0:
				others.append(op)
	if not others.is_empty():
		var np := body.position + CityFolk.separation(body.position, others) * delta
		if CityFolk.walkable(Vector2i(floori(np.x / 32.0), floori(np.y / 32.0)), blocked):
			body.position = np
	if body.position.distance_to(target) < 0.5:
		path.pop_front()
	var d := body.position - before
	w["face"] = NpcSchedule.facing_of(d, int(w["face"]))
	w["t"] = float(w["t"]) + delta
	spr.frame = NpcLook.frame(w["outfit"], w["face"], PlayerMath.walk_frame_hd(float(w["t"]) * 0.8, true))

func _arrive(w: Dictionary) -> void:
	var kind := String(w["kind"])
	if bool(w["leaving"]) and kind == "door" and not _down(w):
		(w["node"] as Node2D).queue_free()
		walkers.erase(w)
		return
	w["face"] = 2 if kind == "door" else 0   # look at the shop window / sit facing the plaza
	w["wait"] = CityFolk.dwell(kind, rng.randf()) * (0.5 if bool(w["cop"]) else 1.0)
	w["kind"] = ""
