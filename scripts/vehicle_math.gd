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

static func step(vel: Vector2, heading: float, throttle: float, steer: float, handbrake: bool, delta: float) -> Dictionary:
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
	vs *= exp(-g * delta)
	# steering needs speed; reverses when rolling backwards; handbrake adds yaw
	var speed_factor := clampf(absf(vf) / 80.0, 0.0, 1.0)
	var yaw := steer * STEER_RATE * speed_factor * (1.0 if vf >= 0.0 else -1.0)
	if handbrake:
		yaw *= 1.5
	var h := wrapf(heading + yaw * delta, -PI, PI)
	return {"vel": f * vf + side * vs, "heading": h}

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
