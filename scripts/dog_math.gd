class_name DogMath
extends RefCounted
## Pure rules for a guard dog inside a robbed house (RobberyModel gives a house a dog after repeat robberies).
## It wakes when you come close, runs at you, and barks every second or so; each bark is noise toward waking
## the residents. A piece of raw meat from your bag keeps it busy chewing for a while.

const WAKE_RADIUS := 150.0   # px
const SPEED := 72.0          # px/s, a bit slower than a sprint
const STOP := 20.0           # stays this far off, growling
const BARK_EVERY := 1.1      # s
const BARK_NOISE := 7.0      # RobberyModel noise per bark (wake threshold is 60)
const TREAT := "raw_meat"
const CHEW_SECS := 14.0

static func awake(dog: Vector2, player: Vector2, was_awake: bool) -> bool:
	return was_awake or dog.distance_to(player) <= WAKE_RADIUS

static func step(dog: Vector2, player: Vector2, dt: float) -> Vector2:
	var d := player - dog
	var l := d.length()
	if l <= STOP:
		return dog
	return dog + d / l * minf(SPEED * dt, l - STOP)

static func bark(timer: float, dt: float) -> Dictionary:
	## {bark, timer}: counts down while awake; barks and rearms at zero.
	var t := timer - dt
	if t <= 0.0:
		return {"bark": true, "timer": BARK_EVERY}
	return {"bark": false, "timer": t}
