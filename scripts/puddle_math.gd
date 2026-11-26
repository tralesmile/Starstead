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

static func noise_at(world_px: Vector2) -> float:
	var tx := posmod(floori(world_px.x / TEXEL_PX), TEXELS)
	var ty := posmod(floori(world_px.y / TEXEL_PX), TEXELS)
	return field()[ty * TEXELS + tx]

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
