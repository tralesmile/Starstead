class_name HoopBall
extends RefCounted
## Pure streetball physics: a ball with height (z), gravity, floor bounce, a round steel rim, a backboard and the
## chain fence round the half court. Ground plane is x/y in pixels (y down, the hoop is at the top), no autoload use.

const COURT := Vector2(440.0, 236.0)
const RIM := Vector2(220.0, 30.0)      # ground point under the middle of the rim
const RIM_Z := 56.0
const RIM_R := 10.0
const TUBE := 1.0
const RADIUS := 5.0
const BOARD_Y := 19.0                  # backboard face
const BOARD_HALF := 24.0
const BOARD_Z0 := 50.0
const BOARD_Z1 := 82.0
const ARC := 150.0                     # three point line, measured from RIM
const GRAVITY := 420.0
const AIR_DRAG := 0.0                  # shots must fly the arc they were aimed on
const BOUNCE := 0.66
const FLOOR_KEEP := 0.86               # ground speed kept per bounce
const ROLL_DRAG := 1.6
const RIM_KEEP := 0.55
const BOARD_KEEP := 0.6
const FENCE_KEEP := 0.5

var pos := COURT * 0.5
var vel := Vector2.ZERO
var z := RADIUS
var vz := 0.0
var spin := 0.0          # distance travelled, drives the sprite frame
var shot := false        # a live shot that has not yet touched anything: passes the iron on the way up, no catching
var touched_iron := false

static func is_three(from: Vector2) -> bool:
	return from.distance_to(RIM) > ARC

static func flight_time(dist: float) -> float:
	## High arcs, so the ball drops into the ring instead of clipping its front.
	return 0.72 + clampf(dist, 0.0, 300.0) / 430.0

static func launch_velocity(from: Vector2, from_z: float, target: Vector2, target_z: float, secs: float) -> Vector3:
	## Velocity (vx, vy, vz) that carries a ball from `from` to `target` in `secs` under gravity.
	var v := (target - from) / secs
	return Vector3(v.x, v.y, (target_z - from_z + 0.5 * GRAVITY * secs * secs) / secs)

func reset(at: Vector2) -> void:
	pos = at
	vel = Vector2.ZERO
	z = RADIUS
	vz = 0.0
	shot = false
	touched_iron = false

func launch(v: Vector3, is_shot: bool = false) -> void:
	vel = Vector2(v.x, v.y)
	vz = v.z
	shot = is_shot
	touched_iron = false

## Advances the ball. Returns what happened: "score", "rim", "board", "floor", "fence" or "".
func step(dt: float) -> String:
	var ev := ""
	var old_z := z
	var old_pos := pos
	var g := GRAVITY
	pos += vel * dt
	z += vz * dt - 0.5 * g * dt * dt
	vz -= g * dt
	spin += vel.length() * dt
	if old_z >= RIM_Z and z < RIM_Z:
		var k := (old_z - RIM_Z) / maxf(0.0001, old_z - z)
		if old_pos.lerp(pos, k).distance_to(RIM) < RIM_R - 2.0:
			shot = false
			vel *= 0.25          # the net takes the pace off
			vz *= 0.5
			pos = RIM + (pos - RIM).limit_length(3.0)
			return "score"
	if not (shot and vz > 0.0):
		ev = _iron()
	if z < RADIUS:
		z = RADIUS
		shot = false
		if vz < -40.0:
			vz = -vz * BOUNCE
			vel *= FLOOR_KEEP
			ev = "floor"
		else:
			vz = 0.0
	if z <= RADIUS + 0.01 and vz == 0.0:
		vel *= exp(-ROLL_DRAG * dt)
	if pos.x < RADIUS or pos.x > COURT.x - RADIUS:
		pos.x = clampf(pos.x, RADIUS, COURT.x - RADIUS)
		vel.x = -vel.x * FENCE_KEEP
		ev = "fence"
	if pos.y < RADIUS or pos.y > COURT.y - RADIUS:
		pos.y = clampf(pos.y, RADIUS, COURT.y - RADIUS)
		vel.y = -vel.y * FENCE_KEEP
		ev = "fence"
	return ev

func _iron() -> String:
	## Backboard (a flat pane) and rim (a torus: push away from the closest point of the ring).
	if pos.y - RADIUS < BOARD_Y and pos.y > BOARD_Y - RADIUS and vel.y < 0.0 and absf(pos.x - RIM.x) < BOARD_HALF and z > BOARD_Z0 and z < BOARD_Z1:
		pos.y = BOARD_Y + RADIUS
		vel.y = -vel.y * BOARD_KEEP
		vel.x *= 0.85
		touched_iron = true
		shot = false
		return "board"
	var flat := pos - RIM
	if flat.length() < 0.001:
		return ""
	var ring := RIM + flat.normalized() * RIM_R
	var d := Vector3(pos.x - ring.x, pos.y - ring.y, z - RIM_Z)
	var dist := d.length()
	if dist >= RADIUS + TUBE or dist < 0.001:
		return ""
	var n := d / dist
	var v := Vector3(vel.x, vel.y, vz)
	var into := v.dot(n)
	var push := RADIUS + TUBE - dist
	pos += Vector2(n.x, n.y) * push
	z += n.z * push
	if into >= 0.0:
		return ""
	v -= n * into * (1.0 + RIM_KEEP)
	vel = Vector2(v.x, v.y)
	vz = v.z
	touched_iron = true
	shot = false
	return "rim"

func predict_landing(height: float = 40.0) -> Vector2:
	## Where a falling ball will be when it drops to `height` (ignoring further iron): rebounders run there.
	var disc := vz * vz + 2.0 * GRAVITY * maxf(0.0, z - height)
	var secs := (vz + sqrt(disc)) / GRAVITY
	return (pos + vel * clampf(secs, 0.0, 1.5)).clamp(Vector2(8, 24), COURT - Vector2(8, 8))
