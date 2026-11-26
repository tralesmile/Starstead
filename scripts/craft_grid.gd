class_name CraftGrid
extends RefCounted
## Pure layout of the craft menu: two columns, filled across then down, so every recipe fits the 640x360 screen.

const COLS := 2
const CELL := Vector2(300.0, 31.0)
const GRID := Vector2(20, 62)

static func cell_rect(i: int) -> Rect2:
	return Rect2(GRID + Vector2(i % COLS * CELL.x, i / COLS * CELL.y), CELL - Vector2(4, 3))

static func index_at(p: Vector2, count: int) -> int:
	for i in count:
		if cell_rect(i).has_point(p):
			return i
	return -1

static func panel_rect(count: int) -> Rect2:
	var rows := (count + COLS - 1) / COLS
	return Rect2(GRID - Vector2(10, 30), Vector2(COLS * CELL.x + 16, 52.0 + rows * CELL.y))
