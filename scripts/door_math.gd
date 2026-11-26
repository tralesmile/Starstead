class_name DoorMath
extends RefCounted
## Pure swing of a built door: opens as you come close, stays open while you are near, eases shut behind you.

const FRAMES := 5
const OPEN_AT := 40.0     # px from the doorway centre that starts it opening
const CLOSE_AT := 54.0    # wider than OPEN_AT so standing on the edge never flaps it
const OPEN_TIME := 0.16
const CLOSE_TIME := 0.34

## Whether the door wants to be open, given the distance and what it wanted last frame.
static func wants_open(dist: float, was: bool) -> bool:
	return dist < (CLOSE_AT if was else OPEN_AT)

## openness 0 (shut) .. 1 (wide open), moved toward the wish; it shuts slower than it opens.
static func step(openness: float, want: bool, delta: float) -> float:
	return move_toward(openness, 1.0 if want else 0.0, delta / (OPEN_TIME if want else CLOSE_TIME))

static func frame(openness: float) -> int:
	return clampi(int(round(clampf(openness, 0.0, 1.0) * (FRAMES - 1))), 0, FRAMES - 1)
