class_name ShoreMath
extends RefCounted
## Shoreline collision that follows the painted shore: bilinear sdf (same sampling as the ground
## shader's linear data texture, texel centres at tile centres), 8px sub-cells, merged into row runs.

const SUB := 4  # sub-cells per tile side (8px)

## sdf at a continuous point in tile units; get(Vector2i)->float is the per-tile sdf.
static func sdf_bilinear(get: Callable, p: Vector2) -> float:
	var u := p - Vector2(0.5, 0.5)
	var i := Vector2i(floori(u.x), floori(u.y))
	var f := u - Vector2(i)
	var a: float = get.call(i)
	var b: float = get.call(i + Vector2i(1, 0))
	var c: float = get.call(i + Vector2i(0, 1))
	var d: float = get.call(i + Vector2i(1, 1))
	return lerpf(lerpf(a, b, f.x), lerpf(c, d, f.x), f.y)

## Blocked rectangles (pixels) for sub-cells whose sdf < 0 inside the shore band.
## band: tiles with |sdf| below this are subdivided; free(Vector2i)->bool marks tiles never blocked (docks).
static func blocked_rects(get: Callable, size: int, free: Callable, band: float = 2.5) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var step := 32.0 / float(SUB)
	# row-run merge per sub-row
	for sy in size * SUB:
		var ty := sy / SUB
		var run := -1
		for sx in size * SUB + 1:
			var b := false
			if sx < size * SUB:
				var tx := sx / SUB
				var t := Vector2i(tx, ty)
				var s: float = get.call(t)
				if absf(s) < band and not free.call(t):
					var p := (Vector2(sx, sy) + Vector2(0.5, 0.5)) / float(SUB)
					b = sdf_bilinear(get, p) < 0.0
			if b and run < 0:
				run = sx
			elif not b and run >= 0:
				out.append(Rect2(Vector2(run, sy) * step, Vector2(sx - run, 1) * step))
				run = -1
	return out
