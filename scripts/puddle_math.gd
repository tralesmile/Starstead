class_name PuddleMath
extends RefCounted
## Where rain puddles lie on dirt paths and city asphalt, and how they act on feet and tyres. Pure.
## One tileable noise field is shared by the ground shader (as a texture) and the game, so the puddle you see
## is exactly the puddle that splashes and mirrors.

const TEXELS := 256      # noise texture side
const TEXEL_PX := 4      # world pixels per texel (the field repeats every 32 tiles)
const LATTICE := [44, 96]   # value-noise cells across the field (coarse shape, ragged edge)
const T0 := 0.58
const T1 := 0.68
const SEEN := 0.35       # mask at or above this is standing water

static var _field := PackedFloat32Array()
static var _tex: ImageTexture

static func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0

static func _octave(tx: int, ty: int, n: int, salt: int) -> float:
	var fx := float(tx) * n / TEXELS
	var fy := float(ty) * n / TEXELS
	var ix := int(fx)
	var iy := int(fy)
	var ux := smoothstep(0.0, 1.0, fx - ix)
	var uy := smoothstep(0.0, 1.0, fy - iy)
	var a := lerpf(_hash(ix % n + salt, iy % n), _hash((ix + 1) % n + salt, iy % n), ux)
	var b := lerpf(_hash(ix % n + salt, (iy + 1) % n), _hash((ix + 1) % n + salt, (iy + 1) % n), ux)
	return lerpf(a, b, uy)

static func field() -> PackedFloat32Array:
	if _field.is_empty():
		_field.resize(TEXELS * TEXELS)
		for y in TEXELS:
			for x in TEXELS:
				var v := _octave(x, y, LATTICE[0], 0) * 0.72 + _octave(x, y, LATTICE[1], 91) * 0.28
				_field[y * TEXELS + x] = float(roundi(v * 255.0)) / 255.0   # 8-bit, same as the texture
	return _field

static func texture() -> ImageTexture:
	if _tex == null:
		var f := field()
		var img := Image.create(TEXELS, TEXELS, false, Image.FORMAT_L8)
		for y in TEXELS:
			for x in TEXELS:
				var v := f[y * TEXELS + x]
				img.set_pixel(x, y, Color(v, v, v))
		_tex = ImageTexture.create_from_image(img)
	return _tex

## Bilinear between texel centres, evaluated once per world (art) pixel: soft organic outlines with crisp pixels.
## The ground shader does the same with a filter_linear lookup at the pixel centre.
static func noise_at(world_px: Vector2) -> float:
	var fx := (floorf(world_px.x) + 0.5) / TEXEL_PX - 0.5
	var fy := (floorf(world_px.y) + 0.5) / TEXEL_PX - 0.5
	var ix := floori(fx)
	var iy := floori(fy)
	var f := field()
	var x0 := posmod(ix, TEXELS)
	var x1 := posmod(ix + 1, TEXELS)
	var y0 := posmod(iy, TEXELS) * TEXELS
	var y1 := posmod(iy + 1, TEXELS) * TEXELS
	return lerpf(lerpf(f[y0 + x0], f[y0 + x1], fx - ix), lerpf(f[y1 + x0], f[y1 + x1], fx - ix), fy - iy)

## ---- Night reflections: lamps and lit windows smear into vertical wavering streaks on wet ground.
const STREAK_PUDDLE := 1.0    # surface mirror strength: standing water,
const STREAK_ASPHALT := 0.58  # wet asphalt,
const STREAK_DAMP := 0.32     # wet paving slabs and mud

## How well the ground at a spot mirrors a light (0 on grass, water, or dry weather).
static func gloss(tile: int, mask: float, wet: float) -> float:
	var w := clampf(wet, 0.0, 1.0)
	if capable(tile):
		if mask >= SEEN:
			return STREAK_PUDDLE * w
		return (STREAK_ASPHALT if tile == WorldGen.ASPHALT else STREAK_DAMP) * w
	return STREAK_DAMP * w if WorldGen.is_road(tile) else 0.0

## Streak length in pixels for a lamp hung `height` px above its foot.
static func streak_length(height: float) -> float:
	return clampf(height * 1.6 + 60.0, 70.0, 140.0)

## Brightness 0..1 along the streak, u = 0 at the foot of the lamp, 1 at the tip: quick rise, long fade.
static func streak_profile(u: float) -> float:
	if u <= 0.0 or u >= 1.0:
		return 0.0
	return smoothstep(0.0, 0.22, u) * (1.0 - smoothstep(0.42, 1.0, u))

## Sideways ripple of the row `y` px below the foot; swings wider further out.
static func streak_wobble(y: float, t: float, phase: float) -> float:
	return roundf((sin(y * 0.42 - t * 3.6 + phase) * 1.4 + sin(y * 0.17 + t * 2.1 + phase * 1.7) * 1.2) * clampf(0.4 + y / 70.0, 0.4, 1.5))

## 0..1 ripple breaks: bright dashes with darker gaps that crawl down the streak.
static func streak_dash(y: float, t: float, phase: float) -> float:
	return clampf(0.62 + 0.55 * sin(y * 0.9 - t * 4.2 + phase) * sin(y * 0.31 + t * 1.3 + phase * 0.6) + 0.2 * sin(y * 0.55 - t * 2.0), 0.0, 1.0)

static func mask_of(v: float, wet: float) -> float:
	return smoothstep(T0, T1, v) * clampf(wet, 0.0, 1.0)

static func mask_at(world_px: Vector2, wet: float) -> float:
	return mask_of(noise_at(world_px), wet)

## Puddles form in the ruts of dirt paths and on city asphalt (not on grass or paving slabs).
static func capable(tile: int) -> bool:
	return tile == WorldGen.ASPHALT or (tile >= WorldGen.PATH and tile < WorldGen.PATH + 3)

## Droplets thrown by one footfall: none on dry ground or when creeping, more when running through deep water.
static func step_drops(speed: float, mask: float) -> int:
	if mask < SEEN or speed < 30.0:
		return 0
	return clampi(int(roundf(speed / 22.0 * mask)), 2, 12)

## Standing water slows a wheel: exponential drag per second, from nothing at walking pace.
static func wheel_drag(speed: float, mask: float) -> float:
	if mask < SEEN:
		return 0.0
	return 0.30 * mask * clampf((speed - 40.0) / 160.0, 0.0, 1.0)

## Aquaplaning: above 130 px/s the tyres ride up on the water and lose up to 40% of their grip.
static func aquaplane_grip(speed: float, mask: float) -> float:
	if mask < SEEN:
		return 1.0
	return 1.0 - 0.40 * mask * clampf((speed - 130.0) / 110.0, 0.0, 1.0)

## Droplets per second of the bow wave under a wheel.
static func spray_amount(speed: float, mask: float) -> int:
	if mask < SEEN or speed < 50.0:
		return 0
	return clampi(int(speed / 8.0 * mask), 6, 36)
