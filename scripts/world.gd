class_name World
extends Node2D
## Builds a TileMapLayer + collision from WorldGen; places trees and rocks as solid props.

var gen: WorldGen
var layer: TileMapLayer

func build(seed_value: int = 1) -> void:
	gen = WorldGen.new(seed_value)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_physics_layer()
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/atlas.png")
	src.texture_region_size = Vector2i(32, 32)
	for i in 11:
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)
	for i in [WorldGen.WATER_SHALLOW, WorldGen.WATER_DEEP]:
		var td := src.get_tile_data(Vector2i(i, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)]))
	layer = TileMapLayer.new()
	layer.tile_set = ts
	add_child(layer)
	for y in WorldGen.SIZE:
		for x in WorldGen.SIZE:
			layer.set_cell(Vector2i(x, y), 0, Vector2i(gen.tiles[y * WorldGen.SIZE + x], 0))
	for p in gen.trees:
		_prop("res://assets/sprites/tree.png", p, Vector2(12, 8), Vector2(0, -32))
	for p in gen.rocks:
		_prop("res://assets/sprites/rock.png", p, Vector2(24, 18), Vector2.ZERO)

func _prop(tex: String, cell: Vector2i, body: Vector2, off: Vector2) -> void:
	var b := StaticBody2D.new()
	b.position = Vector2(cell) * 32.0 + Vector2(16, 28)
	var s := Sprite2D.new()
	s.texture = load(tex)
	s.offset = off + Vector2(0, -16)
	b.add_child(s)
	var c := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = body
	c.shape = rs
	b.add_child(c)
	b.y_sort_enabled = true
	add_child(b)
