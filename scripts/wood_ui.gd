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

# --- Slot grids and window layouts (pure, so tests can check them against the 640x360 screen) ---

const SLOT_BG := Color(0.80, 0.65, 0.42)
const GOLD := Color(1.0, 0.78, 0.25)
const GRID_COLS := 10
const GRID_CELL := 28.0
const GRID_W := GRID_COLS * GRID_CELL - 2.0
const BAG_GRID := Vector2(181, 96)          # bag screen: slot 0
const CHEST_GRID := Vector2(181, 56)        # chest screen: chest slot 0
const CHEST_BAG_GRID := Vector2(181, 160)   # chest screen: bag slot 0 (room for 5 bag rows)
const BUS_ORIGIN := Vector2(150, 50)
const BUS_ROW := 30.0
const BUS_W := 340.0

static func grid_rows(slots: int) -> int:
	return ceili(float(slots) / GRID_COLS)

static func grid_slot_rect(origin: Vector2, i: int) -> Rect2:
	return Rect2(origin + Vector2((i % GRID_COLS) * GRID_CELL, (i / GRID_COLS) * GRID_CELL), Vector2(GRID_CELL - 2, GRID_CELL - 2))

static func bag_window(slots: int, perk_line: bool) -> Rect2:
	var bottom := BAG_GRID.y + grid_rows(slots) * GRID_CELL + (66.0 if perk_line else 53.0)
	var top := BAG_GRID.y - 34.0
	return Rect2(BAG_GRID.x - 11.0, top, GRID_W + 24.0, bottom - top)

static func chest_window(bag_slots: int) -> Rect2:
	var bottom := CHEST_BAG_GRID.y + grid_rows(bag_slots) * GRID_CELL + 32.0
	var top := CHEST_GRID.y - 42.0
	return Rect2(CHEST_GRID.x - 11.0, top, GRID_W + 24.0, bottom - top)

static func bus_window(count: int) -> Rect2:
	return Rect2(BUS_ORIGIN - Vector2(10, 34), Vector2(BUS_W + 20.0, 68.0 + count * BUS_ROW))

static func bus_row_rect(i: int) -> Rect2:
	return Rect2(BUS_ORIGIN + Vector2(0, i * BUS_ROW), Vector2(BUS_W, BUS_ROW - 3))

static func bus_row_at(p: Vector2, count: int) -> int:
	## Row under p, or -1. The small gap under a row still counts as that row.
	var d := p - BUS_ORIGIN
	if d.x < 0.0 or d.x >= BUS_W or d.y < 0.0:
		return -1
	var i := int(d.y / BUS_ROW)
	return i if i < count else -1

static func tooltip_rect(mouse: Vector2, text_w: float, screen: Vector2) -> Rect2:
	## Below-right of the mouse, pushed back so the tag (and its 2px frame) stays on screen.
	var size := Vector2(text_w + 10.0, 18.0)
	var at := mouse + Vector2(10, 12)
	return Rect2(at.clamp(Vector2(2, 2), (screen - size - Vector2(2, 2)).max(Vector2(2, 2))), size)

static func slot(c: CanvasItem, r: Rect2, hover: bool, picked: bool = false) -> void:
	c.draw_rect(r, SLOT_BG.lerp(GOLD, 0.8) if picked else (SLOT_BG.lightened(0.35) if hover else SLOT_BG))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(0.36, 0.21, 0.10, 0.5))
	c.draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color(0.36, 0.21, 0.10, 0.3))
	c.draw_rect(Rect2(Vector2(r.position.x, r.end.y - 1), Vector2(r.size.x, 1)), Color(1, 1, 0.9, 0.7))

static func slot_mark(c: CanvasItem, r: Rect2, hover: bool, picked: bool) -> void:
	## Outline drawn over a slot's contents: thick and dark when picked up, thin when hovered.
	if picked:
		c.draw_rect(r.grow(1), OUTLINE, false, 2.0)
	elif hover:
		c.draw_rect(r, WOOD_D, false, 1.0)

static func count_badge(c: CanvasItem, r: Rect2, n: int) -> void:
	## Stack size in the slot's bottom-right corner: ink with a cream halo so it reads over the icon.
	var at := Vector2(r.position.x, r.end.y - 2)
	c.draw_string_outline(ThemeDB.fallback_font, at, str(n), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 2, 10, 4, CREAM)
	text(c, at, str(n), 10, INK, r.size.x - 2, HORIZONTAL_ALIGNMENT_RIGHT)

static func plank_note(c: CanvasItem, r: Rect2, s: String) -> void:
	## Right-aligned text on a panel's title plank.
	text(c, r.position + Vector2(0, 15), s, 10, CREAM, r.size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)
