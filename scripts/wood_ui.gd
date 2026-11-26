class_name WoodUI
extends RefCounted
## One wooden look for menus (the market stall's): plank frame with nails, parchment paper, a title plank,
## a coloured trim that tells menus apart, and inset rows with a gold highlight.

const OUTLINE := Color(0.13, 0.08, 0.04)
const WOOD_D := Color(0.36, 0.21, 0.10)
const WOOD := Color(0.55, 0.34, 0.17)
const WOOD_L := Color(0.73, 0.49, 0.26)
const INK := Color(0.24, 0.15, 0.08)
const INK_SOFT := Color(0.42, 0.3, 0.18)
const PAPER := Color(0.94, 0.87, 0.68)
const CREAM := Color(1.0, 0.94, 0.72)
const GOOD := Color(0.14, 0.42, 0.10)
const BAD := Color(0.68, 0.18, 0.12)
const PRICE := Color(0.45, 0.29, 0.02)
const TITLE_H := 20.0

enum Trim { SAWDUST, GINGHAM, HAZARD, IRON, EMBER }

static func panel(c: CanvasItem, r: Rect2, title: String, trim: int = Trim.SAWDUST) -> void:
	c.draw_rect(r.grow(6), OUTLINE)
	c.draw_rect(r.grow(5), WOOD)
	c.draw_rect(Rect2(r.position - Vector2(5, 5), Vector2(r.size.x + 10, 2)), WOOD_L)
	c.draw_rect(Rect2(Vector2(r.position.x - 5, r.end.y + 3), Vector2(r.size.x + 10, 2)), WOOD_D)
	for corner in [r.position + Vector2(-2.5, -1), Vector2(r.end.x + 2.5, r.position.y - 1), Vector2(r.position.x - 2.5, r.end.y + 1), r.end + Vector2(2.5, 1)]:
		c.draw_circle(corner, 1.8, OUTLINE)
		c.draw_circle(corner + Vector2(-0.5, -0.5), 0.8, PAPER)
	c.draw_rect(r, PAPER)
	var plank := Rect2(r.position, Vector2(r.size.x, TITLE_H))
	c.draw_rect(plank, WOOD_D)
	c.draw_rect(Rect2(plank.position, Vector2(plank.size.x, 2)), WOOD)
	for i in int(plank.size.x / 46.0):   # grain
		c.draw_line(plank.position + Vector2(14 + i * 46, 6 + (i * 5) % 9), plank.position + Vector2(32 + i * 46, 6 + (i * 5) % 9), Color(0.26, 0.14, 0.06, 0.8), 1.0)
	_trim(c, Rect2(r.position + Vector2(0, TITLE_H), Vector2(r.size.x, 4)), trim)
	c.draw_string(ThemeDB.fallback_font, r.position + Vector2(10, 15), title, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, 12, CREAM)

static func _trim(c: CanvasItem, r: Rect2, kind: int) -> void:
	var pair: Array = [Color(0.86, 0.66, 0.36), Color(0.74, 0.52, 0.26)]
	match kind:
		Trim.GINGHAM:
			pair = [Color(0.76, 0.24, 0.18), Color(0.96, 0.92, 0.8)]
		Trim.HAZARD:
			pair = [Color(0.95, 0.74, 0.12), Color(0.16, 0.14, 0.12)]
		Trim.IRON:
			pair = [Color(0.46, 0.50, 0.56), Color(0.62, 0.67, 0.72)]
		Trim.EMBER:
			pair = [Color(0.90, 0.42, 0.12), Color(0.98, 0.68, 0.22)]
	var x := r.position.x
	var i := 0
	while x < r.end.x:
		c.draw_rect(Rect2(x, r.position.y, minf(8.0, r.end.x - x), r.size.y), pair[i % 2])
		x += 8.0
		i += 1

static func row(c: CanvasItem, r: Rect2, hover: bool, enabled: bool) -> void:
	c.draw_rect(r, PAPER.darkened(0.08) if enabled else PAPER.darkened(0.17))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(0.36, 0.21, 0.10, 0.45))
	c.draw_rect(Rect2(Vector2(r.position.x, r.end.y - 1), Vector2(r.size.x, 1)), Color(1, 1, 0.9, 0.7))
	if hover:
		c.draw_rect(r, Color(1.0, 0.78, 0.25, 0.5))
		c.draw_rect(r, WOOD_D, false, 1.0)

static func icon_well(c: CanvasItem, r: Rect2) -> void:
	c.draw_rect(r, WOOD_L)
	c.draw_rect(r.grow(-1), Color(0.99, 0.95, 0.80))

static func text(c: CanvasItem, at: Vector2, s: String, size: int, col: Color = INK, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	c.draw_string(ThemeDB.fallback_font, at, s, align, width, size, col)
