class_name ForestryView
extends Node
## World side of Forestry: sapling sprites, planted trees, the big hardwood stumps, and planting from the hotbar.

const SPOT_SEARCH := 6

var m   # Main
var world: World
var sapling_tex: Texture2D = load("res://assets/sprites/saplings.png")
var stump_tex: Texture2D = load("res://assets/sprites/big_stump.png")
var sapling_nodes: Dictionary = {}   # cell -> Sprite2D
var tree_nodes: Dictionary = {}      # cell -> [body, stump sprite]
var stump_cells: Dictionary = {}     # spot index -> cell
var _model: Forestry = null
var _rev := -1

func setup(main) -> void:
	m = main
	world = main.world
	sync()

func _process(_d: float) -> void:
	sync()

## Redraws after any model change (also after a load or a new game swapped the model) and places pine-forest stumps as chunks stream in.
func sync() -> void:
	var model: Forestry = GameState.forestry
	var changed := model != _model or model.rev != _rev
	if _place_stumps() or changed:
		if changed:
			_rebuild(model)
		world.sync_props(GameState.nodes)

func _rebuild(model: Forestry) -> void:
	_model = model
	_rev = model.rev
	for c in sapling_nodes:
		sapling_nodes[c].queue_free()
	sapling_nodes.clear()
	for c in model.saplings:
		var s := Sprite2D.new()
		s.texture = sapling_tex
		s.region_enabled = true
		var st := Forestry.stage(int(model.saplings[c].age), model.grow_days())
		s.region_rect = Rect2(st * 32, 40 if model.saplings[c].kind == "pine" else 0, 32, 40)
		s.offset = Vector2(0, -16)
		s.position = Vector2(c) * 32.0 + Vector2(16, 28)
		world.add_child(s)
		Outline.set_sway(s, 1.0, c.x * 0.7 + c.y * 0.3)
		sapling_nodes[c] = s
	for c in tree_nodes.keys():
		if not model.grown.has(c):
			for n in tree_nodes[c]:
				n.queue_free()
			tree_nodes.erase(c)
			world.props.erase(c)
			world.stumps.erase(c)
			world.planted.erase(c)
	model.register(GameState.nodes)
	for c in model.grown:
		if tree_nodes.has(c):
			continue
		var body := world.make_prop(World.PROP_TEX[model.grown[c]], c, Vector2(12, 8), Vector2(0, -44))
		world.register_prop(c, body, true)
		var stump := world.prop_stump(c, body)
		Outline.set_sway(body.get_child(0), 1.6, c.x * 0.7 + c.y * 0.3)
		tree_nodes[c] = [body, stump]
		world.planted[c] = true

## Each spot settles on the nearest free grass once its chunk is loaded. Returns true if any appeared.
func _place_stumps() -> bool:
	var spots: Array = GameState.forestry.data.get("stump_spots", [])
	var any := false
	for i in spots.size():
		var want := Vector2i(int(spots[i][0]), int(spots[i][1]))
		if stump_cells.has(i):
			var have: Vector2i = stump_cells[i]
			if not GameState.nodes.nodes.has(have):
				GameState.nodes.add("big_stump", have)   # a load/new game swapped the nodes
				any = true
			continue
		var ch := ChunkGrid.chunk_of_cell(want)
		if ch != WorldGen.HOME and not world.chunk_views.has(ch):
			continue
		for r in SPOT_SEARCH:
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var c := want + Vector2i(dx, dy)
					if not stump_cells.has(i) and ChunkGrid.chunk_of_cell(c) == ch and _free_ground(c):
						spawn_stump(c, i % 2)
						stump_cells[i] = c
						any = true
	return any

func spawn_stump(cell: Vector2i, variant: int) -> void:
	var body := world.make_prop("res://assets/sprites/big_stump.png", cell, Vector2(30, 14), Vector2(0, -11))
	var at := AtlasTexture.new()
	at.atlas = stump_tex
	at.region = Rect2(48 * variant, 0, 48, 32)
	(body.get_child(0) as Sprite2D).texture = at
	world.register_prop(cell, body, false)
	GameState.nodes.add("big_stump", cell)

## Dry grass with nothing the world itself put there (the same every session, so saved stumps stay put).
func _free_ground(c: Vector2i) -> bool:
	if not Forestry.can_plant(world.gen.tile_at(c.x, c.y), world.gen.sdf_at(c.x, c.y), world.props.has(c) or world.interactables.cells.has(c)):
		return false
	if CityModel.in_rect(c) or CircuitModel.in_rect(c) or VanceYard.in_rect(c) or HarbourModel.is_quay(c) or c in world.gen.dock:
		return false
	var ch := ChunkGrid.chunk_of_cell(c)
	var bushes: Array = world.gen.bushes if ch == WorldGen.HOME else (world.chunk_views[ch].gen.bushes if world.chunk_views.has(ch) else [])
	return not ((c - ChunkGrid.origin_cell(ch)) if ch != WorldGen.HOME else c) in bushes

func _can_plant_at(c: Vector2i) -> bool:
	var farm: FarmModel = GameState.farm
	if farm.soil.has(c) or farm.weeds.has(c) or farm.sprinklers.has(c) or farm.scarecrows.has(c):
		return false
	if GameState.nodes.nodes.has(c) or GameState.build.placed.has(c) or GameState.snares.snares.has(c):
		return false
	return _free_ground(c)

## Hotbar use on a cell. True when forestry dealt with the click.
func use(tool: String, cell: Vector2i) -> bool:
	var model: Forestry = GameState.forestry
	if model.saplings.has(cell):
		if tool == "hand" and int(model.saplings[cell].age) == 0:
			var seed_id := String(model.data["seeds"][model.saplings[cell].kind])
			model.saplings.erase(cell)
			model.rev += 1
			GameState.bag.add(seed_id, 1)
			m._say("Dug the seed back up")
		else:
			m._say("A sapling is growing here (%d days to go)" % model.days_left(cell))
		return true
	if model.kind_for_seed(tool) == "":
		return false
	var label := tool.replace("_", " ")
	if GameState.bag.count(tool) < 1:
		m._say("No %s - felled trees sometimes drop one" % label)
	elif _can_plant_at(cell) and model.plant(cell, tool):
		GameState.bag.remove(tool, 1)
		m._say("Planted the %s - a tree in %d days" % [label, model.grow_days()])
	else:
		m._say("Plant it on free grass, away from water")
	return true

## Seed and sap shaken loose when the tree on `cell` has just been felled.
func fell_drops(cell: Vector2i) -> Array:
	var n: Dictionary = GameState.nodes.nodes.get(cell, {})
	if String(n.get("kind", "")) != "tree" or int(n.get("stump_days", 0)) <= 0:
		return []
	var spr := world.prop_sprite(cell)
	var kind := "oak" if spr != null and spr.texture.resource_path.contains("oak") else "pine"
	return GameState.forestry.fell_drops(kind, randf(), randf())

func new_day() -> void:
	var here := TargetMath.cell_of(m.player.position)
	GameState.forestry.next_day(GameState.nodes, func(c: Vector2i) -> bool: return c == here or GameState.build.placed.has(c))
	sync()
