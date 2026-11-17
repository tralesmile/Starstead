class_name BobberMath
extends RefCounted
## Pure fishing-line visuals: bobber bob/dip, droop of the line, splash ring size.

## Vertical bobber offset in whole pixels: gentle bob while waiting, a hard dip when a fish bites.
static func bob(t: float, biting: bool) -> float:
	if biting:
		return roundf(2.0 + sin(t * 30.0) * 1.5)
	return roundf(sin(t * 2.2) * 1.0)

## Point on the fishing line: quadratic curve from rod tip a to bobber b, sagging by `sag` px at the middle.
static func line_point(a: Vector2, b: Vector2, k: float, sag: float) -> Vector2:
	var mid := (a + b) * 0.5 + Vector2(0, sag)
	var u := 1.0 - k
	return u * u * a + 2.0 * u * k * mid + k * k * b

## Splash ring: radius px and alpha at age seconds (0 after it ends).
static func splash(age: float, life: float = 0.6) -> Vector2:
	if age < 0.0 or age >= life:
		return Vector2.ZERO
	var k := age / life
	return Vector2(3.0 + 12.0 * k, 1.0 - k)
