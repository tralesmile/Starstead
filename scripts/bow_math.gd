class_name BowMath
extends RefCounted
## Pure bow physics (owner 2026-11-18 hunting): hold to draw, release to loose. The arrow flies flat in top-down space,
## loses speed to drag, is carried sideways by the day's storm wind (PlayerMath.wind_angle) and drops when it has
## flown its range or slowed to a stall. A longer draw is faster, farther and hits harder.

const DRAW_TIME := 0.9        # seconds to a full draw
const MIN_DRAW := 0.25        # release below this fraction just relaxes the string (no arrow spent)
const SPEED_MIN := 220.0      # px/s
const SPEED_MAX := 430.0
const RANGE_MIN := 96.0       # px (3 tiles)
const RANGE_MAX := 288.0      # px (9 tiles)
const DMG_MIN := 5.0
const DMG_MAX := 18.0
const DRAG := 0.55            # fraction of speed lost per second (exponential)
const WIND_ACCEL := 110.0     # px/s^2 sideways push in a full storm
const BREEZE := 0.12          # a dry day still has a light breeze (fraction of the storm push)
const STALL_SPEED := 90.0
const HIT_RADIUS := 11.0
const COOLDOWN := 0.35
const PERFECT_WINDOW := 0.28  # s after reaching full draw: release now for a perfect shot
const PERFECT_DMG := 1.35
const PERFECT_SPEED := 1.08
const PERFECT_WIND := 0.35    # a perfect arrow flies true: only this share of the wind push
const TIRE_AFTER := 2.4       # s held before the bow arm starts to shake
const TIRE_FULL := 4.4
const SWAY_MAX := 0.09        # radians either side

static func draw_power(held: float) -> float:
	return clampf(held / DRAW_TIME, 0.0, 1.0)

static func can_loose(power: float) -> bool:
	return power >= MIN_DRAW

static func _t(power: float) -> float:
	return clampf((power - MIN_DRAW) / (1.0 - MIN_DRAW), 0.0, 1.0)

static func speed(power: float) -> float:
	return lerpf(SPEED_MIN, SPEED_MAX, _t(power))

static func reach(power: float) -> float:
	return lerpf(RANGE_MIN, RANGE_MAX, _t(power))

static func damage(power: float) -> float:
	return lerpf(DMG_MIN, DMG_MAX, _t(power))

static func is_perfect(held: float) -> bool:
	return held >= DRAW_TIME and held <= DRAW_TIME + PERFECT_WINDOW

static func sway(held: float) -> float:
	## Aim error (radians) from holding a full draw too long; zero while fresh.
	var amp := SWAY_MAX * clampf((held - TIRE_AFTER) / (TIRE_FULL - TIRE_AFTER), 0.0, 1.0)
	return amp * sin(held * 11.0)

static func perfect(a: Dictionary) -> Dictionary:
	## The perfect-release bonus applied to a launched arrow.
	var out := a.duplicate()
	out["vel"] = (a["vel"] as Vector2) * PERFECT_SPEED
	out["dmg"] = float(a["dmg"]) * PERFECT_DMG
	out["perfect"] = true
	return out

static func wind_share(a: Dictionary) -> float:
	return PERFECT_WIND if bool(a.get("perfect", false)) else 1.0

static func wind_accel(rain: float, angle: float) -> Vector2:
	var storm := clampf((rain - 0.6) / 0.4, 0.0, 1.0)
	return Vector2.from_angle(angle) * WIND_ACCEL * maxf(BREEZE, storm)

static func launch(origin: Vector2, dir: Vector2, power: float) -> Dictionary:
	var d := dir.normalized() if dir.length() > 0.001 else Vector2.DOWN
	return {"pos": origin, "vel": d * speed(power), "flown": 0.0, "reach": reach(power), "dmg": damage(power), "done": false}

static func step(a: Dictionary, wind: Vector2, dt: float) -> Dictionary:
	## One physics step; returns the new arrow state (the input is not changed).
	var out := a.duplicate()
	var vel: Vector2 = a["vel"]
	vel = vel * pow(1.0 - DRAG, dt) + wind * wind_share(a) * dt
	var move := vel * dt
	var left := float(a["reach"]) - float(a["flown"])
	if move.length() >= left:
		move = move.limit_length(left)
		out["done"] = true
	out["pos"] = (a["pos"] as Vector2) + move
	out["flown"] = float(a["flown"]) + move.length()
	out["vel"] = vel
	if vel.length() < STALL_SPEED:
		out["done"] = true
	return out

static func hits(from: Vector2, to: Vector2, target: Vector2, radius: float = HIT_RADIUS) -> bool:
	## Swept test: did the arrow's path this step pass within `radius` of the target? (no tunnelling at low frame rates)
	return Geometry2D.get_closest_point_to_segment(target, from, to).distance_to(target) <= radius

static func lift(a: Dictionary) -> float:
	## Drawn height above the ground shadow: level for most of the flight, dropping over the last third.
	var f := clampf(float(a["flown"]) / maxf(1.0, float(a["reach"])), 0.0, 1.0)
	return 12.0 * (1.0 if f < 0.66 else maxf(0.0, 1.0 - (f - 0.66) / 0.34))

static func recoverable(hit_animal: bool, roll: float) -> bool:
	## Arrows that stick in the ground can usually be picked up again; arrows in game break more often.
	return roll < (0.4 if hit_animal else 0.75)
