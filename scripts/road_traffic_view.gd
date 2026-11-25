class_name RoadTrafficView
extends Node2D
## Ambient life on the open-world roads (E11): a few cars keep to their lane and slow, stop and honk for whatever
## is in front (you on foot, your car, another car), and hikers stroll the verge by day. They appear out of sight
## and fade away behind you. Rules are in RoadTraffic (pure, tested); cars are solid bodies you can crash into.

var world: Node2D
var player: Node2D
var car: Node2D
var open_cb: Callable = Callable()   # Vector2 -> bool: false inside a story-locked region (no traffic there)
var night := 0.0
var roads: Array = []                # PackedVector2Array per road, in px
var cars: Array = []                 # {node, body, sprite, road, dist, fwd, speed, cruise, blocked, light, honk}
var hikers: Array = []               # {node, sprite, outfit, road, dist, fwd, speed, t, face, wait}
var rng := RandomNumberGenerator.new()
var spawn_cd := 0.0
var _serial := 0
var _tex: Texture2D
var ring := Vector2(RoadTraffic.SPAWN_MIN, RoadTraffic.SPAWN_MAX)   # demo flags pull it in so a screenshot shows traffic
var honks := 0                       # count, for QA

func setup(w: Node2D, p: Node2D, c: Node2D, net: RoadNet) -> void:
	world = w
	player = p
	car = c
	rng.seed = 7117
	roads.clear()
	for pl in net.polylines:
		roads.append(RoadTraffic.to_px(pl))
	var spine := RoadTraffic.spine_polyline(RoadNet.SPINE_X0, RoadNet.SPINE_X1, RoadNet.spine_y)
	roads.append(RoadTraffic.to_px(spine))
	_tex = load("res://assets/sprites/car.png")

func _hour() -> float:
	return NpcSchedule.hour_of(GameState.clock.minutes)

func _allowed(pos: Vector2) -> bool:
	var cell := Vector2i(floori(pos.x / 32.0), floori(pos.y / 32.0))
	if ChunkGrid.chunk_of_cell(cell) == ChunkGrid.HOME:
		return false
	return not open_cb.is_valid() or bool(open_cb.call(pos))

func _obstacles(skip: Node2D) -> Array:
	var out: Array = [player.position]
	if car != null:
		out.append(car.position)
	for v in cars:
		if v["node"] != skip:
			out.append((v["node"] as Node2D).position)
	return out

func _process(delta: float) -> void:
	if player == null or roads.is_empty():
		return
	_spawn_tick(delta)
	for v in cars.duplicate():
		_step_car(v, delta)
	for h in hikers.duplicate():
		_step_hiker(h, delta)

func _spawn_tick(delta: float) -> void:
	spawn_cd -= delta
	if spawn_cd > 0.0:
		return
	spawn_cd = 0.7
	var hr := _hour()
	if cars.size() < RoadTraffic.car_target(hr):
		_try_spawn(false)
	elif hikers.size() < RoadTraffic.hiker_target(hr):
		_try_spawn(true)

func _near(pts: PackedVector2Array, p: Vector2) -> Vector2:
	## (arc distance along the road of the closest point, distance from p to the road).
	var best := Vector2(0.0, INF)
	var acc := 0.0
	for i in range(pts.size() - 1):
		var q := Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1])
		var dd := q.distance_to(p)
		if dd < best.y:
			best = Vector2(acc + pts[i].distance_to(q), dd)
		acc += pts[i].distance_to(pts[i + 1])
	return best

func _try_spawn(hiker: bool) -> void:
	var near: Array = []   # roads that pass within spawn range of the player: {road, arc}
	for ri in roads.size():
		var n := _near(roads[ri], player.position)
		if n.y < ring.y:
			near.append({"road": ri, "arc": n.x})
	if near.is_empty():
		return
	for _try in 8:
		var pick: Dictionary = near[rng.randi() % near.size()]
		var ri: int = pick["road"]
		var pts: PackedVector2Array = roads[ri]
		var len := RoadTraffic.length(pts)
		var d := float(pick["arc"]) + rng.randf_range(-ring.y, ring.y)
		if d < 0.0 or d > len:
			continue
		var fwd := rng.randf() < 0.5
		var lp := RoadTraffic.lane_point(pts, d, fwd, RoadTraffic.VERGE if hiker else RoadTraffic.LANE)
		var pos: Vector2 = lp["pos"]
		if not RoadTraffic.in_view_ring(pos.distance_to(player.position), ring.x, ring.y) or not _allowed(pos):
			continue
		var clear := true
		for o in _obstacles(null):
			if (o as Vector2).distance_to(pos) < 90.0:
				clear = false
		if not clear:
			continue
		_serial += 1
		if hiker:
			_add_hiker(ri, d, fwd, lp)
		else:
			_add_car(ri, d, fwd, lp)
		return

