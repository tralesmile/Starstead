class_name RaceView
extends Node2D
## Time-trial race against a rival driver: press R while driving to start a lap around a ring
## of checkpoints near the start. Place pays prize money; best time is remembered.

signal message(msg: String)

const N_CP := 6
const RING := 300.0
var car: CarView
var world: World
var gen: WorldGen
var model: RaceModel
var laps := 1                       # L cycles 1-3 before the start
var rivals := {"rival": {"pos": Vector2.ZERO, "speed": 125.0}, "rival2": {"pos": Vector2.ZERO, "speed": 108.0}}
var running := false
var t := 0.0
var label: Label
var markers: Array = []
var rival_nodes: Dictionary = {}
const RIVAL_TINT := {"rival": Color(0.55, 0.75, 1.3), "rival2": Color(1.3, 1.2, 0.45)}

func setup(c: CarView, w: World, g: WorldGen, hud: Node) -> void:
	car = c
	world = w
	gen = g
	label = Label.new()
	label.position = Vector2(250, 6)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	var layer := CanvasLayer.new()
	layer.layer = 6
	layer.add_child(label)
	hud.add_child(layer)

func _drivable(c: Vector2i) -> bool:
	return gen.sdf_at(c.x, c.y) >= 2.0 and not (c in gen.trees) and not (c in gen.rocks) and not (c in gen.bushes)

func start() -> void:
	_clear_markers()
	var cps := RaceModel.ring_checkpoints(car.position, RING, N_CP, _drivable)
	model = RaceModel.new(cps, laps, 34.0)
	model.add_racer("you")
	var k := 0
	for id in rivals:
		model.add_racer(id)
		rivals[id]["pos"] = car.position + Vector2(0, 28 + 26 * k)
		var rn := Sprite2D.new()
		rn.texture = load("res://assets/sprites/car.png")
		rn.offset = Vector2(0, -6)
		rn.modulate = RIVAL_TINT.get(id, Color.WHITE)
		rn.position = rivals[id]["pos"]
		world.add_child(rn)
		rival_nodes[id] = rn
		k += 1
	t = 0.0
	running = true
	for p in cps:
		var m := ColorRect.new()
		m.size = Vector2(12, 12)
		m.position = p - Vector2(6, 6)
		m.color = Color(1, 1, 1, 0.5)
		m.z_index = -2
		world.add_child(m)
		markers.append(m)
	message.emit("Race! %d lap%s - hit the checkpoints in order" % [laps, "s" if laps > 1 else ""])

func _clear_markers() -> void:
	for id in rival_nodes:
		(rival_nodes[id] as Node).queue_free()
	rival_nodes.clear()
	for m in markers:
		m.queue_free()
	markers.clear()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and car.driving and not running:
		if e.keycode == KEY_R:
			start()
		elif e.keycode == KEY_L:
			laps = laps % 3 + 1
			message.emit("Race length: %d lap%s" % [laps, "s" if laps > 1 else ""])

func _process(delta: float) -> void:
	if not running:
		label.text = "R: start race (%d lap%s, L: change)" % [laps, "s" if laps > 1 else ""] if car.driving else ""
		return
	t += delta
	model.update("you", car.position, t)
	for id in rivals:
		var rcp: int = model.racers[id]["cp"]
		rivals[id]["pos"] = RaceModel.ai_step(rivals[id]["pos"], model.checkpoints[rcp], float(rivals[id]["speed"]), delta)
		model.update(id, rivals[id]["pos"], t)
		var rn2: Sprite2D = rival_nodes[id]
		var dv: Vector2 = rivals[id]["pos"] - rn2.position
		if dv.length() > 0.1:
			rn2.rotation = dv.angle()
		rn2.position = rivals[id]["pos"]
	for i in markers.size():
		var next: int = model.racers["you"]["cp"]
		(markers[i] as ColorRect).color = Color(1, 0.9, 0.2, 0.9) if i == next else Color(1, 1, 1, 0.4)
	label.text = "RACE lap %d/%d cp %d/%d  %.1fs  place %d/%d" % [mini(int(model.racers["you"]["lap"]) + 1, laps), laps, int(model.racers["you"]["cp"]) + 1, N_CP, t, model.place("you"), model.racers.size()]
	if model.is_finished("you") or t > 60.0 + 60.0 * laps:
		_finish()

func _finish() -> void:
	running = false
	var place := model.place("you") if model.is_finished("you") else 0
	var prize := model.payout_for_place(place) * laps
	GameState.money += prize
	var key := str(laps)
	var best_prev := float(GameState.race_best.get(key, -1.0))
	var best := model.is_finished("you") and (best_prev < 0.0 or t < best_prev)
	if best:
		GameState.race_best[key] = t
	if place == 0:
		message.emit("Race lost - out of time")
	else:
		message.emit("Place %d of %d! +$%d  %.1fs%s" % [place, model.racers.size(), prize, t, "  NEW BEST (%d lap)" % laps if best else ""])
	_clear_markers()
