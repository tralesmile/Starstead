class_name CraftGrid
extends RefCounted
## Pure layout of the craft menu: two columns, filled across then down, so every recipe fits the 640x360 screen.

const COLS := 2
const CELL := Vector2(300.0, 31.0)
const GRID := Vector2(20, 62)

static func cell_rect(i: int) -> Rect2:
	return Rect2(GRID + Vector2(i % COLS * CELL.x, i / COLS * CELL.y), CELL - Vector2(4, 3))

const LIST_ORIGIN := Vector2(150, 60)
const LIST_ROW := 34.0
const LIST_MAX := 8   # more rows than this would leave the 360px screen: switch to the two-column grid

static func list_rect(i: int, count: int) -> Rect2:
	## Row i of a stove/anvil style menu: a single column, or the craft grid when the list is long.
	if count > LIST_MAX:
		return cell_rect(i)
	return Rect2(LIST_ORIGIN + Vector2(0, i * LIST_ROW), Vector2(340, LIST_ROW - 3))

static func list_panel(count: int) -> Rect2:
	if count > LIST_MAX:
		return panel_rect(count)
	return Rect2(LIST_ORIGIN - Vector2(10, 34), Vector2(360, 60.0 + count * LIST_ROW))

static func list_index_at(p: Vector2, count: int) -> int:
	for i in count:
		if list_rect(i, count).has_point(p):
			return i
	return -1

static func index_at(p: Vector2, count: int) -> int:
	for i in count:
		if cell_rect(i).has_point(p):
			return i
	return -1

static func panel_rect(count: int) -> Rect2:
	var rows := (count + COLS - 1) / COLS
	return Rect2(GRID - Vector2(10, 30), Vector2(COLS * CELL.x + 16, 52.0 + rows * CELL.y))
