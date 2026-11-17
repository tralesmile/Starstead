class_name Autotile
extends RefCounted
## Pure wall autotiling helper (no nodes, no autoloads).
## Bitmask: N=1, E=2, S=4, W=8; a bit is set when that neighbour's piece is in `joins`.
## Naming: end_x = single neighbour on side x (the wall runs toward x);
## t_x = three neighbours, the MISSING side is x (t_n: E+S+W, stem points S);
## corner_ab = neighbours on the two sides a and b.

const N := 1
const E := 2
const S := 4
const W := 8

const SHAPES := [
	"isolated", "end_n", "end_e", "corner_ne",
	"end_s", "straight_ns", "corner_se", "t_w",
	"end_w", "corner_nw", "straight_ew", "t_s",
	"corner_sw", "t_e", "t_n", "cross",
]

static func mask(cells: Dictionary, cell: Vector2i, joins: Array) -> int:
	var m := 0
	if cells.get(cell + Vector2i(0, -1)) in joins: m |= N
	if cells.get(cell + Vector2i(1, 0)) in joins: m |= E
	if cells.get(cell + Vector2i(0, 1)) in joins: m |= S
	if cells.get(cell + Vector2i(-1, 0)) in joins: m |= W
	return m

static func shape_name(m: int) -> String:
	return SHAPES[m & 15]

static func atlas_index(m: int) -> int:
	return m & 15
