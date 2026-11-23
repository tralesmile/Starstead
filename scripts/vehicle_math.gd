class_name VehicleMath
extends RefCounted
## Pure top-down car physics: heading + velocity, lateral grip (drift), handbrake, drag. Units px, s.

const ENGINE := 260.0        # px/s^2 at full throttle
const BRAKE := 420.0
const DRAG := 0.6            # 1/s, rolling resistance
const MAX_SPEED := 300.0
const GRIP := 8.0            # 1/s: how fast sideways velocity is killed
const GRIP_HANDBRAKE := 1.2  # rear lets go: drift
const STEER_RATE := 2.6      # rad/s at full lock
const REVERSE_MAX := 90.0

static func forward(heading: float) -> Vector2:
	return Vector2.from_angle(heading)

static func slip(vel: Vector2, heading: float) -> float:
	## Sideways speed (px/s); > ~60 reads as a drift.
	return vel.dot(forward(heading).orthogonal())

static func step(vel: Vector2, heading: float, throttle: float, steer: float, handbrake: bool, delta: float, grip_mul: float = 1.0) -> Dictionary:
	## throttle in [-1,1] (negative = brake/reverse), steer in [-1,1]. Returns {vel, heading}.
	var f := forward(heading)
	var side := f.orthogonal()
	var vf := vel.dot(f)
	var vs := vel.dot(side)
	# engine / brake along the car's nose
	if throttle > 0.0:
		vf += ENGINE * throttle * delta
	elif throttle < 0.0:
		if vf > 1.0:
			vf = maxf(0.0, vf - BRAKE * -throttle * delta)
		else:
			vf = maxf(-REVERSE_MAX, vf + ENGINE * 0.5 * throttle * delta)
	vf *= maxf(0.0, 1.0 - DRAG * delta)
	vf = clampf(vf, -REVERSE_MAX, MAX_SPEED)
	if handbrake:
		vf = move_toward(vf, 0.0, BRAKE * 0.5 * delta)
	# lateral grip
	var g := GRIP_HANDBRAKE if handbrake else GRIP
	vs *= exp(-g * grip_mul * delta)
	# steering needs speed; reverses when rolling backwards; handbrake adds yaw
	var speed_factor := clampf(absf(vf) / 80.0, 0.0, 1.0)
	var yaw := steer * STEER_RATE * speed_factor * steer_scale(absf(vf)) * (1.0 if vf >= 0.0 else -1.0)
	if handbrake:
		yaw *= 1.5
	var h := wrapf(heading + yaw * delta, -PI, PI)
	return {"vel": f * vf + side * vs, "heading": h}

const STEER_LOSS := 0.4   # share of steering lost at top speed (high-speed understeer: nimble in town, stable on the straight)

static func steer_scale(speed: float) -> float:
	return 1.0 - STEER_LOSS * clampf(speed / MAX_SPEED, 0.0, 1.0)

const FUEL_MAX := 40.0
const FUEL_BURN := 0.35   # units/s at full throttle (idle burns a little)
const SKID_SLIP := 60.0

static func is_skidding(vel: Vector2, heading: float) -> bool:
	return absf(slip(vel, heading)) > SKID_SLIP and vel.length() > 50.0

static func fuel_after(fuel: float, throttle: float, delta: float) -> float:
	return maxf(0.0, fuel - (0.03 + FUEL_BURN * absf(throttle)) * delta)

static func throttle_with_fuel(throttle: float, fuel: float) -> float:
	## Empty tank: no engine power (braking still works).
	return throttle if (fuel > 0.0 or throttle < 0.0) else 0.0

static func wheel_points(pos: Vector2, heading: float) -> Array[Vector2]:
	## Rear wheel contact points for skid marks.
	var f := forward(heading)
	var s := f.orthogonal()
	var back := pos - f * 9.0
	return [back + s * 5.0, back - s * 5.0]

const HEALTH_MAX := 100.0
const REPAIR_WOOD_PER_25 := 2

static func crash_damage(impact_speed: float) -> float:
	## Bumps under 90 px/s are free; harder hits hurt, capped at 60.
	return clampf((impact_speed - 90.0) * 0.25, 0.0, 60.0)

static func crash_response(vel: Vector2, normal: Vector2, heading: float) -> Dictionary:
	## Wall hit: the part of the speed into the wall bounces back at 30%, the scrape along it keeps 80%,
	## and the nose is shoved away from the wall (spin in radians, at most 0.5). Replaces the flat "vel *= 0.4".
	var n := normal.normalized()
	var into := maxf(0.0, -vel.dot(n))
	var along := vel - n * vel.dot(n)
	var out := along * 0.8 + n * maxf(vel.dot(n), into * 0.3)   # already moving away: keep that part
	var spin := clampf(forward(heading).cross(n) * into / 260.0, -0.5, 0.5)
	return {"vel": out, "spin": spin}

static func crash_dust(vel: Vector2, normal: Vector2) -> int:
	## Dust/debris bits thrown by a wall hit: none for a graze (into-wall speed < 40 px/s), up to 14 for a full-speed smash.
	var into := maxf(0.0, -vel.dot(normal.normalized()))
	if into < 40.0:
		return 0
	return clampi(int(into / 25.0), 2, 14)

static func speed_cap(health: float) -> float:
	## Battered cars top out lower (never below 45%).
	return MAX_SPEED * lerpf(0.45, 1.0, clampf(health / HEALTH_MAX, 0.0, 1.0))

static func repair_cost(health: float) -> int:
	## Wood needed to restore full health (2 per started 25 hp).
	return int(ceil((HEALTH_MAX - health) / 25.0)) * REPAIR_WOOD_PER_25

