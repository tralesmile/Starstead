class_name FootballBall
extends RefCounted
## Pure football physics: a ball with height (z), rolling friction, air drag, bounces, curl (Magnus),
## rebounding boards round the pitch and round goal posts. Pixel units, y down, no autoload use.

const FIELD := Vector2(520.0, 240.0)   # playing area; (0,0) is the top-left corner flag
const GOAL_HALF := 38.0                # half height of the goal mouth
const BAR_Z := 24.0                    # crossbar height
const NET_DEPTH := 18.0
const RADIUS := 4.0
const POST_R := 2.5
const GRAVITY := 420.0
const ROLL_DRAG := 0.9                 # 1/s, exponential part of grass friction
const ROLL_DECEL := 26.0               # px/s^2, constant part so a slow ball really stops
const AIR_DRAG := 0.25
const BOUNCE := 0.55
const WALL_KEEP := 0.65
const CURL_DECAY := 1.6                # 1/s

var pos := FIELD * 0.5
var vel := Vector2.ZERO
var z := 0.0
var vz := 0.0
var curl := 0.0       # rad/s the heading turns while the spin lasts (+ = clockwise on screen)
var roll := 0.0       # distance rolled, drives the sprite frame
var wet := 0.0        # 0 dry .. 1 soaked pitch

static func roll_drag(wetness: float) -> float:
	## A wet pitch skids: the rolling ball keeps its pace longer.
	return ROLL_DRAG * (1.0 - 0.35 * clampf(wetness, 0.0, 1.0))

static func roll_decel(wetness: float) -> float:
	return ROLL_DECEL * (1.0 - 0.45 * clampf(wetness, 0.0, 1.0))

static func bounce_keep(wetness: float) -> float:
	## Sodden turf deadens the bounce.
	return BOUNCE * (1.0 - 0.3 * clampf(wetness, 0.0, 1.0))

func reset(at: Vector2) -> void:
	pos = at
	vel = Vector2.ZERO
	z = 0.0
	vz = 0.0
	curl = 0.0

func kick(dir: Vector2, speed: float, lift: float = 0.0, spin: float = 0.0) -> void:
	vel = dir.normalized() * speed
	vz = maxf(0.0, lift)
	curl = spin

func airborne() -> bool:
	return z > 0.5 or vz > 1.0

static func mouth_top() -> float:
	return FIELD.y * 0.5 - GOAL_HALF

static func mouth_bottom() -> float:
	return FIELD.y * 0.5 + GOAL_HALF

## Advances one small step. Returns "" or "goal_left" / "goal_right" (the goal the ball went INTO),
## "post" on a post or bar rebound, "wall" on a hard board rebound.
func step(dt: float) -> String:
	var event := ""
	if absf(curl) > 0.01:
		vel = vel.rotated(curl * dt)
		curl *= exp(-CURL_DECAY * dt)
	if airborne():
		vel *= exp(-AIR_DRAG * dt)
		vz -= GRAVITY * dt
		z += vz * dt
		if z <= 0.0:
			z = 0.0
			if vz < -40.0:
				vz = -vz * bounce_keep(wet)
				vel *= lerpf(0.86, 0.94, clampf(wet, 0.0, 1.0))
			else:
				vz = 0.0
	else:
		z = 0.0
		vz = 0.0
		var s := vel.length()
		var ns := maxf(0.0, s * exp(-roll_drag(wet) * dt) - roll_decel(wet) * dt)
		vel = vel * (ns / s) if s > 0.001 else Vector2.ZERO
	var prev := pos
	pos += vel * dt
	roll += vel.length() * dt

	# posts: round obstacles at both ends of each goal mouth
	for gx: float in [0.0, FIELD.x]:
		for gy: float in [mouth_top(), mouth_bottom()]:
			var post := Vector2(gx, gy)
			var off := pos - post
			var d := off.length()
			if d < RADIUS + POST_R and z <= BAR_Z + RADIUS and d > 0.001:
				var n := off / d
				if vel.dot(n) < 0.0:
					vel = vel.bounce(n) * WALL_KEEP
					curl = 0.0
					event = "post"
				pos = post + n * (RADIUS + POST_R)

	# side boards
	if pos.y < RADIUS or pos.y > FIELD.y - RADIUS:
		pos.y = clampf(pos.y, RADIUS, FIELD.y - RADIUS)
		if absf(vel.y) > 60.0 and event == "":
			event = "wall"
		vel.y = -vel.y * WALL_KEEP
		curl = 0.0

	# goal lines
	for side in 2:
		var line := 0.0 if side == 0 else FIELD.x
		var crossed := (prev.x >= line and pos.x < line) if side == 0 else (prev.x <= line and pos.x > line)
		var in_mouth := pos.y > mouth_top() and pos.y < mouth_bottom()
		if crossed and in_mouth:
			if z < BAR_Z - RADIUS:
				return "goal_left" if side == 0 else "goal_right"
			if z < BAR_Z + RADIUS:   # off the crossbar
				pos.x = line
				vel.x = -vel.x * WALL_KEEP
				vz = absf(vz) * 0.4
				return "post"
		var beyond := pos.x < RADIUS if side == 0 else pos.x > FIELD.x - RADIUS
		# outside the mouth (or sailing over the bar) the end boards throw it back
		if beyond and (not in_mouth or z >= BAR_Z + RADIUS):
			pos.x = clampf(pos.x, RADIUS, FIELD.x - RADIUS)
			if absf(vel.x) > 60.0 and event == "":
				event = "wall"
			vel.x = -vel.x * WALL_KEEP
			curl = 0.0
	return event

## Where a flat (rolling) ball will be after t seconds, for passing and keepers. Ignores walls.
func predict(t: float) -> Vector2:
	var s := vel.length()
	if s < 1.0:
		return pos
	var drag := roll_drag(wet)
	var travel := s * (1.0 - exp(-drag * t)) / drag - 0.25 * roll_decel(wet) * t * t
	return pos + vel / s * maxf(0.0, travel)

## Initial speed needed for a rolling pass to cover `dist` and arrive still moving.
static func pass_speed(dist: float) -> float:
	return clampf(dist * 1.25 + 80.0, 130.0, 330.0)
