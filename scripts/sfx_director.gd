class_name SfxDirector
extends Node
## Wires play to sound (Sfx + SfxSynth): footsteps, tool results, money, menus and the weather ambience.
## main.gd only creates it and calls `play` for one-off events. N mutes.

var m   # Main
var sfx := Sfx.new()
var _money := 0
var _menu := false
var _near_water := 0.0
var _water_t := 0.0

const TOOL_SOUNDS := {"Tilled": "hoe", "Watered": "water_pour"}

func setup(main) -> void:
	m = main
	add_child(sfx)
	_money = GameState.money
	m.player.footstep.connect(_step)
	m.bow.sound.connect(func(n: String): play(n))
	m.bow.impact.connect(func(at: Vector2, kind: String):
		play("arrow_hit", 1.0 if kind != "ground" else 0.5)
		ImpactFx.spawn(m.world, at, kind))
	m.drops_view.picked.connect(func(_id, _n): play("pickup"))
	m.isle_view.found.connect(func(_id, _at): play("pickup"))

func play(name: String, gain: float = 1.0, pitch: float = 1.0) -> void:
	sfx.play(name, gain, pitch)

func tool_result(tool: String, msg: String) -> void:
	## Called after a tool use that did something.
	if TOOL_SOUNDS.has(msg):
		play(TOOL_SOUNDS[msg])
	elif tool == "axe" and msg.begins_with("Got"):
		play("tree_fall")
	elif tool == "axe" and msg == "Hit":
		play("chop")
	elif tool == "pickaxe" and (msg == "Hit" or msg.begins_with("Got")):
		play("mine")
	elif tool == "scythe":
		play("swing")
	elif msg.begins_with("Harvested"):
		play("pickup")

static func water_nearness(gen, pos: Vector2) -> float:
	## 0..1 from the closest water within 6 tiles (drives the lapping-waves loop).
	var c := Vector2i(floori(pos.x / 32.0), floori(pos.y / 32.0))
	var best := 99.0
	for dy in range(-6, 7, 2):
		for dx in range(-6, 7, 2):
			if gen.sdf_at(c.x + dx, c.y + dy) < 0.0:
				best = minf(best, Vector2(dx, dy).length())
	return clampf(1.0 - best / 7.0, 0.0, 1.0)

func _step() -> void:
	var c := Vector2i(floori(m.player.position.x / 32.0), floori(m.player.position.y / 32.0))
	var on_wood: bool = c in m.world.gen.dock or IsleModel.is_jetty(c)
	var name := SfxSynth.footstep_name(m.world.gen.tile_at(c.x, c.y), GameState.clock.season(), m._indoors(), m.rain_today, on_wood)
	play(name, 0.8 if m.player.sprinting else 0.5)

func _menu_open() -> bool:
	for v in [m.shop, m.dealer, m.inv_view, m.craft_view, m.chest_view, m.cook_view, m.bus_view, m.forge_view, m.butcher_view, m.smelt_view, m.upgrade_view, m.garage_view, m.journal_view]:
		if v.visible:
			return true
	return m.map_view.is_open() or m.story_view.log_open()

func _process(delta: float) -> void:
	if m == null:
		return
	_water_t -= delta
	if _water_t <= 0.0:
		_water_t = 0.4
		_near_water = 0.0 if m._indoors() else water_nearness(m.world.gen, m.player.position)
	var hour := fposmod(6.0 + GameState.clock.minutes / 60.0, 24.0)
	sfx.set_ambience(SfxSynth.ambience_levels(m.weather.now, hour, GameState.clock.season(), m.interior.active, _near_water, m.cave.active), delta)
	if GameState.money != _money:
		play("coin", 0.8, 1.0 if GameState.money > _money else 0.82)
		_money = GameState.money
	var open := _menu_open()
	if open != _menu:
		_menu = open
		play("ui_open" if open else "ui_close", 0.7)

func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_N:
		m._say("Sound off (N)" if sfx.toggle_mute() else "Sound on (N)")