const SIDEWALK_CAP := 0.5

static func surface_cap(on_road: bool, sdf: float, rain: float = 0.0, sidewalk: bool = false) -> float:
	## Top-speed factor by ground: roads full, paved sidewalk 0.5 (kerb bumps, pedestrians), grass 0.82 (0.7 in the rain), the wet bank 0.55.
	if sdf < 0.9:
		return 0.55
	if sidewalk:
		return SIDEWALK_CAP
	if on_road:
		return 1.0 - 0.1 * clampf(rain, 0.0, 1.0)
	return 0.82 - 0.12 * clampf(rain, 0.0, 1.0)

static func surface_grip(tile: int, sdf: float, rain: float = 0.0) -> float:
	## Tyre grip by ground: dry asphalt best (1.2), packed paths/sidewalk 0.95, grass loose (0.7), wet bank 0.5.
	## Rain takes up to 35% off asphalt (puddled, slick) and 15% off everything else.
	var r := clampf(rain, 0.0, 1.0)
	if sdf < 0.9:
		return 0.5
	if tile == WorldGen.ASPHALT:
		return 1.2 * (1.0 - 0.35 * r)
	if WorldGen.is_road(tile):
		return 0.95 * (1.0 - 0.15 * r)
	return 0.7 * (1.0 - 0.15 * r)

static func kerb_bump(speed: float, cap_before: float, cap_after: float) -> Dictionary:
	## Driving off the street onto a sidewalk/quay (the surface cap drops to the sidewalk cap) at speed:
	## the car loses up to 25% speed and the camera jolts. Slow rolls (< 60 px/s) cross the kerb quietly.
	if cap_before <= SIDEWALK_CAP + 0.01 or cap_after > SIDEWALK_CAP + 0.01 or speed < 60.0:
		return {"factor": 1.0, "shake": 0.0}
	var t := clampf((speed - 60.0) / 200.0, 0.0, 1.0)
	return {"factor": 1.0 - 0.25 * t, "shake": 0.5 + 1.5 * t}

static func rumble(speed: float, on_kerb: bool) -> Dictionary:
	## Red/white circuit kerbs: a rattling camera jolt and 8% less grip, stronger when fast. Slow rolls feel nothing.
	if not on_kerb or speed < 80.0:
		return {"grip": 1.0, "shake": 0.0}
	var t := clampf((speed - 80.0) / 160.0, 0.0, 1.0)
	return {"grip": 1.0 - 0.08 * t, "shake": 0.3 + 0.9 * t}

static func slipstream(pos: Vector2, heading: float, other: Vector2, other_heading: float) -> float:
	## Drafting: within 140px directly behind another car heading the same way gives up to +8% top speed (1.0 .. 1.08).
	var to := other - pos
	var d := to.length()
	if d < 1.0 or d > 140.0:
		return 1.0
	var ahead := forward(heading).dot(to / d)
	var same := forward(heading).dot(forward(other_heading))
	if ahead < 0.9 or same < 0.8:
		return 1.0
	return 1.0 + 0.08 * (1.0 - d / 140.0)

static func skid_alpha(tile: int, sdf: float, rain: float = 0.0) -> float:
	## Tyre marks show best on dry asphalt, fainter on packed paths, barely on grass; rain washes them out.
	if sdf < 0.9:
		return 0.0
	var base := 0.9 if tile == WorldGen.ASPHALT else (0.6 if WorldGen.is_road(tile) else 0.3)
	return base * (1.0 - 0.4 * clampf(rain, 0.0, 1.0))

static func light_levels(night: float, braking: bool, reversing: bool = false) -> Dictionary:
	## Car lamps: headlights follow the night (0..1); tail lights glow dim at night and flare when braking (also by day).
	var head := clampf(night, 0.0, 1.0)
	var tail := 0.45 * head
	if braking:
		tail = maxf(tail, 0.95)
	return {"head": head, "tail": tail, "reverse": 0.7 if reversing else 0.0}

static func skid_life(on_circuit: bool, rain: float) -> float:
	## Seconds a tyre mark stays: rubber builds up on the circuit (40 s), rain washes it faster, elsewhere 6 s.
	return (40.0 if on_circuit else 6.0) * (1.0 - 0.5 * clampf(rain, 0.0, 1.0))

static func is_braking(throttle: float, forward_speed: float, handbrake: bool) -> bool:
	return handbrake or (throttle < 0.0 and forward_speed > 1.0)

static func smoke_style(slip_amount: float, tile: int, sdf: float, rain: float = 0.0) -> Dictionary:
	## Drift smoke by ground: white tyre smoke on asphalt, tan dust on packed paths, olive grass dust off-road,
	## thin spray in the wet. Puffs scale with how hard the tail is out (6..22).
	var hard := clampf((absf(slip_amount) - SKID_SLIP) / 120.0, 0.0, 1.0)
	var col := Color(0.88, 0.88, 0.9)
	var a := 0.55
	if sdf < 0.9:
		col = Color(0.7, 0.85, 0.9)   # splash on the wet bank
		a = 0.4
	elif tile == WorldGen.ASPHALT:
		pass
	elif WorldGen.is_road(tile):
		col = Color(0.82, 0.68, 0.46)
		a = 0.5
	else:
		col = Color(0.58, 0.62, 0.35)
		a = 0.45
	a *= 1.0 - 0.45 * clampf(rain, 0.0, 1.0)
	return {"amount": int(round(lerpf(6.0, 22.0, hard))), "color": Color(col.r, col.g, col.b, a), "size": lerpf(1.5, 3.4, hard)}