func _add_car(ri: int, d: float, fwd: bool, lp: Dictionary) -> void:
	var body := AnimatableBody2D.new()
	body.sync_to_physics = false
	body.position = lp["pos"]
	var sh := World.make_shadow(30)
	body.add_child(sh)
	var sp := Sprite2D.new()
	sp.texture = _tex
	sp.offset = Vector2(0, -6)
	var paint: Color = GarageModel.PAINTS[(_serial * 3) % GarageModel.PAINTS.size()]["color"]
	sp.modulate = paint * Color(0.92, 0.92, 0.92)
	body.add_child(sp)
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(26, 14)
	cs.shape = rs
	body.add_child(cs)
	var light := PointLight2D.new()
	light.texture = CarView.cone_texture()
	light.texture_scale = 1.2
	light.offset = Vector2(100, 0)
	light.energy = 0.0
	light.visible = false
	body.add_child(light)
	var tail := PointLight2D.new()   # red brake glow, lit while the car is braking or stopped
	tail.texture = CarView.cone_texture()
	tail.texture_scale = 0.5
	tail.rotation = PI
	tail.offset = Vector2(36, 0)
	tail.color = Color(1.0, 0.2, 0.15)
	tail.energy = 0.0
	body.add_child(tail)
	var honk := Label.new()
	honk.text = "BEEP!"
	honk.add_theme_font_size_override("font_size", 10)
	honk.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	honk.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	honk.add_theme_constant_override("font_outline_size", 3)
	honk.position = Vector2(-16, -34)
	honk.visible = false
	body.add_child(honk)
	body.rotation = float(lp["heading"])
	honk.rotation = -body.rotation   # keep the label upright
	world.add_child(body)
	var cruise := RoadTraffic.cruise_speed(_serial)
	cars.append({"node": body, "sprite": sp, "road": ri, "dist": d, "fwd": fwd, "speed": cruise, "cruise": cruise,
		"blocked": 0.0, "stall": 0.0, "shove": Vector2.ZERO, "light": light, "tail": tail, "honk": honk, "honk_t": 0.0})

func _add_hiker(ri: int, d: float, fwd: bool, lp: Dictionary) -> void:
	var body := Node2D.new()
	var outfit := NpcLook.outfit_of("hiker_%d" % _serial)
	var s := NpcLook.make_sprite(outfit)
	body.add_child(s)
	var sh := World.make_shadow(20)
	sh.scale = Vector2(0.6, 0.7)
	body.add_child(sh)
	body.position = lp["pos"]
	world.add_child(body)
	hikers.append({"node": body, "sprite": s, "outfit": outfit, "road": ri, "dist": d, "fwd": fwd,
		"speed": RoadTraffic.hiker_speed(_serial), "t": 0.0, "face": 0})

