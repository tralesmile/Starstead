class_name HarbourProps
extends RefCounted
## Working-quay clutter on the Halden quay (sprites from dock_props.png, see tools/gen_dock.py).
## Pure layout: cells sit on the paved quay rect, off the road column and the pier approach, and off HarbourModel.props().
## frame: 1 crates, 2 rope, 5 net on stakes, 7 lobster pots, 8 gull on barrel, 9 bollard lamp.

const ITEMS := [
	{"frame": 7, "cell": Vector2i(213, 103)},
	{"frame": 8, "cell": Vector2i(217, 101)},
	{"frame": 1, "cell": Vector2i(219, 104)},
	{"frame": 2, "cell": Vector2i(221, 102)},
	{"frame": 9, "cell": Vector2i(229, 103)},
	{"frame": 7, "cell": Vector2i(234, 101)},
]

static func items() -> Array:
	return ITEMS

static func sprite(it: Dictionary, sheet: Texture2D) -> Sprite2D:
	var c: Vector2i = it["cell"]
	var s := Sprite2D.new()
	s.texture = sheet
	s.region_enabled = true
	s.region_rect = Rect2(32.0 * int(it["frame"]), 0, 32, 32)
	s.offset = Vector2(0, -14)
	s.position = Vector2(c.x * 32 + 16, c.y * 32 + 28)
	return s
