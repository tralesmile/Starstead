class_name TownView
extends Node2D
## Builds the houses/barn/workshop from TownModel as y-sorted blocking props with door prompts.

var buildings: Array = []

func setup(world: World, gen: WorldGen, stall: Vector2i) -> void:
	var npcs: Dictionary = DataDB.load_json("npcs")
	var blocked: Array = []
	if stall.x >= 0:
		for dx in range(-1, 4):
			for dy in range(-1, 3):
				blocked.append(stall + Vector2i(dx, dy))
	for d in gen.dock:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				blocked.append(d + Vector2i(dx, dy))
	var ok := func(c: Vector2i) -> bool:
		return c.x > 1 and c.y > 1 and c.x < WorldGen.SIZE - 2 and c.y < WorldGen.SIZE - 2 and gen.sdf_at(c.x, c.y) >= 2.0 and gen.tile_at(c.x, c.y) < WorldGen.PATH and not (c in gen.trees) and not (c in gen.rocks) and not (c in gen.bushes)
	var home: Vector2i = Vector2i(int(npcs["npcs"][0]["home"][0]), int(npcs["npcs"][0]["home"][1]))
	buildings = TownModel.layout(npcs["places"], home, ok, blocked)
	for b in buildings:
		_make(world, gen, b)

func _make(world: World, gen: WorldGen, b: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.position = TownModel.sprite_bottom_center(b)
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/%s.png" % b["sprite"])
	s.offset = Vector2(0, -s.texture.get_height() / 2.0)
	body.add_child(s)
	body.add_child(World.make_shadow(s.texture.get_width() * 0.8))
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(float(b["w"]) * 32.0 - 6.0, 36.0)
	cs.shape = rs
	cs.position = Vector2(0, -20)
	body.add_child(cs)
	world.add_child(body)
	world.interactables.add(b["door"], "door", "E: %s (locked)" % b["name"])