func _step_car(v: Dictionary, delta: float) -> void:
	var body: Node2D = v["node"]
	var pts: PackedVector2Array = roads[int(v["road"])]
	var len := RoadTraffic.length(pts)
	var along := float(v["dist"]) * 1.0
	var sign_ := 1.0 if bool(v["fwd"]) else -1.0
	var lp := RoadTraffic.lane_point(pts, along, bool(v["fwd"]))
	var heading := float(lp["heading"])
	var gap := RoadTraffic.gap_ahead(body.position, heading, _obstacles(body))
	var target := RoadTraffic.follow_speed(float(v["cruise"]), gap)
	if car != null and float(v["stall"]) <= 0.0 and car.position.distance_to(body.position) < 28.0 and (car.get("vel") as Vector2).length() > 45.0:
		var hit := RoadTraffic.hit_response((car.get("vel") as Vector2).length(), body.position - car.position)
		v["stall"] = hit["stall"]
		v["shove"] = hit["shove"]
		v["speed"] = 0.0
	if float(v["stall"]) > 0.0:
		v["stall"] = float(v["stall"]) - delta
		target = 0.0
		(v["honk"] as Label).text = "!!" if float(v["stall"]) > 0.0 else "BEEP!"
	v["shove"] = RoadTraffic.shove_decay(v["shove"], delta)
	if not _allowed(body.position):
		target = 0.0
	v["speed"] = RoadTraffic.ease_speed(float(v["speed"]), target, delta)
	v["blocked"] = (float(v["blocked"]) + delta) if (target < 5.0 and float(v["speed"]) < 5.0) else 0.0
	if RoadTraffic.honks(float(v["blocked"])) and float(v["honk_t"]) <= 0.0:
		v["honk_t"] = 1.2
		honks += 1
	var ht := float(v["honk_t"])
	if ht > 0.0:
		v["honk_t"] = ht - delta
	(v["honk"] as Label).visible = float(v["honk_t"]) > 0.0 or float(v["stall"]) > 0.0
	v["dist"] = along + sign_ * float(v["speed"]) * delta
	var np := RoadTraffic.lane_point(pts, float(v["dist"]), bool(v["fwd"]))
	body.position = (np["pos"] as Vector2) + (v["shove"] as Vector2)
	body.rotation = lerp_angle(body.rotation, float(np["heading"]), clampf(delta * 6.0, 0.0, 1.0))
	(v["honk"] as Label).rotation = -body.rotation
	var light: PointLight2D = v["light"]
	var braking := target < float(v["speed"]) - 2.0 or (float(v["speed"]) < 3.0 and target < 3.0)
	(v["tail"] as PointLight2D).energy = 1.4 if braking else 0.35 * night
	(v["tail"] as PointLight2D).visible = braking or night > 0.05
	light.energy = 1.2 * night
	light.visible = night > 0.05
	if RoadTraffic.should_despawn(body.position.distance_to(player.position), float(v["dist"]), len):
		body.queue_free()
		cars.erase(v)

func _step_hiker(h: Dictionary, delta: float) -> void:
	var body: Node2D = h["node"]
	var pts: PackedVector2Array = roads[int(h["road"])]
	var len := RoadTraffic.length(pts)
	var sign_ := 1.0 if bool(h["fwd"]) else -1.0
	var wait := float(h["wait"]) if h.has("wait") else 0.0
	var before := body.position
	if player.position.distance_to(body.position) < 22.0:
		wait = 0.5   # stops to let you by
	if wait > 0.0:
		h["wait"] = wait - delta
	else:
		h["dist"] = float(h["dist"]) + sign_ * float(h["speed"]) * delta
	var lp := RoadTraffic.lane_point(pts, float(h["dist"]), bool(h["fwd"]), RoadTraffic.VERGE)
	body.position = lp["pos"]
	h["face"] = NpcSchedule.facing_of(body.position - before, int(h["face"]))
	var moving := body.position.distance_to(before) > 0.01
	h["t"] = float(h["t"]) + (delta if moving else 0.0)
	(h["sprite"] as Sprite2D).frame = NpcLook.frame(h["outfit"], h["face"], PlayerMath.walk_frame_hd(float(h["t"]) * 0.8, true) if moving else 0)
	if body.position.distance_to(player.position) > RoadTraffic.DESPAWN or float(h["dist"]) < -40.0 or float(h["dist"]) > len + 40.0 or not _allowed(body.position) or hikers.size() > RoadTraffic.hiker_target(_hour()) + 1:
		body.queue_free()
		hikers.erase(h)

func clear() -> void:
	for v in cars:
		(v["node"] as Node2D).queue_free()
	for h in hikers:
		(h["node"] as Node2D).queue_free()
	cars.clear()
	hikers.clear()

func debug_text() -> String:
	var out := ""
	for v in cars:
		var b: Node2D = v["node"]
		out += "car r%d d%.0f fwd%s sp%.0f blk%.1f pos%s\n" % [v["road"], v["dist"], v["fwd"], v["speed"], v["blocked"], b.position]
	return out
