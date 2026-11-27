class_name PoseMath
extends RefCounted
## Pure per-tool body poses: which player_hd.png column a tool swing shows, where the fists are in that
## frame and the angle of the held tool. Frame art: tools/gen_player_hd.py (TOOL_FRONT / TOOL_BACK / TOOL_SIDE).

const HEAVY_WIND := 12
const HEAVY_STRIKE := 13
const HEAVY_RECOVER := 14
const HOE_REACH := 15
const HOE_CHOP := 16
const HOE_DRAG := 17
const CAN_HOLD := 18
const CAN_POUR := 19
const BOW_DRAWN := 20

const SWING_TIME := 0.18   # tools without their own pose (scythe, hand, rod, seeds)

## Fist position per column as pixels from the player's feet, [down, up, right]; left mirrors right.
## Two-handed grips sit between the fists, the can hangs from the right (screen) fist.
const GRIPS := {
	HEAVY_WIND: [Vector2(0, -38), Vector2(0, -37), Vector2(-2, -37)],
	HEAVY_STRIKE: [Vector2(0, -7), Vector2(10, -24), Vector2(11, -9)],
	HEAVY_RECOVER: [Vector2(0, -12), Vector2(10, -18), Vector2(9, -13)],
	HOE_REACH: [Vector2(0, -15), Vector2(10, -26), Vector2(11, -20)],
	HOE_CHOP: [Vector2(0, -8), Vector2(10, -22), Vector2(10, -11)],
	HOE_DRAG: [Vector2(0, -11), Vector2(10, -17), Vector2(5, -12)],
	CAN_HOLD: [Vector2(6, -13), Vector2(11, -19), Vector2(10, -15)],
	CAN_POUR: [Vector2(5, -11), Vector2(11, -22), Vector2(11, -14)],
}

static func kind(tool: String) -> String:
	match tool:
		"axe", "pickaxe", "club":
			return "heavy"
		"hoe":
			return "hoe"
		"watering_can":
			return "can"
	return ""

## Seconds the pose of a tool plays: long enough to read each phase.
static func swing_time(tool: String) -> float:
	return {"heavy": 0.28, "hoe": 0.32, "can": 0.4}.get(kind(tool), SWING_TIME)

## 0 at the start of a swing, 1 at its end.
static func progress(t_left: float, total: float) -> float:
	if total <= 0.0:
		return 1.0
	return clampf(1.0 - t_left / total, 0.0, 1.0)

## Body column while a tool is in use; tools without their own pose keep the generic swing frame.
static func frame(tool: String, k: float) -> int:
	match kind(tool):
		"heavy":
			return HEAVY_WIND if k < 0.3 else (HEAVY_STRIKE if k < 0.72 else HEAVY_RECOVER)
		"hoe":   # the cuts follow HitMath.hoe_angle: lifted, driven into the soil, dragged back
			return HOE_REACH if k < 0.47 else (HOE_CHOP if k < 0.72 else HOE_DRAG)
		"can":
			return CAN_HOLD if k < 0.22 or k >= 0.88 else CAN_POUR
	return PlayerMath.TOOL_FRAME

static func has_grip(col: int) -> bool:
	return GRIPS.has(col)

static func grip(col: int, facing: int) -> Vector2:
	var g: Array = GRIPS[col]
	match facing:
		PlayerMath.Facing.DOWN:
			return g[0]
		PlayerMath.Facing.UP:
			return g[1]
		PlayerMath.Facing.LEFT:
			return Vector2(-(g[2] as Vector2).x, (g[2] as Vector2).y)
	return g[2]

## Direction of the tool in degrees above the horizontal, toward the facing side (90 = straight up, -90 = down).
static func tool_deg(tool: String, k: float, facing: int) -> float:
	var col := frame(tool, k)
	var view := 0 if facing == PlayerMath.Facing.DOWN else (1 if facing == PlayerMath.Facing.UP else 2)
	match kind(tool):
		"heavy":
			if col == HEAVY_WIND:   # cocked further back as the wind-up builds
				var u := k / 0.3
				return [lerpf(60.0, 48.0, u), lerpf(105.0, 125.0, u), lerpf(115.0, 160.0, u)][view]
			if col == HEAVY_STRIKE:  # whips through fast, then bites
				var u := clampf((k - 0.3) / 0.15, 0.0, 1.0)
				return [lerpf(-60.0, -90.0, u), lerpf(75.0, 45.0, u), lerpf(10.0, -35.0, u)][view]
			var r := (k - 0.72) / 0.28
			return [lerpf(-65.0, -30.0, r), lerpf(25.0, 50.0, r), lerpf(-20.0, 25.0, r)][view]
		"hoe":
			var a := rad_to_deg(HitMath.hoe_angle(1.0 - k, 1.0)) if k > 0.0 else rad_to_deg(-1.0)
			if col == HOE_REACH:
				var up := clampf(25.0 - a, 35.0, 115.0)
				return [minf(up - 45.0, 35.0), up, 35.0 + (up - 35.0) * 0.5][view]   # side: held out ahead, clear of the face
			var down := 25.0 - a   # +25 while level, about -38 at the bottom of the chop
			if col == HOE_CHOP and k >= 0.55:
				down = -38.0   # the blade is in the soil
			elif col == HOE_DRAG:
				down = lerpf(-38.0, -28.0, clampf((k - 0.72) / 0.28, 0.0, 1.0))
			return [-90.0 + (down + 38.0) * 0.3, 55.0 + down * 0.4, down][view]
		"can":   # the icon rests at 45; pouring tips the spout down
			var tip := clampf((k - 0.22) / 0.18, 0.0, 1.0) if k < 0.88 else clampf((1.0 - k) / 0.12, 0.0, 1.0)
			return 45.0 - 40.0 * tip
	return 45.0

## True when the tool is hidden behind the body (facing away, except raised overhead toward the camera).
static func behind(col: int, facing: int) -> bool:
	return facing == PlayerMath.Facing.UP and col != HEAVY_WIND

## Rotation for the held sprite: the icons point 45 degrees up toward the side they face (side -1 = flipped).
static func rotation_for(deg: float, side: float) -> float:
	return deg_to_rad(45.0 - deg) * side

## Sprite2D offset that puts the icon's grip pixel on the node position (the can is held by its back handle).
static func grip_offset(tool: String, flipped: bool) -> Vector2:
	var o := Vector2(6, 1) if tool == "watering_can" else Vector2(4, -4)
	return Vector2(-o.x, o.y) if flipped else o
