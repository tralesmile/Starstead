class_name IsleView
extends Node2D
## World layer for E13: jetty planks, today's beach finds (walk over to take them), the moored ferry bobbing at both
## ends and the Halden lighthouse beam. A child of World; the rules live in IsleModel / FerryModel / LighthouseMath.

signal found(item: String, at: Vector2)

const REACH := 18.0

var player: Player
var rain := 0.0
var lamp := 0.0          # DayNight.lamp_strength
var haze := 0.0
var finds: Array = []    # {cell, item}
var _day := -1
var _t := 0.0
var _props: Texture2D = load("res://assets/sprites/isle_props.png")
var _boats: Array = []
var _planks: Node2D
var _beam: Node2D

func _ready() -> void:
	_planks = Node2D.new()
	_planks.z_index = -8
	_planks.draw.connect(_draw_jetty)
	add_child(_planks)
	for at in [FerryModel.HARBOUR_MOOR, FerryModel.ISLE_MOOR]:
		var s := Sprite2D.new()
		s.texture = load("res://assets/sprites/ferry.png")
		s.position = (at as Vector2) * 32.0
		add_child(s)
		_boats.append(s)
	_beam = Node2D.new()
	_beam.position = Vector2(233, 120) * 32.0 + Vector2(16, -52)
	_beam.z_index = 40
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_beam.material = mat
	_beam.draw.connect(_draw_beam)
	add_child(_beam)

func refresh(day: int) -> void:
	_day = day
	var stormy := WeatherMath.rain_for_day(1, day - 1, GameState.clock.season()) >= IsleModel.STORM_RAIN
	finds = GameState.isle.remaining(day, IsleModel.forage(day, stormy))
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _day != GameState.clock.day:
		refresh(GameState.clock.day)
	var b := FerryModel.bob(_t, rain)
	for i in _boats.size():
		(_boats[i] as Sprite2D).offset = Vector2(0, -22.0 + float(b["y"]) * (1.0 if i == 0 else -1.0))
		(_boats[i] as Sprite2D).rotation = float(b["roll"])
	_beam.visible = lamp > 0.01
	if _beam.visible:
		_beam.queue_redraw()
	if player == null:
		return
	if player.position.distance_to(IsleModel.CENTER * 32.0) < 900.0:
		for i in range(finds.size() - 1, -1, -1):
			var c: Vector2i = finds[i]["cell"]
			var at := Vector2(c) * 32.0 + Vector2(16, 22)
			if player.position.distance_to(at) < REACH:
				var item := String(finds[i]["item"])
				if GameState.bag.add(item, 1) == 0:
					GameState.isle.pick(_day, c)
					finds.remove_at(i)
					found.emit(item, at)
		queue_redraw()

func _draw() -> void:
	for f in finds:
		var c: Vector2i = f["cell"]
		var p := Vector2(c) * 32.0
		draw_texture_rect_region(_props, Rect2(p, Vector2(32, 32)), Rect2(32.0 * IsleModel.frame_for(String(f["item"])), 0, 32, 32))
		var tw := fposmod(_t * 0.7 + float(c.x * 13 + c.y * 7) * 0.31, 2.0)
		if tw < 0.35:   # a glint so finds read from a few tiles away
			var s := sin(tw / 0.35 * PI) * 4.0
			var g := p + Vector2(21, 14)
			draw_line(g - Vector2(s, 0), g + Vector2(s, 0), Color(1, 1, 0.9, 0.9), 1.0)
			draw_line(g - Vector2(0, s), g + Vector2(0, s), Color(1, 1, 0.9, 0.9), 1.0)

func _draw_jetty() -> void:
	var r := Rect2(Vector2(IsleModel.JETTY.position) * 32.0, Vector2(IsleModel.JETTY.size) * 32.0)
	_planks.draw_rect(Rect2(r.position + Vector2(0, r.size.y), Vector2(r.size.x, 7)), Color(0.05, 0.1, 0.14, 0.45))   # shade on the water
	_planks.draw_rect(r, Color(0.47, 0.31, 0.17))
	var x := r.position.x
	var i := 0
	while x < r.end.x:
		var shade := 0.04 * float((i * 5) % 3)
		_planks.draw_rect(Rect2(x + 1, r.position.y + 1, 6, r.size.y - 2), Color(0.62 - shade, 0.43 - shade, 0.24 - shade))
		_planks.draw_rect(Rect2(x + 1, r.position.y + 1, 1, r.size.y - 2), Color(0.78, 0.58, 0.34, 0.7))
		_planks.draw_rect(Rect2(x + 3, r.position.y + 4 + (i * 17) % 80, 2, 2), Color(0.25, 0.16, 0.08))
		x += 8.0
		i += 1
	for side in [r.position.y, r.end.y]:   # posts and a sagging rope rail
		var prev := Vector2.INF
		var px := r.position.x + 4.0
		while px <= r.end.x:
			var top := Vector2(px, side - 9.0)
			_planks.draw_rect(Rect2(px - 3, side - 10, 6, 14), Color(0.22, 0.13, 0.07))
			_planks.draw_rect(Rect2(px - 2, side - 9, 4, 12), Color(0.55, 0.37, 0.2))
			if prev != Vector2.INF:
				_planks.draw_polyline(PackedVector2Array([prev, (prev + top) * 0.5 + Vector2(0, 4), top]), Color(0.85, 0.74, 0.5), 1.0)
			prev = top
			px += 64.0

func _draw_beam() -> void:
	var k := LighthouseMath.strength(lamp, haze)
	if k <= 0.0:
		return
	var a := LighthouseMath.angle(_t)
	for dir in [0.0, PI]:
		for layer in [[1.0, 1.0, 0.55], [0.7, 0.5, 0.6]]:   # [length, width, alpha]: soft edge + bright core
			var pts := LighthouseMath.beam(a + dir, LighthouseMath.LENGTH * float(layer[0]), LighthouseMath.HALF_WIDTH * float(layer[1]))
			var c0 := Color(1.0, 0.93, 0.7, k * float(layer[2]))
			_beam.draw_polygon(pts, PackedColorArray([c0, Color(c0, 0.0), Color(c0, 0.0)]))
	_beam.draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.95, 0.75, minf(1.0, k * 2.6)))
