class_name BuildingShadow
extends Node2D
## A building's ground shadow, in the building's own space (origin = bottom centre of the walls):
## a contact strip that seats it on the ground and a sun-cast wedge on the side away from the sun.
## The outlines are pure static functions; apply_sun (World) moves them with the clock.

const NOON_REACH := 7.0    # the sun is never straight overhead: a thin strip stays on the east side at noon
const REACH_PER_PX := 0.16 # shadow length per pixel of building height, per unit of ShadowMath.length_factor
const MAX_REACH := 56.0
const ALPHA := 0.40

var left := -48.0
var right := 48.0
var height := 90.0
var minutes := 360.0

## How far the cast shadow reaches sideways, whole pixels. Negative = west (morning), positive = east.
static func reach(mins: float, h: float) -> float:
	var side := -cos(ShadowMath.sun_angle(mins))
	var len_px := minf(h * REACH_PER_PX * ShadowMath.length_factor(mins) * absf(side) * 1.4, MAX_REACH)
	if len_px < NOON_REACH:
		return NOON_REACH if side > -0.1 else -NOON_REACH
	return roundf(len_px * signf(side))

## The wedge beside the wall: it starts under the eaves, runs out to the sun's reach and meets the ground just
## below the base line, so the corner never floats. `grow` widens it for the soft outer layer.
static func cast_points(mins: float, l: float, r: float, h: float, grow: float = 0.0) -> PackedVector2Array:
	var d := reach(mins, h)
	var s := signf(d)
	var edge := r if s > 0.0 else l
	var tip := edge + d + s * grow
	var inner := edge - s * 6.0   # tucked behind the sprite so no gap shows beside the wall
	var top := -roundf(h * 0.42) - grow
	return PackedVector2Array([Vector2(inner, top), Vector2(edge + roundf(d * 0.45), top + 4.0),
		Vector2(tip, -roundf(h * 0.2)), Vector2(tip, 1.0 + grow), Vector2(tip - s * 8.0, 5.0 + grow), Vector2(inner, 5.0 + grow)])

## The strip along the foot of the front wall, with clipped corners.
static func contact_points(l: float, r: float, grow: float = 0.0) -> PackedVector2Array:
	return PackedVector2Array([Vector2(l - grow, -4.0), Vector2(r + grow, -4.0), Vector2(r + grow, 2.0 + grow),
		Vector2(r - 5.0 + grow, 5.0 + grow), Vector2(l + 5.0 - grow, 5.0 + grow), Vector2(l - grow, 2.0 + grow)])

static func make(l: float, r: float, h: float) -> BuildingShadow:
	var n := BuildingShadow.new()
	n.left = l
	n.right = r
	n.height = h
	n.z_index = -3
	n.add_to_group("building_shadows")
	return n

func set_sun(mins: float) -> void:
	minutes = mins
	queue_redraw()

func _draw() -> void:
	var a := ALPHA * ShadowMath.strength(minutes)
	var ink := Color(0.04, 0.07, 0.14)
	for grow in [3.0, 0.0]:   # a faint wide layer under a darker core = soft edge in two pixel steps
		ink.a = a * (0.4 if grow > 0.0 else 0.8)
		draw_colored_polygon(cast_points(minutes, left, right, height, grow), ink)
		draw_colored_polygon(contact_points(left, right, grow), ink)
