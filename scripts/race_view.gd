class_name RaceView
extends Node2D
## Time-trial race against a rival driver: press R while driving to start a lap around a ring
## of checkpoints near the start. Place pays prize money; best time is remembered.

signal message(msg: String)

const N_CP := 6
const RING := 300.0
const RIVAL_SPEED := 125.0
var car: CarView
var world: World
var gen: WorldGen
var model: RaceModel
var rival_pos := Vector2.ZERO
var running := false
var t := 0.0
var label: Label
var markers: Array = []

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
	var cps := RaceModel.ring_checkpoints(car.position, RING, N_CP, _drivable)
	model = RaceModel.new(cps, 1, 34.0)
	model.add_racer("you")
	model.add_racer("rival")
	rival_pos = car.position + Vector2(0, 28)
	t = 0.0
	running = true
	_clear_markers()
	for p in cps:
		var m := ColorRect.new()
		m.size = Vector2(12, 12)
		m.position = p - Vector2(6, 6)
		m.color = Color(1, 1, 1, 0.5)
		m.z_index = -2
		world.add_child(m)
		markers.append(m)
	message.emit("Race! Hit the checkpoints in order")

func _clear_markers() -> void:
	for m in markers:
		m.queue_free()
	markers.clear()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_R and car.driving and not running:
		start()

func _process(delta: float) -> void:
	if not running:
		label.text = "R: start race" if car.driving else ""
		return
	t += delta
	model.update("you", car.position, t)
	var rcp: int = model.racers["rival"]["cp"]
	rival_pos = RaceModel.ai_step(rival_pos, model.checkpoints[rcp], RIVAL_SPEED, delta)
	model.update("rival", rival_pos, t)
	for i in markers.size():
		var next: int = model.racers["you"]["cp"]
		(markers[i] as ColorRect).color = Color(1, 0.9, 0.2, 0.9) if i == next else Color(1, 1, 1, 0.4)
	label.text = "RACE cp %d/%d  %.1fs  place %d" % [int(model.racers["you"]["cp"]) + 1, N_CP, t, model.place("you")]
	if model.is_finished("you") or model.is_finished("rival") or t > 120.0:
		_finish()

func _finish() -> void:
	running = false
	var place := model.place("you") if model.is_finished("you") else 0
	var prize := model.payout_for_place(place)
	GameState.money += prize
	var best := model.is_finished("you") and model.best_time == float(model.racers["you"]["finish"])
	if place == 0:
		message.emit("Race lost - the rival finished first")
	else:
		message.emit("Place %d! +$%d  %.1fs%s" % [place, prize, t, "  NEW BEST" if best else ""])
	_clear_markers()
